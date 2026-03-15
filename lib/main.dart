// Author: Wélbster Florentino Labat Uchôas
// Email: welbsteruchoas@gmail.com

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

// --- MODELOS DE DADOS ---

class AnimalStats {
  bool possui;
  int total;
  int castrados;
  int vacinados;

  AnimalStats({
    this.possui = false,
    this.total = 0,
    this.castrados = 0,
    this.vacinados = 0,
  });

  Map<String, dynamic> toJson() => {
        'possui': possui,
        'total': total,
        'castrados': castrados,
        'naoCastrados': (total > castrados) ? (total - castrados) : 0,
        'vacinados': vacinados,
        'naoVacinados': (total > vacinados) ? (total - vacinados) : 0,
      };

  factory AnimalStats.fromJson(Map<String, dynamic> json) {
    return AnimalStats(
      possui: json['possui'] ?? false,
      total: json['total'] ?? 0,
      castrados: json['castrados'] ?? 0,
      vacinados: json['vacinados'] ?? 0,
    );
  }
}

class CensusRecord {
  String id;
  String timestamp;
  String? agentName;
  String? agentId;
  Map<String, String> endereco;
  bool possuiAnimais;
  Map<String, AnimalStats> dadosAnimais;

  CensusRecord({
    required this.id,
    required this.timestamp,
    this.agentName,
    this.agentId,
    required this.endereco,
    required this.possuiAnimais,
    required this.dadosAnimais,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'deviceInfo': 'App Android Nativo v3.0 (Novo PC)',
        'agentName': agentName,
        'agentId': agentId,
        'endereco': endereco,
        'possuiAnimais': possuiAnimais,
        'dadosAnimais': {
          'cachorros': dadosAnimais['cachorros']?.toJson() ?? AnimalStats().toJson(),
          'gatos': dadosAnimais['gatos']?.toJson() ?? AnimalStats().toJson(),
          'pitbulls': dadosAnimais['pitbulls']?.toJson() ?? AnimalStats().toJson(),
          'rottweilers': dadosAnimais['rottweilers']?.toJson() ?? AnimalStats().toJson(),
        },
      };

  factory CensusRecord.fromJson(Map<String, dynamic> json) {
    var dadosAnimaisRaw = json['dadosAnimais'];
    return CensusRecord(
      id: json['id'],
      timestamp: json['timestamp'],
      agentName: json['agentName'],
      agentId: json['agentId'],
      endereco: Map<String, String>.from(json['endereco']),
      possuiAnimais: json['possuiAnimais'],
      dadosAnimais: {
        'cachorros': AnimalStats.fromJson(dadosAnimaisRaw['cachorros'] ?? {}),
        'gatos': AnimalStats.fromJson(dadosAnimaisRaw['gatos'] ?? {}),
        'pitbulls': AnimalStats.fromJson(dadosAnimaisRaw['pitbulls'] ?? {}),
        'rottweilers': AnimalStats.fromJson(dadosAnimaisRaw['rottweilers'] ?? {}),
      },
    );
  }
}

// --- LISTA DE BAIRROS ---
const List<String> bairrosSJC = [
  "Altos de Santana", "Bosque dos Eucaliptos", "Buquirinha", "Campos de São José",
  "Centro", "Chácaras Reunidas", "Cidade Jardim", "Cidade Morumbi", "Dom Pedro I",
  "Eugênio de Melo", "Floradas de São José", "Galo Branco", "Jardim América",
  "Jardim Aquarius", "Jardim das Indústrias", "Jardim Esplanada", "Jardim Ismênia",
  "Jardim Motorama", "Jardim Oriente", "Jardim Paulista", "Jardim Satélite",
  "Novo Horizonte", "Parque Industrial", "Putim", "Santana", "São Francisco",
  "São Judas Tadeu", "Urbanova", "Vila Adyana", "Vila Ema", "Vila Industrial",
  "Vila Maria", "Vila Nair", "Vila Paiva", "Vila Tesouro", "Vista Verde"
];

// --- APP ---

void main() {
  runApp(const CensoPetApp());
}

class CensoPetApp extends StatelessWidget {
  const CensoPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CensoPet SJC',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0EA5E9),
        brightness: brightness,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: brightness == Brightness.light ? Colors.grey[50] : Colors.grey[900],
      ),
    );
  }
}

