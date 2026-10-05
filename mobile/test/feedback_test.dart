import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sangai/core/errors/app_exception.dart';
import 'package:ride_sangai/core/network/api_client.dart';
import 'package:ride_sangai/features/feedback/data/datasources/feedback_remote_datasource.dart';
import 'package:ride_sangai/features/feedback/data/dto/feedback_dto.dart';
import 'package:ride_sangai/features/feedback/data/repositories/feedback_repository_impl.dart';
import 'package:ride_sangai/features/feedback/domain/entities/user_feedback.dart';
import 'package:ride_sangai/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:ride_sangai/features/feedback/presentation/providers/feedback_providers.dart';
import 'package:ride_sangai/features/feedback/presentation/screens/feedback_screen.dart';

class _FakeAdapter implements HttpClientAdapter {
  final ({int status, Object? body}) Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final reply = handler(options);
    return ResponseBody.fromString(
      reply.body == null ? '' : jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> feedbackJson({String category = 'bug', int? rating = 4}) => {
      'id': 'f1',
      'category': category,
      'rating': rating,
      'message': 'The map freezes.',
      'status': 'open',
      'createdAt': '2026-10-05T10:00:00.000Z',
    };

/// Records what the form sends; fails when [error] is set.
class _FakeFeedbackRepository implements FeedbackRepository {
  final sent = <({String message, FeedbackCategory? category, int? rating})>[];
  AppException? error;

  @override
  Future<UserFeedback> send({required String message, FeedbackCategory? category, int? rating}) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    sent.add((message: message, category: category, rating: rating));
    if (error != null) throw error!;
    return UserFeedback(
      id: 'f1',
      category: category ?? FeedbackCategory.other,
      rating: rating,
      message: message,
      status: FeedbackStatus.open,
      createdAt: DateTime(2026, 10, 5),
    );
  }
}

void main() {
  group('FeedbackRemoteDataSource', () {
    late _FakeAdapter adapter;
    late FeedbackRemoteDataSource remote;

    void serve(({int status, Object? body}) Function(RequestOptions) handler) {
      adapter = _FakeAdapter(handler);
      final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..httpClientAdapter = adapter;
      remote = FeedbackRemoteDataSource(ApiClient(dio));
    }

    test('POSTs /feedback with the trimmed message and every set field', () async {
      serve((_) => (status: 201, body: feedbackJson()));
      final repository = FeedbackRepositoryImpl(remote, platform: 'android', appVersion: '1.0.0+1');

      final feedback = await repository.send(message: '  The map freezes.  ', category: FeedbackCategory.bug, rating: 4);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/feedback');
      expect(request.data, {
        'message': 'The map freezes.',
        'category': 'bug',
        'rating': 4,
        'platform': 'android',
        'appVersion': '1.0.0+1',
      });
      expect(feedback.id, 'f1');
      expect(feedback.category, FeedbackCategory.bug);
      expect(feedback.rating, 4);
      expect(feedback.status, FeedbackStatus.open);
      expect(feedback.createdAt.toUtc(), DateTime.utc(2026, 10, 5, 10));
    });

    test('leaves out the optional fields that are not set', () async {
      serve((_) => (status: 201, body: feedbackJson(category: 'other', rating: null)));

      final dto = await remote.send(const SendFeedbackDto(message: 'Hello'));

      expect(adapter.requests.single.data, {'message': 'Hello'});
      expect(dto.rating, isNull);
      expect(dto.toEntity().category, FeedbackCategory.other);
    });

    test('unknown category and status from a newer server fall back safely', () {
      final dto = FeedbackDto.fromJson({...feedbackJson(), 'category': 'question', 'status': 'archived'});
      expect(dto.toEntity().category, FeedbackCategory.other);
      expect(dto.toEntity().status, FeedbackStatus.open);
    });

    test('the rate limit surfaces as an AppException with the server message', () async {
      serve((_) => (
            status: 429,
            body: {
              'error': {'code': 'RATE_LIMITED', 'message': 'Too many requests. Try again later.'},
              'requestId': 'test',
            },
          ));

      await expectLater(
        remote.send(const SendFeedbackDto(message: 'Hello')),
        throwsA(isA<AppException>().having((e) => e.message, 'message', 'Too many requests. Try again later.')),
      );
    });
  });

  group('FeedbackScreen', () {
    late _FakeFeedbackRepository repository;

    Future<void> pumpScreen(WidgetTester tester) async {
      repository = _FakeFeedbackRepository();
      await tester.pumpWidget(ProviderScope(
        overrides: [feedbackRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: FeedbackScreen()),
      ));
    }

    Finder messageField() => find.byKey(const ValueKey('feedback-message'));

    Future<void> tapSend(WidgetTester tester) async {
      final button = find.widgetWithText(ElevatedButton, 'Send Feedback');
      await tester.scrollUntilVisible(button, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(button);
    }

    testWidgets('requires a message', (tester) async {
      await pumpScreen(tester);

      await tapSend(tester);
      await tester.pumpAndSettle();

      expect(find.text('Please write a message'), findsOneWidget);
      expect(repository.sent, isEmpty);

      await tester.enterText(messageField(), '   ');
      await tapSend(tester);
      await tester.pumpAndSettle();
      expect(find.text('Please write a message'), findsOneWidget);
      expect(repository.sent, isEmpty);
    });

    testWidgets('rejects messages over 2000 characters', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(messageField(), 'a' * 2001);
      await tapSend(tester);
      await tester.pumpAndSettle();

      expect(find.text('Keep it under 2000 characters'), findsOneWidget);
      expect(repository.sent, isEmpty);
    });

    testWidgets('sends category, rating and message, then thanks the rider', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Bug'));
      await tester.tap(find.byKey(const ValueKey('feedback-star-4')));
      await tester.pump();
      expect(find.text('Great'), findsOneWidget);
      await tester.enterText(messageField(), 'The map freezes.');
      await tapSend(tester);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(repository.sent.single, (message: 'The map freezes.', category: FeedbackCategory.bug, rating: 4));
      expect(find.text('Thanks for your feedback!'), findsOneWidget);
    });

    testWidgets('shows the server message when sending fails', (tester) async {
      await pumpScreen(tester);
      repository.error = const AppException('Too many requests. Try again later.', code: 'RATE_LIMITED');

      await tester.enterText(messageField(), 'Hello');
      await tapSend(tester);
      await tester.pumpAndSettle();

      expect(find.text('Too many requests. Try again later.'), findsOneWidget);
      expect(find.text('Thanks for your feedback!'), findsNothing);
      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
