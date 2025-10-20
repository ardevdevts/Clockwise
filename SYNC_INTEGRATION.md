# ClockWise Sync Integration

This document explains how the real-time sync mechanism has been integrated into the ClockWise Flutter app.

## Overview

The sync system allows ClockWise to synchronize data between the local SQLite database (using Drift) and a remote server via WebSocket connection. It supports:

- ✅ Real-time bidirectional sync
- ✅ Conflict resolution (server wins based on `updatedAt` timestamp)
- ✅ Automatic reconnection
- ✅ Offline-first architecture
- ✅ Authentication with email/password
- ✅ Session management

## Architecture

### Components

1. **AuthService** (`lib/core/services/auth_service.dart`)
   - Handles user authentication (login, register, logout)
   - Manages session cookies
   - Stores session data in SharedPreferences

2. **SyncService** (`lib/core/services/sync/sync_service.dart`)
   - Manages WebSocket connection to server
   - Handles sync operations
   - Monitors connectivity and auto-reconnects
   - Tracks sync status (idle, connecting, syncing, success, error, disconnected)

3. **SyncModels** (`lib/core/services/sync/sync_models.dart`)
   - Defines data models for sync requests/responses
   - Provides conversion methods between Drift models and JSON

4. **AppDatabase Extensions** (`lib/database/crud.dart`)
   - Methods to get records changed since last sync
   - Upsert methods to apply server changes locally

5. **Riverpod Providers** (`lib/core/services/providers.dart`)
   - `authServiceProvider`: Provides AuthService instance
   - `syncServiceProvider`: Provides SyncService instance
   - `authStateProvider`: Manages authentication state
   - `syncStatusProvider`: Streams sync status updates

## Configuration

### Server URL

Update the server URLs in:

1. **AuthService** (`lib/core/services/auth_service.dart`):
```dart
static const String _baseUrl = 'http://localhost:3000'; // Change to your server URL
```

2. **SyncService** (`lib/core/services/sync/sync_service.dart`):
```dart
static const String _baseUrl = 'ws://localhost:3000'; // Change to your server URL
```

For production, use HTTPS and WSS:
```dart
static const String _baseUrl = 'https://your-server.com';
static const String _baseUrl = 'wss://your-server.com';
```

## Usage

### 1. User Authentication

Users can sign in or register via the login page:

```dart
// Navigate to login
context.push('/login');
```

The login page is at `lib/features/auth/login_page.dart`.

### 2. Automatic Sync

Sync happens automatically:

- **On app startup**: If authenticated, performs full sync
- **On login**: Connects and syncs all data
- **App resume**: Syncs when app comes to foreground
- **App pause**: Disconnects WebSocket to save resources

### 3. Manual Sync

Users can trigger manual sync using the `SyncStatusWidget`:

```dart
import 'package:financialtracker/features/settings/sync_status_widget.dart';

// Add to your settings or profile page
const SyncStatusWidget()
```

This widget displays:
- Authentication status
- Sync status
- Last sync time
- Manual sync button

### 4. Monitoring Sync Status

