class Hotel {
  Hotel({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.country,
    this.imageUrl,
    this.address,
  });

  final String id;
  final String name;
  final String city;
  final String state;
  final String country;
  final String? imageUrl;
  final String? address;

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: (json['id'] ?? json['hotel_id'] ?? '').toString(),
      name: (json['name'] ?? json['hotel_name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      imageUrl: (json['image'] ?? json['image_url'])?.toString(),
      address: (json['address'])?.toString(),
    );
  }
}


