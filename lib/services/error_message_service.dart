import 'dart:async';

class ErrorMessageService {
  final _errorController = StreamController<String>.broadcast();

  Stream<String> get errorStream => _errorController.stream;

  void showError(String message) {
    _errorController.add(message);
  }

  void dispose() {
    _errorController.close();
  }
}
