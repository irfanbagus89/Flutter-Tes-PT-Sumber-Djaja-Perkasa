import 'package:flutter/foundation.dart';

import '../models/pembelian.dart';
import '../services/pembelian_service.dart';

class PembelianProvider extends ChangeNotifier {
  final _service = PembelianService();

  List<Pembelian> items = [];
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;
  String search = '';
  String statusFilter = '';
  int _page = 1;

  Future<void> refresh() => load(reset: true);

  Future<void> load({bool reset = false}) async {
    if (loading || loadingMore) return;
    if (!reset && !hasMore) return;
    if (reset) {
      _page = 1;
      hasMore = true;
    }
    if (reset) {
      loading = true;
    } else {
      loadingMore = true;
    }
    error = null;
    notifyListeners();
    try {
      final page = await _service.list(
        status: statusFilter,
        search: search,
        page: _page,
      );
      if (reset) items = page.items;
      else items = [...items, ...page.items];
      hasMore = page.hasMore;
      _page++;
    } catch (e) {
      error = e.toString();
      if (reset) hasMore = false;
    } finally {
      loading = false;
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<Pembelian> detail(int id) => _service.detail(id);

  Future<List<Pembelian>> fetchAll({String? status}) async {
    final first = await _service.list(status: status, page: 1, limit: 100);
    if (!first.hasMore) return first.items;
    var all = [...first.items];
    var p = 2;
    while ((p - 1) * 100 < first.total) {
      final next = await _service.list(status: status, page: p, limit: 100);
      all = [...all, ...next.items];
      p++;
    }
    return all;
  }

  Future<String> create({
    required int supplierId,
    required String tanggal,
    required List<Map<String, dynamic>> items,
  }) async {
    await _service.create(supplierId: supplierId, tanggal: tanggal, items: items);
    await load(reset: true);
    return 'Pembelian dibuat';
  }

  Future<String> update({
    required int id,
    required int supplierId,
    required String tanggal,
    required List<Map<String, dynamic>> items,
  }) async {
    await _service.update(id: id, supplierId: supplierId, tanggal: tanggal, items: items);
    await load(reset: true);
    return 'Pembelian diperbarui';
  }

  Future<void> remove(int id) async {
    await _service.delete(id);
    await load(reset: true);
  }

  Future<String> changeStatus(int id, String status) async {
    await _service.changeStatus(id, status);
    await load(reset: true);
    return 'Status diubah menjadi $status';
  }
}
