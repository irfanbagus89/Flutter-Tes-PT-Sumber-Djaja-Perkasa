import 'package:flutter/foundation.dart';

import '../models/supplier.dart';
import '../services/supplier_service.dart';

class SupplierProvider extends ChangeNotifier {
  final _service = SupplierService();

  List<Supplier> items = [];
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
        search: search,
        status: statusFilter,
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

  Future<Supplier> detail(int id) => _service.detail(id);

  Future<String> save(Supplier s, {int? id}) async {
    try {
      if (id == null) await _service.create(s);
      else await _service.update(id, s);
      await refresh();
      return id == null ? 'Supplier ditambahkan' : 'Supplier diperbarui';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> remove(int id) async {
    await _service.delete(id);
    await refresh();
  }
}
