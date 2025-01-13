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
                  value: _getLocale(context),
                  onChanged: (String? newValue) {
                    if (newValue != null) _setLocale(context, newValue);
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
        ],
      ),
    );
  }

  String _getLocale(BuildContext context) {
    // return context.setting<MainSettings>().get(MainSettings.locale);
    return Settings.from<MainSettings>(context).get(MainSettings.locale);
  }

  void _setLocale(BuildContext context, String localeId) async {
    await Settings.from<MainSettings>(context)
        .update(MainSettings.locale.copyWith(defaultValue: localeId));
    setState(() {});
  }
}
