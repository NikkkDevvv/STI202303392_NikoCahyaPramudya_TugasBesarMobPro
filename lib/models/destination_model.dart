class Destination {
  final int? id;
  final String name;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final String openTime;
  final String? imagePath;

  Destination({
    this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    this.imagePath,
  });

  factory Destination.fromMap(Map<String, dynamic> json) {
    return Destination(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      openTime: json['openTime'],
      imagePath: json['imagePath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'openTime': openTime,
      'imagePath': imagePath,
    };
  }
}