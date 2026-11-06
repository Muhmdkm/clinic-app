import 'package:flutter/material.dart';

import 'models.dart';
import 'store.dart';

// ---------- Dashboard ----------

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.store});

  final ClinicStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final today = dateKey(DateTime.now());
        final todays = store.surgeries.where((s) => s.date == today).toList()
          ..sort((a, b) => a.time.compareTo(b.time));
        final upcoming = store.surgeries
            .where((s) => s.status == SurgeryStatus.scheduled && s.date.compareTo(today) > 0)
            .length;
        final done = store.surgeries.where((s) => s.status == SurgeryStatus.done).length;

        return Scaffold(
          appBar: AppBar(title: const Text('لوحة التحكم')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (store.isDemo)
                Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: ListTile(
                    title: const Text('هذه بيانات تجريبية للعرض فقط'),
                    trailing: TextButton(onPressed: store.reset, child: const Text('مسح')),
                  ),
                ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatTile(value: '${store.patients.length}', label: 'إجمالي المرضى'),
                  _StatTile(value: '${todays.length}', label: 'عمليات اليوم'),
                  _StatTile(value: '$upcoming', label: 'عمليات قادمة'),
                  _StatTile(value: '$done', label: 'عمليات مكتملة'),
                ],
              ),
              const SizedBox(height: 24),
              Text('جدول اليوم', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (todays.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('لا توجد عمليات مجدولة اليوم')),
                )
              else
                for (final s in todays) SurgeryTile(store: store, surgery: s),
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ---------- Patients ----------

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key, required this.store});

  final ClinicStore store;

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String _query = '';

  Future<void> _openAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPatientScreen(store: widget.store)),
    );
  }

  Future<void> _confirmDelete(Patient p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف ${p.name}؟'),
        content: const Text('سيتم حذف المريض وكل عملياته.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) widget.store.deletePatient(p.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final q = _query.trim();
        final list = widget.store.patients.where((p) =>
            q.isEmpty || p.name.contains(q) || p.phone.contains(q) || p.diagnosis.contains(q)).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('المرضى')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAdd,
            icon: const Icon(Icons.person_add),
            label: const Text('مريض جديد'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'ابحث بالاسم أو الهاتف أو التشخيص',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('لا يوجد مرضى مطابقون'))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        children: [
                          for (final p in list)
                            Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(p.name),
                                subtitle: Text(
                                  [
                                    if (p.diagnosis.isNotEmpty) p.diagnosis,
                                    if (p.age != null) '${p.age} سنة',
                                    if (p.phone.isNotEmpty) p.phone,
                                  ].join(' · '),
                                ),
                                trailing: IconButton(
                                  tooltip: 'حذف',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _confirmDelete(p),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key, required this.store});

  final ClinicStore store;

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _diagnosis = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _phone.dispose();
    _diagnosis.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.store.addPatient(
      name: _name.text.trim(),
      age: int.tryParse(_age.text.trim()),
      phone: _phone.text.trim(),
      diagnosis: _diagnosis.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مريض جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب اسم المريض' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'السن', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _diagnosis,
              decoration: const InputDecoration(labelText: 'التشخيص', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('حفظ')),
          ],
        ),
      ),
    );
  }
}

// ---------- Surgeries ----------

class SurgeriesScreen extends StatelessWidget {
  const SurgeriesScreen({super.key, required this.store});

  final ClinicStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = [...store.surgeries]
          ..sort((a, b) => (a.date + a.time).compareTo(b.date + b.time));
        return Scaffold(
          appBar: AppBar(title: const Text('العمليات')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddSurgeryScreen(store: store)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('جدولة عملية'),
          ),
          body: list.isEmpty
              ? const Center(child: Text('لم تُجدول أي عمليات بعد'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    for (final s in list) SurgeryTile(store: store, surgery: s, editable: true),
                  ],
                ),
        );
      },
    );
  }
}

class SurgeryTile extends StatelessWidget {
  const SurgeryTile({super.key, required this.store, required this.surgery, this.editable = false});

