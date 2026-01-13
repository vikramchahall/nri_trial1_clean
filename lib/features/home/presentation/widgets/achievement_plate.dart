import 'package:flutter/material.dart';

class Achievement {
  final String title;
  final IconData icon;
  final Color color;

  const Achievement({
    required this.title,
    required this.icon,
    required this.color,
  });
}

class AchievementPlate extends StatelessWidget {
  const AchievementPlate({super.key});

  @override
  Widget build(BuildContext context) {
    const achievements = [
      Achievement(
        title: "Sample 1 ",
        icon: Icons.bolt,
        color: Colors.orange,
      ),
      Achievement(
        title: "Sample 1Lab",
        icon: Icons.computer,
        color: Colors.blue,
      ),
      Achievement(
        title: "Sample 1 Project",
        icon: Icons.water_drop,
        color: Colors.cyan,
      ),
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: achievements.length,
        itemBuilder: (_, index) {
          final item = achievements[index];

          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: item.color.withOpacity(0.1),
                  child: Icon(item.icon, color: item.color),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
