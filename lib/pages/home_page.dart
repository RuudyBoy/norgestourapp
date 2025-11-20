import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background image
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/4.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1. HEADER IMAGE (Logo) - Kept for design
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 250,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 40), 

              // 
              // --- DYNAMIC SECTION: TOURNAMENTS FROM FIREBASE ---
              // 

              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Turneringer for sesongen',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    // Added white color to make it visible on background
                    color: Colors.white, 
                  ),
                ),
              ),

              const SizedBox(height: 12),
              
              // The StreamBuilder connected to Firestore
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
                
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Feil ved lasting.", style: TextStyle(color: Colors.white)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Ingen turneringer funnet.", style: TextStyle(color: Colors.white)),
                    );
                  }

                  final tournaments = snapshot.data!.docs;

                  return Column(
                    children: tournaments.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      
                      final name = data['name'] ?? 'Ukjent navn';
                      final date = data['start_date'] ?? 'Dato kommer'; 

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: ListTile(
                          leading: const Icon(Icons.emoji_events, color: Colors.blue),
                          title: Text(name),
                          subtitle: Text(date.toString()),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                             // Navigation logic will go here
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),    
              
              const SizedBox(height: 40), // Bottom spacing
            ], 
          ),
        ),
      ),
    );
  }
}