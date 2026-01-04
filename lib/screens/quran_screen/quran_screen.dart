import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../blocs/quran_bloc.dart';
import '../../utils/constants.dart';
import '../../widgets/app_card.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quran", style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              onChanged: (value) {
                context.read<QuranBloc>().add(FilterQuranEvent(value));
              },
              decoration: InputDecoration(
                hintText: "Search Surah...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<QuranBloc, QuranState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: state.filteredSurahs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final surah = state.filteredSurahs[index];
              return _SurahCard(
                surah: surah,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          QuranSurahScreen(surahNumber: surah.number),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class QuranSurahScreen extends StatelessWidget {
  final int surahNumber;
  final int? startAyah;
  final int? endAyah;

  const QuranSurahScreen({
    super.key,
    required this.surahNumber,
    this.startAyah,
    this.endAyah,
  });

  @override
  Widget build(BuildContext context) {
    final ayahCount = quran.getVerseCount(surahNumber);
    final rangeLabel = (startAyah != null && endAyah != null)
        ? "Ayah $startAyah - $endAyah"
        : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          quran.getSurahNameEnglish(surahNumber),
          style: AppTextStyles.heading2,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: ayahCount + (rangeLabel == null ? 0 : 1),
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (rangeLabel != null && index == 0) {
            return AppCard(
              child: Text(
                "Memorization range: $rangeLabel",
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          final listIndex = rangeLabel == null ? index : index - 1;
          final ayahNumber = listIndex + 1;
          final arabic = quran.getVerse(surahNumber, ayahNumber);
          final translationEn = quran.getVerseTranslation(
            surahNumber,
            ayahNumber,
          );
          final translationFr = quran.getVerseTranslation(
            surahNumber,
            ayahNumber,
            translation: quran.Translation.frHamidullah,
          );
          final isInRange =
              startAyah != null &&
              endAyah != null &&
              ayahNumber >= startAyah! &&
              ayahNumber <= endAyah!;
          return AppCard(
            borderRadius: 16,
            backgroundColor: isInRange
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arabic,
                  style: AppTextStyles.heading2.copyWith(fontSize: 18),
                  textDirection: TextDirection.rtl,
                ),
                if (translationEn.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(translationEn, style: AppTextStyles.bodyMedium),
                ],
                if (translationFr.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    translationFr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  final SurahInfo surah;
  final VoidCallback onTap;

  const _SurahCard({required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah.arabicName,
                  style: AppTextStyles.heading2.copyWith(fontSize: 18),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 6),
                Text(surah.englishName, style: AppTextStyles.bodyMedium),
                Text(
                  surah.frenchName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
