import '../core/api_client.dart' as api;
import '../models/barang.dart';

class BarangService {
  Future<BarangPage> list({String? search, int page = 1, int limit = 20}) async {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (search != null && search.isNotEmpty) query['search'] = search;
    final data = await api.get('/barang', query);
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
    return BarangPage(
      items: list.map((e) => Barang.fromJson(e)).toList(),
      page: page,
      limit: limit,
      total: total,
    );
  }

  Future<Barang> detail(int id) async {
    final data = await api.get('/barang/$id');
    return Barang.fromJson(data);
  }

  Future<Barang> create(Barang b) async {
    final data = await api.post('/barang', b.toCreateJson());
    return Barang.fromJson(data);
  }

  Future<Barang> update(int id, Barang b) async {
    final data = await api.patch('/barang/$id', b.toUpdateJson());
    return Barang.fromJson(data);
  }

  Future<void> delete(int id) async {
    await api.delete('/barang/$id');
  }
}
