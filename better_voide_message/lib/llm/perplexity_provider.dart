import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:openai_dart/openai_dart.dart';

import 'available_models.dart';

class PerplexityProvider extends LlmProvider with ChangeNotifier {
  late final OpenAIClient _client;
  late final AvailableModels _model;
  late List<ChatMessage> _history;

  PerplexityProvider({
    required String apiKey,
    AvailableModels model = AvailableModels.llama3_1SonarSmall128kOnline,
    Iterable<ChatMessage> history = const [],
  }) {
    _client =
        OpenAIClient(apiKey: apiKey, baseUrl: "https://api.perplexity.ai");
    _model = model;
    _history = history.toList();
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
        origin: MessageOrigin.user, text: prompt, attachments: attachments));
    notifyListeners();

    String assistantResponse = '';

    final messages = _history
        .map((msg) => msg.origin.isUser
            ? ChatCompletionMessage.user(
                content:
                    ChatCompletionUserMessageContent.string(msg.text ?? ''),
              )
            : ChatCompletionMessage.assistant(
                content: msg.text ?? '',
              ))
        .toList();

    final stream = _client.createChatCompletionStream(
      request: CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId(_model.toString()),
        messages: messages,
      ),
    );

    await for (final res in stream) {
      final content = res.choices.first.delta.content;
      if (content != null) {
        assistantResponse += content;
        yield content;
      }
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
