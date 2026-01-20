import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';

class QuickLogScreen extends StatefulWidget {
  const QuickLogScreen({super.key});

  @override
  State<QuickLogScreen> createState() => _QuickLogScreenState();
}

enum VoiceState { idle, listening, review, processing, success, error }

class _QuickLogScreenState extends State<QuickLogScreen> {
  late stt.SpeechToText _speech;
  VoiceState _state = VoiceState.idle;
  String _text = "Tap the mic to start...";
  String _lastError = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // Auto-initialize and start listening for speed
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAndStart());
  }

  Future<void> _initAndStart() async {
    bool available = await _speech.initialize(
      onError: (val) => setState(() {
        _state = VoiceState.error;
        _lastError = "Microphone Error";
      }),
      onStatus: (status) {
        // If speech engine stops by itself (timeout), go to review mode
        if (status == 'notListening' && _state == VoiceState.listening) {
          setState(() => _state = VoiceState.review);
        }
      },
    );

    if (available) {
      _startListening();
    } else {
      setState(() {
        _state = VoiceState.error;
        _lastError = "Speech recognition unavailable";
      });
    }
  }

  void _startListening() {
    setState(() {
      _state = VoiceState.listening;
      _text = ""; // Clear previous text
    });
    
    _speech.listen(
      onResult: (val) => setState(() {
        _text = val.recognizedWords;
      }),
      cancelOnError: false,
      partialResults: true,
      listenMode: stt.ListenMode.dictation, // Optimized for longer dictation
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _state = VoiceState.review);
  }

  Future<void> _submitLog() async {
    if (_text.isEmpty || _text == "Tap the mic to start...") return;

    setState(() => _state = VoiceState.processing);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("No user logged in");

      // Send to Backend
      await Supabase.instance.client.functions.invoke(
        'process-voice-log',
        body: {
          'text': _text,
          'user_id': user.id,
          'timezone': DateTime.now().timeZoneName,
        },
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _state = VoiceState.success;
          _text = "Saved successfully!";
        });

        // Optional: Auto-reset after 1.5s so they can speak again
        // Or just stay on success screen. 
        // Based on "let them speak again by clicking voice button", we stay here.
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = VoiceState.error;
          _lastError = "Upload Failed. Try again.";
        });
      }
    }
  }

  void _reset() {
    // User wants to speak again
    _startListening();
  }

  void _closeApp() {
    // Try to pop or exit system
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      SystemNavigator.pop(); // Closes the app entirely
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple dark background
    return Scaffold(
      backgroundColor: const Color(0xFF121212), 
      body: SafeArea(
        child: Column(
          children: [
            // --- TOP BAR: Close Button ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _closeApp,
                    iconSize: 40,
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),

            // --- CENTER: Text Display ---
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SingleChildScrollView(
                    child: _buildTextContent(),
                  ),
                ),
              ),
            ),

            // --- BOTTOM: Controls ---
            Container(
              padding: const EdgeInsets.only(bottom: 50, top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    if (_state == VoiceState.processing) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    
    Color textColor = Colors.white;
    if (_state == VoiceState.success) textColor = Colors.greenAccent;
    if (_state == VoiceState.error) textColor = Colors.redAccent;

    return Text(
      _state == VoiceState.error ? _lastError : _text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: textColor,
        fontSize: 26,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }

  List<Widget> _buildButtons() {
    // Case 1: Listening -> Show STOP button
    if (_state == VoiceState.listening) {
      return [
        _buildCircleButton(
          icon: Icons.stop,
          color: Colors.redAccent,
          onTap: _stopListening,
          label: "Stop",
        ),
      ];
    }

    // Case 2: Review -> Show SEND and RETRY buttons
    if (_state == VoiceState.review) {
      return [
        _buildCircleButton(
          icon: Icons.mic,
          color: Colors.white24,
          onTap: _reset, // Re-record
          label: "Retry",
        ),
        _buildCircleButton(
          icon: Icons.check,
          color: Colors.green,
          onTap: _submitLog, // Send
          label: "Send",
        ),
      ];
    }

    // Case 3: Success -> Show NEW button
    if (_state == VoiceState.success) {
      return [
        _buildCircleButton(
          icon: Icons.mic,
          color: Colors.blueAccent,
          onTap: _reset, // Start fresh
          label: "New Log",
        ),
      ];
    }

    // Case 4: Idle/Error -> Show START button
    return [
      _buildCircleButton(
        icon: Icons.mic,
        color: Colors.blueAccent,
        onTap: _startListening,
        label: "Start",
      ),
    ];
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        )
      ],
    );
  }
}