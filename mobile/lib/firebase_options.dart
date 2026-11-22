// Firebase settings for project finbridge-df94f (same content `flutterfire configure` writes).
// These keys only identify the project; access is controlled by Firestore security rules
// (backend/firestore.rules) and Firebase Authentication.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('FinBridge is set up for Android and web only.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDsJE9CLTuQ4u3LyQ8p94dO5Ypl2qZJ9gE',
    appId: '1:181381616183:web:3066246dda57067e9465b2',
    messagingSenderId: '181381616183',
    projectId: 'finbridge-df94f',
    authDomain: 'finbridge-df94f.firebaseapp.com',
    storageBucket: 'finbridge-df94f.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBBnaJuBWDqO55FMntVYhliVaFX1eWEwMc',
    appId: '1:181381616183:android:07545e8b51ac184a9465b2',
    messagingSenderId: '181381616183',
    projectId: 'finbridge-df94f',
    storageBucket: 'finbridge-df94f.firebasestorage.app',
  );
}
