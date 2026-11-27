import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/application/auth_controller.dart';
import '../auth/data/auth_repository.dart';
import '../quests/quest.dart';
import '../workout/exercise.dart';

/// Demo scoring rules, taken from the Figma design where it gives one.
abstract final class PointsRules {
  /// Figma: every rep is 1 Point and 1 XP.
  static const perRep = 1;
  static const xpPerRep = 1;
  static const dailyCap = 200;

  /// Used for the calorie estimate until the app asks for body weight.
  static const defaultWeightKg = 60.0;

  /// XP needed to finish [level]. Figma says it grows each level.
  static int xpForLevel(int level) => 100 * level;

  /// Bonus Points for finishing [level]. Figma: +40 on reaching Level 2.
  static int levelBonus(int level) => 40 * level;
}

/// A discount bought with Points.
class Coupon {
  const Coupon({required this.percent, required this.cost, required this.code});

  final int percent;
  final int cost;
  final String code;
}

/// What one finished workout earned.
class WorkoutResult {
  const WorkoutResult({
    required this.exercise,
    required this.reps,
    required this.seconds,
    required this.points,
    required this.xp,
    required this.levelBonus,
  });

  final Exercise exercise;
  final int reps;
  final int seconds;

  /// From reps, after the daily cap.
  final int points;
  final int xp;

  /// Extra Points for finishing a level.
  final int levelBonus;

  /// True when the daily cap cut the Points.
  bool get capped => points < reps * PointsRules.perRep;

  /// An estimate: MET x body weight x hours.
  double get calories =>
      exercise.met * PointsRules.defaultWeightKg * seconds / 3600;
}

class UserProgress {
  const UserProgress({
    this.xp = 0,
    this.earnedPoints = 0,
    this.monthPoints = 0,
    this.todayPoints = 0,
    this.coupons = const [],
    this.workouts = const [],
    this.claimedQuests = const {},
  });

  /// All time. Drives the Level.
  final int xp;

  /// All Points ever earned.
  final int earnedPoints;

  /// Points earned this month. Drives the Ranking, so spending never lowers it.
  final int monthPoints;

  /// Today. Limited by [PointsRules.dailyCap].
  final int todayPoints;

  final List<Coupon> coupons;
  final List<WorkoutResult> workouts;

  /// Names of today's claimed Quests.
  final Set<String> claimedQuests;

  /// Points still available to redeem.
  int get balance =>
      earnedPoints - coupons.fold(0, (sum, coupon) => sum + coupon.cost);

  ({int level, int xpInto}) get _levelState {
    var level = 1;
    var left = xp;
    while (left >= PointsRules.xpForLevel(level)) {
      left -= PointsRules.xpForLevel(level);
      level++;
    }
    return (level: level, xpInto: left);
  }

  int get level => _levelState.level;
  int get xpIntoLevel => _levelState.xpInto;
  int get xpForNextLevel => PointsRules.xpForLevel(level);
  double get levelFraction => xpIntoLevel / xpForNextLevel;

  UserProgress withCoupon(Coupon coupon) => UserProgress(
    xp: xp,
    earnedPoints: earnedPoints,
    monthPoints: monthPoints,
    todayPoints: todayPoints,
    coupons: [...coupons, coupon],
    workouts: workouts,
    claimedQuests: claimedQuests,
  );

  /// Pays a finished Quest's bonus, once. Bonus Points skip the daily cap.
  UserProgress withClaim(Quest quest) {
    if (!quest.isComplete(this) || quest.isClaimed(this)) return this;
    return UserProgress(
      xp: xp,
      earnedPoints: earnedPoints + quest.reward,
      monthPoints: monthPoints + quest.reward,
      todayPoints: todayPoints,
      coupons: coupons,
      workouts: workouts,
      claimedQuests: {...claimedQuests, quest.name},
    );
  }

  /// Adds a workout and says what it earned.
  (UserProgress, WorkoutResult) withWorkout({
    required Exercise exercise,
    required int reps,
    required int seconds,
  }) {
    final room = PointsRules.dailyCap - todayPoints;
    final points = (reps * PointsRules.perRep).clamp(0, room);
    final gainedXp = reps * PointsRules.xpPerRep;

    // Pay the bonus for every level this workout finishes.
    var bonus = 0;
    final newLevel = UserProgress(xp: xp + gainedXp).level;
    for (var finished = level; finished < newLevel; finished++) {
      bonus += PointsRules.levelBonus(finished);
    }

    final result = WorkoutResult(
      exercise: exercise,
      reps: reps,
      seconds: seconds,
      points: points,
      xp: gainedXp,
      levelBonus: bonus,
    );
    final next = UserProgress(
      xp: xp + gainedXp,
      earnedPoints: earnedPoints + points + bonus,
      monthPoints: monthPoints + points + bonus,
      todayPoints: todayPoints + points,
      coupons: coupons,
      workouts: [...workouts, result],
      claimedQuests: claimedQuests,
    );
    return (next, result);
  }
}

/// Fake, in-memory progress for each account, keyed by email.
class ProgressStore extends Notifier<Map<String, UserProgress>> {
  @override
  Map<String, UserProgress> build() => const {
    FakeAuthRepository.demoEmail: UserProgress(
      xp: 340,
      earnedPoints: 340,
      monthPoints: 340,
    ),
  };

  /// Saves a finished workout. Nothing is saved when no reps were done.
  WorkoutResult finishWorkout({
    required Exercise exercise,
    required int reps,
    required int seconds,
  }) {
    final email = ref.read(authControllerProvider).user?.email;
    final progress = state[email] ?? const UserProgress();
    final (next, result) = progress.withWorkout(
      exercise: exercise,
      reps: reps,
      seconds: seconds,
    );
    if (email != null && reps > 0) state = {...state, email: next};
    return result;
  }

  void claimQuest(Quest quest) {
    final email = ref.read(authControllerProvider).user?.email;
    final progress = state[email];
    if (email == null || progress == null) return;
    state = {...state, email: progress.withClaim(quest)};
  }

  /// Spends Points on a discount. False if there are not enough.
  bool redeem({required int percent, required int cost}) {
    final email = ref.read(authControllerProvider).user?.email;
    if (email == null) return false;
    final progress = state[email] ?? const UserProgress();
    if (progress.balance < cost) return false;

    final number = progress.coupons.length + 1;
    final coupon = Coupon(
      percent: percent,
      cost: cost,
      code: 'DEMO-$percent-${number.toString().padLeft(3, '0')}',
    );
    state = {...state, email: progress.withCoupon(coupon)};
    return true;
  }
}

final progressStoreProvider =
    NotifierProvider<ProgressStore, Map<String, UserProgress>>(
      ProgressStore.new,
    );

/// Progress of whoever is logged in. A new account starts at zero.
final myProgressProvider = Provider<UserProgress>((ref) {
  final email = ref.watch(authControllerProvider.select((s) => s.user?.email));
  return ref.watch(progressStoreProvider)[email] ?? const UserProgress();
});
