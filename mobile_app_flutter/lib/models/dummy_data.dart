import 'models.dart'; // Adjust import path as needed
import 'package:uuid/uuid.dart';

final _uuid = const Uuid();

// Helper to generate a random Tanzanian phone number
String _generateTzPhoneNumber() {
  final random = _uuid.v4().replaceAll('-', ''); // Use UUID for randomness
  final prefix = ['06', '07'][_uuid.v1().hashCode % 2]; // Randomly pick 06 or 07
  return '$prefix${random.substring(0, 8)}'; // 8 digits after prefix
}

// Pre-populate a list of dummy shops
List<Shop> dummyShops = [
  Shop(
    id: 'SHOP_DAR_001',
    name: 'Mama Amina Grocery',
    address: 'Kariakoo, Dar es Salaam',
    phoneNumber: _generateTzPhoneNumber(),
    managers: [
      Manager(
        id: 'MGR_DAR_001',
        name: 'Amina Juma',
        phoneNumber: _generateTzPhoneNumber(),
        firebaseUid: null, // Will be set on login/registration
        shopId: 'SHOP_DAR_001',
      ),
    ],
    workers: [
      Worker(
        id: 'WRK_DAR_001',
        name: 'Juma Selemani',
        phoneNumber: _generateTzPhoneNumber(),
        firebaseUid: null,
        shopId: 'SHOP_DAR_001',
      ),
      Worker(
        id: 'WRK_DAR_002',
        name: 'Fatma Hassan',
        phoneNumber: _generateTzPhoneNumber(),
        firebaseUid: null,
        shopId: 'SHOP_DAR_001',
      ),
    ],
  ),
  Shop(
    id: 'SHOP_ARU_002',
    name: 'Arusha Hardware Store',
    address: 'Sanawari, Arusha',
    phoneNumber: _generateTzPhoneNumber(),
    managers: [
      Manager(
        id: 'MGR_ARU_002',
        name: 'Peter Mushi',
        phoneNumber: _generateTzPhoneNumber(),
        firebaseUid: null,
        shopId: 'SHOP_ARU_002',
      ),
    ],
    workers: [
      Worker(
        id: 'WRK_ARU_003',
        name: 'Neema John',
        phoneNumber: _generateTzPhoneNumber(),
        firebaseUid: null,
        shopId: 'SHOP_ARU_002',
      ),
    ],
  ),
  Shop(
    id: 'SHOP_MZA_003',
    name: 'Mwanza Fish Mart',
    address: 'Kirumba, Mwanza',
    phoneNumber: _generateTzPhoneNumber(),
    managers: [
      Manager(
        id: 'MGR_MZA_003',
        name: 'Zainabu Musa',
        phoneNumber: _generateTzPhoneNumber(),
        firebaseUid: null,
        shopId: 'SHOP_MZA_003',
      ),
    ],
    workers: [], // No workers initially
  ),
  Shop(
    id: 'SHOP_DOD_004',
    name: 'Dodoma Bakery',
    address: 'Majengo, Dodoma',
    phoneNumber: _generateTzPhoneNumber(),
    managers: [
      Manager(
        id: 'MGR_DOD_004',
        name: 'Hassan Ali',
        phoneNumber: _generateTzPhoneNumber(),
        firebaseUid: null,
        shopId: 'SHOP_DOD_004',
      ),
    ],
    workers: [
      Worker(
        id: 'WRK_DOD_004',
        name: 'Aisha Said',
        phoneNumber: _generateTzPhoneNumber(),
        firebaseUid: null,
        shopId: 'SHOP_DOD_004',
      ),
    ],
  ),
];
