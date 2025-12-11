# `StreamAsserter` - Refactoring and Behavioral Change Specification

| **Task ID** | `TEST-EXCEPT-LIST-006` |
| **Date** | `2025/12/13` |
| **Author** | Gemini |
| **Based On** | `TEST-EXCEPT-LIST-005` |

## 1. Overview

This document specifies two major architectural changes to the `StreamAsserter` class:

1.  **Immediate Subscription:** The stream will now be listened to immediately upon the instantiation of `StreamAsserter`, rather than waiting for `expect` or `expectWait` to be called. This ensures no events are missed between the creation of the asserter and the start of the assertion.
2.  **Return Type Unification:** The `expect` method's return type will be changed from `Future<void>` to `Future<bool>`, making its behavior consistent with `expectWait`. Both methods will now return `true` on success and `false` on timeout or premature stream closure, without throwing exceptions.

## 2. Analysis and Improvement Suggestions

This section addresses the logical implications of the requested changes and provides suggestions for improvement.

### 2.1. Unifying `expect` and `expectWait`

-   **Logical Analysis:** By changing `expect` to return `Future<bool>`, its functionality becomes identical to `expectWait`. This creates redundancy in the API, as there is no longer a distinction between the two methods.
-   **Improvement Suggestion:** It is recommended to maintain a behavioral difference. A common and effective pattern in testing libraries is:
    -   `expect()`: Throws a `TestFailure` on assertion failure (like timeout). This is idiomatic for testing, as an uncaught exception automatically fails the test.
    -   `expectWait()`: Returns a `Future<bool>`, allowing the developer to programmatically handle cases where a timeout is an expected or recoverable outcome.

    *This specification will proceed with making them identical as requested, but we recommend retaining the throwing behavior for `expect` for a more robust testing API.*

### 2.2. Listening on Initialization

-   **Logical Analysis:** Starting the stream subscription in the constructor is a valid approach to prevent event loss. However, it introduces a potential for resource leaks. If a `StreamAsserter` instance is created but neither `expect` nor `expectWait` is ever called, the underlying stream subscription will remain active.
-   **Improvement Suggestion:** To mitigate this, a public `cancel()` method should be added to `StreamAsserter`. This allows the consumer to explicitly dispose of the subscription and associated resources, for instance, in a test's `tearDown` or `addTearDown` block.

## 3. Class Design Changes (from `TEST-EXCEPT-LIST-005`)

The changes will be applied to `lib/test/stream_asserter.dart`.

### 3.1. `StreamAsserter<T>`

**Constructor:**
- The constructor will now immediately subscribe to the stream (`_stream.listen(...)`).
- Events will be processed and stored in `recordedEvents` as they arrive, even before `expect` or `expectWait` is called.

**`expect` and `expectWait` Methods:**
- Both methods will now have the signature `Future<bool> methodName({Duration? timeout})`.
- Their logic will be unified. When called, they will:
    1.  Check if an assertion is already in progress (e.g., by checking if `_completer` is not null).
    2.  Create a `Completer<bool>`.
    3.  Check if all predicates have *already* been met by the time of the call. If so, complete immediately with `true`.
    4.  If not, set up the timeout `Timer`, which will complete the future with `false` if it fires.

**New `cancel()` Method:**
- A new public method `void cancel()` will be added. This method will cancel the stream subscription (`_subscription?.cancel()`) and the timeout timer (`_timer?.cancel()`) to prevent resource leaks.

**Internal State Management:**
- The `_onData`, `_onError`, and `_onDone` handlers must now be robust enough to handle events before `_completer` has been initialized. When a predicate is met that fulfills all conditions, it should only attempt to complete the completer if it is non-null.

## 4. Updated Usage Example

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

// Assume StreamAsserter is defined as per the new spec.

void main() {
  late StreamController<int> controller;
  late StreamAsserter<int> asserter;

  setUp(() {
    controller = StreamController<int>();
  });

  tearDown(() {
    // Ensure resources are cleaned up after each test.
    asserter.cancel();
    controller.close();
  });

  test('should capture events before expect is called and return true', () async {
    // Events are emitted before expect() is called.
    controller.add(1);
    controller.add(99); // Noise
    controller.add(2);

    asserter = StreamAsserter<int>(
      controller.stream,
      [
        StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1'),
        StreamPredicate(predicate: (val) => val == 2, reason: 'Should be 2'),
      ],
    );

    // Let the stream emit, then wait a moment to ensure events are processed.
    await Future.delayed(const Duration(milliseconds: 10));

    // Now, call expect(). It should complete successfully (and quickly).
    final result = await asserter.expect(timeout: const Duration(seconds: 1));

    expect(result, isTrue);
    expect(asserter.recordedEvents, [1, 99, 2]);
  });

  test('expect should return false on timeout', () async {
    asserter = StreamAsserter<int>(
      controller.stream,
      [StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1')]
    );

    final result = await asserter.expect(timeout: const Duration(milliseconds: 50));

    expect(result, isFalse);
  });
}
```
