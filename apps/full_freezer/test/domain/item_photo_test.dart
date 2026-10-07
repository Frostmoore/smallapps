import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/features/items/item_photo.dart';

/// F4.5b: la miniatura si ricava dal percorso della foto, con la convenzione di ImageStore.
void main() {
  test('la miniatura sta in images/thumbs/<bucket>/<stesso nome>', () {
    expect(thumbPathOf('images/items/abc.jpg'), 'images/thumbs/items/abc.jpg');
  });

  test('solo il primo "images/" diventa "images/thumbs/"', () {
    expect(thumbPathOf('images/items/images-1.jpg'), 'images/thumbs/items/images-1.jpg');
  });
}
