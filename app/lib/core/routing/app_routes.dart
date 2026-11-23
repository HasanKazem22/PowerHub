/// Every route path in one place. Use these instead of string literals.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';

  // Bottom-bar tabs.
  static const home = '/home';
  static const history = '/history';
  static const guide = '/guide';
  static const settings = '/settings';

  // Pushed on top of the tabs.
  static const backup = '/backup';
  static const calcPath = '/calc/:module';

  /// A calculator; with [projectId], that saved project opens in it.
  static String calc(String module, {String? projectId}) =>
      Uri(path: '/calc/$module', queryParameters: {'project': ?projectId}).toString();
}
