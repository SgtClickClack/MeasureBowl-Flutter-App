/// Enum representing which team a bowl belongs to
enum BowlTeam {
  teamA,
  teamB,
  unknown,
}

/// Data model representing a single bowl measurement result
class BowlMeasurement {
  final String id;
  final String teamName;
  final BowlTeam team; // Team enum for type-safe team identification
  final double distanceFromJack; // Distance in centimeters
  final int rank; // 1st, 2nd, 3rd place etc.
  final int x; // X coordinate in pixels
  final int y; // Y coordinate in pixels

  const BowlMeasurement({
    required this.id,
    required this.teamName,
    this.team = BowlTeam.unknown,
    required this.distanceFromJack,
    required this.rank,
    required this.x,
    required this.y,
  });

  /// Create a mock bowl measurement for testing purposes
  factory BowlMeasurement.mock({
    required String id,
    required String teamName,
    BowlTeam team = BowlTeam.unknown,
    required double distance,
    required int rank,
    int x = 0,
    int y = 0,
  }) {
    return BowlMeasurement(
      id: id,
      teamName: teamName,
      team: team,
      distanceFromJack: distance,
      rank: rank,
      x: x,
      y: y,
    );
  }

  /// Create a copy of this BowlMeasurement with updated fields
  BowlMeasurement copyWith({
    String? id,
    String? teamName,
    BowlTeam? team,
    double? distanceFromJack,
    int? rank,
    int? x,
    int? y,
  }) {
    return BowlMeasurement(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      team: team ?? this.team,
      distanceFromJack: distanceFromJack ?? this.distanceFromJack,
      rank: rank ?? this.rank,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamName': teamName,
      'team': team.name,
      'distanceFromJack': distanceFromJack,
      'rank': rank,
      'x': x,
      'y': y,
    };
  }

  /// Create from JSON map
  factory BowlMeasurement.fromJson(Map<String, dynamic> json) {
    BowlTeam team = BowlTeam.unknown;
    if (json['team'] != null) {
      try {
        team = BowlTeam.values.firstWhere(
          (e) => e.name == json['team'],
          orElse: () => BowlTeam.unknown,
        );
      } catch (e) {
        // If enum parsing fails, default to unknown
        team = BowlTeam.unknown;
      }
    }
    return BowlMeasurement(
      id: json['id'] as String,
      teamName: json['teamName'] as String,
      team: team,
      distanceFromJack: (json['distanceFromJack'] as num).toDouble(),
      rank: json['rank'] as int,
      x: (json['x'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Data model representing the complete measurement results
class MeasurementResult {
  final String id;
  final DateTime timestamp;
  final String? imagePath; // Path to captured image
  final List<BowlMeasurement> bowls;
  final bool usingHighAccuracy; // Whether high-accuracy metrology was used
  final String?
      accuracyMessage; // Message about accuracy (e.g., "Results are an estimate...")
  final String? name; // Optional name for the measurement (e.g., "End 1")
  final int?
      originalImageWidth; // Original image width in pixels for coordinate scaling
  final int?
      originalImageHeight; // Original image height in pixels for coordinate scaling

  const MeasurementResult({
    required this.id,
    required this.timestamp,
    this.imagePath,
    required this.bowls,
    this.usingHighAccuracy = false,
    this.accuracyMessage,
    this.name,
    this.originalImageWidth,
    this.originalImageHeight,
  });

  /// Create measurement results with captured image
  factory MeasurementResult.fromCapturedImage({
    required String imagePath,
    List<BowlMeasurement>? bowls,
  }) {
    return MeasurementResult(
      id: 'measurement_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      imagePath: imagePath,
      bowls: bowls ??
          [
            // Mock bowls for now - will be replaced with actual CV processing
            BowlMeasurement.mock(
              id: 'bowl_1',
              teamName: 'Team A',
              distance: 5.2,
              rank: 1,
              x: 0,
              y: 0,
            ),
            BowlMeasurement.mock(
              id: 'bowl_2',
              teamName: 'Team B',
              distance: 8.7,
              rank: 2,
              x: 0,
              y: 0,
            ),
            BowlMeasurement.mock(
              id: 'bowl_3',
              teamName: 'Team A',
              distance: 12.1,
              rank: 3,
              x: 0,
              y: 0,
            ),
          ],
    );
  }

  /// Create mock measurement results for testing purposes
  factory MeasurementResult.createMock() {
    return MeasurementResult(
      id: 'mock_measurement_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      imagePath: null, // Will use placeholder asset
      bowls: [
        BowlMeasurement.mock(
          id: 'bowl_1',
          teamName: 'Team A',
          distance: 5.2,
          rank: 1,
          x: 0,
          y: 0,
        ),
        BowlMeasurement.mock(
          id: 'bowl_2',
          teamName: 'Team B',
          distance: 8.7,
          rank: 2,
          x: 0,
          y: 0,
        ),
        BowlMeasurement.mock(
          id: 'bowl_3',
          teamName: 'Team A',
          distance: 12.1,
          rank: 3,
          x: 0,
          y: 0,
        ),
      ],
    );
  }

  /// Get the closest bowl (rank 1)
  BowlMeasurement? get closestBowl {
    if (bowls.isEmpty) return null;
    return bowls.firstWhere((bowl) => bowl.rank == 1);
  }

  /// Create a copy of this MeasurementResult with updated fields
  MeasurementResult copyWith({
    String? id,
    DateTime? timestamp,
    String? imagePath,
    List<BowlMeasurement>? bowls,
    bool? usingHighAccuracy,
    String? accuracyMessage,
    String? name,
    int? originalImageWidth,
    int? originalImageHeight,
  }) {
    return MeasurementResult(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      bowls: bowls ?? this.bowls,
      usingHighAccuracy: usingHighAccuracy ?? this.usingHighAccuracy,
      accuracyMessage: accuracyMessage ?? this.accuracyMessage,
      name: name ?? this.name,
      originalImageWidth: originalImageWidth ?? this.originalImageWidth,
      originalImageHeight: originalImageHeight ?? this.originalImageHeight,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'bowls': bowls.map((bowl) => bowl.toJson()).toList(),
      'usingHighAccuracy': usingHighAccuracy,
      'accuracyMessage': accuracyMessage,
      'name': name,
      'originalImageWidth': originalImageWidth,
      'originalImageHeight': originalImageHeight,
    };
  }

  /// Create from JSON map
  factory MeasurementResult.fromJson(Map<String, dynamic> json) {
    return MeasurementResult(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imagePath: json['imagePath'] as String?,
      bowls: (json['bowls'] as List<dynamic>)
          .map((bowlJson) => BowlMeasurement.fromJson(
                bowlJson as Map<String, dynamic>,
              ))
          .toList(),
      usingHighAccuracy: json['usingHighAccuracy'] as bool? ?? false,
      accuracyMessage: json['accuracyMessage'] as String?,
      name: json['name'] as String?,
      originalImageWidth: json['originalImageWidth'] as int?,
      originalImageHeight: json['originalImageHeight'] as int?,
    );
  }
}
