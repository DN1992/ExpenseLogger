import 'package:flutter/material.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> subcategories;

  Category({
    required this.name,
    required this.icon,
    required this.color,
    required this.subcategories,
  });
}

// Complete predefined categories with all subcategories
final List<Category> defaultCategories = [
  Category(
    name: 'Food & Dining',
    icon: Icons.restaurant,
    color: Colors.orange,
    subcategories: [
      'Groceries',
      'Restaurants',
      'Fast Food',
      'Coffee Shops',
      'Food Delivery',
      'Alcohol & Bars',
      'Bakeries',
      'Meal Prep Services',
      'Work Lunch',
      'Date Night',
    ],
  ),
  Category(
    name: 'Transportation',
    icon: Icons.directions_car,
    color: Colors.blue,
    subcategories: [
      'Fuel',
      'Public Transport',
      'Ride Sharing',
      'Parking',
      'Vehicle Maintenance',
      'Car Insurance',
      'Parking Fees',
      'Tolls',
      'Car Wash',
      'Vehicle Registration',
      'Train Tickets',
      'Bus Pass',
      'Bike Maintenance',
      'Taxi',
    ],
  ),
  Category(
    name: 'Shopping',
    icon: Icons.shopping_bag,
    color: Colors.purple,
    subcategories: [
      'Clothing',
      'Electronics',
      'Home Goods',
      'Personal Care',
      'Gifts',
      'Online Shopping',
      'Shoes',
      'Accessories',
      'Furniture',
      'Kitchenware',
      'Books',
      'Music',
      'Video Games',
      'Seasonal Decor',
    ],
  ),
  Category(
    name: 'Entertainment',
    icon: Icons.movie,
    color: Colors.pink,
    subcategories: [
      'Movies',
      'Concerts',
      'Streaming Services',
      'Games',
      'Hobbies',
      'Sports',
      'Theater',
      'Museums',
      'Amusement Parks',
      'Nightclubs',
      'Podcast Subscriptions',
      'Live Events',
      'Arcade',
      'Bowling',
    ],
  ),
  Category(
    name: 'Bills & Utilities',
    icon: Icons.receipt,
    color: Colors.red,
    subcategories: [
      'Electricity',
      'Water',
      'Gas',
      'Internet',
      'Phone',
      'Rent/Mortgage',
      'Insurance',
      'Cable TV',
      'Trash Collection',
      'HOA Fees',
      'Property Tax',
      'Streaming Services',
      'Cloud Storage',
      'Software Subscriptions',
    ],
  ),
  Category(
    name: 'Healthcare',
    icon: Icons.local_hospital,
    color: Colors.green,
    subcategories: [
      'Doctor Visits',
      'Medications',
      'Dental',
      'Vision',
      'Health Insurance',
      'Fitness',
      'Therapy',
      'Medical Tests',
      'Veterinary',
      'Vitamins',
      'Medical Equipment',
      'Emergency Room',
      'Physical Therapy',
    ],
  ),
  Category(
    name: 'Education',
    icon: Icons.school,
    color: Colors.teal,
    subcategories: [
      'Tuition',
      'Books',
      'Courses',
      'Supplies',
      'Student Loans',
      'Online Courses',
      'Tutoring',
      'Workshops',
      'Educational Apps',
      'School Fees',
      'Certifications',
      'Language Classes',
    ],
  ),
  Category(
    name: 'Travel',
    icon: Icons.flight,
    color: Colors.indigo,
    subcategories: [
      'Flights',
      'Hotels',
      'Rental Cars',
      'Activities',
      'Travel Insurance',
      'Luggage',
      'Travel Gear',
      'Vacation Rentals',
      'Cruises',
      'Tours',
      'Travel Dining',
      'Airport Parking',
      'Passport/Visa',
    ],
  ),
  Category(
    name: 'Personal Care',
    icon: Icons.face,
    color: Colors.deepPurple,
    subcategories: [
      'Haircuts',
      'Spa',
      'Cosmetics',
      'Gym Membership',
      'Wellness',
      'Skincare',
      'Fragrance',
      'Manicure/Pedicure',
      'Massage',
      'Barber',
      'Yoga Classes',
      'Meditation Apps',
    ],
  ),
  Category(
    name: 'Other',
    icon: Icons.category,
    color: Colors.grey,
    subcategories: [
      'Miscellaneous',
      'Gifts',
      'Donations',
      'Fees',
      'Services',
      'Pet Care',
      'Child Care',
      'Laundry',
      'Postage',
      'Office Supplies',
      'Tools',
      'Gardening',
    ],
  ),
];

// Helper function to get subcategories for a category
List<String> getSubcategoriesForCategory(String categoryName) {
  final category = defaultCategories.firstWhere(
    (c) => c.name == categoryName,
    orElse: () => defaultCategories.last,
  );
  return category.subcategories;
}

// Helper function to get all main category names
List<String> getMainCategoryNames() {
  return defaultCategories.map((c) => c.name).toList();
}

// Helper function to get category color
Color getCategoryColor(String categoryName) {
  final category = defaultCategories.firstWhere(
    (c) => c.name == categoryName,
    orElse: () => defaultCategories.last,
  );
  return category.color;
}

// Helper function to get category icon
IconData getCategoryIcon(String categoryName) {
  final category = defaultCategories.firstWhere(
    (c) => c.name == categoryName,
    orElse: () => defaultCategories.last,
  );
  return category.icon;
}