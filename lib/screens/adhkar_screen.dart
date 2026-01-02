import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  List<_DhikrItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdhkar();
  }

  Future<void> _loadAdhkar() async {
    try {
      final raw = await rootBundle.loadString('assets/data/adhkar.json');
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items =
          decoded.map((item) => _DhikrItem.fromMap(item)).toList();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Adhkar", style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.redAccent,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _buildCard(context, item);
                  },
                ),
    );
  }

  Widget _buildCard(BuildContext context, _DhikrItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: AppTextStyles.heading2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(item.text, style: AppTextStyles.bodyLarge),
          if (item.translation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.translation,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Target: ${item.repeat}",
                style: AppTextStyles.bodyMedium,
              ),
              _buildCounter(context, item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(BuildContext context, _DhikrItem item) {
    final progress = item.repeat == 0
        ? 0.0
        : (item.count / item.repeat).clamp(0.0, 1.0);
    return Row(
      children: [
        Text(
          "${item.count}",
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(
                  0.1,
                ),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => setState(item.increment),
          icon: const Icon(Icons.add_circle),
        ),
        IconButton(
          onPressed: () => setState(item.reset),
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _DhikrItem {
  final String title;
  final String text;
  final String translation;
  final int repeat;
  int count;

  _DhikrItem({
    required this.title,
    required this.text,
    required this.translation,
    required this.repeat,
    this.count = 0,
  });

  factory _DhikrItem.fromMap(dynamic data) {
    final map = data as Map<String, dynamic>;
    return _DhikrItem(
      title: map['title']?.toString() ?? 'Dhikr',
      text: map['text']?.toString() ?? '',
      translation: map['translation']?.toString() ?? '',
      repeat: map['repeat'] is int ? map['repeat'] as int : 0,
    );
  }

  void increment() {
    count++;
  }

  void reset() {
    count = 0;
  }
}
