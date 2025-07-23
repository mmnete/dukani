import 'package:uuid/uuid.dart'; // For generating unique IDs

// Initialize Uuid for generating unique IDs
final _uuid = const Uuid();

// Enum to differentiate between user types
enum UserType {
  worker,
  manager,
}

// Abstract parent class for all user types (Worker, Manager)
abstract class User {
  String id;
  String name;
  String phoneNumber;
  String? firebaseUid; // Link to Firebase Auth UID if user logs in
  String? shopId; // The shop this user belongs to
  UserType userType; // Differentiating field

  User({
    String? id,
    required this.name,
    required this.phoneNumber,
    this.firebaseUid,
    this.shopId,
    required this.userType,
  }) : id = id ?? _uuid.v4();

  // Abstract method to convert User object to a Map for storage/transfer
  Map<String, dynamic> toJson();

  // Factory constructor to create User (or its subclass) from a Map
  // This factory method will determine the concrete type (Worker or Manager)
  factory User.fromJson(Map<String, dynamic> json) {
    final typeString = json['userType'] as String;
    final userType = UserType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => UserType.worker, // Default to worker if type is unknown
    );

    if (userType == UserType.manager) {
      return Manager.fromJson(json);
    } else {
      // Default to worker if userType is 'worker' or unknown
      return Worker.fromJson(json);
    }
  }
}

// Worker class now extends User
class Worker extends User {
  Worker({
    String? id,
    required String name,
    required String phoneNumber,
    String? firebaseUid,
    String? shopId,
  }) : super(
          id: id,
          name: name,
          phoneNumber: phoneNumber,
          firebaseUid: firebaseUid,
          shopId: shopId,
          userType: UserType.worker, // Explicitly set userType for Worker
        );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'firebaseUid': firebaseUid,
        'shopId': shopId,
        'userType': userType.toString().split('.').last, // Store as string 'worker'
      };

  // Factory constructor to create Worker object from a Map
  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
        id: json['id'],
        name: json['name'],
        phoneNumber: json['phoneNumber'],
        firebaseUid: json['firebaseUid'],
        shopId: json['shopId'],
      );
}

// Manager class now extends User
class Manager extends User {
  Manager({
    String? id,
    required String name,
    required String phoneNumber,
    String? firebaseUid,
    String? shopId,
  }) : super(
          id: id,
          name: name,
          phoneNumber: phoneNumber,
          firebaseUid: firebaseUid,
          shopId: shopId,
          userType: UserType.manager, // Explicitly set userType for Manager
        );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'firebaseUid': firebaseUid,
        'shopId': shopId,
        'userType': userType.toString().split('.').last, // Store as string 'manager'
      };

  // Factory constructor to create Manager object from a Map
  factory Manager.fromJson(Map<String, dynamic> json) => Manager(
        id: json['id'],
        name: json['name'],
        phoneNumber: json['phoneNumber'],
        firebaseUid: json['firebaseUid'],
        shopId: json['shopId'],
      );
}

class Shop {
  String id;
  String name;
  String address;
  String phoneNumber; // Shop's main contact number
  List<Worker> workers; // Still type-safe list of Worker objects
  List<Manager> managers; // Still type-safe list of Manager objects

  Shop({
    String? id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    List<Worker>? workers,
    List<Manager>? managers,
  }) : id = id ?? _uuid.v4(),
       workers = workers ?? [],
       managers = managers ?? [];

  // Convert Shop object to a Map
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'phoneNumber': phoneNumber,
    'workers': workers.map((w) => w.toJson()).toList(),
    'managers': managers.map((m) => m.toJson()).toList(),
  };

  // Create Shop object from a Map
  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    phoneNumber: json['phoneNumber'],
    workers: (json['workers'] as List<dynamic>?)
        ?.map((wJson) => Worker.fromJson(wJson as Map<String, dynamic>))
        .toList() ?? [],
    managers: (json['managers'] as List<dynamic>?)
        ?.map((mJson) => Manager.fromJson(mJson as Map<String, dynamic>))
        .toList() ?? [],
  );
}
