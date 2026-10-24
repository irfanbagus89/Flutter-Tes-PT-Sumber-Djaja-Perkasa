import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/barang.dart';
import '../../providers/barang_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';

class BarangForm extends StatefulWidget {
  final Barang? existing;

  const BarangForm({super.key, this.existing});

  @override
  State<BarangForm> createState() => _BarangFormState();
}

class _BarangFormState extends State<BarangForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kode;
  late final TextEditingController _nama;
  late final TextEditingController _satuan;
  late final TextEditingController _hargaBeli;
  late final TextEditingController _hargaJual;
  bool _saving = false;
  bool _deleting = false;

  Barang get _barang => widget.existing!;

  @override
  void initState() {
    super.initState();
    _kode = TextEditingController(text: widget.existing?.kode);
    _nama = TextEditingController(text: widget.existing?.nama);
    _satuan = TextEditingController(text: widget.existing?.satuan);
    _hargaBeli = TextEditingController(
      text: widget.existing == null ? '' : _group(_num(widget.existing!.hargaBeli)),
    );
    _hargaJual = TextEditingController(
      text: widget.existing == null ? '' : _group(_num(widget.existing!.hargaJual)),
    );
  }

  String _num(double v) =>
      v.truncateToDouble() == v ? v.toInt().toString() : v.toString();

  static String _strip(String s) => s.replaceAll('.', '');

  static String _group(String s) {
    if (s.isEmpty) return s;
    final hasDecimal = s.contains('.');
    final parts = hasDecimal ? s.split('.') : [s, ''];
    final intPart = parts[0].replaceAll(RegExp(r'^0+(?=\d)'), '');
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      final remaining = intPart.length - i;
      buf.write(intPart[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write('.');
    }
    return hasDecimal && parts[1].isNotEmpty ? '$buf.${parts[1]}' : buf.toString();
  }

  @override
  void dispose() {
    _kode.dispose();
    _nama.dispose();
    _satuan.dispose();
    _hargaBeli.dispose();
    _hargaJual.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final barang = Barang(
      id: 0,
      kode: _kode.text.trim(),
      nama: _nama.text.trim(),
      satuan: _satuan.text.trim(),
      hargaBeli: double.tryParse(_strip(_hargaBeli.text)) ?? 0,
      hargaJual: double.tryParse(_strip(_hargaJual.text)) ?? 0,
      stok: 0,
    );
    try {
      final message =
          await context.read<BarangProvider>().save(barang, id: widget.existing?.id);
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

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus barang?',
      message: 'Barang "${_barang.nama}" akan dihapus permanen.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _deleting = true);
    try {
      await context.read<BarangProvider>().remove(_barang.id);
      if (mounted) {
        SuccessSnackBar.show(context, 'Barang dihapus');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ErrorSnackBar.show(context, e);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Detail Barang' : 'Barang Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isEdit) ...[
              _FieldLabel('Kode Barang'),
              TextFormField(
                controller: _kode,
                enabled: false,
                style: const TextStyle(color: AppColors.muted),
               
              ),
              const SizedBox(height: 16),
            ],
            _FieldLabel('Nama Barang'),
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(
                hintText: 'mis. Beras Premium 5kg',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel('Satuan'),
            TextFormField(
              controller: _satuan,
              decoration: const InputDecoration(
                hintText: 'mis. pcs, kg, pack',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Satuan wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel('Harga Beli'),
            TextFormField(
              controller: _hargaBeli,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                _ThousandsSeparatorInputFormatter(),
              ],
              decoration: const InputDecoration(
                hintText: 'mis. 85.000',
                prefixIcon: _RupiahPrefix(),
                prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Harga beli wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel('Harga Jual'),
            TextFormField(
              controller: _hargaJual,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                _ThousandsSeparatorInputFormatter(),
              ],
              decoration: const InputDecoration(
                hintText: 'mis. 100.000',
                prefixIcon: _RupiahPrefix(),
                prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Harga jual wajib diisi' : null,
            ),
            if (isEdit) ...[
              const SizedBox(height: 8),
              const Text(
                'Stok hanya bertambah melalui penerimaan barang.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Barang'),
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
                    onPressed: _deleting ? null : _delete,
                    child: _deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Hapus'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.inkSoft,
        ),
      ),
    );
  }
}

/// Prefix "Rp" yang tampil permanen (focus maupun tidak).
class _RupiahPrefix extends StatelessWidget {
  const _RupiahPrefix();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 14, right: 2),
      child: Text(
        'Rp',
        style: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}

/// Menampilkan angka dengan pemisah ribuan (3.000, 12.500, dst)
/// saat diketik. Nilai tersimpan tetap angka murni (3000).
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll('.', '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final grouped = _groupDigits(digitsOnly);

    // Pertahankan posisi kursor relatif terhadap digit di depan kursor.
    final selectionIndex = newValue.selection.baseOffset;
    final digitsBeforeCursor =
        newValue.text.substring(0, selectionIndex.clamp(0, newValue.text.length)).replaceAll('.', '');
    var cursor = 0;
    var counted = 0;
    for (var i = 0; i < grouped.length; i++) {
      if (grouped[i] != '.') counted++;
      cursor = i + 1;
      if (counted >= digitsBeforeCursor.length) break;
    }

    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  static String _groupDigits(String s) {
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
