import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import 'create_doubt_screen.dart';
import 'doubt_detail_screen.dart';

class DoubtsListScreen extends StatefulWidget {
  const DoubtsListScreen({super.key});

  @override
  State<DoubtsListScreen> createState() => _DoubtsListScreenState();
}

class _DoubtsListScreenState extends State<DoubtsListScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _doubts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoubts();
  }

  Future<void> _fetchDoubts() async {
    try {
      final data = await supabase
          .from('doubts')
          .select('*, profiles(username, display_name)')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _doubts = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching doubts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        title: const Text('❓ DOUBTS NETWORK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _doubts.isEmpty
              ? const Center(child: Text('No doubts found. Ask the Grid!', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _doubts.length,
                  itemBuilder: (context, index) {
                    final doubt = _doubts[index];
                    final author = doubt['profiles'];
                    final isSolved = doubt['solved'] == true;
                    final tags = doubt['tags'] as List<dynamic>? ?? [];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => DoubtDetailScreen(doubt: doubt)));
                        },
                        child: NeoPixelBox(
                          padding: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isSolved)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(color: AppColors.primary, border: Border.all(color: AppColors.blockEdge, width: 2)),
                                      child: const Text('SOLVED', style: TextStyle(color: AppColors.neutralBg, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  Expanded(
                                    child: Text(
                                      doubt['subject']?.toUpperCase() ?? 'GENERAL',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '@${author?['username'] ?? 'unknown'}',
                                      style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(doubt['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
                              if (tags.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags.map((t) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(border: Border.all(color: AppColors.shadowDark, width: 2)),
                                    child: Text('#$t', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                  )).toList(),
                                )
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: NeoPixelBox(
        padding: 16,
        isButton: true,
        onTap: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateDoubtScreen()));
          if (result == true) {
            setState(() => _isLoading = true);
            _fetchDoubts();
          }
        },
        child: const Icon(Icons.add, color: AppColors.primary),
      ),
    );
  }
}
