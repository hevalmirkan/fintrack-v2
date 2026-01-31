/// ====================================================
/// PHASE 4 STEP 3 — CREATE GROUP SCREEN
/// ====================================================
///
/// This screen allows users to create a new shared expense group.
///
/// CRITICAL RULES:
/// - Exactly ONE GroupMember must have isCurrentUser = true
/// - "Ben" (currentUser) is ALWAYS present and non-removable
/// - Other members can be added by name
/// ====================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/shared_expense_models.dart';
import '../providers/shared_expense_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _memberNameController = TextEditingController();

  // Member list: First entry is ALWAYS "Ben" (currentUser)
  // CRITICAL: "Ben" cannot be removed
  final List<String> _memberNames = ['Ben'];

  @override
  void dispose() {
    _titleController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Yeni Grup Oluştur',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==================== GROUP TITLE ====================
            const Text('Grup Adı',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Yaz Tatili, Ev Arkadaşları...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF1E2230),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Grup adı gerekli';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ==================== MEMBERS SECTION ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Üyeler',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text('${_memberNames.length} üye',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),

            // Member chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _memberNames.asMap().entries.map((entry) {
                final index = entry.key;
                final name = entry.value;
                final isCurrentUser = index == 0; // First entry is always "Ben"

                return Chip(
                  label: Text(
                    isCurrentUser ? 'Ben (Sen)' : name,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.orange : Colors.white,
                      fontWeight:
                          isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  backgroundColor: isCurrentUser
                      ? Colors.orange.withValues(alpha: 0.2)
                      : const Color(0xFF1E2230),
                  side: BorderSide(
                    color: isCurrentUser ? Colors.orange : Colors.grey.shade700,
                  ),
                  // CRITICAL: "Ben" cannot be deleted
                  deleteIcon: isCurrentUser
                      ? null
                      : const Icon(Icons.close, size: 18, color: Colors.red),
                  onDeleted: isCurrentUser
                      ? null
                      : () => setState(() => _memberNames.removeAt(index)),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Add member input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Üye adı ekle...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: const Color(0xFF1E2230),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _addMember(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addMember,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              'En az 2 üye gerekli (sen dahil)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 32),

            // ==================== CREATE BUTTON ====================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _memberNames.length >= 2 ? _createGroup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Grup Oluştur',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addMember() {
    final name = _memberNameController.text.trim();
    if (name.isEmpty) return;

    // Prevent duplicate names
    if (_memberNames.map((n) => n.toLowerCase()).contains(name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bu isim zaten mevcut'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _memberNames.add(name);
      _memberNameController.clear();
    });
  }

  void _createGroup() {
    if (!_formKey.currentState!.validate()) return;
    if (_memberNames.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('En az 2 üye gerekli'), backgroundColor: Colors.red),
      );
      return;
    }

    final title = _titleController.text.trim();
    final now = DateTime.now();

    // ================================================================
    // CRITICAL: Build GroupMember list
    // - EXACTLY ONE member has isCurrentUser = true (index 0 = "Ben")
    // - All others have isCurrentUser = false
    // ================================================================
    final members = _memberNames.asMap().entries.map((entry) {
      final index = entry.key;
      final name = entry.value;
      final isCurrentUser =
          index == 0; // CRITICAL: Only first entry is currentUser

      return GroupMember(
        id: 'member_${now.millisecondsSinceEpoch}_$index',
        name: isCurrentUser ? 'Ben' : name,
        isCurrentUser: isCurrentUser, // ENFORCED: Only one true
        currentBalance: 0, // Starting balance is always 0
      );
    }).toList();

    // Validate: Exactly one currentUser (safety check)
    final currentUserCount = members.where((m) => m.isCurrentUser).length;
    if (currentUserCount != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Sistem hatası: currentUser=$currentUserCount'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Create the group
    final group = SharedGroup(
      id: 'group_${now.millisecondsSinceEpoch}',
      title: title,
      members: members,
      createdAt: now,
      isActive: true,
    );

    try {
      // Call provider to create group
      ref.read(sharedExpenseProvider.notifier).addGroup(group);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title grubu oluşturuldu ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } on SharedExpenseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Hata: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  }
}
