import 'package:flutter_test/flutter_test.dart';
import 'package:overcise/features/workout/rep_counter.dart';

/// Standing person facing the camera, shoulders 100 px wide.
Pose jack({required bool handsUp, required double feet, double seen = 1}) {
  final wristY = handsUp ? 60.0 : 400.0;
  return {
    Joint.nose: const Landmark(300, 100),
    Joint.leftShoulder: const Landmark(350, 160),
    Joint.rightShoulder: const Landmark(250, 160),
    Joint.leftWrist: Landmark(handsUp ? 330 : 380, wristY),
    Joint.rightWrist: Landmark(handsUp ? 270 : 220, wristY),
    Joint.leftAnkle: Landmark(300 + feet / 2, 600, seen),
    Joint.rightAnkle: Landmark(300 - feet / 2, 600, seen),
  };
}

/// Side view with a 100 px trunk; [rise] is the nose height in trunk lengths.
Pose sit(double rise) => {
  Joint.nose: Landmark(100, 500 - rise * 100),
  Joint.leftShoulder: const Landmark(200, 500),
  Joint.leftHip: const Landmark(300, 500),
  Joint.leftKnee: const Landmark(380, 440),
};

int run(RepCounter counter, List<Pose> frames) {
  for (final frame in frames) {
    counter.update(frame);
  }
  return counter.count;
}

void main() {
  final closed = jack(handsUp: false, feet: 60);
  final open = jack(handsUp: true, feet: 160);

  test('jumping jack: five real reps count five', () {
    expect(
      run(JumpingJackCounter(), [
        for (var i = 0; i < 5; i++) ...[closed, open, open],
      ]),
      5,
    );
  });

  test('jumping jack: legs kept spread, arms only, counts nothing', () {
    final spreadDown = jack(handsUp: false, feet: 160);
    expect(
      run(JumpingJackCounter(), [
        for (var i = 0; i < 5; i++) ...[spreadDown, open],
      ]),
      0,
    );
  });

  test('jumping jack: arms only or legs only counts nothing', () {
    final armsOnly = jack(handsUp: true, feet: 60);
    final legsOnly = jack(handsUp: false, feet: 160);
    expect(run(JumpingJackCounter(), [closed, armsOnly, closed]), 0);
    expect(run(JumpingJackCounter(), [closed, legsOnly, closed]), 0);
  });

  test('jumping jack: hidden feet are ignored', () {
    expect(
      run(JumpingJackCounter(), [
        jack(handsUp: false, feet: 60, seen: 0.1),
        jack(handsUp: true, feet: 160, seen: 0.1),
      ]),
      0,
    );
  });

  test('sit-up: lying then up counts once per rep', () {
    expect(
      run(SitUpCounter(), [
        sit(0.1),
        sit(0.5),
        sit(0.9),
        sit(0.9),
        sit(0.5),
        sit(0.9),
        sit(0.1),
        sit(0.9),
      ]),
      2,
    );
  });

  test('sit-up: someone already upright is not counted', () {
    expect(run(SitUpCounter(), [sit(1.4), sit(1.4)]), 0);
  });
}
