// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

// ignore: use_key_in_widget_constructors
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Adjust duration as needed
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Navigate to the next screen after animation completes
        Navigator.pushReplacementNamed(context, '/screen1');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Change as per your design
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Your logo image
                  Image.asset(
                    'assets/icon.png', // Replace with your logo path
                    width: 150, // Adjust size as needed
                    height: 150,
                  ),
                  const SizedBox(height: 20), // Adjust spacing
                  // Your app name or text
                  const Text(
                    'AuroraTrack',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Change text color
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 5,
            left: 5,
              child: Text(
                'Version v1.0.0.0',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                ),
              ),
          ),
          const Positioned(
            top: 5,
            right: 5,
              child: Text(
                '@garv.it',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                ),
              ),
          ),
          const Positioned(
            bottom: 5,
            left: 5,
              child: Text(
                'All rights reserved to the developer @garv.it',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                ),
              ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // Properly dispose the animation controller
    super.dispose();
  }
}
