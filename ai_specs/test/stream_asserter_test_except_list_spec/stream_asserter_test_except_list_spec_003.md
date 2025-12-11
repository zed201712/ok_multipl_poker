# `StreamAsserter` - Timeout Enhancement Specification

| **Task ID** | `TEST-EXCEPT-LIST-003` |
| **Date** | `2025/12/12` |
| **Author** | Gemini |
| **Based On** | `TEST-EXCEPT-LIST-002` |

## 1. Overview

This document specifies an enhancement to the `StreamAsserter` utility class to include a timeout mechanism. The goal is to add a `timeout` parameter to the `expect` function. If the stream does not satisfy all predicates within the specified duration, the test will fail, preventing it from hanging indefinitely.

### Key Changes:
1.  **Timeout in `expect`:** The `expect` method will be updated to accept an optional `timeout` parameter (`Duration`).
2.  **Timeout Failure:** If all stream predicates are not matched within the specified duration, the `Future` returned by `expect` will complete with a `TestFailure`.

## 2. Analysis of Requested Changes

Currently, a test using `StreamAsserter` may hang indefinitely if the stream under test ceases to emit events that match the remaining predicates. This can slow down test suites and make debugging difficult.

By introducing a configurable timeout directly within the `expect` method, we provide more granular control and immediate, clear feedback for a specific stream assertion failure.

### Improvement Suggestions:
- The `TestFailure` message upon timeout should be highly descriptive, indicating which predicate was pending and what events were received before the timeout occurred. This aligns with the existing failure reporting mechanisms.

## 3. Class Design Changes (from `TEST-EXCEPT-LIST-002`)

The changes will be applied to `lib/test/stream_asserter.dart`.

### 3.1. `StreamAsserter<T>`

**Modified `expect` method:**
- The `expect` method signature will be updated to accept an optional named `timeout` parameter of type `Duration?`.

  ```dart
  Future<void> expect({Duration? timeout})
  ```

**Modified `expect` Internal Logic:**
1.  The core stream listening logic will remain unchanged.
2.  The `Future` returned by `expect` will be chained with `.timeout()` if a `timeout` duration is provided.
3.  The `onTimeout` callback will be responsible for:
    a.  Canceling the stream subscription to prevent further execution.
    b.  Completing the internal `_completer` with a `TestFailure` that includes a detailed message about the timeout, the pending predicate, and all events received up to that point.

  ```dart
  // Simplified conceptual logic for expect()
  Future<void> expect({Duration? timeout}) {
    // ... existing initial checks ...

    _subscription = _stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: true,
    );

    if (timeout == null) {
      return _completer.future;
    }

    return _completer.future.timeout(timeout, onTimeout: () {
      if (!_completer.isCompleted) {
        _subscription?.cancel();
        _completer.completeError(TestFailure(
          'Timeout of ${timeout.inMilliseconds}ms expired before all expectations were met.\n'
          'Pending expectation at index $_currentIndex: ${_predicates[_currentIndex].reason}.\n'
          'Received events: ${recordedEvents.toString()}',
        ));
      }
    });
  }
  ```

## 4. Updated Usage Example

The following examples demonstrate how the `timeout` feature will work in both failure and success scenarios.

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

// Assume StreamAsserter and StreamPredicate are defined as per the new spec.

void main() {
  test('should fail with a timeout if predicates are not matched in time', () {
    // This stream only emits `1` and then stops, never emitting `2`.
    final controller = StreamController<int>();
    final stream = controller.stream;

    final asserter = StreamAsserter<int>(
      stream,
      [
        StreamPredicate(
          predicate: (val) => val == 1,
          reason: 'Should emit 1',
        ),
        StreamPredicate(
          predicate: (val) => val == 2, // This will never be matched.
          reason: 'Should emit 2',
        ),
      ],
    );

    // Add the first event to the stream.
    controller.add(1);

    // We expect this to throw a TestFailure because the timeout will expire.
    expect(
      () => asserter.expect(timeout: const Duration(milliseconds: 50)),
      throwsA(isA<TestFailure>()),
    );
  });

  test('should pass if all predicates match before timeout expires', () async {
    final stream = Stream.fromIterable([1, 99, 2]); // Event `99` is ignored.

    final asserter = StreamAsserter<int>(
      stream,
      [
        StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1'),
        StreamPredicate(predicate: (val) => val == 2, reason: 'Should be 2'),
      ],
    );

    // This should complete successfully, well before the 1-second timeout.
    await asserter.expect(timeout: const Duration(seconds: 1));
  });
}
```
