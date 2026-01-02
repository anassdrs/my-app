import 'package:adhan/adhan.dart' as adhan;
import 'package:geolocator/geolocator.dart';

class PrayerTimeResult {
  final adhan.PrayerTimes prayerTimes;
  final adhan.Coordinates coordinates;
  final bool usedFallback;
  final String locationLabel;
  final adhan.CalculationParameters calculationParameters;

  const PrayerTimeResult({
    required this.prayerTimes,
    required this.coordinates,
    required this.usedFallback,
    required this.locationLabel,
    required this.calculationParameters,
  });
}

class PrayerTimeService {
  static const double casablancaLat = 33.5731;
  static const double casablancaLng = -7.5898;

  Future<PrayerTimeResult> getPrayerTimes() async {
    final now = DateTime.now();
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallback(now, 'Casablanca (GPS off)');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallback(now, 'Casablanca (permission denied)');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!position.latitude.isFinite || !position.longitude.isFinite) {
        return _fallback(now, 'Casablanca (invalid GPS)');
      }

      final coordinates = adhan.Coordinates(
        position.latitude,
        position.longitude,
      );
      final params = adhan.CalculationMethod.muslim_world_league.getParameters();
      params.madhab = adhan.Madhab.shafi;
      final dateComponents = adhan.DateComponents(now.year, now.month, now.day);
      final times = adhan.PrayerTimes(coordinates, dateComponents, params);
      return PrayerTimeResult(
        prayerTimes: times,
        coordinates: coordinates,
        usedFallback: false,
        locationLabel:
            '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}',
        calculationParameters: params,
      );
    } catch (_) {
      return _fallback(now, 'Casablanca (GPS error)');
    }
  }

  PrayerTimeResult _fallback(DateTime now, String label) {
    final coordinates = adhan.Coordinates(casablancaLat, casablancaLng);
    final params = adhan.CalculationParameters(
      fajrAngle: 19,
      ishaAngle: 17,
    );
    params.madhab = adhan.Madhab.shafi;
    final dateComponents = adhan.DateComponents(now.year, now.month, now.day);
    final times = adhan.PrayerTimes(coordinates, dateComponents, params);
    return PrayerTimeResult(
      prayerTimes: times,
      coordinates: coordinates,
      usedFallback: true,
      locationLabel: label,
      calculationParameters: params,
    );
  }
}
