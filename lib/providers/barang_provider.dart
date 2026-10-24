import 'package:flutter/foundation.dart';

import '../models/barang.dart';
import '../services/barang_service.dart';

class BarangProvider extends ChangeNotifier {
  final _service = BarangService();

  List<Barang> items = [];
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;
  String search = '';
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
      final page = await _service.list(search: search, page: _page);
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

  Future<Barang> detail(int id) => _service.detail(id);

  Future<String> save(Barang b, {int? id}) async {
    if (id == null) await _service.create(b);
    else await _service.update(id, b);
    await refresh();
    return id == null ? 'Barang ditambahkan' : 'Barang diperbarui';
  }

  Future<void> remove(int id) async {
    await _service.delete(id);
    await refresh();
  }
}
