import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/penerimaan_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'penerimaan_detail.dart';
import 'penerimaan_form.dart';

class PenerimaanPage extends StatefulWidget {
  const PenerimaanPage({super.key});

  @override
  State<PenerimaanPage> createState() => _PenerimaanPageState();
}

class _PenerimaanPageState extends State<PenerimaanPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PenerimaanProvider>().load(reset: true);
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 300) return;
    final provider = context.read<PenerimaanProvider>();
    if (provider.loading || provider.loadingMore || !provider.hasMore) return;
    provider.load();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PenerimaanProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('Penerimaan')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_penerimaan',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PenerimaanForm()),
          );
          if (mounted) provider.load(reset: true);
        },
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
                child: _statusChips(provider),
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
                child: EmptyState(icon: Icons.local_shipping_outlined, message: 'Belum ada penerimaan'),
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
                    final r = provider.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PenerimaanDetail(id: r.id)),
                        ),
                        child: Row(
                          children: [
                            const ItemAvatar(
                              icon: Icons.local_shipping_outlined,
                              color: AppColors.primary,
                              bg: AppColors.primarySoft,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.noPenerimaan,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PO: ${r.noPembelian ?? '-'} • ${r.tanggal}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: r.status),
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

  Widget _statusChips(PenerimaanProvider provider) {
    const filters = ['', 'pending', 'selesai'];
    return Row(
      children: [
        for (final f in filters) ...[
          _chip(f, provider),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _chip(String value, PenerimaanProvider provider) {
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
