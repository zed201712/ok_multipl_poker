# `StreamAsserter` - Specification

| **Task ID** | `TEST-EXCEPT-LIST-001` |
| **Date** | `2025/12/12` |
| **Author** | Gemini |

## 1. Overview

This document specifies a testing utility class, `StreamAsserter`, designed to assert a sequence of expectations on a `Stream`. It helps verify that a stream emits specific values in a specific order, with custom failure reasons for unmet expectations. This is an alternative to `emitsInOrder` that provides more detailed custom messages and a slightly different API.

This addresses the user's request to create a custom class for `expectLater` on streams.

## 2. Problem Statement Analysis & Improvement Suggestions

The initial request described a class `MyMatcher<T>` that listens to a stream and checks a list of `MyMatcher<T>` objects.

### Logical Issues and Naming
- **Name Collision:** The name `MyMatcher` was used for both the orchestrating class and the individual predicate object, which is confusing.
- **Imperative `close()`:** The request mentioned a `close()` method to verify completion. In asynchronous Dart testing, it's more idiomatic to return a `Future` that represents the completion of the entire expectation. This integrates better with `async`/`await` and `expectLater`.

### Proposed Improvements
1.  **Clearer Naming:**
    *   The main orchestrating class will be named `StreamAsserter<T>`.
    *   The individual expectation object will be defined by a class named `StreamPredicate<T>`.
2.  **Idiomatic Async API:**
    *   Instead of a `void close()` method, the `StreamAsserter` will have a method `Future<void> expect()` that completes when all predicates are successfully matched, or throws a `TestFailure` if an expectation is violated or the stream closes prematurely. This allows for easy integration with `flutter_test`: `await asserter.expect();`.

## 3. Class Design

The implementation will consist of two main classes located in `lib/test/stream_asserter.dart`.

### 3.1. `StreamPredicate<T>`

This class represents a single condition to be met by a stream event.

**Properties:**
- `final bool Function(T value) predicate;`: A function that returns `true` if the stream event `value` matches the expectation.
- `final String reason;`: A descriptive string explaining what this predicate is checking for. This is used in error messages.

**Constructor:**
- `const StreamPredicate({required this.predicate, required this.reason});`

### 3.2. `StreamAsserter<T>`

This class orchestrates the matching of a stream against a list of predicates.

**Properties:**
- `final Stream<T> _stream;`: The stream to be tested.
- `final List<StreamPredicate<T>> _predicates;`: The ordered list of expectations.
- `final Completer<void> _completer = Completer<void>();`: Manages the asynchronous completion of the assertion.
- `int _currentIndex = 0;`: Tracks the current predicate to be matched.
- `StreamSubscription<T>? _subscription;`: The subscription to the stream.

**Constructor:**
- `StreamAsserter(this._stream, this._predicates);`

**Public Methods:**
- `Future<void> expect()`:
  - This method initiates the listening and assertion process.
  - It returns a `Future` that will be managed by the internal `_completer`.
  - It should be called only once.
  - It subscribes to the `_stream` and starts matching events.

**Internal Logic (`_listen` method called by `expect`):**
1.  If `_predicates` is empty, the `_completer` completes immediately.
2.  A subscription is made to `_stream`.
3.  **`onData` handler:**
    - For each event from the stream:
    - It checks if `_predicates[_currentIndex].predicate(event)` is `true`.
    - If `true`:
      - Increment `_currentIndex`.
      - If `_currentIndex` equals `_predicates.length`, it means all expectations have been met. The subscription is cancelled, and `_completer.complete()` is called.
    - If `false`:
      - The expectation has failed.
      - The subscription is cancelled.
      - `_completer.completeError()` is called with a `TestFailure` containing a message like:
        ```
        Expectation failed at index $_currentIndex: ${_predicates[_currentIndex].reason}.
        Received event: ${event.toString()}
        ```
4.  **`onDone` handler:**
    - When the stream closes:
    - If `_currentIndex` is less than `_predicates.length`, not all expectations were met.
    - `_completer.completeError()` is called with a `TestFailure`:
      ```
      Stream closed before all expectations were met.
      Pending expectation at index $_currentIndex: ${_predicates[_currentIndex].reason}.
      ```
5. **`onError` handler:**
    - If the stream emits an error, this error is propagated to the `_completer` via `completeError`. The subscription is cancelled.

## 4. Usage Example

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

// Assume StreamAsserter and StreamPredicate are defined as per the spec.

void main() {
  test('stream emits correct sequence', () async {
    final stream = Stream.fromIterable([1, 2, 3]);

    final asserter = StreamAsserter<int>(
      stream,
      [
        StreamPredicate(
          predicate: (val) => val == 1,
          reason: 'Should emit 1 first',
        ),
        StreamPredicate(
          predicate: (val) => val > 1,
          reason: 'Should emit a value greater than 1',
        ),
        StreamPredicate(
          predicate: (val) => val == 3,
          reason: 'Should emit 3 last',
        ),
      ],
    );

    await asserter.expect(); // This will complete successfully.
  });

  test('stream fails expectation', () async {
    final stream = Stream.fromIterable([1, 5, 3]); // 5 does not match the second predicate.

    final asserter = StreamAsserter<int>(
      stream,
      [
         StreamPredicate(
          predicate: (val) => val == 1,
          reason: 'Should be 1',
        ),
         StreamPredicate(
          predicate: (val) => val == 2, // This will fail
          reason: 'Should be 2',
        ),
      ],
    );

    // This will throw a TestFailure.
    expectLater(() => asserter.expect(), throwsA(isA<TestFailure>()));
  });
}

```
