class Ticket {
  final int? id;
  final String code;
  final String title;
  final DateTime dateAdded;

  Ticket({
    this.id,
    required this.code,
    required this.title,
    required this.dateAdded,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'],
      code: map['code'],
      title: map['title'],
      dateAdded: DateTime.parse(map['dateAdded']),
    );
  }
}