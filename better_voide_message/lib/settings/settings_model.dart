import 'package:better_voice_message/llm/available_models.dart';
import 'package:better_voice_message/llm/available_providers.dart';
import 'package:settings_provider/settings_provider.dart';

class MainSettings extends SettingsModel {
  @override
  List<BaseProperty> get properties => [locale, apiKey, model, aiProvider];

  static const Property<String> locale = Property(
    id: 'locale',
    defaultValue: 'en_US',
    isLocalStored: true,
  );

  static const Property<String> apiKey = Property(
    id: 'apiKey',
    defaultValue: '???',
    isLocalStored: true,
  );

  static const EnumProperty<AvailableModels> model = EnumProperty(
    id: 'model',
    values: AvailableModels.values,
    defaultValue: AvailableModels.llama3_1SonarLarge128kOnline,
    isLocalStored: true,
  );

  static const EnumProperty<AvailableProviders> aiProvider = EnumProperty(
    id: 'aiProvider',
    values: AvailableProviders.values,
    defaultValue: AvailableProviders.perplexity,
    isLocalStored: true,
  );
}
