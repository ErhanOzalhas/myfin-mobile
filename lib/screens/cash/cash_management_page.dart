import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/cash_movement.dart';
import '../../repositories/cash_repository.dart';
import '../../utils/myfin_formatters.dart';
import '../../widgets/navigation/myfin_back_button.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';

class CashManagementPage extends StatelessWidget {
  const CashManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const MyFinBackButton(),
        title: const Text('TL Nakit'),
      ),
      body: StreamBuilder<CashBalanceSnapshot>(
        stream: CashRepository.instance.watchBalance(),
        initialData: CashBalanceSnapshot.empty,
        builder: (context, snapshot) {
          final data = snapshot.data ?? CashBalanceSnapshot.empty;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _BalanceCard(balance: data.balance),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          _openMovementSheet(context, CashMovementType.deposit),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Para Ekle'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: data.balance <= 0
                          ? null
                          : () => _openMovementSheet(
                              context,
                              CashMovementType.withdrawal,
                            ),
                      icon: const Icon(Icons.remove_rounded),
                      label: const Text('Para Çek'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Nakit Hareketleri',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (data.movements.isEmpty)
                const _EmptyMovements()
              else
                ...data.movements.map(
                  (movement) => _MovementTile(
                    movement,
                    onEdit: movement.transactionId == null
                        ? () => _openEditSheet(context, movement)
                        : null,
                    onDelete: movement.transactionId == null
                        ? () => _confirmDelete(context, movement)
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: const MyFinBottomNav(selectedIndex: 1),
    );
  }

  Future<void> _openMovementSheet(BuildContext context, CashMovementType type) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CashMovementSheet(type: type),
    );
  }

  Future<void> _openEditSheet(BuildContext context, CashMovement movement) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _CashMovementSheet(type: movement.type, movement: movement),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CashMovement movement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nakit hareketini sil'),
        content: Text(
          '${formatCurrency(movement.amount.abs(), 'TRY')} tutarındaki hareket silinecek. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await CashRepository.instance.deleteManualMovement(movement);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _CashMovementSheet extends StatefulWidget {
  const _CashMovementSheet({required this.type, this.movement});

  final CashMovementType type;
  final CashMovement? movement;

  @override
  State<_CashMovementSheet> createState() => _CashMovementSheetState();
}

class _CashMovementSheetState extends State<_CashMovementSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  bool get _isDeposit => widget.type == CashMovementType.deposit;
  bool get _isEdit => widget.movement != null;

  @override
  void initState() {
    super.initState();
    final movement = widget.movement;
    if (movement != null) {
      _amountController.text = movement.amount
          .abs()
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _noteController.text = movement.note;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final raw = _amountController.text
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final amount = double.tryParse(raw) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Geçerli bir tutar girin.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final movement = widget.movement;
      if (movement == null) {
        await CashRepository.instance.addManualMovement(
          type: widget.type,
          amount: amount,
          date: DateTime.now(),
          note: _noteController.text,
        );
      } else {
        await CashRepository.instance.updateManualMovement(
          movement: movement,
          amount: amount,
          note: _noteController.text,
        );
      }
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit
                ? 'Nakit Hareketini Düzenle'
                : _isDeposit
                ? 'TL Nakit Ekle'
                : 'TL Nakit Çek',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Tutar',
              prefixText: '₺ ',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Not (isteğe bağlı)',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEdit
                          ? 'Değişiklikleri Kaydet'
                          : _isDeposit
                          ? 'Bakiyeye Ekle'
                          : 'Bakiyeden Çek',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF0E7490)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kullanılabilir TL Nakit',
            style: TextStyle(color: Colors.white.withValues(alpha: .72)),
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(balance, 'TRY'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yatırım performansından ayrı, toplam finansal varlığa dahildir.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .68),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile(this.movement, {this.onEdit, this.onDelete});

  final CashMovement movement;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final positive = movement.amount >= 0;
    final title = switch (movement.type) {
      CashMovementType.deposit => 'Para Ekleme',
      CashMovementType.withdrawal => 'Para Çekme',
      CashMovementType.buy => 'Varlık Alımı',
      CashMovementType.sell => 'Varlık Satışı',
      CashMovementType.adjustment => 'Bakiye Düzeltme',
    };
    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (positive ? Colors.green : Colors.red).withValues(
            alpha: .10,
          ),
          child: Icon(
            positive ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: positive ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          movement.note.isEmpty
              ? _date(movement.movementDate)
              : '${movement.note} · ${_date(movement.movementDate)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 142),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${positive ? '+' : '−'}${formatCurrency(movement.amount.abs(), 'TRY')}',
                  style: TextStyle(
                    color: positive
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                tooltip: 'Hareket işlemleri',
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}

class _EmptyMovements extends StatelessWidget {
  const _EmptyMovements();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Henüz nakit hareketi yok. İlk TL bakiyenizi “Para Ekle” ile oluşturabilirsiniz.',
        style: TextStyle(color: Color(0xFF64748B), height: 1.4),
      ),
    );
  }
}
