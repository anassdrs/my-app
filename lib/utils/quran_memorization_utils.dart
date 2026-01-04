const Duration baseMemorizationInterval = Duration(minutes: 10);
const Duration longMemorizationInterval = Duration(days: 45);
const int masteredThreshold = 5;

Duration scaleInterval(Duration interval, double factor) {
  final scaledMs = (interval.inMilliseconds * factor).round();
  final next = Duration(milliseconds: scaledMs);
  return next < baseMemorizationInterval ? baseMemorizationInterval : next;
}
