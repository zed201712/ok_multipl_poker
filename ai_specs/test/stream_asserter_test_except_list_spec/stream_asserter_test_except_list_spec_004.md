# `StreamAsserter` - `expectWait` Method Specification

| **Task ID** | `TEST-EXCEPT-LIST-004` |
| **Date** | `2025/12/12` |
| **Author** | Gemini |
| **Based On** | `TEST-EXCEPT-LIST-003` |

## 1. Overview

This document specifies the addition of a new `expectWait` method to the `StreamAsserter` utility class. This method will provide an alternative way to initiate the stream assertion process, with behavior identical to the existing `expect` method, including timeout functionality.

### Key Changes:
1.  **New `expectWait` method:** Add a new method `Future<void> expectWait({Duration? timeout})` to `StreamAsserter`.
2.  **Identical Behavior:** This method will function exactly like the `expect` method, returning a `Future` that completes when all predicates are met, or completes with a `TestFailure` if the timeout is reached or the stream closes prematurely.
3.  **Implementation Refactoring:** The internal implementation will be refactored to avoid code duplication between `expect` and `expectWait`.

## 2. Analysis of Requested Changes

The request is to add a new method `expectWait` that mirrors the functionality of `expect`. This provides an alternative entry point for stream assertions. To maintain clean and maintainable code, the common logic for setting up the stream listening, handling timeouts, and managing the completer should be extracted into a shared private method.

## 3. Class Design Changes (from `TEST-EXCEPT-LIST-003`)

The changes will be applied to `lib/test/stream_asserter.dart`.

### 3.1. `StreamAsserter<T>`

**New `expectWait` method:**
- A new public method `expectWait` will be added with the same signature as `expect`.
  ```dart
  Future<void> expectWait({Duration? timeout})
  ```

**Refactoring `expect` and `expectWait`:**
- A new private method, e.g., `_doExpect`, will be created to contain the shared logic.
- Both `expect` and `expectWait` will delegate to this new private method.

  ```dart
  // Conceptual logic for refactoring

  Future<void> expect({Duration? timeout}) {
    return _doExpect(timeout: timeout);
  }

  Future<void> expectWait({Duration? timeout}) {
    return _doExpect(timeout: timeout);
  }

  Future<void> _doExpect({Duration? timeout}) {
    if (_subscription != null) {
      throw StateError('expect() or expectWait() has already been called.');
    }

    if (_predicates.isEmpty) {
      _completer.complete();
      return _completer.future;
    }

    _subscription = _stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: true,
    );

    if (timeout != null) {
      _timer = Timer(timeout, () {
        if (!_completer.isCompleted) {
          _cancelSubscription();
          _completer.completeError(TestFailure(
            // ... error message
          ));
        }
      });
    }

    return _completer.future;
  }
  ```

## 4. Updated Usage Example

The usage of `expectWait` is identical to `expect`.

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

// Assume StreamAsserter is defined as per the new spec.

void main() {
  test('should pass using expectWait with a delayed value before timeout', () async {
    final controller = StreamController<int>();
    final stream = controller.stream;

    final asserter = StreamAsserter<int>(
      stream,
      [
        StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1'),
        StreamPredicate(predicate: (val) => val == 2, reason: 'Should be 2'),
      ],
    );

    // Add events with a delay.
    controller.add(1);
    Future.delayed(const Duration(milliseconds: 50), () => controller.add(2));

    // Use expectWait to wait for completion.
    await asserter.expectWait(timeout: const Duration(milliseconds: 200));
  });

  test('should fail using expectWait with a timeout', () {
    final controller = StreamController<int>();
    final stream = controller.stream;

    final asserter = StreamAsserter<int>(
      stream,
      [
        StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1'),
        StreamPredicate(predicate: (val) => val == 2, reason: 'Should be 2'),
      ],
    );

    controller.add(1);

    // We expect this to throw a TestFailure because the timeout will expire.
    expect(
      () => asserter.expectWait(timeout: const Duration(milliseconds: 50)),
      throwsA(isA<TestFailure>()),
    );
  });
}
```
