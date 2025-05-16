import 'package:equatable/equatable.dart';
import '../../presentation/screens/auth/login_screen.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthInitialEvent extends AuthEvent {
  const AuthInitialEvent();
}

class AuthNavigateToLoginEvent extends AuthEvent {
  const AuthNavigateToLoginEvent();
}

class AuthPhoneNumberSubmitted extends AuthEvent {
  final String phoneNumber;
  final String name;
  final UserType userType;

  const AuthPhoneNumberSubmitted(
    this.phoneNumber, {
    required this.name,
    required this.userType,
  });

  @override
  List<Object?> get props => [phoneNumber, name, userType];
}

class AuthVerificationCodeSubmitted extends AuthEvent {
  final String verificationCode;

  const AuthVerificationCodeSubmitted(this.verificationCode);

  @override
  List<Object?> get props => [verificationCode];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthVerifyPhoneNumber extends AuthEvent {
  const AuthVerifyPhoneNumber();
}

class AuthCodeResendRequested extends AuthEvent {
  const AuthCodeResendRequested();
}

class AuthCheckLoginStatusEvent extends AuthEvent {
  const AuthCheckLoginStatusEvent();
}
