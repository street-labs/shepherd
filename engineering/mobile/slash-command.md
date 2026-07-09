---
product-hash: 4f261d48ab29cab39839634612b23b33c6062080d1681fec93813a0cbedc1f2d
product-slugs: [AC-sc-absolute-path, AC-sc-binary-file-rejected, AC-sc-cold-launch-8s, AC-sc-concurrent-sessions, AC-sc-cross-platform-open, AC-sc-directory-rejected, AC-sc-file-not-found, AC-sc-install-global, AC-sc-install-symlink, AC-sc-large-file-warning, AC-sc-launch-happy-path, AC-sc-no-args-usage, AC-sc-permission-denied, AC-sc-prompt-cleanup-stale, AC-sc-prompt-output-api-localhost-only, AC-sc-prompt-output-api-success, AC-sc-prompt-received, AC-sc-prompt-watcher-timeout, AC-sc-server-manual-stop, AC-sc-server-reuse, AC-sc-session-clear-on-new-file, AC-sc-session-output-isolation, AC-sc-single-tool-call, AC-sc-standalone-window, AC-sc-warm-launch-2s, FR-crp-done-action, FR-crp-file-load, FR-crp-syntax-highlight, FR-sc-app-serve, FR-sc-auto-load-file, FR-sc-browser-open, FR-sc-concurrent-windows, FR-sc-dynamic-port, FR-sc-file-api, FR-sc-file-resolution, FR-sc-file-validation, FR-sc-install, FR-sc-invoke-command, FR-sc-launcher-script, FR-sc-output-feedback, FR-sc-prompt-cleanup, FR-sc-prompt-output-api, FR-sc-prompt-receive, FR-sc-server-shutdown, FR-sc-session-cleanup, FR-sc-session-id, FR-sc-session-scoped-output, NFR-crp-client-only, NFR-crp-large-file-perf, NFR-sc-cross-platform, NFR-sc-launch-speed, NFR-sc-localhost-only, NFR-sc-minimal-footprint, NFR-sc-no-global-deps, NFR-sc-no-telemetry, NFR-sc-watcher-low-overhead]
---
# Slash Command Protocol — Mobile Engineering Spec

> Based on requirements in `../../product/slash-command.md` and `../../product/mobile/slash-command.md`
> See design in `../../design/mobile/slash-command.md`

## Overview

This spec defines the technical implementation of the mobile slash command protocol layer: deep link registration, URL parsing, callback construction, timeout handling, offline queue persistence, and session ID management. The protocol bridges Buzz Mobile (server-side agent) and Shepherd Mobile (native iOS/Android app) using URI schemes.

## Architecture

### Protocol Flow

1. **Launch**: Buzz Mobile constructs `shepherd://review?session=<id>&files=<base64>&context=<base64>` and opens it via platform deep link API
2. **Parse**: Shepherd Mobile receives URL, extracts parameters, validates session ID, decodes base64 payloads
3. **Annotate**: User annotates code in CRPG (covered by CRPG spec, not this spec)
4. **Callback**: Shepherd Mobile constructs `buzz://shepherd-result?session=<id>&prompt=<base64>` and opens it with 5-second timeout
5. **Queue (if offline)**: If callback fails, prompt is queued locally and retried when connectivity returns

### Technology Decisions

**iOS**:
- Deep link registration: `Info.plist` `CFBundleURLTypes` for `shepherd://` scheme
- Deep link handling: `SceneDelegate.scene(_:openURLContexts:)` or SwiftUI `onOpenURL` modifier
- URL parsing: `URLComponents` and `URL.queryItems`
- Callback: `UIApplication.shared.open(_:options:completionHandler:)` with 5-second timeout
- Offline queue: JSON file in `FileManager.default.urls(for: .applicationSupportDirectory)` at `ShepherdQueue/pending-prompts.json`
- Network reachability: `NWPathMonitor` (Network framework)

