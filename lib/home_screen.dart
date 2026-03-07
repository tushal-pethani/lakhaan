import 'dashboard/dashboard_screen.dart';

import 'login/login_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.isLoggedIn = false});
  final bool isLoggedIn;
  @override
  Widget build(BuildContext context) {
    return isLoggedIn ? DashboardScreen() : LoginScreen();
  }
}