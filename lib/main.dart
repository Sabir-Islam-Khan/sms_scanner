import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

// Background message handler - must be a top-level function
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) {
  // Process the SMS in background
  _processSms(message);
}

// Process SMS and send to API
void _processSms(SmsMessage message) async {
  String? sender = message.address;
  String? body = message.body;

  if (body == null || sender == null) return;

  // Check if the SMS is from bKash
  if (body.toLowerCase().contains('bkash') ||
      body.toLowerCase().contains('trxid')) {
    print('Received bKash SMS: $body');

    // Parse amount and transaction ID
    Map<String, dynamic>? data = parseBkashSms(body);

    if (data != null) {
      // Send to API
      await sendToApi(data['amount'], data['trxId']);
    }
  }
}

// Parse bKash SMS to extract amount and TrxID
Map<String, dynamic>? parseBkashSms(String smsBody) {
  try {
    // Example SMS: You have received Tk 2,000.00 from 01776800874. Fee Tk 0.00. Balance Tk 5,087.84. TrxID CLP5GGO1NZ at 25/12/2025 19:18

    // Extract amount - looking for "received Tk X.XX"
    RegExp amountRegex = RegExp(r'received Tk\s*([\d,]+\.?\d*)');
    Match? amountMatch = amountRegex.firstMatch(smsBody);

    // Extract TrxID - looking for "TrxID XXXXXXXXXX"
    RegExp trxIdRegex = RegExp(r'TrxID\s+([A-Z0-9]+)');
    Match? trxIdMatch = trxIdRegex.firstMatch(smsBody);

    if (amountMatch != null && trxIdMatch != null) {
      String amountStr = amountMatch.group(1)!.replaceAll(',', '');
      double amount = double.parse(amountStr);
      String trxId = trxIdMatch.group(1)!;

      print('Parsed - Amount: $amount, TrxID: $trxId');

      return {'amount': amount, 'trxId': trxId};
    }
  } catch (e) {
    print('Error parsing SMS: $e');
  }

  return null;
}

// Send transaction data to API
Future<void> sendToApi(double amount, String trxId) async {
  try {
    final url = Uri.parse('http://143.244.191.183:3003/transactions');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'transaction_id': trxId,
        'amount': amount,
        'method': 'BKASH',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Successfully sent to API: TrxID=$trxId, Amount=$amount');
    } else {
      print('API Error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Error sending to API: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'bKash SMS Scanner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Telephony telephony = Telephony.instance;
  bool _permissionsGranted = false;
  String _status = 'Checking permissions...';
  List<String> _recentMessages = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request SMS permissions
    final smsStatus = await Permission.sms.request();
    final phoneStatus = await Permission.phone.request();

    if (smsStatus.isGranted && phoneStatus.isGranted) {
      setState(() {
        _permissionsGranted = true;
        _status = 'Permissions granted. Listening for bKash SMS...';
      });

      // Start listening for SMS
      _startListening();
    } else {
      setState(() {
        _permissionsGranted = false;
        _status = 'Permissions denied. Please grant SMS permissions.';
      });
    }
  }

  void _startListening() {
    // Listen for incoming SMS in foreground
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _processSms(message);
        setState(() {
          _recentMessages.insert(
            0,
            'From: ${message.address}\n${message.body}\n---',
          );
          if (_recentMessages.length > 10) {
            _recentMessages.removeLast();
          }
        });
      },
      onBackgroundMessage: backgroundMessageHandler,
      listenInBackground: true,
    );
  }

  Future<void> _testWithSampleSms() async {
    String sampleSms =
        'You have received Tk 2,000.00 from 01776800874. Fee Tk 0.00. Balance Tk 5,087.84. TrxID CLP5GGO1NZ at 25/12/2025 19:18';

    Map<String, dynamic>? data = parseBkashSms(sampleSms);

    if (data != null) {
      await sendToApi(data['amount'], data['trxId']);

      setState(() {
        _recentMessages.insert(0, 'TEST SMS:\n$sampleSms\n---');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test SMS processed! Amount: ${data['amount']}, TrxID: ${data['trxId']}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _permissionsGranted
                              ? Icons.check_circle
                              : Icons.error,
                          color: _permissionsGranted
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_status)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _testWithSampleSms,
              icon: const Icon(Icons.send),
              label: const Text('Test with Sample bKash SMS'),
            ),
            const SizedBox(height: 16),
            Text('Recent SMS:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: _recentMessages.isEmpty
                  ? const Center(child: Text('No messages yet'))
                  : ListView.builder(
                      itemCount: _recentMessages.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _recentMessages[index],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
