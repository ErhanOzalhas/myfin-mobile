import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../repositories/portfolio_repository.dart';
import '../../utils/myfin_formatters.dart';
import '../../widgets/common/icon_box.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import 'transaction_detail_page.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day.$month.${date.year}';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlemler'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: PortfolioRepository.instance.watchTransactions(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                const SectionTitle(title: 'İşlem Geçmişi'),
                const SizedBox(height: 12),
                SurfaceCard(
                  child: Text(
                    docs.isEmpty
                        ? 'Henüz işlem kaydı yok. Alış veya satış işlemi girdiğinde burada görünecek.'
                        : '${docs.length} işlem kaydı bulundu.',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                for (final doc in docs)
                  _TransactionHistoryTile(
                    transactionId: doc.id,
                    data: doc.data(),
                    formattedDate: _formatDate(
                      doc.data()['transactionDate'] ?? doc.data()['createdAt'],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(selectedIndex: 2),
    );
  }
}

class _TransactionHistoryTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String formattedDate;
  final String transactionId;

  const _TransactionHistoryTile({
    required this.data,
    required this.formattedDate,
    required this.transactionId,
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

    final isSell = type == 'Satış';
    final color = isSell ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final icon = isSell ? Icons.south_west_rounded : Icons.north_east_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailPage(
                transactionId: transactionId,
                data: data,
                formattedDate: formattedDate,
              ),
            ),
          );
        },
        child: SurfaceCard(
          child: Row(
            children: [
              IconBox(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assetName.isEmpty || assetName == symbol
                          ? symbol
                          : '$symbol • $assetName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$type • ${formatQuantity(quantity)} adet • Birim: ${formatCurrency(price, currency)} • $formattedDate',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(total, currency),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'İşlem Tutarı',
                    style: TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
