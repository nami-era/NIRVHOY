import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertScreen extends StatefulWidget {
  final Position? currentPosition;
  const AlertScreen({super.key, this.currentPosition});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  Timer? _timer;
  int _secondsRemaining = 15;
  bool _smsSent = false;
  List<String> _recipients = [];

  @override
  void initState() {
    super.initState();
    _loadSavedContacts();
    _startTimer();
  }

  Future<void> _loadSavedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    String? contactsString = prefs.getString('emergency_contacts');
    if (contactsString != null) {
      List<dynamic> decodedList = jsonDecode(contactsString);
      List<String> phoneNumbers = [];
      for (var item in decodedList) {
        if (item['phone'] != null && item['phone'].toString().isNotEmpty) {
          phoneNumbers.add(item['phone'].toString());
        }
      }
      setState(() {
        _recipients = phoneNumbers;
      });
    } else {
      setState(() {
        _recipients = ["+8801712345678", "+8801812345678"];
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
        _sendOfflineEmergencySMS();
      }
    });
  }

  static const MethodChannel _smsChannel = MethodChannel('com.example.nirbhoy_app/sms');

  Future<void> _dispatchSMS(String message, List<String> recipients) async {
    try {
      final result = await _smsChannel.invokeMethod('sendDirectSMS', {
        'message': message,
        'recipients': recipients,
      });
      debugPrint("Native Direct SMS sent: $result");
    } catch (e) {
      debugPrint("Native direct SMS error, attempting fallback: $e");
      try {
        await sendSMS(message: message, recipients: recipients);
      } catch (err) {
        debugPrint("Fallback SMS failed: $err");
      }
    }
  }

  Future<void> _sendOfflineEmergencySMS() async {
    if (_smsSent) return;

    if (_recipients.isEmpty) {
      debugPrint("No emergency recipients found!");
      return;
    }

    String mapsUrl = widget.currentPosition != null
        ? "https://maps.google.com/?q=${widget.currentPosition!.latitude},${widget.currentPosition!.longitude}"
        : "GPS Location Unavailable";

    String msgBody = "EMERGENCY ALERT! I need urgent help. My Offline GPS Location: $mapsUrl";

    await _dispatchSMS(msgBody, _recipients);

    if (mounted) {
      setState(() {
        _smsSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Emergency SMS dispatched successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _sendOfflineApologySMS() async {
    if (_recipients.isEmpty) return;

    String apologyMsg = "APOLOGY: I clicked the emergency button by mistake. I am totally safe now. Please ignore previous message.";

    await _dispatchSMS(apologyMsg, _recipients);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.portable_wifi_off, size: 100, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  'EMERGENCY ALERT (OFFLINE)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$_secondsRemaining s',
                    style: const TextStyle(fontSize: 32, color: Colors.yellowAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 15),

                Text(
                  _secondsRemaining > 0
                      ? 'Offline Cellular SMS will send automatically in $_secondsRemaining seconds to ${_recipients.length} saved contacts!'
                      : 'Emergency Offline Location SMS Sent Successfully!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),

                const SizedBox(height: 40),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.volume_off, size: 24),
                  label: const Text('STOP ALARM & SAFE NOW'),
                ),

                const SizedBox(height: 15),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: () async {
                    _timer?.cancel();
                    await _sendOfflineApologySMS();
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.mark_email_read, color: Colors.yellowAccent),
                  label: const Text('SEND APOLOGY MSG (PRESSED BY MISTAKE)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}