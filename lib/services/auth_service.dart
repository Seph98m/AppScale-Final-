import 'dart:conimport 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
‎import 'package:connectivity_plus/connectivity_plus.dart';
‎
‎class AuthService {
‎  // TODO: palitan ng actual IP mo
‎  static const String baseUrl = 'http://192.168.1.100:3000/api';
‎
‎  static Future<bool> isOnline() async {
‎    final result = await Connectivity().checkConnectivity();
‎    return result != ConnectivityResult.none;
‎  }
‎
‎  static Future<Map<String, dynamic>> login(
‎      String email, String password) async {
‎    final box = Hive.box('authBox');
‎    final online = await isOnline();
‎
‎    if (online) {
‎      // ── ONLINE: call MySQL via REST API ──
‎      try {
‎        final response = await http.post(
‎          Uri.parse('$baseUrl/login'),
‎          headers: {'Content-Type': 'application/json'},
‎          body: jsonEncode({'email': email, 'password': password}),
‎        ).timeout(const Duration(seconds: 10));
‎
‎        final data = jsonDecode(response.body);
‎
‎        if (response.statusCode == 200 && data['success'] == true) {
‎          // I-save sa Hive para sa offline
‎          await box.put('user', {
‎            'email': email,
‎            'password': password, // hashed na sana galing sa server
‎            'name': data['user']['name'],
‎            'role': data['user']['role'],
‎            'barangay': data['user']['barangay'],
‎          });
‎
‎          return {
‎            'success': true,
‎            'source': 'online',
‎            'user': data['user'],
‎          };
‎        } else {
‎          return {
‎            'success': false,
‎            'message': data['message'] ?? 'Invalid credentials.',
‎          };
‎        }
‎      } catch (e) {
‎        // Kung nag-fail ang API call, fallback sa Hive
‎        return await _offlineLogin(email, password, fallback: true);
‎      }
‎    } else {
‎      // ── OFFLINE: check Hive ──
‎      return await _offlineLogin(email, password);
‎    }
‎  }
‎
‎  static Future<Map<String, dynamic>> _offlineLogin(
‎      String email, String password,
‎      {bool fallback = false}) async {
‎    final box = Hive.box('authBox');
‎    final savedUser = box.get('user');
‎
‎    if (savedUser != null &&
‎        savedUser['email'] == email &&
‎        savedUser['password'] == password) {
‎      return {
‎        'success': true,
‎        'source': fallback ? 'offline-fallback' : 'offline',
‎        'user': savedUser,
‎      };
‎    }
‎
‎    return {
‎      'success': false,
‎      'message': fallback
‎          ? 'Server unreachable. Offline credentials did not match.'
‎          : 'No internet. Please connect to login for the first time.',
‎    };
‎  }
‎
‎  static Future<vo }