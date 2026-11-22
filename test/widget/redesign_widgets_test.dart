import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunikos/core/theme.dart';
import 'package:hunikos/models/property.dart';
import 'package:hunikos/widgets/price_text.dart';
import 'package:hunikos/widgets/property_card.dart';
import 'package:hunikos/widgets/property_map.dart';

// Uji sementara: memastikan widget baru benar-benar terbangun saat runtime,
// bukan hanya lolos analyzer.
PropertyItem _property() => const PropertyItem(
      id: 'p1',
      name: 'Kos Putri Anggrek',
      city: 'Yogyakarta',
      address: 'Jl. Anggrek No. 5',
      propertyType: 'putri',
      availableRooms: 2,
      totalRooms: 3,
      minPrice: 750000,
    );

void main() {
  testWidgets('kartu properti tampil dengan harga', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: SingleChildScrollView(child: PropertyCard(property: _property())),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Kos Putri Anggrek'), findsOneWidget);
    expect(find.text('Kos Putri'), findsOneWidget);
    expect(find.textContaining('Yogyakarta'), findsOneWidget);
    // Harga digambar sebagai RichText, bukan Text biasa.
    expect(find.byType(PriceText), findsOneWidget);
    final price = tester.widget<RichText>(find.byType(RichText).last);
    expect(price.text.toPlainText(), contains('Rp'));
  });

  testWidgets('peta lokasi terbangun tanpa error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: PropertyMap(latitude: -7.7712, longitude: 110.4012),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PropertyMap), findsOneWidget);
    expect(find.text('© OpenStreetMap'), findsOneWidget);
  });
}
