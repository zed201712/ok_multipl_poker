# `StreamAsserter` - Final Architecture Specification

| **Task ID** | `TEST-EXCEPT-LIST-007` |
| **Date** | `2025/12/13` |
| **Author** | Gemini |
| **Based On** | `TEST-EXCEPT-LIST-006` (with improvements) |

## 1. Overview

This document specifies the final revised architecture for the `StreamAsserter` class, incorporating the improvement suggestions from the previous specification. This design provides a robust, flexible, and resource-safe utility for stream testing.

### Key Architectural Changes:
1.  **Immediate Subscription:** `StreamAsserter` will begin listening to the stream immediately upon its instantiation to prevent any event loss.
2.  **Explicit Resource Management:** A public `cancel()` method will be added to allow for the explicit disposal of the stream subscription and other resources.
3.  **Distinct Assertion Methods:** The API will provide two distinct methods for assertion, each with a clear purpose:
    -   `expect()`: Returns `Future<void>` and throws a `TestFailure` if the assertion fails (due to timeout or premature stream closure). This is the standard assertion method.
    -   `expectWait()`: Returns `Future<bool>`, completing with `false` on failure and `true` on success. This method provides a non-exceptional way to check stream behavior.

## 2. Analysis and Design Rationale

This architecture is the culmination of previous iterations and is designed for clarity and safety.

-   **Immediate Listening & `cancel()`:** By subscribing in the constructor, we guarantee that no events are missed. The addition of `cancel()` addresses the potential for resource leaks by giving the user explicit control over the subscription's lifecycle, which is crucial in test environments (e.g., using `tearDown` or `addTearDown`).

-   **Differentiated `expect` vs. `expectWait`:** This separation provides a clear and powerful API. `expect()` is the go-to for standard test assertions, where a failure should halt the test. `expectWait()` is for more advanced scenarios where a developer might want to handle an assertion failure programmatically without failing the entire test.

## 3. Class Design Changes (from `TEST-EXCEPT-LIST-005`)

The changes will be applied to `lib/test/stream_asserter.dart`.

### 3.1. `StreamAsserter<T>`

**Constructor:**
-   The constructor will be modified to immediately call a private `_listen()` method which sets up the `_stream.listen(...)` subscription.

**`expect({Duration? timeout})` Method:**
-   **Signature:** `Future<void> expect({Duration? timeout})`
-   **Behavior:** This method will use a `Completer<void>`. If a timeout occurs or the stream closes before all predicates are met, the `Future` will complete with a `TestFailure`.

**`expectWait({Duration? timeout})` Method:**
-   **Signature:** `Future<bool> expectWait({Duration? timeout})`
-   **Behavior:** This method will use a `Completer<bool>`. On timeout or premature closure, the `Future` completes with `false`. On success, it completes with `true`.

**`cancel()` Method:**
-   **Signature:** `void cancel()`
-   **Behavior:** This public method will cancel the active `_subscription` and any pending `_timer`. It makes the `StreamAsserter` instance unusable for further assertions.

**Internal State and Handlers:**
-   The `_onData`, `_onError`, and `_onDone` handlers will be active from the moment of construction.
-   They must be able to handle events even before `expect` or `expectWait` sets a `_completer`.
-   A check (`_completer != null && !_completer.isCompleted`) must guard any attempt to complete a future.
-   Calling `expect` or `expectWait` more than once will still throw a `StateError`.

## 4. Updated Usage Example

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

// Assume StreamAsserter is defined as per the new spec.

void main() {
  late StreamController<int> controller;
  // The asserter is declared here but will be initialized in each test
  // to ensure a fresh instance and subscription.
  late StreamAsserter<int> asserter;

  setUp(() {
    controller = StreamController<int>();
  });

  tearDown(() async {
    // Clean up resources to prevent leaks between tests.
    asserter.cancel();
    if (!controller.isClosed) {
      await controller.close();
    }
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

    final result = await asserter.expectWait(timeout: const Duration(milliseconds: 50));

    expect(result, isFalse);
  });

  test('should capture events before expectWait() is called and return true', () async {
    // Emit an event *before* creating the asserter to show it would be missed.
    // Then create the asserter, then emit the events to be tested.
    controller.add(0); // This event will be missed.

    asserter = StreamAsserter<int>(
      controller.stream,
      [
        StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1'),
        StreamPredicate(predicate: (val) => val == 2, reason: 'Should be 2'),
      ],
    );

    // These events are captured immediately by the new asserter.
    controller.add(1);
    controller.add(99);
    controller.add(2);

    // Let the stream emit and be processed.
    await Future.delayed(const Duration(milliseconds: 10));

    // Now, call expectWait(). It should complete with true almost instantly.
    final result = await asserter.expectWait(timeout: const Duration(seconds: 1));

    expect(result, isTrue);
    // The recorded events should not include the event `0`.
    expect(asserter.recordedEvents, [1, 99, 2]);
  });
}
```
