/// Base interface for all Mage-chan modules/plugins.
/// Every new feature should implement this interface to be registered in the system.
abstract class MagePlugin {
  /// Unique identifier for the plugin
  String get id;

  /// Human-readable name of the plugin
  String get name;

  /// Initialize the plugin (e.g., set up event listeners, load initial data)
  Future<void> initialize();

  /// Dispose the plugin when the app is terminating or plugin is disabled
  Future<void> dispose();
}

/// Plugin Manager to register and manage all available plugins
class PluginManager {
  static final PluginManager _instance = PluginManager._internal();

  factory PluginManager() {
    return _instance;
  }

  PluginManager._internal();

  final Map<String, MagePlugin> _plugins = {};

  /// Register a new plugin
  void registerPlugin(MagePlugin plugin) {
    if (!_plugins.containsKey(plugin.id)) {
      _plugins[plugin.id] = plugin;
    }
  }

  /// Initialize all registered plugins
  Future<void> initializeAll() async {
    for (final plugin in _plugins.values) {
      await plugin.initialize();
    }
  }

  /// Get a specific plugin by ID
  MagePlugin? getPlugin(String id) {
    return _plugins[id];
  }

  /// Dispose all plugins
  Future<void> disposeAll() async {
    for (final plugin in _plugins.values) {
      await plugin.dispose();
    }
    _plugins.clear();
  }
}
