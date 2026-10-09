/// Lo stile di un QR: colori, forme, logo (develop_microapps.md F17.1.3). Pro
/// (`FeatureKey.themeCustomization`), salvo [QrStyle.plain].
///
/// ⚑ Dart puro: `QrStyle` vive nella colonna `style_json` e nei backup, e deve potersi leggere
/// e scrivere nei test senza Flutter. I colori sono quindi `int` ARGB e non `Color`; la
/// traduzione in parametri di qr_flutter la fa un solo punto, `QrRenderer` (F17.1.7).
library;

import 'package:characters/characters.dart';

/// La forma dei moduli di dati.
enum QrModuleShape { square, circle }

/// La forma dei tre "occhi" (i quadrati di posizionamento negli angoli).
enum QrEyeShape { square, circle }

/// Gli id del catalogo delle icone pronte per il logo, **stabili**.
///
/// ⚑ Un id testuale e non il `codePoint` dell'icona Material: i codePoint cambiano fra versioni
/// dei font di Flutter, e un preferito salvato mostrerebbe un'altra icona dopo un
/// aggiornamento. L'id -> `IconData` sta in `lib/features/style/logo_picker.dart`
/// (`kLogoIcons`, F17.4), che deve avere **esattamente** queste chiavi.
/// ☠ Un id pubblicato non si toglie e non si rinomina: e' gia' nei database e nei backup.
const List<String> kLogoIconIds = [
  'wifi', 'phone', 'email', 'sms', 'home', 'work', 'heart', 'star', 'shop', 'restaurant', //
  'coffee', 'music', 'camera', 'link', 'person', 'group', 'event', 'location', 'car', 'pets', //
  'school', 'info', 'gift', 'payment',
];

/// Il logo al centro del QR.
sealed class QrLogo {
  const QrLogo();

  Map<String, Object?>? toJson();

  /// Tollerante: un logo sconosciuto o rotto diventa [NoLogo] (meglio un QR senza logo che una
  /// pagina che non si apre).
  static QrLogo fromJson(Object? json) {
    if (json is! Map) return const NoLogo();
    return switch (json['type']) {
      'photo' => switch (json['image']) {
        final String name when name.isNotEmpty => PhotoLogo(imageName: name, round: json['round'] == true),
        _ => const NoLogo(),
      },
      'icon' => switch (json['id']) {
        final String id when id.isNotEmpty => IconLogo(id),
        _ => const NoLogo(),
      },
      'text' => switch (json['text']) {
        final String t when TextLogo.isValidText(t) => TextLogo(t),
        _ => const NoLogo(),
      },
      _ => const NoLogo(),
    };
  }
}

final class NoLogo extends QrLogo {
  const NoLogo();

  @override
  Map<String, Object?>? toJson() => null;

  @override
  bool operator ==(Object other) => other is NoLogo;

  @override
  int get hashCode => (NoLogo).hashCode;
}

/// Una foto della galleria, gia' ritagliata a 512 px e salvata in `ImageStore`.
final class PhotoLogo extends QrLogo {
  const PhotoLogo({required this.imageName, this.round = false});

  /// Il percorso **relativo** in `ImageStore` (`images/logos/<uuid>.jpg`): lo stesso che
  /// `StoredImage.path`. La miniatura sta in `images/thumbs/logos/<uuid>.jpg` (vedi
  /// `QrLogoFiles` in lib/data/qr_repository.dart).
  final String imageName;

  /// Ritaglio rotondo invece che quadrato.
  final bool round;

  @override
  Map<String, Object?> toJson() => {'type': 'photo', 'image': imageName, 'round': round};

  @override
  bool operator ==(Object other) => other is PhotoLogo && other.imageName == imageName && other.round == round;

  @override
  int get hashCode => Object.hash('photo', imageName, round);
}

/// Un'icona pronta del catalogo, per id stabile (vedi [kLogoIconIds]).
final class IconLogo extends QrLogo {
  const IconLogo(this.iconId);

  final String iconId;

  @override
  Map<String, Object?> toJson() => {'type': 'icon', 'id': iconId};

