class Store {
  final int id;
  final String name;
  final String description;
  final String city;
  final String logoUrl;
  final bool isApproved;

  Store({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    required this.logoUrl,
    required this.isApproved,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      city: json['city'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? '',
      isApproved: json['is_approved'] as bool? ?? false,
    );
  }
}
