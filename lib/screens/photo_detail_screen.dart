import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../models/photo.dart';
import '../services/album_service.dart';

class PhotoDetailScreen extends StatefulWidget {
  final Photo photo;
  final List<Photo> allPhotos;
  final int initialIndex;

  const PhotoDetailScreen({
    super.key,
    required this.photo,
    required this.allPhotos,
    required this.initialIndex,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late List<Photo> _photos;
  bool _showDetails = true;
  final AlbumService _albumService = AlbumService.instance;
  
  // Video player
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _photos = List.from(widget.allPhotos);
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideoIfNeeded();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Photo get _currentPhoto => _photos[_currentIndex];

  void _initializeVideoIfNeeded() {
    if (_currentPhoto.isVideo) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(File(_currentPhoto.path))
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
        });
    }
  }

  Future<void> _toggleFavorite() async {
    final newFavoriteStatus = !_currentPhoto.isFavorite;
    final success = await _albumService.toggleFavorite(_currentPhoto.id!, newFavoriteStatus);
    
    if (success) {
      setState(() {
        _photos[_currentIndex] = Photo(
          id: _currentPhoto.id,
          path: _currentPhoto.path,
          albumId: _currentPhoto.albumId,
          userId: _currentPhoto.userId,
          takenAt: _currentPhoto.takenAt,
          takenBy: _currentPhoto.takenBy,
          isVideo: _currentPhoto.isVideo,
          isFavorite: newFavoriteStatus,
        );
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newFavoriteStatus ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _deleteCurrentMedia() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentPhoto.isVideo ? 'Videoyu Sil' : 'Fotoğrafı Sil'),
        content: Text('Bu ${_currentPhoto.isVideo ? 'videoyu' : 'fotoğrafı'} silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Dosyayı sil
      try {
        final file = File(_currentPhoto.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Dosya silme hatası: $e');
      }

      // Veritabanından sil
      final success = await _albumService.deletePhoto(_currentPhoto.id!);
      
      if (success) {
        if (_photos.length == 1) {
          // Son medya silindiyse geri dön
          if (mounted) Navigator.pop(context);
        } else {
          // Listeden kaldır ve güncelle
          setState(() {
            _photos.removeAt(_currentIndex);
            if (_currentIndex >= _photos.length) {
              _currentIndex = _photos.length - 1;
            }
          });
          
          // Video ise yeniden başlat
          _initializeVideoIfNeeded();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_currentPhoto.isVideo ? 'Video silindi' : 'Fotoğraf silindi'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      }
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController == null) return;
    
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showDetails = !_showDetails;
          });
        },
        child: Stack(
          children: [
            // Medya görüntüleme
            PageView.builder(
              controller: _pageController,
              itemCount: _photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _isVideoInitialized = false;
                });
                _initializeVideoIfNeeded();
              },
              itemBuilder: (context, index) {
                final photo = _photos[index];
                
                if (photo.isVideo) {
                  // Video oynatıcı
                  if (index == _currentIndex && _isVideoInitialized && _videoController != null) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _showDetails = !_showDetails);
                      },
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_videoController!),
                              // Play/Pause overlay
                              GestureDetector(
                                onTap: _toggleVideoPlayback,
                                child: Container(
                                  color: Colors.transparent,
                                  child: AnimatedOpacity(
                                    opacity: !_videoController!.value.isPlaying ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                } else {
                  // Fotoğraf görüntüleme
                  return InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.file(
                        File(photo.path),
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }
              },
            ),

            // Üst bar
            if (_showDetails)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    left: 8,
                    right: 8,
                    bottom: 8,
                  ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        '${_currentIndex + 1} / ${_photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Favori butonu
                          IconButton(
                            icon: Icon(
                              _currentPhoto.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _currentPhoto.isFavorite ? Colors.red : Colors.white,
                            ),
                            onPressed: _toggleFavorite,
                          ),
                          // Silme butonu
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: _deleteCurrentMedia,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Video kontrolleri
            if (_showDetails && _currentPhoto.isVideo && _isVideoInitialized && _videoController != null)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // İlerleme çubuğu
                    VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Süre göstergesi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: _videoController!,
                          builder: (context, VideoPlayerValue value, child) {
                            return Text(
                              _formatDuration(value.position),
                              style: const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                        Text(
                          _formatDuration(_videoController!.value.duration),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Alt detay bilgileri
            if (_showDetails)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    top: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Medya tipi göstergesi
                      if (_currentPhoto.isVideo)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Video', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      _buildDetailRow(
                        Icons.person,
                        'Çeken',
                        _currentPhoto.takenBy,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Tarih',
                        DateFormat('dd.MM.yyyy').format(_currentPhoto.takenAt),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.access_time,
                        'Saat',
                        DateFormat('HH:mm:ss').format(_currentPhoto.takenAt),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
