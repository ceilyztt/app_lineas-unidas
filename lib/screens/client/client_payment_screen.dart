import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/ride_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/ride_model.dart';
import '../../models/driver_model.dart';
import '../../services/firestore_service.dart';

class ClientPaymentScreen extends StatefulWidget {
  const ClientPaymentScreen({super.key});

  @override
  State<ClientPaymentScreen> createState() => _ClientPaymentScreenState();
}

class _ClientPaymentScreenState extends State<ClientPaymentScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  String? _selectedMethod; // 'cash' or 'pago_movil'
  File? _selectedImage;
  bool _isScanning = false;
  bool _isUploading = false;

  // Form controllers for Pago Móvil
  final _bankController = TextEditingController();
  final _referenceController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void dispose() {
    _bankController.dispose();
    _referenceController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // --- OCR Extraction Methods ---
  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 60,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (photo == null) return;

      setState(() {
        _selectedImage = File(photo.path);
        _isScanning = true;
      });

      // Process OCR
      final inputImage = InputImage.fromFilePath(photo.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      final text = recognizedText.text;
      await textRecognizer.close();

      // Extract details
      final bank = _extractBank(text);
      final reference = _extractReference(text);
      final amount = _extractAmount(text);
      final date = _extractDate(text);

      setState(() {
        _bankController.text = bank ?? '';
        _referenceController.text = reference ?? '';
        _amountController.text = amount ?? '';
        _dateController.text = date ?? '';
        _isScanning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Captura procesada con éxito.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la imagen: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  String? _extractBank(String text) {
    final textLower = text.toLowerCase();
    
    // Check Venezuelan banks first
    if (textLower.contains('banesco')) return 'Banesco';
    if (textLower.contains('mercantil')) return 'Mercantil';
    if (textLower.contains('provincial') || textLower.contains('bbva')) return 'Provincial';
    if (textLower.contains('venezuela') || textLower.contains('bdv')) return 'Venezuela';
    if (textLower.contains('bnc') || textLower.contains('nacional de credito') || textLower.contains('nacional de crédito')) return 'BNC';
    if (textLower.contains('bancaribe')) return 'Bancaribe';
    if (textLower.contains('banplus')) return 'Banplus';
    if (textLower.contains('bfc') || textLower.contains('fondo comun') || textLower.contains('fondo común')) return 'BFC';
    if (textLower.contains('exterior')) return 'Exterior';
    if (textLower.contains('delsur')) return 'Delsur';
    if (textLower.contains('caroni') || textLower.contains('caroní')) return 'Caroní';
    if (textLower.contains('tesoro')) return 'Banco del Tesoro';
    if (textLower.contains('bicentenario')) return 'Bicentenario';
    if (textLower.contains('plaza')) return 'Banco Plaza';
    if (textLower.contains('activo')) return 'Banco Activo';
    
    // Fallback list search
    final banks = [
      'Banesco', 'Mercantil', 'Provincial', 'Venezuela', 'BNC', 'Bancaribe', 
      'Banplus', 'BFC', 'Exterior', 'Delsur', 'Caroni', 
      'Tesoro', 'Bicentenario', 'Plaza', 'Activo'
    ];
    for (final bank in banks) {
      if (textLower.contains(bank.toLowerCase())) {
        return bank;
      }
    }
    return null;
  }

  String? _extractReference(String text) {
    final lines = text.split('\n');
    
    // Look for lines containing keywords
    final keywords = ['ref', 'referencia', 'confirmacion', 'confirmación', 'recibo', 'operacion', 'operación', 'transaccion', 'transacción', 'aprobacion', 'aprobación', 'control', 'nro'];
    for (final line in lines) {
      final lineLower = line.toLowerCase();
      for (final kw in keywords) {
        if (lineLower.contains(kw)) {
          // Find the first sequence of 6-16 digits in this line
          final match = RegExp(r'\b\d{6,16}\b').firstMatch(line);
          if (match != null) {
            final val = match.group(0)!;
            // Check that it's not a Venezuelan phone number prefix
            if (!val.startsWith('0412') && !val.startsWith('0414') && !val.startsWith('0424') && !val.startsWith('0416') && !val.startsWith('0426')) {
              return val;
            }
          }
        }
      }
    }

    // Fallback 1: search the entire text for pattern-based references near keywords
    final patterns = [
      RegExp(r'(?:ref|referencia|confirmacion|confirmación|recibo|operacion|operación|transaccion|transacción|nro|aprobacion|aprobación)\s*:?\s*(\d{6,16})', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    // Fallback 2: find any 6-16 digit number that doesn't start with Venezuelan mobile phone prefixes or common DNI formats
    final allNumbers = RegExp(r'\b\d{6,16}\b').allMatches(text);
    for (final m in allNumbers) {
      final val = m.group(0)!;
      final isPhone = val.startsWith('0412') || val.startsWith('0414') || val.startsWith('0424') || val.startsWith('0416') || val.startsWith('0426') || val.startsWith('412') || val.startsWith('414') || val.startsWith('424') || val.startsWith('416') || val.startsWith('426') || val.startsWith('584');
      if (!isPhone) {
        return val;
      }
    }

    return null;
  }

  String? _extractAmount(String text) {
    final lines = text.split('\n');
    final keywords = ['monto', 'total', 'pagado', 'pagar', 'importe', 'monto recibido', 'monto de la operacion', 'monto de la operación', 'bs', 'bs.', '\$', 'usd'];
    
    // Pattern for numbers with 2 decimal places (handles thousands separators like 1.250,00 or 1,250.00)
    final decimalAmountPattern = RegExp(r'\b\d+(?:[\d.,]*\d+)?[\.,]\d{2}\b');

    // 1. Look for lines containing keywords
    for (final line in lines) {
      final lineLower = line.toLowerCase();
      
      // Check if line contains amount keywords
      bool hasKeyword = false;
      for (final kw in keywords) {
        if (lineLower.contains(kw)) {
          hasKeyword = true;
          break;
        }
      }
      
      if (hasKeyword) {
        // Try to find a number with 2 decimal places in this line first
        final match = decimalAmountPattern.firstMatch(line);
        if (match != null) {
          return _cleanAmount(match.group(0)!);
        }
        
        // If no 2-decimal number, look for any general number in the line (e.g., integer amount like "Monto: 150")
        final generalNumberPattern = RegExp(r'\b\d+(?:[\d.,]*\d+)?\b');
        final matches = generalNumberPattern.allMatches(line);
        for (final m in matches) {
          final val = m.group(0)!;
          // Filter out obvious reference numbers, phone numbers, or dates in the same line
          if (val.length < 10 && val != '0') {
            // Check if it's not a phone number prefix or a DNI
            if (!val.startsWith('0412') && !val.startsWith('0414') && !val.startsWith('0424') && !val.startsWith('0416') && !val.startsWith('0426')) {
              return _cleanAmount(val);
            }
          }
        }
      }
    }

    // 2. Fallback: Search the entire text for any number with 2 decimal places
    final match = decimalAmountPattern.firstMatch(text);
    if (match != null) {
      return _cleanAmount(match.group(0)!);
    }

    // 3. Last fallback: look for general amount pattern
    final patterns = [
      RegExp(r'(?:monto|importe|total|pagado|pagar)\s*:?\s*(?:bs\.?|usd|\$)?\s*([\d.,]+)', caseSensitive: false),
      RegExp(r'(?:bs\.?|usd|\$)\s*([\d.,]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountText = match.group(1) ?? match.group(0) ?? '';
        if (amountText.isNotEmpty && amountText.length < 10) {
          return _cleanAmount(amountText);
        }
      }
    }
    
    return null;
  }

  // Helper method to clean extra punctuation at the beginning/end of extracted amounts
  String _cleanAmount(String val) {
    String cleaned = val.trim();
    // Remove leading/trailing non-digit characters except for digits, dots, commas
    cleaned = cleaned.replaceAll(RegExp(r'^[^\d]+|[^\d]+$'), '');
    return cleaned;
  }

  String? _extractDate(String text) {
    final datePatterns = [
      // dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy
      RegExp(r'\b\d{2}[-/.]\d{2}[-/.]\d{4}\b'),
      // dd/mm/yy, dd-mm-yy, dd.mm.yy
      RegExp(r'\b\d{2}[-/.]\d{2}[-/.]\d{2}\b'),
      // yyyy/mm/dd, yyyy-mm-dd, yyyy.mm.dd
      RegExp(r'\b\d{4}[-/.]\d{2}[-/.]\d{2}\b'),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0);
      }
    }
    
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.toLowerCase().contains('fecha')) {
        for (final pattern in datePatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            return match.group(0);
          }
        }
      }
    }
    
    // Fallback to today's date
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
  }

  // --- Submit Payment ---
  Future<void> _submitCashPayment(String rideId) async {
    setState(() => _isUploading = true);
    try {
      await _firestoreService.updateRide(rideId, {
        'paymentMethod': 'cash',
        'paymentStatus': 'pending',
        'paymentDetails': {},
      });
      setState(() => _isUploading = false);
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar el pago: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _submitPagoMovil(String rideId) async {
    if (_bankController.text.trim().isEmpty ||
        _referenceController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty ||
        _dateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos del pago móvil.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona o toma una foto del capture de pago.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Sube capture de pantalla a Firebase Storage
      final imageUrl = await _firestoreService.uploadPaymentScreenshot(rideId, _selectedImage!);

      if (imageUrl == null) {
        throw 'No se pudo subir la captura del pago a Firebase Storage.';
      }

      final details = {
        'banco': _bankController.text.trim(),
        'referencia': _referenceController.text.trim(),
        'monto': 'Bs. ${_amountController.text.trim()}',
        'fecha': _dateController.text.trim(),
        'imagenUrl': imageUrl,
      };

      await _firestoreService.updateRide(rideId, {
        'paymentMethod': 'pago_movil',
        'paymentStatus': 'pending',
        'paymentDetails': details,
      });

      setState(() => _isUploading = false);
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pago móvil: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _cancelPaymentSubmission(String rideId) async {
    setState(() => _isUploading = true);
    try {
      await _firestoreService.updateRide(rideId, {
        'paymentMethod': null,
        'paymentStatus': null,
        'paymentDetails': null,
      });
      setState(() {
        _isUploading = false;
        _selectedMethod = null;
        _selectedImage = null;
        _bankController.clear();
        _referenceController.clear();
        _amountController.clear();
        _dateController.clear();
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final rideProvider = Provider.of<RideProvider>(context);
    final ride = rideProvider.currentRide;

    if (ride == null) {
      return const Scaffold(
        body: Center(
          child: Text('No hay información de viaje activa.'),
        ),
      );
    }

    // Auto-navigate to Rating when confirmed
    if (ride.paymentStatus == 'confirmed') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.rating, arguments: ride);
      });
    }

    final double fareUsd = ride.fare ?? 0.0;
    final double fareBs = fareUsd * currencyProvider.bcvRate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MÉTODO DE PAGO'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Resumen de Pago ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'TOTAL A PAGAR',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${fareUsd.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (currencyProvider.bcvRate > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Equivalente a Bs. ${fareBs.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tasa BCV: Bs. ${currencyProvider.bcvRate.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Flujo Reactivo de Estados ---
              if (ride.paymentStatus == 'pending') ...[
                _buildWaitingState(ride)
              ] else ...[
                if (ride.paymentStatus == 'rejected') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.errorRed, width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'El conductor rechazó el pago anterior. Por favor verifica los datos e intenta nuevamente.',
                            style: TextStyle(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (_selectedMethod == null) ...[
                  const Text(
                    'Selecciona cómo deseas pagar:',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Tarjeta Efectivo
                      Expanded(
                        child: _buildMethodCard(
                          title: 'Efectivo',
                          subtitle: 'Pago en mano',
                          icon: Icons.money,
                          color: Colors.green,
                          isSelected: false,
                          onTap: () {
                            setState(() => _selectedMethod = 'cash');
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Tarjeta Pago Móvil
                      Expanded(
                        child: _buildMethodCard(
                          title: 'Pago Móvil',
                          subtitle: 'Escanear captura',
                          icon: Icons.qr_code_scanner,
                          color: AppTheme.primaryColor,
                          isSelected: false,
                          onTap: () {
                            setState(() => _selectedMethod = 'pago_movil');
                          },
                        ),
                      ),
                    ],
                  ),
                ] else if (_selectedMethod == 'cash') ...[
                  _buildCashFlow(ride.rideId)
                ] else if (_selectedMethod == 'pago_movil') ...[
                  _buildPagoMovilFlow(ride)
                ]
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textGrey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlow(String rideId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _selectedMethod = null),
              icon: const Icon(Icons.arrow_back),
            ),
            const Text(
              'Pagar con Efectivo',
              style: TextStyle(
                color: AppTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Una vez entregues el dinero en efectivo al conductor, haz clic en el botón inferior para notificarle que ya realizaste el pago. El conductor deberá confirmarlo desde su aplicación.',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : () => _submitCashPayment(rideId),
            icon: _isUploading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textWhite),
                )
              : const Icon(Icons.check_circle_outline),
            label: const Text('CONFIRMAR ENVÍO DE PAGO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagoMovilFlow(RideModel ride) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _selectedMethod = null),
              icon: const Icon(Icons.arrow_back),
            ),
            const Text(
              'Pago Móvil (IA Escáner)',
              style: TextStyle(
                color: AppTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Datos de Pago Móvil del Conductor (En tiempo real desde Firestore) ---
        StreamBuilder<DriverModel?>(
          stream: _firestoreService.streamDriver(ride.driverId ?? ''),
          builder: (context, snapshot) {
            final driver = snapshot.data;
            final bank = driver?.bankName ?? 'Banesco';
            final phone = driver?.bankPhone ?? driver?.phone ?? '04121234567';
            final dni = driver?.bankDni ?? 'V-12345678';
            
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance, color: AppTheme.primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Datos de Pago Móvil del Conductor',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Banco:', bank),
                  _buildDetailRow('Teléfono:', phone),
                  _buildDetailRow('Cédula/RIF:', dni),
                ],
              ),
            );
          },
        ),

        if (_selectedImage == null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.textGrey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: AppTheme.textGrey,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sube la captura de tu transferencia de Pago Móvil para que la IA extraiga los datos automáticamente.',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickAndProcessImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _pickAndProcessImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Cámara'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          if (_isScanning) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 16),
                    Text(
                      'La Inteligencia Artificial está leyendo tu captura...',
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
            )
          ] else ...[
            // Formulario editable con datos extraídos
            const Text(
              'Confirma los datos leídos por la IA:',
              style: TextStyle(
                color: AppTheme.textWhite,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _bankController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Banco Emisor',
                prefixIcon: Icon(Icons.account_balance),
              ),
              style: const TextStyle(color: AppTheme.textWhite),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _referenceController,
              readOnly: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número de Referencia',
                prefixIcon: Icon(Icons.pin),
              ),
              style: const TextStyle(color: AppTheme.textWhite),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountController,
              readOnly: true,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Monto de Pago Móvil',
                prefixIcon: Icon(Icons.payments),
                prefixText: 'Bs. ',
                prefixStyle: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(color: AppTheme.textWhite),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Fecha de Operación',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              style: const TextStyle(color: AppTheme.textWhite),
            ),
            const SizedBox(height: 16),

            // Vista previa del capture
            const Text(
              'Captura cargada:',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botón para volver a intentar la imagen
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedImage = null),
                icon: const Icon(Icons.refresh, color: AppTheme.textGrey),
                label: const Text('Subir otra imagen', style: TextStyle(color: AppTheme.textGrey)),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : () => _submitPagoMovil(ride.rideId),
                icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textWhite),
                    )
                  : const Icon(Icons.send),
                label: const Text('ENVIAR DETALLES AL CONDUCTOR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ]
        ],
      ],
    );
  }

  Widget _buildWaitingState(RideModel ride) {
    final bool isPagoMovil = ride.paymentMethod == 'pago_movil';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Pulse Animation Placeholder
          const SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 4,
                ),
                Icon(
                  Icons.hourglass_empty,
                  color: AppTheme.primaryColor,
                  size: 36,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Verificando Pago',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPagoMovil
              ? 'Le hemos enviado la información y la captura al conductor. Por favor espera a que valide que el dinero llegó a su cuenta bancaria.'
              : 'Le hemos notificado al conductor que pagarás en efectivo. Por favor espera a que valide la recepción del dinero.',
            style: const TextStyle(
              color: AppTheme.textGrey,
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Mostrar detalles enviados
          if (isPagoMovil && ride.paymentDetails != null) ...[
            const Divider(color: AppTheme.cardColor),
            const SizedBox(height: 12),
            _buildDetailRow('Banco:', ride.paymentDetails!['banco'] ?? ''),
            _buildDetailRow('Referencia:', ride.paymentDetails!['referencia'] ?? ''),
            _buildDetailRow('Monto:', ride.paymentDetails!['monto'] ?? ''),
            _buildDetailRow('Fecha:', ride.paymentDetails!['fecha'] ?? ''),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _isUploading ? null : () => _cancelPaymentSubmission(ride.rideId),
            icon: const Icon(Icons.cancel, color: AppTheme.errorRed),
            label: const Text('CAMBIAR MÉTODO DE PAGO', style: TextStyle(color: AppTheme.errorRed)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.errorRed, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
