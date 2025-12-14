import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/album.dart';
import '../services/camera_service.dart';
import '../services/album_service.dart';

class CameraScreen extends StatefulWidget {
  final Album album;

  const CameraScreen({
    super.key,
    required this.album,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService.instance;
  final AlbumService _albumService = AlbumService.instance;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  bool _isVideoMode = false;
  bool _isRecording = false;
  String? _lastMediaPath;
  bool _lastMediaIsVideo = false;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final success = await _cameraService.initialize();
      setState(() {
        _isInitialized = success;
      });
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera başlatılamadı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera hatası: $e')),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture || _isRecording) return;

    setState(() => _isTakingPicture = true);

    try {
      final photoPath = await _cameraService.takePicture();

      if (photoPath != null) {
        setState(() {
          _lastMediaPath = photoPath;
          _lastMediaIsVideo = false;
          _isTakingPicture = false;
        });
        
        _albumService.addPhotoToAlbum(photoPath, widget.album.id!);
      } else {
        setState(() => _isTakingPicture = false);
      }
    } catch (e) {
      setState(() => _isTakingPicture = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf çekilemedi: $e')),
        );
      }
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_isRecording) {
      // Kaydı durdur
      _recordingTimer?.cancel();
      final videoPath = await _cameraService.stopVideoRecording();
      
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });

      if (videoPath != null) {
        setState(() {
          _lastMediaPath = videoPath;
          _lastMediaIsVideo = true;
        });
        
        _albumService.addPhotoToAlbum(videoPath, widget.album.id!, isVideo: true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video kaydedildi'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      // Kaydı başlat
      final success = await _cameraService.startVideoRecording();
      
      if (success) {
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });
        
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _switchCamera() async {
    if (_isRecording) return;
    await _cameraService.switchCamera();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: !_isInitialized
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Stack(
                children: [
                  // Kamera önizlemesi
                  Positioned.fill(
                    child: CameraPreview(_cameraService.controller!),
                  ),
                  
                  // Kayıt göstergesi
                  if (_isRecording)
                    Positioned(
                      top: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(_recordingSeconds),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Üst bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                            onPressed: _isRecording ? null : () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                widget.album.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          if (_cameraService.cameras != null && 
                              _cameraService.cameras!.length > 1)
                            IconButton(
                              icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                              onPressed: _isRecording ? null : _switchCamera,
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                  
                  // Alt kontroller
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(24),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mod seçici (Fotoğraf / Video)
                          if (!_isRecording)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => _isVideoMode = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: !_isVideoMode ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Fotoğraf',
                                        style: TextStyle(
                                          color: !_isVideoMode ? Colors.black : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _isVideoMode = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _isVideoMode ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Video',
                                        style: TextStyle(
                                          color: _isVideoMode ? Colors.black : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Kontrol butonları
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Son medya önizlemesi
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: _lastMediaPath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            if (!_lastMediaIsVideo)
                                              Image.file(
                                                File(_lastMediaPath!),
                                                fit: BoxFit.cover,
                                              )
                                            else
                                              Container(
                                                color: Colors.grey.shade900,
                                                child: const Icon(
                                                  Icons.play_circle_fill,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ),
                                            if (_lastMediaIsVideo)
                                              const Positioned(
                                                bottom: 2,
                                                right: 2,
                                                child: Icon(
                                                  Icons.videocam,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                          ],
                                        ),
                                      )
                                    : Icon(
                                        _isVideoMode ? Icons.videocam : Icons.photo,
                                        color: Colors.white54,
                                      ),
                              ),
                              
                              // Çekim butonu
                              GestureDetector(
                                onTap: _isTakingPicture
                                    ? null
                                    : (_isVideoMode ? _toggleVideoRecording : _takePicture),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isVideoMode ? Colors.red : Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                                        borderRadius: _isRecording ? BorderRadius.circular(8) : null,
                                        color: _isVideoMode
                                            ? (_isRecording ? Colors.red : Colors.red)
                                            : (_isTakingPicture ? Colors.grey : Colors.white),
                                      ),
                                      margin: _isRecording ? const EdgeInsets.all(16) : null,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Boşluk
                              const SizedBox(width: 60),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Çekim göstergesi
                  if (_isTakingPicture)
                    Positioned(
                      top: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Kaydediliyor...',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
