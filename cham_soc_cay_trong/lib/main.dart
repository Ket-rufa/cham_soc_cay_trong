import 'package:camera/camera.dart';
import 'package:cham_soc_cay_trong/l10n/app_localizations.dart';
import 'package:cham_soc_cay_trong/l10n/language_controller.dart';
import 'package:cham_soc_cay_trong/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final languageController = LanguageController();
  await languageController.load();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }

  runApp(MyApp(languageController: languageController));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.languageController,
  });

  final LanguageController languageController;

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      controller: languageController,
      child: AnimatedBuilder(
        animation: languageController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: languageController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            onGenerateTitle: (context) => context.tr('app.title'),
            theme: ThemeData(
              primarySwatch: Colors.green,
            ),
            home: LoginScreen(),
          );
        },
      ),
    );
  }
}
