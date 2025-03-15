class Reminder {
  String id; // You can use this for uniquely identifying each reminder
  final String message;
  final DateTime dateTime;

  Reminder({
    required this.id,
    required this.message,
    required this.dateTime,
  });

  Reminder.fromMap(Map<String, dynamic> data)
      : id = data['id'] ?? "",
        message = data['message'] ?? "",
        dateTime = data['dateTime'] != null
            ? data['dateTime'].toDate()
            : DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'dateTime': dateTime,
    };
  }
}