// --- DASHBOARD ---

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<CensusRecord> records = [];
  String agentName = "";
  String agentId = "";
  
  final Set<String> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      agentName = prefs.getString('agent_name') ?? "";
      agentId = prefs.getString('agent_id') ?? "";
      final String? recordsString = prefs.getString('records');
      if (recordsString != null) {
        final List<dynamic> decoded = jsonDecode(recordsString);
        records = decoded.map((item) => CensusRecord.fromJson(item)).toList();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == records.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(records.map((r) => r.id));
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _deleteRecord(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir"),
        content: const Text("Deseja apagar este registro?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Apagar")
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        records.removeWhere((r) => r.id == id);
        if (_selectedIds.contains(id)) _selectedIds.remove(id);
      });
      await prefs.setString('records', jsonEncode(records));
    }
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Excluir $count itens?"),
        content: const Text("Essa ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Excluir")
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        records.removeWhere((r) => _selectedIds.contains(r.id));
        _selectedIds.clear();
      });
      await prefs.setString('records', jsonEncode(records));
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Limpar Tudo?"),
        content: const Text("Deseja apagar TODOS os registros do dispositivo?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("LIMPAR TUDO")
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        records.clear();
        _selectedIds.clear();
      });
      await prefs.setString('records', jsonEncode(records));
    }
  }

  void _editRecord(CensusRecord record) async {
    if (_isSelectionMode) {
      _toggleSelection(record.id);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormScreen(recordToEdit: record)),
    );
    _loadData();
  }

  Future<void> _importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        List<dynamic> importedJson = jsonDecode(content);
        
        List<CensusRecord> newRecords = importedJson.map((item) => CensusRecord.fromJson(item)).toList();
        
        final currentIds = records.map((r) => r.id).toSet();
        int addedCount = 0;
        
        for (var rec in newRecords) {
          if (!currentIds.contains(rec.id)) {
            records.add(rec);
            addedCount++;
          }
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('records', jsonEncode(records));
        
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("$addedCount registros importados!"),
            backgroundColor: Colors.green,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Erro ao importar. Verifique o arquivo."),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _exportData() async {
    if (agentName.isEmpty || agentId.isEmpty) {
      _showAgentConfigDialog();
      return;
    }

    final exportList = records.map((r) {
      r.agentName ??= agentName;
      r.agentId ??= agentId;
      return r;
    }).toList();

    final jsonString = jsonEncode(exportList);
    final now = DateTime.now();
    final fileName = "CensoPet_${agentName.replaceAll(' ', '_')}_${DateFormat('yyyy-MM-dd_HH-mm').format(now)}.json";

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'Exportação CensoPet SJC');
  }

  void _showAgentConfigDialog() {
    final nameController = TextEditingController(text: agentName);
    final idController = TextEditingController(text: agentId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Identificação do Agente"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nome Completo", prefixIcon: Icon(LucideIcons.user))),
            const SizedBox(height: 10),
            TextField(controller: idController, decoration: const InputDecoration(labelText: "Matrícula", prefixIcon: Icon(LucideIcons.badgeCheck))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('agent_name', nameController.text);
              await prefs.setString('agent_id', idController.text);
              _loadData();
              Navigator.pop(ctx);
            },
            child: const Text("Salvar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode 
      ? AppBar(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _clearSelection,
          ),
          title: Text("${_selectedIds.length} selecionado(s)"),
          actions: [
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: "Selecionar Todos",
              onPressed: _selectAll,
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
              tooltip: "Excluir Seleção",
              onPressed: _deleteSelected,
            ),
          ],
        )
      : AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(LucideIcons.clipboardList, size: 20),
              SizedBox(width: 8),
              Text("CensoPet SJC"),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(LucideIcons.userCircle), onPressed: _showAgentConfigDialog),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'deleteAll') _deleteAll();
                if (value == 'import') _importData();
                if (value == 'about') {
                  showAboutDialog(
                    context: context,
                    applicationName: 'CensoPet SJC',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Desenvolvido por Wélbster Florentino Labat Uchôas\nContato: welbsteruchoas@gmail.com',
                    applicationIcon: const Icon(LucideIcons.dog, size: 40, color: Colors.blue),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(value: 'import', child: Row(children: [Icon(LucideIcons.upload, color: Colors.blue), SizedBox(width: 8), Text("Importar Backup")])),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'deleteAll', child: Row(children: [Icon(LucideIcons.trash2, color: Colors.red), SizedBox(width: 8), Text("Limpar Tudo")])),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'about', child: Row(children: [Icon(LucideIcons.info, color: Colors.grey), SizedBox(width: 8), Text("Sobre")])),
              ],
            ),
          ],
        ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade700, Colors.lightBlue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("REGISTROS SALVOS", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text("${records.length}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(LucideIcons.database, color: Colors.white, size: 30),
                    )
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: records.isEmpty ? null : _exportData,
                    icon: const Icon(LucideIcons.send, size: 20),
                    label: const Text("ENVIAR COLETAS (EXPORTAR)", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, 
                      foregroundColor: Colors.lightBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12)
                    ),
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.dog, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("Nenhuma coleta hoje", style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: records.length,
                    itemBuilder: (ctx, i) {
                      final rec = records[records.length - 1 - i];
                      final isSelected = _selectedIds.contains(rec.id);
                      final hasDogs = rec.dadosAnimais['cachorros']!.possui;
                      final hasCats = rec.dadosAnimais['gatos']!.possui;
                      final hasPitbull = rec.dadosAnimais['pitbulls']?.possui ?? false;
                      final hasRott = rec.dadosAnimais['rottweilers']?.possui ?? false;

                      return GestureDetector(
                        onLongPress: () => _toggleSelection(rec.id),
                        onTap: () => _isSelectionMode ? _toggleSelection(rec.id) : _editRecord(rec),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: isSelected ? Colors.blue.shade50 : null,
                          shape: isSelected 
                            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.blue, width: 2))
                            : null,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: isSelected 
                              ? const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.check, color: Colors.white))
                              : Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: rec.possuiAnimais ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    rec.possuiAnimais ? Icons.pets : LucideIcons.home,
                                    color: rec.possuiAnimais ? Colors.green : Colors.grey,
                                  ),
                                ),
                            title: Text("${rec.endereco['logradouro']}, ${rec.endereco['numero']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rec.endereco['bairro'] ?? "Bairro desconhecido"),
                                if (rec.possuiAnimais)
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (hasDogs) Text("🐶 ${rec.dadosAnimais['cachorros']!.total}", style: const TextStyle(fontSize: 12)),
                                      if (hasCats) Text("🐱 ${rec.dadosAnimais['gatos']!.total}", style: const TextStyle(fontSize: 12)),
                                      if (hasPitbull) Text("⚠️ Pitbull: ${rec.dadosAnimais['pitbulls']!.total}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                                      if (hasRott) Text("⚠️ Rottweiler: ${rec.dadosAnimais['rottweilers']!.total}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                                    ],
                                  )
                              ],
                            ),
                            trailing: isSelected 
                              ? null 
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.pencil, color: Colors.blue),
                                      onPressed: () => _editRecord(rec),
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, color: Colors.red),
                                      onPressed: () => _deleteRecord(rec.id),
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode 
        ? null 
        : FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen()));
              _loadData();
            },
            label: const Text("Nova Coleta"),
            icon: const Icon(LucideIcons.plus),
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
          ),
    );
  }
}

