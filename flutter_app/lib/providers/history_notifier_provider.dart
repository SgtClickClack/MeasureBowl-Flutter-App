import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/history_viewmodel.dart';
import 'service_providers.dart';

/// Provider for HistoryNotifier that manages measurement history state
final historyNotifierProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  // Get the MeasurementHistoryService from the service provider
  final historyService = ref.watch(historyServiceProvider);

  // Create the notifier with the service
  final notifier = HistoryNotifier(historyService);

  // Initialize asynchronously to load measurements from storage
  // This will update the state once measurements are loaded
  notifier.initialize();

  return notifier;
});