**Android**:
- Deep link registration: `AndroidManifest.xml` `<intent-filter>` with `<data android:scheme="shepherd" android:host="review" />`
- Deep link handling: `Activity.onNewIntent(Intent)` or Jetpack Compose `NavHost` deep link
- URL parsing: `Uri.parse()` and `Uri.getQueryParameter()`
- Callback: `Intent(Intent.ACTION_VIEW, Uri.parse(callbackUrl))` + `startActivity()` with 5-second Handler timeout
- Offline queue: JSON file in `Context.getFilesDir()` at `shepherd_queue/pending_prompts.json`
- Network reachability: `ConnectivityManager.registerNetworkCallback()`

Both platforms use **Swift/Kotlin native implementations**. No cross-platform wrapper (React Native/Flutter/etc.) — Shepherd Mobile is already native per the platform choice.

## Deep Link Registration

### iOS: `Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>shepherd</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.shepherd.review</string>
    </dict>
</array>
```

### Android: `AndroidManifest.xml`

```xml
<activity android:name=".MainActivity">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="shepherd" android:host="review" />
    </intent-filter>
</activity>
```

**Requirements satisfied**: `FR-scm-deeplink-protocol`

## Deep Link Parsing

### URL Format

`shepherd://review?session=<session-id>&files=<base64>&context=<base64>`

**Parameters**:
- `session` (required): Session ID string (slugified worktree name per `FR-sc-session-id`)
- `files` (required): Base64-encoded JSON array of file objects `[{path: string, content: string}]`
- `context` (optional): Base64-encoded JSON object `{overview: string, perFile: {[path: string]: string}}`

### iOS Implementation

```swift
// Implements: FR-scm-deeplink-protocol, FR-sc-session-id
func handleDeepLink(_ url: URL) -> Result<DeepLinkPayload, DeepLinkError> {
    guard url.scheme == "shepherd", url.host == "review" else {
        return .failure(.invalidScheme)
    }
    
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
        return .failure(.missingParameters)
    }
    
    guard let sessionId = queryItems.first(where: { $0.name == "session" })?.value,
          !sessionId.isEmpty else {
        return .failure(.missingSessionId)
    }
    
    guard let filesBase64 = queryItems.first(where: { $0.name == "files" })?.value,
          let filesData = Data(base64Encoded: filesBase64),
          let files = try? JSONDecoder().decode([FilePayload].self, from: filesData) else {
        return .failure(.invalidFilesPayload)
    }
    
    var context: ContextPayload? = nil
    if let contextBase64 = queryItems.first(where: { $0.name == "context" })?.value,
       let contextData = Data(base64Encoded: contextBase64) {
        context = try? JSONDecoder().decode(ContextPayload.self, from: contextData)
    }
    
    return .success(DeepLinkPayload(sessionId: sessionId, files: files, context: context))
}
```

### Android Implementation

```kotlin
// Implements: FR-scm-deeplink-protocol, FR-sc-session-id
fun handleDeepLink(intent: Intent): Result<DeepLinkPayload> {
    val uri = intent.data ?: return Result.failure(DeepLinkError.NoUri)
    
    if (uri.scheme != "shepherd" || uri.host != "review") {
        return Result.failure(DeepLinkError.InvalidScheme)
    }
    
    val sessionId = uri.getQueryParameter("session")
        ?: return Result.failure(DeepLinkError.MissingSessionId)
    
    val filesBase64 = uri.getQueryParameter("files")
        ?: return Result.failure(DeepLinkError.MissingFiles)
    
    val filesJson = try {
        String(Base64.decode(filesBase64, Base64.DEFAULT))
    } catch (e: IllegalArgumentException) {
        return Result.failure(DeepLinkError.InvalidBase64)
    }
    
    val files = try {
        Json.decodeFromString<List<FilePayload>>(filesJson)
    } catch (e: Exception) {
        return Result.failure(DeepLinkError.InvalidFilesJson)
    }
    
    val context = uri.getQueryParameter("context")?.let { contextBase64 ->
        try {
            val contextJson = String(Base64.decode(contextBase64, Base64.DEFAULT))
            Json.decodeFromString<ContextPayload>(contextJson)
        } catch (e: Exception) {
            null
        }
    }
    
    return Result.success(DeepLinkPayload(sessionId, files, context))
}
```

**Validation**:
- Session ID: non-empty string
- Files: valid base64 → valid JSON → array with at least one object containing `path` and `content` strings
- Context (optional): valid base64 → valid JSON → object with `overview` and/or `perFile` keys

