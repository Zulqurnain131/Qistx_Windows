import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:qistx_app/Providers/CustomerProvider%20.dart';
import 'package:qistx_app/Providers/ProductStockProvider.dart';
import 'package:qistx_app/Providers/StatisticsProvider.dart';
import 'package:qistx_app/Providers/home_provider.dart';
import 'package:qistx_app/View/auth_screens/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 💻 Sirf Desktop platforms par Window Manager initialize hoga
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    const double targetWidth = 1480;
    const double targetHeight = 900;

    WindowOptions windowOptions = const WindowOptions(
      size: Size(targetWidth, targetHeight),
      minimumSize: Size(targetWidth, targetHeight),
      center: false,
      title: 'qistx_app',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setMinimumSize(const Size(targetWidth, targetHeight));
      await windowManager.show();
      await windowManager.maximize();
      await windowManager.focus();
    });
  }

  debugPrint("MAIN: Flutter initialized");
  await dotenv.load(fileName: ".env");
  debugPrint("MAIN: dotenv loaded");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  debugPrint("MAIN: Supabase initialized");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ProductStockProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => Statisticsprovider()),
      ],
      child: const MyApp(),
    ),
  );

  // const MyApp());
  debugPrint("MAIN: runApp called");
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  static const _deepLinkChannel = MethodChannel('qistx.app/deeplink');

  // Taake initial link sirf ek hi baar process ho (uriLinkStream se bhi
  // aa sakta hai, isliye duplicate se bachne ke liye guard rakha hai)
  bool _initialLinkHandled = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Cold start: app direct deep link se open hui ho
    _appLinks
        .getInitialLink()
        .then((uri) {
          if (uri != null && !_initialLinkHandled) {
            _initialLinkHandled = true;
            _handleDeepLink(uri);
          }
        })
        .catchError((e) {
          debugPrint('getInitialLink error: $e');
        });

    // App already chal rahi ho aur naya link stream se aaye
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _initialLinkHandled = true;
      _handleDeepLink(uri);
    }, onError: (err) => debugPrint('Deep Link Error: $err'));

    // Windows-only: jab existing instance ko doosre process se link forward ho
    _deepLinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final raw = (call.arguments as String).trim().replaceAll(
          '"',
          '',
        ); // extra safety
        final uri = Uri.tryParse(raw);
        if (uri != null) {
          _initialLinkHandled = true;
          _handleDeepLink(uri);
        }
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'qistxapp') {
      debugPrint('Handling deep link: $uri');
      Supabase.instance.client.auth.getSessionFromUrl(uri).catchError((e) {
        debugPrint('getSessionFromUrl error: $e');
      });
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'qistX App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
