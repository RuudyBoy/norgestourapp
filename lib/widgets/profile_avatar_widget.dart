import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:norges_tour_app/pages/auth/login_page.dart';
import 'package:norges_tour_app/theme/app_colors.dart';
import 'package:norges_tour_app/theme/app_text_styles.dart';
import 'package:norges_tour_app/theme/app_theme.dart';

class ProfileAvatarWidget extends StatelessWidget {
  const ProfileAvatarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
            ),
          );
        }

        final user = snapshot.data;

        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: user == null
              ? GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.sand2,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Icon(Icons.person_outline, color: AppColors.ink3, size: 20),
                  ),
                )
              : PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      FirebaseAuth.instance.signOut();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Logget ut', style: AppText.uiBody.copyWith(color: AppColors.ink)),
                          backgroundColor: AppColors.sand0,
                        ),
                      );
                    }
                  },
                  offset: const Offset(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusRow)),
                  color: AppColors.sand0,
                  elevation: 8,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.email != null && user.email!.isNotEmpty ? user.email![0].toUpperCase() : 'U',
                        style: AppText.dispKicker(16).copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: AppColors.coral, size: 18),
                          const SizedBox(width: 12),
                          Text('Logg ut', style: AppText.uiBody),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
