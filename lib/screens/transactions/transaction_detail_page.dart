import 'package:flutter/material.dart';

import '../../repositories/portfolio_repository.dart';
import '../../services/portfolio_rebuild_service.dart';
import '../../utils/myfin_formatters.dart';
import '../../widgets/common/report_row.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import 'transaction_entry_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final symbol = (data['symbol'] ?? '-').toString();
    final assetName = (data['assetName'] ?? '').toString();
    final type = (data['type'] ?? '-').toString();
    final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final currency = (data['currency'] ?? 'TRY').toString();
    final note = (data['note'] ?? '').toString();

    final isSell = type == 'Satış';
    final color = isSell ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlem Detayı'),
        centerTitle: false,
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
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
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
                  ReportRow(label: 'İşlem Tarihi', value: formattedDate),
                  if (note.isNotEmpty) ReportRow(label: 'Not', value: note),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
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

                await PortfolioRepository.instance.deleteTransaction(transactionId);
                await PortfolioRebuildService().rebuildFromTransactions();

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('İşlem silindi.')),
                );

                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('İşlemi Sil'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(selectedIndex: 2),
    );
  }
}
