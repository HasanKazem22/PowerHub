// Source of web/drift_worker.js: the web worker that runs the database when
// PowerHub is previewed in a browser. Compiled from this project's own package
// versions so it always matches drift and sqlite3:
//
//   dart compile js -O4 tool/web/drift_worker.dart -o web/drift_worker.js
import 'package:drift/wasm.dart';

void main() => WasmDatabase.workerMainForOpen();
