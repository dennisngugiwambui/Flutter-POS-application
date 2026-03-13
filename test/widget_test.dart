// Basic Flutter widget test for Pixel POS.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/main.dart';

void main() {
  testWidgets('App loads and shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PosApp(),
      ),
    );

    expect(find.text('LOGIN'), findsOneWidget);
  });
}
