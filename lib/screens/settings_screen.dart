import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const platform = MethodChannel('com.example.myapp/control');
  Future<List<AppInfo>>? _appsFuture;
  Set<String> _selectedAppPackages = {};
  bool _isServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _appsFuture = _loadAppsAndPreferences();
  }

  Future<List<AppInfo>> _loadAppsAndPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAppPackages =
          (prefs.getStringList('selected_apps') ?? []).toSet();
      _isServiceEnabled = prefs.getBool('is_service_enabled') ?? false;
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
    
    // Send updated list to native side
    try {
      await platform.invokeMethod('setSelectedApps', {
        'packages': _selectedAppPackages.toList(),
      });
      print('Updated selected apps sent to native: ${_selectedAppPackages.length} apps');
    } on PlatformException catch (e) {
      print('Error updating selected apps: ${e.message}');
    }
  }

  Future<void> _toggleService(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isServiceEnabled = isEnabled;
    });
    await prefs.setBool('is_service_enabled', isEnabled);

    try {
      if (isEnabled) {
        await platform.invokeMethod('startForegroundService');
        print('Notification service started from settings');
      } else {
        await platform.invokeMethod('stopForegroundService');
        print('Notification service stopped from settings');
      }
    } on PlatformException catch (e) {
      print("Failed to toggle service: '${e.message}'.");
    }
  }

  void _simulateTestNotification() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Para testar, envie uma notificação de outro app (ex: WhatsApp, banco)'),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Monitoramento em Segundo Plano'),
            subtitle: const Text(
                'Mantenha o serviço ativo para capturar notificações.'),
            value: _isServiceEnabled,
            onChanged: _toggleService,
            secondary: const Icon(Icons.miscellaneous_services),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Debug & Teste',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Simular Notificação de Teste'),
            subtitle: const Text('Gera uma notificação de teste para verificar captura'),
            onTap: _simulateTestNotification,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Selecionar Aplicativos para Monitorar (${_selectedAppPackages.length} selecionados)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AppInfo>>(
              future: _appsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                        'Erro ao carregar aplicativos: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Nenhum aplicativo encontrado.'));
                }

                final apps = snapshot.data!;
                apps.sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );

                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    final isSelected =
                        _selectedAppPackages.contains(app.packageName);

                    return CheckboxListTile(
                      secondary: app.icon != null
                          ? Image.memory(app.icon!, width: 40, height: 40)
                          : null,
                      title: Text(app.name),
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
          ),
        ],
      ),
    );
  }
}
