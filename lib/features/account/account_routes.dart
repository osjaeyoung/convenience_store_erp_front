import 'package:flutter/material.dart';

import 'screens/account_settings_menu_screen.dart';

void openAccountSettingsMenu(BuildContext context) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const AccountSettingsMenuScreen(),
    ),
  );
}
