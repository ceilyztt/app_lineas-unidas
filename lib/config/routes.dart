import 'package:flutter/material.dart';
// Autenticación
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/email_login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/client_welcome_screen.dart';
import '../screens/auth/driver_welcome_screen.dart';
import '../screens/auth/driver_requirements_screen.dart';
import '../screens/splash_screen.dart';
// Cliente
import '../screens/client/client_home_screen.dart';
import '../screens/client/ride_in_progress_screen.dart';
import '../screens/client/national_fares_screen.dart';
import '../screens/client/city_ride_screen.dart';
import '../screens/client/client_payment_screen.dart';
// Conductor
import '../screens/driver/driver_home_screen.dart';
import '../screens/driver/pending_screen.dart'; // IMPORTANTE
import '../screens/driver/driver_earnings_screen.dart';
// Administración
import '../screens/admin/admin_home_screen.dart'; // IMPORTANTE
// Otros
import '../screens/profile/client_profile_screen.dart';
import '../screens/profile/edit_client_profile_screen.dart';
import '../screens/profile/driver_profile_screen.dart';
import '../screens/profile/edit_driver_profile_screen.dart';
import '../screens/history/ride_history_screen.dart';
import '../screens/rating/rating_screen.dart';
import '../screens/directory/drivers_directory_screen.dart';
import '../screens/directory/driver_reviews_screen.dart';
import '../screens/chat/chat_screen.dart';

class AppRoutes {
  // Definición de nombres de rutas
  static const String splash = '/splash';
  static const String login = '/login';
  static const String emailLogin = '/login/email';
  static const String forgotPassword = '/login/forgot';
  static const String clientWelcome = '/client/welcome';
  static const String driverWelcome = '/driver/welcome';
  static const String driverRequirements = '/driver/requirements';
  static const String register = '/register';
  static const String clientHome = '/client/home';
  static const String driverHome = '/driver/home';
  static const String rideInProgress = '/ride/progress';
  static const String nationalFares = '/fares/national';
  static const String cityRide = '/ride/city';
  static const String clientProfile = '/profile/client';
  static const String driverProfile = '/profile/driver';
  static const String editClientProfile = '/profile/client/edit';
  static const String editDriverProfile = '/profile/driver/edit';
  static const String rideHistory = '/history';
  static const String rating = '/rating';
  static const String directory = '/directory';
  static const String driverReviews = '/driver-reviews';
  
  // Nuevas rutas para el proyecto de grado
  static const String driverPending = '/driverPending';
  static const String adminHome = '/admin/home';
  static const String chat = '/chat';
  static const String payment = '/payment';
  static const String driverEarnings = '/driver/earnings';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      emailLogin: (context) => const EmailLoginScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      clientWelcome: (context) => const ClientWelcomeScreen(),
      driverWelcome: (context) => const DriverWelcomeScreen(),
      driverRequirements: (context) => const DriverRequirementsScreen(),
      register: (context) => const RegisterScreen(),
      clientHome: (context) => const ClientHomeScreen(),
      driverHome: (context) => const DriverHomeScreen(),
      rideInProgress: (context) => const RideInProgressScreen(),
      nationalFares: (context) => const NationalFaresScreen(),
      cityRide: (context) => const CityRideScreen(),
      clientProfile: (context) => const ClientProfileScreen(),
      driverProfile: (context) => const DriverProfileScreen(),
      editClientProfile: (context) => const EditClientProfileScreen(),
      editDriverProfile: (context) => const EditDriverProfileScreen(),
      rideHistory: (context) => const RideHistoryScreen(),
      rating: (context) => const RatingScreen(),
      payment: (context) => const ClientPaymentScreen(),
      
      // Registro de las nuevas pantallas
      driverPending: (context) => const DriverPendingScreen(),
      adminHome: (context) => const AdminHomeScreen(),
      directory: (context) => const DriversDirectoryScreen(),
      driverReviews: (context) => const DriverReviewsScreen(),
      chat: (context) => const ChatScreen(),
      driverEarnings: (context) => const DriverEarningsScreen(),
    };
  }
}