import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/transaction_model.dart';
import '../../core/models/ingredient_model.dart';
import '../../core/models/attendance_log_model.dart';
import '../../core/models/inventory_log_model.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/session_user.dart';
import '../../core/services/supabase_sync_service.dart';
import '../../core/bloc/connectivity/connectivity_cubit.dart';
import '../../config/theme_config.dart';

class DashboardTab extends StatefulWidget {
  final VoidCallback onGoToInventory;
  final VoidCallback onGoToStaff;

  const DashboardTab({
    super.key,
    required this.onGoToInventory,
    required this.onGoToStaff,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  
  @override
  Widget build(BuildContext context) {
    final user = SessionUser.current;

    return ValueListenableBuilder(
      valueListenable: HiveService.transactionBox.listenable(),
      builder: (context, Box<TransactionModel> txnBox, _) {
        return ValueListenableBuilder(
          valueListenable: HiveService.attendanceBox.listenable(),
          builder: (context, Box<AttendanceLogModel> attBox, _) {
            return ValueListenableBuilder(
              valueListenable: HiveService.ingredientBox.listenable(),
              builder: (context, Box<IngredientModel> ingBox, _) {
                
                // --- DATA CALCULATION ---
                final today = DateTime.now();
                
                final todayTxns = txnBox.values.where((t) {
                  return t.dateTime.year == today.year &&
                      t.dateTime.month == today.month &&
                      t.dateTime.day == today.day &&
                      !t.isVoid;
                }).toList();

                final totalSales = todayTxns.fold(0.0, (sum, t) => sum + t.totalAmount);
                final orderCount = todayTxns.length;

                final lowStockCount = ingBox.values
                    .where((i) => i.quantity <= i.reorderLevel)
                    .length;

                final activeStaffCount = attBox.values.where((l) {
                   return l.date.year == today.year && 
                          l.date.month == today.month && 
                          l.date.day == today.day &&
                          l.timeOut == null;
                }).length;

                return Scaffold(
                  backgroundColor: Colors.grey.shade50,
                  body: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. GRADIENT HEADER
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                ThemeConfig.primaryGreen,
                                ThemeConfig.secondaryGreen,
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              // ROW 1: Greeting + Online Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Good ${_getTimeOfDay()}",
                                        style: const TextStyle(color: ThemeConfig.white, fontSize: 16),
                                      ),
                                      Text(
                                        user?.fullName ?? "Manager",
                                        style: const TextStyle(
                                          color: ThemeConfig.white, 
                                          fontSize: 22, 
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
                                  ),
                                  BlocBuilder<ConnectivityCubit, bool>(
                                    builder: (context, isOnline) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: ThemeConfig.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: ThemeConfig.white.withValues(alpha: 0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isOnline ? Icons.wifi : Icons.wifi_off, 
                                              color: isOnline ? Colors.lightGreenAccent : Colors.redAccent, 
                                              size: 20
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isOnline ? "Online" : "Offline",
                                              style: const TextStyle(
                                                color: ThemeConfig.white, 
                                                fontSize: 14, 
                                                fontWeight: FontWeight.bold
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // ROW 2: The White Hero Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: ThemeConfig.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "TODAY'S TOTAL REVENUE",
                                      style: TextStyle(
                                        color: ThemeConfig.secondaryGreen,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      NumberFormat.currency(symbol: "₱").format(totalSales),
                                      style: const TextStyle(
                                        color: ThemeConfig.primaryGreen,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w700,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 2. STATUS TRIO (Horizontal Scroll)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Text(
                            "Overview", 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              _buildStatusCard(
                                title: "ORDERS",
                                value: "$orderCount",
                                subtext: "Served Today",
                                icon: Icons.receipt_long,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              _buildStatusCard(
                                title: "INVENTORY",
                                value: lowStockCount == 0 ? "OK" : "$lowStockCount",
                                subtext: lowStockCount == 0 ? "Healthy" : "Alerts",
                                icon: lowStockCount == 0 ? Icons.check_circle : Icons.warning_rounded,
                                color: lowStockCount == 0 ? Colors.green : Colors.orange,
                                isAlert: lowStockCount > 0,
                                onTap: widget.onGoToInventory,
                              ),
                              const SizedBox(width: 12),
                              _buildStatusCard(
                                title: "ATTENDANCE",
                                value: "$activeStaffCount",
                                subtext: "Active Now",
                                icon: Icons.people,
                                color: Colors.purple,
                                onTap: widget.onGoToStaff,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 3. QUICK ACTIONS
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Text(
                            "Quick Actions", 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _buildActionChip(
                                context, 
                                icon: Icons.add_box_outlined, 
                                label: "Receive Stock", 
                                onTap: widget.onGoToInventory
                              ),
                              const SizedBox(width: 10),
                              _buildActionChip(
                                context, 
                                icon: Icons.verified_user_outlined, 
                                label: "Verify Staff", 
                                onTap: widget.onGoToStaff
                              ),
                              const SizedBox(width: 10),
                              _buildActionChip(
                                context, 
                                icon: Icons.sync, 
                                label: "Sync Data", 
                                onTap: () => _runSync(context)
                              ),
                              const SizedBox(width: 10),
                              _buildActionChip(
                                context, 
                                icon: Icons.history, 
                                label: "Audit Logs", 
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Audit Logs: Coming Soon"))
                                  );
                                }
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 4. RECENT ACTIVITY
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Text(
                            "Recent Activity", 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRecentActivityFeed(),
                        
                        const SizedBox(height: 40), // Bottom Spacing
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 🎨 WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildStatusCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    bool isAlert = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 130, // Consistent width for horizontal scroll
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAlert ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isAlert ? Border.all(color: Colors.red.shade100) : Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAlert ? Colors.white : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: isAlert ? Colors.red : color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: isAlert ? Colors.red : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5
                ),
              ),
              Text(
                subtext,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, {
    required IconData icon, 
    required String label, 
    required VoidCallback onTap
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: ThemeConfig.primaryGreen),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: Colors.grey.shade300)
      ),
      onPressed: onTap,
    );
  }

  Widget _buildRecentActivityFeed() {
    final List<dynamic> combined = [];
    final txns = HiveService.transactionBox.values.toList();
    combined.addAll(txns);
    final logs = HiveService.logsBox.values.toList();
    combined.addAll(logs);
    final atts = HiveService.attendanceBox.values.toList();
    combined.addAll(atts);

    combined.sort((a, b) {
      DateTime timeA = DateTime(1970);
      if (a is TransactionModel) timeA = a.dateTime;
      if (a is InventoryLogModel) timeA = a.dateTime;
      if (a is AttendanceLogModel) timeA = a.timeIn;

      DateTime timeB = DateTime(1970);
      if (b is TransactionModel) timeB = b.dateTime;
      if (b is InventoryLogModel) timeB = b.dateTime;
      if (b is AttendanceLogModel) timeB = b.timeIn;

      return timeB.compareTo(timeA);
    });

    final displayItems = combined.take(10).toList();

    if (displayItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text("No activity yet today.", style: TextStyle(color: Colors.grey))),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: displayItems.map((item) {
          return _buildFeedItem(item);
        }).toList(),
      ),
    );
  }

  Widget _buildFeedItem(dynamic item) {
    IconData icon;
    Color color;
    String title;
    String subtitle;
    DateTime time;

    if (item is TransactionModel) {
      icon = Icons.point_of_sale;
      color = Colors.blue;
      title = "Sale: ₱${item.totalAmount.toStringAsFixed(0)}";
      subtitle = "${item.items.length} items • ${item.paymentMethod}";
      time = item.dateTime;
    } else if (item is InventoryLogModel) {
      final isAdd = item.changeAmount > 0;
      icon = isAdd ? Icons.add_box : Icons.indeterminate_check_box;
      color = isAdd ? Colors.green : Colors.orange;
      title = "${item.ingredientName} ${isAdd ? '+' : ''}${item.changeAmount} ${item.unit}";
      subtitle = "${item.action} by ${item.userName}";
      time = item.dateTime;
    } else if (item is AttendanceLogModel) {
      icon = Icons.badge;
      color = Colors.purple;
      final user = HiveService.userBox.get(item.userId);
      title = "${user?.fullName ?? 'Staff'} Clocked In";
      subtitle = item.timeOut == null ? "Shift Active" : "Shift Ended";
      time = item.timeIn;
    } else {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          trailing: Text(
            DateFormat('h:mm a').format(time),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        const Divider(height: 1, indent: 60, endIndent: 20, color: Colors.black12),
      ],
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Morning";
    if (hour < 17) return "Afternoon";
    return "Evening";
  }

  Future<void> _runSync(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Syncing Data...")));
    try {
      await SupabaseSyncService.restoreFromCloud();
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Sync Complete")));
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }
}