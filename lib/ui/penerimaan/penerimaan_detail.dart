import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/penerimaan.dart';
import '../../providers/penerimaan_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';

class PenerimaanDetail extends StatefulWidget {
  final int id;

  const PenerimaanDetail({super.key, required this.id});

  @override
  State<PenerimaanDetail> createState() => _PenerimaanDetailState();
}

class _PenerimaanDetailState extends State<PenerimaanDetail> {
  late Future<dynamic> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<PenerimaanProvider>().detailFetch(widget.id);
  }

  void _reload() {
    setState(() {
      _future = context.read<PenerimaanProvider>().detailFetch(widget.id);
    });
  }

  Future<void> _selesai() async {
    final ok = await confirmDialog(
      context,
      title: 'Selesaikan penerimaan?',
      message: 'Stok barang bertambah.',
      confirmLabel: 'Selesaikan',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final message = await context.read<PenerimaanProvider>().selesai(widget.id);
      if (mounted) {
        SuccessSnackBar.show(context, message);
        _reload();
      }
    } catch (e) {
      if (mounted) ErrorSnackBar.show(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus penerimaan?',
      message: 'Penerimaan pending akan dihapus permanen.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<PenerimaanProvider>().remove(widget.id);
      if (mounted) {
        SuccessSnackBar.show(context, 'Penerimaan dihapus');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ErrorSnackBar.show(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Penerimaan')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: AppCard(
                child: Text(snapshot.error.toString(), style: const TextStyle(color: AppColors.red)),
              ),
            );
          }
          final r = snapshot.data! as Penerimaan;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.noPenerimaan,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        StatusBadge(status: r.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 13, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          'PO: ${r.noPembelian ?? '-'}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          r.tanggal,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (r.status == 'pending') ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _selesai,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Selesaikan Penerimaan'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
                  onPressed: _busy ? null : _delete,
                  child: const Text('Hapus'),
                ),
              ],
              if (r.status == 'selesai') ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20, color: AppColors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Penerimaan selesai — stok sudah diperbarui.',
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SectionLabel('ITEM'),
              const SizedBox(height: 8),
              ...r.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.kodeBarang ?? ''} — ${item.namaBarang ?? ''}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        Text('+${item.qtyTerima} ${item.satuan ?? ''}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: AppColors.green)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
