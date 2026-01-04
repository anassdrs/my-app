import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/prayer.dart';
import '../../blocs/prayer_bloc.dart';
import '../../blocs/add_edit_prayer_bloc.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';

class AddEditPrayerScreen extends StatelessWidget {
  final Prayer? prayer;
  const AddEditPrayerScreen({super.key, this.prayer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AddEditPrayerBloc(prayerBloc: context.read<PrayerBloc>())
            ..add(InitializePrayerEvent(prayer)),
      child: const _AddEditPrayerView(),
    );
  }
}

class _AddEditPrayerView extends StatefulWidget {
  const _AddEditPrayerView();

  @override
  State<_AddEditPrayerView> createState() => _AddEditPrayerViewState();
}

class _AddEditPrayerViewState extends State<_AddEditPrayerView> {
  late TextEditingController _descriptionController;
  final List<String> _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: context.read<AddEditPrayerBloc>().state.description,
    );
    _descriptionController.addListener(() {
      context.read<AddEditPrayerBloc>().add(
        UpdatePrayerFieldsEvent(description: _descriptionController.text),
      );
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddEditPrayerBloc, AddEditPrayerState>(
      listener: (context, state) {
        if (state.isSuccess) Navigator.pop(context);
        if (state.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      child: BlocBuilder<AddEditPrayerBloc, AddEditPrayerState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.initialPrayer == null ? "New Prayer" : "Edit Prayer",
                style: AppTextStyles.heading2,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: state.name,
                      decoration: InputDecoration(
                        labelText: "Prayer Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _prayerNames
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (val) {
                        context.read<AddEditPrayerBloc>().add(
                          UpdatePrayerFieldsEvent(name: val),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _descriptionController,
                      style: AppTextStyles.bodyLarge,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Description (optional)",
                        hintStyle: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (state.isLoadingLocation)
                      const LinearProgressIndicator(minHeight: 3),
                    if (state.locationError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          state.locationError!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _buildLocationInfo(context, state),
                    const SizedBox(height: 20),
                    _buildPrayerTimeCard(context, state),
                    const SizedBox(height: 16),
                    _buildReminderSlider(context, state),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: "Save Prayer",
                      onPressed: () => context.read<AddEditPrayerBloc>().add(
                        SavePrayerEvent(),
                      ),
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationInfo(BuildContext context, AddEditPrayerState state) {
    return Row(
      children: [
        Expanded(
          child: Text(
            state.latitude == null || state.longitude == null
                ? 'Location not set'
                : 'Lat ${state.latitude!.toStringAsFixed(4)}, Lng ${state.longitude!.toStringAsFixed(4)}',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        TextButton.icon(
          onPressed: state.isLoadingLocation
              ? null
              : () =>
                    context.read<AddEditPrayerBloc>().add(FetchLocationEvent()),
          icon: const Icon(Icons.my_location, size: 18),
          label: const Text('Use GPS'),
        ),
      ],
    );
  }

  Widget _buildPrayerTimeCard(BuildContext context, AddEditPrayerState state) {
    if (state.prayerTime == null) return const SizedBox();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Prayer Time for ${state.name}:",
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 10),
            Text(
              state.prayerTime!
                  .toLocal()
                  .toString()
                  .split(' ')[1]
                  .substring(0, 5),
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSlider(BuildContext context, AddEditPrayerState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Reminder",
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          state.reminderMinutes == 0
              ? "At prayer time"
              : "${state.reminderMinutes} minutes before",
          style: AppTextStyles.bodyMedium,
        ),
        Slider(
          value: state.reminderMinutes.toDouble(),
          min: 0,
          max: 60,
          divisions: 12,
          label: state.reminderMinutes == 0
              ? "At time"
              : "${state.reminderMinutes} min",
          onChanged: (val) {
            context.read<AddEditPrayerBloc>().add(
              UpdatePrayerFieldsEvent(reminderMinutes: val.round()),
            );
          },
        ),
      ],
    );
  }
}
