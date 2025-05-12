import 'package:authentication/core/utils/result.dart';

class ResultResolver<T> {
  Result<T> resolve(final T Function() block) {
    try {
      return SuccessResult(block());
    } catch (e) {
      return ErrorResult(e);
    }
  }
}
