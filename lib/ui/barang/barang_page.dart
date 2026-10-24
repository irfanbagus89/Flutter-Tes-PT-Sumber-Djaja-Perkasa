import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/barang_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'barang_detail.dart';
import 'barang_form.dart';

class BarangPage extends StatefulWidget {
  const BarangPage({super.key});

  @override
  State<BarangPage> createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BarangProvider>().load(reset: true);
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
    final provider = context.read<BarangProvider>();
    if (provider.loading || provider.loadingMore || !provider.hasMore) return;
    provider.load();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final provider = context.read<BarangProvider>();
      provider.search = v;
      provider.load(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BarangProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('Barang')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_barang',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BarangForm()),
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
                child: TextField(
                  controller: _controller,
                  onChanged: _onSearchChanged,
                  onSubmitted: (v) {
                    _debounce?.cancel();
                    _onSearchChanged(v);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Cari kode atau nama barang...',
                    prefixIcon: Icon(Icons.search, size: 20, color: AppColors.muted),
                  ),
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
                child: EmptyState(icon: Icons.inventory_2_outlined, message: 'Belum ada barang'),
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
                    final b = provider.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BarangDetail(id: b.id)),
                        ),
                        child: Row(
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    b.kode,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${formatRupiah(b.hargaJual)} • Stok: ${b.stok} ${b.satuan}',
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.muted, size: 22),
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
}
