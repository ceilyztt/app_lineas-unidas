import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiUploadService {
  // Clave de API de ImgBB proporcionada por el usuario
  static const String _apiKey = "50b58710f91a22017c517e0d379cdc2e"; 

  static Future<String?> subirImagenAInternet(File imagenArchivo) async {
    try {
      var url = Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey');

      // Convertir la imagen a bytes y luego a formato Base64 para poder enviarla
      List<int> imageBytes = await imagenArchivo.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Hacer la petición POST al servidor de ImgBB
      var response = await http.post(url, body: {
        'image': base64Image,
      });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // Retorna la URL pública y directa de la imagen subida
        return data['data']['url'] as String; 
      } else {
        debugPrint("Error en el servidor ImgBB: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Error de conexión al subir imagen: $e");
      return null;
    }
  }
}
