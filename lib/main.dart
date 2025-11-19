import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'views/screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization (fast, required for app start)
  await EasyLocalization.ensureInitialized();

  // Set system UI overlay style for a professional appearance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.backgroundWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Start Firebase initialization in background (non-blocking)
  // The SplashScreen will wait for this to complete
  final firebaseInitialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ro')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      useOnlyLangCode: true,
      child: MyApp(firebaseInitialization: firebaseInitialization),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> firebaseInitialization;

  const MyApp({super.key, required this.firebaseInitialization});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: SplashScreen(firebaseInitialization: firebaseInitialization),
        // Localization configuration
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      ),
    );
  }
}
