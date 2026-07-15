# Flutter Dio Package

An internal Flutter package for building and configuring HTTP clients with
[`dio`](https://pub.dev/packages/dio). It centralizes networking concerns and
returns request results as `Either<Failure, T>`.

## Features

- Configurable `Dio` client builder
- Safe requests with `Either<Failure, T>` results
- Centralized transport and API error handling
- JWT authentication and token refresh support
- Request, response, and error logging
- Standard response, error, and metadata models
- Custom error message and `FailureType` resolvers
- Flutter Web compatibility

## Requirements

- Dart `^3.12.2`
- Flutter `>=1.17.0`

The package depends on `flutter_core_package` for types such as `Failure`,
`FailureType`, and `IStorageService`.

## Installation

This package is private and is not published on pub.dev. Add it to the consuming
application's `pubspec.yaml` using a local path:

```yaml
dependencies:
  flutter_dio_package:
    path: ../flutter_dio_package
```

Alternatively, install it from its Git repository:

```yaml
dependencies:
  flutter_dio_package:
    git:
      url: <repository-url>
      ref: <branch-or-tag>
```

Then fetch the dependencies:

```shell
flutter pub get
```

## Quick start

Create a configured client:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_core_package/flutter_core_package.dart';
import 'package:flutter_dio_package/flutter_dio_package.dart';

final Dio dio = DioBuilder().getDio(
  baseUrl: 'https://api.example.com/v1',
  enableLogging: true,
  headers: const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
);
```

### Fetch a single model

Given an API response with the following envelope:

```json
{
  "success": true,
  "data": { "id": 1, "name": "Sara" },
  "metadata": {
    "request_id": "req-123",
    "timestamp": "2026-07-16T10:00:00Z"
  }
}
```

Define the model and make the request:

```dart
class User {
  const User({required this.id, required this.name});

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as int,
        name: map['name'] as String,
      );

  final int id;
  final String name;
}

final result = await dio.safeCall<ApiResponse<User>>(
  '/users/1',
  mapper: (json) => ApiResponse<User>.fromMap(json, User.fromMap),
);

result.fold(
  (failure) => print(failure.message),
  (response) => print(response.data?.name),
);
```

### Fetch a list

Use `listMapper` when the response body is directly a JSON array:

```dart
final result = await dio.safeCall<List<User>>(
  '/users',
  listMapper: (items) => items
      .map((item) => User.fromMap(item as Map<String, dynamic>))
      .toList(),
);
```

Every `safeCall` must receive either a `mapper` or a `listMapper` appropriate
for the response shape.

### Send data

```dart
final result = await dio.safeCall<ApiResponse<User>>(
  '/users',
  method: RequestType.POST,
  data: const {'name': 'Sara'},
  mapper: (json) => ApiResponse<User>.fromMap(json, User.fromMap),
  options: Options(
    headers: const {'X-Request-Source': 'mobile'},
  ),
);
```

`GET`, `POST`, `PUT`, `PATCH`, and `DELETE` are supported. `safeCall` also
accepts query parameters, a `CancelToken`, and upload/download progress
callbacks.

## JWT authentication

For access-token injection without automatic refresh, provide a `tokenGetter`:

```dart
final dio = DioBuilder().getDio(
  baseUrl: 'https://api.example.com/v1',
  hasToken: true,
  tokenGetter: () => currentAccessToken,
);
```

For automatic token refresh and persistence, provide an `IStorageService`. The
interceptor uses the `access_token` and `refresh_token` storage keys:

```dart
final dio = DioBuilder().getDio(
  baseUrl: 'https://api.example.com/v1',
  hasToken: true,
  storageService: storageService,
  refreshTokenCallback: (refreshToken) async {
    final tokens = await authRepository.refresh(refreshToken);
    return TokenPair(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  },
);
```

The default authorization header is `Authorization: Bearer <token>`. Instantiate
`JwtInterceptor` directly when custom `headerKey` or `tokenPrefix` values are
required.

## Error handling

`ErrorInterceptor` converts HTTP errors, timeouts, cancellations, certificate
errors, and unsuccessful API envelopes into the appropriate `Failure`. A `2xx`
response is still considered unsuccessful when it contains `success: false` or
an `error` object.

Example error envelope:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The submitted data is invalid.",
    "details": ["The phone number is invalid."]
  },
  "metadata": { "request_id": "req-456" }
}
```

Observe normalized failures and customize their messages or presentation type:

```dart
final dio = DioBuilder().getDio(
  baseUrl: 'https://api.example.com/v1',
  onErrorCallback: (failure) {
    // Report the failure or forward it to the presentation layer.
  },
  errorMessageResolver: (error) {
    if (error.code == ApiResultCode.tokenExpired) {
      return 'Your session has expired. Please sign in again.';
    }
    return error.message;
  },
  failureTypeResolver: (error, request) => FailureType.popUp,
);
```

Override the presentation type for an individual request through `Options.extra`:

```dart
final result = await dio.safeCall<ApiResponse<User>>(
  '/users/1',
  mapper: (json) => ApiResponse<User>.fromMap(json, User.fromMap),
  options: Options(
    extra: {
      DioErrorHandler.failureTypeExtraKey: FailureType.inline,
    },
  ),
);
```

## Logging

Setting `enableLogging: true` adds a `LoggingInterceptor` with the default `Dio`
tag. Add it directly for more control:

```dart
dio.interceptors.add(
  LoggingInterceptor(
    tag: 'UsersApi',
    requestBody: true,
    responseBody: true,
  ),
);
```

Avoid logging sensitive headers or request bodies in production.

## Response models

- `ApiResponse<T>` contains `success`, `data`, `error`, and `metadata`.
- `ApiError` contains `code`, `message`, `details`, `statusCode`, and `requestId`.
- `Metadata` contains `requestId` and `timestamp`.
- `ApiResultCode` defines known backend error codes.
- `ResponseCode` defines HTTP and local network error codes.

## Development

Run static analysis and tests before submitting changes:

```shell
flutter analyze
flutter test
```

## License

See [LICENSE](LICENSE) for the project's licensing status.