  final ClinicStore store;
  final Surgery surgery;
  final bool editable;

  void _openChecklist(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurgeryChecklistScreen(store: store, surgeryId: surgery.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = store.patientById(surgery.patientId);
    final chip = Chip(label: Text(surgery.status.label));
    final checklistInfo =
        'قائمة التحقق ${surgery.checklistDone}/${surgeryChecklistItems.length}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        isThreeLine: true,
        onTap: editable ? () => _openChecklist(context) : null,
        title: Text(surgery.type),
        subtitle: Text(
          '${patient?.name ?? 'مريض محذوف'} · ${surgery.surgeon}\n'
          '${surgery.date} ${surgery.time} · $checklistInfo',
        ),
        trailing: editable
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<SurgeryStatus>(
                    tooltip: 'تغيير الحالة',
                    onSelected: (s) {
                      final ok = store.setStatus(surgery.id, s);
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('أكمل قائمة التحقق قبل تحديد العملية كمكتملة')),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      for (final s in SurgeryStatus.values)
                        PopupMenuItem(value: s, child: Text(s.label)),
                    ],
                    child: chip,
                  ),
                  IconButton(
                    tooltip: 'حذف',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => store.deleteSurgery(surgery.id),
                  ),
                ],
              )
            : chip,
      ),
    );
  }
}

class SurgeryChecklistScreen extends StatelessWidget {
  const SurgeryChecklistScreen({super.key, required this.store, required this.surgeryId});

  final ClinicStore store;
  final String surgeryId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final index = store.surgeries.indexWhere((s) => s.id == surgeryId);
        if (index == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('قائمة التحقق')),
            body: const Center(child: Text('العملية غير موجودة')),
          );
        }
        final s = store.surgeries[index];
        final total = surgeryChecklistItems.length;

        return Scaffold(
          appBar: AppBar(title: const Text('قائمة التحقق')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(s.type, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('${s.checklistDone} من $total مكتمل'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: s.checklistDone / total),
              const SizedBox(height: 12),
              for (var i = 0; i < total; i++)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(surgeryChecklistItems[i]),
                  value: s.checklist[i],
                  onChanged: (_) => store.toggleChecklist(surgeryId, i),
                ),
              const SizedBox(height: 12),
              Text(
                'لا يمكن تحديد العملية كمكتملة إلا بعد إكمال كل البنود.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class AddSurgeryScreen extends StatefulWidget {
  const AddSurgeryScreen({super.key, required this.store});

  final ClinicStore store;

  @override
  State<AddSurgeryScreen> createState() => _AddSurgeryScreenState();
}

class _AddSurgeryScreenState extends State<AddSurgeryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _type = TextEditingController();
  final _surgeon = TextEditingController();
  String? _patientId;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _type.dispose();
    _surgeon.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.store.addSurgery(
      patientId: _patientId!,
      type: _type.text.trim(),
      date: dateKey(_date),
      time: timeKey(_time.hour, _time.minute),
      surgeon: _surgeon.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final patients = widget.store.patients;
    return Scaffold(
      appBar: AppBar(title: const Text('جدولة عملية')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _patientId,
              decoration: const InputDecoration(labelText: 'المريض', border: OutlineInputBorder()),
              items: [
                for (final p in patients) DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => _patientId = v),
              validator: (v) => v == null ? 'اختر المريض' : null,
            ),
            if (patients.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('أضف مريضاً أولاً من تبويب المرضى'),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _type,
              decoration: const InputDecoration(labelText: 'نوع العملية', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب نوع العملية' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _surgeon,
              decoration: const InputDecoration(labelText: 'الجراح', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              title: const Text('التاريخ'),
              subtitle: Text(dateKey(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              title: const Text('الوقت'),
              subtitle: Text(timeKey(_time.hour, _time.minute)),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: patients.isEmpty ? null : _save, child: const Text('حفظ الموعد')),
          ],
        ),
      ),
    );
  }
}
