import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';

class SimulationViewer extends StatefulWidget {
  final String simPath;
  final String title;

  const SimulationViewer({
    super.key,
    required this.simPath,
    required this.title,
  });

  @override
  State<SimulationViewer> createState() => _SimulationViewerState();
}

class _SimulationViewerState extends State<SimulationViewer> {
  late final WebViewController _controller;
  HttpServer? _localServer;
  
  bool _isLoading = true;
  bool _isExtracting = true;
  bool _hasError = false;
  int _loadProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) setState(() => _loadProgress = progress);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error [${error.errorCode}]: ${error.description}');
            // Filter out ERR_FAILED unhandled errors if they aren't critical
            if (error.errorCode == -999) return;
            // IMPORTANT: If we are offline, sub-resources (fonts, external CSS) will fail.
            // Only trigger the "Cold Reboot" panic if the MAIN FRAME fails to inject.
            if (error.isForMainFrame != true) return;
            
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      );
    _extractAndServe();
  }

  @override
  void dispose() {
    _localServer?.close(force: true);
    super.dispose();
  }

  /// Extracts the HTML asset to temp storage and serves it via a local 
  /// HTTP server to bypass Android's strict `file://` permissions and CORS issues.
  Future<void> _extractAndServe() async {
    try {
      setState(() {
        _isExtracting = true;
        _hasError = false;
        _isLoading = true;
        _loadProgress = 0;
      });

      final bytes = await rootBundle.load(widget.simPath);
      final tempDir = await getTemporaryDirectory();

      final safeName = widget.simPath.replaceAll('/', '_');
      final tempFile = File('${tempDir.path}/$safeName');

      await tempFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );

      // Close existing server if rebooting
      if (_localServer != null) {
        await _localServer!.close(force: true);
      }

      // Bind to an ephemeral port
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

      if (mounted) setState(() => _isExtracting = false);

      final localUrl = 'http://127.0.0.1:${_localServer!.port}';
      debugPrint('Serving simulation at $localUrl');
      await _controller.loadRequest(Uri.parse(localUrl));
    } catch (e) {
      debugPrint('Simulation Extraction Error: $e');
      if (mounted) {
        setState(() {
          _isExtracting = false;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          color: Color(0xFFD32F2F),
          child: Column(
            children: [
              // ── HEADER ──
              Padding(
                padding: EdgeInsets.fromLTRB(8, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: NeoPixelBox(
                        padding: 8,
                        backgroundColor: Colors.black,
                        child: Text(
                          widget.title.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.w900,
                            color: context.colors.primary,
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white, size: 22),
                      onPressed: _extractAndServe,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // ── PROGRESS BAR ──
              if (_isExtracting || _isLoading)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: _isExtracting
                        ? LinearProgressIndicator(
                            backgroundColor: Colors.black26,
                            color: context.colors.primary,
                            minHeight: 4,
                          )
                        : LinearProgressIndicator(
                            value: _loadProgress / 100,
                            backgroundColor: Colors.black26,
                            color: context.colors.primary,
                            minHeight: 4,
                          ),
                  ),
                ),
              if (!_isLoading && !_isExtracting) SizedBox(height: 10),

              // ── SIMULATION VIEWPORT ──
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: NeoPixelBox(
                    padding: 4,
                    backgroundColor: Colors.black,
                    child: _hasError
                        ? _buildErrorView()
                        : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: WebViewWidget(controller: _controller),
                              ),
                              if (_isExtracting || _isLoading)
                                Container(
                                  color: Colors.black87,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          color: context.colors.primary,
                                          strokeWidth: 3,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          _isExtracting
                                              ? 'DECOMPRESSING MODULE...'
                                              : 'INJECTING ENVIRONMENT... $_loadProgress%',
                                          style: TextStyle(
                                            fontFamily: 'Courier',
                                            color: context.colors.primary,
                                            fontSize: 12,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(
            'MODULE LOAD FAILED',
            style: TextStyle(
              fontFamily: 'Courier',
              color: Colors.red,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'The simulation kernel panicked.\nTap COLD REBOOT to retry.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Courier',
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: _extractAndServe,
            child: NeoPixelBox(
              isButton: true,
              padding: 12,
              backgroundColor: Color(0xFFD32F2F),
              child: Text(
                'COLD REBOOT',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
