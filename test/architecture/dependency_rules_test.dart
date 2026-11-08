import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Vérifie le sens des dépendances de la Clean Architecture
/// (docs/architecture.txt, section 4) en lisant les `import` de lib/.
///
///   presentation → domain ← data        app → tout        core ↛ app
void main() {
  final libDir = Directory('lib').absolute;
  final libUri = libDir.uri;

  /// Chemin relatif à lib/ de chaque fichier source (hors code généré).
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
      .toList();

  String rel(Uri uri) => uri.path.substring(libUri.path.length);

  /// Imports d'un fichier : paquets externes tels quels, fichiers du projet
  /// convertis en chemin relatif à lib/ (ex. « core/database/x.dart »).
  List<String> importsOf(File file) {
    final pattern = RegExp(r'''^(?:import|export)\s+['"]([^'"]+)['"]''');
    return file
        .readAsLinesSync()
        .map((line) => pattern.firstMatch(line.trim())?.group(1))
        .whereType<String>()
        .map((target) {
          const self = 'package:personnal_heath/';
          if (target.startsWith(self)) return target.substring(self.length);
          if (target.contains(':')) return target; // dart:, package:
          return rel(file.uri.resolve(target));
        })
        .toList();
  }

  final layerOf = RegExp(r'^features/[^/]+/(domain|data|presentation|di)/');

  /// Liste « fichier → import interdit » pour les fichiers ciblés.
  List<String> violations(
    bool Function(String path) appliesTo,
    bool Function(String import) forbidden,
  ) => [
    for (final file in files)
      if (appliesTo(rel(file.uri)))
        for (final import in importsOf(file))
          if (forbidden(import)) '${rel(file.uri)} → $import',
  ];

  bool inLayer(String path, String layer) =>
      layerOf.firstMatch(path)?.group(1) == layer;

  test('domain est du Dart pur et ne dépend que de domain', () {
    expect(
      violations(
        (p) => inLayer(p, 'domain'),
        (i) =>
            i.startsWith('package:') ||
            i == 'dart:ui' ||
            (!i.startsWith('dart:') && !inLayer(i, 'domain')),
      ),
      isEmpty,
    );
  });

  test('data ne dépend pas de presentation', () {
    expect(
      violations(
        (p) => inLayer(p, 'data'),
        (i) =>
            inLayer(i, 'presentation') ||
            i.startsWith('package:flutter/') ||
            i.startsWith('app/'),
      ),
      isEmpty,
    );
  });

  test('presentation ne touche ni data, ni Drift, ni la base', () {
    expect(
      violations(
        (p) => inLayer(p, 'presentation'),
        (i) =>
            inLayer(i, 'data') ||
            i.startsWith('core/database/') ||
            i.startsWith('package:drift') ||
            i.startsWith('package:supabase') ||
            i.startsWith('app/'),
      ),
      isEmpty,
    );
  });

  test('core ne dépend ni de app/ ni des couches data/presentation', () {
    expect(
      violations(
        (p) => p.startsWith('core/'),
        (i) =>
            i.startsWith('app/') ||
            inLayer(i, 'presentation') ||
            inLayer(i, 'data') ||
            inLayer(i, 'di'),
      ),
      isEmpty,
    );
  });
}
