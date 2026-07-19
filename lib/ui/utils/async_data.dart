enum AsyncStatus {notStarted, loading, success, error}

class AsyncData<T> {

  final AsyncStatus status;
  final T? value;
  final String? error;

  AsyncData.success(T data):
    status = AsyncStatus.success,
    value = data,
    error = null;

  AsyncData.error(String data):
    status = AsyncStatus.error,
    value = null,
    error = data;

  AsyncData.loading():
    status = AsyncStatus.loading,
    value = null,
    error = null;

  AsyncData.notStarted():
    status = AsyncStatus.notStarted,
    value = null,
    error = null;
    
}