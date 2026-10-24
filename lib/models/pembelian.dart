/// mysql2 mengembalikan DECIMAL/SUM sebagai String — parse aman keduanya.
int _toInt(dynamic v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

double _toDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? fallback;
}

/// Backend mengembalikan tanggal ISO penuh (2026-10-22T17:00:00.000Z)
/// — ambil bagian tanggalnya saja (YYYY-MM-DD).
String _dateOnly(dynamic v) {
  final s = v?.toString() ?? '';
  return s.length >= 10 ? s.substring(0, 10) : s;
}

class PembelianItem {
  final int? id;
  final int barangId;
  final String? kodeBarang;
  final String? namaBarang;
  final String? satuan;
  final int qty;
  final double harga;
  final double subtotal;
  final int qtyDiterima;

  PembelianItem({
    this.id,
    required this.barangId,
    this.kodeBarang,
    this.namaBarang,
    this.satuan,
    required this.qty,
    required this.harga,
    required this.subtotal,
    this.qtyDiterima = 0,
  });

  factory PembelianItem.fromJson(Map<String, dynamic> json) => PembelianItem(
        id: json['id'] == null ? null : _toInt(json['id']),
        barangId: _toInt(json['barang_id']),
        kodeBarang: json['barang_kode']?.toString() ??
            json['kode_barang']?.toString() ??
            json['kode']?.toString(),
        namaBarang: json['barang_nama']?.toString() ??
            json['nama_barang']?.toString() ??
            json['nama']?.toString(),
        satuan: json['satuan']?.toString(),
        qty: _toInt(json['qty']),
        harga: _toDouble(json['harga']),
        subtotal: _toDouble(json['subtotal']),
        qtyDiterima: _toInt(json['qty_diterima']),
      );
}

class Pembelian {
  final int id;
  final String noPembelian;
  final String tanggal;
  final int supplierId;
  final String? namaSupplier;
  final String? kodeSupplier;
  final String status;
  final double total;
  final List<PembelianItem> items;

  Pembelian({
    required this.id,
    required this.noPembelian,
    required this.tanggal,
    required this.supplierId,
    this.namaSupplier,
    this.kodeSupplier,
    required this.status,
    required this.total,
    this.items = const [],
  });

  factory Pembelian.fromJson(Map<String, dynamic> json) => Pembelian(
        // Respons create backend hanya berisi no_pembelian & total,
        // jadi id / supplier_id bisa absen.
        id: _toInt(json['id']),
        noPembelian: json['no_pembelian']?.toString() ?? '',
        tanggal: _dateOnly(json['tanggal']),
        supplierId: _toInt(json['supplier_id']),
        namaSupplier:
            (json['supplier'] is Map ? json['supplier']['nama'] : json['nama_supplier'])?.toString(),
        kodeSupplier:
            (json['supplier'] is Map ? json['supplier']['kode'] : json['kode_supplier'])?.toString(),
        status: json['status']?.toString() ?? 'draft',
        total: _toDouble(json['total']),
        items: json['items'] is List
            ? (json['items'] as List).map((e) => PembelianItem.fromJson(e)).toList()
            : const [],
      );

  bool get isDraft => status == 'draft';
  bool get isDiproses => status == 'diproses';
  bool get isFinal => status == 'diterima' || status == 'dibatalkan';
}

class PembelianList {
  final List<Pembelian> items;
  final int page;
  final int limit;
  final int total;

  PembelianList({required this.items, required this.page, required this.limit, required this.total});

  bool get hasMore => page * limit < total;
}
