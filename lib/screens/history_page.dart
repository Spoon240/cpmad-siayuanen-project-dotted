import 'package:flutter/material.dart';
import '../widgets/stylesheet.dart';
import '../services/firestore_service.dart';
import 'history_report_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _days = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // FOR 30 DAYS
      final data = await FirestoreService().fetchDiaryHistory(maxDays: 30);
      if (!mounted) return;
      setState(() {
        _days = data;
        _loading = false;
      });
    } 
    catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteEntry({ required String uiDate, required String entryId, required String entryName,}) async {
    final before = _days;
    bool removedLast = false;

    final updated = <Map<String, dynamic>>[];
    for (final d in _days) {
      final date = (d['date'] ?? '').toString();
      final entries = (d['entries'] as List).cast<Map<String, dynamic>>();

      if (date != uiDate) {
        updated.add(d);
        continue;
      }

      // remove the entry
      final filtered = entries.where((e) => (e['id'] ?? '') != entryId).toList();

      if (filtered.isEmpty) {
        removedLast = true; // drop this day card from UI
      } 
      else {
        updated.add({'date': date, 'entries': filtered});
      }
    }
    setState(() => _days = updated);

    // DELETE
    await FirestoreService().deleteDiaryEntry(
      dayDocId: uiDate,
      entryId: entryId,
    );

    if (removedLast) {
      await FirestoreService().deleteEmptyDayDoc(uiDate);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted: $entryName')),
    );
  }

  Future<void> _confirmDelete({required String uiDate, required String entryId, required String entryName,}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text(entryName),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _deleteEntry(uiDate: uiDate, entryId: entryId, entryName: entryName);
    }
  }

  void _openReportForDay(String date, List<Map<String, dynamic>> entries) {
    double carbsG = 0, proteinG = 0, fatG = 0;
    num totalFoodCalories = 0;

    for (final rec in entries) {
      if (rec['type'] == 'food') { // no need for ?? ''
        totalFoodCalories += (rec['calories'] as num);
        carbsG   += (rec['carbs']   as num).toDouble();
        proteinG += (rec['protein'] as num).toDouble();
        fatG     += (rec['fats']    as num).toDouble();
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => ReportPage(
          carbsG: carbsG,
          proteinG: proteinG,
          fatG: fatG,
          calories: totalFoodCalories,
          date: date,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (contexr) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_days.isEmpty) {
            return const Center(child: Text('No history yet', style: AppTextStyles.bodyHint));
          }

          return RefreshIndicator(
            onRefresh: _loadHistory,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                final date = (day['date'] ?? '').toString();
                final entries = (day['entries'] as List).cast<Map<String, dynamic>>();

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBE4E4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: ValueKey('day_$date'),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      title: Text(date, style: AppTextStyles.body),
                      iconColor: const Color(0xFF3F3F3F),
                      collapsedIconColor: const Color(0xFF3F3F3F),
                      children: [
                        ...entries.map((entry) {
                          final isFood = entry['type'] == 'food';
                          final name = (entry['name'] ?? '').toString();
                          final cals = (entry['calories'] ?? 0);
                          final meal = (entry['meal'] ?? '').toString();
                        
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            title: Text(
                              '$name - ${cals is num ? cals.round() : cals} kcal',
                              style: AppTextStyles.bodyHintSmall2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              isFood ? 'Meal: ${_titleCase(meal)}' : 'Exercise',
                              style: AppTextStyles.bodyHintSmall2,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Color.fromARGB(255, 65, 87, 69)),
                              onPressed: () {
                                final entryId = (entry['id'] ?? '').toString();
                                _confirmDelete(uiDate: date, entryId: entryId, entryName: name);
                              },
                            ),

                          );
                        }),

                        // See Report button (non-functional for now)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () => _openReportForDay(date, entries),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B7E7A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text('See Report', style: AppTextStyles.bodyW),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // helper to make 'breakfast' to 'Breakfast'
  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
