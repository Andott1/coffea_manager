import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/models/attendance_log_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/hive_service.dart';
import '../../config/theme_config.dart';
import 'attendance_verification_sheet.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  // 0 = Today, 1 = History
  int _viewIndex = 0;
  String _searchQuery = "";
  DateTimeRange? _historyDateRange;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.attendanceBox.listenable(),
      builder: (context, Box<AttendanceLogModel> box, _) {
        final allLogs = box.values.toList();
        
        // --- 1. Compute Stats for Hero Card (Today Only) ---
        final today = DateTime.now();
        final todayLogs = allLogs.where((l) => 
          l.date.year == today.year && 
          l.date.month == today.month && 
          l.date.day == today.day
        ).toList();

        int onFloor = 0;
        int onBreak = 0;
        int completed = 0;

        for (var log in todayLogs) {
          if (log.timeOut != null) {
            completed++;
          } else if (log.breakStart != null && log.breakEnd == null) {
            onBreak++;
          } else {
            onFloor++;
          }
        }

        // --- 2. Filter Pending Reviews (All Time) ---
        final pendingLogs = allLogs.where((l) => !l.isVerified).toList();

        return Column(
          children: [
            // SCROLLABLE TOP SECTION (Hero + Actions)
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildHeroStatusCard(onFloor, onBreak, completed),
                  
                  // Dynamic Action Section
                  if (pendingLogs.isNotEmpty)
                    _buildActionSection(pendingLogs),

                  // Segmented Toggle (Today vs History)
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

            // LIST CONTENT
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

  // ---------------------------------------------------------------------------
  // 🦸‍♂️ HERO SECTION
  // ---------------------------------------------------------------------------
  Widget _buildHeroStatusCard(int onFloor, int onBreak, int completed) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ThemeConfig.primaryGreen, ThemeConfig.secondaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeConfig.primaryGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "STAFF ON FLOOR",
                    style: TextStyle(
                      color: Colors.white70, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.0
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$onFloor Active",
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 28, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
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
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label, 
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ⚠️ ACTION SECTION (Pending Reviews)
  // ---------------------------------------------------------------------------
  Widget _buildActionSection(List<AttendanceLogModel> pendingLogs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            // Filter view to pending only or show a modal? 
            // For now, let's just highlight them in the list or assume they are at top.
            // A simple approach: Switch to History (or Today) and scroll?
            // BETTER: Show a bottom sheet with just the pending ones to clear them fast.
            _showPendingSheet(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${pendingLogs.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Verification Needed",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                      ),
                      Text(
                        "Staff logs require approval",
                        style: TextStyle(fontSize: 12, color: Colors.brown),
                      ),
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

  // ---------------------------------------------------------------------------
  // 📋 LIST SECTIONS
  // ---------------------------------------------------------------------------
  
  Widget _buildTodayList(List<AttendanceLogModel> logs) {
    if (logs.isEmpty) {
      return _buildEmptyState(Icons.today, "No attendance activity today");
    }
    // Sort: Active first, then by time
    logs.sort((a, b) {
      if (a.timeOut == null && b.timeOut != null) return -1;
      if (a.timeOut != null && b.timeOut == null) return 1;
      return b.timeIn.compareTo(a.timeIn);
    });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildLogCard(logs[index]),
    );
  }

  Widget _buildHistoryList(List<AttendanceLogModel> allLogs) {
    // Exclude today? Or keep all? Usually History implies everything.
    // Let's filter out today to avoid duplication if user just toggled.
    final today = DateTime.now();
    var history = allLogs.where((l) => 
      l.date.year != today.year || 
      l.date.month != today.month || 
      l.date.day != today.day
    ).toList();
    
    // Sort Newest First
    history.sort((a, b) => b.date.compareTo(a.date));

    if (history.isEmpty) {
      return _buildEmptyState(Icons.history, "No past history records");
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildLogCard(history[index], showDate: true),
    );
  }

  Widget _buildLogCard(AttendanceLogModel log, {bool showDate = false}) {
    final user = HiveService.userBox.get(log.userId);
    final isPending = !log.isVerified;
    
    return Card(
      elevation: 0, // Flat style for modern look
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
              // Avatar
              CircleAvatar(
                backgroundColor: ThemeConfig.primaryGreen.withOpacity(0.1),
                child: Text(
                  user?.fullName.substring(0, 1).toUpperCase() ?? "?",
                  style: const TextStyle(color: ThemeConfig.primaryGreen, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? "Unknown ID: ${log.userId}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${showDate ? DateFormat('MMM dd • ').format(log.date) : ''}${DateFormat('h:mm a').format(log.timeIn)} - ${log.timeOut != null ? DateFormat('h:mm a').format(log.timeOut!) : 'Active'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              // Status Pill
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text("Review", style: TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                )
              else if (log.rejectionReason != null)
                 const Icon(Icons.cancel, color: Colors.red, size: 20)
              else
                 const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🛠 HELPERS
  // ---------------------------------------------------------------------------
  
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
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? ThemeConfig.primaryGreen : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showPendingSheet(BuildContext context) { // ✅ Removed list argument
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            // ✅ Wrap in ValueListenableBuilder to react to changes immediately
            return ValueListenableBuilder(
              valueListenable: HiveService.attendanceBox.listenable(),
              builder: (context, Box<AttendanceLogModel> box, _) {
                // Re-fetch pending logs dynamically
                final pendingLogs = box.values.where((l) => !l.isVerified).toList();
                
                // Sort by date (Oldest first usually makes sense for backlog, or Newest)
                pendingLogs.sort((a, b) => b.timeIn.compareTo(a.timeIn));

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Pending Verifications (${pendingLogs.length})", 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                          if (pendingLogs.isEmpty)
                             const Icon(Icons.check_circle, color: Colors.green)
                        ],
                      ),
                    ),
                    Expanded(
                      child: pendingLogs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_turned_in, size: 60, color: Colors.grey.shade300),
                                  const SizedBox(height: 10),
                                  const Text("All caught up!", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: pendingLogs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) => _buildLogCard(pendingLogs[index], showDate: true),
                            ),
                    ),
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