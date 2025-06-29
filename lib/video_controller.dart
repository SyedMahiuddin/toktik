import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:toktik/video_model.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class VideoController extends ChangeNotifier {
  List<VideoModel> _videos = [];
  Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Connectivity _connectivity = Connectivity();
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  final Set<int> _initializingVideos = {};

  // Dummy data generators
  String _getDummyTitle() {
    final titles = [
      "Amazing sunset vibes 🌅",
      "Dance moves on point! 💃",
      "Cooking hack that changed my life",
      "Pet doing the funniest thing",
      "Travel adventure begins here",
    ];
    return titles[Random().nextInt(titles.length)];
  }

  String _getDummyCreator() {
    final creators = [
      "@creativesoul",
      "@techguru",
      "@foodlover",
      "@dancer_pro",
      "@traveler_life",
    ];
    return creators[Random().nextInt(creators.length)];
  }

  List<VideoModel> get videos => _videos;
  Map<int, VideoPlayerController> get controllers => _controllers;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  VideoController() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadVideosWithFallback();

      if (_videos.isNotEmpty) {
        await _initializeVideoAtIndex(0);
      }
    } catch (e) {
      _errorMessage = 'Failed to load videos: ${e.toString()}';
      _createDummyVideosList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadVideosWithFallback() async {
    try {
      if (await _hasGoodConnection()) {
        final videos = await _loadVideoListFromFirebase();
        if (videos.isEmpty) throw Exception('No videos found');
        _videos = videos;
      } else {
        throw Exception('Poor connection');
      }
    } catch (e) {
      print('Using fallback: $e');
      final cachedVideos = await _loadFromCache();
      _videos = cachedVideos ?? _createDummyVideosList();
    }
  }

  Future<bool> _hasGoodConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  Future<List<VideoModel>> _loadVideoListFromFirebase() async {
    try {
      final ref = _storage.ref('videos');
      final result = await ref.listAll().timeout(const Duration(seconds: 15));

      final videos = await Future.wait(
        result.items.take(50).map((item) => _createVideoModel(item)),
      );

      return videos.whereType<VideoModel>().toList();
    } catch (e) {
      print('Firebase load error: $e');
      rethrow;
    }
  }

  Future<VideoModel?> _createVideoModel(Reference ref) async {
    try {
      final url = await ref.getDownloadURL().timeout(const Duration(seconds: 10));
      return VideoModel(
        id: ref.name,
        url: url,
        title: _getDummyTitle(),
        creator: _getDummyCreator(),
        likes: Random().nextInt(10000),
        comments: Random().nextInt(1000),
      );
    } catch (e) {
      print('Error creating video model for ${ref.name}: $e');
      return null;
    }
  }

  Future<List<VideoModel>?> _loadFromCache() async {
    try {
      // Implement your cache loading logic here
      return null; // Return null to force dummy data
    } catch (e) {
      return null;
    }
  }

  List<VideoModel> _createDummyVideosList() {
    List<String> workingUrls = [
      'https://firebasestorage.googleapis.com/v0/b/jadurhotel.appspot.com/o/videos%2FPower%20%F0%9F%92%80.mp4?alt=media&token=12046596-ae2a-48a0-b0e2-a7cd07a52be4',
      // Add more fallback URLs
    ];

    return List.generate(workingUrls.length, (index) => VideoModel(
      id: 'dummy_$index',
      url: workingUrls[index % workingUrls.length],
      title: _getDummyTitle(),
      creator: _getDummyCreator(),
      likes: Random().nextInt(10000),
      comments: Random().nextInt(1000),
    ));
  }

  Future<void> _initializeVideoAtIndex(int index, {int retries = 2}) async {
    if (index >= _videos.length ||
        _controllers.containsKey(index) ||
        _initializingVideos.contains(index)) {
      return;
    }

    _initializingVideos.add(index);

    try {
      for (var attempt = 1; attempt <= retries; attempt++) {
        try {
          final controller = VideoPlayerController.network(
            _videos[index].url,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );

          await controller.initialize().timeout(const Duration(seconds: 20));
          controller.setLooping(true);

          _controllers[index] = controller;

          if (index == _currentIndex) {
            await controller.play();
          }

          // Cache the video for future use
          unawaited(_cacheManager.downloadFile(_videos[index].url));

          break;
        } catch (e) {
          if (attempt == retries) rethrow;
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    } catch (e) {
      print('Error initializing video at index $index: $e');
    } finally {
      _initializingVideos.remove(index);
      notifyListeners();
    }
  }

  void changeVideo(int index) {
    if (index < 0 || index >= _videos.length) return;

    // Pause current video
    if (_controllers.containsKey(_currentIndex)) {
      _controllers[_currentIndex]!.pause();
    }

    _currentIndex = index;

    // Initialize current video if not ready
    if (!_controllers.containsKey(index)) {
      _initializeVideoAtIndex(index);
    } else {
      _controllers[index]!.play();
    }

    // Preload nearby videos
    _preloadNearbyVideos();

    // Clean up old controllers
    _cleanupControllers();

    notifyListeners();
  }

  void _preloadNearbyVideos() {
    final preloadIndices = {
      _currentIndex - 1,
      _currentIndex + 1,
      _currentIndex + 2,
    }.where((i) => i >= 0 && i < _videos.length);

    for (final index in preloadIndices) {
      if (!_controllers.containsKey(index)) {
        _initializeVideoAtIndex(index);
      }
    }
  }

  void _cleanupControllers() {
    final keepIndices = {
      _currentIndex - 1,
      _currentIndex,
      _currentIndex + 1,
      _currentIndex + 2,
    }.where((i) => i >= 0 && i < _videos.length);

    _controllers.keys.toList().forEach((key) {
      if (!keepIndices.contains(key)) {
        _controllers[key]?.dispose();
        _controllers.remove(key);
      }
    });
  }

  bool isVideoReady(int index) {
    return _controllers.containsKey(index) &&
        _controllers[index]!.value.isInitialized;
  }

  bool isVideoLoading(int index) {
    return _initializingVideos.contains(index);
  }

  void toggleLike(int index) {
    if (index < _videos.length) {
      _videos[index] = _videos[index].copyWith(
        likes: _videos[index].likes + 1,
      );
      notifyListeners();
    }
  }

  void addComment(int index) {
    if (index < _videos.length) {
      _videos[index] = _videos[index].copyWith(
        comments: _videos[index].comments + 1,
      );
      notifyListeners();
    }
  }

  void retry() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _initializingVideos.clear();
    _currentIndex = 0;
    _initializeApp();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _initializingVideos.clear();
    super.dispose();
  }
}

// Helper function to avoid void value error
void unawaited(Future<void>? future) {}