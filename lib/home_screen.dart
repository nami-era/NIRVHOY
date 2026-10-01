import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'contacts_screen.dart';
import 'alert_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const MethodChannel _triggerChannel = MethodChannel('com.example.nirbhoy_app/hardware_trigger');
  int _holdSeconds = 0;
  Timer? _simHoldTimer;
  String _locationMessage = "Fetching Offline Satellite GPS...";
  Position? _currentPosition;
  bool _isAlertOpen = false;

  @override
  void initState() {
    super.initState();
    _getOfflineLocation();
    _initHardwareTriggerListener();
  }

  void _initHardwareTriggerListener() {
    _triggerChannel.setMethodCallHandler((call) async {
      if (!mounted) return;
      if (call.method == 'holdProgress') {
        int sec = (call.arguments as int?) ?? 0;
        setState(() {
          _holdSeconds = sec;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.volume_down, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Holding Volume Down: $sec / 3s...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.red.shade700,
          ),
        );
      } else if (call.method == 'holdCancelled') {
        setState(() {
          _holdSeconds = 0;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      } else if (call.method == 'triggerEmergencyAlarm') {
        setState(() {
          _holdSeconds = 0;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _triggerEmergencyAlarm();
      }
    });
  }

  Future<void> _getOfflineLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = "GPS is turned off. Please enable Location.";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = "Location permission denied.";
        });
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      forceAndroidLocationManager: true,
    );

    setState(() {
      _currentPosition = position;
      _locationMessage = "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
    });
  }

  void _triggerEmergencyAlarm() {
    if (_isAlertOpen) return;
    _isAlertOpen = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertScreen(currentPosition: _currentPosition),
      ),
    ).then((_) {
      _isAlertOpen = false;
    });
  }

  void _startSimulateHold() {
    setState(() {
      _holdSeconds = 0;
    });
    _simHoldTimer?.cancel();
    _simHoldTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _holdSeconds++;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulated Hold: $_holdSeconds / 3s...'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red.shade700,
        ),
      );

      if (_holdSeconds >= 3) {
        timer.cancel();
        setState(() {
          _holdSeconds = 0;
        });
        _triggerEmergencyAlarm();
      }
    });
  }

  void _cancelSimulateHold() {
    if (_simHoldTimer != null && _simHoldTimer!.isActive) {
      _simHoldTimer?.cancel();
      setState(() {
        _holdSeconds = 0;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  @override
  void dispose() {
    _simHoldTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NIRVHOY Guard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Emergency Contacts',
            icon: const Icon(Icons.quick_contacts_dialer, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (_) {}
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_logged_in', false);
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.satellite_alt, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Offline GPS: $_locationMessage',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        onPressed: _getOfflineLocation,
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'PRESS SOS FOR EMERGENCY',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
              const SizedBox(height: 25),

              GestureDetector(
                onTap: _triggerEmergencyAlarm,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_rounded, size: 50, color: Colors.white),
                        SizedBox(height: 5),
                        Text(
                          'SOS',
                          style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text('15 SEC AUTO-SMS TIMER', style: TextStyle(fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // Volume Down instruction card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.volume_down, color: Colors.red, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hardware Shortcut',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Hold Volume Down for 3 seconds to trigger SOS alarm instantly.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 15),

              GestureDetector(
                onTapDown: (_) => _startSimulateHold(),
                onTapUp: (_) => _cancelSimulateHold(),
                onTapCancel: _cancelSimulateHold,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.touch_app),
                  label: Text(_holdSeconds > 0
                      ? 'Holding... ($_holdSeconds/3s)'
                      : 'Hold to Simulate Volume Down (3s)'),
                ),
              ),

              const SizedBox(height: 15),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ContactsScreen()),
                  );
                },
                icon: const Icon(Icons.contacts),
                label: const Text('Manage Emergency Contacts'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}