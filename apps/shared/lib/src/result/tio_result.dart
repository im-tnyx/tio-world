sealed class TioResult<T> {
  const TioResult();
}

class TioSuccess<T> extends TioResult<T> {
  const TioSuccess(this.value);

  final T value;
}

class TioFailure<T> extends TioResult<T> {
  const TioFailure(this.message, {this.code});

  final String message;
  final String? code;
}
