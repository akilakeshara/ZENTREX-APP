import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

enum SpeedTestStage { idle, pinging, downloading, uploading, finished, error }

class SpeedTestState {
  final SpeedTestStage stage;
  final double pingMs;
  final double downloadMbps;
  final double uploadMbps;
  final String? errorMessage;

  SpeedTestState({
    required this.stage,
    this.pingMs = 0.0,
    this.downloadMbps = 0.0,
    this.uploadMbps = 0.0,
    this.errorMessage,
  });

  SpeedTestState copyWith({
    SpeedTestStage? stage,
    double? pingMs,
    double? downloadMbps,
    double? uploadMbps,
    String? errorMessage,
  }) {
    return SpeedTestState(
      stage: stage ?? this.stage,
      pingMs: pingMs ?? this.pingMs,
      downloadMbps: downloadMbps ?? this.downloadMbps,
      uploadMbps: uploadMbps ?? this.uploadMbps,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SpeedTester {
  static const int _downloadBytes = 15000000; // 15 MB
  static const int _uploadBytes = 10000000; // 10 MB
  
  static const String _downUrl = 'https://speed.cloudflare.com/__down?bytes=$_downloadBytes';
  static const String _upUrl = 'https://speed.cloudflare.com/__up';

  bool _isTesting = false;
  HttpClient? _httpClient;

  Stream<SpeedTestState> startTest() async* {
    if (_isTesting) return;
    _isTesting = true;

    _httpClient = HttpClient();
    _httpClient!.connectionTimeout = const Duration(seconds: 10);

    SpeedTestState currentState = SpeedTestState(stage: SpeedTestStage.pinging);
    yield currentState;

    try {
      // 1. Measure Ping
      final pingStart = DateTime.now();
      final pingReq = await _httpClient!.headUrl(Uri.parse('https://speed.cloudflare.com'));
      await pingReq.close();
      final pingEnd = DateTime.now();
      final pingMs = pingEnd.difference(pingStart).inMilliseconds.toDouble();

      currentState = currentState.copyWith(
        stage: SpeedTestStage.downloading,
        pingMs: pingMs,
      );
      yield currentState;

      // 2. Measure Download Speed
      final downReq = await _httpClient!.getUrl(Uri.parse(_downUrl));
      final downRes = await downReq.close();

      int downloaded = 0;
      final downStart = DateTime.now();
      
      await for (final chunk in downRes) {
        downloaded += chunk.length;
        final elapsed = DateTime.now().difference(downStart).inMilliseconds;
        if (elapsed > 100) {
          final mbps = (downloaded * 8) / (elapsed / 1000) / 1000000;
          currentState = currentState.copyWith(downloadMbps: mbps);
          yield currentState;
        }
      }
      
      final downTotalElapsed = DateTime.now().difference(downStart).inMilliseconds;
      final finalDownMbps = (downloaded * 8) / (downTotalElapsed / 1000) / 1000000;
      currentState = currentState.copyWith(
        stage: SpeedTestStage.uploading,
        downloadMbps: finalDownMbps,
      );
      yield currentState;

      // 3. Measure Upload Speed
      final random = Random();
      const chunkSize = 500000; // 500KB
      final chunkData = Uint8List(chunkSize);
      for (int i = 0; i < chunkData.length; i++) {
        chunkData[i] = random.nextInt(256);
      }

      final upStart = DateTime.now();
      final upReq = await _httpClient!.postUrl(Uri.parse(_upUrl));
      upReq.contentLength = _uploadBytes;
      
      int uploaded = 0;
      
      while (uploaded < _uploadBytes) {
        if (!_isTesting) break; // Check if cancelled
        
        final bytesToSend = (_uploadBytes - uploaded < chunkData.length) 
            ? _uploadBytes - uploaded 
            : chunkData.length;
            
        upReq.add(Uint8List.view(chunkData.buffer, 0, bytesToSend));
        uploaded += bytesToSend;
        
        await Future.delayed(const Duration(milliseconds: 10));
        
        final elapsed = DateTime.now().difference(upStart).inMilliseconds;
        if (elapsed > 100) {
          final mbps = (uploaded * 8) / (elapsed / 1000) / 1000000;
          currentState = currentState.copyWith(uploadMbps: mbps);
          yield currentState;
        }
      }
      
      final upRes = await upReq.close();
      await upRes.drain();

      final upTotalElapsed = DateTime.now().difference(upStart).inMilliseconds;
      final finalUpMbps = (uploaded * 8) / (upTotalElapsed / 1000) / 1000000;
      
      currentState = currentState.copyWith(
        stage: SpeedTestStage.finished,
        uploadMbps: finalUpMbps,
      );
      yield currentState;

    } catch (e) {
      debugPrint("Speed test error: $e");
      currentState = currentState.copyWith(
        stage: SpeedTestStage.error,
        errorMessage: 'Network error. Please try again.',
      );
      yield currentState;
    } finally {
      _httpClient?.close(force: true);
      _httpClient = null;
      _isTesting = false;
    }
  }

  void cancelTest() {
    _httpClient?.close(force: true);
    _httpClient = null;
    _isTesting = false;
  }
}
