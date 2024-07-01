import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secondbrand/screens/detail_screen.dart';
import 'package:secondbrand/screens/post_screen.dart';
import 'package:secondbrand/screens/profile_screen.dart';
import 'package:secondbrand/services/themeprov.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secondbrand/screens/sign_in_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SignInScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            backgroundColor:
                themeProvider.isDarkMode ? Colors.black : Colors.white,
            actions: [
              IconButton(
                onPressed: () {
                  signOut(context);
                },
                icon: const Icon(Icons.logout),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => ProfileScreen()));
                },
                icon: const Icon(Icons.person),
              ),
              IconButton(
                icon: Stack(
                  children: [
                    Icon(Icons.notifications),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  // Handle the notification button press
                },
              )
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('test').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return Text('Loading....');
                default:
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot documentSnapshot =
                          snapshot.data!.docs[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(
                                documentId: documentSnapshot.id,
                                imageUrl: documentSnapshot['image_url'],
                                description: documentSnapshot['deskripsi'],
                                timestamp: documentSnapshot['timestamp'],
                                userEmail: documentSnapshot['user_email'],
                                latitude: documentSnapshot['latitude'],
                                longitude: documentSnapshot['longitude'],
                              ),
                            ),
                          );
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(
                              'Deskripsi : ${documentSnapshot['deskripsi']}',
                            ),
                            leading: Container(
                              width: 50,
                              height: 50,
                              child: Image.network(
                                documentSnapshot['image_url'],
                                fit: BoxFit.cover,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat.yMMMd().add_jm().format(
                                      documentSnapshot['timestamp'].toDate(),
                                    )),
                                Text(
                                  'Posted by: ${_auth.currentUser?.email == documentSnapshot['user_email'] ? _auth.currentUser?.email ?? 'Unknown' : documentSnapshot['user_email']}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
              }
            },
          ),
          floatingActionButton: IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => PostScreen()));
            },
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
