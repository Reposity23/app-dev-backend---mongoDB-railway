import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import './models.dart';

class Database {
  mongo.Db? _db;
  mongo.DbCollection? _users;
  mongo.DbCollection? _orders;

  Future<void> initialize() async {
    final mongoUrl = Platform.environment['MONGO_URL'];
    if (mongoUrl == null) {
      throw Exception('MONGO_URL environment variable not set');
    }
    _db = await mongo.Db.create(mongoUrl);
    await _db!.open();
    _users = _db!.collection('users');
    _orders = _db!.collection('orders');
    print('MongoDB connected');
  }

  Future<void> close() async {
    await _db?.close();
  }

  Future<void> createUser(User user) async {
    await _users?.insertOne(user.toJson());
  }

  Future<User?> getUserByUsername(String username) async {
    final userMap = await _users?.findOne(mongo.where.eq('username', username));
    if (userMap != null) {
      // The mongo_dart driver >=0.9 returns ObjectId for _id.
      // We need to convert it to a string to match the model.
      userMap['_id'] = userMap['_id'].toHexString();
      return User.fromJson(userMap);
    }
    return null;
  }

  Future<void> createOrder(Order order) async {
    await _orders?.insertOne(order.toJson());
  }

  Future<Order?> getOrderById(String id) async {
    final orderMap = await _orders?.findOne(mongo.where.eq('id', id));
    if (orderMap != null) {
      orderMap['_id'] = orderMap['_id'].toHexString();
      return Order.fromJson(orderMap);
    }
    return null;
  }
  
  Future<Order?> getOrderByRfidUid(String rfidUid) async {
    final orderMap = await _orders?.findOne(mongo.where.eq('rfidUid', rfidUid));
    if (orderMap != null) {
      orderMap['_id'] = orderMap['_id'].toHexString();
      return Order.fromJson(orderMap);
    }
    return null;
  }

  Future<Order?> updateOrder(Order order) async {
    await _orders?.replaceOne(mongo.where.eq('id', order.id), order.toJson());
    return order;
  }

  Future<List<Order>> getAllOrders() async {
    final ordersList = await _orders?.find().toList() ?? [];
    return ordersList.map((map) {
      map['_id'] = map['_id'].toHexString();
      return Order.fromJson(map);
    }).toList();
  }

  Future<void> clearAllOrders() async {
    await _orders?.deleteMany({});
  }

  Future<Order?> getOldestPendingOrderForPerson(String personName) async {
    final orderMap = await _orders?.findOne(
        mongo.where.eq('assignedPerson', personName)
            .eq('status', 'PENDING')
            .sortBy('createdAt')
    );
    if (orderMap != null) {
      orderMap['_id'] = orderMap['_id'].toHexString();
      return Order.fromJson(orderMap);
    }
    return null;
  }
}
