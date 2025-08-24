import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:auralearn/components/toast.dart';

class DeleteConfirmationDialog extends StatefulWidget {
  final String userName;
  final String userId;

  const DeleteConfirmationDialog({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  bool _isLoading = false;

  Future<void> _handleDeleteUser() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).delete();
      if (!mounted) return;
      Toast.show(context, 'User deleted successfully!', type: ToastType.success);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      Toast.show(context, 'Failed to delete user.', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
          const SizedBox(width: 10),
          const Text('Delete User', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white70, height: 1.5),
          children: [
            const TextSpan(text: 'Are you sure you want to permanently delete '),
            TextSpan(text: widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const TextSpan(text: '? This action cannot be undone.'),
          ],
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
          onPressed: _isLoading ? null : _handleDeleteUser,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Delete'),
        ),
      ],
    );
  }
}