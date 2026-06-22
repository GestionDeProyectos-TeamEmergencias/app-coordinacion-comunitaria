import 'package:app_coordinacion_comunitaria/app/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';

class UnauthorizedAccessPage extends StatelessWidget {
  const UnauthorizedAccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.unauthorizedAccess),
        automaticallyImplyLeading: false, // Hide back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_person_rounded,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                AppStrings.unauthorizedAccessTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                AppStrings.unauthorizedAccessMessage,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text(AppStrings.goToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
