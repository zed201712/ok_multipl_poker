# `StreamAsserter` - `expectWait` Return Type Modification Specification

| **Task ID** | `TEST-EXCEPT-LIST-005` |
| **Date** | `2025/12/13` |
| **Author** | Gemini |
| **Based On** | `TEST-EXCEPT-LIST-004` |

## 1. Overview

This document specifies a change to the `expectWait` method in the `StreamAsserter` class. The method's return type will be changed from `Future<void>` to `Future<bool>`.

This provides a non-exceptional flow for handling stream assertions. Instead of throwing a `TestFailure` on timeout, the method will gracefully complete its `Future` with `false`. If all predicates are successfully matched, it will complete with `true`.

### Key Changes:
1.  **Modified Return Type:** The `expectWait` method signature will be updated to `Future<bool> expectWait({Duration? timeout})`.
2.  **Timeout Behavior:** On timeout, the `Future` returned by `expectWait` will resolve to `false` instead of throwing an error.
3.  **Success Behavior:** Upon successfully matching all predicates, the `Future` will resolve to `true`.
4.  **Early Stream Closure:** If the stream closes before all predicates are met, the `Future` will also resolve to `false`.

## 2. Analysis of Requested Changes

The current `expectWait` method mirrors `expect`, throwing a `TestFailure` on timeout. This change differentiates its purpose. By returning a boolean, `expectWait` becomes a tool for verifying stream conditions where a timeout is a possible and acceptable outcome, not necessarily a test-breaking failure.

This allows for more flexible testing patterns, such as:
```dart
final asserter = StreamAsserter(stream, predicates);
final bool didMatch = await asserter.expectWait(timeout: const Duration(seconds: 1));

if (!didMatch) {
  // Handle the timeout case gracefully, e.g., by logging or making a different assertion.
} else {
  // Proceed with other assertions.
}
```

This isolates timeout handling from the main test exception mechanism, keeping the `expect` method for cases where a timeout should definitively fail the test.

## 3. Class Design Changes (from `TEST-EXCEPT-LIST-004`)

The changes will be applied to `lib/test/stream_asserter.dart`.

### 3.1. `StreamAsserter<T>`

The core change is to make `expectWait` manage a `Completer<bool>` and handle its own timeout and completion logic, separate from the throwing behavior of `expect`.

**Refactoring Internal Logic:**
- The shared `_doExpect` method from the previous spec will be removed, as `expect` and `expectWait` now have fundamentally different completion contracts.
- The logic will be inlined back into the respective `expect` and `expectWait` methods to keep their behaviors distinct and clear.

**`expect` Method (Reverted to `TEST-EXCEPT-LIST-003` logic):**
- This method will manage a `Completer<void>` and will throw a `TestFailure` on timeout or premature stream closure.

**`expectWait` Method (New Logic):**
- This method will return `Future<bool>`.
- It will manage its own `Completer<bool>`.
- **On Timeout:** The timer will call `completer.complete(false)`.
- **On Success:** When all predicates are matched, `completer.complete(true)` will be called.
- **On Stream Done:** If the stream closes early, `completer.complete(false)` will be called.
- **On Stream Error:** Errors from the stream will still be propagated as exceptions.

```dart
// Conceptual logic for expectWait()

Future<bool> expectWait({Duration? timeout}) {
  if (_subscription != null) {
    throw StateError('expect() or expectWait() has already been called.');
  }

  final waitCompleter = Completer<bool>();

  // A new set of handlers specific to expectWait's logic
  void onData(T event) { ... }
  void onDone() { ... }
  void onError(Object e, StackTrace st) { ... }

  _subscription = _stream.listen(onData, onError: onError, onDone: onDone);

  if (timeout != null) {
    _timer = Timer(timeout, () {
      if (!waitCompleter.isCompleted) {
        _cancelSubscription();
        waitCompleter.complete(false);
      }
    });
  }

  return waitCompleter.future;
}
```
*Note: To avoid duplicating all the handler logic, the implementation can use a single set of handlers that check which completer (`Completer<void>` for `expect` or `Completer<bool>` for `expectWait`) is active.*

## 4. Updated Usage Example

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

// Assume StreamAsserter is defined as per the new spec.

void main() {
  test('expectWait should return false on timeout', () async {
    final controller = StreamController<int>();
    final stream = controller.stream;

    final asserter = StreamAsserter<int>(
      stream,
      [StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1')]
    );

    // Do not add any events, forcing a timeout.
    final result = await asserter.expectWait(timeout: const Duration(milliseconds: 50));

    expect(result, isFalse);
  });

  test('expectWait should return true on success', () async {
    final stream = Stream.fromIterable([1, 2]);

    final asserter = StreamAsserter<int>(
      stream,
      [StreamPredicate(predicate: (val) => val == 2, reason: 'Should be 2')]
    );

    final result = await asserter.expectWait(timeout: const Duration(seconds: 1));

    expect(result, isTrue);
  });

   test('expectWait should return false if stream closes early', () async {
    final stream = Stream.fromIterable([1]); // Stream ends before `2` is emitted.

    final asserter = StreamAsserter<int>(
      stream,
      [StreamPredicate(predicate: (val) => val == 2, reason: 'Should be 2')]
    );

    final result = await asserter.expectWait();

    expect(result, isFalse);
  });
}
```