  @override
  bool operator ==(Object other) => other is IconLogo && other.iconId == iconId;

  @override
  int get hashCode => Object.hash('icon', iconId);
}

/// Un'emoji o un testo corto: 1..3 grafemi.
final class TextLogo extends QrLogo {
  const TextLogo(this.text);

  final String text;

  static const int maxGraphemes = 3;

  /// 1..3 grafemi come li vede una persona (`characters`): una bandiera o una famiglia di
  /// emoji (piu' code point uniti) contano uno. ⚑ `String.length` conterebbe i code unit UTF-16
  /// e una sola bandiera sembrerebbe gia' "troppo lunga".
  static bool isValidText(String text) {
    final n = text.trim().characters.length;
    return n >= 1 && n <= maxGraphemes;
  }

  @override
  Map<String, Object?> toJson() => {'type': 'text', 'text': text};

  @override
  bool operator ==(Object other) => other is TextLogo && other.text == text;

  @override
  int get hashCode => Object.hash('text', text);
}

final class QrStyle {
  const QrStyle({
    this.foreground = 0xFF000000,
    this.background = 0xFFFFFFFF,
    this.moduleShape = QrModuleShape.square,
    this.eyeShape = QrEyeShape.square,
    this.logo = const NoLogo(),
  });

  /// Nero su bianco, quadrati, senza logo: lo stile gratuito.
  static const QrStyle plain = QrStyle();

  /// ARGB del primo piano (moduli e occhi).
  final int foreground;

  /// ARGB dello sfondo, anche della zona di rispetto: mai trasparente.
  final int background;
  final QrModuleShape moduleShape;
  final QrEyeShape eyeShape;
  final QrLogo logo;

  /// Uguale a [plain]: nessun Pro coinvolto, `style_json` null.
  bool get isPlain => this == plain;

  bool get hasLogo => logo is! NoLogo;

  QrStyle copyWith({
    int? foreground,
    int? background,
    QrModuleShape? moduleShape,
    QrEyeShape? eyeShape,
    QrLogo? logo,
  }) => QrStyle(
    foreground: foreground ?? this.foreground,
    background: background ?? this.background,
    moduleShape: moduleShape ?? this.moduleShape,
    eyeShape: eyeShape ?? this.eyeShape,
    logo: logo ?? this.logo,
  );

  /// Chiavi corte e stabili: e' il contenuto di `style_json` e dei backup.
  /// ☠ Le chiavi non si rinominano: i dati salvati le hanno gia'.
  Map<String, Object?> toJson() => {
    'fg': foreground,
    'bg': background,
    'module': moduleShape.name,
    'eye': eyeShape.name,
    if (logo.toJson() case final l?) 'logo': l,
  };

  /// Tollerante: chiavi sconosciute ignorate, mancanti o del tipo sbagliato = default. ⚑ Uno
  /// stile scritto da una versione futura (una forma nuova) si apre con la forma di default
  /// invece di non aprirsi: il contenuto del QR, che e' cio' che conta, resta intatto.
  static QrStyle fromJson(Map<String, Object?> json) {
    int color(Object? v, int fallback) => v is num ? v.toInt() & 0xFFFFFFFF : fallback;
    return QrStyle(
      foreground: color(json['fg'], plain.foreground),
      background: color(json['bg'], plain.background),
      moduleShape: QrModuleShape.values.asNameMap()[json['module']] ?? plain.moduleShape,
      eyeShape: QrEyeShape.values.asNameMap()[json['eye']] ?? plain.eyeShape,
      logo: QrLogo.fromJson(json['logo']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QrStyle &&
      other.foreground == foreground &&
      other.background == background &&
      other.moduleShape == moduleShape &&
      other.eyeShape == eyeShape &&
      other.logo == logo;

  @override
  int get hashCode => Object.hash(foreground, background, moduleShape, eyeShape, logo);

  @override
  String toString() =>
      'QrStyle(fg: ${foreground.toRadixString(16)}, bg: ${background.toRadixString(16)}, '
      '${moduleShape.name}/${eyeShape.name}, logo: ${logo.runtimeType})';
}
