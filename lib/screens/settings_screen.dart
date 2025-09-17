
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<List<Application>>? _appsFuture;
  Set<String> _selectedAppPackages = {};

  @override
  void initState() {
    super.initState();
    _appsFuture = _loadAppsAndPreferences();
  }

  Future<List<Application>> _loadAppsAndPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAppPackages = (prefs.getStringList('selected_apps') ?? []).toSet();
    });
    // Retorna apenas aplicativos que não são do sistema para facilitar a seleção
    return await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );
  }

  Future<void> _onAppSelected(String packageName, bool isSelected) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (isSelected) {
        _selectedAppPackages.add(packageName);
      } else {
        _selectedAppPackages.remove(packageName);
      }
    });
    await prefs.setStringList('selected_apps', _selectedAppPackages.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Aplicativos'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Application>>(
        future: _appsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar aplicativos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum aplicativo encontrado.'));
          }

          final apps = snapshot.data!;
          // Ordena os apps em ordem alfabética
          apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

          return ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              final isSelected = _selectedAppPackages.contains(app.packageName);

              return CheckboxListTile(
                secondary: app is ApplicationWithIcon ? Image.memory(app.icon, width: 40, height: 40) : null,
                title: Text(app.appName),
                subtitle: Text(app.packageName),
                value: isSelected,
                onChanged: (bool? value) {
                  if (value != null) {
                    _onAppSelected(app.packageName, value);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
