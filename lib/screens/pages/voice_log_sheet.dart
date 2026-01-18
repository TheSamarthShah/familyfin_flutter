import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foundation_app/services/master_data_service.dart';

class VoiceLogSheet extends StatefulWidget {
  const VoiceLogSheet({super.key});

  @override
  State<VoiceLogSheet> createState() => _VoiceLogSheetState();
}

class _VoiceLogSheetState extends State<VoiceLogSheet> {
  late stt.SpeechToText _speech;
  late TextEditingController _textController; // 1. Added Controller

  bool _isListening = false;
  bool _isProcessing = false;
  
  String _status = "Initializing...";
  
  final List<Map<String, String>> _languages = [
    {'code': 'en_IN', 'name': 'English (India)'},
    {'code': 'hi_IN', 'name': 'Hindi'},
    {'code': 'gu_IN', 'name': 'Gujarati'},
    {'code': 'mr_IN', 'name': 'Marathi'},
    {'code': 'bn_IN', 'name': 'Bengali'},
    {'code': 'ta_IN', 'name': 'Tamil'},
    {'code': 'te_IN', 'name': 'Telugu'},
    {'code': 'kn_IN', 'name': 'Kannada'},
  ];
  String _currentLocaleId = 'en_IN'; 

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _textController = TextEditingController(); // 2. Initialize
    _loadSettings();
  }

  @override
  void dispose() {
    _textController.dispose(); // 3. Clean up
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastUsed = prefs.getString('last_voice_locale');
    
    if (mounted) {
      setState(() {
        if (lastUsed != null) _currentLocaleId = lastUsed;
        _initSpeech();
      });
    }
  }

  Future<void> _savePreference(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_voice_locale', code);
  }

  Future<void> _initSpeech() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() => _status = "Microphone permission denied");
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (val) {
        if (mounted) {
          setState(() {
            if (val == 'listening') {
              _status = "Listening (${_getLangName(_currentLocaleId)})...";
            } else if (val == 'notListening') {
              _status = "Tap to Speak";
            }
          });
        }
      },
      onError: (val) => setState(() => _status = "Error: ${val.errorMsg}"),
    );

    setState(() => _status = available ? "Ready" : "Speech unavailable");
  }

  void _listen() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
        _textController.clear(); // Clear old text on new listen
      });
      
      _speech.listen(
        localeId: _currentLocaleId, 
        onResult: (val) {
           setState(() {
             // 4. Update controller instead of string variable
             _textController.text = val.recognizedWords;
             // Keep cursor at end
             _textController.selection = TextSelection.fromPosition(
               TextPosition(offset: _textController.text.length)
             );
           });
        },
      );
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _processAndSend() async {
    final textToSend = _textController.text.trim(); // 5. Use edited text

    if (textToSend.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _status = "Analyzing with AI..."; 
    });
    
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.functions.invoke(
        'process-voice-log',
        body: {
          'text': textToSend, 
          'user_id': userId,
        },
      );

      if (mounted) {
        Navigator.pop(context);
        context.read<MasterDataProvider>().refreshDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Draft saved!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
           _status = "Error processing request";
           _isProcessing = false;
        });
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
  
  String _getLangName(String code) {
    return _languages.firstWhere((e) => e['code'] == code, orElse: () => {'name': code})['name']!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      // 6. Handle Keyboard overlapping
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
            Text(_status, style: theme.textTheme.titleMedium),
            const SizedBox(height: 20),
            
            if (!_isProcessing) 
              DropdownButton<String>(
                value: _currentLocaleId,
                items: _languages.map((l) => DropdownMenuItem(value: l['code'], child: Text(l['name']!))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _currentLocaleId = val);
                    _savePreference(val);
                  }
                },
              ),

            const SizedBox(height: 20),

            // 7. Replaced Text widget with TextField
            TextField(
              controller: _textController,
              textAlign: TextAlign.center,
              enabled: !_isListening, // Disable editing while listening
              maxLines: 4,
              minLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Tap the mic and speak naturally...",
                hintStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.outline.withOpacity(0.5)
                ),
                border: InputBorder.none,
              ),
            ),
            
            if (!_isListening && _textController.text.isNotEmpty)
              Text("Tap text to edit", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),

            const SizedBox(height: 40),

            if (_isProcessing)
               const CircularProgressIndicator()
            else
              GestureDetector(
                onTap: _listen,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: _isListening ? Colors.red : theme.colorScheme.primary,
                  child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 35),
                ),
              ),
            
            const SizedBox(height: 40),
            
            if (!_isListening && !_isProcessing)
               ElevatedButton(
                 onPressed: _textController.text.isNotEmpty ? _processAndSend : null,
                 child: const Text("Create Draft Log"),
               ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}