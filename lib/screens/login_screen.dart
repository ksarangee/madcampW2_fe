import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // shared_preferences 패키지 임포트

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _afterSuccess(OAuthToken token) async {
    try {
      User user = await UserApi.instance.me();
      print('사용자 정보 요청 성공'
          '\n회원번호: ${user.id}'
          '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
          '\n이메일: ${user.kakaoAccount?.email}');

      await _saveToken(token); // 토큰 저장
      await _sendUserInfoToServer(user);
      print('사용자 정보 서버 전송 성공');

      // 모든 데이터가 준비된 후 홈 화면으로 이동
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
      print('홈 화면으로 이동');
    } catch (error) {
      print('사용자 정보 요청 실패 $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToken(OAuthToken token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token.accessToken);
    // refreshToken이 null일 경우 빈 문자열을 기본값으로 사용
    await prefs.setString('refreshToken', token.refreshToken ?? '');
    print('토큰 저장 성공');
  }

  Future<void> _sendUserInfoToServer(User user) async {
    final response = await http.post(
      Uri.parse('http://172.10.7.100/kakao_login'), // 실제 서버 URL로 변경하세요
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'kakao_id': user.id.toString(), // String?을 String으로 변환
        'nickname': user.kakaoAccount?.profile?.nickname ??
            'Unknown', // String?을 String으로 변환
      }),
    );

    if (response.statusCode == 200) {
      // 서버에 사용자 정보 전송 성공하면 SharedPreferences에 닉네임 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'userNickname', user.kakaoAccount?.profile?.nickname ?? 'Unknown');
      print('닉네임 저장 성공');
    } else {
      throw Exception('Failed to send user info to server');
    }
  }

  Future<void> _signInWithKakao() async {
    if (await isKakaoTalkInstalled()) {
      try {
        setState(() {
          _isLoading = true;
        });
        OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
        print('카카오톡으로 로그인 성공');
        await _afterSuccess(token);
      } catch (error) {
        print('카카오톡으로 로그인 실패 $error');
        if (error is PlatformException && error.code == 'CANCELED') {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        try {
          OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
          print('카카오계정으로 로그인 성공');
          await _afterSuccess(token);
        } catch (error) {
          print('카카오계정으로 로그인 실패 $error');
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      try {
        setState(() {
          _isLoading = true;
        });
        OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
        print('카카오계정으로 로그인 성공');
        await _afterSuccess(token);
      } catch (error) {
        print('카카오계정으로 로그인 실패 $error');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.25,
                  left: 0,
                  right: 0,
                  child: const Text(
                    '손 끝에서 시작되는\n지식의 조각들,',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontFamily: 'IBMPlexSansKR',
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Center(
                  child: SizedBox(
                    width:
                        MediaQuery.of(context).size.width * 0.3, // 화면 너비의 60%
                    child: Image.asset(
                      'assets/images/tidbitslogo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.1,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _signInWithKakao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEEC981),
                        side: const BorderSide(color: Colors.brown, width: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/kakaologo.png',
                            height: 24, // 텍스트 크기에 맞춰 조정
                            width: 24, // 텍스트 크기에 맞춰 조정
                          ),
                          const SizedBox(width: 10), // 로고와 텍스트 사이 간격
                          const Text(
                            'Start with Kakao',
                            style: TextStyle(
                                color: Color(0xFF350B08),
                                fontFamily: 'IBMPlexSansKR'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
