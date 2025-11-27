import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/attendance_log_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/supabase_sync_service.dart';
import '../../config/theme_config.dart';

class AttendanceVerificationSheet extends StatefulWidget {
  final AttendanceLogModel log;
  final UserModel? employee;

  const AttendanceVerificationSheet({
    super.key, 
    required this.log,
    required this.employee,
  });

  @override
  State<AttendanceVerificationSheet> createState() => _AttendanceVerificationSheetState();
}

class _AttendanceVerificationSheetState extends State<AttendanceVerificationSheet> {
  final TextEditingController _rejectReasonController = TextEditingController();
  bool _isRejecting = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // ✅ ROBUST VALIDATION: Determine Status
    final bool isVerified = widget.log.isVerified;
    final bool isRejected = !isVerified && widget.log.rejectionReason != null;
    final bool isPending = !isVerified && widget.log.rejectionReason == null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.brown.shade100,
                child: Text(
                  widget.employee?.fullName.substring(0, 1).toUpperCase() ?? "?",
                  style: const TextStyle(fontSize: 20, color: Colors.brown),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.employee?.fullName ?? "Unknown Employee",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${dateFormat.format(widget.log.date)} • ${timeFormat.format(widget.log.timeIn)}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Proof Image Area
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.hardEdge,
            child: widget.log.proofImage != null && widget.log.proofImage!.isNotEmpty
                ? Image.network(
                    widget.log.proofImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            Text("Image failed to load", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 40),
                        Text("No Proof Photo", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
          ),
          
          const SizedBox(height: 24),

          // 3. ACTION AREA (Conditional Rendering)
          if (isPending) ...[
            // === PENDING STATE: Show Buttons ===
            if (_isRejecting) ...[
              TextField(
                controller: _rejectReasonController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Reason for Rejection",
                  border: OutlineInputBorder(),
                  hintText: "e.g., Photo is blurry, Wrong uniform",
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _isRejecting = false),
                      child: const Text("Cancel"),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_rejectReasonController.text.isEmpty) return;
                        _finalize(isVerified: false, reason: _rejectReasonController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Confirm Reject"),
                    ),
                  ),
                ],
              )
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _isRejecting = true),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text("Reject", style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _finalize(isVerified: true),
                      icon: const Icon(Icons.check),
                      label: const Text("Verify"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConfig.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            // === COMPLETED STATE: Show Read-Only Status ===
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isVerified ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isVerified ? Colors.green.shade200 : Colors.red.shade200
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVerified ? Icons.check_circle : Icons.cancel, 
                        color: isVerified ? Colors.green : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isVerified ? "VERIFIED" : "REJECTED",
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: isVerified ? Colors.green.shade800 : Colors.red.shade800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  if (isRejected && widget.log.rejectionReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Reason: ${widget.log.rejectionReason}",
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
          
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Future<void> _finalize({required bool isVerified, String? reason}) async {
    // 1. Update Local Hive Data
    widget.log.isVerified = isVerified;
    widget.log.rejectionReason = reason;
    await widget.log.save(); 
    
    // 2. Push to Cloud Queue (Partial Update)
    SupabaseSyncService.addToQueue(
      table: 'attendance_logs',
      action: 'UPDATE', 
      data: {
        'id': widget.log.id,
        'is_verified': isVerified,
        'rejection_reason': reason,
      }
    );

    if (mounted) Navigator.pop(context);
  }
}