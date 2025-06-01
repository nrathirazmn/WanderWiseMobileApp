// // AuthScreen is now a simple router between LoginScreen and RegisterScreen

// import 'package:flutter/material.dart';
// import 'login_screen.dart';
// import 'register_screen.dart';

// class AuthScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: const Color.fromARGB(255, 86, 35, 1),
//           title: Text('WanderWise', style: TextStyle(color: Colors.white)),
//           centerTitle: true,
//           bottom: TabBar(
//             tabs: [
//               Tab(text: 'Login'),
//               Tab(text: 'Register'),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             LoginScreen(),
//             RegisterScreen(),
//           ],
//         ),
//       ),
//     );
//   }
// }
