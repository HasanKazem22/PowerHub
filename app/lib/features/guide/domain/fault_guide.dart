import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One fault: how it shows, how to find it, why it happens, what to do.
class Fault {
  const Fault({required this.title, required this.symptom, required this.check, required this.cause, required this.fix});

  factory Fault.fromJson(Map<String, dynamic> j) => Fault(
    title: j['title'] as String,
    symptom: j['symptom'] as String,
    check: j['check'] as String,
    cause: j['cause'] as String,
    fix: j['fix'] as String,
  );

  final String title, symptom, check, cause, fix;

  bool matches(String q) => '$title $symptom $check $cause $fix'.toLowerCase().contains(q);
}

/// The faults of one kind of equipment (motor, transformer, …).
class FaultGroup {
  const FaultGroup({required this.id, required this.name, required this.faults});

  factory FaultGroup.fromJson(Map<String, dynamic> j) => FaultGroup(
    id: j['id'] as String,
    name: j['name'] as String,
    faults: [for (final f in j['faults'] as List) Fault.fromJson(f as Map<String, dynamic>)],
  );

  final String id, name;
  final List<Fault> faults;
}

/// The fault-finding and safety guide (Bangla), from assets/data/faults.json.
class FaultGuide {
  const FaultGuide({required this.safety, required this.emergency, required this.tools, required this.groups});

  factory FaultGuide.fromJson(Map<String, dynamic> j) => FaultGuide(
    safety: [for (final s in j['safety'] as List) s as String],
    emergency: [for (final s in j['emergency'] as List) s as String],
    tools: j['tools'] as String,
    groups: [for (final g in j['groups'] as List) FaultGroup.fromJson(g as Map<String, dynamic>)],
  );

  /// The five safety rules, the steps for an emergency call-out, and the tools to carry.
  final List<String> safety, emergency;
  final String tools;
  final List<FaultGroup> groups;

  static Future<FaultGuide> load() async =>
      FaultGuide.fromJson(jsonDecode(await rootBundle.loadString('assets/data/faults.json')) as Map<String, dynamic>);
}

final faultGuideProvider = FutureProvider<FaultGuide>((ref) => FaultGuide.load());