**Requirements satisfied**: `FR-scm-deeplink-protocol`, `FR-sc-session-id`

## Callback Deep Link Construction

### URL Format

`buzz://shepherd-result?session=<session-id>&prompt=<base64>`

**Parameters**:
- `session` (required): Session ID (must match launch session ID)
- `prompt` (required): Base64-encoded markdown prompt text

### iOS Implementation

```swift
// Implements: FR-scm-mobile-callback, FR-scm-session-consistency
func sendCallback(sessionId: String, prompt: String, completion: @escaping (Result<Void, CallbackError>) -> Void) {
    guard let promptBase64 = prompt.data(using: .utf8)?.base64EncodedString() else {
        completion(.failure(.encodingFailed))
        return
    }
    
    guard let url = URL(string: "buzz://shepherd-result?session=\(sessionId)&prompt=\(promptBase64)") else {
        completion(.failure(.invalidURL))
        return
    }
    
    let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
        completion(.failure(.timeout))
    }
    
    UIApplication.shared.open(url, options: [:]) { success in
        timeoutTimer.invalidate()
        if success {
            completion(.success(()))
        } else {
            completion(.failure(.appNotAvailable))
        }
    }
}
```

### Android Implementation

```kotlin
// Implements: FR-scm-mobile-callback, FR-scm-session-consistency
fun sendCallback(sessionId: String, prompt: String, context: Context, completion: (Result<Unit>) -> Unit) {
    val promptBase64 = Base64.encodeToString(prompt.toByteArray(), Base64.NO_WRAP)
    val callbackUri = Uri.parse("buzz://shepherd-result")
        .buildUpon()
        .appendQueryParameter("session", sessionId)
        .appendQueryParameter("prompt", promptBase64)
        .build()
    
    val intent = Intent(Intent.ACTION_VIEW, callbackUri).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK
    }
    
    val handler = Handler(Looper.getMainLooper())
    var completed = false
    
    handler.postDelayed({
        if (!completed) {
            completed = true
            completion(Result.failure(CallbackError.Timeout))
        }
    }, 5000)
    
    try {
        context.startActivity(intent)
        handler.postDelayed({
            if (!completed) {
                completed = true
                completion(Result.success(Unit))
            }
        }, 500)
    } catch (e: ActivityNotFoundException) {
        handler.removeCallbacksAndMessages(null)
        if (!completed) {
            completed = true
            completion(Result.failure(CallbackError.AppNotAvailable))
        }
    }
}
```

**Timeout behavior**:
- 5-second timeout starts when callback URL is opened
- If timeout expires before success, callback fails with `.timeout` error
- On timeout or app-not-available error, UI falls back to clipboard copy + alert

**Requirements satisfied**: `FR-scm-mobile-callback`, `FR-scm-callback-timeout`, `FR-scm-session-consistency`

## Offline Queue Persistence

### Queue Storage Format

JSON file at platform-specific path:
- iOS: `<ApplicationSupportDirectory>/ShepherdQueue/pending-prompts.json`
- Android: `<FilesDir>/shepherd_queue/pending_prompts.json`

**Structure**:
```json
{
  "version": 1,
  "prompts": [
    {
      "id": "uuid-v4-string",
      "sessionId": "project-main",
      "prompt": "markdown prompt text (not base64)",
      "timestamp": 1720000000,
      "retryCount": 0
    }
  ]
}
```

### iOS Implementation

