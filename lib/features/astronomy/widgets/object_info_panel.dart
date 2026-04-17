import 'package:flutter/material.dart';
import '../models/celestial_object.dart';

/// Expandable bottom sheet for detailed object info + AI chat.
class ObjectInfoPanel extends StatefulWidget {
  final CelestialObject object;
  final VoidCallback onClose;

  const ObjectInfoPanel({
    super.key,
    required this.object,
    required this.onClose,
  });

  @override
  State<ObjectInfoPanel> createState() => _ObjectInfoPanelState();
}

class _ObjectInfoPanelState extends State<ObjectInfoPanel> {
  final _chatController = TextEditingController();
  final List<_ChatMessage> _chatMessages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Initial greeting
    _chatMessages.add(_ChatMessage(
      text:
          'You\'re looking at ${widget.object.name}. ${widget.object.description} What would you like to know?',
      isAI: true,
    ));
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add(_ChatMessage(text: text, isAI: false));
      _chatController.clear();
      _isTyping = true;
    });

    // Simulate AI response (replace with real AI later)
    Future.delayed(Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _chatMessages.add(_ChatMessage(
          text: _generateResponse(text, widget.object),
          isAI: true,
        ));
      });
    });
  }

  String _generateResponse(String query, CelestialObject obj) {
    final q = query.toLowerCase();

    if (q.contains('how far') || q.contains('distance')) {
      if (obj.distanceLy > 0) {
        return '${obj.name} is approximately ${obj.distanceLy} light-years away from Earth. '
            'That means the light you\'re seeing left the star ${obj.distanceLy.toStringAsFixed(0)} years ago!';
      }
      return 'Distance data is not available for ${obj.name} in this catalog.';
    }

    if (q.contains('how big') || q.contains('size')) {
      if (obj.type == 'planet') {
        return '${obj.name} is one of the ${obj.magnitude < 0 ? "brighter" : "dimmer"} planets visible from Earth. '
            'Check out its magnitude: ${obj.magnitude}!';
      }
      return '${obj.name} has an apparent magnitude of ${obj.magnitude}. '
          'Lower magnitude = brighter. Sirius at -1.46 is the brightest star.';
    }

    if (q.contains('constellation')) {
      if (obj.constellation.isNotEmpty) {
        return '${obj.name} belongs to the constellation ${obj.constellation}. '
            'It is designated as ${obj.bayer.isNotEmpty ? obj.bayer : "a prominent star"} in this constellation.';
      }
      return '${obj.name} is a solar system object and doesn\'t belong to a constellation.';
    }

    if (q.contains('color') || q.contains('why')) {
      if (obj.type == 'star') {
        final temp = obj.colorIndex < 0
            ? 'very hot (blue-white)'
            : obj.colorIndex < 0.5
                ? 'hot (white-yellow)'
                : obj.colorIndex < 1.0
                    ? 'medium temperature (yellow-orange)'
                    : 'cool (orange-red)';
        return 'The color of ${obj.name} tells us its surface temperature! '
            'With a color index of ${obj.colorIndex.toStringAsFixed(2)}, it is $temp.';
      }
      return '${obj.name}\'s appearance depends on its atmosphere and composition.';
    }

    if (q.contains('see') || q.contains('find') || q.contains('where')) {
      return '${obj.name} is currently at altitude ${obj.altitude.toStringAsFixed(1)}° '
          'and azimuth ${obj.azimuth.toStringAsFixed(1)}°. '
          '${obj.altitude > 30 ? "It's high in the sky — easy to spot!" : obj.altitude > 0 ? "Look closer to the horizon." : "It's below the horizon right now."}';
    }

    // Default educational response
    return '${obj.description} '
        'Its apparent magnitude is ${obj.magnitude}, making it '
        '${obj.magnitude < 0 ? "extremely bright" : obj.magnitude < 2 ? "one of the brighter objects" : "visible to the naked eye"} in the sky.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF8BAC0F), // Classic LCD Green
        border: Border.all(
          color: Color(0xFF0F380F), 
          width: 3,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE0E0E0),
            blurRadius: 10,
          )
        ]
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF0F380F), width: 2),
              ),
            ),
            child: Row(
              children: [
                Text(widget.object.emoji, style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.object.name.toUpperCase(),
                        style: TextStyle(
                          color: Color(0xFF0F380F),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        widget.object.typeLabel,
                        style: TextStyle(
                          color: Color(0xFF0F380F).withValues(alpha: 0.7),
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF0F380F)),
                    ),
                    child: Icon(Icons.close,
                        color: Color(0xFF0F380F), size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _chatMessages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chatMessages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_chatMessages[index]);
              },
            ),
          ),

          // Input field
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF0F380F), width: 2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF0F380F)),
                      color: Color(0xFF9BBC0F),
                    ),
                    child: TextField(
                      controller: _chatController,
                      style: TextStyle(
                          color: Color(0xFF0F380F), fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText:
                            'Ask about ${widget.object.name}...',
                        hintStyle: TextStyle(
                            color: Color(0xFF0F380F).withValues(alpha: 0.5), fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF0F380F)),
                      color: Color(0xFF9BBC0F),
                    ),
                    child: Icon(Icons.send,
                        color: Color(0xFF0F380F), size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Align(
        alignment:
            msg.isAI ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: msg.isAI
                ? Color(0xFF8BAC0F)
                : Color(0xFF9BBC0F),
            border: Border.all(
              color: Color(0xFF0F380F),
              width: 1,
            ),
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              color: Color(0xFF0F380F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xFF8BAC0F),
            border: Border.all(color: Color(0xFF0F380F)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(0),
              SizedBox(width: 4),
              _dot(1),
              SizedBox(width: 4),
              _dot(2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 200),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Container(
          width: 6,
          height: 6,
          color: Color(0xFF0F380F),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isAI;

  _ChatMessage({required this.text, required this.isAI});
}
