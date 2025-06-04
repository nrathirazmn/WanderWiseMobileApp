import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Screens
import 'screens/forum_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/swipe_buddy_screen.dart';
import 'screens/itinerary_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/message_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/firestore_chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/expense_list_screen.dart';
import 'screens/admin_update_screen.dart';
import 'screens/landing_page.dart';
import 'screens/welcome_screen.dart';
import 'screens/travel_buddy_setup_screen.dart';
import 'screens/update_email_screen.dart';
import 'screens/change_pass_screen.dart';
import 'screens/trip_details_screen.dart';
import 'screens/daily_itinerary_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TravelBuddyApp());
}

class TravelBuddyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 86, 35, 1),
        ),
        useMaterial3: true,
      ),
      home: LandingPage(),
      routes: {
        '/admin-update': (context) => AdminUpdateScreen(),
        '/landingpage': (context) => LandingPage(),
        '/trip-details': (context) {
          final tripId = ModalRoute.of(context)?.settings.arguments as String?;
          if (tripId == null || tripId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text('Error')),
              body: Center(child: Text('Trip ID is missing')),
            );
          }
          return TripDetailsScreen(tripId: tripId);
        },
        '/daily-itinerary': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          if (args == null ||
              args['tripId'] == null ||
              args['tripTitle'] == null ||
              args['startDate'] == null ||
              args['endDate'] == null) {
            return Scaffold(
              appBar: AppBar(title: const Text("Missing Data")),
              body: const Center(child: Text("Required trip details are missing.")),
            );
          }

          return DailyItineraryScreen(
            tripId: args['tripId'],
            tripTitle: args['tripTitle'],
            startDate: args['startDate'],
            endDate: args['endDate'],
          );
        },
        '/travelbuddy-setup': (context) => TravelBuddySetupScreen(),
        '/login': (context) => LoginScreen(),
        '/change-password': (_) => ChangePasswordScreen(),
        '/update-email': (_) => UpdateEmailScreen(),
        '/welcome': (context) => WelcomeScreen(userName: ''),
        '/register': (context) => RegisterScreen(),
        '/main': (context) => MainNavigation(),
        '/itinerary': (context) => ItineraryScreen(),
        '/home': (context) => HomeScreen(),
        '/messages': (context) => MessageScreen(),
        '/expenses': (context) => ExpenseListScreen(),
        '/chat': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          final isAI = args['isAI'] ?? false;

          return isAI
              ? ChatScreen(chatWith: args['peerName'])
              : FirestoreChatScreen(
                  chatId: args['chatId'],
                  peerId: args['peerId'],
                  peerName: args['peerName'],
                  peerPhoto: args['peerPhoto'],
                );
        },
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Page Not Found')),
          body: Center(child: Text('The page "${settings.name}" does not exist.')),
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    HomeScreen(),
    ConverterScreen(),
    SwipeBuddyScreen(),
    ItineraryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
          if (kDebugMode && FirebaseAuth.instance.currentUser?.email == 'nrathirazmn@gmail.com')
            Positioned(
              bottom: 100,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: Colors.brown,
                child: Icon(Icons.admin_panel_settings),
                onPressed: () => Navigator.pushNamed(context, '/admin-update'),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 86, 35, 1),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Homepage'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Convert'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Travel Buddy'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Itinerary'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
