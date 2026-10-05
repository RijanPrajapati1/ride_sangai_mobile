# Ride Sangai (mobile)

Flutter app for group rides, treks and meetups. State management is Riverpod; each feature follows clean architecture (`data` → `domain` → `presentation`).

## Running against the API

Start the server first (see [`../server/README.md`](../server/README.md)), then:

| Where the app runs | Command |
| --- | --- |
| Android emulator | `flutter run` (uses `http://10.0.2.2:4000/api/v1`) |
| iOS simulator, desktop, web | `flutter run` (uses `http://localhost:4000/api/v1`) |
| Real phone on your Wi-Fi | `flutter run --dart-define=API_BASE_URL=http://<your-computer-ip>:4000/api/v1` |
| Release build | `flutter build apk --dart-define=API_BASE_URL=https://api.example.com/api/v1` |

Sign in with the seeded demo account `demo@bikersync.app` / `biker123` (the "Try Demo Login" button), or `admin@gmail.com` / `Test@1234` for the admin dashboard.

## How networking works

```
Screen ─► Riverpod controller ─► Repository ─► RemoteDataSource ─► ApiClient ─► Dio ─► API
                                     │                                  │
                                TokenStorage                      AuthInterceptor
                              (secure storage)               (token + refresh + sign-out)
```

All of it lives in `lib/core`:

| File | What it does |
| --- | --- |
| `config/app_config.dart` | API base URL (`--dart-define=API_BASE_URL`) and timeouts |
| `network/api_client.dart` | `get` / `post` / `put` / `patch` / `delete` / `upload`. Returns decoded JSON or throws an `AppException`, never a raw `DioException` |
| `network/api_endpoints.dart` | API paths |
| `network/api_error_mapper.dart` | Turns the server's `{ error: { code, message } }` envelope into typed exceptions (`ConflictException`, `NotFoundException`, `NetworkException`, …). `message` is safe to show users; `code` (for example `RIDE_FULL`) is for branching |
| `network/interceptors/auth_interceptor.dart` | Adds `Authorization: Bearer …`, refreshes the token before it expires or after `401 TOKEN_EXPIRED`, retries once, and signs the user out when the session is gone |
| `network/interceptors/logging_interceptor.dart` | Debug builds only: method, path, status, timing. Never prints bodies or headers |
| `network/network_providers.dart` | Riverpod providers: `apiClientProvider`, `tokenStorageProvider`, `sessionEventsProvider` |
| `storage/token_storage.dart` | Tokens and the signed-in user in Keychain / Keystore-backed secure storage |

### Security

- Tokens are stored with `flutter_secure_storage` (iOS: `first_unlock_this_device`, so they're never restored onto another device). Android app backups are off.
- Only one token refresh runs at a time. Refresh tokens are single-use, and the server revokes the session if one is replayed.
- When the server reports the session is over (`SESSION_REVOKED`, `REFRESH_TOKEN_REUSED`, …), tokens are wiped and the app returns to the login screen.
- Release builds refuse a non-HTTPS `API_BASE_URL` at startup. Plain HTTP works only in Android **debug** builds (`android/app/src/debug/res/xml/network_security_config.xml`) and to local-network addresses on iOS (`NSAllowsLocalNetworking`).
- Request logs never include passwords, tokens or response bodies.

### What's connected

Every feature talks to the API through a `*RemoteDataSource`: authentication, profile and settings, rides, create ride, ride requests, community, notifications, messages and explore (places, reviews, saved places). Admin and home reuse those repositories. Only onboarding stays local, because "has seen the intro" is a per-device setting.

Photo pickers upload real images with `UploadService` (`lib/core/network/upload_service.dart`) and store the returned URL. Image URLs that point at `localhost` are rewritten to the host the app uses for the API (`AppConfig.mediaUrl`), so uploads also show on the emulator and phones.

Not yet: realtime updates over the WebSocket (`/api/v1/ws`), so chats refresh on pull or reopen; push notifications; infinite scroll (lists load the first page, up to 100 items).

### Adding an endpoint

1. **DTO**: `fromJson`/`toJson` with field names exactly as in the API (http://localhost:4000/docs).
2. **Remote data source**: add a method that calls `ApiClient`.
3. **Repository**: expose it through the domain interface.
4. **Provider/controller**: call it, and invalidate the affected providers after a change.

Show errors with `error.message` from the `AppException` (`runOrShowError` in `lib/shared/utils/` does this for button actions).

## Tests

```bash
flutter test
```

`test/core/network/api_client_test.dart` covers the interceptor (token header, single refresh for parallel requests, proactive refresh, sign-out on revoked sessions) and error mapping, using a fake HTTP adapter.
