import 'dart:math';

import 'exercise.dart';

/// The body points the rules need.
enum Joint {
  nose,
  leftShoulder,
  rightShoulder,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

/// A body point in picture pixels. y grows downward.
class Landmark {
  const Landmark(this.x, this.y, [this.visibility = 1]);

  final double x;
  final double y;

  /// How sure the pose model is, 0 to 1.
  final double visibility;
}

typedef Pose = Map<Joint, Landmark>;

/// Counts reps from one pose per camera frame. Knows nothing about the camera
/// or the pose model, so any of them can feed it.
abstract class RepCounter {
  factory RepCounter(Exercise exercise) => switch (exercise) {
    Exercise.jumpingJack => JumpingJackCounter(),
    Exercise.sitUp => SitUpCounter(),
  };

  /// Points the model is less sure of than this are not trusted.
  static const minVisibility = 0.5;

  int get count;

  /// Reads one frame. True when it completed a rep.
  bool update(Pose pose);
}

bool _sees(Pose pose, List<Joint> joints) =>
    joints.every((j) => (pose[j]?.visibility ?? 0) >= RepCounter.minVisibility);

/// Closed (hands down, feet together) then open (hands above the head, feet
/// apart) is one rep. From jumpingjack.ipynb, plus the closed position.
class JumpingJackCounter implements RepCounter {
  /// Ankle distance compared with shoulder width. Tune on real people.
  static const feetOpen = 1.1;
  static const feetClosed = 0.9;

  /// Box height above the nose, in shoulder widths. Tall enough for straight
  /// arms.
  static const boxHeight = 2.5;

  static const _needed = [
    Joint.nose,
    Joint.leftShoulder,
    Joint.rightShoulder,
    Joint.leftWrist,
    Joint.rightWrist,
    Joint.leftAnkle,
    Joint.rightAnkle,
  ];

  bool _closed = false;

  /// True once the closed position is seen and an open one will count.
  bool get isReady => _closed;

  /// Whether every point this counter needs is in view.
  static bool seesBody(Pose pose) => _sees(pose, _needed);

  /// Ankle distance in shoulder widths, to help tune the limits.
  static double? feetRatio(Pose pose) {
    if (!seesBody(pose)) return null;
    final shoulders =
        (pose[Joint.leftShoulder]!.x - pose[Joint.rightShoulder]!.x).abs();
    if (shoulders == 0) return null;
    return (pose[Joint.leftAnkle]!.x - pose[Joint.rightAnkle]!.x).abs() /
        shoulders;
  }

  @override
  int count = 0;

  @override
  bool update(Pose pose) {
    if (!_sees(pose, _needed)) return false;
    final nose = pose[Joint.nose]!;
    final leftShoulder = pose[Joint.leftShoulder]!;
    final rightShoulder = pose[Joint.rightShoulder]!;
    final leftWrist = pose[Joint.leftWrist]!;
    final rightWrist = pose[Joint.rightWrist]!;

    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
    final ankleWidth = (pose[Joint.leftAnkle]!.x - pose[Joint.rightAnkle]!.x)
        .abs();
    final centerX = (leftShoulder.x + rightShoulder.x) / 2;

    // The box above the head, one shoulder width to each side.
    bool inBox(Landmark wrist) =>
        (wrist.x - centerX).abs() < shoulderWidth &&
        wrist.y < nose.y &&
        wrist.y > nose.y - boxHeight * shoulderWidth;

    final handsDown =
        leftWrist.y > leftShoulder.y && rightWrist.y > rightShoulder.y;

    if (handsDown && ankleWidth < feetClosed * shoulderWidth) {
      _closed = true;
    } else if (_closed &&
        inBox(leftWrist) &&
        inBox(rightWrist) &&
        ankleWidth > feetOpen * shoulderWidth) {
      _closed = false;
      count++;
      return true;
    }
    return false;
  }
}

/// Side view. Lying (nose low) then up (nose high above the hip) is one rep.
/// From SitUp 2.ipynb.
class SitUpCounter implements RepCounter {
  /// How far the nose is above the hip, in trunk lengths.
  static const down = 0.3;
  static const up = 0.7;

  bool? _leftSide;

  // Starts false, so someone already sitting or standing is not counted.
  bool _lying = false;

  @override
  int count = 0;

  @override
  bool update(Pose pose) {
    // The side nearer the camera, picked once.
    if (_leftSide == null) {
      double score(List<Joint> joints) =>
          joints.fold(0, (sum, j) => sum + (pose[j]?.visibility ?? 0));
      final left = score([Joint.leftShoulder, Joint.leftHip, Joint.leftKnee]);
      final right = score([
        Joint.rightShoulder,
        Joint.rightHip,
        Joint.rightKnee,
      ]);
      if (max(left, right) < 3 * RepCounter.minVisibility) return false;
      _leftSide = left > right;
    }
    final shoulderJoint = _leftSide! ? Joint.leftShoulder : Joint.rightShoulder;
    final hipJoint = _leftSide! ? Joint.leftHip : Joint.rightHip;
    if (!_sees(pose, [Joint.nose, shoulderJoint, hipJoint])) return false;

    final shoulder = pose[shoulderJoint]!;
    final hip = pose[hipJoint]!;
    final trunk = sqrt(pow(shoulder.x - hip.x, 2) + pow(shoulder.y - hip.y, 2));
    if (trunk <= 1) return false;
    final rise = (hip.y - pose[Joint.nose]!.y) / trunk;

    if (rise < down) {
      _lying = true;
    } else if (rise > up && _lying) {
      _lying = false;
      count++;
      return true;
    }
    return false;
  }
}
