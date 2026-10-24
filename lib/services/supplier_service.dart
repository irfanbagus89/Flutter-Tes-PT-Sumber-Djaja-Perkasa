import '../core/api_client.dart' as api;
import '../models/supplier.dart';

class SupplierService {
  Future<SupplierPage> list({String? search, String? status, int page = 1, int limit = 10}) async {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;
    final data = await api.get('/supplier', query);
    final list = data is Map
        ? (data['items'] ?? data['data'] ?? data['rows']) as List? ?? []
        : data as List? ?? [];
    final total = data is Map
        ? (data['pagination'] is Map
                ? (data['pagination']['total'] as num?)
                : (data['total'] as num?))
            ?.toInt() ??
            list.length
        : list.length;
    return SupplierPage(
      items: list.map((e) => Supplier.fromJson(e)).toList(),
      page: page,
      limit: limit,
      total: total,
    );
  }

  Future<Supplier> detail(int id) async {
    final data = await api.get('/supplier/$id');
    return Supplier.fromJson(data);
  }

  Future<Supplier> create(Supplier s) async {
    final data = await api.post('/supplier', s.toCreateJson());
    return Supplier.fromJson(data);
  }

  Future<Supplier> update(int id, Supplier s) async {
    final data = await api.patch('/supplier/$id', s.toUpdateJson());
    return Supplier.fromJson(data);
  }

  Future<void> delete(int id) async {
    await api.delete('/supplier/$id');
  }
}
