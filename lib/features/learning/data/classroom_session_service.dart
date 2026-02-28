import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';
import 'package:verasso/core/services/offline_storage_service.dart';
import 'package:verasso/core/services/supabase_service.dart';
import 'package:verasso/features/learning/data/course_models.dart';

import '../../../core/mesh/models/mesh_packet.dart';

/// Provides a scoped [ClassroomSessionService] that is disposed with the UI.
final classroomSessionServiceProvider =
    Provider.autoDispose<ClassroomSessionService>((ref) {
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  final storage = ref.watch(offlineStorageServiceProvider);
  final client = SupabaseService.client;
  final service = ClassroomSessionService(mesh, storage, client: client);
  ref.onDispose(() => service.dispose());
  return service;
});

// Models

/// Represents a single mesh-based classroom session.
class ClassroomSession {
  /// Unique identifier of the session.
  final String id;

  /// The ID of the user hosting the session.
  final String hostId;

  /// The subject of the session (e.g., 'Physics').
  final String subject;

  /// The specific topic being discussed.
  final String topic;

  /// The date and time when the session was created.
  final DateTime createdAt;

  /// Creates a new [ClassroomSession] descriptor.
  ClassroomSession({
    required this.id,
    required this.hostId,
    required this.subject,
    required this.topic,
    required this.createdAt,
  });

  /// Builds a [ClassroomSession] from a serialized [map].
  factory ClassroomSession.fromMap(Map<String, dynamic> map) =>
      ClassroomSession(
        id: map['id'],
        hostId: map['hostId'],
        subject: map['subject'],
        topic: map['topic'],
        createdAt: DateTime.parse(map['createdAt']),
      );

  /// Serializes this session into a JSON-compatible map.
  Map<String, dynamic> toMap() => {
        'id': id,
        'hostId': hostId,
        'subject': subject,
        'topic': topic,
        'createdAt': createdAt.toIso8601String(),
      };
}

// Service

/// Mesh-backed service for coordinating live classroom sessions, polls and doubts.
class ClassroomSessionService {
  final BluetoothMeshService _meshService;
  final OfflineStorageService _storageService;
  final SupabaseClient _client;

  // State
  ClassroomSession? _currentSession;
  bool _isHost = false;
  final List<String> _participants = []; // Names
  SessionPoll? _activePoll;
  final List<SessionDoubt> _doubts = [];

  // Streams
  final _sessionController = StreamController<ClassroomSession?>.broadcast();
  final _pollController = StreamController<SessionPoll?>.broadcast();

  final _doubtsController = StreamController<List<SessionDoubt>>.broadcast();
  final _participantsController = StreamController<List<String>>.broadcast();

  /// Creates a [ClassroomSessionService] and subscribes to mesh packets.
  ClassroomSessionService(this._meshService, this._storageService,
      {required SupabaseClient client})
      : _client = client {
    _initListener();
  }

  /// Stream of all doubts raised in the current session.
  Stream<List<SessionDoubt>> get doubtsStream => _doubtsController.stream;

  /// Stream of participant display names currently in the session.
  Stream<List<String>> get participantsStream => _participantsController.stream;

  /// Stream of the active poll, if any.
  Stream<SessionPoll?> get pollStream => _pollController.stream;

  /// Stream of the active [ClassroomSession], or `null` when idle.
  Stream<ClassroomSession?> get sessionStream => _sessionController.stream;

  /// Cleans up all internal stream controllers.
  void dispose() {
    _sessionController.close();
    _pollController.close();
    _doubtsController.close();
    _participantsController.close();
  }

  // --- Student Actions ---

