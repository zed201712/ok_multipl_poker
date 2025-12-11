# `StreamAsserter` - Enhancements Specification

| **Task ID** | `TEST-EXCEPT-LIST-002` |
| **Date** | `2025/12/12` |
| **Author** | Gemini |
| **Based On** | `TEST-EXCEPT-LIST-001` |

## 1. Overview

This document specifies enhancements to the `StreamAsserter` utility class. The goal is to evolve its matching logic to be more flexible and to provide better debugging capabilities.

### Key Changes:
1.  **Flexible Matching Logic:** Modify the assertion criteria to ensure all `StreamPredicate`s are matched in the correct order, while ignoring any intermediate events that do not match the current predicate. This is a shift from a strict one-to-one event-to-predicate match.
2.  **Event Callback:** Introduce an optional `onData` callback to allow developers to inspect every event as it is received from the stream.
3.  **Event Recording:** Add an internal list to record all received events, which can be included in failure messages to improve debugging context.

## 2. Analysis of Requested Changes

The previous implementation (`TEST-EXCEPT-LIST-001`) behaved similarly to `emitsInOrder`, where every event from the stream was expected to match a predicate in the list. The new requirement is to allow non-matching events ("noise") to occur between matching events. This significantly increases the utility's flexibility for testing complex event streams.

### Improvement Suggestions:
- **Debugging Context:** In case of failure (especially when the stream closes prematurely), the error message should include all the events that were recorded. This helps the developer understand what the stream actually emitted, making it easier to diagnose the issue.

## 3. Class Design Changes (from `TEST-EXCEPT-LIST-001`)

The changes will be applied to `lib/test/stream_asserter.dart`.

### 3.1. `StreamAsserter<T>`

**New/Modified Properties:**
- `final void Function(T data)? onData;`: An optional callback function that is invoked for every event received from the stream.
- `final List<T> recordedEvents = [];`: A public list that stores every event received from the stream for debugging purposes.

**Updated Constructor:**
- The constructor will be updated to accept the optional `onData` callback.
  ```dart
  StreamAsserter(this._stream, this._predicates, {this.onData});
  ```

**Modified `_onData` Internal Logic:**
1.  For every event received, it will first be added to the `recordedEvents` list.
2.  The `onData?.call(event)` callback will be invoked.
3.  The logic then attempts to match the event against the *current* predicate at `_predicates[_currentIndex]`.
    -   **If it matches:** `_currentIndex` is incremented. If all predicates have now been matched, the assertion completes successfully.
    -   **If it does not match:** The event is simply ignored, and the asserter waits for the next event to try and match the same `_currentIndex` predicate.

**Modified `_onDone` Internal Logic:**
- If the stream closes before all predicates are matched (`_currentIndex < _predicates.length`), the `TestFailure` message will be enhanced to include the list of `recordedEvents`.
  ```
  Stream closed before all expectations were met.
  Pending expectation at index $_currentIndex: ${_predicates[_currentIndex].reason}.
  Received events: [event1, event2, ...]
  ```

## 4. Updated Usage Example

This example demonstrates the new flexible matching logic where intermediate, non-matching events are ignored.

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

// Assume StreamAsserter and StreamPredicate are defined as per the new spec.

void main() {
  test('should pass with intermediate non-matching events', () async {
    final stream = Stream.fromIterable([1, 99, 2, 100, 3]); // 99 and 100 are noise
    final received = <int>[];

    final asserter = StreamAsserter<int>(
      stream,
      [
        StreamPredicate(
          predicate: (val) => val == 1,
          reason: 'Should emit 1',
        ),
        StreamPredicate(
          predicate: (val) => val == 2,
          reason: 'Should emit 2 after 1',
        ),
        StreamPredicate(
          predicate: (val) => val == 3,
          reason: 'Should emit 3 at the end',
        ),
      ],
      onData: (data) => received.add(data), // Optional: record data
    );

    await asserter.expect(); // This will complete successfully.

    // Verify onData callback and recordedEvents work as expected
    expect(received, [1, 99, 2, 100, 3]);
    expect(asserter.recordedEvents, [1, 99, 2, 100, 3]);
  });

  test('should pass when predicates are not exhaustive', () async {
    final stream = Stream.fromIterable([1, 2, 3, 4, 5]);

    final asserter = StreamAsserter<int>(
      stream,
      [
        StreamPredicate(
          predicate: (val) => val == 1,
          reason: 'Should find 1',
        ),
        StreamPredicate(
          predicate: (val) => val == 5,
          reason: 'Should find 5',
        ),
      ],
    );

    await asserter.expect(); // This will also complete successfully.
  });

  test('should fail if stream closes before all predicates are matched', () {
    final stream = Stream.fromIterable([1, 2, 99]); // Missing event 3

    final asserter = StreamAsserter<int>(
      stream,
      [
        StreamPredicate(predicate: (val) => val == 1, reason: 'Should be 1'),
        StreamPredicate(predicate: (val) => val == 3, reason: 'Should be 3'),
      ],
    );

    // This will throw a TestFailure with a detailed message.
    expect(asserter.expect, throwsA(isA<TestFailure>()));
  });
}
```
