import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Holds all clinic data and saves it on the device.
class ClinicStore extends ChangeNotifier {
  static const _key = 'clinic_data_v1';

  final List<Patient> patients = [];
  final List<Surgery> surgeries = [];
  bool isDemo = false;

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) {
      _seed();
      await _save();
    } else {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      isDemo = j['demo'] as bool? ?? false;
      patients.addAll((j['patients'] as List)
          .map((e) => Patient.fromJson(e as Map<String, dynamic>)));
      surgeries.addAll((j['surgeries'] as List)
          .map((e) => Surgery.fromJson(e as Map<String, dynamic>)));
    }
    notifyListeners();
  }

  Patient? patientById(String id) {
    for (final p in patients) {
      if (p.id == id) return p;
    }
    return null;
  }

  void addPatient({
    required String name,
    int? age,
    String phone = '',
    String diagnosis = '',
  }) {
    patients.add(Patient(
      id: _newId(),
      name: name,
      age: age,
      phone: phone,
      diagnosis: diagnosis,
    ));
    _changed();
  }

  void deletePatient(String id) {
    patients.removeWhere((p) => p.id == id);
    surgeries.removeWhere((s) => s.patientId == id);
    _changed();
  }

  void addSurgery({
    required String patientId,
    required String type,
    required String date,
    required String time,
    required String surgeon,
  }) {
    surgeries.add(Surgery(
      id: _newId(),
      patientId: patientId,
      type: type,
      date: date,
      time: time,
      surgeon: surgeon,
    ));
    _changed();
  }

  void setStatus(String surgeryId, SurgeryStatus status) {
    final i = surgeries.indexWhere((s) => s.id == surgeryId);
    if (i == -1) return;
    surgeries[i] = surgeries[i].copyWith(status: status);
    _changed();
  }

  void deleteSurgery(String id) {
    surgeries.removeWhere((s) => s.id == id);
    _changed();
  }

  void reset() {
    patients.clear();
    surgeries.clear();
    isDemo = false;
    _changed();
  }

  void _seed() {
    final p1 = _newId();
    final p2 = _newId();
    final p3 = _newId();
    final today = dateKey(DateTime.now());
    final tomorrow = dateKey(DateTime.now().add(const Duration(days: 1)));

    patients.addAll([
      Patient(id: p1, name: 'أحمد محمود', age: 54, phone: '01000000001', diagnosis: 'حصوة في المرارة'),
      Patient(id: p2, name: 'منى السيد', age: 38, phone: '01100000002', diagnosis: 'فتق إربي'),
      Patient(id: p3, name: 'محمد علي', age: 67, phone: '01200000003', diagnosis: 'تضخم البروستاتا'),
    ]);
    surgeries.addAll([
      Surgery(id: _newId(), patientId: p1, type: 'استئصال المرارة بالمنظار', date: today, time: '09:00', surgeon: 'د. خالد عمر'),
      Surgery(id: _newId(), patientId: p2, type: 'إصلاح الفتق الإربي', date: today, time: '11:30', surgeon: 'د. ياسمين فؤاد', status: SurgeryStatus.done),
      Surgery(id: _newId(), patientId: p3, type: 'استئصال البروستاتا بالمنظار', date: tomorrow, time: '10:00', surgeon: 'د. خالد عمر'),
    ]);
    isDemo = true;
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    final data = {
      'demo': isDemo,
      'patients': patients.map((p) => p.toJson()).toList(),
      'surgeries': surgeries.map((s) => s.toJson()).toList(),
    };
    await _prefs?.setString(_key, jsonEncode(data));
  }
}
