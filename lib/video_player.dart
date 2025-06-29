import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_model.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoModel video;
  final VideoPlayerController? controller;
  final int index;
  final bool isReady;
  final bool isLoading;

  const VideoPlayerWidget({
    Key? key,
    required this.video,
    required this.controller,
    required this.index,
    required this.isReady,
    required this.isLoading,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _showControls = false;
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or loading/error state
          _buildVideoContent(),

          // Gradient overlays
          _buildBottomGradient(),
          if (_showControls) _buildTopGradient(),

          // Video information
          _buildVideoInfo(),

          // Action buttons
          _buildActionButtons(),

          // Loading indicator if needed
          if (widget.isLoading) _buildLoadingIndicator(),

          // Controls if visible
          if (_showControls && widget.isReady) _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    if (!widget.isReady) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isLoading ? Icons.downloading : Icons.error_outline,
                size: 50,
                color: Colors.white70,
              ),
              SizedBox(height: 16),
              Text(
                widget.isLoading ? 'Loading video...' : 'Tap to retry',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: widget.controller!.value.aspectRatio,
      child: VideoPlayer(widget.controller!),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.creator,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.video.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.music_note, size: 14, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Original Sound',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: '${widget.video.likes + (_isLiked ? 1 : 0)}',
            color: _isLiked ? Colors.red : Colors.white,
            onTap: _toggleLike,
          ),
          SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.comment,
            label: '${widget.video.comments}',
            onTap: _showComments,
          ),
          SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.share,
            label: 'Share',
            onTap: _showShareOptions,
          ),
          SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.more_vert,
            label: '',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          if (label.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
      ),
    );
  }

  Widget _buildVideoControls() {
    if (widget.controller == null || !widget.controller!.value.isInitialized) {
      return SizedBox();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            VideoProgressIndicator(
              widget.controller!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Colors.deepPurple,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.grey.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(widget.controller!.value.position),
                  style: TextStyle(color: Colors.white),
                ),
                IconButton(
                  icon: Icon(
                    widget.controller!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: _togglePlayPause,
                ),
                Text(
                  _formatDuration(widget.controller!.value.duration),
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
    }
    return "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.controller!.value.isPlaying) {
        widget.controller!.pause();
      } else {
        widget.controller!.play();
      }
    });
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
    // You might want to call controller.toggleLike(widget.index) here
  }

  void _showComments() {
    // Implement comments dialog
  }

  void _showShareOptions() {
    // Implement share dialog
  }

  @override
  void dispose() {
    super.dispose();
  }
}