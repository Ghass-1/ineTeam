import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // Accès à l'utilisateur connecté et à la collection Firestore
  final currentUser = FirebaseAuth.instance.currentUser!;
  final CollectionReference matchesCollection = 
      FirebaseFirestore.instance.collection('matches');

  // Fonction pour afficher la fenêtre de création de match
  void _showCreateMatchDialog() {
    String selectedSport = "Football";
    String lieu = "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Organiser un match"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedSport,
              items: ["Football", "Basket-ball", "Volley-ball", "Ping-pong"]
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => selectedSport = val!,
              decoration: const InputDecoration(labelText: "Sport"),
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Lieu (ex: City Foot)"),
              onChanged: (val) => lieu = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              if (lieu.isNotEmpty) {
                // Envoi des données vers Firebase Firestore
                matchesCollection.add({
                  'sport': selectedSport,
                  'lieu': lieu,
                  'organisateur': currentUser.email,
                  'date': Timestamp.now(),
                  'joueurs': [currentUser.email], // Le créateur est inscrit d'office
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ineTeam - Matchs"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      // Le StreamBuilder écoute Firestore en temps réel
      body: StreamBuilder<QuerySnapshot>(
        stream: matchesCollection.orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Erreur de chargement"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return const Center(child: Text("Aucun match pour le moment."));
          }

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final match = documents[index].data() as Map<String, dynamic>;
              final List joueurs = match['joueurs'] ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.sports, color: Colors.green),
                  title: Text("${match['sport']} @ ${match['lieu']}"),
                  subtitle: Text("Organisé par: ${match['organisateur']}\nJoueurs inscrits: ${joueurs.length}"),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Logique pour rejoindre le match
                      if (!joueurs.contains(currentUser.email)) {
                        documents[index].reference.update({
                          'joueurs': FieldValue.arrayUnion([currentUser.email])
                        });
                      }
                    },
                    child: const Text("Rejoindre"),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMatchDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}