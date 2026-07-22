import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myfin_mobile/widgets/profile/active_profile_bar.dart';
import 'package:myfin_mobile/widgets/navigation/myfin_back_button.dart';

import '../../repositories/portfolio_repository.dart';
import '../../services/portfolio_rebuild_service.dart';
import '../../utils/myfin_formatters.dart';
import '../../widgets/common/report_row.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import 'transaction_entry_page.dart';
import '../../utils/no_animation_route.dart';

class TransactionDetailPage extends StatelessWidget {
  final String transactionId;
  final Map<String, dynamic> data;
  final String formattedDate;

  const TransactionDetailPage({
    super.key,
    required this.transactionId,
    required this.data,
    required this.formattedDate,
  });

  String _formatTimestamp(dynamic value) {
    if (value is! Timestamp) return '-';
    final date = value.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  Map<String, dynamic>? get _latestChange {
    final history = data['changeHistory'];
    if (history is! List || history.isEmpty) return null;
    final latest = history.last;
    return latest is Map ? Map<String, dynamic>.from(latest) : null;
  }

  @override
  Widget build(BuildContext context) {
    final symbol = (data['symbol'] ?? '-').toString();
    final assetName = (data['assetName'] ?? '').toString();
    final type = (data['type'] ?? '-').toString();
    final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final currency = (data['currency'] ?? 'TRY').toString();
    final cashFlowMode = data['cashFlowMode']?.toString();
    final paymentSource = switch (cashFlowMode) {
      'cash' => 'TL Nakit',
      'external' => 'Dış Kaynak',
      _ => 'Belirtilmemiş',
    };
    final note = (data['note'] ?? '').toString();
    final latestChange = _latestChange;
    final hasChanges =
        data['wasEdited'] == true ||
        data['updatedAt'] != null ||
        latestChange != null;

    final isSell = type == 'Satış';
    final color = isSell ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Scaffold(
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: const Text('İşlem Detayı'),
        bottom: const ActiveProfileBar(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assetName.isEmpty || assetName == symbol
                        ? symbol
                        : '$symbol • $assetName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ReportRow(
                    label: 'Adet / Miktar',
                    value: formatQuantity(quantity),
                  ),
                  ReportRow(
                    label: 'Birim Fiyat',
                    value: formatCurrency(price, currency),
                  ),
                  ReportRow(
                    label: 'İşlem Tutarı',
                    value: formatCurrency(total, currency),
                  ),
                  ReportRow(label: 'Para Birimi', value: currency),
                  ReportRow(label: 'Ödeme Kaynağı', value: paymentSource),
                  ReportRow(label: 'İşlem Tarihi', value: formattedDate),
                  if (note.isNotEmpty) ReportRow(label: 'Not', value: note),
                ],
              ),
            ),
            if (hasChanges) ...[
              const SizedBox(height: 14),
              _TransactionChangeHistoryCard(
                latestChange: latestChange,
                fallbackEditedAt: data['updatedAt'],
                formatTimestamp: _formatTimestamp,
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  noAnimationRoute(
                    builder: (_) => TransactionEntryPage(
                      transactionId: transactionId,
                      transactionData: data,
                      formattedDate: formattedDate,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_rounded),
              label: const Text('İşlemi Düzenle'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('İşlemi Sil'),
                    content: const Text(
                      'Bu işlem kalıcı olarak silinecek.\n\nDevam etmek istiyor musun?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Vazgeç'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                );

                if (result != true) return;

                await PortfolioRepository.instance.deleteTransaction(
                  transactionId,
                );
                await PortfolioRebuildService().rebuildFromTransactions();

                if (!context.mounted) return;

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('İşlem silindi.')));

                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('İşlemi Sil'),
            ),
          ],
        ),
      ),

      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 2,
        allowSelectedDestinationNavigation: true,
      ),
    );
  }
}

class _TransactionChangeHistoryCard extends StatelessWidget {
  final Map<String, dynamic>? latestChange;
  final dynamic fallbackEditedAt;
  final String Function(dynamic) formatTimestamp;

  const _TransactionChangeHistoryCard({
    required this.latestChange,
    required this.fallbackEditedAt,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final change = latestChange;
    final editedAt = change?['editedAt'] ?? fallbackEditedAt;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Değişiklik Geçmişi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          ReportRow(label: 'Son düzenleme', value: formatTimestamp(editedAt)),
          if (change == null)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Bu işlem düzenlendi. Önceki değişiklik ayrıntısı kaydedilmemiş.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                ),
              ),
            )
          else
            ..._buildVersionCards(change),
        ],
      ),
    );
  }

  List<Widget> _buildVersionCards(Map<String, dynamic> change) {
    final before = Map<String, dynamic>.from(change['before'] as Map? ?? {});
    final after = Map<String, dynamic>.from(change['after'] as Map? ?? {});
    return [
      const SizedBox(height: 6),
      _TransactionVersionCard(
        title: 'İşlemin Önceki Hali',
        data: before,
        color: const Color(0xFFF59E0B),
        formatTimestamp: formatTimestamp,
      ),
      const SizedBox(height: 12),
      _TransactionVersionCard(
        title: 'İşlemin Yeni Hali',
        data: after,
        color: const Color(0xFF0284C7),
        formatTimestamp: formatTimestamp,
      ),
    ];
  }
}

class _TransactionVersionCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final Color color;
  final String Function(dynamic) formatTimestamp;

  const _TransactionVersionCard({
    required this.title,
    required this.data,
    required this.color,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final total = (data['total'] as num?)?.toDouble() ?? quantity * price;
    final currency = (data['currency'] ?? 'TRY').toString();
    final type = (data['type'] ?? '-').toString();
    final note = (data['note'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          _VersionRow(label: 'İşlem türü', value: type),
          _VersionRow(label: 'Adet / Miktar', value: formatQuantity(quantity)),
          _VersionRow(
            label: 'Birim fiyat',
            value: formatCurrency(price, currency),
          ),
          _VersionRow(
            label: 'İşlem tutarı',
            value: formatCurrency(total, currency),
          ),
          _VersionRow(
            label: 'İşlem tarihi',
            value: formatTimestamp(data['transactionDate']),
          ),
          if (note.isNotEmpty) _VersionRow(label: 'Not', value: note),
        ],
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  final String label;
  final String value;

  const _VersionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
