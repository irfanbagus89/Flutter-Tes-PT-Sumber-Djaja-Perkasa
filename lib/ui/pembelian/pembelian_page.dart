import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pembelian_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'pembelian_detail.dart';
import 'pembelian_form.dart';

class PembelianPage extends StatefulWidget {
  const PembelianPage({super.key});

  @override
  State<PembelianPage> createState() => _PembelianPageState();
}

class _PembelianPageState extends State<PembelianPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PembelianProvider>().load(reset: true);
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
    final provider = context.read<PembelianProvider>();
    if (provider.loading || provider.loadingMore || !provider.hasMore) return;
    provider.load();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final provider = context.read<PembelianProvider>();
      provider.search = v;
      provider.load(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PembelianProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('Pembelian')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_pembelian',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PembelianForm()),
        ),
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
                        hintText: 'Cari nomor pembelian...',
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
                child: EmptyState(icon: Icons.receipt_long_outlined, message: 'Belum ada pembelian'),
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
                    final p = provider.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PembelianDetail(id: p.id)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ItemAvatar(
                              icon: Icons.receipt_long_outlined,
                              color: AppColors.primary,
                              bg: AppColors.primarySoft,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.noPembelian,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.namaSupplier ?? '—',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        p.tanggal,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      Text(
                                        formatRupiah(p.total),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            StatusBadge(status: p.status),
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

  Widget _statusChips(PembelianProvider provider) {
    const filters = ['', 'draft', 'diproses', 'diterima', 'dibatalkan'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in filters) ...[
            _chip(f, provider),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _chip(String value, PembelianProvider provider) {
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
