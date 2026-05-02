import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReactEngineBridge extends StatefulWidget {
  final String htmlAssetPath;

  const ReactEngineBridge({
    super.key,
    required this.htmlAssetPath,
  });

  @override
  State<ReactEngineBridge> createState() => _ReactEngineBridgeState();
}

class _ReactEngineBridgeState extends State<ReactEngineBridge> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadFlutterAsset(widget.htmlAssetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: WebViewWidget(controller: _controller),
    );
  }
}
