import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import '../services/order_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final WebSocketService _wsService = WebSocketService();
  final OrderService _orderService = OrderService();

  User? _currentUser;
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  // Callback for general notifications
  Function(String title, String body)? onNotification;
  // New, specific callback for delivered orders
  Function(Order order)? onOrderDelivered;

  User? get currentUser => _currentUser;
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _wsService.isConnected;
  bool get isLoggedIn => _isLoggedIn;

  void setNotificationCallback(Function(String title, String body) callback) {
    onNotification = callback;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _isLoggedIn = true;
      _currentUser = await _authService.getCurrentUser();
      if (_currentUser != null) {
        _connectWebSocket();
        await loadOrders();
      }
    }
    notifyListeners();
  }

  void _connectWebSocket() {
    _wsService.connect();
    _wsService.orderStream.listen((order) {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index >= 0) {
        final oldStatus = _orders[index].status;
        _orders[index] = order;
        
        // General notification for any status change
        if (onNotification != null && oldStatus != order.status) {
          onNotification!(
            'Order Update: ${order.toyName}',
            'Your order status changed to ${order.status}',
          );
        }

        // **NEW**: Specific trigger for the delivered pop-up
        if (onOrderDelivered != null && order.status == 'DELIVERED' && oldStatus != 'DELIVERED') {
          onOrderDelivered!(order);
        }

      } else {
        _orders.insert(0, order);
      }
      notifyListeners();
    });
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _errorMessage = null;

    final user = await _authService.login(username, password);
    if (user != null) {
      _currentUser = user;
      _isLoggedIn = true;
      _connectWebSocket();
      await loadOrders();
      _setLoading(false);
      return true;
    }

    _errorMessage = 'Invalid username or password';
    _setLoading(false);
    return false;
  }

  Future<bool> signup(String username, String email, String password, String department) async {
    _setLoading(true);
    _errorMessage = null;

    final user = await _authService.signup(username, email, password, department);
    if (user != null) {
      _currentUser = user;
      _isLoggedIn = true;
      _connectWebSocket();
      _setLoading(false);
      return true;
    }

    _errorMessage = 'Signup failed. Please try again.';
    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _wsService.disconnect();
    _currentUser = null;
    _orders = [];
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> loadOrders() async {
    if (_currentUser?.token == null) return;

    _setLoading(true);
    _orders = await _orderService.fetchOrders(_currentUser!.token!);
    _setLoading(false);
  }

  Future<bool> createOrder({
    required String toyId,
    required String toyName,
    required String category,
    required String rfidUid,
    required String assignedPerson,
    required double totalAmount,
  }) async {
    if (_currentUser?.token == null) return false;

    _setLoading(true);
    final order = await _orderService.createOrder(
      toyId: toyId,
      toyName: toyName,
      category: category,
      rfidUid: rfidUid,
      assignedPerson: assignedPerson,
      department: currentUser!.department,
      totalAmount: totalAmount,
      token: _currentUser!.token!,
    );

    if (order != null) {
      _wsService.sendMessage(order.toJson());
      _orders.insert(0, order);
      if (onNotification != null) {
        onNotification!('Order Placed!', 'Your order for ${order.toyName} has been confirmed.');
      }
      _setLoading(false);
      return true;
    }

    _setLoading(false);
    return false;
  }

  Future<void> updateUserEmail(String newEmail) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(email: newEmail);
      notifyListeners();
    }
  }

  Future<void> updateUserAddress(String newAddress) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(address: newAddress);
      notifyListeners();
    }
  }

  List<Order> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }
}
