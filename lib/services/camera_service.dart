import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class CameraService {
  static final CameraService instance = CameraService._init();
  CameraService._init();

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  String? _photoDir;
  String? _videoDir;
  bool _isRecording = false;

  CameraController? get controller => _controller;
  List<CameraDescription>? get cameras => _cameras;
  bool get isRecording => _isRecording;

  Future<bool> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        return false;
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      _photoDir = path.join(appDir.path, 'photos');
      _videoDir = path.join(appDir.path, 'videos');
      await Directory(_photoDir!).create(recursive: true);
      await Directory(_videoDir!).create(recursive: true);

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      
      await _controller!.setFocusMode(FocusMode.auto);
      
      return true;
    } catch (e) {
      print('Kamera başlatma hatası: $e');
      return false;
    }
  }

  Future<String?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    if (_controller!.value.isTakingPicture) {
      return null;
    }

    try {
      final String timestamp = DateFormat('yyyyMMdd_HHmmss_SSS').format(DateTime.now());
      final String filePath = path.join(_photoDir!, 'IMG_$timestamp.jpg');

      final XFile picture = await _controller!.takePicture();
      
      try {
        await File(picture.path).rename(filePath);
      } catch (e) {
        await File(picture.path).copy(filePath);
        await File(picture.path).delete();
      }

      return filePath;
    } catch (e) {
      print('Fotoğraf çekme hatası: $e');
      return null;
    }
  }

  Future<bool> startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return false;
    }

    if (_isRecording) {
      return false;
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      return true;
    } catch (e) {
      print('Video kayıt başlatma hatası: $e');
      return false;
    }
  }

  Future<String?> stopVideoRecording() async {
    if (_controller == null || !_isRecording) {
      return null;
    }

    try {
      final XFile video = await _controller!.stopVideoRecording();
      _isRecording = false;

      final String timestamp = DateFormat('yyyyMMdd_HHmmss_SSS').format(DateTime.now());
      final String filePath = path.join(_videoDir!, 'VID_$timestamp.mp4');

      try {
        await File(video.path).rename(filePath);
      } catch (e) {
        await File(video.path).copy(filePath);
        await File(video.path).delete();
      }

      return filePath;
    } catch (e) {
      print('Video kayıt durdurma hatası: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      return;
    }

    if (_isRecording) {
      return;
    }

    final currentCameraIndex = _cameras!.indexOf(_controller!.description);
    final newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;

    await _controller?.dispose();

    _controller = CameraController(
      _cameras![newCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _controller!.initialize();
  }

  void dispose() {
    _controller?.dispose();
  }
}
