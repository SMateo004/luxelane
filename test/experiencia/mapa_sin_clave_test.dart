import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/widgets/lux_map.dart';

/// E27: sin clave de Maps la persona leía «Esta versión se compiló sin la
/// clave de Google Maps (GOOGLE_MAPS_KEY)».
void main() {
  testWidgets('texto neutro, sin detalles técnicos', (t) async {
    await t
        .pumpWidget(const MaterialApp(home: Scaffold(body: MapsKeyMissing())));
    expect(find.text('Mapa no disponible'), findsOneWidget);
    expect(find.textContaining('GOOGLE_MAPS_KEY'), findsNothing);
    expect(find.textContaining('compiló'), findsNothing);
  });
}
