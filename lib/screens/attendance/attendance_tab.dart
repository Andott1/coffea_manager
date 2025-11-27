import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/attendance_log_model.dart';
import '../../core/models/user_model.dart';
import '../../core/models/payroll_record_model.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/supabase_sync_service.dart';
import '../../core/services/session_user.dart';
import '../../config/theme_config.dart';
import 'attendance_verification_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAIN STAFF TAB (CONTROLLER)
// ─────────────────────────────────────────────────────────────────────────────
class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. TOP NAV (Attendance vs Payroll)
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _mainTabController,
            labelColor: ThemeConfig.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: ThemeConfig.primaryGreen,
            tabs: const [
              Tab(text: "Attendance"),
              Tab(text: "Payroll"),
            ],
          ),
        ),

        // 2. CONTENT
        Expanded(
          child: TabBarView(
            controller: _mainTabController,
            children: const [
              _AttendanceDashboard(), // The "Waterfall" View
              _PayrollDashboard(),    // The New Payroll View
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: ATTENDANCE DASHBOARD (Daily Ops)
// ─────────────────────────────────────────────────────────────────────────────
class _AttendanceDashboard extends StatefulWidget {
  const _AttendanceDashboard();

  @override
  State<_AttendanceDashboard> createState() => _AttendanceDashboardState();
}

class _AttendanceDashboardState extends State<_AttendanceDashboard> {
  int _viewIndex = 0; // 0 = Today, 1 = History

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.attendanceBox.listenable(),
      builder: (context, Box<AttendanceLogModel> box, _) {
        final allLogs = box.values.toList();
        
        // Stats
        final today = DateTime.now();
        final todayLogs = allLogs.where((l) => 
          l.date.year == today.year && 
          l.date.month == today.month && 
          l.date.day == today.day
        ).toList();

        int onFloor = 0, onBreak = 0, completed = 0;
        for (var log in todayLogs) {
          if (log.timeOut != null) {
            completed++;
          } else if (log.breakStart != null && log.breakEnd == null) {
            onBreak++;
          }
          else {
            onFloor++;
          }
        }

        final pendingLogs = allLogs.where((l) => !l.isVerified).toList();

        return Column(
          children: [
            // CONTROL CENTER
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildHeroStatusCard(onFloor, onBreak, completed),
                  if (pendingLogs.isNotEmpty) _buildActionSection(context, pendingLogs),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildSegmentButton("Today's Activity", 0),
                          _buildSegmentButton("Past History", 1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // LIST
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: _viewIndex == 0 
                  ? _buildTodayList(todayLogs)
                  : _buildHistoryList(allLogs),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroStatusCard(int onFloor, int onBreak, int completed) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ThemeConfig.primaryGreen, ThemeConfig.secondaryGreen],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: ThemeConfig.primaryGreen.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("STAFF ON FLOOR", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 4),
                  Text("$onFloor Active", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.people, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatBadge(Icons.coffee, "$onBreak on Break", Colors.orangeAccent),
              const SizedBox(width: 12),
              _buildStatBadge(Icons.check_circle, "$completed Finished", Colors.lightGreenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, List<AttendanceLogModel> pendingLogs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showPendingSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  child: Text("${pendingLogs.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Verification Needed", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                      Text("Staff logs require approval", style: TextStyle(fontSize: 12, color: Colors.brown)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.orange),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayList(List<AttendanceLogModel> logs) {
    if (logs.isEmpty) return _buildEmptyState(Icons.today, "No activity today");
    logs.sort((a, b) => b.timeIn.compareTo(a.timeIn));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildLogCard(context, logs[index]),
    );
  }

  Widget _buildHistoryList(List<AttendanceLogModel> allLogs) {
    final today = DateTime.now();
    var history = allLogs.where((l) => l.date.year != today.year || l.date.month != today.month || l.date.day != today.day).toList();
    history.sort((a, b) => b.date.compareTo(a.date));
    if (history.isEmpty) return _buildEmptyState(Icons.history, "No history records");
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildLogCard(context, history[index], showDate: true),
    );
  }

  Widget _buildLogCard(BuildContext context, AttendanceLogModel log, {bool showDate = false}) {
    final user = HiveService.userBox.get(log.userId);
    final isPending = !log.isVerified;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AttendanceVerificationSheet(log: log, employee: user),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: ThemeConfig.primaryGreen.withValues(alpha: 0.1),
                child: Text(user?.fullName.substring(0, 1).toUpperCase() ?? "?", style: const TextStyle(color: ThemeConfig.primaryGreen, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("${showDate ? DateFormat('MMM dd • ').format(log.date) : ''}${DateFormat('h:mm a').format(log.timeIn)} - ${log.timeOut != null ? DateFormat('h:mm a').format(log.timeOut!) : 'Active'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (isPending) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                child: const Text("Review", style: TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
              ) else if (log.rejectionReason != null) const Icon(Icons.cancel, color: Colors.red, size: 20)
              else const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, int index) {
    final isSelected = _viewIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? ThemeConfig.primaryGreen : Colors.grey, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 48, color: Colors.grey.shade300), const SizedBox(height: 16), Text(message, style: const TextStyle(color: Colors.grey))]));
  }

  void _showPendingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false, initialChildSize: 0.6, maxChildSize: 0.9,
          builder: (context, scrollController) {
            return ValueListenableBuilder(
              valueListenable: HiveService.attendanceBox.listenable(),
              builder: (context, Box<AttendanceLogModel> box, _) {
                final pendingLogs = box.values.where((l) => !l.isVerified).toList();
                pendingLogs.sort((a, b) => b.timeIn.compareTo(a.timeIn));
                return Column(
                  children: [
                    Padding(padding: const EdgeInsets.all(20), child: Text("Pending Verifications (${pendingLogs.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    Expanded(child: pendingLogs.isEmpty ? _buildEmptyState(Icons.check_circle, "All caught up!") : ListView.separated(controller: scrollController, padding: const EdgeInsets.all(16), itemCount: pendingLogs.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) => _buildLogCard(context, pendingLogs[index], showDate: true))),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: PAYROLL DASHBOARD (Admin Only)
// ─────────────────────────────────────────────────────────────────────────────
class _PayrollDashboard extends StatefulWidget {
  const _PayrollDashboard();

  @override
  State<_PayrollDashboard> createState() => _PayrollDashboardState();
}

class _PayrollDashboardState extends State<_PayrollDashboard> {
  DateTimeRange? _selectedPeriod;
  List<_PayrollDraft>? _generatedDrafts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // FILTER BAR
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(_selectedPeriod == null ? "Select Pay Period" : "${DateFormat('MMM d').format(_selectedPeriod!.start)} - ${DateFormat('MMM d').format(_selectedPeriod!.end)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _selectedPeriod == null ? null : _generatePreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("GENERATE"),
              ),
            ],
          ),
        ),

        // CONTENT
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_generatedDrafts == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.monetization_on_outlined, size: 60, color: Colors.grey.shade300), const SizedBox(height: 10), const Text("Select a date range to generate payroll", style: TextStyle(color: Colors.grey))]),
      );
    }
    
    if (_generatedDrafts!.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade300), const SizedBox(height: 10), const Text("No unpaid, verified logs found for this period", style: TextStyle(color: Colors.grey))]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _generatedDrafts!.length,
      itemBuilder: (context, index) {
        final draft = _generatedDrafts![index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: ThemeConfig.secondaryGreen.withValues(alpha: 0.1),
              child: Text(draft.user.fullName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: ThemeConfig.primaryGreen)),
            ),
            title: Text(draft.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${draft.totalHours.toStringAsFixed(1)} hrs • ${draft.logs.length} shifts", style: const TextStyle(color: Colors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Est. Gross", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(NumberFormat.currency(symbol: "₱").format(draft.grossPay), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ThemeConfig.primaryGreen)),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: () => _openDetailSheet(draft),
          ),
        );
      },
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context, firstDate: DateTime(2023), lastDate: DateTime.now(),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: ThemeConfig.primaryGreen)), child: child!),
    );
    if (picked != null) setState(() => _selectedPeriod = picked);
  }

  void _generatePreview() {
    final start = _selectedPeriod!.start;
    final end = _selectedPeriod!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    
    final logs = HiveService.attendanceBox.values.where((l) {
      return l.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
             l.date.isBefore(end) &&
             l.isVerified && 
             l.payrollId == null && // Not yet paid
             l.timeOut != null;     // Completed shifts only
    }).toList();

    // Group by User
    final Map<String, List<AttendanceLogModel>> grouped = {};
    for (var log in logs) {
      if (!grouped.containsKey(log.userId)) grouped[log.userId] = [];
      grouped[log.userId]!.add(log);
    }

    final List<_PayrollDraft> drafts = [];
    grouped.forEach((userId, userLogs) {
      final user = HiveService.userBox.get(userId);
      if (user != null) {
        double hours = 0;
        double gross = 0;
        for (var l in userLogs) {
          final h = l.totalHoursWorked;
          hours += h;
          // Use snapshot if available, else current user rate
          final rate = l.hourlyRateSnapshot > 0 ? l.hourlyRateSnapshot : user.hourlyRate;
          gross += (h * rate);
        }
        drafts.add(_PayrollDraft(user: user, logs: userLogs, totalHours: hours, grossPay: gross));
      }
    });

    setState(() => _generatedDrafts = drafts);
  }

  void _openDetailSheet(_PayrollDraft draft) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PayrollDetailSheet(draft: draft, period: _selectedPeriod!),
    );

    if (result == true) {
      _generatePreview(); // Refresh list if marked as paid
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payroll saved and locked!"), backgroundColor: Colors.green));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYROLL DETAIL & ADJUSTMENT SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _PayrollDetailSheet extends StatefulWidget {
  final _PayrollDraft draft;
  final DateTimeRange period;

  const _PayrollDetailSheet({required this.draft, required this.period});

  @override
  State<_PayrollDetailSheet> createState() => _PayrollDetailSheetState();
}

