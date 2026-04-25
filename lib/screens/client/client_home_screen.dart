import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMapView(),
          _buildHistoryPlaceholder(),
          _buildProfilePlaceholder(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.rideHistory);
            return;
          }
          if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.clientProfile);
            return;
          }
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Premium Superior
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 32,
                              width: 32,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Líneas Unidas',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return Text(
                                    '¡Hola, ${auth.userModel?.name ?? 'Pasajero'}! 👋',
                                    style: const TextStyle(
                                      color: AppTheme.textWhite,
                                      fontSize: 13,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.people_alt_outlined,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.directory);
                              },
                              tooltip: 'Directorio de Conductores',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pide un taxi seguro, rápido y confiable. Nosotros te llevamos a tu destino.',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Imagen del Equipo (Fuera del cuadro de saludo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/team_welcome.png',
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: AppTheme.primaryColor, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Guarda tu imagen como\nassets/images/team_welcome.png',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sección: ¿Qué necesitas hoy?
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Qué necesitas hoy?',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedServiceCard(
                          title: 'Moverme\nen la ciudad',
                          emoji: '🚕',
                          color: AppTheme.primaryColor,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.cityRide);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedServiceCard(
                          title: 'Salir\nde viaje',
                          emoji: '🧳',
                          color: AppTheme.secondaryColor,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.nationalFares);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        );
  }

  // _buildServiceCard was removed in favor of AnimatedServiceCard

  Widget _buildHistoryPlaceholder() =>
      const Center(child: Text('Historial'));

  Widget _buildProfilePlaceholder() =>
      const Center(child: Text('Perfil'));
}

class AnimatedServiceCard extends StatefulWidget {
  final String title;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const AnimatedServiceCard({
    super.key,
    required this.title,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  State<AnimatedServiceCard> createState() => _AnimatedServiceCardState();
}

class _AnimatedServiceCardState extends State<AnimatedServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calcula el color sólido de fondo interno basándose en el fondo oscuro
    final innerBackgroundColor = Color.alphaBlend(
      widget.color.withValues(alpha: 0.1),
      AppTheme.backgroundColor,
    );

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Capa de Luz Animada (Borde)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(color: widget.color.withValues(alpha: 0.1)),
                      Transform.scale(
                        scale: 3.5,
                        child: Transform.rotate(
                          angle: _controller.value * 2 * 3.141592653589793,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: SweepGradient(
                                colors: [
                                  Colors.transparent,
                                  widget.color.withValues(alpha: 0.2),
                                  widget.color,
                                  widget.color,
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Capa Interna (Mismo diseño existente pero ocultando el interior del gradiente giratorio)
          Container(
            margin: const EdgeInsets.all(1.5),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: innerBackgroundColor,
              borderRadius: BorderRadius.circular(14.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Ver opciones',
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 10, color: widget.color),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
