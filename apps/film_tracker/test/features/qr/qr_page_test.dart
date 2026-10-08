import 'package:film_tracker/features/qr/qr_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../photos/fake_photo_repo.dart';

/// F6.12: l'etichetta QR, bianca anche nel tema scuro.
void main() {
  testWidgets('mostra il QR, il numero e la pellicola su fondo bianco', (tester) async {
    await pumpWithFakeRepo(tester, const QrPage(rollId: 1), roll: testRoll(seq: 17, title: 'Praga'));
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.backgroundColor, Colors.white);
    expect(find.text('#17'), findsOneWidget);
    expect(find.text('Kodak Portra 400'), findsOneWidget);
    expect(find.text('Praga'), findsOneWidget);
    expect(qr.semanticsLabel, 'Codice QR del rullino 17');
  });

  testWidgets('rullino cancellato: lo dice invece di un QR vuoto', (tester) async {
    await pumpWithFakeRepo(tester, const QrPage(rollId: 99), roll: testRoll());
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Questo rullino non esiste più.'), findsOneWidget);
  });
}
