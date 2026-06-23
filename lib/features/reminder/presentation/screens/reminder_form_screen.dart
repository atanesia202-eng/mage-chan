import 'package:flutter/material.dart';
import '../../../../models/reminder_model.dart';
import '../../../../database/isar_service.dart';

class ReminderFormScreen extends StatefulWidget {
  final ReminderModel? existingReminder;
  
  const ReminderFormScreen({super.key, this.existingReminder});

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final _titleController = TextEditingController();
  
  // Now using a list of times
  final List<TimeOfDay> _selectedTimes = [TimeOfDay.now()];
  
  String _repeatType = 'daily'; // 'daily', 'custom', 'specific_date'
  
  // Custom Days State
  final List<bool> _selectedDays = List.generate(7, (_) => false);
  final List<String> _dayNames = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
  
  // Specific Date State
  DateTime? _specificDate;

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      final r = widget.existingReminder!;
      _titleController.text = r.title;
      
      _selectedTimes.clear();
      for (final timeString in r.allTimes) {
        final timeParts = timeString.split(':');
        if (timeParts.length == 2) {
          _selectedTimes.add(TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])));
        }
      }
      if (_selectedTimes.isEmpty) {
        _selectedTimes.add(TimeOfDay.now());
      }
      
      _repeatType = r.repeatType;
      if (r.customDaysList != null) {
        for (int day in r.customDaysList!) {
          _selectedDays[day - 1] = true;
        }
      }
      if (r.specificDate != null) {
        _specificDate = DateTime.fromMillisecondsSinceEpoch(r.specificDate!);
      }
    }
  }

  void _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกหัวข้อ')));
      return;
    }

    final reminder = widget.existingReminder ?? ReminderModel();
    reminder.title = _titleController.text;
    
    // Sort times first
    _selectedTimes.sort((a, b) {
      final aMin = a.hour * 60 + a.minute;
      final bMin = b.hour * 60 + b.minute;
      return aMin.compareTo(bMin);
    });

    // Extract primary time and additional times
    final h0 = _selectedTimes[0].hour.toString().padLeft(2, '0');
    final m0 = _selectedTimes[0].minute.toString().padLeft(2, '0');
    reminder.time = "$h0:$m0";
    
    reminder.additionalTimes = [];
    for (int i = 1; i < _selectedTimes.length; i++) {
      final h = _selectedTimes[i].hour.toString().padLeft(2, '0');
      final m = _selectedTimes[i].minute.toString().padLeft(2, '0');
      reminder.additionalTimes.add("$h:$m");
    }

    reminder.repeatType = _repeatType;

    if (_repeatType == 'custom') {
      List<int> customDays = [];
      for (int i = 0; i < 7; i++) {
        if (_selectedDays[i]) customDays.add(i + 1);
      }
      reminder.customDaysList = customDays;
    } else {
      reminder.customDaysList = null;
    }

    if (_repeatType == 'specific_date' && _specificDate != null) {
      reminder.specificDate = _specificDate!.millisecondsSinceEpoch;
    } else {
      reminder.specificDate = null;
    }

    await IsarService.saveReminder(reminder);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกสำเร็จ!')));
      Navigator.pop(context);
    }
  }

  void _addNewTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      setState(() {
        _selectedTimes.add(time);
        // Sort after adding
        _selectedTimes.sort((a, b) {
          final aMin = a.hour * 60 + a.minute;
          final bMin = b.hour * 60 + b.minute;
          return aMin.compareTo(bMin);
        });
      });
    }
  }

  void _editTime(int index) async {
    final time = await showTimePicker(context: context, initialTime: _selectedTimes[index]);
    if (time != null) {
      setState(() {
        _selectedTimes[index] = time;
        // Sort after editing
        _selectedTimes.sort((a, b) {
          final aMin = a.hour * 60 + a.minute;
          final bMin = b.hour * 60 + b.minute;
          return aMin.compareTo(bMin);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งแจ้งเตือน'),
        actions: [
          if (widget.existingReminder != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('ลบการแจ้งเตือน'),
                    content: const Text('คุณต้องการลบการแจ้งเตือนนี้ใช่หรือไม่?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ยกเลิก'),
                      ),
                      TextButton(
                        onPressed: () {
                          IsarService.deleteReminder(widget.existingReminder!.id);
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close form
                        },
                        child: const Text('ลบ', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'หัวข้อที่ต้องการแจ้งเตือน'),
            ),
            const SizedBox(height: 24),
            
            // Times Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('เวลาแจ้งเตือน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: _addNewTime,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('เพิ่มเวลา'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(_selectedTimes.length, (index) {
                final time = _selectedTimes[index];
                return InputChip(
                  label: Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                  avatar: Icon(Icons.access_time, size: 18, color: theme.colorScheme.onSecondaryContainer),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  deleteIcon: _selectedTimes.length > 1 ? const Icon(Icons.close, size: 18) : null,
                  onDeleted: _selectedTimes.length > 1 ? () {
                    setState(() {
                      _selectedTimes.removeAt(index);
                    });
                  } : null,
                  onPressed: () => _editTime(index),
                );
              }),
            ),
            const SizedBox(height: 24),
            
            DropdownButtonFormField<String>(
              initialValue: _repeatType,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('แจ้งเตือนทุกวัน')),
                DropdownMenuItem(value: 'custom', child: Text('เลือกวันในสัปดาห์ (จ-อา)')),
                DropdownMenuItem(value: 'specific_date', child: Text('ระบุวันที่ (ปฏิทิน)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _repeatType = val);
              },
              decoration: const InputDecoration(labelText: 'รูปแบบการแจ้งเตือน'),
            ),
            const SizedBox(height: 16),
            
            // Conditional UI based on repeatType
            if (_repeatType == 'custom')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('เลือกวันที่ต้องการให้แจ้งเตือน', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: List.generate(7, (index) {
                      return FilterChip(
                        label: Text(_dayNames[index]),
                        selected: _selectedDays[index],
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedDays[index] = selected;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              
            if (_repeatType == 'specific_date')
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: const Text('วันที่ต้องการนัดหมาย'),
                subtitle: Text(_specificDate != null 
                  ? "${_specificDate!.day}/${_specificDate!.month}/${_specificDate!.year}" 
                  : "กรุณาเลือกวันที่"),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _specificDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _specificDate = date);
                  }
                },
              ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                onPressed: _save,
                child: Text('บันทึก', style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
