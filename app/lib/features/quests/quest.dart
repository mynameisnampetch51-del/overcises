import '../progress/progress.dart';

/// The daily Quests, with the targets and rewards from the Figma.
enum Quest {
  getMoving(
    difficulty: 'Easy',
    title: 'Get moving',
    detail: 'Finish 1 workout',
    target: 1,
    reward: 15,
  ),
  thirtyReps(
    difficulty: 'Medium',
    title: '30 reps of anything',
    detail: 'Count 30 reps in total',
    target: 30,
    reward: 35,
  ),
  tenMinutes(
    difficulty: 'Hard',
    title: 'Keep going',
    detail: 'Train for 10 minutes in total',
    target: 600,
    reward: 70,
  );

  const Quest({
    required this.difficulty,
    required this.title,
    required this.detail,
    required this.target,
    required this.reward,
  });

  final String difficulty;
  final String title;
  final String detail;

  /// Workouts, reps or seconds, depending on the Quest.
  final int target;

  /// Bonus Points.
  final int reward;

  /// How far today's workouts have come, never above [target].
  int done(UserProgress progress) {
    final amount = switch (this) {
      getMoving => progress.workouts.length,
      thirtyReps => progress.workouts.fold(0, (sum, w) => sum + w.reps),
      tenMinutes => progress.workouts.fold(0, (sum, w) => sum + w.seconds),
    };
    return amount.clamp(0, target);
  }

  bool isComplete(UserProgress progress) => done(progress) >= target;

  bool isClaimed(UserProgress progress) =>
      progress.claimedQuests.contains(name);
}

/// How many Quests are complete and not yet claimed.
int questsReady(UserProgress progress) => Quest.values
    .where((q) => q.isComplete(progress) && !q.isClaimed(progress))
    .length;

String questsReadyText(int count) =>
    '$count ${count == 1 ? 'Quest' : 'Quests'} ready to claim';
