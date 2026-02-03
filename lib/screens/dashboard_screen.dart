import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? selectedMaterialId;
  String? currentPersonId;
  List<dynamic> materials = [];
  List<dynamic> borrowings = [];
  DateTime selectedDate = DateTime.now();
  final TextEditingController _daysController = TextEditingController(text: "7");

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  _refresh() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var m = await ApiService.getMaterials();
    var b = await ApiService.getBorrowings();
    setState(() {
      currentPersonId = prefs.getString('savedPersonId');
      materials = m;
      borrowings = b;
    });
  }

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  _submitBorrow() async {
    if (currentPersonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Configurez la personne dans Réglages !")));
      return;
    }
    bool success = await ApiService.addBorrowing(
      currentPersonId!, 
      selectedMaterialId!, 
      int.parse(_daysController.text),
      selectedDate
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Emprunt réussi !")));
      setState(() => selectedMaterialId = null);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Emprunts"), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)
      ]),
      body: Column(
        children: [
          // PARTIE HAUTE : FORMULAIRE
          Padding(
            padding: const EdgeInsets.all(15),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Choisir le matériel"),
                      value: selectedMaterialId,
                      items: materials.map((m) => DropdownMenuItem(value: m['_id'].toString(), child: Text(m['libelle']))).toList(),
                      onChanged: (val) => setState(() => selectedMaterialId = val),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _daysController,
                            decoration: const InputDecoration(labelText: "Durée (jours)", icon: Icon(Icons.timer)),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today),
                          label: Text("${selectedDate.day}/${selectedDate.month}"),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: selectedMaterialId == null ? null : _submitBorrow,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45), backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      child: const Text("VALIDER L'EMPRUNT"),
                    )
                  ],
                ),
              ),
            ),
          ),
          
          const Divider(),
          const Text("Historique des emprunts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          
          // PARTIE BASSE : LISTE
          Expanded(
            child: ListView.builder(
              itemCount: borrowings.length,
              itemBuilder: (context, index) {
                var b = borrowings[index];
                return ListTile(
                  leading: Icon(b['estRendu'] ? Icons.check_circle : Icons.pending, color: b['estRendu'] ? Colors.green : Colors.orange),
                  title: Text("${b['materialId']['libelle']}"),
                  subtitle: Text("Par: ${b['personId']['nom']} - ${b['dureeJours']} jours"),
                  trailing: Text("${DateTime.parse(b['dateEmprunt']).day}/${DateTime.parse(b['dateEmprunt']).month}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}