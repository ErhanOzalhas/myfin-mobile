import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myfin_mobile/widgets/navigation/myfin_back_button.dart';

import '../../repositories/portfolio_repository.dart';
import '../../services/portfolio_rebuild_service.dart';
import '../../utils/myfin_formatters.dart';
import '../../widgets/common/icon_box.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import 'transaction_detail_page.dart';
import '../../utils/no_animation_route.dart';

enum _HistoryPeriod { sevenDays, oneMonth, threeMonths, sixMonths, custom }

class TransactionHistoryPage extends StatefulWidget {
  final bool showBottomNav;
  final String? symbolFilter;

  const TransactionHistoryPage({
    super.key,
    this.showBottomNav = true,
    this.symbolFilter,
  });

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  static bool _portfolioReconciledThisSession = false;
  _HistoryPeriod _period = _HistoryPeriod.oneMonth;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    if (!_portfolioReconciledThisSession) {
      _portfolioReconciledThisSession = true;
      PortfolioRebuildService().rebuildFromTransactions().catchError((error) {
        debugPrint('İşlem geçmişi portföy mutabakatı yapılamadı: $error');
      });
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) return _plainDate(value.toDate());
    return '-';
  }

  String _plainDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  DateTime _monthsAgo(DateTime date, int months) {
    final monthIndex = date.year * 12 + date.month - 1 - months;
    final year = monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final day = date.day.clamp(1, DateUtils.getDaysInMonth(year, month));
    return DateTime(year, month, day);
  }

  bool _isInSelectedPeriod(Map<String, dynamic> data) {
    final rawDate = data['transactionDate'] ?? data['createdAt'];
    if (rawDate is! Timestamp) return false;
    final date = rawDate.toDate();
    final now = DateTime.now();
    late DateTime start;
    var end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (_period) {
      case _HistoryPeriod.sevenDays:
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
      case _HistoryPeriod.oneMonth:
        start = _monthsAgo(now, 1);
      case _HistoryPeriod.threeMonths:
        start = _monthsAgo(now, 3);
      case _HistoryPeriod.sixMonths:
        start = _monthsAgo(now, 6);
      case _HistoryPeriod.custom:
        final range = _customRange;
        if (range == null) return true;
        start = DateTime(range.start.year, range.start.month, range.start.day);
        end = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
          59,
          999,
        );
    }
    return !date.isBefore(start) && !date.isAfter(end);
  }

  String get _periodSummary {
    switch (_period) {
      case _HistoryPeriod.sevenDays:
        return 'Son 7 günde';
      case _HistoryPeriod.oneMonth:
        return '1 ay içinde';
      case _HistoryPeriod.threeMonths:
        return '3 ay içinde';
      case _HistoryPeriod.sixMonths:
        return '6 ay içinde';
      case _HistoryPeriod.custom:
        final range = _customRange;
        return range == null
            ? 'Özel tarih aralığında'
            : '${_plainDate(range.start)} – ${_plainDate(range.end)} arasında';
    }
  }

  Future<void> _selectPeriod(_HistoryPeriod period) async {
    if (period != _HistoryPeriod.custom) {
      setState(() => _period = period);
      return;
    }
    final range = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: .62),
      backgroundColor: Colors.transparent,
      builder: (_) => _TurkishDateRangeSheet(initialRange: _customRange),
    );
    if (!mounted || range == null) return;
    setState(() {
      _period = _HistoryPeriod.custom;
      _customRange = range;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: Text(
          widget.symbolFilter == null || widget.symbolFilter!.isEmpty
              ? 'İşlem Geçmişi'
              : '${widget.symbolFilter} İşlem Geçmişi',
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: PortfolioRepository.instance.watchTransactions(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final symbolDocs =
                widget.symbolFilter == null || widget.symbolFilter!.isEmpty
                ? docs
                : docs.where((doc) {
                    final symbol = (doc.data()['symbol'] ?? '').toString();
                    return symbol.toUpperCase() ==
                        widget.symbolFilter!.toUpperCase();
                  }).toList();
            final visibleDocs = symbolDocs
                .where((doc) => _isInSelectedPeriod(doc.data()))
                .toList(growable: false);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _PeriodSelector(selected: _period, onSelected: _selectPeriod),
                const SizedBox(height: 14),
                SurfaceCard(
                  child: Text(
                    visibleDocs.isEmpty
                        ? '$_periodSummary işlem kaydı bulunamadı.'
                        : '$_periodSummary ${visibleDocs.length} işlem kaydı bulundu.',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                for (final doc in visibleDocs)
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
      bottomNavigationBar: widget.showBottomNav
          ? const MyFinBottomNav(
              selectedIndex: 2,
              allowSelectedDestinationNavigation: true,
            )
          : null,
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final _HistoryPeriod selected;
  final ValueChanged<_HistoryPeriod> onSelected;

  const _PeriodSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const periods = <(_HistoryPeriod, String)>[
      (_HistoryPeriod.sevenDays, '7 Gün'),
      (_HistoryPeriod.oneMonth, '1 Ay'),
      (_HistoryPeriod.threeMonths, '3 Ay'),
      (_HistoryPeriod.sixMonths, '6 Ay'),
      (_HistoryPeriod.custom, 'Özel'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int index = 0; index < periods.length; index++) ...[
            InkWell(
              onTap: () => onSelected(periods[index].$1),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: selected == periods[index].$1
                      ? const Color(0xFF0F73C5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == periods[index].$1
                        ? const Color(0xFF0F73C5)
                        : const Color(0xFFD7DEE8),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      periods[index].$2,
                      style: TextStyle(
                        color: selected == periods[index].$1
                            ? Colors.white
                            : const Color(0xFF334155),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (index != periods.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TurkishDateRangeSheet extends StatefulWidget {
  final DateTimeRange? initialRange;

  const _TurkishDateRangeSheet({this.initialRange});

  @override
  State<_TurkishDateRangeSheet> createState() => _TurkishDateRangeSheetState();
}

class _TurkishDateRangeSheetState extends State<_TurkishDateRangeSheet> {
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
  }

  void _selectDay(DateTime date) {
    setState(() {
      if (_start == null || _end != null || date.isBefore(_start!)) {
        _start = date;
        _end = null;
      } else {
        _end = date;
      }
    });
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Seçilmedi';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      height: MediaQuery.sizeOf(context).height * .58,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 10, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tarih Aralığı Seç',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _DateValue(
                      label: 'Başlangıç',
                      value: _dateLabel(_start),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateValue(label: 'Bitiş', value: _dateLabel(_end)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 380,
                  height: 310,
                  child: Theme(
                    data: _compactCalendarTheme(context),
                    child: CalendarDatePicker(
                      initialDate: _end ?? _start ?? now,
                      firstDate: DateTime(2000),
                      lastDate: now,
                      onDateChanged: _selectDay,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _start != null && _end != null
                      ? () => Navigator.pop(
                          context,
                          DateTimeRange(start: _start!, end: _end!),
                        )
                      : null,
                  child: const Text('Tarih Aralığını Uygula'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ThemeData _compactCalendarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      datePickerTheme: base.datePickerTheme.copyWith(
        headerHeadlineStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        weekdayStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        dayStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        yearStyle: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class _DateValue extends StatelessWidget {
  final String label;
  final String value;

  const _DateValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
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
    final hasChanges =
        data['wasEdited'] == true ||
        data['updatedAt'] != null ||
        (data['changeHistory'] is List &&
            (data['changeHistory'] as List).isNotEmpty);

    final isSell = type == 'Satış';
    final color = isSell ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final icon = isSell ? Icons.south_west_rounded : Icons.north_east_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).push(
            noAnimationRoute(
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconBox(icon: icon, color: color),
                  if (hasChanges)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
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
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: type,
                            style: TextStyle(color: color),
                          ),
                          TextSpan(
                            text:
                                ' • ${formatQuantity(quantity)} adet • Birim: ${formatCurrency(price, currency)} • $formattedDate',
                          ),
                        ],
                      ),
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
                    style: const TextStyle(
                      color: Color(0xFF0F3150),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'İşlem Tutarı',
                    style: TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
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
