class AppUser {
  final String id;
  final String fullName;
  final String photoUrl;
  final String email;
  final String userRole;
  final double latitude;
  final double homeLat;
  final double longitude;
  final double homeLong;
  final String place;
  final String phone;
  final DateTime regTime;

  AppUser({
    required this.id,
    required this.fullName,
    required this.photoUrl,
    required this.email,
    required this.userRole,
    required this.latitude,
    required this.longitude,
    required this.homeLat,
    required this.homeLong,
    required this.place,
    required this.regTime,
    required this.phone,
  });

  AppUser.fromMap(Map<String, dynamic> data)
      : id = data['id'] ?? "",
        fullName = data['fullName'] ?? "nil",
        photoUrl = data['photoUrl'] ?? "nil",
        email = data['email'] ?? "nil",
        userRole = data['userRole'] ?? "patient",
        latitude = data['lat'] ?? 0.0,
        longitude = data['long'] ?? 0.0,
        homeLat = data['homeLat'] ?? 0.0,
        homeLong = data['homeLong'] ?? 0.0,
        phone = data['phone'] ?? "",
        place = data['place'] ?? "",
        regTime =
            data['regTime'] != null ? data['regTime'].toDate() : DateTime.now();

  Map<String, dynamic> toJson(keyword) {
    Map<String, dynamic> map = {
      'id': id,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'keyword': keyword,
      'email': email,
      'userRole': userRole,
      'lat': latitude,
      'long': longitude,
      'place': place,
      'phone': "+918137810031",
      'regTime': regTime,
    };
    // if (imgString != null) map['imgString'] = imgString!;
    return map;
  }
}
