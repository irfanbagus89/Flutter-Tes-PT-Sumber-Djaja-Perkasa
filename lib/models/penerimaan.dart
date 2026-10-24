/// mysql2 mengembalikan DECIMAL/SUM sebagai String — parse aman keduanya.
int _toInt(dynamic v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

/// Backend mengembalikan tanggal ISO penuh — ambil YYYY-MM-DD saja.
String _dateOnly(dynamic v) {
  final s = v?.toString() ?? '';
  return s.length >= 10 ? s.substring(0, 10) : s;
}

class PenerimaanItem {
  final int? id;
  final int barangId;
  final String? kodeBarang;
  final String? namaBarang;
  final String? satuan;
  final int qtyTerima;

  PenerimaanItem({
    this.id,
    required this.barangId,
    this.kodeBarang,
    this.namaBarang,
    this.satuan,
    required this.qtyTerima,
  });

  factory PenerimaanItem.fromJson(Map<String, dynamic> json) => PenerimaanItem(
        id: json['id'] == null ? null : _toInt(json['id']),
        barangId: _toInt(json['barang_id']),
        kodeBarang: json['barang_kode']?.toString() ??
            json['kode_barang']?.toString() ??
            json['kode']?.toString(),
        namaBarang: json['barang_nama']?.toString() ??
            json['nama_barang']?.toString() ??
            json['nama']?.toString(),
        satuan: json['satuan']?.toString(),
        qtyTerima: _toInt(json['qty_terima']),
      );
}

class Penerimaan {
  final int id;
  final String noPenerimaan;
  final int pembelianId;
  final String? noPembelian;
  final String tanggal;
  final String status;
  final List<PenerimaanItem> items;

  Penerimaan({
    required this.id,
    required this.noPenerimaan,
    required this.pembelianId,
    this.noPembelian,
    required this.tanggal,
    required this.status,
    this.items = const [],
  });

  factory Penerimaan.fromJson(Map<String, dynamic> json) => Penerimaan(
        // Respons create backend hanya berisi no_penerimaan & status,
        // jadi id / pembelian_id bisa absen.
        id: _toInt(json['id']),
        noPenerimaan: json['no_penerimaan']?.toString() ?? '',
        pembelianId: _toInt(json['pembelian_id']),
        noPembelian: (json['pembelian'] is Map
                ? json['pembelian']['no_pembelian']
                : json['no_pembelian'])
            ?.toString(),
        tanggal: _dateOnly(json['tanggal']),
        status: json['status']?.toString() ?? 'pending',
        items: json['items'] is List
            ? (json['items'] as List).map((e) => PenerimaanItem.fromJson(e)).toList()
            : const [],
      );
}

class PenerimaanList {
  final List<Penerimaan> items;
  final int page;
  final int limit;
  final int total;

  PenerimaanList({required this.items, required this.page, required this.limit, required this.total});

  bool get hasMore => page * limit < total;
}
