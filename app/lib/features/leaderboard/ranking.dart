/// The top this many players will win a Reward at the end of the month.
/// Not built yet, so the screen calls it "coming soon".
const rewardPlaces = 20;

/// Made-up players for the demo, highest first.
const otherPlayers = <({String name, int points})>[
  (name: 'Ploy', points: 1240),
  (name: 'Ton', points: 1105),
  (name: 'Mint', points: 980),
  (name: 'Bank', points: 870),
  (name: 'Fah', points: 760),
  (name: 'Beam', points: 655),
  (name: 'June', points: 590),
  (name: 'Earth', points: 520),
  (name: 'Nan', points: 470),
  (name: 'Pete', points: 415),
  (name: 'Aom', points: 372),
  (name: 'Game', points: 318),
  (name: 'Praew', points: 290),
  (name: 'Win', points: 262),
  (name: 'Cream', points: 231),
  (name: 'Ice', points: 205),
  (name: 'Tle', points: 184),
  (name: 'Gift', points: 160),
  (name: 'Boss', points: 138),
  (name: 'Pang', points: 115),
  (name: 'Joe', points: 96),
  (name: 'Mew', points: 74),
  (name: 'Film', points: 52),
  (name: 'Nut', points: 31),
  (name: 'Dream', points: 12),
];

class MyRank {
  const MyRank({required this.place, required this.pointsToRewardZone});

  final int place;

  /// Zero when already in a Reward place.
  final int pointsToRewardZone;

  bool get inRewardZone => place <= rewardPlaces;
}

MyRank rankFor(int monthPoints) {
  final place = 1 + otherPlayers.where((p) => p.points > monthPoints).length;
  final needed = place <= rewardPlaces
      ? 0
      : otherPlayers[rewardPlaces - 1].points - monthPoints;
  return MyRank(place: place, pointsToRewardZone: needed);
}
