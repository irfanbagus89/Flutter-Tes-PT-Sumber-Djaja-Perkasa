import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/supplier.dart';
import '../../providers/supplier_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SupplierForm extends StatefulWidget {
  final Supplier? existing;

  const SupplierForm({super.key, this.existing});

  @override
  State<SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<SupplierForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kode;
  late final TextEditingController _nama;
  late final TextEditingController _telepon;
  late final TextEditingController _alamat;
  late bool _aktif;
  bool _saving = false;
  bool _deleting = false;

  Supplier get _supplier => widget.existing!;

  @override
  void initState() {
    super.initState();
    _kode = TextEditingController(text: widget.existing?.kode);
    _nama = TextEditingController(text: widget.existing?.nama);
    _telepon = TextEditingController(text: widget.existing?.telepon);
    _alamat = TextEditingController(text: widget.existing?.alamat);
    _aktif = widget.existing?.status != 'nonaktif';
  }

  @override
  void dispose() {
    _kode.dispose();
    _nama.dispose();
    _telepon.dispose();
    _alamat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final supplier = Supplier(
      id: 0,
      kode: _kode.text.trim(),
      nama: _nama.text.trim(),
      telepon: _telepon.text.trim().isEmpty ? null : _telepon.text.trim(),
      alamat: _alamat.text.trim().isEmpty ? null : _alamat.text.trim(),
      status: _aktif ? 'aktif' : 'nonaktif',
    );
    try {
      final message = await context
          .read<SupplierProvider>()
          .save(supplier, id: widget.existing?.id);
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
      title: 'Hapus supplier?',
      message: 'Supplier "${_supplier.nama}" akan dihapus permanen.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _deleting = true);
    try {
      await context.read<SupplierProvider>().remove(_supplier.id);
      if (mounted) {
        SuccessSnackBar.show(context, 'Supplier dihapus');
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
      appBar: AppBar(title: Text(isEdit ? 'Edit Supplier' : 'Supplier Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isEdit) ...[
              _FieldLabel('Kode Supplier'),
              TextFormField(
                controller: _kode,
                enabled: false,
                style: const TextStyle(color: AppColors.muted),
                
              ),
              const SizedBox(height: 16),
            ],
            _FieldLabel('Nama Supplier'),
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(
                hintText: 'mis. CV Maju Jaya',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel('Telepon'),
            TextFormField(
              controller: _telepon,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'mis. 0812-3456-7890',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Telepon wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel('Alamat'),
            TextFormField(
              controller: _alamat,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'mis. Jl. Merdeka No. 10, Bandung',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Alamat wajib diisi' : null,
            ),
            if (isEdit) ...[
              const SizedBox(height: 20),
              const SectionLabel('Status'),
              Row(
                children: [
                  Expanded(
                    child: _StatusOption(
                      label: 'Aktif',
                      icon: Icons.check_circle_outline,
                      selected: _aktif,
                      color: AppColors.green,
                      onTap: () => setState(() => _aktif = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatusOption(
                      label: 'Nonaktif',
                      icon: Icons.do_not_disturb_on_outlined,
                      selected: !_aktif,
                      color: AppColors.red,
                      onTap: () => setState(() => _aktif = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Supplier nonaktif tidak bisa dipakai untuk PO baru',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
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
                      : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Supplier'),
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

class _StatusOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.10) : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? color : AppColors.muted),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
