import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/auth/login_page.dart';

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
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        
        final user = snapshot.data;
        
        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: user == null
              ? GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF1E1E1E), // Dark circle
                    child: Icon(Icons.person, color: Colors.white70, size: 20),
                  ),
                )
              : PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      FirebaseAuth.instance.signOut();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logget ut')),
                      );
                    }
                  },
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: const Color(0xFF2C2C2E),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF1E1E1E),
                    child: Text(
                      user.email != null && user.email!.isNotEmpty
                          ? user.email![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: const [
                          Icon(Icons.logout, color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Text('Logg ut', style: TextStyle(color: Colors.white)),
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
