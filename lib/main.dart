import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planilhaehtudo/helpers/database_helper.dart';
import 'package:planilhaehtudo/screens/settings_screen.dart';
import 'package:planilhaehtudo/services/webhook_service.dart';
import 'package:planilhaehtudo/permission_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Future<bool> _permissionStatus;
  static const _methodChannel = MethodChannel('com.example.myapp/control');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissionStatus = _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _permissionStatus = _checkPermission();
      });
    }
  }

  Future<bool> _checkPermission() async {
    try {
      return await _methodChannel.invokeMethod('isNotificationListenerEnabled');
    } on PlatformException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planilha Eh Tudo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: _permissionStatus,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data == true) {
            return const HomeScreen();
          } else {
            return const PermissionScreen();
          }
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _notificationChannel = EventChannel(
    'com.example.myapp/notifications',
  );
  static const _methodChannel = MethodChannel('com.example.myapp/control');
  StreamSubscription? _notificationSubscription;
  List<Map<String, dynamic>> _transactions = [];
  final dbHelper = DatabaseHelper.instance;
  bool _isSyncing = false;
  bool _isListening = false;
  String _lastNotificationTime = 'Nunca';

  @override
  void initState() {
    super.initState();
    _refreshTransactionList();
    _startListening();
    _sendSelectedAppsToNative();
    _startServiceIfEnabled(); // Ensure service is running
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  Future<void> _sendSelectedAppsToNative() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedApps = prefs.getStringList('selected_apps') ?? [];
    try {
      await _methodChannel.invokeMethod('setSelectedApps', {
        'packages': selectedApps,
      });
      print('Selected apps sent to native: ${selectedApps.length} apps');
    } on PlatformException catch (e) {
      print('Error sending selected apps: ${e.message}');
    }
  }

  Future<void> _startServiceIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final isServiceEnabled = prefs.getBool('is_service_enabled') ?? true; // Default to true
    
    if (isServiceEnabled) {
      try {
        await _methodChannel.invokeMethod('startForegroundService');
        print('Notification service started');
      } on PlatformException catch (e) {
        print('Error starting service: ${e.message}');
      }
    }
  }

  void _refreshTransactionList() async {
    final allRows = await dbHelper.getAllTransactions();
    setState(() {
      _transactions = allRows;
    });
  }

  void _startListening() {
    print('Starting to listen for notifications...');
    setState(() {
      _isListening = true;
    });
    
    _notificationSubscription = _notificationChannel
        .receiveBroadcastStream()
        .listen((event) async {
          print('Notification received: $event');
          final notification = Map<String, dynamic>.from(event);
          notification['status'] = 'pending';
          await dbHelper.addTransaction(notification);
          
          setState(() {
            _lastNotificationTime = DateTime.now().toString().substring(11, 19);
          });
          
          _refreshTransactionList();
        }, onError: (error) {
          print('Error in notification stream: $error');
          setState(() {
            _isListening = false;
          });
        });
  }

  void _stopListening() {
    _notificationSubscription?.cancel();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _syncTransactions() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    final pendingTransactions = _transactions
        .where((t) => t['status'] == 'pending')
        .toList();
    if (pendingTransactions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma transação pendente para sincronizar.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      setState(() {
        _isSyncing = false;
      });
      return;
    }

    int successCount = 0;
    int failCount = 0;

    for (var transaction in pendingTransactions) {
      final bool success = await WebhookService.sendTransaction(transaction);
      if (success) {
        await dbHelper.updateTransactionStatus(transaction['id'], 'synced');
        successCount++;
      } else {
        await dbHelper.updateTransactionStatus(transaction['id'], 'failed');
        failCount++;
      }
    }

    _refreshTransactionList();

    setState(() {
      _isSyncing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sincronização concluída: $successCount com sucesso, $failCount com falha.',
          ),
          backgroundColor: failCount > 0 ? Colors.red : Colors.green,
        ),
      );
    }
  }

  void _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    // Após retornar da tela de configurações, reenvia a lista para o lado nativo
    _sendSelectedAppsToNative();
    _startServiceIfEnabled(); // Ensure service is running after settings change
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações Capturadas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _startListening();
              _sendSelectedAppsToNative();
              _startServiceIfEnabled();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Serviço de notificação reiniciado'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            tooltip: 'Reiniciar Captura',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _navigateToSettings,
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status card
          Container(
            margin: const EdgeInsets.all(8.0),
            child: Card(
              color: _isListening ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isListening ? Icons.check_circle : Icons.error,
                      color: _isListening ? Colors.green : Colors.red,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isListening ? 'Capturando Notificações' : 'Captura Inativa',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isListening ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                          Text(
                            'Última captura: $_lastNotificationTime',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Transactions list
          Expanded(
            child: _transactions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhuma transação capturada ainda.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Verifique se:\n• O serviço está ativo nas configurações\n• Você selecionou os apps para monitorar\n• Os apps selecionados estão enviando notificações',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(transaction['status']),
                            child: _getStatusIcon(transaction['status']),
                          ),
                          title: Text(
                            transaction['title'] ?? 'Sem Título',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(transaction['message'] ?? 'Sem Mensagem'),
                              const SizedBox(height: 4),
                              Text(
                                'App: ${transaction['package'] ?? 'Desconhecido'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSyncing ? null : _syncTransactions,
        backgroundColor: Colors.deepPurple,
        tooltip: 'Sincronizar com Webhook',
        child: _isSyncing
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Icon(Icons.sync, color: Colors.white),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'synced':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return const Icon(Icons.hourglass_top, color: Colors.white, size: 20);
      case 'synced':
        return const Icon(Icons.check, color: Colors.white, size: 20);
      case 'failed':
        return const Icon(Icons.close, color: Colors.white, size: 20);
      default:
        return const Icon(Icons.question_mark, color: Colors.white, size: 20);
    }
  }
}
