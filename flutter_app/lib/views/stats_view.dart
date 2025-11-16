import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/stats_viewmodel.dart';

/// Performance Dashboard view widget that displays statistics and analytics.
class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  @override
  void initState() {
    super.initState();
    // Load statistics when the view is initialized
    // Use addPostFrameCallback to ensure context is fully available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<StatsViewModel>(context, listen: false);
      viewModel.loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Dashboard'),
      ),
      body: Consumer<StatsViewModel>(
        builder: (context, viewModel, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Bowls Measured: ${viewModel.totalBowls}'),
                Text(
                    'Overall Average: ${viewModel.averageDistanceCm.toStringAsFixed(1)} cm'),
                Text(
                    'Consistency Avg: ${viewModel.averageBestBowlDistanceCm.toStringAsFixed(1)} cm'),
                Text(
                    'Personal Best: ${viewModel.bestBowlDistanceCm.toStringAsFixed(1)} cm'),
              ],
            ),
          );
        },
      ),
    );
  }
}
