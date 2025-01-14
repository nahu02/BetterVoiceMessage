import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:openai_dart/openai_dart.dart';

import 'available_models.dart';

class PerplexityProvider extends LlmProvider with ChangeNotifier {
  late final OpenAIClient _client;
  late final AvailableModels _model;
  late List<ChatMessage> _history;
  late final String _systemInstruction;

  PerplexityProvider({
    required String apiKey,
    AvailableModels model = AvailableModels.llama3_1SonarSmall128kOnline,
    Iterable<ChatMessage> history = const [],
    String systemInstruction = '',
  }) {
    _client =
        OpenAIClient(apiKey: apiKey, baseUrl: "https://api.perplexity.ai");
    _model = model;
    _history = history.toList();
    _systemInstruction = systemInstruction;
  }

  @override
  Stream<String> generateStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) {
    return sendMessageStream(prompt, attachments: attachments);
  }

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    if (attachments.isNotEmpty) {
      throw UnimplementedError('Attachments are not supported');
    }

    // Add user message to history
    _history.add(ChatMessage(
      origin: MessageOrigin.user,
      text: prompt,
      attachments: attachments,
    ));
    notifyListeners();

    List<ChatCompletionMessage> messages = [];

    if (_systemInstruction.isNotEmpty) {
      messages.add(ChatCompletionMessage.system(content: _systemInstruction));
    }

    messages.addAll(_history.map((msg) {
      if (msg.origin.isUser) {
        return ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.string(msg.text ?? ''),
        );
      } else {
        return ChatCompletionMessage.assistant(
          content: msg.text ?? '',
        );
      }
    }));

    String assistantResponse = '';

    try {
      final stream = _client.createChatCompletionStream(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId(_model.toString()),
          messages: messages,
          // Default is 0 which the Perplexity API does not accept. Perplexity.ai uses 1 as default
          frequencyPenalty: 1,
        ),
      );

      await for (final res in stream) {
        final content = res.choices.first.delta.content;
        if (content != null) {
          assistantResponse += content;
          yield content;
        }
      }
    } on OpenAIClientException catch (e) {
      print('OpenAIException: ${e.toString()}');
      rethrow;
    }

    // Add assistant response to history
    _history.add(ChatMessage(
        origin: MessageOrigin.llm, text: assistantResponse, attachments: []));

    notifyListeners();
  }

  @override
  List<ChatMessage> get history => _history;

  @override
  set history(Iterable<ChatMessage> history) {
    _history = history.toList();
    notifyListeners();
  }
}
