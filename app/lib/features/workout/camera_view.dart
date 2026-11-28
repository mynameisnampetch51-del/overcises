import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../auth/application/auth_controller.dart';

/// Builds the live camera picture. Tests replace it, as they have no camera.
final cameraViewProvider = Provider<Widget Function()>(
  (ref) =>
      () => const CameraView(),
);

/// Whether the signed-in user agreed to use the camera. Not saved.
class CameraConsent extends Notifier<bool> {
  @override
  bool build() {
    // Asked again whenever someone else signs in.
    ref.watch(authControllerProvider.select((s) => s.user?.email));
    return false;
  }

  void allow() => state = true;
}

final cameraConsentProvider = NotifierProvider<CameraConsent, bool>(
  CameraConsent.new,
);

/// Shows the front camera. Nothing is recorded, analysed or sent anywhere.
class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      // The screen may have closed while the camera was starting.
      if (!mounted) return await controller.dispose();
      setState(() => _controller = controller);
    } catch (_) {
      // No camera, or permission refused. The workout still works.
      await controller?.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_failed) return const CameraMessage('Camera not available');
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.skeleton),
      );
    }
    return Center(child: CameraPreview(controller));
  }
}

/// Text shown in the camera box when there is no picture.
class CameraMessage extends StatelessWidget {
  const CameraMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    // One line along the top, clear of the rep count in the middle.
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              size: 20,
              color: AppColors.skeleton,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.pastel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
