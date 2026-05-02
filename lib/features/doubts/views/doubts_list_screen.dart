import 'package:flutter/material.dart';
import 'package:verasso/core/theme/verasso_loading.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import 'create_doubt_screen.dart';
import 'doubt_detail_screen.dart';
import 'package:verasso/core/utils/logger.dart';

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
      appLogger.d('Error fetching doubts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('â“ DOUBTS NETWORK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.colors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? Center(child: VerassoLoading())
          : _doubts.isEmpty
              ? Center(child: Text('No doubts found. Ask the Grid!', style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.bold)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _doubts.length,
                  itemBuilder: (context, index) {
                    final doubt = _doubts[index];
                    final author = doubt['profiles'];
                    final isSolved = doubt['solved'] == true;
                    final tags = doubt['tags'] as List<dynamic>? ?? [];

                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
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
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      margin: EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(color: context.colors.primary, border: Border.all(color: context.colors.blockEdge, width: 2)),
                                      child: Text('SOLVED', style: TextStyle(color: context.colors.neutralBg, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  Expanded(
                                    child: Text(
                                      doubt['subject']?.toUpperCase() ?? 'GENERAL',
                                      style: TextStyle(color: context.colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '@${author?['username'] ?? 'unknown'}',
                                      style: TextStyle(color: context.colors.accent, fontSize: 11, fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(doubt['title'], style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: context.colors.textPrimary)),
                              if (tags.isNotEmpty) ...[
                                SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags.map((t) => Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(border: Border.all(color: context.colors.shadowDark, width: 2)),
                                    child: Text('#$t', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.colors.textSecondary)),
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
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateDoubtScreen()));
          if (result == true) {
            setState(() => _isLoading = true);
            _fetchDoubts();
          }
        },
        child: Icon(Icons.add, color: context.colors.primary),
      ),
    );
  }
}

