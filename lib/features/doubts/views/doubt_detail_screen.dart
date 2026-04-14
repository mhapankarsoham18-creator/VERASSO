import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';

class DoubtDetailScreen extends StatefulWidget {
  final Map<String, dynamic> doubt;
  const DoubtDetailScreen({super.key, required this.doubt});

  @override
  State<DoubtDetailScreen> createState() => _DoubtDetailScreenState();
}

class _DoubtDetailScreenState extends State<DoubtDetailScreen> {
  final supabase = Supabase.instance.client;
  final _answerController = TextEditingController();
  List<dynamic> _answers = [];
  bool _isLoadingAnswers = true;
  bool _isSubmitting = false;
  String? _currentUserProfileId;
  late bool _baseDoubtSolved;

  @override
  void initState() {
    super.initState();
    _baseDoubtSolved = widget.doubt['solved'] == true;
    _resolveCurrentUser();
    _fetchAnswers();
  }

  Future<void> _resolveCurrentUser() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      final profile = await supabase.from('profiles').select('id').eq('firebase_uid', fbUser.uid).maybeSingle();
      if (mounted && profile != null) {
        setState(() => _currentUserProfileId = profile['id']);
      }
    }
  }

  Future<void> _fetchAnswers() async {
    try {
      final data = await supabase
          .from('doubt_answers')
          .select('*, profiles(username, display_name)')
          .eq('doubt_id', widget.doubt['id'])
          .order('is_accepted', ascending: false) // showing accepted answer top
          .order('created_at', ascending: true);
      
      if (mounted) {
        setState(() {
          _answers = data;
          _isLoadingAnswers = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching answers: $e');
      if (mounted) setState(() => _isLoadingAnswers = false);
    }
  }

  Future<void> _postAnswer() async {
    if (_answerController.text.trim().isEmpty) return;
    
    setState(() => _isSubmitting = true);
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) throw 'Authentication session lost.';
      
      final profile = await supabase.from('profiles').select('id').eq('firebase_uid', fbUser.uid).maybeSingle();
      if (profile == null) throw 'Profile not linked.';

      await supabase.from('doubt_answers').insert({
        'doubt_id': widget.doubt['id'],
        'author_id': profile['id'],
        'content': _answerController.text.trim(),
      });
      _answerController.clear();
      _fetchAnswers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _acceptAnswer(String answerId) async {
    try {
      await supabase.from('doubt_answers').update({
        'is_accepted': true,
      }).eq('id', answerId);
      
      setState(() {
        _baseDoubtSolved = true;
      });
      
      _fetchAnswers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Answer marked as solution! +10 Trust Score awarded.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = widget.doubt['profiles'];
    final isMyDoubt = _currentUserProfileId != null && _currentUserProfileId == widget.doubt['author_id'];

    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        title: const Text('THREAD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // OP Post
                  NeoPixelBox(
                    padding: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_baseDoubtSolved)
                               Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(color: AppColors.primary, border: Border.all(color: AppColors.blockEdge, width: 2)),
                                child: const Text('SOLVED', style: TextStyle(color: AppColors.neutralBg, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            Expanded(
                              child: Text('@${author?['username'] ?? 'unknown'}', 
                              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent),
                              overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(widget.doubt['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 16),
                        Text(widget.doubt['body'], style: const TextStyle(height: 1.5, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('ANSWERS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 12),

                  // Input Box
                  if (!_baseDoubtSolved)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.shadowLight,
                              border: Border.all(color: AppColors.blockEdge, width: 2),
                            ),
                            child: TextField(
                              controller: _answerController,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                hintText: 'Transmit answer...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        NeoPixelBox(
                          isButton: true,
                          padding: 12,
                          onTap: _isSubmitting ? null : _postAnswer,
                          child: _isSubmitting 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                            : const Icon(Icons.send, color: AppColors.primary, size: 20),
                        )
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          if (_isLoadingAnswers)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          else if (_answers.isEmpty)
            const SliverFillRemaining(child: Center(child: Text('No answers yet.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))))
          else
            SliverPadding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ans = _answers[index];
                    final ansProfile = ans['profiles'];
                    final isAccepted = ans['is_accepted'] == true;
                    
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          margin: const EdgeInsets.only(right: 12, top: 16),
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: AppColors.blockEdge.withAlpha(50), width: 2)))
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NeoPixelBox(
                              padding: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isAccepted)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Icon(Icons.verified, size: 16, color: AppColors.primary),
                                        ),
                                      Expanded(
                                        child: Text('@${ansProfile?['username'] ?? 'unknown'}', 
                                          style: TextStyle(fontWeight: FontWeight.w900, color: isAccepted ? AppColors.primary : AppColors.textPrimary, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(ans['content'], style: const TextStyle(height: 1.4, color: AppColors.textSecondary)),
                                  
                                  if (isMyDoubt && !_baseDoubtSolved && !isAccepted) ...[
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: InkWell(
                                        onTap: () => _acceptAnswer(ans['id']),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 2)),
                                          child: const Text('MARK SOLVED', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                        ),
                                      ),
                                    )
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: _answers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
