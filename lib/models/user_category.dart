class UserCategory {
  int? id;
  String name;
  String? iconName; // Store icon name as string
  int colorValue; // Store color as integer
  bool isCustom;
  int? parentId; // null for main categories, parent ID for subcategories
  int displayOrder;

  UserCategory({
    this.id,
    required this.name,
    this.iconName,
    required this.colorValue,
    required this.isCustom,
    this.parentId,
    this.displayOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorValue': colorValue,
      'isCustom': isCustom ? 1 : 0,
      'parentId': parentId,
      'displayOrder': displayOrder,
    };
  }

  factory UserCategory.fromMap(Map<String, dynamic> map) {
    return UserCategory(
      id: map['id'],
      name: map['name'],
      iconName: map['iconName'],
      colorValue: map['colorValue'],
      isCustom: map['isCustom'] == 1,
      parentId: map['parentId'],
      displayOrder: map['displayOrder'],
    );
  }
}