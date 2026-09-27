import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Almacenamiento local con Hive (equivalente a UserDefaults del Ejercicio 2).
///
/// La caja se guarda en "Application Support" y NO en Documents, para que sus
/// archivos internos (.hive / .lock) no aparezcan en el explorador de la app.
/// Solo guardamos tipos simples (String, bool, List<String>), así que no hace
/// falta generar TypeAdapters.
class HivePreferencesDataSource {
  HivePreferencesDataSource(this._box);

  static const boxName = 'gestor_archivos_prefs';

  final Box<dynamic> _box;

  static Future<HivePreferencesDataSource> open() async {
    final dir = await getApplicationSupportDirectory();
    Hive.init(dir.path);
    final box = await Hive.openBox<dynamic>(boxName);
    return HivePreferencesDataSource(box);
  }

  T? read<T>(String key) {
    final value = _box.get(key);
    return value is T ? value : null;
  }

  List<String> readStringList(String key) {
    final value = _box.get(key);
    if (value is List) return value.whereType<String>().toList();
    return <String>[];
  }

  Future<void> write(String key, Object? value) => _box.put(key, value);
}