// --- FORMULÁRIO ---

class FormScreen extends StatefulWidget {
  final CensusRecord? recordToEdit; 

  const FormScreen({super.key, this.recordToEdit});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  int _currentStep = 0;
  
  final _cepCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _complCtrl = TextEditingController();
  
  bool _possuiAnimais = false;
  late AnimalStats _dogs;
  late AnimalStats _cats;
  late AnimalStats _pitbulls;
  late AnimalStats _rottweilers;
  
  bool _isLoadingCep = false;

  @override
  void initState() {
    super.initState();
    if (widget.recordToEdit != null) {
      final r = widget.recordToEdit!;
      _cepCtrl.text = r.endereco['cep'] ?? '';
      _logradouroCtrl.text = r.endereco['logradouro'] ?? '';
      _numeroCtrl.text = r.endereco['numero'] ?? '';
      _bairroCtrl.text = r.endereco['bairro'] ?? '';
      _complCtrl.text = r.endereco['complemento'] ?? '';
      
      _possuiAnimais = r.possuiAnimais;
      _dogs = AnimalStats.fromJson(r.dadosAnimais['cachorros']?.toJson() ?? {});
      _cats = AnimalStats.fromJson(r.dadosAnimais['gatos']?.toJson() ?? {});
      _pitbulls = AnimalStats.fromJson(r.dadosAnimais['pitbulls']?.toJson() ?? {});
      _rottweilers = AnimalStats.fromJson(r.dadosAnimais['rottweilers']?.toJson() ?? {});
    } else {
      _dogs = AnimalStats();
      _cats = AnimalStats();
      _pitbulls = AnimalStats();
      _rottweilers = AnimalStats();
      _loadLastAddress();
    }
  }

