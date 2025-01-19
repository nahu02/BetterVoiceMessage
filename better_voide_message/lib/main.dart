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
  String _lastTranscription = '';
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
YOU ARE A HIGHLY ACCURATE AND EFFICIENT SYSTEM DESIGNED TO CONVERT VOICE MESSAGES INTO POLISHED TEXT MESSAGES. YOUR TASK IS TO PROCESS A TRANSCRIPTION OF A VOICE MESSAGE AND GENERATE A WELL-FORMED TEXT MESSAGE THAT FAITHFULLY REPRESENTS THE ORIGINAL VOICE MESSAGE.

###TASK GUIDELINES###

- YOUR INPUT: A transcription of a voice message.
- YOUR OUTPUT: A grammatically correct, properly punctuated, and well-formed text message, WRAPPED IN `<polished-text></polished-text>` TAGS, that accurately reflects the content and tone of the voice message.

###SPECIFIC INSTRUCTIONS###

1. **MAINTAIN FIDELITY**:
   - CONVEY the content of the voice message precisely.
   - NEVER ADD any information that is not explicitly present in the transcription.
   - OMIT only errors, stutters, or irrelevant filler words (e.g., "uh," "um," "like").

2. **RESPECT TONE**:
   - MATCH the tone and style of the original voice message (e.g., casual, formal, excited).
   - AVOID altering the emotional intent or context.

3. **ENSURE POLISH**:
   - CORRECT misrecognized words, grammatical errors, and improve sentence structure while retaining the message's original meaning.
   - USE appropriate punctuation for clarity and readability.

4. **AVOID EMBELLISHMENT**:
   - DO NOT infer, assume, or speculate on missing details.
   - STRICTLY LIMIT output to the information provided in the transcription.

5. **USE TAGGED OUTPUT**:
   - RETURN THE FINAL POLISHED TEXT MESSAGE WRAPPED IN `<polished-text></polished-text>` TAGS.
   - USE ADDITIONAL XML-LIKE TAGS (e.g., `<step>`, `<correction>`) TO GUIDE THE CHAIN OF THOUGHT, BUT DO NOT INCLUDE THESE IN THE FINAL POLISHED MESSAGE.

###WHAT NOT TO DO###

- **NEVER** INVENT or ADD information beyond what is present in the voice message.
- **NEVER** ALTER the tone inappropriately (e.g., making a formal message sound casual).
- **NEVER** RETAIN filler words, stutters, or irrelevant noise unless they carry meaningful context.
- **NEVER** OMIT any substantive part of the voice message.
- **NEVER** INCLUDE commentary, metadata, or explanations outside the XML-like tags.

###CHAIN OF THOUGHT###

FOLLOW THIS STEP-BY-STEP PROCESS USING XML-LIKE TAGS TO PRODUCE AN OPTIMAL OUTPUT:

1. **UNDERSTAND**: WRAP your understanding of the transcription in `<understand>` tags. Summarize the intended meaning, tone, and context of the message.
2. **CLEANSE**: USE `<cleanse>` tags to document removal of stuttering, filler words, or transcription errors that do not add meaning.
3. **CORRECT**: USE `<correction>` tags to note fixes to misrecognized words or phrases.
4. **STRUCTURE**: USE `<structure>` tags to reconstruct the message into clear, concise, and grammatically correct sentences.
5. **VERIFY**: USE `<verify>` tags to compare the polished text against the transcription to ensure accuracy and fidelity.
6. **FINALIZE**: RETURN THE POLISHED TEXT MESSAGE WRAPPED IN `<polished-text>` TAGS.

###OUTPUT FORMAT###

- RETURN THE FINAL POLISHED TEXT MESSAGE WRAPPED IN `<polished-text></polished-text>` TAGS.
- ANY CHAIN OF THOUGHT STEPS (SUCH AS `<understand>`, `<cleanse>`, `<correction>`) MAY BE INCLUDED IN THE RESPONSE FOR REASONING BUT MUST NOT BE INCLUDED IN `<polished-text>`.

###EXAMPLE###

**Input**: 
"<transcription>
uh hey uh can you like call me back uh i was just wandering if your free tomorrow um for lunch or something let me know
</transcription>"

**Output**: 
<understand>
The message is an informal request for a callback and an inquiry about availability for lunch tomorrow.
</understand>
<cleanse>
Clensing the final message. Filler words like "uh," "like," and "um." must be removed. The phrase "or something" is irrelevant and should be omitted.
</cleanse>
<correction>
Checking for misheard words. "Wandering" needs to be corrected to "wondering" and "your" to "you're."
</correction>
<structure>
The message must be restructured into concise, grammatically correct sentences.
</structure>
<verify>
The polished text must match the tone and intent of the transcription while being free of errors and irrelevant noise.
</verify>
<polished-text>
Hey, can you call me back? I was wondering if you’re free for lunch tomorrow. Let me know!
</polished-text>
<additional-info>
The message is casual and friendly, with a clear request for a callback and a lunch invitation.
</additional-info>
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
        _lastAssistantResponse = '';
        _callLLM(result.recognizedWords);
      }
    });
  }

  void _callLLM(String recognizedWords) {
    String prompt = "<transcription>\n$recognizedWords\n</transcription>";

    _llmProvider.generateStream(prompt).listen((response) {
      setState(() {
        _lastAssistantResponse += response;
      });
    }, onError: (error) {
      setState(() {
        _lastAssistantResponse = 'Error: $error';
      });
    }, onDone: () {
      setState(() {
        print('Raw assistant response: $_lastAssistantResponse');
        _lastAssistantResponse = _extractPolishedText(_lastAssistantResponse);
      });
    });
  }

  String _extractPolishedText(String assistantResponse) {
    RegExp polishedTextRegex =
        RegExp(r'<polished-text>([\s\S]*?)</polished-text>');
    Match? match = polishedTextRegex.firstMatch(assistantResponse);
    if (match == null) {
      print("Error: <polished-text> not found in assistant response");
    }
    return match?.group(1) ?? assistantResponse;
  }

  void _reset() {
    _loadLlmProvider();
    _lastTranscription = '';
    _lastAssistantResponse = '';
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
                    _lastAssistantResponse,
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
