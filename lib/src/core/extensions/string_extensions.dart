extension NullableStringX on String? {
  bool get isEmptyOrNull => this == null || this!.isEmpty;

  bool get isNotEmptyOrNull => !isEmptyOrNull;
}
