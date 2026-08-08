import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:flutter_template/core/di/locator.dart';
import 'package:flutter_template/core/network/api_client.dart';
import 'package:flutter_template/core/storage/secure_storage_service.dart';
import 'package:flutter_template/features/auth/auth_controller.dart';

import 'helpers/auth_harness.dart';

void main() {
  late FakeSecureStorage secure;
  late DioAdapter adapter;
  late ProviderContainer container;

  setUp(() async {
    await locator.reset();
    secure = FakeSecureStorage();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    locator
      ..registerSingleton<SecureStorageService>(secure)
      ..registerSingleton<ApiClient>(mocked.client);
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  Future<void> waitForResolution() async {
    for (var i = 0;
        i < 50 && container.read(authProvider).status == AuthStatus.unknown;
        i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  test('login persists the session and authenticates', () async {
    adapter.onPost(
      '/api/v1/auth/login',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'tokens': {
            'access_token': 'acc',
            'refresh_token': 'ref',
            'expires_in': 900,
          },
          'user': {
            'id': 'u1',
            'email': 'a@b.com',
            'name': 'Alex',
            'role': 'user',
          },
        },
      }),
      data: {'email': 'a@b.com', 'password': 'secret123'},
    );

    final ok = await container
        .read(authProvider.notifier)
        .login(email: 'a@b.com', password: 'secret123');

    expect(ok, isTrue);
    final state = container.read(authProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.email, 'a@b.com');
    expect(state.user?.role, 'user');
    expect(secure.store[SecureKeys.authToken], 'acc');
    expect(secure.store[SecureKeys.refreshToken], 'ref');
    expect(secure.store[SecureKeys.userId], 'u1');
  });

  test('login failure surfaces the server message and stays signed out',
      () async {
    adapter.onPost(
      '/api/v1/auth/login',
      (server) => server.reply(401, {
        'success': false,
        'error': {'code': 'unauthorized', 'message': 'invalid credentials'},
      }),
      data: {'email': 'a@b.com', 'password': 'wrong'},
    );

    final ok = await container
        .read(authProvider.notifier)
        .login(email: 'a@b.com', password: 'wrong');

    expect(ok, isFalse);
    final state = container.read(authProvider);
    expect(state.status, isNot(AuthStatus.authenticated));
    expect(state.error, 'invalid credentials');
    expect(secure.store[SecureKeys.authToken], isNull);
  });

  test('register creates the account then logs in', () async {
    adapter
      ..onPost(
        '/api/v1/auth/register',
        (server) => server.reply(201, {
          'success': true,
          'data': {
            'id': 'u2',
            'email': 'n@b.com',
            'name': 'New',
            'role': 'user',
          },
        }),
        data: {'name': 'New', 'email': 'n@b.com', 'password': 'secret123'},
      )
      ..onPost(
        '/api/v1/auth/login',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'tokens': {
              'access_token': 'acc2',
              'refresh_token': 'ref2',
              'expires_in': 900,
            },
            'user': {
              'id': 'u2',
              'email': 'n@b.com',
              'name': 'New',
              'role': 'user',
            },
          },
        }),
        data: {'email': 'n@b.com', 'password': 'secret123'},
      );

    final ok = await container.read(authProvider.notifier).register(
          name: 'New',
          email: 'n@b.com',
          password: 'secret123',
        );

    expect(ok, isTrue);
    expect(container.read(authProvider).status, AuthStatus.authenticated);
    expect(secure.store[SecureKeys.userId], 'u2');
  });

  test('restore re-fetches the profile from a saved session', () async {
    secure.store[SecureKeys.authToken] = 'acc';
    secure.store[SecureKeys.userId] = 'u1';
    adapter.onGet(
      '/api/v1/users/u1',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'id': 'u1',
          'email': 'a@b.com',
          'name': 'Alex',
          'role': 'user',
        },
      }),
    );

    // First read constructs the controller, whose build() triggers _restore().
    container.read(authProvider.notifier);
    await waitForResolution();

    final state = container.read(authProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.name, 'Alex');
  });
}