```swift
// Implements: FR-scm-offline-queue
struct QueuedPrompt: Codable {
    let id: String
    let sessionId: String
    let prompt: String
    let timestamp: TimeInterval
    var retryCount: Int
}

class OfflineQueue {
    private let fileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let queueDir = appSupport.appendingPathComponent("ShepherdQueue", isDirectory: true)
        try? FileManager.default.createDirectory(at: queueDir, withIntermediateDirectories: true)
        return queueDir.appendingPathComponent("pending-prompts.json")
    }()
    
    func enqueue(sessionId: String, prompt: String) {
        var queue = loadQueue()
        let item = QueuedPrompt(
            id: UUID().uuidString,
            sessionId: sessionId,
            prompt: prompt,
            timestamp: Date().timeIntervalSince1970,
            retryCount: 0
        )
        queue.append(item)
        saveQueue(queue)
    }
    
    func dequeue(id: String) {
        var queue = loadQueue()
        queue.removeAll { $0.id == id }
        saveQueue(queue)
    }
    
    func retryAll(sendCallback: @escaping (QueuedPrompt, @escaping (Bool) -> Void) -> Void) {
        let queue = loadQueue()
        for var item in queue {
            sendCallback(item) { success in
                if success {
                    self.dequeue(id: item.id)
                } else {
                    item.retryCount += 1
                    self.updateRetryCount(id: item.id, count: item.retryCount)
                }
            }
        }
    }
    
    private func loadQueue() -> [QueuedPrompt] {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([QueuedPrompt].self, from: data) else {
            return []
        }
        return decoded
    }
    
    private func saveQueue(_ queue: [QueuedPrompt]) {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
    
    private func updateRetryCount(id: String, count: Int) {
        var queue = loadQueue()
        if let index = queue.firstIndex(where: { $0.id == id }) {
            queue[index].retryCount = count
            saveQueue(queue)
        }
    }
}
```

### Android Implementation

```kotlin
// Implements: FR-scm-offline-queue
@Serializable
data class QueuedPrompt(
    val id: String,
    val sessionId: String,
    val prompt: String,
    val timestamp: Long,
    var retryCount: Int
)

class OfflineQueue(private val context: Context) {
    private val queueFile: File
        get() {
            val queueDir = File(context.filesDir, "shepherd_queue")
            queueDir.mkdirs()
            return File(queueDir, "pending_prompts.json")
        }
    
    fun enqueue(sessionId: String, prompt: String) {
        val queue = loadQueue().toMutableList()
        val item = QueuedPrompt(
            id = UUID.randomUUID().toString(),
            sessionId = sessionId,
            prompt = prompt,
            timestamp = System.currentTimeMillis() / 1000,
            retryCount = 0
        )
        queue.add(item)
        saveQueue(queue)
    }
    
    fun dequeue(id: String) {
        val queue = loadQueue().filterNot { it.id == id }
        saveQueue(queue)
    }
    
    fun retryAll(sendCallback: (QueuedPrompt, (Boolean) -> Unit) -> Unit) {
        val queue = loadQueue()
        queue.forEach { item ->
            sendCallback(item) { success ->
                if (success) {
                    dequeue(item.id)
                } else {
                    updateRetryCount(item.id, item.retryCount + 1)
                }
            }
        }
    }
    
    private fun loadQueue(): List<QueuedPrompt> {
        if (!queueFile.exists()) return emptyList()
        return try {
            val json = queueFile.readText()
            Json.decodeFromString<List<QueuedPrompt>>(json)
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    private fun saveQueue(queue: List<QueuedPrompt>) {
        try {
            val json = Json.encodeToString(queue)
            queueFile.writeText(json)
        } catch (e: Exception) {
            // Log error but don't crash
        }
    }
    
    private fun updateRetryCount(id: String, count: Int) {
        val queue = loadQueue().toMutableList()
        val index = queue.indexOfFirst { it.id == id }
        if (index != -1) {
            queue[index] = queue[index].copy(retryCount = count)
            saveQueue(queue)
        }
    }
}
```

**Retry Logic**:
- Automatic retry on network reconnect (monitored by `NWPathMonitor` / `ConnectivityManager`)
- Exponential backoff: 0s (immediate), 5s, 15s, then manual-only after 3 attempts
- Max 3 automatic retry attempts per prompt
- After 3 failed attempts, item stays in queue for manual retry via UI

**Requirements satisfied**: `FR-scm-offline-queue`, `AC-scm-offline-queue`

## Session ID Management

Session IDs are passed via deep link parameters. No local session ID generation or storage is needed — the server-side agent (Buzz Mobile) generates the session ID per `FR-sc-session-id` and passes it in both launch and callback URLs.

**Session ID format**: Slugified worktree basename (e.g., `project-main`, `my-feature-branch`)

**Storage**: Only stored in-memory during active session. When a new deep link arrives with a different session ID, the previous session is cleared and replaced (per design spec Flow 4).

