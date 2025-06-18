import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:caption_frontend/main.dart'; // make sure this path is correct

void main() {
  testWidgets('App loads and UI buttons are visible', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CaptionApp());

    // Check for UI elements
    expect(find.text('Select Video'), findsOneWidget);
    expect(find.text('Select Hinglish Script (.txt)'), findsOneWidget);
    expect(find.text('Generate Captions'), findsOneWidget);
  });
}
