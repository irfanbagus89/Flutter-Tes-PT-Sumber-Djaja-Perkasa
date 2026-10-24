import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/supplier_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'supplier_detail.dart';
import 'supplier_form.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().load(reset: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 300) return;
    final provider = context.read<SupplierProvider>();
    if (provider.loading || provider.loadingMore || !provider.hasMore) return;
    provider.load();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final provider = context.read<SupplierProvider>();
      provider.search = v;
      provider.load(reset: true);
    });
  }

  void _openForm() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierForm()));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('Supplier')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_supplier',
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller,
                      onChanged: _onSearchChanged,
                      onSubmitted: (v) {
                        _debounce?.cancel();
                        _onSearchChanged(v);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Cari kode atau nama supplier...',
                        prefixIcon: Icon(Icons.search, size: 20, color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _statusChips(provider),
                  ],
                ),
              ),
            ),
            if (provider.loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppCard(
                    child: Text(provider.error!, style: const TextStyle(color: AppColors.red)),
                  ),
                ),
              )
            else if (provider.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(icon: Icons.storefront_outlined, message: 'Belum ada supplier'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                sliver: SliverList.builder(
                  itemCount: provider.items.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= provider.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final s = provider.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupplierDetail(id: s.id),
                          ),
                        ),
                        child: Row(
                          children: [
                            const ItemAvatar(
                              icon: Icons.storefront_outlined,
                              color: AppColors.primary,
                              bg: AppColors.primarySoft,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.nama,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.kode,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: s.status),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChips(SupplierProvider provider) {
    const filters = ['', 'aktif', 'nonaktif'];
    return Row(
      children: [
        for (final f in filters) ...[
          _chip(f, provider),
          if (f != filters.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _chip(String value, SupplierProvider provider) {
    final selected = provider.statusFilter == value;
    return ChoiceChip(
      label: Text(value.isEmpty ? 'Semua' : value),
      selected: selected,
      onSelected: (_) {
        provider.statusFilter = value;
        provider.load(reset: true);
      },
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.primary : AppColors.muted,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      selectedColor: AppColors.primarySoft,
      showCheckmark: false,
    );
  }
}
