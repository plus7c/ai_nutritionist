import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'apptemplate/apptemplate.dart';
import 'firebase_options.dart';
import 'auth/user_session_manager.dart';
import 'auth/signup.dart'; // LoginScreen 类在这个文件中

import 'chatpage/chatpage.dart';
import 'home/profile.dart';
import 'onboarding/onboarding.dart';
import 'photologger/foodloggerpage.dart';
import 'stats/stats_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载环境变量
  try {
    // 加载环境变量
    await dotenv.load(fileName: '.env');
    print(
        '环境变量加载成功: DASHSCOPE_API_KEY=${dotenv.env['DASHSCOPE_API_KEY']?.substring(0, 5)}...');
  } catch (e) {
    print('加载环境变量失败: $e');
    // 如果无法加载.env文件，使用默认值或者显示错误提示
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting();

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final UserSessionManager _sessionManager = UserSessionManager();
  bool _isInitialized = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    try {
      // 检查是否有保存的登录状态
      bool hasLoginState = await _sessionManager.hasSavedLoginState();

      setState(() {
        _isLoggedIn = hasLoginState && _sessionManager.isLoggedIn;
        _isInitialized = true;
      });

      print('登录状态检查完成: ${_isLoggedIn ? "已登录" : "未登录"}');
    } catch (e) {
      print('检查登录状态时出错: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果正在初始化，显示加载界面
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // 根据登录状态决定显示哪个页面
    Widget homeWidget;

    // 开发模式下可以设置为直接跳过登录流程
    bool devModeSkipLogin = false;

    if (_isLoggedIn || devModeSkipLogin) {
      // 已登录或开发模式跳过登录，直接进入主应用
      homeWidget = AppTemplate();
    } else {
      // 未登录，显示引导页
      homeWidget = const OnboardingScreen();
    }

    return MultiProvider(
      providers: [
        // 添加语言切换功能的 Provider
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NutrAI',
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('zh', ''), // Chinese
          ],
          home: homeWidget,
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  // ignore: unused_field
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static final List<Widget> _widgetOptions = <Widget>[
    HomeProfile(),
    FoodLoggerPage(),
    const ChatPage(),
    StatsPage(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // title: const Text('BottomNavigationBar Sample'),
          ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Photo AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Emma AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

// 添加语言切换功能的 Provider
class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('zh', '');
  static const String _localeKey = 'locale_language_code';

  LocaleProvider() {
    _loadSavedLocale();
  }

  Locale get locale => _locale;

  // 从 SharedPreferences 加载保存的语言设置
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_localeKey);

    if (savedLanguageCode != null) {
      _locale = Locale(savedLanguageCode, '');
      notifyListeners();
    }
  }

  // 更改并保存语言设置
  Future<void> changeLocale(Locale locale) async {
    _locale = locale;

    // 保存语言设置到 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);

    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NutrAI',
        locale: localeProvider.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', ''), // Chinese
          Locale('en', ''), // English
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const AppTemplate(),
        routes: {
          '/login': (context) => const LoginScreen(), // Define a route to login
        },
      ),
    );
  }
}
