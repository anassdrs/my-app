import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/todo_bloc.dart';
import '../../blocs/quran_heart_bloc.dart';
import '../../models/todo.dart';

/// =======================
/// MAIN SCREEN
/// =======================
class QuranHeartScreen extends StatefulWidget {
  const QuranHeartScreen({super.key});

  @override
  State<QuranHeartScreen> createState() => _QuranHeartScreenState();
}

class _QuranHeartScreenState extends State<QuranHeartScreen> {
  final GlobalKey _svgKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate
      body: Stack(
        children: [
          /// BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
            ),
          ),

          /// CENTERED SVG CONTAINER
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: BlocBuilder<QuranHeartBloc, QuranHeartState>(
                builder: (context, quranState) {
                  if (quranState is QuranHeartError) {
                    return const Center(
                      child: Text(
                        'Error loading Quran Heart',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  if (quranState is! QuranHeartLoaded) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF43F5E),
                      ),
                    );
                  }

                  final data = quranState.data;
                  final groupCount = RegExp(
                    r'<g[^>]*class="section-group"[^>]*>',
                    caseSensitive: false,
                  ).allMatches(data.rawSvg).length;
                  final pathCount = RegExp(
                    r'<path[^>]*d="[^"]+"[^>]*>',
                    caseSensitive: false,
                  ).allMatches(data.rawSvg).length;
                  final hasActiveFill = data.svgPathsOnly.contains('#38BDF8');

                  return BlocBuilder<TodoBloc, TodoState>(
                    builder: (context, todoState) {
                      final List<Todo> todos = todoState is TodoLoaded
                          ? todoState.todos
                          : [];

                      final masteredSurahNumbers = todos
                          .where(
                            (todo) =>
                                todo.category == 'Quran Memorization' &&
                                todo.memorizationStatus == 'MASTERED' &&
                                todo.surahNumber != null,
                          )
                          .map((todo) => todo.surahNumber!)
                          .toSet();

                      final totalSelected = quranState.activeSurahs.length;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          _SvgWithLabels(
                            key: _svgKey,
                            data: data,
                            masteredSurahs: masteredSurahNumbers,
                            activeSurahs: quranState.activeSurahs,
                            transformController: _transformController,
                            onSegmentTap: (segment) =>
                                _handleSegmentTap(context, segment),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 6,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'segments=${data.segments.length} groups=$groupCount paths=$pathCount active=${quranState.activeSurahs.length} hasActive=$hasActiveFill',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),

                          /// TOP HEADER & PROGRESS
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 20,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back_ios_new,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'Quranic Heart',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    _ProgressBadge(count: totalSelected),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 48.0),
                                  child: Text(
                                    'Visualize your memorization journey',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// BOTTOM CONTROLS
                          Positioned(
                            bottom: 120,
                            right: 20,
                            child: Column(
                              children: [
                                GlassIconButton(
                                  icon: Icons.add,
                                  onTap: () {
                                    final current = _transformController.value
                                        .getMaxScaleOnAxis();
                                    _transformController.value =
                                        Matrix4.diagonal3Values(
                                          current * 1.2,
                                          current * 1.2,
                                          1.0,
                                        );
                                  },
                                ),
                                const SizedBox(height: 12),
                                GlassIconButton(
                                  icon: Icons.remove,
                                  onTap: () {
                                    final current = _transformController.value
                                        .getMaxScaleOnAxis();
                                    _transformController.value =
                                        Matrix4.diagonal3Values(
                                          current / 1.2,
                                          current / 1.2,
                                          1.0,
                                        );
                                  },
                                ),
                                const SizedBox(height: 12),
                                GlassIconButton(
                                  icon: Icons.center_focus_strong,
                                  onTap: () {
                                    _transformController.value =
                                        Matrix4.identity();
                                  },
                                ),
                              ],
                            ),
                          ),

                          /// LEGEND
                          Positioned(bottom: 120, left: 20, child: _Legend()),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSegmentTap(
    BuildContext context,
    QuranHeartSegment segment,
  ) async {
    final surahNumber = segment.surahNumber;
    final int key = surahNumber ?? -(segment.groupId + 1);
    context.read<QuranHeartBloc>().add(ToggleQuranHeartSegmentEvent(key));

    if (surahNumber == null) {
      debugPrint('Clicked segment with NULL surahNumber: ${segment.name}');
      return;
    }

    debugPrint('Dispatching ToggleSurahMasteryEvent for Surah $surahNumber');
    context.read<TodoBloc>().add(ToggleSurahMasteryEvent(surahNumber));
  }
}

class _SvgWithLabels extends StatefulWidget {
  final ParsedQuranHeartSvg data;
  final Set<int> masteredSurahs;
  final Set<int> activeSurahs;
  final TransformationController transformController;
  final ValueChanged<QuranHeartSegment> onSegmentTap;

  const _SvgWithLabels({
    super.key,
    required this.data,
    required this.masteredSurahs,
    required this.activeSurahs,
    required this.transformController,
    required this.onSegmentTap,
  });

  @override
  State<_SvgWithLabels> createState() => _SvgWithLabelsState();
}

class _SvgWithLabelsState extends State<_SvgWithLabels>
    with SingleTickerProviderStateMixin {
  bool _didSetInitialTransform = false;
  late final AnimationController _tapController;
  int? _lastTappedKey;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewBox = widget.data.viewBoxSize;
    final aspectRatio = viewBox.width / viewBox.height;
    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = min(
              constraints.maxWidth / viewBox.width,
              constraints.maxHeight / viewBox.height,
            );
            if (!_didSetInitialTransform) {
              _didSetInitialTransform = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  widget.transformController.value = Matrix4.diagonal3Values(
                    scale,
                    scale,
                    1.0,
                  );
                }
              });
            }
            return Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.6,
                    maxScale: 4.0,
                    constrained: false,
                    transformationController: widget.transformController,
                    child: SizedBox(
                      width: viewBox.width,
                      height: viewBox.height,
                      child: Stack(
                        children: [
                          IgnorePointer(
                            child: SvgPicture.string(
                              widget.data.svgPathsOnly,
                              key: ValueKey(widget.data.svgPathsOnly.hashCode),
                              width: viewBox.width,
                              height: viewBox.height,
                              fit: BoxFit.contain,
                              allowDrawingOutsideViewBox: true,
                            ),
                          ),
                          IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _tapController,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: viewBox,
                                  painter: _SurahSegmentsPainter(
                                    segments: widget.data.segments,
                                    activeSurahs: widget.activeSurahs,
                                    masteredSurahs: widget.masteredSurahs,
                                    labels: widget.data.labels,
                                    labelStyle: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    tapKey: _lastTappedKey,
                                    tapT: _tapController.value,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      debugPrint(
                        'QuranHeart: tap down ${details.localPosition}',
                      );
                      _handleTap(details.localPosition);
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleTap(Offset localPosition) {
    debugPrint('QuranHeart: handleTap $localPosition');
    final Offset sceneOffset = widget.transformController.toScene(
      localPosition,
    );
    debugPrint(
      'QuranHeart: sceneOffset=$sceneOffset segments=${widget.data.segments.length}',
    );

    if (widget.data.segments.isEmpty && widget.data.labels.isNotEmpty) {
      final labelHit = _findNearestLabel(sceneOffset);
      if (labelHit != null) {
        _handleLabelTap(labelHit);
      }
      return;
    }

    QuranHeartSegment? nearestSegment;
    double nearestDistance = double.infinity;

    for (final segment in widget.data.segments.reversed) {
      if (segment.path.contains(sceneOffset)) {
        debugPrint(
          'QuranHeart: hit name=${segment.name} surah=${segment.surahNumber} group=${segment.groupId}',
        );
        HapticFeedback.lightImpact();
        final key = segment.surahNumber ?? -(segment.groupId + 1);
        setState(() {
          _lastTappedKey = key;
        });
        _tapController.forward(from: 0.0);
        widget.onSegmentTap(segment);
        break;
      }

      final distance = (segment.center - sceneOffset).distance;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestSegment = segment;
      }
    }

    if (nearestSegment != null && nearestDistance <= 40) {
      debugPrint(
        'QuranHeart: fallback name=${nearestSegment.name} surah=${nearestSegment.surahNumber} group=${nearestSegment.groupId} dist=${nearestDistance.toStringAsFixed(1)}',
      );
      HapticFeedback.lightImpact();
      final key = nearestSegment.surahNumber ?? -(nearestSegment.groupId + 1);
      setState(() {
        _lastTappedKey = key;
      });
      _tapController.forward(from: 0.0);
      widget.onSegmentTap(nearestSegment);
    } else {
      debugPrint(
        'QuranHeart: no hit, nearestDist=${nearestDistance.toStringAsFixed(1)}',
      );
    }
  }

  QuranHeartLabel? _findNearestLabel(Offset sceneOffset) {
    QuranHeartLabel? nearest;
    double nearestDistance = double.infinity;
    for (final label in widget.data.labels) {
      final distance = (Offset(label.x, label.y) - sceneOffset).distance;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = label;
      }
    }
    if (nearest != null && nearestDistance <= 40) {
      return nearest;
    }
    return null;
  }

  void _handleLabelTap(QuranHeartLabel label) {
    debugPrint(
      'QuranHeart: label tap text=${label.text} group=${label.groupId}',
    );
    final key = -(label.groupId + 1);
    final pulsePath = Path()
      ..addOval(Rect.fromCircle(center: Offset(label.x, label.y), radius: 24));
    final segment = QuranHeartSegment(
      id: label.groupId,
      groupId: label.groupId,
      name: label.text,
      path: pulsePath,
      surahNumber: null,
      center: Offset(label.x, label.y),
    );
    HapticFeedback.lightImpact();
    setState(() {
      _lastTappedKey = key;
    });
    _tapController.forward(from: 0.0);
    widget.onSegmentTap(segment);
  }
}

class _ProgressBadge extends StatelessWidget {
  final int count;
  const _ProgressBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFFBD38D), size: 16),
          const SizedBox(width: 8),
          Text(
            '$count / 114',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahSegmentsPainter extends CustomPainter {
  final List<QuranHeartSegment> segments;
  final Set<int> activeSurahs;
  final Set<int> masteredSurahs;
  final List<QuranHeartLabel> labels;
  final TextStyle labelStyle;
  final int? tapKey;
  final double tapT;

  _SurahSegmentsPainter({
    required this.segments,
    required this.activeSurahs,
    required this.masteredSurahs,
    required this.labels,
    required this.labelStyle,
    required this.tapKey,
    required this.tapT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty && labels.isNotEmpty) {
      _paintLabelFallback(canvas);
      return;
    }

    final rosePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFF43F5E); // Mastered

    final bluePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF38BDF8); // Active

    for (final segment in segments) {
      final n = segment.surahNumber;
      final idKey = -(segment.groupId + 1);

      final isMastered = n != null && masteredSurahs.contains(n);
      final isActive =
          (n != null && activeSurahs.contains(n)) ||
          activeSurahs.contains(idKey);

      if (isActive) {
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawPath(segment.path, glowPaint);
        canvas.drawPath(segment.path, bluePaint);
      } else if (isMastered) {
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFF43F5E).withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawPath(segment.path, glowPaint);
        canvas.drawPath(segment.path, rosePaint);
      }
    }

