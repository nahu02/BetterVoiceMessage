import 'package:better_voide_message/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:settings_provider/settings_provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'settings/settings_model.dart';

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
  String _lastWords = '';
  String _localeId = '';

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

  void _loadLocale() async {
    setState(() {
      _localeId = Settings.from<MainSettings>(context).get(MainSettings.locale);
    });
  }

  void _listenToLocale() {
    _localeId =
        Settings.listenFrom<MainSettings>(context).get(MainSettings.locale);
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
    );
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
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
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  // If listening is active show 'Listening...', otherwise show the last recognized words / error message
                  _speechToText.isListening
                      ? 'Listening...'
                      : _speechEnabled
                          ? _lastWords.isEmpty
                              ? 'Tap the microphone to start listening...'
                              : _lastWords
                          : 'Speech not available',
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            // If not yet listening for speech start, otherwise stop
            _speechToText.isNotListening ? _startListening : _stopListening,
        tooltip: 'Listen',
        child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
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
