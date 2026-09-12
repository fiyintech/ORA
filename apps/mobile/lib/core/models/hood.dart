class HoodModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final int memberCount;
  final bool isJoined;
  final String bannerUrl;
  final String iconUrl;

  HoodModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.memberCount,
    this.isJoined = false,
    this.bannerUrl = '',
    this.iconUrl = '',
  });
}