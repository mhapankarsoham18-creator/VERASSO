import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';

class GlobeScreen extends StatefulWidget {
  const GlobeScreen({super.key});

  @override
  State<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends State<GlobeScreen> {
  late final WebViewController _controller;
  HttpServer? _localServer;
  bool _isLoading = true;
  String _selectedCountry = 'None';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(context.colors.neutralBg)
      ..addJavaScriptChannel(
        'VerassoGlobe',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            if (data['type'] == 'polygonClick') {
              setState(() => _selectedCountry = data['name'] ?? 'Unknown');
            }
          } catch (e) {
            debugPrint("VerassoGlobe payload exception: $e");
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
            // Example of dispatching initial data into the globe GL structure
            _controller.runJavaScript("window.initGlobeData();");
          },
        ),
      );
    _extractAndServeGlobe();
  }

  @override
  void dispose() {
    _localServer?.close(force: true);
    super.dispose();
  }

  Future<void> _extractAndServeGlobe() async {
    try {
      final simPath = 'assets/simulations/geography/index.html';
      final bytes = await DefaultAssetBundle.of(context).load(simPath);
      final tempDir = await getTemporaryDirectory();

      final safeName = simPath.replaceAll('/', '_');
      final tempFile = File('${tempDir.path}/$safeName');

      await tempFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );

      if (_localServer != null) {
        await _localServer!.close(force: true);
      }

      _localServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _localServer!.listen((HttpRequest request) async {
        request.response.headers.contentType = ContentType.html;
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        
        if (!tempFile.existsSync()) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        try {
          await tempFile.openRead().pipe(request.response);
        } catch (e) {
          debugPrint('HTTP Server Pipe error: $e');
        }
      });

      final localUrl = 'http://127.0.0.1:${_localServer!.port}';
      await _controller.loadRequest(Uri.parse(localUrl));
    } catch (e) {
      debugPrint('Globe Extraction Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text(
          "GLOBAL ATLAS",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: context.colors.neutralBg,
      ),
      body: SafeArea(
        child: Container(
          color: Color(0xFFD32F2F), // Pokédex Red Bezel
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Top HUD
              NeoPixelBox(
                padding: 12,
                backgroundColor: Colors.black,
                child: Row(
                  children: [
                    Icon(Icons.public, color: context.colors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TARGET SCANNED: ${_selectedCountry.toUpperCase()}',
                        style: TextStyle(
                          fontFamily: 'Courier', // Monospace Pokédex feel
                          fontWeight: FontWeight.w900,
                          color: context.colors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              // The Embedded 3D Data layer wrapped in Pokédex screen border
              Expanded(
                child: NeoPixelBox(
                  padding: 8,
                  backgroundColor: Color(0xFF9E9E9E), // Inner grey bezel
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: context.colors.primary,
        onPressed: () {
          // Push a JS message down commanding the globe viewport to rotate or shift data layers
          _controller.runJavaScript("window.rotateToHome();");
        },
        icon: Icon(Icons.home, color: context.colors.neutralBg),
        label: Text(
          "HOME", 
          style: TextStyle(color: context.colors.neutralBg, fontWeight: FontWeight.w900)
        ),
      ),
    );
  }
}
