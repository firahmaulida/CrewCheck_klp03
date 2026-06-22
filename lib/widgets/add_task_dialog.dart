import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';

/// Popup "Tambah Tugas Baru" — dipanggil dari FAB ProjectDetailPage (hanya Ketua).
/// Anggota dipilih dari dropdown daftar member tim, lalu tugas baru
/// disimpan ke teams/{teamId}/tasks dengan assignedTo = uid anggota tsb.
void showAddTaskDialog(
  BuildContext context, {
  required String teamId,
  required List<Map<String, dynamic>> members,
  DateTime? defaultDate,
}) {
  final descriptionController = TextEditingController();
  String? selectedUid = members.isNotEmpty
      ? members.first['uid'] as String?
      : null;
  DateTime selectedDate = defaultDate ?? DateTime.now();
  bool isLoading = false;

  String selectedDateText() {
    return '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
  }

  Future<void> pickTaskDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(DateTime.now().year + 3),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: colorMerah)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      selectedDate = picked;
    }
  }

  showDialog(
    context: context,
    barrierColor: Colors.black26,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            final description = descriptionController.text.trim();
            if (selectedUid == null || description.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lengkapi anggota dan deskripsi tugas'),
                ),
              );
              return;
            }

            setState(() => isLoading = true);
            final snackBarMessenger = ScaffoldMessenger.of(context);
            final dialogNavigator = Navigator.of(context);
            final member = members.firstWhere(
              (m) => m['uid'] == selectedUid,
              orElse: () => {'name': 'Anggota'},
            );

            try {
              await FirebaseFirestore.instance
                  .collection('teams')
                  .doc(teamId)
                  .collection('tasks')
                  .add({
                    'title': description,
                    'description': description,
                    'assignedTo': selectedUid,
                    'assignedName': member['name'] ?? 'Anggota',
                    'completed': false,
                    'createdAt': FieldValue.serverTimestamp(),
                    'date': Timestamp.fromDate(selectedDate),
                  });

              if (!dialogContext.mounted) return;
              dialogNavigator.pop();
              _showSuccessToast(dialogContext);
            } catch (e) {
              setState(() => isLoading = false);
              snackBarMessenger.showSnackBar(
                SnackBar(content: Text('Gagal menambah tugas: $e')),
              );
            }
          }

          return Dialog(
            backgroundColor: colorBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Tambah Tugas Baru',
                      style: crewCheckTitleStyle(size: 24, color: colorMerah),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Nama Anggota', style: bodyTextStyle(size: 15)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorKuning,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedUid,
                        isExpanded: true,
                        items: members.map((m) {
                          return DropdownMenuItem<String>(
                            value: m['uid'] as String?,
                            child: Text(
                              m['name'] ?? 'Tanpa nama',
                              style: bodyTextStyle(size: 16),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedUid = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Deskripsi Pembagian Tugas',
                    style: bodyTextStyle(size: 15),
                  ),
                  const SizedBox(height: 6),
                  buildTextField(
                    hint: 'Deskripsi Pembagian Tugas',
                    icon: Icons.assignment_outlined,
                    controller: descriptionController,
                  ),
                  const SizedBox(height: 16),
                  Text('Tanggal Tugas', style: bodyTextStyle(size: 15)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final previousDate = selectedDate;
                      await pickTaskDate();
                      if (selectedDate != previousDate) {
                        setState(() {});
                      }
                    },
                    child: AbsorbPointer(
                      child: buildTextField(
                        hint: 'Pilih tanggal tugas',
                        icon: Icons.calendar_today,
                        controller: TextEditingController(
                          text: selectedDateText(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pop(dialogContext),
                        child: Text('Batal', style: bodyTextStyle(size: 15)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isLoading ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorBiru,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 10,
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Tambah',
                                style: bodyTextStyle(
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void _showSuccessToast(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black26,
    builder: (dialogContext) {
      final dialogNavigator = Navigator.of(dialogContext);
      Future.delayed(const Duration(seconds: 2), () {
        if (dialogNavigator.canPop()) dialogNavigator.pop();
      });
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: colorMerah,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Tugas baru berhasil ditambahkan',
                style: bodyTextStyle(size: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
}
