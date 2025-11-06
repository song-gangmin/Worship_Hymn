import 'package:flutter/material.dart';
import 'constants/topic_hymns.dart';

class GenreScroll extends StatelessWidget {
  final void Function(String topic, List<int> hymnList) onTopicSelected;

  GenreScroll({required this.onTopicSelected});

  final List<String> genres = topicHymns.keys.toList();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: genres.map((genre) {
            return GestureDetector(
              onTap: () {
                final hymns = topicHymns[genre] ?? [];
                onTopicSelected(genre, hymns);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(genre, style: const TextStyle(fontSize: 15)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}


class GenreChip extends StatelessWidget {
  final String label;

  const GenreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, color: Colors.black),
      ),
    );
  }
}
