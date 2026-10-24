import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/barang_provider.dart';
import '../../models/barang.dart';
import '../../providers/pembelian_provider.dart';
import '../../providers/supplier_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';

class PembelianForm extends StatefulWidget {
  final int? editId;

  const PembelianForm({super.key, this.editId});

  @override
  State<PembelianForm> createState() => _PembelianFormState();
}

class _PembelianFormState extends State<PembelianForm> {
  bool _saving = false;
  int? _supplierId;
  String _tanggal = '';
  final List<_ItemRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _tanggal = DateTime.now().toIso8601String().substring(0, 10);
    if (widget.editId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final p = await context.read<PembelianProvider>().detail(widget.editId!);
          if (!mounted) return;
          setState(() {
            _supplierId = p.supplierId;
            _tanggal = p.tanggal;
            for (final item in p.items) {
              _rows.add(_ItemRow(barang: Barang(id: item.barangId, kode: item.kodeBarang ?? '', nama: item.namaBarang ?? '', satuan: item.satuan ?? '', hargaBeli: item.harga, hargaJual: 0, stok: 0), qty: item.qty));
              _rows.last.hargaCtrl.text = _formatHarga(item.harga);
            }
          });
        } catch (e) {
          if (mounted) ErrorSnackBar.show(context, e);
        }
      });
    }
  }

  String _formatHarga(double v) => _ItemRow._formatHarga(v);

  double get _total =>
      _rows.fold(0, (sum, r) => sum + r.qty * r.barang.hargaBeli);

  Future<void> _addRow() async {
    final barangProvider = context.read<BarangProvider>();
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Pilih Barang', style: TextStyle(fontSize: 16)),
        children: barangProvider.items
            .map(
              (b) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, b.id),
                child: Text('${b.kode} — ${b.nama}'),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null) return;
    final barang = barangProvider.items.firstWhere((b) => b.id == selected);
    setState(() {
      _rows.add(_ItemRow(barang: barang));
    });
  }

  Future<void> _save() async {
    if (_supplierId == null) {
      ErrorSnackBar.show(context, 'Pilih supplier terlebih dahulu');
      return;
    }
    if (_rows.isEmpty) {
      ErrorSnackBar.show(context, 'Minimal 1 item barang');
      return;
    }
    final provider = context.read<PembelianProvider>();
    final items = _rows
        .map((r) => {
              'barang_id': r.barang.id,
              'qty': r.qty,
              'harga': r.barang.hargaBeli,
            })
        .toList();
    setState(() => _saving = true);
    try {
      final message = widget.editId == null
          ? await provider.create(supplierId: _supplierId!, tanggal: _tanggal, items: items)
          : await provider.update(
              id: widget.editId!, supplierId: _supplierId!, tanggal: _tanggal, items: items);
      if (mounted) {
        SuccessSnackBar.show(context, message);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ErrorSnackBar.show(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final barangProvider = context.watch<BarangProvider>();
    final activeSuppliers =
        supplierProvider.items.where((s) => s.status == 'aktif').toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.editId == null ? 'Pembelian Baru' : 'Edit Pembelian')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionLabel('SUPPLIER'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _supplierId,
            decoration: const InputDecoration(hintText: 'Pilih supplier'),
            items: activeSuppliers
                .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.kode} — ${s.nama}')))
                .toList(),
            onChanged: (v) => setState(() => _supplierId = v),
          ),
          const SizedBox(height: 16),
          SectionLabel('TANGGAL'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(_tanggal) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _tanggal = picked.toIso8601String().substring(0, 10));
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.muted),
              ),
              child: Text(_tanggal),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionLabel('ITEM (${_rows.length})'),
              TextButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
              ),
            ],
          ),
          ..._rows.asMap().entries.map(
                (entry) => _buildRow(entry.key, entry.value, barangProvider),
              ),
          if (_rows.isEmpty)
            AppCard(
              child: Center(
                child: Text(
                  'Belum ada item — tekan "Tambah"',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                  Text(formatRupiah(_total),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Pembelian'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(int index, _ItemRow row, BarangProvider barangProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${row.barang.kode} — ${row.barang.nama}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                  onPressed: () => setState(() => _rows.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Qty', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: row.qty > 1 ? () => setState(() => row.qty--) : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                ),
                Text('${row.qty}', style: const TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => row.qty++),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                ),
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: row.hargaCtrl,
                    readOnly: true,
                    style: const TextStyle(color: AppColors.inkSoft),
                    decoration: const InputDecoration(
                      prefixIcon: _RupiahPrefix(),
                      prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow {
  final Barang barang;
  int qty;
  late final TextEditingController hargaCtrl;

  _ItemRow({required this.barang, this.qty = 1}) {
    hargaCtrl = TextEditingController(text: _formatHarga(barang.hargaBeli));
  }

  static String _formatHarga(double v) {
    final s = v.truncateToDouble() == v ? v.toInt().toString() : v.toString();
    final buf = StringBuffer();
    final len = s.length;
    for (var i = 0; i < len; i++) {
      buf.write(s[i]);
      final remaining = len - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buf.write('.');
    }
    return buf.toString();
  }
}

/// Prefix "Rp" yang tampil permanen (focus maupun tidak).
class _RupiahPrefix extends StatelessWidget {
  const _RupiahPrefix();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 12, right: 2),
      child: Text(
        'Rp',
        style: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

