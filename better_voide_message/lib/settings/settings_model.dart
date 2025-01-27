import 'package:settings_provider/settings_provider.dart';

class MainSettings extends SettingsModel {
  @override
  List<BaseProperty> get properties => [locale, backendEndpoint];

  static const Property<String> locale = Property(
    id: 'locale',
    defaultValue: 'en_US',
    isLocalStored: true,
  );

  static const Property<String> backendEndpoint = Property(
    id: 'backendEndpoint',
    defaultValue: '???',
    isLocalStored: true,
  );
}
