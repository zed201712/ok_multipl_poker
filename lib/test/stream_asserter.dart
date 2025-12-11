import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Represents a single condition to be met by a stream event.
class StreamPredicate<T> {
  final bool Function(T value) predicate;
  final String reason;

  const StreamPredicate({required this.predicate, required this.reason});
}

class StreamAsserter<T> {
  final Stream<T> _stream;
  final List<StreamPredicate<T>> _predicates;
  final void Function(T data)? onData;

  final List<T> recordedEvents = [];
  
  int _currentIndex = 0;
  StreamSubscription<T>? _subscription;
  Timer? _timer;
  Completer<dynamic>? _completer;

  bool _streamIsDone = false;

  StreamAsserter(this._stream, this._predicates, {this.onData}) {
    _listen();
  }

  void _listen() {
    _subscription = _stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: true,
    );
  }

  /// Cancels the stream subscription and any pending timers.
  /// This should be called to clean up resources, e.g., in a test's `tearDown`.
  void cancel() {
    _timer?.cancel();
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> expect({Duration? timeout}) {
    if (_completer != null) {
      throw StateError('expect() or expectWait() has already been called.');
    }
    
    _completer = Completer<void>();

    if (_currentIndex >= _predicates.length) {
      _completer!.complete();
      return _completer!.future;
    }

    if (_streamIsDone) {
      _completer!.completeError(TestFailure(
        _getStreamClosedErrorMessage(),
      ));
      return _completer!.future;
    }

    if (timeout != null) {
      _timer = Timer(timeout, () {
        if (!(_completer?.isCompleted ?? true)) {
          _completer!.completeError(TestFailure(
            _getTimeoutErrorMessage(timeout),
          ));
        }
      });
    }

    return _completer!.future;
  }

  Future<bool> expectWait({Duration? timeout}) {
    if (_completer != null) {
      throw StateError('expect() or expectWait() has already been called.');
    }
    
    _completer = Completer<bool>();

    if (_currentIndex >= _predicates.length) {
      _completer!.complete(true);
      return _completer!.future as Future<bool>;
    }

    if (_streamIsDone) {
      _completer!.complete(false);
      return _completer!.future as Future<bool>;
    }

    if (timeout != null) {
      _timer = Timer(timeout, () {
        if (!(_completer?.isCompleted ?? true)) {
          _completer!.complete(false);
        }
      });
    }

    return _completer!.future as Future<bool>;
  }

  /// Returns a list of reasons for the predicates that have not yet been matched.
  List<String> getPendingReasons() {
    if (_currentIndex >= _predicates.length) {
      return [];
    }
    return _predicates
        .sublist(_currentIndex)
        .map((p) => p.reason)
        .toList();
  }

  String _getTimeoutErrorMessage(Duration timeout) {
    final reason = _currentIndex < _predicates.length ? _predicates[_currentIndex].reason : '[no pending predicate]';
    return 'Timeout of ${timeout.inMilliseconds}ms expired before all expectations were met.\n'
        'Pending expectation at index $_currentIndex: $reason.\n'
        'Received events: ${recordedEvents.toString()}';
  }

  String _getStreamClosedErrorMessage() {
    final reason = _currentIndex < _predicates.length ? _predicates[_currentIndex].reason : '[no pending predicate]';
    return 'Stream closed before all expectations were met.\n'
        'Pending expectation at index $_currentIndex: $reason.\n'
        'Received events: ${recordedEvents.toString()}';
  }

  void _onData(T event) {
    recordedEvents.add(event);
    onData?.call(event);

    if (_currentIndex >= _predicates.length) {
      return; 
    }

    if (_predicates[_currentIndex].predicate(event)) {
      _currentIndex++;
      if (_currentIndex >= _predicates.length) {
        _complete(true);
      }
    }
  }

  void _onError(Object error, StackTrace stackTrace) {
    _streamIsDone = true;
    if (!(_completer?.isCompleted ?? true)) {
      _timer?.cancel();
      _completer!.completeError(error, stackTrace);
    }
  }

  void _onDone() {
    _streamIsDone = true;
    if (!(_completer?.isCompleted ?? true)) {
      _timer?.cancel();
      if (_completer is Completer<bool>) {
          _completer!.complete(false);
      } else {
          _completer!.completeError(TestFailure(_getStreamClosedErrorMessage()));
      }
    }
  }

  void _complete(bool success) {
      if (!(_completer?.isCompleted ?? true)) {
          _timer?.cancel();
          if (_completer is Completer<bool>) {
              _completer!.complete(success);
          } else {
              if (success) {
                  _completer!.complete();
              }
              // Errors are handled elsewhere
          }
      }
  }
}
