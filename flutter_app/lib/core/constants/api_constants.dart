import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/models.dart';

class ApiConstants {
  static const String baseUrl = "http://10.153.88.212:8000";
  static const String login = "/auth/login";
  
  static const String signup             = '/auth/signup';
  static const String authMe             = '/auth/me';

  static const String users              = '/users';
  static const String userProfile        = '/users/profile';
  static const String uploadProfileImage = '/users/profile/image';

  static const String tasks              = '/tasks';
  static const String submissions        = '/submissions';

  static const String walletBalance      = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletTopup        = '/wallet/topup';
  static const String walletDeduct       = '/wallet/deduct';

  static const String dashboardAdmin     = '/dashboard/admin';
  static const String dashboardL1        = '/dashboard/l1';
}
