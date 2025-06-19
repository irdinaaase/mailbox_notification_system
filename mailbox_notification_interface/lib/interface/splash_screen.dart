import 'package:flutter/material.dart';
import 'package:mailbox_notification_system/interface/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('asset/jpg/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // 🟡 Title
                const Padding(
                  padding: EdgeInsets.only(bottom: 2, top: 180), // Move it up
                  child: Text(
                  'Mailbox Notification System',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                ),

                // 🟡 Title
                const Text(
                  '(Mario Version)',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Mario64',
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // 🟡 Loading Bar
                const Padding(
                  padding: EdgeInsets.only(top: 10), // Move it up
                  child: SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
                
                // 🟡 Mario Box
                  Image.asset(
                    'asset/gif/mariobox.gif',
                    width: 470,
                    height: 550,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}