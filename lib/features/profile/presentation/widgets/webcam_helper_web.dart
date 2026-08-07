// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foundit/core/constants/app_colors.dart';

/// Web implementation of the webcam capture flow.
/// Shows a live webcam dialog and captures a picture.
Future<String?> captureWebcamPhoto(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => const WebcamCaptureDialog(),
  );
}

class WebcamCaptureDialog extends StatefulWidget {
  const WebcamCaptureDialog({super.key});

  @override
  State<WebcamCaptureDialog> createState() => _WebcamCaptureDialogState();
}

class _WebcamCaptureDialogState extends State<WebcamCaptureDialog> {
  html.VideoElement? _videoElement;
  html.MediaStream? _localStream;
  bool _initialized = false;
  String? _error;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'webcam-view-${DateTime.now().millisecondsSinceEpoch}';
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      // Register view factory
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _videoElement!,
      );

      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('MediaDevices not supported by browser.');
      }
      final mediaStream = await mediaDevices.getUserMedia({
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720}
        }
      });
      
      _localStream = mediaStream;
      _videoElement!.srcObject = mediaStream;
      
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not access camera. Please ensure permissions are granted.';
        });
      }
    }
  }

  void _capture() {
    if (_videoElement == null || !_initialized) return;

    final canvas = html.CanvasElement(
      width: _videoElement!.videoWidth > 0 ? _videoElement!.videoWidth : 640,
      height: _videoElement!.videoHeight > 0 ? _videoElement!.videoHeight : 480,
    );
    
    final context2D = canvas.context2D;
    context2D.drawImage(_videoElement!, 0, 0);
    
    // Convert to data URL
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
    
    _cleanup();
    Navigator.of(context).pop(dataUrl);
  }

  void _cleanup() {
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        track.stop();
      }
    }
    if (_videoElement != null) {
      _videoElement!.srcObject = null;
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Take Profile Photo',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _cleanup();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.1), width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w500),
                        ),
                      ),
                    )
                  : (!_initialized
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                          ),
                        )
                      : HtmlElementView(viewType: _viewType)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _cleanup();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _initialized && _error == null ? _capture : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: Text(
                    'Capture',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
