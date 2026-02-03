import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? selectedPersonId;
  List<dynamic> persons = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    var p = await ApiService.getPersons();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      persons = p;
      selectedPersonId = prefs.getString('savedPersonId');
    });
  }

  _savePerson(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedPersonId', id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Utilisateur configuré !")));
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    // CHANGEZ CETTE LIGNE : remplacez app_bar par appBar
    appBar: AppBar(
      title: const Text("Réglages"),
      backgroundColor: Colors.blue, // Optionnel : pour la couleur
    ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Qui utilise cette application ?", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            isExpanded: true,
            value: selectedPersonId,
            hint: const Text("Sélectionner une personne"),
            items: persons.map((p) {
              return DropdownMenuItem(
                value: p['_id'].toString(), 
                child: Text("${p['nom']} ${p['prenom']}")
              );
            }).toList(),
            onChanged: (val) {
              setState(() => selectedPersonId = val);
              if (val != null) _savePerson(val);
            },
          ),
        ],
      ),
    ),
  );
}
}
