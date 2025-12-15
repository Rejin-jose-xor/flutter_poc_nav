import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Full-screen, no app bar or bottom nav.
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      // No appBar
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // app logo / image
              const ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Color.fromARGB(255, 30, 24, 61),      // any color you want
                  BlendMode.srcIn, // blend mode for recoloring
                ),
                child: FlutterLogo(size: 120),
              ),
              const SizedBox(height: 24),
               Text(
                'Welcome to Expenses',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Track your spending easily.\nTap continue to enter the app.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w400
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: (){
                  GoRouter.of(context).go('/expenses');
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty .all(
                    Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
