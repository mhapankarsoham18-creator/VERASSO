import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import 'package:verasso/core/utils/logger.dart';

class CodemasterScreen extends StatefulWidget {
  const CodemasterScreen({super.key});

  @override
  State<CodemasterScreen> createState() => _CodemasterScreenState();
}

class _CodemasterScreenState extends State<CodemasterScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'VerassoGameSync',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            if (data['action'] == 'start_challenge') {
              _showChallengeSheet(data['challengeId']);
            }
          } catch (e) {
            appLogger.d("Game payload exception: \$e");
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadFlutterAsset('assets/game/index.html');
  }

  void _showChallengeSheet(String challengeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChallengeSheet(
        challengeId: challengeId,
        onResolve: (bool passed) {
          final payload = jsonEncode({'passed': passed});
          _controller.runJavaScript("window.onChallengeResult($payload);");
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          color: Color(0xFFD32F2F), // PokÃ©dex Red
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Top PokÃ©dex camera/LED array
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 16),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.blue, blurRadius: 10)],
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red)),
                  SizedBox(width: 4),
                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.yellow)),
                  SizedBox(width: 4),
                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                ],
              ),
              SizedBox(height: 16),

              Expanded(
                child: NeoPixelBox(
                  padding: 12,
                  backgroundColor: Color(0xFFEEEEEE),
                  child: NeoPixelBox(
                    padding: 4,
                    backgroundColor: Colors.black,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: WebViewWidget(controller: _controller),
                        ),
                        if (_isLoading)
                          Center(
                            child: VerassoLoading(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeSheet extends StatelessWidget {
  final String challengeId;
  final Function(bool) onResolve;

  const _ChallengeSheet({
    required this.challengeId,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    // This sheet acts as the bridge interpreting the challenge ID 
    // into actual code evaluation sequences (to be linked to Dart evaluator).
    return Container(
      padding: EdgeInsets.all(24) + MediaQuery.of(context).viewInsets,
      decoration: BoxDecoration(
        color: context.colors.neutralBg,
        border: Border(top: BorderSide(color: context.colors.blockEdge, width: 4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "CODEMASTER CHALLENGE",
            style: TextStyle(fontWeight: FontWeight.w900, color: context.colors.textPrimary, fontSize: 18, letterSpacing: 2),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            "Intercepted Challenge ID: \$challengeId",
            style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          
          // Placeholder controls returning pass/fail to HTML5 instance
          Row(
            children: [
              Expanded(
                child: NeoPixelBox(
                  isButton: true,
                  onTap: () {
                    Navigator.pop(context);
                    onResolve(false);
                  },
                  padding: 16,
                  backgroundColor: context.colors.shadowLight,
                  child: Text(
                    "FAIL / RETREAT",
                    style: TextStyle(fontWeight: FontWeight.w900, color: context.colors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: NeoPixelBox(
                  isButton: true,
                  onTap: () {
                    Navigator.pop(context);
                    onResolve(true);
                  },
                  padding: 16,
                  backgroundColor: context.colors.primary,
                  child: Text(
                    "EXECUTE (PASS)",
                    style: TextStyle(fontWeight: FontWeight.w900, color: context.colors.neutralBg),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

