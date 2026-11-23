/// A calculator's inputs with typed getters that never throw: a missing or
/// unreadable value falls back to the calculator's default, then to 0 / ''.
///
/// Values are kept as JSON types (num, String, bool, List, Map) so they save
/// to History and back up as they are.
class CalcInputs {
  const CalcInputs(this.values, this.defaults);
  final Map<String, Object?> values;
  final Map<String, Object?> defaults;

  Object? raw(String key) => values.containsKey(key) ? values[key] : defaults[key];

  /// A number. Text is parsed ("1,250.5" works); anything else gives the default.
  double n(String key) => _num(values[key]) ?? _num(defaults[key]) ?? 0;

  /// A whole number (rounded).
  int i(String key) => n(key).round();

  String s(String key) => (values[key] ?? defaults[key] ?? '').toString();

  bool b(String key) => switch (raw(key)) {
    final bool v => v,
    final String v => v == 'yes' || v == 'true' || v == '1',
    final num v => v != 0,
    _ => false,
  };

  /// A list of objects (units, boards). Entries that are not objects are skipped.
  List<Map<String, Object?>> list(String key) {
    final v = raw(key);
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is Map) e.map((k, v) => MapEntry(k.toString(), v)),
    ];
  }

  /// All inputs with defaults filled in: what gets saved.
  Map<String, Object?> get merged => {...defaults, ...values};

  static double? _num(Object? v) => switch (v) {
    final num x when x.isFinite => x.toDouble(),
    final String x => double.tryParse(x.replaceAll(',', '').trim()),
    _ => null,
  };
}

/// Reads one entry of [CalcInputs.list] the same forgiving way.
extension CalcRow on Map<String, Object?> {
  double n(String key, [double fallback = 0]) => switch (this[key]) {
    final num x when x.isFinite => x.toDouble(),
    final String x => double.tryParse(x.replaceAll(',', '').trim()) ?? fallback,
    _ => fallback,
  };

  String s(String key, [String fallback = '']) => this[key]?.toString() ?? fallback;
}
