import 'package:nutrai/onboarding/onboarding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../onboarding/userstatsonboarding.dart';
import 'user_session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // 添加 Google Sign In 配置
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
  );
  final UserSessionManager _sessionManager = UserSessionManager();
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    // 检查是否有保存的登录状态
    _checkSavedLoginState();
  }

  // 检查是否有保存的登录状态，如果有则自动登录
  Future<void> _checkSavedLoginState() async {
    setState(() {
      _isCheckingSession = true;
    });

    try {
      if (await _sessionManager.hasSavedLoginState()) {
        print('检测到保存的登录状态，尝试自动登录');
        
        // 如果已经有登录用户，直接进入主页面
        if (_sessionManager.isLoggedIn) {
          print('用户已登录: ${_sessionManager.currentUser?.uid}');
          _navigateToMainPage();
          return;
        }
        
        // 尝试从Firebase恢复登录状态
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('从Firebase恢复登录状态成功: ${currentUser.uid}');
          _navigateToMainPage();
        } else {
          print('无法从Firebase恢复登录状态，需要重新登录');
        }
      } else {
        print('没有检测到保存的登录状态');
      }
    } catch (e) {
      print('检查登录状态时出错: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
      }
    }
  }

  // 导航到主页面
  void _navigateToMainPage() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserStatsOnboarding()),
      );
    }
  }

  Future<User?> _signInWithGoogle() async {
    try {
      print('开始 Google 登录流程...');
      
      // 先检查 Google Play Services 是否可用
      if (!await _googleSignIn.isSignedIn()) {
        print('检查 Google Play Services...');
        await _googleSignIn.signOut(); // 清除之前的登录状态
      }
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('用户取消了 Google 登录');
        return null;
      }
      
      print('获取 Google 认证信息...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('创建 Firebase 凭据...');
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('使用凭据进行 Firebase 身份验证...');
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('Firebase 身份验证成功: ${userCredential.user?.uid}');
      
      // 保存登录状态
      if (userCredential.user != null) {
        await _sessionManager.saveLoginState(userCredential.user!);
      }
      
      return userCredential.user;
    } catch (e) {
      print('Google 登录过程中发生错误: $e');
      // 添加更详细的错误处理
      if (e is FirebaseAuthException) {
        print('Firebase Auth 错误码: ${e.code}');
        print('错误信息: ${e.message}');
      }
      return null;
    }
}

  Future<User?> _signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // 保存登录状态
      if (userCredential.user != null) {
        await _sessionManager.saveLoginState(userCredential.user!);
      }
      
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果正在检查会话，显示加载指示器
    if (_isCheckingSession) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[100]!, Colors.green[50]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.local_dining,
                size: 100,
                color: Colors.green[700],
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to nutrai',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your personal nutrition assistant',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () async {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: 10),
                      Text(
                        'Back to Onboarding',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () async {
                    User? user = await _signInWithGoogle();
                    if (user != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const UserStatsOnboarding()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_sharp),
                      SizedBox(width: 10),
                      Text(
                        'Sign In With Google',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'By signing in, you agree to our Terms and Privacy Policy',
                style: TextStyle(
                  color: Colors.green[800],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
