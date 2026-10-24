import '../core/api_client.dart' as api;
import '../models/pembelian.dart';

class PembelianService {
  Future<PembelianList> list({
    String? status,
    String? search,
    int? supplierId,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (supplierId != null) query['supplierId'] = '$supplierId';
    final data = await api.get('/pembelian', query);
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
    return PembelianList(
      items: list.map((e) => Pembelian.fromJson(e)).toList(),
      page: page,
      limit: limit,
      total: total,
    );
  }

  Future<Pembelian> detail(int id) async {
    final data = await api.get('/pembelian/$id');
    return Pembelian.fromJson(data);
  }

  Future<Pembelian> create({
    required int supplierId,
    required String tanggal,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await api.post('/pembelian', {
      'supplier_id': supplierId,
      'tanggal': tanggal,
      'items': items,
    });
    return Pembelian.fromJson(data);
  }

  Future<Pembelian> update({
    required int id,
    required int supplierId,
    required String tanggal,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await api.patch('/pembelian/$id', {
      'supplier_id': supplierId,
      'tanggal': tanggal,
      'items': items,
    });
    return Pembelian.fromJson(data);
  }

  Future<void> delete(int id) async {
    await api.delete('/pembelian/$id');
  }

  Future<Pembelian> changeStatus(int id, String status) async {
    final data = await api.patch('/pembelian/$id/status', {'status': status});
    return Pembelian.fromJson(data);
  }
}
