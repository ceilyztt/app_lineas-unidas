import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/national_fare_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/venezuela_data.dart';

class NationalFaresScreen extends StatefulWidget {
  const NationalFaresScreen({super.key});

  @override
  State<NationalFaresScreen> createState() => _NationalFaresScreenState();
}

class _NationalFaresScreenState extends State<NationalFaresScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<NationalFareModel> _fares = [];
  List<NationalFareModel> _filteredFares = [];
  bool _isLoading = true;
  String? _selectedState = 'Todos los destinos';
  String? _selectedCity = 'Todos los destinos';

  final List<String> _venezuelanStates = [
    'Todos los destinos',
    'Amazonas',
    'Anzoátegui',
    'Apure',
    'Aragua',
    'Bolívar',
    'Carabobo',
    'Cojedes',
    'Delta Amacuro',
    'Falcón',
    'Guárico',
    'Lara',
    'La Guaira',
    'Mérida',
    'Miranda',
    'Monagas',
    'Nueva Esparta',
    'Portuguesa',
    'Sucre',
    'Táchira',
    'Trujillo',
    'Yaracuy',
    'Zulia',
  ];

  @override
  void initState() {
    super.initState();
    _loadFares();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFares() async {
    final fares = await _firestoreService.getNationalFares();
    setState(() {
      _fares = fares;
      _filteredFares = fares;
      _isLoading = false;
    });
  }

                    void _filterFares(String? state, {String? city = 'Todos los destinos'}) {
    setState(() {
      _selectedState = state;
      _selectedCity = city;

      if (state == null || state == 'Todos los destinos') {
        _filteredFares = _fares;
      } else {
        _filteredFares = _fares.where((fare) {
          final dest = fare.destination.toLowerCase();
          final orig = fare.origin.toLowerCase();
          
          if (city != null && city != 'Todos los destinos') {
            return dest.contains(city.toLowerCase()) || orig.contains(city.toLowerCase());
          } else {
            // Check if matches the state name directly
            if (dest.contains(state.toLowerCase()) || orig.contains(state.toLowerCase())) {
              return true;
            }
            // Check if matches any known city of that state
            final stateCities = VenezuelaData.citiesByState[state] ?? [];
            for (var c in stateCities) {
              if (c == 'Todos los destinos') continue;
              if (dest.contains(c.toLowerCase()) || orig.contains(c.toLowerCase())) {
                return true;
              }
            }
            return false;
          }
        }).toList();
      }
    });
  }

  void _showStateSelectorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Pill indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 16, bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.textGrey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '¿Hacia dónde viajas?',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _venezuelanStates.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: AppTheme.surfaceColor,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final state = _venezuelanStates[index];
                    final isSelected = state == _selectedState;
                    final isAll = state == 'Todos los destinos';

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _filterFares(state, city: 'Todos los destinos');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.5) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isAll
                                    ? AppTheme.secondaryColor.withValues(alpha: 0.15)
                                    : AppTheme.surfaceColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAll ? Icons.map : Icons.location_city,
                                color: isAll ? AppTheme.secondaryColor : AppTheme.textGrey,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                state,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.primaryColor : AppTheme.textWhite,
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCitySelectorModal() {
    if (_selectedState == null || _selectedState == 'Todos los destinos') return;
    
    final cities = VenezuelaData.citiesByState[_selectedState!] ?? ['Todos los destinos'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Pill indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 16, bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.textGrey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Municipios de $_selectedState',
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: cities.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: AppTheme.surfaceColor,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final isSelected = city == _selectedCity;
                    final isAll = city == 'Todos los destinos';

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _filterFares(_selectedState, city: city);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.secondaryColor.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.secondaryColor.withValues(alpha: 0.5) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isAll
                                    ? AppTheme.primaryColor.withValues(alpha: 0.15)
                                    : AppTheme.surfaceColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAll ? Icons.map : Icons.holiday_village,
                                color: isAll ? AppTheme.primaryColor : AppTheme.textGrey,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                city,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.secondaryColor : AppTheme.textWhite,
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.secondaryColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Regresar al inicio',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            fontSize: 18,
            color: AppTheme.textWhite,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textWhite,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppTheme.secondaryColor.withValues(alpha: 0.3),
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
                        color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.explore,
                        color: AppTheme.secondaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '¿Cruzar fronteras?',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Te llevamos a cualquier estado del país con la confianza de cumplir con toda la normativa legal. Nuestros conductores te garantizan un viaje placentero en unidades modernas; porque tu única preocupación debe ser disfrutar el paisaje mientras nosotros nos encargamos del camino.',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
          // Selector de destino premium
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _showStateSelectorModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedState != 'Todos los destinos'
                        ? AppTheme.primaryColor.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Destino Nacional',
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedState ?? 'Selecciona un destino',
                            style: const TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textGrey,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Selector de Ciudad/Municipio premium
          if (_selectedState != null && _selectedState != 'Todos los destinos')
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
              child: GestureDetector(
                onTap: _showCitySelectorModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedCity != 'Todos los destinos'
                          ? AppTheme.secondaryColor.withValues(alpha: 0.5)
                          : Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.holiday_village,
                          color: AppTheme.secondaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Municipio en $_selectedState',
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedCity ?? 'Selecciona un municipio',
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
          const SizedBox(height: 16),



          // Lista de tarifas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : _filteredFares.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredFares.length,
                        itemBuilder: (context, index) {
                          final fare = _filteredFares[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.trip_origin,
                                              color: AppTheme.successGreen,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              fare.origin,
                                              style: const TextStyle(
                                                color: AppTheme.textWhite,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 7),
                                          child: Container(
                                            width: 2,
                                            height: 16,
                                            color: AppTheme.textGrey,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              color: AppTheme.errorRed,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              fare.destination,
                                              style: const TextStyle(
                                                color: AppTheme.textWhite,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (fare.description != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            fare.description!,
                                            style: const TextStyle(
                                              color: AppTheme.textGrey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '\$${fare.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
