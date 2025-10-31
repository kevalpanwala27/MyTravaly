import 'package:flutter/material.dart';
import 'features/auth/presentation/sign_in_page.dart';
import 'features/hotels/presentation/home_page.dart';
import 'features/hotels/presentation/search_results_page.dart';
import 'features/splash/splash_page.dart';

class AppRouter {
  static const String splash = '/splash';
  static const String signIn = '/sign-in';
  static const String home = '/home';
  static const String results = '/results';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case signIn:
        return MaterialPageRoute(builder: (_) => const SignInPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case results:
        return MaterialPageRoute(builder: (_) => const SearchResultsPage());
      default:
        return MaterialPageRoute(builder: (_) => const SignInPage());
    }
  }
}
