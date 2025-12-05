import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'score_detail_screen.dart';
import 'recent_service.dart';

class RecentAllScreen extends StatelessWidget {
  final String uid;
  const RecentAllScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final recentService = RecentService(uid: uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text("최근 본 찬송 전체"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: recentService.getAllRecent(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text("기록이 없습니다."));
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final item = list[i];
              final num = item["number"] as int;
              final title = item["title"] as String;

              return ListTile(
                leading: Text(
                  "$num장",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(title),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScoreDetailScreen(
                        hymnNumber: num,
                        hymnTitle: title,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
