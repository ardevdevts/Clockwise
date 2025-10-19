import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../auth_service.dart';
import 'sync_models.dart';
import '../../../database/crud.dart';

enum SyncStatus { idle, connecting, syncing, success, error, disconnected }

class SyncService {
  static const String _baseUrl =
      'ws://localhost:3000'; // Change to your server URL
  static const String _lastSyncKey = 'last_sync_at';

  final AuthService _authService;
  final AppDatabase _database;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  StreamSubscription? _connectivitySubscription;

  final _statusController = StreamController<SyncStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  SyncStatus _currentStatus = SyncStatus.idle;
  String? _lastSyncAt;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  // Singleton pattern
  static SyncService? _instance;
  factory SyncService({
    required AuthService authService,
    required AppDatabase database,
  }) {
    _instance ??= SyncService._internal(authService, database);
    return _instance!;
  }

  SyncService._internal(this._authService, this._database);

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus get currentStatus => _currentStatus;
  String? get lastSyncAt => _lastSyncAt;

  /// Initialize the sync service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSyncAt = prefs.getString(_lastSyncKey);

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      if (result != ConnectivityResult.none && _authService.isAuthenticated) {
        _attemptReconnect();
      }
    });
  }

  /// Connect to sync websocket
  Future<bool> connect() async {
    if (!_authService.isAuthenticated) {
      _updateStatus(SyncStatus.error);
      _errorController.add('Not authenticated');
      return false;
    }

    if (_channel != null) {
      return true; // Already connected
    }

    try {
      _updateStatus(SyncStatus.connecting);

      final uri = Uri.parse('$_baseUrl/sync');

      // Create websocket with authentication cookie
      _channel = WebSocketChannel.connect(uri, protocols: ['websocket']);

      // Wait for connection to be established
      await _channel!.ready;

      // Listen to messages
      _channelSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _reconnectAttempts = 0;
      _updateStatus(SyncStatus.idle);

      debugPrint('Sync WebSocket connected');
      return true;
    } catch (e) {
      debugPrint('Sync connection error: $e');
      _updateStatus(SyncStatus.error);
      _errorController.add('Connection failed: $e');
      _scheduleReconnect();
      return false;
    }
  }

  /// Disconnect from sync websocket
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _channelSubscription?.cancel();
    _channelSubscription = null;

    await _channel?.sink.close();
    _channel = null;

    _updateStatus(SyncStatus.disconnected);
    debugPrint('Sync WebSocket disconnected');
  }

  /// Perform a full sync
  Future<bool> sync({bool fullSync = false}) async {
    if (!_authService.isAuthenticated) {
      _errorController.add('Not authenticated');
      return false;
    }

    // Ensure connection
    if (_channel == null) {
      final connected = await connect();
      if (!connected) return false;
    }

    try {
      _updateStatus(SyncStatus.syncing);

      // Get changes since last sync
      final changes = await _getLocalChanges(fullSync ? null : _lastSyncAt);

      // Create sync request
      final request = SyncRequest(
        lastSyncAt: fullSync ? '' : (_lastSyncAt ?? ''),
        changes: changes,
      );

      // Send sync request
      final requestJson = jsonEncode(request.toJson());
      debugPrint('Sending sync request: ${changes.toJson().keys}');
      _channel!.sink.add(requestJson);

      return true;
    } catch (e) {
      debugPrint('Sync error: $e');
      _updateStatus(SyncStatus.error);
      _errorController.add('Sync failed: $e');
      return false;
    }
  }

  /// Get local changes since last sync
  Future<SyncChanges> _getLocalChanges(String? since) async {
    final DateTime? sinceDate = since != null && since.isNotEmpty
        ? DateTime.tryParse(since)
        : null;

    // Get all changes or only changes since last sync
    final projects = sinceDate != null
        ? await _database.getProjectsChangedSince(sinceDate)
        : await _database.allProjects;

    final todos = sinceDate != null
        ? await _database.getTodosChangedSince(sinceDate)
        : await _database.allTodoItems;

    final habits = sinceDate != null
        ? await _database.getHabitsChangedSince(sinceDate)
        : await _database.allHabits;

    final habitLogs = sinceDate != null
        ? await _database.getHabitLogsChangedSince(sinceDate)
        : await _database.allHabitLogs;

    final reminders = sinceDate != null
        ? await _database.getRemindersChangedSince(sinceDate)
        : await _database.allReminders;

    final noteFolders = sinceDate != null
        ? await _database.getNoteFoldersChangedSince(sinceDate)
        : await _database.allNoteFolders;

    final notes = sinceDate != null
        ? await _database.getNotesChangedSince(sinceDate)
        : await _database.allNotes;

    final tags = sinceDate != null
        ? await _database.getTagsChangedSince(sinceDate)
        : await _database.allTags;

    return SyncChanges(
      projects: projects.map((p) => p.toSyncJson()).toList(),
      todos: todos.map((t) => t.toSyncJson()).toList(),
      habits: habits.map((h) => h.toSyncJson()).toList(),
      habitLogs: habitLogs.map((hl) => hl.toSyncJson()).toList(),
      reminders: reminders.map((r) => r.toSyncJson()).toList(),
      noteFolders: noteFolders.map((nf) => nf.toSyncJson()).toList(),
      notes: notes.map((n) => n.toSyncJson()).toList(),
      tags: tags.map((t) => t.toSyncJson()).toList(),
    );
  }

  /// Handle incoming websocket message
  void _handleMessage(dynamic message) async {
    try {
      final data = jsonDecode(message as String);
      final response = SyncResponse.fromJson(data);

      if (response.isSuccess && response.message != null) {
        // Apply server changes to local database
        await _applyServerChanges(response.message!);

        // Update last sync timestamp
        _lastSyncAt = DateTime.now().toIso8601String();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastSyncKey, _lastSyncAt!);

        _updateStatus(SyncStatus.success);
        debugPrint('Sync completed successfully');
      } else if (response.hasError) {
        _updateStatus(SyncStatus.error);
        _errorController.add(response.error ?? 'Unknown sync error');
        debugPrint('Sync error: ${response.error}');
      }
    } catch (e) {
      debugPrint('Error handling sync message: $e');
      _updateStatus(SyncStatus.error);
      _errorController.add('Failed to process sync response: $e');
    }
  }

  /// Apply changes received from server
  Future<void> _applyServerChanges(SyncChanges changes) async {
    debugPrint('Applying server changes...');

    // Apply projects
    if (changes.projects != null) {
      for (final projectData in changes.projects!) {
        await _database.upsertProjectFromSync(projectData);
      }
    }

    // Apply note folders (before notes)
    if (changes.noteFolders != null) {
      for (final folderData in changes.noteFolders!) {
        await _database.upsertNoteFolderFromSync(folderData);
      }
    }

    // Apply tags (before notes)
    if (changes.tags != null) {
      for (final tagData in changes.tags!) {
        await _database.upsertTagFromSync(tagData);
      }
    }

    // Apply notes
    if (changes.notes != null) {
      for (final noteData in changes.notes!) {
        await _database.upsertNoteFromSync(noteData);
      }
    }

    // Apply todos
    if (changes.todos != null) {
      for (final todoData in changes.todos!) {
        await _database.upsertTodoFromSync(todoData);
      }
    }

    // Apply habits
    if (changes.habits != null) {
      for (final habitData in changes.habits!) {
        await _database.upsertHabitFromSync(habitData);
      }
    }

    // Apply habit logs
    if (changes.habitLogs != null) {
      for (final logData in changes.habitLogs!) {
        await _database.upsertHabitLogFromSync(logData);
      }
    }

    // Apply reminders
    if (changes.reminders != null) {
      for (final reminderData in changes.reminders!) {
        await _database.upsertReminderFromSync(reminderData);
      }
    }

    // Apply todo links
    if (changes.todoLinks != null) {
      for (final linkData in changes.todoLinks!) {
        await _database.upsertTodoLinkFromSync(linkData);
      }
    }

    // Apply todo images
    if (changes.todoImages != null) {
      for (final imageData in changes.todoImages!) {
        await _database.upsertTodoImageFromSync(imageData);
      }
    }

    // Apply note tags
    if (changes.noteTags != null) {
      for (final noteTagData in changes.noteTags!) {
        await _database.upsertNoteTagFromSync(noteTagData);
      }
    }

    debugPrint('Server changes applied successfully');
  }

  /// Handle websocket errors
  void _handleError(error) {
    debugPrint('Sync WebSocket error: $error');
    _updateStatus(SyncStatus.error);
    _errorController.add('WebSocket error: $error');
  }

  /// Handle websocket disconnect
  void _handleDisconnect() {
    debugPrint('Sync WebSocket disconnected');
    _channel = null;
    _channelSubscription = null;
    _updateStatus(SyncStatus.disconnected);
    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      _attemptReconnect();
    });
  }

  /// Attempt to reconnect
  void _attemptReconnect() async {
    if (_authService.isAuthenticated && _channel == null) {
      debugPrint('Attempting to reconnect... (attempt $_reconnectAttempts)');
      await connect();
    }
  }

  /// Update current status and notify listeners
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Dispose resources
  void dispose() {
    _reconnectTimer?.cancel();
    _connectivitySubscription?.cancel();
    disconnect();
    _statusController.close();
    _errorController.close();
  }
}
