class DummyAnalyticsService {
  // Dummy data for weekly stock movement
  static List<Map<String, dynamic>> getWeeklyStockData() {
    return [
      {'day': 'Mon', 'stockIn': 30, 'stockOut': 20, 'missedSales': 5},
      {'day': 'Tue', 'stockIn': 50, 'stockOut': 40, 'missedSales': 8},
      {'day': 'Wed', 'stockIn': 40, 'stockOut': 30, 'missedSales': 12},
      {'day': 'Thu', 'stockIn': 70, 'stockOut': 60, 'missedSales': 7},
      {'day': 'Fri', 'stockIn': 90, 'stockOut': 80, 'missedSales': 10},
      {'day': 'Sat', 'stockIn': 100, 'stockOut': 85, 'missedSales': 15},
      {'day': 'Sun', 'stockIn': 110, 'stockOut': 90, 'missedSales': 20},
    ];
  }

  // Dummy data for workers
  static List<Map<String, dynamic>> getWorkersData() {
    return [
      {
        'id': 'W001',
        'name': 'Aisha Juma',
        'role': 'Sales Associate',
        'phone': '+255712345001',
        'lastActivity': '2025-07-12 14:30',
        'actionsToday': ['Sold 5x Milk', 'Processed 2x Returns'],
      },
      {
        'id': 'W002',
        'name': 'Baraka Ali',
        'role': 'Stock Clerk',
        'phone': '+255713456002',
        'lastActivity': '2025-07-12 10:15',
        'actionsToday': ['Restocked 10x Bread', 'Organized Aisle 3'],
      },
      {
        'id': 'W003',
        'name': 'Zawadi Hassan',
        'role': 'Sales Associate',
        'phone': '+255714567003',
        'lastActivity': '2025-07-12 16:00',
        'actionsToday': ['Sold 3x Soda', 'Assisted Customer'],
      },
      {
        'id': 'W004',
        'name': 'Juma Omar',
        'role': 'Delivery Driver',
        'phone': '+255715678004',
        'lastActivity': '2025-07-12 11:45',
        'actionsToday': ['Delivered order to customer X', 'Picked up supplies'],
      },
    ];
  }

  // Dummy data for products
  static List<Map<String, dynamic>> getProductsData() {
    return [
      {
        'id': 'P001',
        'name': 'Milk (1L)',
        'price': 2.50,
        'currentStock': 150,
        'category': 'Dairy',
        'description': 'Fresh cow milk, 1-liter carton.',
      },
      {
        'id': 'P002',
        'name': 'Bread (Whole Wheat)',
        'price': 1.80,
        'currentStock': 80,
        'category': 'Bakery',
        'description': 'Healthy whole wheat bread loaf.',
      },
      {
        'id': 'P003',
        'name': 'Soda (300ml)',
        'price': 1.00,
        'currentStock': 300,
        'category': 'Beverages',
        'description': 'Assorted flavors of carbonated soft drinks.',
      },
      {
        'id': 'P004',
        'name': 'Rice (5kg)',
        'price': 8.75,
        'currentStock': 70,
        'category': 'Grains',
        'description': 'Premium long-grain white rice.',
      },
      {
        'id': 'P005',
        'name': 'Cooking Oil (2L)',
        'price': 5.20,
        'currentStock': 120,
        'category': 'Pantry',
        'description': 'Vegetable cooking oil, 2-liter bottle.',
      },
    ];
  }

  // Dummy data for product performance (e.g., sales volume, revenue)
  static List<Map<String, dynamic>> getProductPerformanceData() {
    return [
      {
        'productId': 'P001',
        'productName': 'Milk (1L)',
        'salesVolume': 500,
        'revenue': 1250.00,
        'trend': 'Up',
      },
      {
        'productId': 'P003',
        'productName': 'Soda (300ml)',
        'salesVolume': 800,
        'revenue': 800.00,
        'trend': 'Stable',
      },
      {
        'productId': 'P002',
        'productName': 'Bread (Whole Wheat)',
        'salesVolume': 200,
        'revenue': 360.00,
        'trend': 'Down',
      },
      {
        'productId': 'P005',
        'productName': 'Cooking Oil (2L)',
        'salesVolume': 300,
        'revenue': 1560.00,
        'trend': 'Up',
      },
    ];
  }
}