**Matching**: Callback URL must include the same session ID as the launch URL. Buzz Mobile uses this to route the prompt back to the correct conversation.

**Requirements satisfied**: `FR-sc-session-id`, `FR-scm-session-consistency`, `AC-scm-session-match`

## Network Reachability

### iOS: `NWPathMonitor`

```swift
// Implements: FR-scm-offline-queue (retry on reconnect)
import Network

class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    var isConnected: Bool {
        monitor.currentPath.status == .satisfied
    }
    
    func startMonitoring(onReconnect: @escaping () -> Void) {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                onReconnect()
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}
```

### Android: `ConnectivityManager`

```kotlin
// Implements: FR-scm-offline-queue (retry on reconnect)
class NetworkMonitor(context: Context, private val onReconnect: () -> Unit) {
    private val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    
    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            onReconnect()
        }
    }
    
    fun startMonitoring() {
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
        connectivityManager.registerNetworkCallback(request, networkCallback)
    }
    
    fun stopMonitoring() {
        connectivityManager.unregisterNetworkCallback(networkCallback)
    }
    
    fun isConnected(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }
}
```

**Usage**: On reconnect callback, invoke `OfflineQueue.retryAll()` to send pending prompts.

**Requirements satisfied**: `FR-scm-offline-queue`

## Error Handling

| Error Condition | iOS Error | Android Error | Action |
|---|---|---|---|
| Invalid URL scheme | `.invalidScheme` | `InvalidScheme` | Show "Invalid Link" alert |
| Missing session ID | `.missingSessionId` | `MissingSessionId` | Show "Session Missing" alert |
| Invalid base64 | `.invalidFilesPayload` | `InvalidBase64` | Show "Invalid Link" alert |
| Invalid JSON | `.invalidFilesPayload` | `InvalidFilesJson` | Show "Invalid Link" alert |
| Callback timeout (5s) | `.timeout` | `Timeout` | Copy to clipboard + show alert |
| Buzz not available | `.appNotAvailable` | `AppNotAvailable` | Copy to clipboard + show alert |
| Network unavailable | (check before send) | (check before send) | Queue prompt + show toast |

All error messages defined in design spec `design/mobile/slash-command.md` §Error Messages.

**Requirements satisfied**: `FR-scm-callback-timeout`, `FR-scm-offline-queue`, `AC-scm-timeout-fallback`

## Code Map

This maps functional requirements to planned implementation locations. All entries are `planned` — no code exists yet.

| Slug | Planned Location | Status |
|---|---|---|
| `FR-scm-deeplink-protocol` | `Sources/DeepLink/DeepLinkParser.swift`, `app/src/main/java/com/shepherd/deeplink/DeepLinkParser.kt` | planned |
| `FR-scm-mobile-callback` | `Sources/DeepLink/CallbackSender.swift`, `app/src/main/java/com/shepherd/deeplink/CallbackSender.kt` | planned |
| `FR-scm-session-consistency` | `Sources/DeepLink/DeepLinkParser.swift`, `Sources/DeepLink/CallbackSender.swift` (same session ID passed through) | planned |
| `FR-scm-offline-queue` | `Sources/Queue/OfflineQueue.swift`, `app/src/main/java/com/shepherd/queue/OfflineQueue.kt` | planned |
| `FR-scm-callback-timeout` | `Sources/DeepLink/CallbackSender.swift`, `app/src/main/java/com/shepherd/deeplink/CallbackSender.kt` | planned |
| `FR-sc-session-id` | `Sources/DeepLink/DeepLinkParser.swift`, `app/src/main/java/com/shepherd/deeplink/DeepLinkParser.kt` (parse from URL) | planned |

## Open Questions

None at this time. All technical decisions made above.

## Dependencies

- **Swift 5.9+** (iOS): For `async`/`await` support in callback handling (if used)
- **Kotlin 1.9+** (Android): For coroutines in queue retry (if used)
- **Network framework** (iOS): For `NWPathMonitor`
- **ConnectivityManager** (Android): For network state monitoring
- **URLComponents / Uri**: Standard library URL parsing
- **JSONEncoder/JSONDecoder** (iOS), **kotlinx.serialization** (Android): JSON encoding/decoding

No third-party dependencies required for protocol layer.
