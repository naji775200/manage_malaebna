import 'package:equatable/equatable.dart';
import '../../presentation/screens/auth/login_screen.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  phoneNumberSubmitted,
  phoneVerificationSent,
  authenticated,
  error
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String phoneNumber;
  final String errorMessage;
  final bool isVerificationCodeSent;
  final String verificationId;
  final String userName;
  final String userId;
  final UserType userType;
  final bool isExistingAccount;

  const AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber = '',
    this.errorMessage = '',
    this.isVerificationCodeSent = false,
    this.verificationId = '',
    this.userName = '',
    this.userId = '',
    this.userType = UserType.owner,
    this.isExistingAccount = false,
  });

  bool get isInitial => status == AuthStatus.initial;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isPhoneNumberSubmitted => status == AuthStatus.phoneNumberSubmitted;
  bool get isPhoneVerificationSent =>
      status == AuthStatus.phoneVerificationSent;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isError => status == AuthStatus.error;

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? errorMessage,
    bool? isVerificationCodeSent,
    String? verificationId,
    String? userName,
    String? userId,
    UserType? userType,
    bool? isExistingAccount,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      errorMessage: errorMessage ?? this.errorMessage,
      isVerificationCodeSent:
          isVerificationCodeSent ?? this.isVerificationCodeSent,
      verificationId: verificationId ?? this.verificationId,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      isExistingAccount: isExistingAccount ?? this.isExistingAccount,
    );
  }

  @override
  List<Object?> get props => [
        status,
        phoneNumber,
        errorMessage,
        isVerificationCodeSent,
        verificationId,
        userName,
        userId,
        userType,
        isExistingAccount,
      ];
}
