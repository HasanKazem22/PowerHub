import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';

/// Where the database file lives on the phone: the app's documents folder,
/// `powerhub.sqlite`. Native only (the web preview keeps its data in the browser).
Future<String> databasePath() async {
  final dir = (await getApplicationDocumentsDirectory()).path;
  return '$dir/${AppConstants.databaseName}.sqlite';
}
