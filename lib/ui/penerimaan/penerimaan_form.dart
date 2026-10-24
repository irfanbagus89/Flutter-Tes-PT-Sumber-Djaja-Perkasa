import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pembelian.dart';
import '../../providers/pembelian_provider.dart';
import '../../providers/penerimaan_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';

class PenerimaanForm extends StatefulWidget {
  const PenerimaanForm({super.key});

  @override
  State<PenerimaanForm> createState() => _PenerimaanFormState();
}

class _PenerimaanFormState extends State<PenerimaanForm> {
  final Map<int, TextEditingController> _qtyControllers = {};
  Pembelian? _selectedPo;
  List<Pembelian> _poList = [];
  bool _loadingPo = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPo());
  }

  Future<void> _loadPo() async {
    try {
      // Ambil hanya PO berstatus 'diproses' — backend mendukung filter status.
      final list = await context.read<PembelianProvider>().fetchAll(status: 'diproses');
      setState(() {
        _poList = list.where((p) => p.isDiproses).toList();
        _loadingPo = false;
      });
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e);
        setState(() => _loadingPo = false);
      }
    }
  }

  Future<void> _selectPo(Pembelian po) async {
    final detail = await context.read<PembelianProvider>().detail(po.id);
    setState(() {
      _selectedPo = detail;
      for (final c in _qtyControllers.values) {
        c.dispose();
      }
      _qtyControllers.clear();
      for (final item in detail.items) {
        _qtyControllers[item.barangId] = TextEditingController(text: '0');
      }
    });
  }

  Future<void> _save() async {
    final po = _selectedPo;
    if (po == null) {
      ErrorSnackBar.show(context, 'Pilih pembelian (PO) terlebih dahulu');
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final item in po.items) {
      final qty = int.tryParse(_qtyControllers[item.barangId]?.text ?? '0') ?? 0;
      if (qty > 0) items.add({'barang_id': item.barangId, 'qty_terima': qty});
    }
    if (items.isEmpty) {
      ErrorSnackBar.show(context, 'Isi minimal 1 qty terima');
      return;
    }
    setState(() => _saving = true);
    try {
      final message = await context.read<PenerimaanProvider>().create(
            pembelianId: po.id,
            tanggal: DateTime.now().toIso8601String().substring(0, 10),
            items: items,
          );
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
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Penerimaan Baru')),
      body: _loadingPo
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionLabel('PEMBELIAN — STATUS DIPROSES'),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedPo?.id,
                  decoration: const InputDecoration(hintText: 'Pilih PO'),
                  items: _poList
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.noPembelian} — ${p.namaSupplier ?? ''}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      _selectPo(_poList.firstWhere((p) => p.id == v));
                    }
                  },
                ),
                if (_selectedPo != null) ...[
                  const SizedBox(height: 16),
                  SectionLabel('ITEM — QTY TERIMA'),
                  const SizedBox(height: 8),
                  ..._selectedPo!.items.map((item) {
                    final sisa = item.qty - item.qtyDiterima;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.kodeBarang ?? ''} — ${item.namaBarang ?? ''}',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              'PO: ${item.qty} • Diterima: ${item.qtyDiterima} • Sisa: $sisa ${item.satuan ?? ''}',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Terima',
                                    style: TextStyle(fontSize: 13, color: AppColors.muted)),
                                const SizedBox(width: 8),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    final ctrl = _qtyControllers[item.barangId]!;
                                    final v = int.tryParse(ctrl.text) ?? 0;
                                    if (v > 0) {
                                      ctrl.text = '${v - 1}';
                                      setState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller: _qtyControllers[item.barangId],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    final ctrl = _qtyControllers[item.barangId]!;
                                    final v = int.tryParse(ctrl.text) ?? 0;
                                    if (v < sisa) {
                                      ctrl.text = '${v + 1}';
                                      setState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _qtyControllers[item.barangId]!.text = '$sisa';
                                    setState(() {});
                                  },
                                  child: const Text('Sisa', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan Penerimaan'),
            ),
          ),
        ),
      ),
    );
  }
}
