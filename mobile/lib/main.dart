export 'src/app.dart';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fr'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      child: const BoboExpressApp(),
    ),
  );
}
