import 'calc_result.dart';

/// Standard values and lookups shared by the calculators (the same tables as
/// the original PowerHub web calculator). Every list is sorted ascending.
abstract final class ElecTables {
  /// Standard breaker ratings (A).
  static const breakers = <double>[
    6, 10, 16, 20, 32, 40, 63, 80, 100, 125, 160, 200, 250, 300, 320, 400, 630, 800, 1000, 1250, 1600, 2000, //
    2500, 3200, 4000, 5000, 6300,
  ];

  /// ACB frame ratings (A).
  static const acb = <double>[630, 800, 1000, 1250, 1600, 2000, 2500, 3200, 4000, 5000, 6300];

  /// Breaker rating (A) → [main cable, earth wire] (mm², Cu), up to 400 A.
  static const cableByBreaker = <int, List<double>>{
    6: [2.5, 2.5], 10: [2.5, 2.5], 16: [2.5, 2.5], 20: [4, 4], 32: [6, 6], 40: [10, 10], 63: [16, 16], //
    80: [25, 16], 100: [35, 16], 125: [50, 25], 160: [70, 35], 200: [95, 50], 250: [120, 70], 300: [150, 70],
    320: [185, 95], 400: [240, 120],
  };

  /// Smallest cable used for a sub-main (mm²).
  static const minCable = 6.0;

  /// Standard cable sizes (mm²).
  static const cableSizes = <double>[1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300];

  /// Current rating (A) for each of [cableSizes], IEC 60364-5-52, method C, 30 °C.
  static const ratingPvc3 = <double>[17.5, 24, 32, 41, 57, 76, 96, 119, 144, 184, 223, 259, 299, 341, 403, 464];
  static const ratingXlpe3 = <double>[23, 31, 42, 54, 75, 100, 127, 158, 192, 246, 298, 346, 399, 456, 538, 621];
  static const ratingPvc1 = <double>[19.5, 27, 36, 46, 63, 85, 112, 138, 168, 213, 258, 299, 344, 392, 461, 530];
  static const ratingXlpe1 = <double>[24, 33, 45, 58, 80, 107, 138, 171, 209, 269, 328, 382, 441, 506, 599, 693];

  /// Ambient temperature correction (°C → factor), IEC 60364-5-52 Table B.52.14.
  static const ambientPvc = <List<double>>[
    [10, 1.22], [15, 1.17], [20, 1.12], [25, 1.06], [30, 1], [35, .94], [40, .87], [45, .79], [50, .71], //
    [55, .61], [60, .5],
  ];
  static const ambientXlpe = <List<double>>[
    [10, 1.15], [15, 1.12], [20, 1.08], [25, 1.04], [30, 1], [35, .96], [40, .91], [45, .87], [50, .82], //
    [55, .76], [60, .71],
  ];

  /// Grouping correction (circuits → factor), IEC 60364-5-52 Table B.52.17.
  static const grouping = <List<double>>[
    [1, 1], [2, .8], [3, .7], [4, .65], [5, .6], [6, .57], [7, .54], [8, .52], [9, .5], [12, .45], [16, .41], //
    [20, .38],
  ];

  /// CT primary ratings (A).
  static const ctPrimaries = <double>[
    10, 15, 20, 25, 30, 40, 50, 60, 75, 100, 125, 150, 175, 200, 250, 300, 400, 500, 600, 750, 800, 1000, //
    1250, 1500, 2000, 2500, 3000, 4000, 5000, 6000,
  ];

  /// LV breaking capacities Icu (kA).
  static const lvIcu = <double>[25, 36, 40, 50, 65, 85, 100];

  /// Copper busbar thicknesses and widths (mm).
  static const busThickness = <double>[3, 5, 6, 10, 12];
  static const busWidth = <double>[12, 15, 20, 25, 30, 40, 50, 60, 80, 100];

  /// Busbar current density used for sizing (A/mm²).
  static const busDensity = 1.6;

  /// The next standard breaker at or above [amps] (the largest if none is big enough).
  static double nextBreaker(double amps) => nextUp(breakers, amps) ?? breakers.last;

  /// Breaker family for a rating.
  static String breakerType(double a) => a <= 32
      ? 'MCB'
      : a <= 63
      ? 'MCB / MCCB'
      : a <= 250
      ? 'MCCB'
      : a <= 320
      ? 'MCCB / Adjustable'
      : a == 400
      ? 'MCCB / ACB'
      : 'ACB';

  /// [main cable, earth wire] for a breaker, as text ("35 mm²"); "Spec sheet" above 400 A.
  static ({String cable, String earth}) cablesFor(double breaker) {
    final c = cableByBreaker[breaker.round()];
    if (c == null) return (cable: 'Spec sheet', earth: 'Spec sheet');
    String mm(double v) => '${_trim(v < minCable ? minCable : v)} mm²';
    return (cable: mm(c[0]), earth: mm(c[1]));
  }

  /// The smallest standard bar (thickness × width) with area ≥ amps / 1.6, or null if none is big enough.
  static ({double area, double thickness, double width})? busbar(double amps) {
    final need = amps / busDensity;
    ({double area, double thickness, double width})? best;
    for (final t in busThickness) {
      for (final w in busWidth) {
        final a = t * w;
        if (a >= need && (best == null || a < best.area)) best = (area: a, thickness: t, width: w);
      }
    }
    return best;
  }

  /// "40 × 5 mm", or "Spec sheet" when no single bar is big enough.
  static String busbarText(double amps) {
    final b = busbar(amps);
    return b == null ? 'Spec sheet' : '${_trim(b.width)} × ${_trim(b.thickness)} mm';
  }

  /// Protective earth conductor for a phase conductor of [s] mm² (IEC 60364-5-54 Table 54.2).
  static double peFor(double s) => s <= 16
      ? s
      : s <= 35
      ? 16
      : (nextUp(cableSizes, s / 2) ?? cableSizes.last);

  static String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
}

/// "2.5", "16", "0.75": a number without a pointless ".0".
String num0(num v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
