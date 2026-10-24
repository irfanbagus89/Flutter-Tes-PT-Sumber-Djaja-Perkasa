import 'package:flutter/foundation.dart';

import '../models/penerimaan.dart';
import '../services/penerimaan_service.dart';

class PenerimaanProvider extends ChangeNotifier {
  final _service = PenerimaanService();

  List<Penerimaan> items = [];
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;
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
      final page = await _service.list(status: statusFilter, page: _page);
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

  Future<Penerimaan> detailFetch(int id) => _service.detail(id);

  Future<String> create({
    required int pembelianId,
    required String tanggal,
    required List<Map<String, dynamic>> items,
  }) async {
    await _service.create(pembelianId: pembelianId, tanggal: tanggal, items: items);
    await load(reset: true);
    return 'Penerimaan dibuat';
  }

  Future<String> selesai(int id) async {
    await _service.selesai(id);
    await load(reset: true);
    return 'Penerimaan selesai — stok diperbarui';
  }

  Future<void> remove(int id) async {
    await _service.delete(id);
    await load(reset: true);
  }
}
