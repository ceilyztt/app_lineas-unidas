import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/ride_provider.dart';
import 'providers/location_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/currency_provider.dart';

class LineasUnidasApp extends StatelessWidget {
  const LineasUnidasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],
      child: MaterialApp(
        title: 'Líneas Unidas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // Usamos las constantes definidas en AppRoutes
        initialRoute: AppRoutes.splash, 
        routes: AppRoutes.routes,
      ),
    );
  }
}