class _PayrollDetailSheetState extends State<_PayrollDetailSheet> {
  final List<Map<String, dynamic>> _adjustments = [];
  bool _isProcessing = false;

  double get _totalAdjustment => _adjustments.fold(0.0, (sum, item) => sum + (item['amount'] as double));
  double get _netPay => widget.draft.grossPay + _totalAdjustment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(widget.draft.user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text("${DateFormat('MMM dd').format(widget.period.start)} - ${DateFormat('MMM dd').format(widget.period.end)}", style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          
          // Calculations
          _buildSummaryCard(),
          
          const SizedBox(height: 20),
          const Text("Adjustments", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // Adjustment List
          Expanded(
            child: ListView(
              children: [
                ..._adjustments.map((adj) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(adj['label']),
                  trailing: Text("${adj['amount'] > 0 ? '+' : ''}${adj['amount']}", style: TextStyle(color: adj['amount'] > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  leading: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red, size: 18), onPressed: () => setState(() => _adjustments.remove(adj))),
                )),
                OutlinedButton.icon(
                  onPressed: _showAddAdjustmentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Bonus or Deduction"),
                ),
                const Divider(height: 30),
                const Text("Shift Logs Included:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                ...widget.draft.logs.map((l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd').format(l.date), style: const TextStyle(fontSize: 12)),
                      Text("${l.totalHoursWorked.toStringAsFixed(1)} hrs", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
              ],
            ),
          ),

          // Footer Action
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isProcessing ? null : _markAsPaid,
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isProcessing 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : Text("MARK AS PAID (₱${_netPay.toStringAsFixed(2)})"),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _row("Total Hours", "${widget.draft.totalHours.toStringAsFixed(1)} hrs"),
          _row("Gross Pay", NumberFormat.currency(symbol: "₱").format(widget.draft.grossPay)),
          if (_adjustments.isNotEmpty) _row("Adjustments", NumberFormat.currency(symbol: "₱").format(_totalAdjustment), color: _totalAdjustment >= 0 ? Colors.green : Colors.red),
          const Divider(),
          _row("NET PAY", NumberFormat.currency(symbol: "₱").format(_netPay), isBold: true, size: 18),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color, double size = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: size, color: color ?? Colors.black)),
      ]),
    );
  }

  void _showAddAdjustmentDialog() {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    bool isDeduction = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text("Add Adjustment"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ChoiceChip(label: const Text("Bonus +"), selected: !isDeduction, onSelected: (v) => setDlgState(() => isDeduction = false)),
                    const SizedBox(width: 10),
                    ChoiceChip(label: const Text("Deduction -"), selected: isDeduction, onSelected: (v) => setDlgState(() => isDeduction = true), selectedColor: Colors.red.shade100),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description (e.g. Tips, Late)")),
                const SizedBox(height: 10),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount", prefixText: "₱ ")),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  final amt = double.tryParse(amountCtrl.text);
                  if (amt != null && descCtrl.text.isNotEmpty) {
                    setState(() {
                      _adjustments.add({
                        'label': descCtrl.text,
                        'amount': isDeduction ? -amt : amt,
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Add"),
              )
            ],
          );
        }
      ),
    );
  }

  Future<void> _markAsPaid() async {
    setState(() => _isProcessing = true);
    
    final payrollId = const Uuid().v4();
    final now = DateTime.now();

    // 1. Create Record
    final record = PayrollRecordModel(
      id: payrollId,
      userId: widget.draft.user.id,
      periodStart: widget.period.start,
      periodEnd: widget.period.end,
      totalHours: widget.draft.totalHours,
      grossPay: widget.draft.grossPay,
      netPay: _netPay,
      adjustmentsJson: jsonEncode(_adjustments),
      generatedAt: now,
      generatedBy: SessionUser.current?.username ?? 'Admin',
    );
    await HiveService.payrollBox.put(record.id, record);

    // 2. Lock Logs
    for (var log in widget.draft.logs) {
      log.payrollId = payrollId;
      await log.save();
      // Queue update for log
      SupabaseSyncService.addToQueue(
        table: 'attendance_logs',
        action: 'UPDATE',
        data: {'id': log.id, 'payroll_id': payrollId},
      );
    }

    // 3. Sync Record
    SupabaseSyncService.addToQueue(
      table: 'payroll_records',
      action: 'UPSERT',
      data: {
        'id': record.id,
        'user_id': record.userId,
        'period_start': record.periodStart.toIso8601String(),
        'period_end': record.periodEnd.toIso8601String(),
        'total_hours': record.totalHours,
        'gross_pay': record.grossPay,
        'net_pay': record.netPay,
        'adjustments_json': record.adjustmentsJson,
        'generated_at': record.generatedAt.toIso8601String(),
        'generated_by': record.generatedBy,
      },
    );

    if (mounted) Navigator.pop(context, true); // Return success
  }
}

// Helper Class for Transient Data
class _PayrollDraft {
  final UserModel user;
  final List<AttendanceLogModel> logs;
  final double totalHours;
  final double grossPay;
  _PayrollDraft({required this.user, required this.logs, required this.totalHours, required this.grossPay});
}