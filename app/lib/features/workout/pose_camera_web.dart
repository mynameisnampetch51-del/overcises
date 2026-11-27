import 'dart:js_interop';

import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' as web;

import 'pose_camera.dart';
import 'rep_counter.dart';

/// Talks to web/pose.js.
@JS('overcisePose.start')
external _Session _start(
  web.HTMLElement host,
  JSFunction onPose,
  JSFunction onError,
);

extension type _Session(JSObject _) implements JSObject {
  external void stop();
}

PoseCamera? createPoseCamera() =>
    ({required onPose, required onError}) =>
        _WebPoseCamera(onPose: onPose, onError: onError);

class _WebPoseCamera extends StatefulWidget {
  const _WebPoseCamera({required this.onPose, required this.onError});

  final ValueChanged<Pose?> onPose;
  final ValueChanged<String> onError;

  @override
  State<_WebPoseCamera> createState() => _WebPoseCameraState();
}

class _WebPoseCameraState extends State<_WebPoseCamera> {
  _Session? _session;

  void _open(Object element) {
    if (!mounted) return;
    try {
      _session = _start(
        element as web.HTMLElement,
        ((JSFloat64Array? data) {
          if (!mounted) return;
          widget.onPose(data == null ? null : poseFromMediaPipe(data.toDart));
        }).toJS,
        ((JSString message) {
          if (mounted) widget.onError(message.toDart);
        }).toJS,
      );
    } catch (_) {
      widget.onError('The pose script did not load. Refresh the page.');
    }
  }

  @override
  void dispose() {
    _session?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      HtmlElementView.fromTagName(tagName: 'div', onElementCreated: _open);
}
