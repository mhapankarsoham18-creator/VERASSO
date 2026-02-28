/// Represents a collaborative engineering or science project.
class Project {
  /// Unique identifier of the project.
  final String id;

  /// The ID of the student leading the project.
  final String leaderId;

  /// The title of the project.
  final String title;

  /// Detailed description of the project's goals and scope.
  final String description;

  /// The current status of the project (e.g., 'In Progress', 'Shipped').
  final String status;

  /// Optional link to the project's GitHub repository.
  final String? githubUrl;

  /// Optional link to a live demo of the project.
  final String? demoUrl;

  /// The date and time when the project was created.
  final DateTime createdAt;

  // Joined Leader info
  /// The display name of the leader (optional, populated via joins).
  final String? leaderName;

  /// The avatar URL of the leader (optional, populated via joins).
  final String? leaderAvatar;

  /// Creates a [Project] instance.
  Project({
    required this.id,
    required this.leaderId,
    required this.title,
    required this.description,
    required this.status,
    this.githubUrl,
    this.demoUrl,
    required this.createdAt,
    this.leaderName,
    this.leaderAvatar,
  });

  /// Creates a [Project] from a JSON-compatible map.
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      leaderId: json['leader_id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      githubUrl: json['github_url'],
      demoUrl: json['demo_url'],
      createdAt: DateTime.parse(json['created_at']),
      leaderName:
          json['profiles'] != null ? json['profiles']['full_name'] : null,
      leaderAvatar:
          json['profiles'] != null ? json['profiles']['avatar_url'] : null,
    );
  }
}

/// Represents a member of a collaborative project.
class ProjectMember {
  /// The ID of the project the user belongs to.
  final String projectId;

  /// The ID of the student user.
  final String userId;

  /// The role of the user within the project (e.g., 'Developer', 'Designer').
  final String role;

  // Joined User info
  /// The display name of the user (optional, populated via joins).
  final String? userName;

  /// The avatar URL of the user (optional, populated via joins).
  final String? userAvatar;

  /// Creates a [ProjectMember] instance.
  ProjectMember({
    required this.projectId,
    required this.userId,
    required this.role,
    this.userName,
    this.userAvatar,
  });

  /// Creates a [ProjectMember] from a JSON-compatible map.
  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      projectId: json['project_id'],
      userId: json['user_id'],
      role: json['role'],
      userName: json['profiles'] != null ? json['profiles']['full_name'] : null,
      userAvatar:
          json['profiles'] != null ? json['profiles']['avatar_url'] : null,
    );
  }
}

/// Represents a task within a collaborative project.
class ProjectTask {
  /// Unique identifier of the task.
  final String id;

  /// The ID of the project this task belongs to.
  final String projectId;

  /// The ID of the user assigned to this task (optional).
  final String? assignedTo;

  /// The title or summary of the task.
  final String title;

  /// The current status of the task (e.g., 'Todo', 'Done').
  final String status;

  // Joined Assignee Info
  /// The display name of the assignee (optional, populated via joins).
  final String? assigneeName;

  /// The avatar URL of the assignee (optional, populated via joins).
  final String? assigneeAvatar;

  /// Creates a [ProjectTask] instance.
  ProjectTask({
    required this.id,
    required this.projectId,
    this.assignedTo,
    required this.title,
    required this.status,
    this.assigneeName,
    this.assigneeAvatar,
  });

  /// Creates a [ProjectTask] from a JSON-compatible map.
  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    return ProjectTask(
      id: json['id'],
      projectId: json['project_id'],
      assignedTo: json['assigned_to'],
      title: json['title'],
      status: json['status'],
      assigneeName:
          json['profiles'] != null ? json['profiles']['full_name'] : null,
      assigneeAvatar:
          json['profiles'] != null ? json['profiles']['avatar_url'] : null,
    );
  }
}
