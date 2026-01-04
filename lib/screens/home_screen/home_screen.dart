import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../blocs/home_bloc.dart';
import '../../utils/constants.dart';
import '../dashboard/dashboard_view.dart';
import '../add_edit_todo_screen/todo_view/todo_view.dart';
import '../habit_view/habit_view.dart';
import '../prayer_view/prayer_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Widget> _views = [
    DashboardView(),
    TodoView(),
    HabitView(),
    PrayerView(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final currentIndex = state.currentIndex;
        debugPrint("HomeScreen building index: $currentIndex");

        return Scaffold(
          extendBody: true,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(currentIndex),
              child: _views[currentIndex],
            ),
          ),
          bottomNavigationBar: Container(
            margin: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.2,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (index) =>
                    context.read<HomeBloc>().add(ChangeTabEvent(index)),
                backgroundColor: Colors.transparent,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: Colors.grey,
                elevation: 0,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_rounded),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.listCheck),
                    label: 'Todos',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.fire),
                    label: 'Habits',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.mosque),
                    label: 'Prayers',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
