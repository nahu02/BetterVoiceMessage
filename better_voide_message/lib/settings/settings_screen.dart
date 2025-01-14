import 'package:better_voice_message/llm/available_models.dart';
import 'package:better_voice_message/llm/available_providers.dart';
import 'package:flutter/material.dart';
import 'package:settings_provider/settings_provider.dart';
import 'package:settings_ui/settings_ui.dart';

import 'settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  static const Map<String, String> _localeNames = {
    'en_US': 'English',
    'hu_HU': 'Hungarian',
    'de_DE': 'German',
    'fr_FR': 'French',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('Voice Recognition'),
            tiles: [
              SettingsTile(
                title: Text('Locale'),
                leading: Icon(Icons.language),
                trailing: DropdownButton<String>(
                  value: _getSetting(context, MainSettings.locale),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _setSetting(context, MainSettings.locale, newValue);
                    }
                  },
                  items: _localeNames.keys.map((String localeId) {
                    return DropdownMenuItem(
                      value: localeId,
                      child: Text(_localeNames[localeId]!),
                    );
                  }).toList(),
                ),
              )
            ],
          ),
          SettingsSection(
            title: Text('AI Settings'),
            tiles: [
              SettingsTile(
                title: Text('AI Provider'),
                leading: Icon(Icons.cloud),
                trailing: DropdownButton<String>(
                  value: _getSetting(context, MainSettings.aiProvider),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _setEnumSetting<AvailableProviders>(
                        context,
                        MainSettings.aiProvider,
                        AvailableProviders.values
                            .firstWhere((e) => e.toString() == newValue),
                      );
                    }
                  },
                  items: AvailableProviders.values
                      .map((AvailableProviders provider) {
                    return DropdownMenuItem(
                      value: provider.toString(),
                      child: Text(provider.toString()),
                    );
                  }).toList(),
                ),
              ),
              SettingsTile(
                title: Text('API Key'),
                leading: Icon(Icons.vpn_key),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditDialog(
                      context,
                      'Enter API Key',
                      defaultValue: _getSetting(context, MainSettings.apiKey),
                    ).then((newValue) {
                      if (newValue != null && newValue.isNotEmpty) {
                        setState(() {
                          _setSetting(context, MainSettings.apiKey, newValue);
                        });
                      }
                    });
                  },
                ),
              ),
              SettingsTile(
                title: Text('Model'),
                leading: Icon(Icons.model_training),
                trailing: SizedBox(
                  width: 200,
                  child: DropdownButton<String>(
                    value: _getSetting(context, MainSettings.model),
                    isExpanded: true,
                    menuWidth: 300,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _setEnumSetting<AvailableModels>(
                          context,
                          MainSettings.model,
                          AvailableModels.values
                              .firstWhere((e) => e.toString() == newValue),
                        );
                      }
                    },
                    items: AvailableModels.values.map((AvailableModels model) {
                      return DropdownMenuItem(
                        value: model.toString(),
                        child: Text(
                          model.toString(),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSetting(BuildContext context, BaseProperty property) {
    return Settings.from<MainSettings>(context).get(property).toString();
  }

  void _setSetting<T>(BuildContext context, Property property, T value) async {
    await Settings.from<MainSettings>(context)
        .update(property.copyWith(defaultValue: value));
    setState(() {});
  }

  void _setEnumSetting<T extends Enum>(
      BuildContext context, EnumProperty<T> property, T value) async {
    await Settings.from<MainSettings>(context)
        .update(property.copyWith(defaultValue: value));
    setState(() {});
  }

  Future<String?> _showEditDialog(BuildContext context, String title,
      {String? defaultValue}) async {
    return await showDialog<String>(
      context: context,
      builder: (ctx) {
        String input = defaultValue ?? '';
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: TextEditingController(text: defaultValue),
            onChanged: (value) => input = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(input),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
