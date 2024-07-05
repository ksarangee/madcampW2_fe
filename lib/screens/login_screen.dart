import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter/services.dart'; // 이 줄을 추가하여 PlatformException을 사용 가능하게 함

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _afterSuccess() async {
    try {
      User user = await UserApi.instance.me();
      print('사용자 정보 요청 성공'
          '\n회원번호: ${user.id}'
          '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
          '\n이메일: ${user.kakaoAccount?.email}');
      // 로그인 성공 시 홈 화면으로 이동
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      print('사용자 정보 요청 실패 $error');
    }
  }

  Future<void> _signInWithKakao() async {
    if (await isKakaoTalkInstalled()) {
      try {
        setState(() {
          _isLoading = true;
        });
        await UserApi.instance.loginWithKakaoTalk();
        await _afterSuccess();
        print('카카오톡으로 로그인 성공');
      } catch (error) {
        print('카카오톡으로 로그인 실패 $error');
        if (error is PlatformException && error.code == 'CANCELED') {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        try {
          await UserApi.instance.loginWithKakaoAccount();
          await _afterSuccess();
          print('카카오계정으로 로그인 성공');
        } catch (error) {
          print('카카오계정으로 로그인 실패 $error');
        }
      }
    } else {
      try {
        setState(() {
          _isLoading = true;
        });
        await UserApi.instance.loginWithKakaoAccount();
        await _afterSuccess();
        print('카카오계정으로 로그인 성공');
      } catch (error) {
        print('카카오계정으로 로그인 실패 $error');
      }
    }
    setState(() {
      _isLoading = false;
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _signInWithKakao,
                    child: const Text('Sign in with Kakao'),
                  ),
                ],
              ),
            ),
    );
  }
}