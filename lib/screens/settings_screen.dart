import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<List<AppInfo>>? _appsFuture;
  Set<String> _selectedAppPackages = {};

  @override
  void initState() {
    super.initState();
    _appsFuture = _loadAppsAndPreferences();
  }

  Future<List<AppInfo>> _loadAppsAndPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAppPackages = (prefs.getStringList('selected_apps') ?? []).toSet();
    });
    return await InstalledApps.getInstalledApps(true, true);
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
      body: FutureBuilder<List<AppInfo>>(
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
          apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              final isSelected = _selectedAppPackages.contains(app.packageName);

              return CheckboxListTile(
                secondary: app.icon != null ? Image.memory(app.icon!, width: 40, height: 40) : null,
                title: Text(app.name),
                subtitle: Text(app.packageName ?? ''),
                value: isSelected,
                onChanged: (bool? value) {
                  if (value != null) {
                    _onAppSelected(app.packageName!, value);
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