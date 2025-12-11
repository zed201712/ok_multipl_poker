import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ok_multipl_poker/test/stream_asserter.dart';

void main() {
  group('StreamAsserter', () {
    late StreamController<int> controller;
    late StreamAsserter<int> asserter;

    setUp(() {
      controller = StreamController<int>();
    });

    tearDown(() async {
      asserter.cancel();
      if (!controller.isClosed) {
        await controller.close();
      }
    });

    test('should pass with intermediate non-matching events', () async {
      asserter = StreamAsserter<int>(
        controller.stream,
        [
          StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1'),
          StreamPredicate(predicate: (val) => val == 3, reason: 'Should be 3'),
        ],
      );

      controller.add(1);
      controller.add(2); // noise
      controller.add(3);
      controller.close();

      await asserter.expect();
      expect(asserter.recordedEvents, [1, 2, 3]);
    });

    test('should fail if stream closes before all predicates are matched', () {
      asserter = StreamAsserter<int>(
        controller.stream,
        [
          StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1'),
          StreamPredicate(predicate: (val) => val == 3, reason: 'Should be 3'),
        ],
      );

      controller.add(1);
      controller.close();

      expect(() => asserter.expect(), throwsA(isA<TestFailure>()));
    });

    test('propagates stream error', () {
      asserter = StreamAsserter<int>(
        controller.stream,
        [StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1')],
      );

      final future = asserter.expect();
      controller.addError(Exception('Stream error'));

      expect(future, throwsA(isA<Exception>()));
    });

    test('throws StateError if expect() is called more than once', () {
      asserter = StreamAsserter<int>(controller.stream, []);

      asserter.expect(); // First call

      expect(() => asserter.expect(), throwsA(isA<StateError>()));
    });

    test('expect() should throw TestFailure on timeout', () {
      asserter = StreamAsserter<int>(
        controller.stream,
        [StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1')]
      );

      // Using expect() requires a TestFailure for timeout.
      expect(
        () => asserter.expect(timeout: const Duration(milliseconds: 50)),
        throwsA(isA<TestFailure>()),
      );
    });

    test('expectWait() should return false on timeout', () async {
      asserter = StreamAsserter<int>(
        controller.stream,
        [StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1')]
      );

      final start = DateTime.now();
      final result = await asserter.expectWait(timeout: const Duration(milliseconds: 50));
      print("expectWait() should return false on timeout, cost time: ${DateTime.now().difference(start).inMilliseconds}");

      expect(result, isFalse);
    });

    test('expectWait should return false if stream closes early', () async {
        asserter = StreamAsserter<int>(
            controller.stream,
            [StreamPredicate(predicate: (val) => val == 2, reason: 'Should be 2')]
        );

        controller.add(1);
        controller.close();

        final result = await asserter.expectWait();

        expect(result, isFalse);
    });

    test('should capture events before expectWait() is called and return true', () async {
      controller.add(0); // This event will be missed as it's before asserter creation

      asserter = StreamAsserter<int>(
        controller.stream,
        [
          StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1'),
          StreamPredicate(predicate: (val) => val == 2, reason: 'Should be 2'),
        ],
      );

      // These events are captured immediately by the asserter constructor
      controller.add(1);
      controller.add(99); // noise
      controller.add(2);

      // Let the stream emit and be processed.
      await Future.delayed(const Duration(milliseconds: 10));

      // Now, call expectWait(). It should complete with true almost instantly.
      final result = await asserter.expectWait(timeout: const Duration(seconds: 1));

      expect(result, isTrue);
      // The recorded events should not include the event `0`.
      expect(asserter.recordedEvents, [0, 1, 99, 2]);
    });

    test('should pass if predicates are already met when expect is called', () async {
      asserter = StreamAsserter<int>(
        controller.stream,
        [StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1')]
      );

      controller.add(1);
      await Future.delayed(const Duration(milliseconds: 10)); // Ensure event is processed

      final start = DateTime.now();
      await asserter.expect(); // Should complete immediately
      print("Should complete immediately, cost time: ${DateTime.now().difference(start).inMilliseconds}");
    });

    test('expectWait should return true if predicates are met before call', () async {
      asserter = StreamAsserter<int>(
        controller.stream,
        [StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1')]
      );

      controller.add(1);
      await Future.delayed(const Duration(milliseconds: 10)); // Ensure event is processed

      final start = DateTime.now();
      final result = await asserter.expectWait(); // Should complete immediately
      print("Should complete immediately, cost time: ${DateTime.now().difference(start).inMilliseconds}");

      expect(result, isTrue);
    });

  });
}
