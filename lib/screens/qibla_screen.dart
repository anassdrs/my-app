import 'dart:math' as math;

import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../services/prayer_time_service.dart';
import '../utils/constants.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _heading;
  double? _qibla;
  String _locationLabel = '';
  bool _isFallback = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final service = PrayerTimeService();
    try {
      final result = await service.getPrayerTimes();
      setState(() {
        _locationLabel = result.locationLabel;
        _isFallback = result.usedFallback;
        _qibla = adhan.Qibla(result.coordinates).direction;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Qibla", style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<CompassEvent>(
                stream: FlutterCompass.events,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildError(
                      "Compass not available on this device.",
                    );
                  }
                  if (!snapshot.hasData || snapshot.data?.heading == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  _heading = snapshot.data!.heading;
                  if (_heading!.isNaN) {
                    return _buildError("Compass data unavailable.");
                  }

                  return _buildCompass();
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildAngleInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.explore, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Direction to Kaaba",
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _locationLabel.isEmpty ? "Loading location..." : _locationLabel,
                  style: AppTextStyles.bodyMedium,
                ),
                if (_isFallback)
                  Text(
                    "Fallback: Casablanca coordinates",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass() {
    if (_qibla == null || _heading == null) {
      return _buildError("Qibla angle unavailable.");
    }

    final headingRad = (_heading! * (math.pi / 180) * -1);
    final qiblaRad = (_qibla! * (math.pi / 180) * -1);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: headingRad,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "N",
                  style: AppTextStyles.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: qiblaRad,
            child: Icon(
              Icons.navigation,
              size: 140,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAngleInfo() {
    if (_qibla == null) {
      return _buildError("Qibla angle unavailable.");
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Qibla Angle", style: AppTextStyles.bodyLarge),
          Text(
            "${_qibla!.toStringAsFixed(1)}°",
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Text(
        _error ?? message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.redAccent,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
