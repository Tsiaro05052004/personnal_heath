import '../../domain/entities/auth_failure.dart';

extension AuthFailureLabel on AuthFailure {
  String get label => switch (this) {
    AuthFailure.invalidCredentials =>
      'Adresse e-mail ou mot de passe incorrect.',
    AuthFailure.emailAlreadyUsed =>
      'Un compte existe déjà avec cette adresse. Connectez-vous.',
    AuthFailure.weakPassword =>
      'Le mot de passe doit contenir au moins 8 caractères.',
    AuthFailure.invalidEmail => "Cette adresse e-mail n'est pas valide.",
    AuthFailure.invalidCode =>
      'Ce code est incorrect ou a expiré. Demandez-en un nouveau.',
    AuthFailure.tooManyAttempts =>
      'Trop de tentatives. Patientez quelques minutes puis réessayez.',
    AuthFailure.network =>
      'Pas de connexion Internet. Réessayez une fois connecté.',
    AuthFailure.unknown => 'Une erreur est survenue. Réessayez.',
  };
}
