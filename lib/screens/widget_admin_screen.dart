import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';
import '../controllers/widget_admin_controller.dart';
import '../models/streak_widget_state.dart';

class WidgetAdminScreen extends GetView<WidgetAdminController> {
  const WidgetAdminScreen({super.key});

  static const Map<StreakWidgetState, String> _stateLabels = {
    StreakWidgetState.startChallenge: 'State 1',
    StreakWidgetState.justCompleted: 'State 2',
    StreakWidgetState.completedToday: 'State 3',
    StreakWidgetState.awaitingToday: 'State 4',
  };

  Color _stateColor(StreakWidgetState state) {
    switch (state) {
      case StreakWidgetState.unlinked:
        return Colors.grey.shade600;
      case StreakWidgetState.startChallenge:
        return AppColors.orange;
      case StreakWidgetState.justCompleted:
        return Colors.green.shade400;
      case StreakWidgetState.completedToday:
        return Colors.blue.shade400;
      case StreakWidgetState.awaitingToday:
        return Colors.pink.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshInstances,
          ),
        ],
      ),
      body: Obx(() {
        final widgets = controller.widgetInstances;
        if (controller.isLoading.value && widgets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (widgets.isEmpty) {
          return Center(
            child: Text(
              'No linked widgets yet.\nAdd a widget on the home screen, tap LINK, and complete the login flow.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(16),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: widgets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final instance = widgets[index];
            final stateLabel = instance.state == StreakWidgetState.unlinked
                ? 'Unlinked'
                : _stateLabels[instance.state] ?? instance.state.name;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Widget #${instance.widgetId}',
                          style: AppTextStyles.hero(18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _stateColor(instance.state).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            stateLabel,
                            style: AppTextStyles.body(14).copyWith(
                              color: _stateColor(instance.state),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login code: ${instance.loginCode ?? '--'}',
                      style: AppTextStyles.body(14),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _stateLabels.entries.map((entry) {
                        return ElevatedButton(
                          onPressed: instance.loginCode == null
                              ? null
                              : () => controller.setWidgetState(
                                    instance: instance,
                                    state: entry.key,
                                    streakCount: entry.key ==
                                            StreakWidgetState.startChallenge
                                        ? 0
                                        : instance.streakCount,
                                    weekProgress: instance.weekProgress,
                                  ),
                          child: Text(entry.value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => controller.unlinkWidget(instance),
                        child: const Text('Unlink'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

