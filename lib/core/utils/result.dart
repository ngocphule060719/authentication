class Result<T> {}

class ErrorResult implements Result<Never> {
  final Object error;

  const ErrorResult(this.error);
}

class SuccessResult<T> implements Result<T> {
  final T data;

  const SuccessResult(this.data);
}
