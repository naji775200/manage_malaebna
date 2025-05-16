import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/navigation/navigation_bloc.dart';
import '../../logic/navigation/navigation_event.dart';
import '../../logic/navigation/navigation_state.dart';
import '../../core/services/translation_service.dart';

class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return BottomNavigationBar(
          currentIndex: state.selectedIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            context.read<NavigationBloc>().add(NavigationTabChanged(index));
          },
          items: [
            _buildNavigationItem(
              context,
              Icons.home_outlined,
              Icons.home,
              0,
              state.selectedIndex,
              translationService.tr('navigation.home', {}, context),
            ),
            _buildNavigationItem(
              context,
              Icons.sports_soccer_outlined,
              Icons.sports_soccer,
              1,
              state.selectedIndex,
              translationService.tr('navigation.fields', {}, context),
            ),
            _buildNavigationItem(
              context,
              Icons.request_page_outlined,
              Icons.request_page,
              2,
              state.selectedIndex,
              translationService.tr('navigation.requests', {}, context),
            ),
            _buildNavigationItem(
              context,
              Icons.payment_outlined,
              Icons.payment,
              3,
              state.selectedIndex,
              translationService.tr('navigation.payment', {}, context),
            ),
            _buildNavigationItem(
              context,
              Icons.person_outline,
              Icons.person,
              4,
              state.selectedIndex,
              translationService.tr('navigation.profile', {}, context),
            ),
          ],
        );
      },
    );
  }

  BottomNavigationBarItem _buildNavigationItem(
    BuildContext context,
    IconData icon,
    IconData activeIcon,
    int index,
    int currentIndex,
    String label,
  ) {
    final isSelected = index == currentIndex;
    return BottomNavigationBarItem(
      icon: Icon(
        isSelected ? activeIcon : icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      label: label,
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
  }) {
    // Check if text is likely to overflow (for Arabic especially)
    final bool isLongText = label.length > 10;

    return InkWell(
      onTap: () {
        context.read<NavigationBloc>().add(NavigationTabChanged(index));
      },
      child: Container(
        // Adjust width to be flexible based on screen size
        width: MediaQuery.of(context).size.width / 5,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              // Make icon slightly smaller for items with long text
              size: isLongText ? 22 : 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: isLongText ? 10 : 12,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
