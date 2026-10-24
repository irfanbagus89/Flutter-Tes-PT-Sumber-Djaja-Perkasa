import '../core/api_client.dart' as api;
import '../models/penerimaan.dart';

class PenerimaanService {
  Future<PenerimaanList> list({
    String? status,
    int? pembelianId,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (pembelianId != null) query['pembelianId'] = '$pembelianId';
    final data = await api.get('/penerimaan', query);
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
    return PenerimaanList(
      items: list.map((e) => Penerimaan.fromJson(e)).toList(),
      page: page,
      limit: limit,
      total: total,
    );
  }

  Future<Penerimaan> detail(int id) async {
    final data = await api.get('/penerimaan/$id');
    return Penerimaan.fromJson(data);
  }

  Future<Penerimaan> create({
    required int pembelianId,
    required String tanggal,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await api.post('/penerimaan', {
      'pembelian_id': pembelianId,
      'tanggal': tanggal,
      'items': items,
    });
    return Penerimaan.fromJson(data);
  }

  Future<void> selesai(int id) async {
    await api.patch('/penerimaan/$id/selesai', {});
  }

  Future<void> delete(int id) async {
    await api.delete('/penerimaan/$id');
  }
}
