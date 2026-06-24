import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/ride_model.dart';
import '../../providers/currency_provider.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverId = Provider.of<AuthProvider>(context, listen: false).driverModel?.uid;
    final bcvRate = Provider.of<CurrencyProvider>(context).bcvRate;
    
    if (driverId == null) {
      return const Scaffold(body: Center(child: Text("Error: No se encontró el conductor")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Ganancias'),
        elevation: 0,
        backgroundColor: AppTheme.backgroundColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: StreamBuilder<List<RideModel>>(
        stream: FirestoreService().streamDriverEarnings(driverId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Ocurrió un error al cargar las ganancias", style: TextStyle(color: AppTheme.errorRed)));
          }
          
          final rides = snapshot.data ?? [];
          
          // Ordenar viajes localmente en memoria (del más reciente al más antiguo)
          rides.sort((a, b) {
            final aDate = a.completedAt ?? a.createdAt;
            final bDate = b.completedAt ?? b.createdAt;
            return bDate.compareTo(aDate);
          });
          
          // Calcular sumatorias y agrupar por día
          double gananciaTotal = 0.0;
          double gananciaHoy = 0.0;
          final int viajesCompletados = rides.length;
          
          final hoy = DateTime.now();
          final fechaHoy = DateTime(hoy.year, hoy.month, hoy.day);
          
          // Agrupar viajes por fecha (sin hora)
          final Map<DateTime, List<RideModel>> viajesAgrupados = {};

          for (var ride in rides) {
            final double fare = ride.fare ?? 0.0;
            gananciaTotal += fare;
            
            final date = ride.completedAt ?? ride.createdAt;
            final fechaLimpia = DateTime(date.year, date.month, date.day);
            
            if (fechaLimpia == fechaHoy) {
              gananciaHoy += fare;
            }
            
            if (!viajesAgrupados.containsKey(fechaLimpia)) {
              viajesAgrupados[fechaLimpia] = [];
            }
            viajesAgrupados[fechaLimpia]!.add(ride);
          }

          // Ordenar las fechas de la más reciente a la más antigua
          final fechasOrdenadas = viajesAgrupados.keys.toList()..sort((a, b) => b.compareTo(a));

          return CustomScrollView(
            slivers: [
              // Dashboard superior
              SliverToBoxAdapter(
                child: _buildDashboard(gananciaHoy, gananciaTotal, viajesCompletados, bcvRate),
              ),
              
              // Título de Historial
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Text(
                    'HISTORIAL DIARIO',
                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ),

              // Lista agrupada
              if (fechasOrdenadas.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        "Aún no tienes viajes completados.",
                        style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final fecha = fechasOrdenadas[index];
                      final viajesDelDia = viajesAgrupados[fecha]!;
                      return _buildDiaCard(fecha, viajesDelDia, fechaHoy, bcvRate);
                    },
                    childCount: fechasOrdenadas.length,
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboard(double gananciaHoy, double gananciaTotal, int totalViajes, double bcvRate) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'GANANCIAS DE HOY',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${gananciaHoy.toStringAsFixed(2)}\n${(gananciaHoy * bcvRate).toStringAsFixed(2)} Bs',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEstatuto('TOTAL HISTÓRICO', '\$${gananciaTotal.toStringAsFixed(2)}\n${(gananciaTotal * bcvRate).toStringAsFixed(2)} Bs'),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildEstatuto('VIAJES COMPLETOS', totalViajes.toString()),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEstatuto(String titulo, String valor) {
    return Column(
      children: [
        Text(titulo, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(valor, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDiaCard(DateTime fecha, List<RideModel> viajes, DateTime fechaHoy, double bcvRate) {
    // Calcular ganancia de ese día
    double gananciaDia = viajes.fold(0.0, (sum, ride) => sum + (ride.fare ?? 0.0));
    
    String tituloFecha;
    if (fecha == fechaHoy) {
      tituloFecha = "Hoy";
    } else if (fecha == fechaHoy.subtract(const Duration(days: 1))) {
      tituloFecha = "Ayer";
    } else {
      tituloFecha = DateFormat('dd/MM/yyyy').format(fecha);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardColor),
      ),
      child: ExpansionTile(
        iconColor: AppTheme.primaryColor,
        collapsedIconColor: AppTheme.textGrey,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tituloFecha,
              style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '+\$${gananciaDia.toStringAsFixed(2)}\n+${(gananciaDia * bcvRate).toStringAsFixed(2)} Bs',
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        subtitle: Text('${viajes.length} viaje(s)', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        children: viajes.map((ride) => _buildViajeDetalle(ride, bcvRate)).toList(),
      ),
    );
  }

  Widget _buildViajeDetalle(RideModel ride, double bcvRate) {
    final hora = ride.completedAt != null ? DateFormat('hh:mm a').format(ride.completedAt!) : '--:--';
    final double fareUsd = ride.fare ?? 0.0;
    final double fareBs = fareUsd * bcvRate;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.cardColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.pickupAddress,
                  style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Completado a las $hora',
                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${fareUsd.toStringAsFixed(2)}\n${fareBs.toStringAsFixed(2)} Bs',
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
