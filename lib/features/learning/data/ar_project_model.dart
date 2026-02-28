/// Represents a circuit component in the AR workspace
class ArComponent {
  /// Unique identifier of the component instance.
  final String id;

  /// Reference to the library item ID.
  final String componentLibraryId;

  /// Human-readable name of the component.
  final String name;

  /// Category (e.g., 'Power', 'Logic').
  final String category;

  /// 3D transform properties.
  final Transform3D transform;

  /// Custom property values for this component.
  final Map<String, dynamic> properties;

  /// IDs of components connected to this one.
  final List<String> connectedTo; // IDs of connected components

  /// Creates an [ArComponent] instance.
  const ArComponent({
    required this.id,
    required this.componentLibraryId,
    required this.name,
    required this.category,
    required this.transform,
    this.properties = const {},
    this.connectedTo = const [],
  });

  /// Creates an [ArComponent] from a JSON-compatible map.
  factory ArComponent.fromJson(Map<String, dynamic> json) => ArComponent(
        id: json['id'] as String,
        componentLibraryId: json['componentLibraryId'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        transform:
            Transform3D.fromJson(json['transform'] as Map<String, dynamic>),
        properties: (json['properties'] as Map<String, dynamic>?) ?? {},
        connectedTo: (json['connectedTo'] as List?)?.cast<String>() ?? [],
      );

  /// Creates a copy of this [ArComponent] with optional field overrides.
  ArComponent copyWith({
    String? id,
    String? componentLibraryId,
    String? name,
    String? category,
    Transform3D? transform,
    Map<String, dynamic>? properties,
    List<String>? connectedTo,
  }) =>
      ArComponent(
        id: id ?? this.id,
        componentLibraryId: componentLibraryId ?? this.componentLibraryId,
        name: name ?? this.name,
        category: category ?? this.category,
        transform: transform ?? this.transform,
        properties: properties ?? this.properties,
        connectedTo: connectedTo ?? this.connectedTo,
      );

  /// Converts this [ArComponent] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'componentLibraryId': componentLibraryId,
        'name': name,
        'category': category,
        'transform': transform.toJson(),
        'properties': properties,
        'connectedTo': connectedTo,
      };
}

/// Main AR project model
class ArProject {
  /// Unique identifier of the project.
  final String id;

  /// ID of the user who owns the project.
  final String userId;

  /// Title of the project.
  final String title;

  /// Optional description of the project.
  final String description;

  /// Optional URL to a thumbnail image of the project.
  final String? thumbnailUrl;

  /// List of components in the project.
  final List<ArComponent> components;

  /// List of connections between components.
  final List<ComponentConnection> connections;

  /// Results of the last simulation run.
  final SimulationResult? lastSimulation;

  /// Whether the project is visible to others.
  final bool isPublic;

  /// Whether the project is shared with friend list.
  final bool sharedWithFriends;

  /// When the project was first created.
  final DateTime createdAt;

  /// When the project was last updated.
  final DateTime updatedAt;

