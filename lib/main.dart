import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech to Text',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking...';
  String _statusLog = 'Status: Ready'; // New variable for debugging
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _listen() async {
    // 1. Initialize with explicit error handling for the UI
    bool available = await _speech.initialize(
      onStatus: (val) {
        // Update the UI with the exact status from the engine
        setState(() => _statusLog = 'Status: $val');
        if (val == 'done' || val == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (val) {
        // Show errors in Red
        setState(() {
          _statusLog = 'Error: ${val.errorMsg}';
          _isListening = false;
        });
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _statusLog = 'Status: Listening...';
      });
      
      // 2. Start Listening with longer timeouts
      _speech.listen(
        onResult: (val) {
          setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          });
        },
        // Wait 30 seconds for speech
        listenFor: const Duration(seconds: 30),
        // Wait 3 seconds of silence before stopping
        pauseFor: const Duration(seconds: 3),
        // Try to use the system default locale
        localeId: "en_US", 
        // Partial results show text *while* you speak, not just at the end
        partialResults: true, 
      );
    } else {
      setState(() {
        _isListening = false;
        _text = "Speech recognition denied or not available.";
      });
    }
  }

  void _stop() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio to Text Debugger')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stop : _listen,
        backgroundColor: _isListening ? Colors.red : Colors.indigo,
        child: Icon(_isListening ? Icons.stop : Icons.mic),
      ),
      body: SingleChildScrollView(
        reverse: true,
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            // STATUS DEBUGGER (New)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              width: double.infinity,
              child: Text(
                _statusLog,
                style: TextStyle(
                  color: _statusLog.contains('Error') ? Colors.red : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            
            Text(
              'Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16.0, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // MAIN TEXT BOX
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _text,
                style: const TextStyle(
                  fontSize: 24.0,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}