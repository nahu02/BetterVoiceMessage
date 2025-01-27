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
            title: Text("Backend"),
            tiles: [
              SettingsTile(
                title: Text('Endpoint'),
                leading: Icon(Icons.cloud),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditDialog(
                      context,
                      'Backend URL',
                      defaultValue:
                          _getSetting(context, MainSettings.backendEndpoint),
                    ).then((newValue) {
                      if (newValue != null && newValue.isNotEmpty) {
                        setState(() {
                          _setSetting(
                              context, MainSettings.backendEndpoint, newValue);
                        });
                      }
                    });
                  },
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
