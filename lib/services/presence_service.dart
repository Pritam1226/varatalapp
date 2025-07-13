import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// Tracks foreground / background and updates `isOnline` + `lastSeen`
/// in the **users/{uid}** document.
class PresenceService with WidgetsBindingObserver {
  PresenceService._();               // private ctor
  static final PresenceService _i = PresenceService._();
  factory PresenceService() => _i;   // singleton

  //--------------------------------------------------------------------
  // Call once **after** a successful login
  //--------------------------------------------------------------------
  void start() {
    WidgetsBinding.instance.addObserver(this);
    _setOnline(true);
  }

  /// Call when the user logs out
  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnline(false);
  }

  //--------------------------------------------------------------------
  // WidgetsBindingObserver
  //--------------------------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnline(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setOnline(false);
    }
  }

  //--------------------------------------------------------------------
  // Firestore write helper
  //--------------------------------------------------------------------
  Future<void> _setOnline(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isOnline': value,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
