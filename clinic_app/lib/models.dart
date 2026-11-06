enum SurgeryStatus { scheduled, active, done, cancelled }

extension SurgeryStatusLabel on SurgeryStatus {
  String get label => switch (this) {
        SurgeryStatus.scheduled => 'مجدولة',
        SurgeryStatus.active => 'جارية',
        SurgeryStatus.done => 'مكتملة',
        SurgeryStatus.cancelled => 'ملغاة',
      };
}

/// Formats a date as yyyy-MM-dd so dates can be compared as strings.
String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String timeKey(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

class Patient {
  Patient({
    required this.id,
    required this.name,
    this.age,
    this.phone = '',
    this.diagnosis = '',
  });

  final String id;
  final String name;
  final int? age;
  final String phone;
  final String diagnosis;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'phone': phone,
        'diagnosis': diagnosis,
      };

  factory Patient.fromJson(Map<String, dynamic> j) => Patient(
        id: j['id'] as String,
        name: j['name'] as String,
        age: j['age'] as int?,
        phone: j['phone'] as String? ?? '',
        diagnosis: j['diagnosis'] as String? ?? '',
      );
}

class Surgery {
  Surgery({
    required this.id,
    required this.patientId,
    required this.type,
    required this.date,
    required this.time,
    required this.surgeon,
    this.status = SurgeryStatus.scheduled,
  });

  final String id;
  final String patientId;
  final String type;
  final String date; // yyyy-MM-dd
  final String time; // HH:mm
  final String surgeon;
  final SurgeryStatus status;

  Surgery copyWith({SurgeryStatus? status}) => Surgery(
        id: id,
        patientId: patientId,
        type: type,
        date: date,
        time: time,
        surgeon: surgeon,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'type': type,
        'date': date,
        'time': time,
        'surgeon': surgeon,
        'status': status.name,
      };

  factory Surgery.fromJson(Map<String, dynamic> j) => Surgery(
        id: j['id'] as String,
        patientId: j['patientId'] as String,
        type: j['type'] as String,
        date: j['date'] as String,
        time: j['time'] as String,
        surgeon: j['surgeon'] as String? ?? '',
        status: SurgeryStatus.values.byName(j['status'] as String),
      );
}
