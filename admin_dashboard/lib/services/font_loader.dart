import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AppFontLoader {
  static bool _fontsLoaded = false;
  
  static Future<void> loadFonts() async {
    if (_fontsLoaded) return;
    
    try {
      // Try to load Material Icons font
      await rootBundle.load('packages/flutter/material_icons.ttf');
      if (kDebugMode) {
        print('✅ Material Icons font loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Material Icons font not found, using fallback: $e');
      }
    }
    
    try {
      // Try to load other common fonts
      final fontPaths = [
        'packages/flutter/noto_sans_regular.ttf',
        'packages/flutter/noto_color_emoji.ttf',
      ];
      
      for (String fontPath in fontPaths) {
        try {
          await rootBundle.load(fontPath);
          if (kDebugMode) {
            print('✅ Font loaded: $fontPath');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Font not found: $fontPath');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error loading fonts: $e');
      }
    }
    
    _fontsLoaded = true;
  }
}
