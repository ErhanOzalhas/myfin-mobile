import 'package:flutter/material.dart';
import '../../services/ai/timeline_engine.dart';

class IntelligenceTimelineCard extends StatelessWidget {
  final List<AITimelineEvent> events;

  const IntelligenceTimelineCard({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
         if (events.isEmpty)
  const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      'No timeline data available yet.',
      style: TextStyle(color: Colors.grey),
    ),
  )
else
 ...events.map(
  (e) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                e.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(e.message),
            ],
          ),
        ),
      ],
    ),
  ),
), 
        ],
      ),
    );
  }
}