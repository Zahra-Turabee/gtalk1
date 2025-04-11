import 'package:flutter/material.dart';
import 'talk_screen.dart';
import 'image_to_gesture_screen.dart';
import 'offline_mode_screen.dart';
import 'entertainment_screen.dart';
import 'sos_system_screen.dart';
import 'flashlight_alarm_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _cards = [
      {'title': 'Talk', 'icon': Icons.chat, 'screen': const TalkScreen()},
      {
        'title': 'Image to Gesture',
        'icon': Icons.image_search,
        'screen': const ImageToGestureScreen(),
      },
      {
        'title': 'Offline Mode',
        'icon': Icons.signal_wifi_off,
        'screen': const OfflineModeScreen(),
      },
      {
        'title': 'Entertainment',
        'icon': Icons.movie,
        'screen': const EntertainmentScreen(),
      },
      {
        'title': 'SOS System',
        'icon': Icons.emergency_share,
        'screen': const SOSSystemScreen(),
      },
      {
        'title': 'Flashlight Alarm',
        'icon': Icons.flashlight_on,
        'screen': const FlashlightAlarmScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        title: const Text(
          'Gesture Talk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // ✅ White title
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 142, 38, 160),
        centerTitle: true,
        elevation: 4,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Text(
                  'Select',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 50, 50, 50),
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.touch_app,
                  color: Color.fromARGB(255, 142, 38, 160),
                  size: 26,
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _cards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 40,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => card['screen']),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: index < 2 ? 20 : 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              card['icon'],
                              size: 50,
                              color: const Color.fromARGB(255, 142, 38, 160),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              card['title'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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
