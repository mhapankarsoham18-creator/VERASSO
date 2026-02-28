/// Model representing the outcome of a science simulation.
class SimulationResult {
  /// Unique identifier for the result.
  final String id;

  /// User who performed the simulation.
  final String userId;

  /// Identifier for the simulation module.
  final String simId;

  /// Category of the simulation (e.g., Physics, Chemistry).
  final String category;

  /// Input parameters used in the simulation.
  final Map<String, dynamic> parameters;

  /// Calculated results from the simulation.
  final Map<String, dynamic> results;

  /// Timestamp when the simulation was completed.
  final DateTime createdAt;

  /// Creates a [SimulationResult] instance.
  const SimulationResult({
    required this.id,
    required this.userId,
    required this.simId,
    required this.category,
    required this.parameters,
    required this.results,
    required this.createdAt,
  });

  /// Creates a [SimulationResult] from a JSON map.
  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    return SimulationResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      simId: json['simId'] as String,
      category: json['category'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      results: json['results'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converts the [SimulationResult] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'simId': simId,
      'category': category,
      'parameters': parameters,
      'results': results,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