```dart
// Watch sync status in your widgets
final syncStatus = ref.watch(syncStatusProvider);

syncStatus.when(
  data: (status) {
    // Handle status: idle, connecting, syncing, success, error, disconnected
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### 5. Offline Mode

The app works fully offline. Users can:
- Use the app without signing in
- Click "Continue Offline" on the login page
- All data is stored locally in SQLite

## Sync Flow

### Initial Sync (First Time)

1. User logs in
2. SyncService connects to WebSocket
3. Sends all local data with empty `lastSyncAt`
4. Server responds with all server data
5. Client merges server data (server wins on conflicts)
6. Saves `lastSyncAt` timestamp

### Incremental Sync

1. SyncService sends only records changed since `lastSyncAt`
2. Server processes changes and returns:
   - New records created on server
   - Records where server version is newer (conflicts)
3. Client applies server changes
4. Updates `lastSyncAt` timestamp

### Conflict Resolution

- Conflicts are resolved using **"last write wins"** based on `updatedAt` timestamp
- Server is the source of truth
- If server's `updatedAt` is newer, server version is accepted
- If client's `updatedAt` is newer, client version is sent to server

## Data Models

All Drift tables support sync with these fields:
- `uuid`: Unique identifier across all devices
- `createdAt`: Creation timestamp
- `updatedAt`: Last modification timestamp
- `isDeleted`: Soft delete flag (for future sync optimization)

### Synced Tables

- ✅ Projects
- ✅ Todos
- ✅ Habits
- ✅ HabitLogs
- ✅ Reminders
- ✅ TodoLinks
- ✅ TodoImages
- ✅ NoteFolders
- ✅ Notes
- ✅ Tags
- ✅ NoteTags

## Error Handling

### Connection Errors

- Automatic reconnection with exponential backoff
- Maximum 5 reconnection attempts
- User can manually trigger sync after errors

### Authentication Errors

- Session expires → User redirected to login
- Invalid credentials → Error message shown
- Network errors → Retry with exponential backoff

### Sync Errors

- Validation errors → Shown to user
- Network timeouts → Automatic retry
- Conflict errors → Server version accepted

## Best Practices

### 1. Always Update `updatedAt`

When modifying records, always update the timestamp:

```dart
await database.update(todos).replace(
  todo.copyWith(
    title: newTitle,
    updatedAt: DateTime.now(), // Always update this
  ),
);
```

### 2. Use UUIDs for Foreign Keys

All foreign key references use UUIDs, not auto-increment IDs:

```dart
// ✅ Correct
projectUuid: project.uuid,

// ❌ Wrong
projectId: project.id,
```

### 3. Handle Offline State

Always design UI to work offline:

```dart
// Check auth state
final authState = ref.watch(authStateProvider);

if (authState.isAuthenticated) {
  // Show sync features
} else {
  // Show offline-only features
}
```

## Troubleshooting

### Sync Not Working

1. Check server URL configuration
2. Verify server is running
3. Check authentication status
4. Review sync status for error messages

### Data Not Syncing

1. Ensure `updatedAt` is being set correctly
2. Check network connectivity
3. Verify WebSocket connection is established
4. Look for errors in sync status

### Authentication Issues

1. Clear app data and try fresh login
2. Verify server authentication endpoint
3. Check session cookie handling
4. Review server logs for auth errors

## Future Enhancements

- [ ] Implement soft delete sync (currently creates/updates only)
- [ ] Add conflict resolution UI for user choice
- [ ] Implement delta sync for large datasets
- [ ] Add sync queue for offline changes
- [ ] Implement selective sync (sync only specific data types)
- [ ] Add sync analytics and monitoring

## Testing

### Manual Testing

1. **Test Offline Mode**:
   - Use app without login
   - Create data
   - Verify data persists locally

2. **Test First Sync**:
   - Login with new account
   - Create data on device
   - Verify data syncs to server
   - Login on another device
   - Verify data appears

3. **Test Incremental Sync**:
   - Make changes on device A
   - Wait for sync
   - Open device B
   - Verify changes appear

4. **Test Conflict Resolution**:
   - Edit same record on two devices offline
   - Bring both online
   - Verify server version wins

### Automated Testing

```dart
// TODO: Add integration tests for sync service
```

## Server Requirements

The server must implement:

1. **Authentication Endpoints**:
   - `POST /api/auth/email/login`
   - `POST /api/auth/email/register`
   - `POST /api/auth/logout`
   - `GET /api/auth/session`

2. **Sync WebSocket**:
   - `WS /sync`
   - Accept JSON sync requests
   - Return JSON sync responses
   - Validate session cookies

3. **Database Schema**:
   - Match Drift schema
   - Include `uuid`, `createdAt`, `updatedAt`, `isDeleted`
   - Add `userId` foreign key to all tables

## License

This sync implementation is part of the ClockWise project.
