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

      // Reset selection if the currently selected material was borrowed by someone else
      if (selectedMaterialId != null && !_isMaterialAvailable(selectedMaterialId!)) {
        selectedMaterialId = null;
      }
    });
  }

  // Checks if material has an active loan (estRendu == false)
  bool _isMaterialAvailable(String materialId) {
    for (var b in borrowings) {
      String bMaterialId = b['materialId']['_id']?.toString() ?? b['materialId'].toString();
      if (bMaterialId == materialId && b['estRendu'] == false) {
        return false;
      }
    }
    return true;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Configurez la personne dans Réglages !"))
      );
      return;
    }
    bool success = await ApiService.addBorrowing(
      currentPersonId!, 
      selectedMaterialId!, 
      int.parse(_daysController.text),
      selectedDate
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emprunt réussi !"))
      );
      setState(() => selectedMaterialId = null);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Emprunts"), 
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)
        ]
      ),
      body: Column(
        children: [
          // FORM SECTION
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
                      items: materials.map((m) {
                        String mId = m['_id'].toString();
                        bool isAvailable = _isMaterialAvailable(mId);
                        return DropdownMenuItem(
                          value: mId,
                          enabled: isAvailable,
                          child: Text(
                            isAvailable ? m['libelle'] : "${m['libelle']} (Indisponible)",
                            style: TextStyle(
                              color: isAvailable ? Colors.black : Colors.grey,
                              fontStyle: isAvailable ? FontStyle.normal : FontStyle.italic,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedMaterialId = val);
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _daysController,
                            decoration: const InputDecoration(
                              labelText: "Durée (jours)", 
                              icon: Icon(Icons.timer)
                            ),
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
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45), 
                        backgroundColor: Colors.blue, 
                        foregroundColor: Colors.white
                      ),
                      child: const Text("VALIDER L'EMPRUNT"),
                    )
                  ],
                ),
              ),
            ),
          ),
          
          const Divider(),
          
          // TRACKING LISTS SECTION
          Expanded(
            child: ListView(
              children: [
                // 1. ACTIVE LOANS (NOT RETURNED YET)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "Matériel non rendu (En cours de prêt)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                  ),
                ),
                ...borrowings
                    .where((b) => b['estRendu'] == false)
                    .map((b) => ListTile(
                          tileColor: Colors.orange.shade50,
                          leading: const Icon(Icons.pending, color: Colors.orange),
                          title: Text(
                            "${b['materialId']['libelle']}", 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          subtitle: Text("Utilisé par: ${b['personId']['nom']} (${b['dureeJours']} jours)"),
                          trailing: Text("${DateTime.parse(b['dateEmprunt']).day}/${DateTime.parse(b['dateEmprunt']).month}"),
                        ))
                    .toList(),

                const Divider(height: 30),

                // 2. RETURNED HISTORY
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "Historique (Matériel rendu)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                  ),
                ),
                ...borrowings
                    .where((b) => b['estRendu'] == true)
                    .map((b) => ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text("${b['materialId']['libelle']}"),
                          subtitle: Text("Par: ${b['personId']['nom']} - ${b['dureeJours']} jours"),
                          trailing: Text("${DateTime.parse(b['dateEmprunt']).day}/${DateTime.parse(b['dateEmprunt']).month}"),
                        ))
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}