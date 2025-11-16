import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_notifier_provider.dart';
import '../viewmodels/history_viewmodel.dart';
import '../models/measurement_result.dart';
import 'results_view.dart';

/// History view widget that displays measurement history.
class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the history state from Riverpod
    final historyState = ref.watch(historyNotifierProvider);
    // Get the notifier to call methods
    final notifier = ref.read(historyNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement History'),
      ),
      body: _buildBody(context, ref, historyState, notifier),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref,
      HistoryState historyState, HistoryNotifier notifier) {
    // Loading state
    if (historyState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (historyState.errorMessage != null) {
      return Center(
        child: Text(historyState.errorMessage!),
      );
    }

    // Empty state
    if (historyState.measurements.isEmpty) {
      return const Center(
        child: Text('No measurement history found'),
      );
    }

    // List view: Display measurements
    return ListView.builder(
      itemCount: historyState.measurements.length,
      itemBuilder: (context, index) {
        final measurement = historyState.measurements[index];
        return Dismissible(
          key: Key(measurement.id),
          background: _buildDismissibleBackground(),
          onDismissed: (direction) {
            notifier.deleteMeasurement(measurement.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Measurement deleted'),
                action: SnackBarAction(
                  label: 'UNDO',
                  onPressed: () {
                    notifier.undoLastDelete();
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          },
          child: _HistoryListItem(measurement: measurement),
        );
      },
    );
  }

  /// Builds the background widget for the Dismissible widget.
  /// Shows a red container with a delete icon when swiping.
  Widget _buildDismissibleBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20.0),
      child: const Icon(
        Icons.delete,
        color: Colors.white,
      ),
    );
  }
}

/// Private widget that displays a single history list item.
class _HistoryListItem extends StatelessWidget {
  final MeasurementResult measurement;

  const _HistoryListItem({required this.measurement});

  /// Formats a DateTime timestamp into "MM/DD/YYYY HH:MM" format.
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.month}/${timestamp.day}/${timestamp.year} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatTimestamp(measurement.timestamp);

    // Check if measurement has a name
    final bool hasName =
        measurement.name != null && measurement.name!.isNotEmpty;

    // Set title and subtitle based on whether name exists
    final String titleText = hasName ? measurement.name! : formattedDate;
    final String subtitleText = hasName
        ? '$formattedDate • ${measurement.bowls.length} bowls'
        : '${measurement.bowls.length} bowls measured';

    return ListTile(
      title: Text(titleText),
      subtitle: Text(subtitleText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to ResultsView (no longer needs SettingsViewModel wrapper)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultsView(measurementResult: measurement),
          ),
        );
      },
    );
  }
}
