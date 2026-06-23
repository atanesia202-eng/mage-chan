import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';

enum _CallViewMode { daily, overview }

class _DayCallStats {
  final DateTime date;
  int incoming = 0;
  int outgoing = 0;
  int missed = 0;

  _DayCallStats(this.date);

  int get total => incoming + outgoing + missed;
}

class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({super.key});

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  List<CallLogEntry> _dayEntries = [];
  List<_DayCallStats> _monthOverview = [];
  bool _isLoading = true;
  _CallViewMode _viewMode = _CallViewMode.daily;

  late DateTime _selectedDate;
  late final DateTime _oldestDate;

  int _incoming = 0;
  int _outgoing = 0;
  int _missed = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _oldestDate = _selectedDate.subtract(const Duration(days: 29));
    _loadData();
  }

  List<DateTime> get _selectableDates {
    final dates = <DateTime>[];
    var cursor = _selectedDate;
    while (!cursor.isBefore(_oldestDate)) {
      dates.add(cursor);
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return dates;
  }

  Future<bool> _ensurePhonePermission() async {
    final status = await Permission.phone.status;
    if (status.isGranted) return true;

    final result = await Permission.phone.request();
    if (!result.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่ได้รับสิทธิ์เข้าถึงประวัติการโทร')),
      );
    }
    return result.isGranted;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (!await _ensurePhonePermission()) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (_viewMode == _CallViewMode.daily) {
        await _loadDailyLogs();
      } else {
        await _loadMonthOverview();
      }
    } catch (e) {
      debugPrint('Error loading call logs: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadDailyLogs() async {
    final startOfDay = _selectedDate;
    final endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
      999,
    );

    final entries = await CallLog.query(
      dateFrom: startOfDay.millisecondsSinceEpoch,
      dateTo: endOfDay.millisecondsSinceEpoch,
    );

    final list = entries.toList();
    var incoming = 0, outgoing = 0, missed = 0;

    for (final entry in list) {
      switch (entry.callType) {
        case CallType.incoming:
          incoming++;
        case CallType.outgoing:
          outgoing++;
        case CallType.missed:
          missed++;
        default:
          break;
      }
    }

    if (mounted) {
      setState(() {
        _dayEntries = list;
        _incoming = incoming;
        _outgoing = outgoing;
        _missed = missed;
        _total = list.length;
      });
    }
  }

  Future<void> _loadMonthOverview() async {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final entries = await CallLog.query(
      dateFrom: _oldestDate.millisecondsSinceEpoch,
      dateTo: end.millisecondsSinceEpoch,
    );

    final byDay = <String, _DayCallStats>{};

    for (final entry in entries) {
      if (entry.timestamp == null) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(entry.timestamp!);
      final dayKey = '${dt.year}-${dt.month}-${dt.day}';
      final stats = byDay.putIfAbsent(
        dayKey,
        () => _DayCallStats(DateTime(dt.year, dt.month, dt.day)),
      );

      switch (entry.callType) {
        case CallType.incoming:
          stats.incoming++;
        case CallType.outgoing:
          stats.outgoing++;
        case CallType.missed:
          stats.missed++;
        default:
          break;
      }
    }

    final overview = byDay.values.toList()
      ..sort((a, b) {
        final byTotal = b.total.compareTo(a.total);
        if (byTotal != 0) return byTotal;
        return b.date.compareTo(a.date);
      });

    if (mounted) {
      setState(() {
        _monthOverview = overview;
        _dayEntries = [];
        _incoming = overview.fold(0, (sum, d) => sum + d.incoming);
        _outgoing = overview.fold(0, (sum, d) => sum + d.outgoing);
        _missed = overview.fold(0, (sum, d) => sum + d.missed);
        _total = overview.fold(0, (sum, d) => sum + d.total);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _oldestDate,
      lastDate: DateTime.now(),
      helpText: 'เลือกวันที่ต้องการดู',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _viewMode = _CallViewMode.daily;
      });
      await _loadData();
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '-';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '${m}น. ${s}วิ.';
    return '${s}วิ.';
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDayLabel(DateTime date) {
    const thaiDays = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
    return '${date.day}/${date.month} ${thaiDays[date.weekday - 1]}';
  }

  String _formatFullDate(DateTime date) {
    const thaiMonths = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
    ];
    return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  IconData _callTypeIcon(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
      default:
        return Icons.phone;
    }
  }

  Color _callTypeColor(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return Colors.green;
      case CallType.outgoing:
        return Colors.blue;
      case CallType.missed:
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _callTypeLabel(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return 'สายเข้า';
      case CallType.outgoing:
        return 'โทรออก';
      case CallType.missed:
        return 'ไม่ได้รับ';
      default:
        return 'อื่นๆ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_viewMode == _CallViewMode.daily
            ? 'ประวัติการโทร'
            : 'ภาพรวม 30 วัน'),
        actions: [
          if (_viewMode == _CallViewMode.daily)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'เลือกวันที่',
              onPressed: _pickDate,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<_CallViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: _CallViewMode.daily,
                        label: Text('รายวัน'),
                        icon: Icon(Icons.today),
                      ),
                      ButtonSegment(
                        value: _CallViewMode.overview,
                        label: Text('ภาพรวม'),
                        icon: Icon(Icons.bar_chart),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (selection) async {
                      setState(() => _viewMode = selection.first);
                      await _loadData();
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_viewMode == _CallViewMode.daily) ...[
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectableDates.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final date = _selectableDates[index];
                          final selected = _isSameDay(date, _selectedDate);
                          return ChoiceChip(
                            label: Text(
                              _isToday(date) ? 'วันนี้' : _formatDayLabel(date),
                            ),
                            selected: selected,
                            onSelected: (_) async {
                              setState(() => _selectedDate = date);
                              await _loadDailyLogs();
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatFullDate(_selectedDate),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Text(
                      'สรุปย้อนหลัง 30 วัน — เรียงตามวันที่โทรมากที่สุด',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      _buildSummaryChip(context, 'สายเข้า', _incoming.toString(), Colors.green, Icons.call_received),
                      const SizedBox(width: 8),
                      _buildSummaryChip(context, 'โทรออก', _outgoing.toString(), Colors.blue, Icons.call_made),
                      const SizedBox(width: 8),
                      _buildSummaryChip(context, 'ไม่ได้รับ', _missed.toString(), Colors.redAccent, Icons.call_missed),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _viewMode == _CallViewMode.daily ? 'ทั้งหมดวันนี้:' : 'รวม 30 วัน:',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$_total สาย',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_viewMode == _CallViewMode.daily) ...[
                    Text('รายการทั้งหมด', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_dayEntries.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('ไม่มีประวัติการโทรวันนี้', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ..._dayEntries.map((entry) => _buildEntryTile(context, entry)),
                  ] else ...[
                    Text('สรุปรายวัน', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_monthOverview.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('ไม่มีประวัติการโทรใน 30 วันที่ผ่านมา', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ..._buildOverviewCards(context),
                  ],
                ],
              ),
            ),
    );
  }

  List<Widget> _buildOverviewCards(BuildContext context) {
    final theme = Theme.of(context);
    final maxTotal = _monthOverview.map((d) => d.total).fold(0, (a, b) => a > b ? a : b);

    return _monthOverview.map((day) {
      final ratio = maxTotal == 0 ? 0.0 : day.total / maxTotal;

      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            setState(() {
              _selectedDate = day.date;
              _viewMode = _CallViewMode.daily;
            });
            await _loadData();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isToday(day.date) ? 'วันนี้ — ${_formatFullDate(day.date)}' : _formatFullDate(day.date),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${day.total} สาย',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildMiniStat(Icons.call_received, Colors.green, day.incoming, 'เข้า'),
                    const SizedBox(width: 16),
                    _buildMiniStat(Icons.call_made, Colors.blue, day.outgoing, 'ออก'),
                    const SizedBox(width: 16),
                    _buildMiniStat(Icons.call_missed, Colors.redAccent, day.missed, 'miss'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMiniStat(IconData icon, Color color, int count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text('$label $count', style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildEntryTile(BuildContext context, CallLogEntry entry) {
    final theme = Theme.of(context);
    final color = _callTypeColor(entry.callType);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(_callTypeIcon(entry.callType), color: color, size: 20),
        ),
        title: Text(
          entry.name ?? entry.number ?? 'ไม่ทราบชื่อ',
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_callTypeLabel(entry.callType)} • ${_formatTime(entry.timestamp)} • ${_formatDuration(entry.duration)}',
          style: TextStyle(color: color, fontSize: 12),
        ),
        trailing: Text(
          entry.number ?? '',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildSummaryChip(BuildContext context, String label, String count, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(count, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
