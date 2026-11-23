import '../domain/calc_module.dart';
import 'earthing_module.dart';
import 'load_module.dart';
import 'motor_module.dart';
import 'pf_module.dart';
import 'rewind_module.dart';
import 'solar_module.dart';
import 'substation_module.dart';

/// Every calculator, in the order Home and the "+" menu show them.
///
/// The web version's eleven tabs are seven here: Load, FDB, MDB and the
/// generator are one Building load calculator; Earthing and Busbar are one;
/// the Fault guide is a reference page, not a calculator.
final List<CalcModule> calcModules = [
  loadModule,
  substationModule,
  pfModule,
  solarModule,
  motorModule,
  rewindModule,
  earthingModule,
];

final Map<String, CalcModule> _byId = {for (final m in calcModules) m.id: m};

/// The calculator with [id], or null for an unknown id (a project from a newer app version).
CalcModule? calcModuleById(String id) => _byId[id];
