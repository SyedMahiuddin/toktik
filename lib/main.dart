import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:toktik/video_controller.dart';

import 'firebase_options.dart';
import 'feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Check and request all necessary permissions
  await _checkAndRequestPermissions();

  runApp(TokTikApp());
}

/// Checks and requests all necessary permissions for the TokTik app
Future<void> _checkAndRequestPermissions() async {
  try {
    // Request permissions one by one to handle them properly
    await _requestCameraPermission();
    await _requestMicrophonePermission();
    await _requestStoragePermissions();
    await _requestNotificationPermission();

    print('All permissions checked and requested');

  } catch (e) {
    print('Error requesting permissions: $e');
  }
}

/// Request camera permission
Future<void> _requestCameraPermission() async {
  var status = await Permission.camera.status;
  print('Camera permission status: $status');

  if (status.isDenied) {
    status = await Permission.camera.request();
    print('Camera permission after request: $status');
  }

  if (status.isPermanentlyDenied) {
    print('Camera permission permanently denied - opening settings');
    await openAppSettings();
  }
}

/// Request microphone permission
Future<void> _requestMicrophonePermission() async {
  var status = await Permission.microphone.status;
  print('Microphone permission status: $status');

  if (status.isDenied) {
    status = await Permission.microphone.request();
    print('Microphone permission after request: $status');
  }

  if (status.isPermanentlyDenied) {
    print('Microphone permission permanently denied - opening settings');
    await openAppSettings();
  }
}

/// Request storage permissions (handles different Android versions)
Future<void> _requestStoragePermissions() async {
  // For Android 13+ (API 33+), we need different permissions
  if (await _isAndroid13OrHigher()) {
    await _requestAndroid13StoragePermissions();
  } else {
    await _requestLegacyStoragePermissions();
  }
}

/// Request storage permissions for Android 13+
Future<void> _requestAndroid13StoragePermissions() async {
  // Request photos permission
  var photosStatus = await Permission.photos.status;
  print('Photos permission status: $photosStatus');

  if (photosStatus.isDenied) {
    photosStatus = await Permission.photos.request();
    print('Photos permission after request: $photosStatus');
  }

  // Request videos permission
  var videosStatus = await Permission.videos.status;
  print('Videos permission status: $videosStatus');

  if (videosStatus.isDenied) {
    videosStatus = await Permission.videos.request();
    print('Videos permission after request: $videosStatus');
  }
}

/// Request storage permissions for older Android versions
Future<void> _requestLegacyStoragePermissions() async {
  var storageStatus = await Permission.storage.status;
  print('Storage permission status: $storageStatus');

  if (storageStatus.isDenied) {
    storageStatus = await Permission.storage.request();
    print('Storage permission after request: $storageStatus');
  }

  if (storageStatus.isPermanentlyDenied) {
    print('Storage permission permanently denied - opening settings');
    await openAppSettings();
  }
}

/// Request notification permission
Future<void> _requestNotificationPermission() async {
  var status = await Permission.notification.status;
  print('Notification permission status: $status');

  if (status.isDenied) {
    status = await Permission.notification.request();
    print('Notification permission after request: $status');
  }
}

/// Check if device is running Android 13 or higher
Future<bool> _isAndroid13OrHigher() async {
  try {
    // This is a simplified check - you might want to use device_info_plus for more accurate detection
    return await Permission.photos.status != PermissionStatus.denied;
  } catch (e) {
    return false;
  }
}



class TokTikApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VideoController()),
      ],
      child: MaterialApp(
        title: 'TokTik',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'Roboto',
          // Additional theme customizations for TikTok-like app
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
          ),
        ),
        home: VideoFeedScreen(),
      ),
    );
  }
}