    if (tapKey != null) {
      for (final segment in segments) {
        final n = segment.surahNumber;
        final idKey = -(segment.groupId + 1);
        final key = n ?? idKey;
        if (key != tapKey) continue;

        final pulse = (1.0 - tapT).clamp(0.0, 1.0);
        final pulsePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * pulse
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(segment.path, pulsePaint);
        break;
      }
    }

    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label.text, style: labelStyle),
        textDirection: TextDirection.rtl,
      )..layout();
      final offset = Offset(
        label.x - (painter.width / 2) + 16,
        label.y - (painter.height / 2),
      );
      painter.paint(canvas, offset);
    }
  }

  void _paintLabelFallback(Canvas canvas) {
    final inactivePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    final activePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF38BDF8);

    for (final segment in segments) {
      final key = segment.surahNumber ?? -(segment.groupId + 1);
      final paint = activeSurahs.contains(key) ? activePaint : inactivePaint;
      canvas.drawPath(segment.path, paint); 
    }
    // for (final label in labels) {
    //   final key = -(label.groupId + 1);
    //   final paint = activeSurahs.contains(key) ? activePaint : inactivePaint;
    //   // canvas.drawCircle(Offset(label.x, label.y), 22, paint);
    //   canvas.drawOval(
    //     Rect.fromCircle(center: Offset(label.x, label.y), radius: 22),
    //     paint,
    //   );
    // }

    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label.text, style: labelStyle),
        textDirection: TextDirection.rtl,
      )..layout();
      final offset = Offset(
        label.x - (painter.width / 2) + 16,
        label.y - (painter.height / 2),
      );
      painter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _SurahSegmentsPainter oldDelegate) {
    return !setEquals(oldDelegate.masteredSurahs, masteredSurahs) ||
        !setEquals(oldDelegate.activeSurahs, activeSurahs) ||
        oldDelegate.segments.length != segments.length ||
        oldDelegate.labels.length != labels.length ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.tapKey != tapKey ||
        oldDelegate.tapT != tapT;
  }
}

class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 50,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool hover = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) {
          setState(() => pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: widget.size,
          height: widget.size,
          transform: Matrix4.translationValues(
            0,
            pressed
                ? 0
                : hover
                ? -2
                : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: hover ? const Color(0xFF334155) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(widget.size / 2),
            border: Border.all(
              color: hover
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: hover ? 16 : 12,
                offset: Offset(0, pressed ? 2 : 4),
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: widget.size * 0.48,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendItem(const Color(0xFF38BDF8), 'Currently Selecting'),
          const SizedBox(height: 8),
          _legendItem(const Color(0xFFF43F5E), 'Mastered Surah'),
          const SizedBox(height: 8),
          _legendItem(Colors.white, 'Not Started'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              if (color != Colors.white)
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
