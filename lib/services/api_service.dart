import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://mern-back-emprunt-matos.vercel.app/api";

  // Récupérer les personnes
  static Future<List<dynamic>> getPersons() async {
    final response = await http.get(Uri.parse('$baseUrl/persons'));
    return json.decode(response.body);
  }

  // Récupérer le matériel disponible
  static Future<List<dynamic>> getMaterials() async {
    final response = await http.get(Uri.parse('$baseUrl/materials'));
    List<dynamic> all = json.decode(response.body);
    return all.where((m) => m['disponible'] == true).toList();
  }

  // Créer un emprunt
 static Future<List<dynamic>> getBorrowings() async {
  final response = await http.get(Uri.parse('$baseUrl/borrowings'));
  return json.decode(response.body);
}

static Future<bool> addBorrowing(String personId, String materialId, int days, DateTime startDate) async {
  final response = await http.post(
    Uri.parse('$baseUrl/borrowings/add'),
    headers: {"Content-Type": "application/json"},
    body: json.encode({
      "personId": personId,
      "materialId": materialId,
      "dureeJours": days,
      "dateEmprunt": startDate.toIso8601String(), // Envoi de la date choisie
    }),
  );
  return response.statusCode == 201;
}
}