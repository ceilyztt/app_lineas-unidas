import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';

class ClientWelcomeScreen extends StatefulWidget {
  const ClientWelcomeScreen({super.key});

  @override
  State<ClientWelcomeScreen> createState() => _ClientWelcomeScreenState();
}

class _ClientWelcomeScreenState extends State<ClientWelcomeScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Botón retroceder (opcional)
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            
            // Carrusel
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // Página 1: Instante (Usa la imagen generada)
                  _buildPage(
                    imagePath: 'assets/images/client_instant_ride.png',
                    icon: null,
                    title: 'Viajes al Instante',
                    description:
                        'Encuentra un conductor cercano y llega a tu destino sin demoras ni complicaciones.',
                    color: AppTheme.primaryColor,
                  ),
                  // Página 2: Seguridad
                  _buildPage(
                    imagePath: 'assets/images/client_security.png',
                    icon: null,
                    title: 'Seguridad Garantizada',
                    description:
                        'Todos nuestros conductores y vehículos están estrictamente verificados para tu completa tranquilidad.',
                    color: AppTheme.secondaryColor,
                  ),
                  // Página 3: Rastreo
                  _buildPage(
                    imagePath: 'assets/images/client_tracking.png',
                    icon: null,
                    title: 'Rastreo en Tiempo Real',
                    description:
                        'Sigue tu ruta exacta en el mapa y comparte tu ubicación en vivo con tus seres queridos.',
                    color: AppTheme.primaryColor,
                  ),
                  // Página 4: Tarifas
                  _buildPage(
                    imagePath: 'assets/images/client_fares.png',
                    icon: null,
                    title: 'Tarifas Transparentes',
                    description:
                        'Precios justos, regulados y transparentes. Conocerás el costo aproximado antes de iniciar cada viaje.',
                    color: AppTheme.secondaryColor,
                  ),
                ],
              ),
            ),
            
            // Puntos indicadores
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 10,
                  width: _currentPage == index ? 24 : 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryColor
                        : AppTheme.textGrey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Botones inferiores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentPage == 3
                    ? _buildActionButtons() // Mostrar botones en la última página
                    : SizedBox(
                        key: const ValueKey('next_btn'),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceColor,
                            foregroundColor: AppTheme.textWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('SIGUIENTE'),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    String? imagePath,
    IconData? icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(imagePath != null ? 4 : 32),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 2,
              )
            ),
            child: imagePath != null 
              ? ClipOval(
                  child: Image.asset(
                    imagePath,
                    height: 160,
                    width: 160,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  icon!,
                  size: 100,
                  color: color,
                ),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      key: const ValueKey('action_buttons'),
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: (_pulseAnimation.value - 1.0) * 15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.emailLogin, arguments: 'client');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryColor.withValues(alpha: (_pulseAnimation.value - 1.0) * 8),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.register, arguments: 'client');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryColor,
                    side: const BorderSide(color: AppTheme.secondaryColor, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('REGISTRARME COMO PASAJERO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