  /// Fetches all available practical labs from the cloud.
  Future<List<Course>> fetchAvailableLabs() async {
    try {
      final response = await _client
          .from('courses')
          .select('*, profiles:creator_id(full_name)')
          .eq('is_lab', true)
          .eq('is_published', true)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Course.fromJson(json)).toList();
    } catch (e) {
      AppLogger.info('Fetch labs error: $e');
      return [];
    }
  }

  /// Fetches active or past classroom sessions from the cloud.
  Future<List<ClassroomSession>> fetchClassroomSessions() async {
    try {
      final response = await _client
          .from('classroom_sessions')
          .select()
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => ClassroomSession(
                id: json['id'],
                hostId: json['host_id'],
                subject: json['subject'],
                topic: json['topic'],
                createdAt: DateTime.parse(json['created_at']),
              ))
          .toList();
    } catch (e) {
      AppLogger.info('Fetch sessions error: $e');
      return [];
    }
  }

  /// Requests to join the current session as a student with [userName].
  ///
  /// Broadcasts a join request to the mesh network.
  Future<void> joinSessionRequest(String userName) async {
    if (_currentSession == null) return;

    await _meshService.broadcastPacket(MeshPayloadType.joinSession, {
      'sessionId': _currentSession!.id,
      'userName': userName,
    });
  }

  // --- Host Actions ---

  /// Publishes a new poll with [question] and [options] to all participants.
  ///
  /// Only has an effect when this instance is the host.
  Future<void> publishPoll(String question, List<String> options) async {
    if (!_isHost || _currentSession == null) return;

    final pollId = const Uuid().v4();
    final pollData = {
      'id': pollId,
      'sessionId': _currentSession!.id,
      'question': question,
      'options': options,
    };

    _activePoll = SessionPoll(id: pollId, question: question, options: options);
    _pollController.add(_activePoll);

    await _meshService.broadcastPacket(MeshPayloadType.pollPublish, pollData);
    await _storageService.queueAction('publish_poll', pollData);
  }

  /// Raises a [question] on behalf of the given [userId] and [userName].
  Future<void> raiseDoubt(
      String userId, String userName, String question) async {
    if (_currentSession == null) return;

    final doubt = SessionDoubt(
      id: const Uuid().v4(),
      userId: userId,
      userName: userName,
      question: question,
    );

    // Add locally immediately
    _doubts.add(doubt);
    _doubtsController.add(_doubts);

    await _meshService.broadcastPacket(MeshPayloadType.doubtRaise, {
      'id': doubt.id,
      'sessionId': _currentSession!.id,
      'userId': userId,
      'userName': userName,
      'question': question,
    });

    // Queue for cloud
    await _storageService.queueAction('raise_doubt', {
      'sessionId': _currentSession!.id,
      'question': question,
    });
  }

  /// Starts a new classroom session as host for the given [subject] and [topic].
  Future<void> startSession(String hostId, String subject, String topic) async {
    final session = ClassroomSession(
      id: const Uuid().v4(),
      hostId: hostId,
      subject: subject,
      topic: topic,
      createdAt: DateTime.now(),
    );

    _currentSession = session;
    _isHost = true;
    _participants.clear();
    _doubts.clear();
    _activePoll = null;

    _updateStreams();

    // Broadcast to Mesh
    await _meshService.broadcastPacket(
        MeshPayloadType.startSession, session.toMap());

    // Save to Offline Queue for Cloud Sync
    await _storageService.queueAction('start_session', session.toMap());

    // Sync to Supabase directly if online
    await _syncSessionStart(session);
  }

  /// Starts mesh discovery so nearby students can discover this session.
  Future<void> startStudentDiscovery() async {
    await _meshService.startDiscovery();
  }

  /// Stops the current session, shuts down mesh communication, and clears internal state.
  Future<void> stopSession() async {
    _meshService.stopAll();
    _currentSession = null;
    _activePoll = null;
    _doubts.clear();
    _participants.clear();
    _updateStreams();
  }

  /// Casts a vote for [optionIndex] in the poll [pollId] on behalf of [userId].
  Future<void> votePoll(String pollId, int optionIndex, String userId) async {
    if (_activePoll == null || _activePoll!.id != pollId) return;

    await _meshService.broadcastPacket(MeshPayloadType.pollVote, {
      'pollId': pollId,
      'optionIndex': optionIndex,
      'userId': userId,
    });

    // Optimistic update locally? No, wait for updates if needed,
    // but for now student app just sends.
  }

  // --- Packet Handling ---

  void _handlePacket(MeshPacket packet) {
    final data = packet.payload;

    switch (packet.type) {
      case MeshPayloadType.startSession:
        // Student sees a session started
        if (!_isHost) {
          _currentSession = ClassroomSession.fromMap(data);
          _sessionController.add(_currentSession);
          // Auto-join? Or wait for UI? Let's assume UI prompts or auto-joins for this MVP
        }
        break;

      case MeshPayloadType.joinSession:
        if (_isHost && data['sessionId'] == _currentSession?.id) {
          final name = data['userName'];
          if (!_participants.contains(name)) {
            _participants.add(name);
            _participantsController.add(_participants);
          }
        }
        break;

      case MeshPayloadType.pollPublish:
        if (!_isHost && data['sessionId'] == _currentSession?.id) {
          _activePoll = SessionPoll(
            id: data['id'],
            question: data['question'],
            options: List<String>.from(data['options']),
          );
          _pollController.add(_activePoll);
        }
        break;

      case MeshPayloadType.pollVote:
        if (_isHost &&
            _activePoll != null &&
            data['pollId'] == _activePoll!.id) {
          final optIndex = data['optionIndex'] as int;
          // Naive aggregation in MVP (Host aggregates)
          final currentVotes = Map<String, int>.from(_activePoll!.votes);
          final key = optIndex.toString();
          currentVotes[key] = (currentVotes[key] ?? 0) + 1;

          _activePoll = SessionPoll(
            id: _activePoll!.id,
            question: _activePoll!.question,
            options: _activePoll!.options,
            votes: currentVotes,
          );
          _pollController.add(_activePoll);
        }
        break;

      case MeshPayloadType.doubtRaise:
        if (data['sessionId'] == _currentSession?.id) {
          final doubt = SessionDoubt(
            id: data['id'],
            userId: data['userId'],
            userName: data['userName'],
            question: data['question'],
          );
          // Avoid duplicates
          if (!_doubts.any((d) => d.id == doubt.id)) {
            _doubts.add(doubt);
            _doubtsController.add(_doubts);
          }
        }
        break;

      default:
        break;
    }
  }

  // --- Supabase Integration ---

  void _initListener() {
    _meshService.meshStream.listen((packet) {
      _handlePacket(packet);
    });
  }

  /// Syncs a session start to the cloud.
  Future<void> _syncSessionStart(ClassroomSession session) async {
    try {
      await _client.from('classroom_sessions').insert({
        'id': session.id,
        'host_id': session.hostId,
        'subject': session.subject,
        'topic': session.topic,
        'is_live': true,
      });
    } catch (e) {
      AppLogger.info('Sync session start error: $e');
    }
  }

  void _updateStreams() {
    _sessionController.add(_currentSession);
    _pollController.add(_activePoll);
    _doubtsController.add(_doubts);
    _participantsController.add(_participants);
  }
}

/// Lightweight model representing a single raised doubt/question.
class SessionDoubt {
  /// Unique identifier of the doubt.
  final String id;

  /// The ID of the user who raised the doubt.
  final String userId;

  /// The display name of the user who raised the doubt.
  final String userName;

  /// The content of the question/doubt.
  final String question;

  /// The number of upvotes this doubt has received.
  final int upvotes;

  /// Creates a [SessionDoubt] with the provided metadata.
  SessionDoubt({
    required this.id,
    required this.userId,
    required this.userName,
    required this.question,
    this.upvotes = 0,
  });
}

/// Represents an interactive poll within a classroom session.
class SessionPoll {
  /// Unique identifier of the poll.
  final String id;

  /// The question being asked in the poll.
  final String question;

  /// List of multiple-choice options for the poll.
  final List<String> options;

  /// Mapping of option index to the number of votes received.
  final Map<String, int> votes; // Option Index -> Count

  /// Whether the poll is currently open for voting.
  final bool isOpen;

  /// Creates a new [SessionPoll] with optional [votes] and [isOpen] state.
  SessionPoll({
    required this.id,
    required this.question,
    required this.options,
    this.votes = const {},
    this.isOpen = true,
  });
}
