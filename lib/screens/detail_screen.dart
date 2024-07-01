import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatelessWidget {
  final String documentId;
  final String imageUrl;
  final String description;
  final Timestamp timestamp;
  final String userEmail;
  final double latitude;
  final double longitude;

  const DetailScreen({
    required this.documentId,
    required this.imageUrl,
    required this.description,
    required this.timestamp,
    required this.userEmail,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Screen'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          // Assuming you have a profile image for the user
                          radius: 20,
                          // Change the image provider to your user's profile image
                          backgroundImage: NetworkImage(
                            'https://via.placeholder.com/150',
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Image.network(
                    imageUrl,
                    fit: BoxFit.fill,
                    width: screenWidth,
                    height: screenWidth * 0.6, // Aspect ratio
                  ),
                  SizedBox(height: 8.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      description,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _openMaps(latitude, longitude);
                        },
                        icon: Icon(Icons.location_on),
                      ),
                      Expanded(
                        child: Text(
                          'Latitude: $latitude, Longitude: $longitude',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Timestamp: ${DateFormat.yMMMd().add_jm().format(timestamp.toDate())}',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _openMaps(double latitude, double longitude) async {
    String mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    try {
      if (await canLaunch(mapsUrl)) {
        await launch(mapsUrl);
      } else {
        throw 'Could not launch $mapsUrl';
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