  /// Creates an [ArProject] instance.
  const ArProject({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.thumbnailUrl,
    this.components = const [],
    this.connections = const [],
    this.lastSimulation,
    this.isPublic = false,
    this.sharedWithFriends = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an [ArProject] from a JSON-compatible map.
  factory ArProject.fromJson(Map<String, dynamic> json) {
    final projectData = json['project_data'] as Map<String, dynamic>? ?? {};
    final simulationState = json['simulation_state'] as Map<String, dynamic>?;

    return ArProject(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      components: (projectData['components'] as List?)
              ?.map((c) => ArComponent.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      connections: (projectData['connections'] as List?)
              ?.map((c) =>
                  ComponentConnection.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      lastSimulation: simulationState != null
          ? SimulationResult.fromJson(simulationState)
          : null,
      isPublic: json['is_public'] as bool? ?? false,
      sharedWithFriends: json['shared_with_friends'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Creates a copy of this [ArProject] with optional field overrides.
  ArProject copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? thumbnailUrl,
    List<ArComponent>? components,
    List<ComponentConnection>? connections,
    SimulationResult? lastSimulation,
    bool? isPublic,
    bool? sharedWithFriends,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ArProject(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        description: description ?? this.description,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        components: components ?? this.components,
        connections: connections ?? this.connections,
        lastSimulation: lastSimulation ?? this.lastSimulation,
        isPublic: isPublic ?? this.isPublic,
        sharedWithFriends: sharedWithFriends ?? this.sharedWithFriends,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Converts this [ArProject] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'thumbnail_url': thumbnailUrl,
        'project_data': {
          'components': components.map((c) => c.toJson()).toList(),
          'connections': connections.map((c) => c.toJson()).toList(),
        },
        'simulation_state': lastSimulation?.toJson(),
        'is_public': isPublic,
        'shared_with_friends': sharedWithFriends,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

/// Represents a connection between two components
/// Represents a electrical or mechanical connection between two components.
class ComponentConnection {
  /// ID of the component where the connection starts.
  final String fromComponentId;

  /// ID of the component where the connection ends.
  final String toComponentId;

  /// The name of the terminal on the starting component (e.g., 'positive').
  final String fromTerminal;

  /// The name of the terminal on the ending component (e.g., 'negative').
  final String toTerminal;

  /// Creates a [ComponentConnection].
  const ComponentConnection({
    required this.fromComponentId,
    required this.toComponentId,
    this.fromTerminal = 'default',
    this.toTerminal = 'default',
  });

  /// Creates a [ComponentConnection] from a JSON-compatible map.
  factory ComponentConnection.fromJson(Map<String, dynamic> json) =>
      ComponentConnection(
        fromComponentId: json['fromComponentId'] as String,
        toComponentId: json['toComponentId'] as String,
        fromTerminal: json['fromTerminal'] as String? ?? 'default',
        toTerminal: json['toTerminal'] as String? ?? 'default',
      );

  /// Converts this [ComponentConnection] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'fromComponentId': fromComponentId,
        'toComponentId': toComponentId,
        'fromTerminal': fromTerminal,
        'toTerminal': toTerminal,
      };
}

/// Component library item model
/// Represents an item in the AR component library.
class ComponentLibraryItem {
  /// Unique identifier of the library item.
  final String id;

  /// Display name of the item.
  final String name;

  /// Category label (e.g., 'Sensor', 'Actuator').
  final String category;

  /// URL to the 3D model asset.
  final String? modelUrl;

  /// URL to the icon image for the library UI.
  final String? iconUrl;

  /// Default properties for instances of this component.
  final Map<String, dynamic> properties;

  /// Rules and parameters used by the simulation engine for this item.
  final Map<String, dynamic> simulationRules;

  /// Whether the item is currently available for use.
  final bool isActive;

  /// Creates a [ComponentLibraryItem].
  const ComponentLibraryItem({
    required this.id,
    required this.name,
    required this.category,
    this.modelUrl,
    this.iconUrl,
    this.properties = const {},
    this.simulationRules = const {},
    this.isActive = true,
  });

  /// Creates a [ComponentLibraryItem] from a JSON-compatible map.
  factory ComponentLibraryItem.fromJson(Map<String, dynamic> json) =>
      ComponentLibraryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        modelUrl: json['model_url'] as String?,
        iconUrl: json['icon_url'] as String?,
        properties: (json['properties'] as Map<String, dynamic>?) ?? {},
        simulationRules:
            (json['simulation_rules'] as Map<String, dynamic>?) ?? {},
        isActive: json['is_active'] as bool? ?? true,
      );

  /// Converts this [ComponentLibraryItem] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'model_url': modelUrl,
        'icon_url': iconUrl,
        'properties': properties,
        'simulation_rules': simulationRules,
        'is_active': isActive,
      };
}

/// Shared project model (for viewing shared projects)
/// Represents a project that has been shared with other users.
class SharedArProject {
  /// The underlying [ArProject] record.
  final ArProject project;

  /// The ID of the user who shared the project.
  final String sharedBy;

  /// The username of the user who shared the project.
  final String sharedByUsername;

  /// The timestamp when the project was shared.
  final DateTime sharedAt;

  /// Whether the recipient has permission to edit the original project.
  final bool canEdit;

  /// Whether the recipient can create a copy (remix) of the project.
  final bool canRemix;

  /// Creates a [SharedArProject].
  const SharedArProject({
    required this.project,
    required this.sharedBy,
    required this.sharedByUsername,
    required this.sharedAt,
    this.canEdit = false,
    this.canRemix = true,
  });

  /// Creates a [SharedArProject] from a JSON-compatible map.
  factory SharedArProject.fromJson(Map<String, dynamic> json) {
    // Reconstruct project from shared data
    final project = ArProject.fromJson({
      'id': json['id'],
      'user_id': json['creator_id'],
      'title': json['title'],
      'description': json['description'],
      'thumbnail_url': json['thumbnail_url'],
      'project_data': {},
      'simulation_state': null,
      'is_public': false,
      'shared_with_friends': false,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    return SharedArProject(
      project: project,
      sharedBy: json['creator_id'] as String,
      sharedByUsername: json['creator_name'] as String? ?? 'Unknown',
      sharedAt: DateTime.parse(json['shared_at'] as String),
      canEdit: json['can_edit'] as bool? ?? false,
      canRemix: json['can_remix'] as bool? ?? true,
    );
  }
}

/// Simulation result for a component or circuit
/// Results and state data from a circuit or component simulation.
class SimulationResult {
  /// Whether the circuit or component is in a valid state for simulation.
  final bool isValid;

  /// Map of component IDs to their calculated voltages.
  final Map<String, double> voltages; // Component ID -> voltage

  /// Map of component IDs to their calculated currents.
  final Map<String, double> currents; // Component ID -> current

  /// List of error messages generated during simulation.
  final List<String> errors;

  /// List of warning messages generated during simulation.
  final List<String> warnings;

  /// Visual state of components (e.g., 'on', 'off', color).
  final Map<String, dynamic> componentStates; // LED on/off, etc.

  /// Creates a [SimulationResult].
  const SimulationResult({
    this.isValid = false,
    this.voltages = const {},
    this.currents = const {},
    this.errors = const [],
    this.warnings = const [],
    this.componentStates = const {},
  });

  /// Creates a [SimulationResult] from a JSON-compatible map.
  factory SimulationResult.fromJson(Map<String, dynamic> json) =>
      SimulationResult(
        isValid: json['isValid'] as bool? ?? false,
        voltages: (json['voltages'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
        currents: (json['currents'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
        errors: (json['errors'] as List?)?.cast<String>() ?? [],
        warnings: (json['warnings'] as List?)?.cast<String>() ?? [],
        componentStates:
            (json['componentStates'] as Map<String, dynamic>?) ?? {},
      );

  /// Converts this [SimulationResult] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'voltages': voltages,
        'currents': currents,
        'errors': errors,
        'warnings': warnings,
        'componentStates': componentStates,
      };
}

/// Represents a 3D position and orientation in AR space
/// Represents 3D transform properties (position, rotation, scale).
class Transform3D {
  /// The X coordinate.
  final double x;

  /// The Y coordinate.
  final double y;

  /// The Z coordinate.
  final double z;

  /// Rotation around the X axis in degrees.
  final double rotationX;

  /// Rotation around the Y axis in degrees.
  final double rotationY;

  /// Rotation around the Z axis in degrees.
  final double rotationZ;

  /// Scale multiplier (default 1.0).
  final double scale;

  /// Creates a [Transform3D].
  const Transform3D({
    this.x = 0.0,
    this.y = 0.0,
    this.z = 0.0,
    this.rotationX = 0.0,
    this.rotationY = 0.0,
    this.rotationZ = 0.0,
    this.scale = 1.0,
  });

  /// Creates a [Transform3D] from a JSON-compatible map.
  factory Transform3D.fromJson(Map<String, dynamic> json) => Transform3D(
        x: (json['x'] as num?)?.toDouble() ?? 0.0,
        y: (json['y'] as num?)?.toDouble() ?? 0.0,
        z: (json['z'] as num?)?.toDouble() ?? 0.0,
        rotationX: (json['rotationX'] as num?)?.toDouble() ?? 0.0,
        rotationY: (json['rotationY'] as num?)?.toDouble() ?? 0.0,
        rotationZ: (json['rotationZ'] as num?)?.toDouble() ?? 0.0,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      );

  /// Creates a copy of this [Transform3D] with optional field overrides.
  Transform3D copyWith({
    double? x,
    double? y,
    double? z,
    double? rotationX,
    double? rotationY,
    double? rotationZ,
    double? scale,
  }) =>
      Transform3D(
        x: x ?? this.x,
        y: y ?? this.y,
        z: z ?? this.z,
        rotationX: rotationX ?? this.rotationX,
        rotationY: rotationY ?? this.rotationY,
        rotationZ: rotationZ ?? this.rotationZ,
        scale: scale ?? this.scale,
      );

  /// Converts this [Transform3D] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'rotationX': rotationX,
        'rotationY': rotationY,
        'rotationZ': rotationZ,
        'scale': scale,
      };
}
