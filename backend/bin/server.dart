import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../lib/database.dart';
import '../lib/models.dart';
import '../lib/auth.dart';

final _clients = <WebSocketChannel>[];
final _db = Database();
final _uuid = Uuid();

// --- Main Server Setup ---
void main() async {
  await _db.initialize();
  print('Database initialized');

  final apiRouter = Router();
  // API Endpoints
  apiRouter.post('/api/login', _loginHandler);
  apiRouter.post('/api/signup', _signupHandler);
  apiRouter.post('/api/orders', _createOrderHandler);
  apiRouter.get('/api/orders', _getOrdersHandler);
  apiRouter.post('/api/orders/clear', _clearOrdersHandler);
  // New endpoint for person-centric scans
  apiRouter.post('/api/process-next', _processNextOrderHandler);

  // WebSocket for dashboard updates
  apiRouter.get('/ws', webSocketHandler((WebSocketChannel webSocket, String? protocol) {
    _clients.add(webSocket);
    print('Dashboard client connected. Total clients: ${_clients.length}');
    webSocket.stream.listen((message) {},
     onDone: () {
      _clients.remove(webSocket);
      print('Dashboard client disconnected. Total clients: ${_clients.length}');
    });
  }));

  final dashboardPath = p.normalize(p.join(Directory.current.path, '..', 'dashboard'));
  final staticHandler = createStaticHandler(dashboardPath, defaultDocument: 'index.html');

  final cascade = Cascade().add(apiRouter.call).add(staticHandler);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(
    const Pipeline().addMiddleware(logRequests()).addHandler(cascade.handler),
    '0.0.0.0', 
    port,
  );

  print('Server running on http://${server.address.host}:${server.port}');
}

// --- New Person-Centric Handler ---
Future<Response> _processNextOrderHandler(Request request) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);
  final personName = data['person_name'];

  if (personName == null) {
    return Response.badRequest(body: jsonEncode({'action': 'error', 'led': 'all'}));
  }

  final nextOrder = await _db.getOldestPendingOrderForPerson(personName);

  if (nextOrder == null) {
    print('Scan from $personName, but they have no pending orders.');
    return Response.ok(jsonEncode({'action': 'no_pending_orders', 'led': 'all'}));
  }

  print('Processing order ${nextOrder.toyName} for $personName');
  var updatedOrder = nextOrder.copyWith(status: 'PROCESSING', updatedAt: DateTime.now());
  await _db.updateOrder(updatedOrder);
  _broadcastToClients(updatedOrder.toJson());

  _simulateFulfillment(updatedOrder);
  
  return Response.ok(jsonEncode({'action': 'processing_success', 'led': updatedOrder.category}));
}

// --- CORRECTED Fulfillment Simulation ---
void _simulateFulfillment(Order order) {
  // PROCESSING -> ON_THE_WAY
  Future.delayed(const Duration(seconds: 3), () async {
    var currentOrder = await _db.getOrderById(order.id);
    if (currentOrder == null || currentOrder.status != 'PROCESSING') return;

    var onTheWayOrder = currentOrder.copyWith(status: 'ON_THE_WAY', updatedAt: DateTime.now());
    var result1 = await _db.updateOrder(onTheWayOrder);
    if (result1 == null) return;

    _broadcastToClients(result1.toJson());

    // ON_THE_WAY -> DELIVERED
    Future.delayed(const Duration(seconds: 3), () async {
      var currentOrder2 = await _db.getOrderById(order.id);
      if (currentOrder2 == null || currentOrder2.status != 'ON_THE_WAY') return;

      var deliveredOrder = currentOrder2.copyWith(status: 'DELIVERED', updatedAt: DateTime.now());
      var result2 = await _db.updateOrder(deliveredOrder);
      if (result2 == null) return;

      _broadcastToClients(result2.toJson());

      // DELIVERED -> COMPLETED
      Future.delayed(const Duration(seconds: 3), () async {
        var currentOrder3 = await _db.getOrderById(order.id);
        if (currentOrder3 == null || currentOrder3.status != 'DELIVERED') return;

        var completedOrder = currentOrder3.copyWith(status: 'COMPLETED', updatedAt: DateTime.now());
        var result3 = await _db.updateOrder(completedOrder);
        if (result3 != null) _broadcastToClients(result3.toJson());
      });
    });
  });
}

// --- Other Handlers (Mostly Unchanged) ---

Future<Response> _createOrderHandler(Request request) async {
    final authHeader = request.headers['authorization'];
    if (authHeader == null) return Response.unauthorized(jsonEncode({'error': 'Unauthorized'}));
    final token = authHeader.replaceFirst('Bearer ', '');
    final payload = AuthService.verifyToken(token);
    if (payload == null) return Response.unauthorized(jsonEncode({'error': 'Invalid token'}));
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final order = Order(
      id: _uuid.v4(),
      toyId: data['toy_id'],
      toyName: data['toy_name'],
      category: data['category'],
      rfidUid: data['rfid_uid'], // This is the Toy's UID, used for placing orders
      assignedPerson: data['assigned_person'],
      status: 'PENDING',
      createdAt: DateTime.now(),
      department: data['department'],
      totalAmount: (data['total_amount'] ?? 0).toDouble(),
    );
    await _db.createOrder(order);
    _broadcastToClients(order.toJson());
    return Response(201, body: jsonEncode(order.toJson()), headers: {'Content-Type': 'application/json'});
}

Future<Response> _clearOrdersHandler(Request request) async {
  await _db.clearAllOrders();
  _broadcastToClients({'type': 'clear'});
  return Response.ok(jsonEncode({'message': 'All orders cleared'}));
}

Future<Response> _getOrdersHandler(Request request) async {
  final orders = await _db.getAllOrders();
  return Response.ok(jsonEncode(orders.map((o) => o.toJson()).toList()), headers: {'Content-Type': 'application/json'});
}

Future<Response> _loginHandler(Request request) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);
  final user = await _db.getUserByUsername(data['username']);
  if (user == null || !AuthService.verifyPassword(data['password'], user.passwordHash)) {
    return Response.unauthorized(jsonEncode({'error': 'Invalid credentials'}));
  }
  final token = AuthService.generateToken(user.id, user.username, user.department);
  return Response.ok(jsonEncode({'user': user.toJson(), 'token': token}), headers: {'Content-Type': 'application/json'});
}

Future<Response> _signupHandler(Request request) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);
  final user = User(
    id: _uuid.v4(),
    username: data['username'],
    email: data['email'],
    passwordHash: AuthService.hashPassword(data['password']),
    department: "General",
    createdAt: DateTime.now(),
  );
  await _db.createUser(user);
  final token = AuthService.generateToken(user.id, user.username, user.department);
  return Response(201, body: jsonEncode({'user': user.toJson(), 'token': token}), headers: {'Content-Type': 'application/json'});
}

void _broadcastToClients(Map<String, dynamic> data) {
  final message = jsonEncode(data);
  _clients.removeWhere((client) => client.closeCode != null);
  for (final client in _clients) {
    try {
      client.sink.add(message);
    } catch (e) {
      print('Failed to send message to client: $e');
    }
  }
}
