import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/qibla_bloc.dart';
import '../../utils/constants.dart';
import '../../widgets/app_card.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Qibla", style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<QiblaBloc, QiblaState>(
          builder: (context, state) {
            if (state is QiblaLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is QiblaError) {
              return _buildError(state.message);
            }
            if (state is QiblaLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, state),
                    const SizedBox(height: 24),
                    SizedBox(height: 320, child: _buildCompass(context, state)),
                    const SizedBox(height: 16),
                    _buildAngleInfo(state),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, QiblaLoaded state) {
    return AppCard(
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
                  state.locationLabel.isEmpty
                      ? "Location unknown"
                      : state.locationLabel,
                  style: AppTextStyles.bodyMedium,
                ),
                if (state.isFallback)
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

  Widget _buildCompass(BuildContext context, QiblaLoaded state) {
    if (state.heading == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Waiting for compass..."),
          ],
        ),
      );
    }

    final headingRad = (state.heading! * (math.pi / 180) * -1);
    final qiblaRad = (state.qiblaAngle * (math.pi / 180) * -1);

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
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
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

  Widget _buildAngleInfo(QiblaLoaded state) {
    return AppCard(
      boxShadow: const [],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Qibla Angle", style: AppTextStyles.bodyLarge),
          Text(
            "${state.qiblaAngle.toStringAsFixed(1)}°",
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
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: Colors.redAccent),
        textAlign: TextAlign.center,
      ),
    );
  }
}
