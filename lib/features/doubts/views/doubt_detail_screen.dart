import 'package:flutter/material.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Answer marked as solution! +10 Trust Score awarded.')));
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
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('THREAD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
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
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(color: context.colors.primary, border: Border.all(color: context.colors.blockEdge, width: 2)),
                                child: Text('SOLVED', style: TextStyle(color: context.colors.neutralBg, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            Expanded(
                              child: Text('@${author?['username'] ?? 'unknown'}', 
                              style: TextStyle(fontWeight: FontWeight.w900, color: context.colors.accent),
                              overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(widget.doubt['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        SizedBox(height: 16),
                        Text(widget.doubt['body'], style: TextStyle(height: 1.5, color: context.colors.textPrimary)),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  Text('ANSWERS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: context.colors.textSecondary, fontSize: 12)),
                  SizedBox(height: 12),

                  // Input Box
                  if (!_baseDoubtSolved)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.colors.shadowLight,
                              border: Border.all(color: context.colors.blockEdge, width: 2),
                            ),
                            child: TextField(
                              controller: _answerController,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: 'Transmit answer...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        NeoPixelBox(
                          isButton: true,
                          padding: 12,
                          onTap: _isSubmitting ? null : _postAnswer,
                          child: _isSubmitting 
                            ? SizedBox(width: 20, height: 20, child: VerassoLoading())
                            : Icon(Icons.send, color: context.colors.primary, size: 20),
                        )
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          if (_isLoadingAnswers)
            SliverFillRemaining(child: Center(child: VerassoLoading()))
          else if (_answers.isEmpty)
            SliverFillRemaining(child: Center(child: Text('No answers yet.', style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.bold))))
          else
            SliverPadding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 40),
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
                          margin: EdgeInsets.only(right: 12, top: 16),
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: context.colors.blockEdge.withAlpha(50), width: 2)))
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: NeoPixelBox(
                              padding: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isAccepted)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Icon(Icons.verified, size: 16, color: context.colors.primary),
                                        ),
                                      Expanded(
                                        child: Text('@${ansProfile?['username'] ?? 'unknown'}', 
                                          style: TextStyle(fontWeight: FontWeight.w900, color: isAccepted ? context.colors.primary : context.colors.textPrimary, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(ans['content'], style: TextStyle(height: 1.4, color: context.colors.textSecondary)),
                                  
                                  if (isMyDoubt && !_baseDoubtSolved && !isAccepted) ...[
                                    SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: InkWell(
                                        onTap: () => _acceptAnswer(ans['id']),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(border: Border.all(color: context.colors.primary, width: 2)),
                                          child: Text('MARK SOLVED', style: TextStyle(color: context.colors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
