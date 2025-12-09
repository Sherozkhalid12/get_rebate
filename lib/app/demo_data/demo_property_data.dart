class DemoPropertyData {
  static Map<String, dynamic> getSampleProperty() {
    return {
      'id': 'property_1',
      'agentId': 'agent_1',
      'title': 'Modern Luxury Home with Pool',
      'description':
          'This stunning modern home features an open floor plan, high-end finishes, and a beautiful pool area perfect for entertaining. Located in a desirable neighborhood with excellent schools and amenities.',
      'price': 2500000,
      'address': '123 Park Avenue',
      'city': 'New York',
      'state': 'NY',
      'zip': '10001',
      'beds': 4,
      'baths': 3,
      'sqft': 2500,
      'lotSize': '0.25 acres',
      'yearBuilt': 2020,
      'status': 'For Sale',
      'propertyType': 'house',
      'images': [
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
        'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
        'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=800',
      ],
      'image':
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      // Rebate-related fields
      'bacPercent': 2.5, // 2.5% BAC
      'dualAgencyAllowed': true, // Dual agency is allowed
      'agent': {
        'name': 'Sarah Johnson',
        'company': 'Premier Realty Group',
        'profileImage':
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=200',
        'phone': '+1 (555) 123-4567',
        'email': 'sarah@premierrealty.com',
      },
    };
  }

  static Map<String, dynamic> getSampleProperty2() {
    return {
      'id': 'property_2',
      'agentId': 'agent_2',
      'title': 'Downtown Condo with City Views',
      'description':
          'Beautiful downtown condo with panoramic city views. Features modern amenities, high-end appliances, and a prime location near restaurants and shopping.',
      'price': 850000,
      'address': '456 Broadway',
      'city': 'New York',
      'state': 'NY',
      'zip': '10002',
      'beds': 2,
      'baths': 2,
      'sqft': 1200,
      'yearBuilt': 2018,
      'status': 'For Sale',
      'propertyType': 'condo',
      'images': [
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800',
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      ],
      'image':
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800',
      // Rebate-related fields
      'bacPercent': 3.0, // 3.0% BAC (maximum)
      'dualAgencyAllowed': false, // Dual agency not allowed
      'agent': {
        'name': 'Michael Chen',
        'company': 'Metro Properties',
        'profileImage':
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
        'phone': '+1 (555) 234-5678',
        'email': 'michael@metroprop.com',
      },
    };
  }

  static Map<String, dynamic> getSampleProperty3() {
    return {
      'id': 'property_3',
      'agentId': 'agent_3',
      'title': 'Family Home in Suburbs',
      'description':
          'Perfect family home in a quiet suburban neighborhood. Features a large backyard, updated kitchen, and excellent schools nearby.',
      'price': 650000,
      'address': '789 Oak Street',
      'city': 'Brooklyn',
      'state': 'NY',
      'zip': '10003',
      'beds': 3,
      'baths': 2,
      'sqft': 1800,
      'lotSize': '0.5 acres',
      'yearBuilt': 2015,
      'status': 'For Sale',
      'propertyType': 'house',
      'images': [
        'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800',
        'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800',
      ],
      'image':
          'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800',
      // Rebate-related fields
      'bacPercent': 2.5, // 2.5% BAC (minimum)
      'dualAgencyAllowed': true, // Dual agency is allowed
      'agent': {
        'name': 'Emily Rodriguez',
        'company': 'City Homes Realty',
        'profileImage':
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
        'phone': '+1 (555) 345-6789',
        'email': 'emily@cityhomes.com',
      },
    };
  }
}
