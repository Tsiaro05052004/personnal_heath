import 'package:flutter_test/flutter_test.dart';
import 'package:personnal_heath/features/auth/domain/repositories/session_data.dart';
import 'package:personnal_heath/features/auth/domain/usecases/auth_usecases.dart';

import '../../helpers/fake_backend.dart';

/// Note si un compte était encore connecté au moment de l'effacement.
class _RecordingSessionData implements SessionData {
  _RecordingSessionData(this.auth);

  final FakeAuthRepository auth;
  bool? signedInDuringClear;

  @override
  Future<void> attachTo(String userId) async {}

  @override
  Future<bool> syncNow() async => true;

  @override
  Future<void> clear() async {
    signedInDuringClear = auth.currentUser != null;
  }
}

void main() {
  // Si le compte est encore connecté pendant l'effacement, la synchro
  // automatique peut re-télécharger les données sur le téléphone.
  test('déconnexion : la session est fermée avant l’effacement', () async {
    final auth = FakeAuthRepository(signedIn: FakeAuthRepository.hery);
    final data = _RecordingSessionData(auth);

    await SignOut(auth, data)();

    expect(data.signedInDuringClear, isFalse);
  });

  test(
    'suppression du compte : la session est fermée avant l’effacement',
    () async {
      final auth = FakeAuthRepository(signedIn: FakeAuthRepository.hery);
      final data = _RecordingSessionData(auth);

      await DeleteAccount(auth, data)();

      expect(data.signedInDuringClear, isFalse);
    },
  );
}
