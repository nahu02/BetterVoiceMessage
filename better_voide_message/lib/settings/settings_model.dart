import 'package:settings_provider/settings_provider.dart';

class MainSettings extends SettingsModel {
  @override
  List<BaseProperty> get properties => [locale];

  static const Property<String> locale = Property(
    id: 'locale',
    defaultValue: 'en_US',
    isLocalStored: true,
  );
}
