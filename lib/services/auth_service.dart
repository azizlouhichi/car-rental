// lib/services/auth_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _currentUser;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get currentUser => _currentUser;

  AuthService() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _currentUser = json.decode(userJson);
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      await _saveAuthData(
        response['access'],
        response['refresh'],
        {'username': username},
      );
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> signup(Map<String, dynamic> userData, String role) async {
    try {
      final data = {...userData, 'role': role};
      final response = await _apiService.signup(data);

      // Auto-login after signup
      if (response['access'] != null) {
        await _saveAuthData(
          response['access'],
          response['refresh'],
          response['user'] ?? {'username': userData['username']},
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Signup error: $e');
      return false;
    }
  }

  Future<void> _saveAuthData(
      String token,
      String refreshToken,
      Map<String, dynamic> user,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userKey, json.encode(user));

    _token = token;
    _refreshToken = refreshToken;
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _apiService.refreshToken(_refreshToken!);
      await _saveAuthData(
        response['access'],
        _refreshToken!,
        _currentUser ?? {},
      );
      return true;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);

    _token = null;
    _refreshToken = null;
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    if (_token == null) return false;
    return true;
  }

  ApiService getApiService() {
    return ApiService(token: _token);
  }
}