  Future<void> _loadLastAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cepCtrl.text = prefs.getString('last_cep') ?? '';
      _logradouroCtrl.text = prefs.getString('last_logradouro') ?? '';
      _bairroCtrl.text = prefs.getString('last_bairro') ?? '';
    });
  }

  Future<void> _fetchCep(String cep) async {
    if (cep.length != 8) return;
    
    setState(() => _isLoadingCep = true);
    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!data.containsKey('erro')) {
          setState(() {
            _logradouroCtrl.text = data['logradouro'] ?? "";
            _bairroCtrl.text = data['bairro'] ?? "";
          });
        }
      }
    } catch (e) {
      debugPrint("Erro CEP ou Offline");
    } finally {
      setState(() => _isLoadingCep = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    ));
  }

  bool _validateStats(String label, AnimalStats stats) {
    if (!stats.possui) return true;
    if (stats.castrados > stats.total) {
      _showError("$label: Castrados (${stats.castrados}) não pode ser maior que o Total (${stats.total}).");
      return false;
    }
    if (stats.vacinados > stats.total) {
      _showError("$label: Vacinados (${stats.vacinados}) não pode ser maior que o Total (${stats.total}).");
      return false;
    }
    return true;
  }

  bool _validateAnimals() {
    if (!_possuiAnimais) return true;
    return _validateStats("Cachorros", _dogs) && 
           _validateStats("Gatos", _cats) &&
           _validateStats("Pitbulls", _pitbulls) &&
           _validateStats("Rottweilers", _rottweilers);
  }

  Future<void> _saveRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRecordsStr = prefs.getString('records');
    List<dynamic> currentList = savedRecordsStr != null ? jsonDecode(savedRecordsStr) : [];

    final agentName = prefs.getString('agent_name');
    final agentId = prefs.getString('agent_id');

    final uuid = widget.recordToEdit != null ? widget.recordToEdit!.id : const Uuid().v7();
    final timestamp = DateTime.now().toIso8601String();

    final recordToSave = CensusRecord(
      id: uuid,
      timestamp: timestamp,
      agentName: agentName,
      agentId: agentId,
      endereco: {
        'cep': _cepCtrl.text,
        'logradouro': _logradouroCtrl.text,
        'numero': _numeroCtrl.text,
        'bairro': _bairroCtrl.text,
        'complemento': _complCtrl.text,
        'localidade': 'São José dos Campos',
        'uf': 'SP'
      },
      possuiAnimais: _possuiAnimais,
      dadosAnimais: {
        'cachorros': _dogs,
        'gatos': _cats,
        'pitbulls': _pitbulls,
        'rottweilers': _rottweilers,
      },
    );

    if (widget.recordToEdit != null) {
      final index = currentList.indexWhere((r) => r['id'] == uuid);
      if (index != -1) {
        currentList[index] = recordToSave.toJson();
      } else {
        currentList.add(recordToSave.toJson());
      }
    } else {
      currentList.add(recordToSave.toJson());
      await prefs.setString('last_cep', _cepCtrl.text);
      await prefs.setString('last_logradouro', _logradouroCtrl.text);
      await prefs.setString('last_bairro', _bairroCtrl.text);
    }

    await prefs.setString('records', jsonEncode(currentList));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recordToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Editar Coleta" : "Nova Coleta")),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
             if (_cepCtrl.text.isEmpty || _logradouroCtrl.text.isEmpty || _numeroCtrl.text.isEmpty || _bairroCtrl.text.isEmpty) {
               _showError("Campos Obrigatórios: CEP, Logradouro, Número e Bairro.");
               return;
             }
             setState(() => _currentStep += 1);
          } else if (_currentStep == 1) {
            if (_validateAnimals()) setState(() => _currentStep += 1);
          } else {
            _saveRecord();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
          else Navigator.pop(context);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: details.onStepContinue,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(_currentStep == 2 ? "SALVAR" : "PRÓXIMO"),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: details.onStepCancel,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(_currentStep == 0 ? "CANCELAR" : "VOLTAR"),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text("Local"),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cepCtrl,
                  decoration: InputDecoration(
                    labelText: "CEP*",
                    suffixIcon: _isLoadingCep ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.search, size: 18),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) { if (val.length == 8) _fetchCep(val); },
                ),
                const SizedBox(height: 15),
                TextFormField(controller: _logradouroCtrl, decoration: const InputDecoration(labelText: "Logradouro*")),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(child: TextFormField(controller: _numeroCtrl, decoration: const InputDecoration(labelText: "Número*"), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _complCtrl, decoration: const InputDecoration(labelText: "Complemento"))),
                ]),
                const SizedBox(height: 15),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') return const Iterable<String>.empty();
                    return bairrosSJC.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) { _bairroCtrl.text = selection; },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    if (_bairroCtrl.text.isNotEmpty && textEditingController.text.isEmpty) {
                       textEditingController.text = _bairroCtrl.text;
                    }
                    textEditingController.addListener(() { _bairroCtrl.text = textEditingController.text; });
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: "Bairro*"),
                    );
                  },
                ),
              ],
            ),
          ),
          Step(
            title: const Text("Animais"),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                SwitchListTile(
                  title: const Text("Possui Animais?", style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _possuiAnimais,
                  onChanged: (val) => setState(() => _possuiAnimais = val),
                ),
                if (_possuiAnimais) ...[
                  const Divider(),
                  _buildSpeciesForm("Cachorros (Geral)", _dogs, LucideIcons.dog),
                  const Divider(),
                  _buildSpeciesForm("Gatos", _cats, LucideIcons.cat),
                  const Divider(),
                  _buildSpeciesForm("Pitbulls", _pitbulls, Icons.warning_amber_rounded, color: Colors.orange),
                  const Divider(),
                  _buildSpeciesForm("Rottweilers", _rottweilers, Icons.warning_amber_rounded, color: Colors.orange),
                ]
              ],
            ),
          ),
          Step(
            title: const Text("Fim"),
            isActive: _currentStep >= 2,
            content: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewItem("Logradouro", _logradouroCtrl.text),
                  _buildReviewItem("Número", _numeroCtrl.text),
                  _buildReviewItem("Bairro", _bairroCtrl.text),
                  const Divider(),
                  if (!_possuiAnimais) const Text("Nenhum animal.", style: TextStyle(fontStyle: FontStyle.italic)),
                  if (_possuiAnimais) ...[
                    if (_dogs.possui) Text("🐶 Cães: ${_dogs.total} (Cast: ${_dogs.castrados} | Vac: ${_dogs.vacinados})"),
                    if (_cats.possui) Text("🐱 Gatos: ${_cats.total} (Cast: ${_cats.castrados} | Vac: ${_cats.vacinados})"),
                    if (_pitbulls.possui) Text("⚠️ Pitbulls: ${_pitbulls.total} (Cast: ${_pitbulls.castrados} | Vac: ${_pitbulls.vacinados})", style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (_rottweilers.possui) Text("⚠️ Rottweilers: ${_rottweilers.total} (Cast: ${_rottweilers.castrados} | Vac: ${_rottweilers.vacinados})", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value.isEmpty ? "-" : value)),
        ],
      ),
    );
  }

  Widget _buildSpeciesForm(String label, AnimalStats stats, IconData icon, {Color? color}) {
    return Column(
      children: [
        CheckboxListTile(
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          secondary: Icon(icon, color: color),
          value: stats.possui,
          onChanged: (val) => setState(() => stats.possui = val!),
        ),
        if (stats.possui) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: TextFormField(
                  initialValue: stats.total.toString(),
                  decoration: const InputDecoration(labelText: "Total"), 
                  keyboardType: TextInputType.number, 
                  onChanged: (v) => stats.total = int.tryParse(v) ?? 0
                )),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(
                  initialValue: stats.castrados.toString(),
                  decoration: const InputDecoration(labelText: "Castrados"), 
                  keyboardType: TextInputType.number, 
                  onChanged: (v) => stats.castrados = int.tryParse(v) ?? 0
                )),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(
                  initialValue: stats.vacinados.toString(),
                  decoration: const InputDecoration(labelText: "Vacinados"), 
                  keyboardType: TextInputType.number, 
                  onChanged: (v) => stats.vacinados = int.tryParse(v) ?? 0
                )),
              ],
            ),
          )
        ]
      ],
    );
  }
}
