import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../repositories/portfolio_repository.dart';
import '../../services/portfolio_rebuild_service.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import 'transaction_entry_page.dart';

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
                const _SectionTitle(title: 'İşlem Geçmişi'),
                const SizedBox(height: 12),
                _SurfaceCard(
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
            _SurfaceCard(
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
                  _ReportRow(label: 'Adet / Miktar', value: _formatQuantity(quantity)),
                  _ReportRow(label: 'Birim Fiyat', value: _formatCurrency(price, currency)),
                  _ReportRow(label: 'İşlem Tutarı', value: _formatCurrency(total, currency)),
                  _ReportRow(label: 'Para Birimi', value: currency),
                  _ReportRow(label: 'İşlem Tarihi', value: formattedDate),
                  if (note.isNotEmpty) _ReportRow(label: 'Not', value: note),
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
        child: _SurfaceCard(
          child: Row(
            children: [
              _IconBox(icon: icon, color: color),
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
                      '$type • ${_formatQuantity(quantity)} adet • Birim: ${_formatCurrency(price, currency)} • $formattedDate',
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
                    _formatCurrency(total, currency),
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

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w900,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .055),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color),
    );
  }
}

String _formatCurrency(double value, [String currency = 'TRY']) {
  final normalizedCurrency =
      currency.trim().isEmpty ? 'TRY' : currency.trim().toUpperCase();
  final formattedValue = _formatTurkishDecimal(value);

  if (normalizedCurrency == 'TRY') {
    return '$formattedValue TL';
  }

  return '$formattedValue $normalizedCurrency';
}

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value
      .toStringAsFixed(4)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll('.', ',');
}

String _formatTurkishDecimal(double value) {
  final isNegative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final decimal = parts.length > 1 ? parts.last : '00';

  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    buffer.write(whole[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${isNegative ? '-' : ''}${buffer.toString()},$decimal';
}