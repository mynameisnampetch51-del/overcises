import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'pose_camera_stub.dart'
    if (dart.library.js_interop) 'pose_camera_web.dart';
import 'rep_counter.dart';

/// Builds a camera picture that reports the pose in every frame.
typedef PoseCamera = Widget Function({
  required ValueChanged<Pose?> onPose,
  required ValueChanged<String> onError,
});

/// Null where there is no pose model yet (only the web build has one). The
/// workout screen then runs in demo mode.
final poseCameraProvider = Provider<PoseCamera?>((ref) => createPoseCamera());

/// MediaPipe's numbers for the points in [Joint], in the same order.
const _mediaPipeIndex = [0, 11, 12, 15, 16, 23, 24, 25, 26, 27, 28];

/// Reads 33 x (x, y, visibility) from MediaPipe.
Pose poseFromMediaPipe(List<double> data) => {
  for (final joint in Joint.values)
    joint: Landmark(
      data[_mediaPipeIndex[joint.index] * 3],
      data[_mediaPipeIndex[joint.index] * 3 + 1],
      data[_mediaPipeIndex[joint.index] * 3 + 2],
    ),
};
