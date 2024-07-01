import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secondbrand/screens/home_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<PostScreen> {
  final _TextController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  XFile? _image;
  String _locationMessage = "";
  Position? _currentPosition;

  void _registerPlatformInstance() {
    if (Platform.isAndroid) {
      GeolocatorAndroid.registerWith();
    } else if (Platform.isIOS) {
      GeolocatorApple.registerWith();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Post'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: IconButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()));
          },
          icon: Icon(Icons.arrow_back_ios_new_outlined)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  await _showImageSourceDialog();
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                      color: Colors.lightBlueAccent,
                      borderRadius: BorderRadius.circular(90)),
                  child: _image != null
                      ? Image.file(File(_image!.path))
                      : Icon(Icons.camera_alt),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _TextController,
                decoration: InputDecoration(
                  hintText: 'Input Deskripsi',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    textStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    )),
                onPressed: () async {
                  if (_image == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select an image')),
                    );
                    return;
                  }

                  if (_currentPosition == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please get your location')),
                    );
                    return;
                  }

                  Reference referenceRoot = FirebaseStorage.instance.ref();
                  Reference referenceDirImages = referenceRoot.child("images");
                  Reference referenceImagesToUpload =
                      referenceDirImages.child(_image!.path.split("/").last);

                  try {
                    final uploadTask = await referenceImagesToUpload
                        .putFile(File(_image!.path));
                    final downloadUrl = await uploadTask.ref.getDownloadURL();

                    String? Token = await _firebaseMessaging.getToken();

                    // Add Firebase Cloud Firestore functionality here
                    final CollectionReference posts =
                        FirebaseFirestore.instance.collection('test');
                    await posts.add({
                      'deskripsi': _TextController.text,
                      'image_url': downloadUrl,
                      'timestamp': Timestamp.now(),
                      'user_email': _auth.currentUser?.email,
                      'latitude': _currentPosition!.latitude,
                      'longitude': _currentPosition!.longitude,
                      'user_token': Token,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Image uploaded successfully')),
                    );

                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const HomeScreen()));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error uploading image: $e')),
                    );
                  }
                },
                child: Text('Post'),
              ),
              SizedBox(height: 16),
              LocationWidget(
                onLocationChanged: (Position position) {
                  setState(() {
                    _currentPosition = position;
                    _locationMessage =
                        'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Sumber Gambar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Open Camera'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _image = pickedFile;
                  });
                }
              },
            ),
            ListTile(
              title: Text('Pick From Gallery'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _image = pickedFile;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _TextController.dispose();
    super.dispose();
  }
}

class LocationWidget extends StatefulWidget {
  final Function(Position) onLocationChanged;

  const LocationWidget({Key? key, required this.onLocationChanged})
      : super(key: key);

  @override
  _LocationWidgetState createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  String _locationMessage = "";
  Position? _currentPosition;

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true,
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _locationMessage =
            'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
        widget.onLocationChanged(
            position); // Callback to notify the parent about the location change
      });
    } catch (e) {
      print('Error getting location: $e');
    }
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _getCurrentLocation,
          child: const Text('Get Location'),
        ),
        Text(_locationMessage),
      ],
    );
  }
}
