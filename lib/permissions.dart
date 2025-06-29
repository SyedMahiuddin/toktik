import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionDebugScreen extends StatefulWidget {
  @override
  _PermissionDebugScreenState createState() => _PermissionDebugScreenState();
}

class _PermissionDebugScreenState extends State<PermissionDebugScreen> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  int _androidVersion = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndCheckPermissions();
  }

  Future<void> _initializeAndCheckPermissions() async {
    await _getAndroidVersion();
    await _checkAllPermissions();
  }

  Future<void> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        setState(() {
          _androidVersion = androidInfo.version.sdkInt;
        });
        print('Android SDK Version: $_androidVersion');
      } catch (e) {
        print('Error getting Android version: $e');
        setState(() {
          _androidVersion = 30; // Fallback
        });
      }
    }
  }

  List<Permission> _getRelevantPermissions() {
    List<Permission> permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
    ];

    // Add storage permissions based on Android version
    if (Platform.isAndroid) {
      if (_androidVersion >= 33) {
        // Android 13+ (API 33+) - Use granular media permissions
        permissions.addAll([
          Permission.photos,        // READ_MEDIA_IMAGES
          Permission.videos,        // READ_MEDIA_VIDEO
          Permission.audio,         // READ_MEDIA_AUDIO
        ]);
      } else if (_androidVersion >= 30) {
        // Android 11-12 (API 30-32) - Use legacy storage
        permissions.addAll([
          Permission.storage,
          Permission.manageExternalStorage, // For accessing all files
        ]);
      } else {
        // Android 10 and below - Use legacy storage
        permissions.add(Permission.storage);
      }
    } else {
      // iOS - add photos permission
      permissions.add(Permission.photos);
    }

    return permissions;
  }

  Future<void> _checkAllPermissions() async {
    setState(() {
      _isLoading = true;
    });

    final permissions = _getRelevantPermissions();
    Map<Permission, PermissionStatus> newStatuses = {};

    for (var permission in permissions) {
      try {
        final status = await permission.status;
        newStatuses[permission] = status;
        print('${permission.toString()}: $status');
      } catch (e) {
        print('Error checking ${permission.toString()}: $e');
        newStatuses[permission] = PermissionStatus.denied;
      }
    }

    setState(() {
      _permissionStatuses = newStatuses;
      _isLoading = false;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    try {
      print('🔄 Requesting ${permission.toString()}...');

      // Special handling for storage permission on Android 13+
      if (permission == Permission.storage && _androidVersion >= 33) {
        _showStoragePermissionDialog();
        return;
      }

      final status = await permission.request();
      print('✅ ${permission.toString()} result: $status');

      setState(() {
        _permissionStatuses[permission] = status;
      });

      if (status.isPermanentlyDenied) {
        _showSettingsDialog(permission);
      }
    } catch (e) {
      print('❌ Error requesting ${permission.toString()}: $e');
      _showErrorDialog(permission, e.toString());
    }
  }

  Future<void> _requestAllMediaPermissions() async {
    if (_androidVersion >= 33) {
      final mediaPermissions = [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ];

      for (var permission in mediaPermissions) {
        await _requestPermission(permission);
      }
    } else {
      await _requestPermission(Permission.storage);
    }
  }

  void _showStoragePermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Storage Permission'),
        content: Text(
          'On Android 13+, generic storage permission is not used. '
              'Use specific media permissions instead:\n\n'
              '• Photos (Images)\n'
              '• Videos\n'
              '• Audio\n\n'
              'Would you like to request these permissions?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestAllMediaPermissions();
            },
            child: Text('Request Media Permissions'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
          '${_getPermissionName(permission)} is permanently denied. '
              'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(Permission permission, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Error'),
        content: Text(
          'Error requesting ${_getPermissionName(permission)}:\n\n$error',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getStatusIcon(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '✅';
      case PermissionStatus.denied:
        return '❌';
      case PermissionStatus.restricted:
        return '⚠️';
      case PermissionStatus.limited:
        return '⚡';
      case PermissionStatus.permanentlyDenied:
        return '🚫';
      default:
        return '❓';
    }
  }

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.red;
      case PermissionStatus.restricted:
        return Colors.orange;
      case PermissionStatus.limited:
        return Colors.yellow;
      case PermissionStatus.permanentlyDenied:
        return Colors.red.shade800;
      default:
        return Colors.grey;
    }
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.microphone:
        return 'Microphone';
      case Permission.storage:
        return 'Storage (Legacy)';
      case Permission.photos:
        return Platform.isAndroid ? 'Photos/Images' : 'Photos';
      case Permission.videos:
        return 'Videos';
      case Permission.audio:
        return Platform.isAndroid ? 'Audio Files' : 'Audio';
      case Permission.notification:
        return 'Notifications';
      case Permission.manageExternalStorage:
        return 'Manage External Storage';
      default:
        return permission.toString().split('.').last;
    }
  }

  String _getPermissionDescription(Permission permission) {
    if (Platform.isAndroid && _androidVersion >= 33) {
      switch (permission) {
        case Permission.photos:
          return 'READ_MEDIA_IMAGES';
        case Permission.videos:
          return 'READ_MEDIA_VIDEO';
        case Permission.audio:
          return 'READ_MEDIA_AUDIO';
        case Permission.storage:
          return 'Not used on Android 13+';
        default:
          return '';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Permission Debug'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkAllPermissions,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Android version info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    Platform.isAndroid
                        ? 'Android SDK: $_androidVersion'
                        : 'iOS Device',
                    style: TextStyle(color: Colors.white70),
                  ),
                  if (Platform.isAndroid && _androidVersion >= 33)
                    Text(
                      'Using granular media permissions',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Tap on any permission to request it',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: Colors.deepPurple,
                ),
              )
                  : ListView.builder(
                itemCount: _permissionStatuses.length,
                itemBuilder: (context, index) {
                  final permission = _permissionStatuses.keys.elementAt(index);
                  final status = _permissionStatuses[permission]!;
                  final description = _getPermissionDescription(permission);

                  return Card(
                    color: Colors.grey[900],
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Text(
                        _getStatusIcon(status),
                        style: TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        _getPermissionName(permission),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.toString().split('.').last,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (description.isNotEmpty)
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.touch_app,
                        color: Colors.white54,
                      ),
                      onTap: () => _requestPermission(permission),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkAllPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Refresh All'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => openAppSettings(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('App Settings'),
                  ),
                ),
              ],
            ),
            if (Platform.isAndroid && _androidVersion >= 33)
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: _requestAllMediaPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Request All Media Permissions'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}