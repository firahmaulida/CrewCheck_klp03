import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime selectedDate = DateTime.now();

  final List<DateTime> dateOptions = List.generate(
    7,
    (index) => DateTime.now().add(Duration(days: index)),
  );

  String formatDate(DateTime date) {
    final dayNames = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jum\'at',
      'Sabtu',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${dayNames[date.weekday % 7]}';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> taskStream(DateTime date) {
    final selectedString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('date', isEqualTo: selectedString)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
      bottomNavigationBar: buildBottomNavBar(context),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              width: double.infinity,
              color: colorMerah,
              child: Center(
                child: Text(
                  'CrewCheck',
                  style: crewCheckTitleStyle(size: 40, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: colorKuning,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: dateOptions.map((date) {
                    final isSelected =
                        date.day == selectedDate.day &&
                        date.month == selectedDate.month &&
                        date.year == selectedDate.year;
                    return GestureDetector(
                      onTap: () => setState(() => selectedDate = date),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 18,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : colorKuning,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: colorBiru, width: 2)
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              date.day.toString().padLeft(2, '0'),
                              style: bodyTextStyle(size: 28, color: colorMerah),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatDate(date).split(' ')[1],
                              style: bodyTextStyle(
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (isSelected)
                              Row(
                                children: const [
                                  Text('•  ', style: TextStyle(fontSize: 18)),
                                  Text('•', style: TextStyle(fontSize: 18)),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: colorKrem,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorKuning, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Kumpul Hari Ini',
                        style: bodyTextStyle(size: 28, color: Colors.black),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: taskStream(selectedDate),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Terjadi kesalahan saat memuat tugas',
                                style: bodyTextStyle(size: 18),
                              ),
                            );
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Center(
                              child: Text(
                                'Tidak ada tugas untuk tanggal ini',
                                style: bodyTextStyle(size: 18),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: docs.length,
                            separatorBuilder: (context, index) =>
                                const Divider(color: colorMerah, height: 1),
                            itemBuilder: (context, index) {
                              final data = docs[index].data();
                              final title =
                                  data['title'] as String? ??
                                  'Tugas tanpa judul';
                              final completed =
                                  data['completed'] as bool? ?? false;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: colorMerah,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Checkbox(
                                          value: completed,
                                          onChanged: (_) {},
                                          activeColor: colorMerah,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: bodyTextStyle(size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: colorMerah,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
