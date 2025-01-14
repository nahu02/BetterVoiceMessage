import 'package:better_voice_message/llm/available_models.dart';
import 'package:better_voice_message/llm/available_providers.dart';
import 'package:better_voice_message/llm/perplexity_provider.dart';
import 'package:better_voice_message/settings/settings_model.dart';
import 'package:better_voice_message/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:settings_provider/settings_provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  late LlmProvider _llmProvider;
  String _lastAssistantResponse = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadLocale();
    _loadLlmProvider();
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

  void _loadLlmProvider() {
    AvailableProviders provider = _getSetting(MainSettings.aiProvider);
    String apiKey = _getSetting(MainSettings.apiKey);
    AvailableModels model = _getSetting(MainSettings.model);

    String systemInstruction = '''
    You are a system that helps users turn their voice messages into text.
    Your input is a transcription of a voice message.
    Your task is to generate a text message that would be the equivalent text message of the voice message.
    Your tone respects the tone of the voice message.
    You are aware you may not have all the information needed to generate a perfect text message, but this does not mean you should add any information that is not present in the voice message.
    You MUST NOT add any information that is not present in the voice message.
    Your output should be a text message that contains proper punctuation and grammar, cuts out stuttering, and is generally well-formed.
    Your output should be a text message that is a good representation of the voice message, and nothing more.
    ''';

    switch (provider) {
      case AvailableProviders.perplexity:
        setState(() {
          _llmProvider = PerplexityProvider(
            apiKey: apiKey,
            model: model,
            systemInstruction: systemInstruction,
          );
        });
      // If more providers are implemented, add them here
      // All AvailableProviders must be handled here
    }
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
      _lastWords = result.recognizedWords;
      if (result.finalResult && result.recognizedWords.isNotEmpty) {
        _lastAssistantResponse = '';
        _callLLM(result.recognizedWords);
      }
    });
  }

  void _callLLM(String recognizedWords) {
    _llmProvider.generateStream(recognizedWords).listen((response) {
      setState(() {
        _lastAssistantResponse += response;
      });
    }, onError: (error) {
      setState(() {
        _lastAssistantResponse = 'Error: $error';
      });
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
                child: Text(
                  _lastAssistantResponse,
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
