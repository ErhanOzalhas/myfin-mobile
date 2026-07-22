import 'package:cloud_firestore/cloud_firestore.dart';

class PortfolioProfile {
  const PortfolioProfile({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    this.isDefault = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final int colorValue;
  final String iconKey;
  final bool isDefault;
  final DateTime? createdAt;

  factory PortfolioProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final createdAt = data['createdAt'];
    return PortfolioProfile(
      id: document.id,
      name: (data['name'] ?? 'Portföy').toString(),
      colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF0284C7,
      iconKey: (data['iconKey'] ?? 'person').toString(),
      isDefault: data['isDefault'] == true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
