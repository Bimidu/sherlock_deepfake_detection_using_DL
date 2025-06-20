import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/api_service.dart';

/// A custom logger that captures logs to display in the UI
class UILogger extends Logger {
  static final List<LogEntry> _logs = [];
  static final List<Function(LogEntry)> _listeners = [];

  UILogger() : super(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: false,
      printEmojis: false,  // Disabled emojis as requested
      printTime: true,
    ),
  );

  @override
  void log(
    Level level,
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    super.log(level, message, time: time, error: error, stackTrace: stackTrace);
    
    final entry = LogEntry(
      level: level,
      message: message?.toString() ?? '',
      time: time ?? DateTime.now(),
      error: error?.toString(),
      source: 'frontend',
    );
    
    _logs.add(entry);
    for (final listener in _listeners) {
      listener(entry);
    }
  }

  static List<LogEntry> get logs => List.unmodifiable(_logs);
  
  static void addListener(Function(LogEntry) listener) {
    _listeners.add(listener);
  }
  
  static void removeListener(Function(LogEntry) listener) {
    _listeners.remove(listener);
  }
  
  static void clear() {
    _logs.clear();
    for (final listener in _listeners) {
      listener(LogEntry(
        level: Level.debug, 
        message: 'Logs cleared', 
        time: DateTime.now(),
        source: 'frontend'
      ));
    }
  }
}

class LogEntry {
  final Level level;
  final String message;
  final DateTime time;
  final String? error;
  final String source;

  LogEntry({
    required this.level,
    required this.message,
    required this.time,
    this.error,
    this.source = 'frontend',
  });
  
  Color get color {
    switch (level) {
      case Level.verbose:
        return Colors.grey;
      case Level.debug:
        return Colors.blue;
      case Level.info:
        return Colors.green;
      case Level.warning:
        return Colors.orange;
      case Level.error:
        return Colors.red;
      case Level.wtf:
        return Colors.purple;
      default:
        return Colors.black;
    }
  }
  
  String get levelName {
    switch (level) {
      case Level.verbose:
        return 'VERBOSE';
      case Level.debug:
        return 'DEBUG';
      case Level.info:
        return 'INFO';
      case Level.warning:
        return 'WARN';
      case Level.error:
        return 'ERROR';
      case Level.wtf:
        return 'WTF';
      default:
        return 'UNKNOWN';
    }
  }
}

class LoggerWidget extends StatefulWidget {
  const LoggerWidget({super.key});

  @override
  State<LoggerWidget> createState() => _LoggerWidgetState();
}

class _LoggerWidgetState extends State<LoggerWidget> with TickerProviderStateMixin {
  final List<LogEntry> _logs = [];
  final ApiService _apiService = ApiService();
  bool _isLoadingBackendLogs = false;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _logs.addAll(UILogger.logs);
    UILogger.addListener(_onNewLog);
    _loadBackendLogs();
  }
  
  @override
  void dispose() {
    UILogger.removeListener(_onNewLog);
    _tabController.dispose();
    super.dispose();
  }
  
  void _onNewLog(LogEntry log) {
    setState(() {
      _logs.add(log);
    });
  }

  Future<void> _loadBackendLogs() async {
    setState(() {
      _isLoadingBackendLogs = true;
    });

    try {
      // First test the connection to diagnose issues
      print('Starting backend logs loading...');
      final connectionTest = await _apiService.testConnection();
      print('Connection test result: $connectionTest');
      
      if (!connectionTest.startsWith('SUCCESS')) {
        throw Exception('Connection test failed: $connectionTest');
      }

      final response = await _apiService.getBackendLogs(limit: 100);
      final backendLogs = response['logs'] as List<dynamic>;
      
      print('Successfully loaded ${backendLogs.length} backend logs');
      
      for (final logData in backendLogs) {
        final level = _parseLogLevel(logData['level'] ?? 'INFO');
        final timestamp = DateTime.tryParse(logData['timestamp'] ?? '') ?? DateTime.now();
        
        final logEntry = LogEntry(
          level: level,
          message: logData['message'] ?? '',
          time: timestamp,
          source: 'backend',
        );
        
        _logs.add(logEntry);
      }
      
      setState(() {});
    } catch (e) {
      print('Error loading backend logs: $e');
      // Add error log entry with detailed information
      final errorEntry = LogEntry(
        level: Level.error,
        message: 'Failed to load backend logs: $e',
        time: DateTime.now(),
        source: 'frontend',
      );
      _logs.add(errorEntry);
      setState(() {});
    } finally {
      setState(() {
        _isLoadingBackendLogs = false;
      });
    }
  }

  Level _parseLogLevel(String levelStr) {
    switch (levelStr.toUpperCase()) {
      case 'DEBUG':
        return Level.debug;
      case 'INFO':
        return Level.info;
      case 'WARNING':
      case 'WARN':
        return Level.warning;
      case 'ERROR':
        return Level.error;
      default:
        return Level.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final frontendLogs = _logs.where((log) => log.source == 'frontend').toList();
    final backendLogs = _logs.where((log) => log.source == 'backend').toList();
    final allLogs = List<LogEntry>.from(_logs)..sort((a, b) => b.time.compareTo(a.time));

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Logs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Logs (${allLogs.length})'),
            Tab(text: 'Backend (${backendLogs.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackendLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                UILogger.clear();
                _logs.clear();
              });
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogsList(allLogs),
          _buildLogsList(backendLogs),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<LogEntry> logs) {
    if (_isLoadingBackendLogs && logs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (logs.isEmpty) {
      return const Center(
        child: Text('No logs available'),
      );
    }

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              _getIconForSource(log.source),
              color: log.color,
              size: 16,
            ),
            title: Text(
              log.message,
              style: TextStyle(
                color: log.color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')} - ${log.levelName} (${log.source})',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                if (log.error != null)
                  Text(
                    log.error!,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForSource(String source) {
    switch (source) {
      case 'backend':
        return Icons.storage;
      case 'frontend':
        return Icons.phone_android;
      default:
        return Icons.info;
    }
  }
} 