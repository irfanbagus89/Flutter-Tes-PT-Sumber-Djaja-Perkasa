import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pembelian_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'pembelian_form.dart';

class PembelianDetail extends StatefulWidget {
  final int id;

  const PembelianDetail({super.key, required this.id});

  @override
  State<PembelianDetail> createState() => _PembelianDetailState();
}

class _PembelianDetailState extends State<PembelianDetail> {
  late Future<dynamic> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<PembelianProvider>().detail(widget.id);
  }

  void _reload() {
    setState(() {
      _future = context.read<PembelianProvider>().detail(widget.id);
    });
  }

  Future<void> _changeStatus(String status) async {
    final ok = await confirmDialog(
      context,
      title: 'Ubah status?',
      message: 'Status pembelian akan diubah menjadi "$status".',
      confirmLabel: 'Ubah',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final message = await context.read<PembelianProvider>().changeStatus(widget.id, status);
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
      title: 'Hapus pembelian?',
      message: 'Pembelian draft akan dihapus permanen.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<PembelianProvider>().remove(widget.id);
      if (mounted) {
        SuccessSnackBar.show(context, 'Pembelian dihapus');
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
      appBar: AppBar(title: const Text('Detail Pembelian'), actions: [
        if (_busy) const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
      ]),
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
          final p = snapshot.data!;
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
                            p.noPembelian,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        StatusBadge(status: p.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${p.kodeSupplier ?? ''} — ${p.namaSupplier ?? ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          p.tanggal,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (p.isDraft)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _changeStatus('diproses'),
                        child: const Text('Proses'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
                        onPressed: () => _changeStatus('dibatalkan'),
                        child: const Text('Batalkan'),
                      ),
                    ),
                  ],
                ),
              if (p.isDraft) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PembelianForm(editId: p.id),
                            ),
                          );
                          _reload();
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
                        onPressed: _delete,
                        child: const Text('Hapus'),
                      ),
                    ),
                  ],
                ),
              ],
              if (p.isDiproses)
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Buat penerimaan barang melalui tab Penerimaan.',
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SectionLabel('ITEM'),
              const SizedBox(height: 8),
              ...p.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('${item.kodeBarang ?? ''} — ${item.namaBarang ?? ''}',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                            Text(
                              '${item.qtyDiterima}/${item.qty}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: item.qtyDiterima >= item.qty
                                    ? AppColors.green
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.qty} ${item.satuan ?? ''} × ${formatRupiah(item.harga)}',
                              style: const TextStyle(fontSize: 13, color: AppColors.muted),
                            ),
                            Text(formatRupiah(item.subtotal),
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      formatRupiah(p.total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
