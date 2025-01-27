import 'dart:convert';
import 'package:better_voice_message/settings/settings_model.dart';
import 'package:better_voice_message/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:settings_provider/settings_provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var mySettings = MainSettings();

  await mySettings.init();

  runApp(
    Settings(
      model: mySettings,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const MaterialColor seedColor = Colors.lightBlue;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Better VoiceMessage',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
        brightness: Brightness.light,
        appBarTheme: AppBarTheme(
          backgroundColor: seedColor.shade500,
        ),
        scaffoldBackgroundColor: seedColor.shade50,
        dialogBackgroundColor: seedColor.shade50,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor.shade900, brightness: Brightness.dark),
        useMaterial3: true,
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          backgroundColor: seedColor.shade800,
        ),
        scaffoldBackgroundColor: Colors.black87,
        dialogBackgroundColor: Colors.black87,
      ),
      home: const MyHomePage(title: 'Better VoiceMessage'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastTranscription = '';
  String _localeId = '';
  String _lastResponse = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadLocale();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  T _getSetting<T>(BaseProperty<T> property) {
    return Settings.from<MainSettings>(context).get(property);
  }

  T _listenSetting<T>(BaseProperty<T> property) {
    return Settings.listenFrom<MainSettings>(context).get(property);
  }

  void _loadLocale() async {
    setState(() {
      _localeId = _getSetting(MainSettings.locale);
    });
  }

  void _listenToLocale() {
    _localeId = _listenSetting(MainSettings.locale);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenToLocale();
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    print('Starting listening... in locale $_localeId');
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: _localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
      ),
    );
    setState(() {});
  }

  /// Manually stop the active speech recognition session.
  /// This is not called when the user stops speaking and the SpeechToText stops automatically.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastTranscription = result.recognizedWords;
      if (result.finalResult && result.recognizedWords.isNotEmpty) {
        _lastResponse = '';
        _processMessage(result.recognizedWords);
      }
    });
  }

  Future<void> _processMessage(String recognizedWords) async {
    final apiUrl = _getSetting(MainSettings.backendEndpoint);

    try {
      final uri = Uri.http(apiUrl, '/processed_voice_message', {
        'transcription': recognizedWords,
        'language': _localeId,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _lastResponse = jsonResponse['message'];
        });
      } else {
        setState(() {
          _lastResponse = 'Error: Server returned ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        _lastResponse = 'Error: $error';
      });
    }
  }

  void _reset() {
    setState(() {
      _lastTranscription = '';
      _lastResponse = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              _navigateToSettingsSmooth(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                'Recognized words:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: SelectableText(
                    // If listening is active show 'Listening...', otherwise show the last recognized words / error message
                    _speechToText.isListening
                        ? 'Listening...'
                        : _speechEnabled
                            ? _lastTranscription.isEmpty
                                ? 'Tap the microphone to start listening...'
                                : _lastTranscription
                            : 'Speech not available',
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                'Assistant response:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _lastResponse,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Stack(
        children: [
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                heroTag: null,
                onPressed: _speechToText.isNotListening
                    ? _startListening
                    : _stopListening,
                tooltip: 'Listen',
                child: Icon(
                    _speechToText.isNotListening ? Icons.mic_off : Icons.mic),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  _reset();
                },
                tooltip: 'New Message',
                child: Icon(Icons.refresh),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSettingsSmooth(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutSine;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }
}
