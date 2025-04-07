import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户会话管理类，负责处理用户登录状态的持久化
class UserSessionManager {
  static final UserSessionManager _instance = UserSessionManager._internal();
  
  // 单例模式
  factory UserSessionManager() => _instance;
  
  UserSessionManager._internal();
  
  // Firebase Auth 实例
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 当前用户
  User? get currentUser => _auth.currentUser;
  
  // 检查用户是否已登录
  bool get isLoggedIn => currentUser != null;
  
  /// 保存用户登录状态到 SharedPreferences
  Future<void> saveLoginState(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', user.uid);
    
    // 保存用户基本信息，便于快速访问
    if (user.displayName != null) {
      await prefs.setString('userName', user.displayName!);
    }
    if (user.email != null) {
      await prefs.setString('userEmail', user.email!);
    }
    if (user.photoURL != null) {
      await prefs.setString('userPhotoUrl', user.photoURL!);
    }
    
    print('用户登录状态已保存: ${user.uid}');
  }
  
  /// 从 SharedPreferences 清除用户登录状态
  Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userPhotoUrl');
    
    print('用户登录状态已清除');
  }
  
  /// 检查 SharedPreferences 中是否有保存的登录状态
  Future<bool> hasSavedLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
  
  /// 获取保存的用户 ID
  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
  
  /// 登出用户并清除登录状态
  Future<void> signOut() async {
    await _auth.signOut();
    await clearLoginState();
  }
}
