import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/barang.dart';
import '../../providers/barang_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'barang_form.dart';

class BarangDetail extends StatefulWidget {
  final int id;

  const BarangDetail({super.key, required this.id});

  @override
  State<BarangDetail> createState() => _BarangDetailState();
}

class _BarangDetailState extends State<BarangDetail> {
  late Future<Barang> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<BarangProvider>().detail(widget.id);
  }

  void _reload() {
    setState(() {
      _future = context.read<BarangProvider>().detail(widget.id);
    });
  }

  Future<void> _openEdit() async {
    final b = await _future;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BarangForm(existing: b)),
    );
    if (mounted) _reload();
  }

  Future<void> _delete() async {
    final provider = context.read<BarangProvider>();
    final b = await provider.detail(widget.id);
    if (!mounted) return;
    final ok = await confirmDialog(
      context,
      title: 'Hapus barang?',
      message: 'Barang "${b.nama}" akan dihapus permanen.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await provider.remove(widget.id);
      if (mounted) {
        SuccessSnackBar.show(context, 'Barang dihapus');
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
      appBar: AppBar(
        title: const Text('Detail Barang'),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<Barang>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: AppCard(
                child: Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: AppColors.red),
                ),
              ),
            );
          }
          final b = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
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
                        const ItemAvatar(
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.primary,
                          bg: AppColors.primarySoft,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.nama,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                b.kode,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.straighten_outlined,
                      label: 'Satuan',
                      value: b.satuan,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Harga Beli',
                      value: formatRupiah(b.hargaBeli),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.sell_outlined,
                      label: 'Harga Jual',
                      value: formatRupiah(b.hargaJual),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  StatTile(
                    label: 'Stok',
                    value: '${b.stok} ${b.satuan}',
                    icon: Icons.warehouse_outlined,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 12),
                  StatTile(
                    label: 'Nilai Stok',
                    value: formatRupiah(b.stok * b.hargaBeli),
                    icon: Icons.payments_outlined,
                    color: AppColors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Actions
              FilledButton.icon(
                onPressed: _busy ? null : _openEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Barang'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Hapus Barang'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _InfoRow({required this.icon, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasValue ? value! : '—',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue ? AppColors.ink : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
