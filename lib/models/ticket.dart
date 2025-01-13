class Ticket {
  final int? id;
  final String code;
  final DateTime dateAdded;

  Ticket({
    this.id,
    required this.code, 
    required this.dateAdded,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'],
      code: map['code'],
      dateAdded: DateTime.parse(map['dateAdded']),
    );
  }
}