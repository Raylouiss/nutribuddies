import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutribuddies/firebase_options.dart';
import 'package:nutribuddies/models/user.dart';
import 'package:nutribuddies/screens/splash_screen.dart';
import 'package:nutribuddies/services/auth.dart';
import 'package:nutribuddies/services/seeding.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Seed initial food data
  final SeedingData seed = SeedingData();
  await seed.seedingData();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamProvider<Users?>.value(
        value: AuthService().user,
        initialData: null,
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        ));
  }
}
