class Barang {
  final int id;
  final String kode;
  final String nama;
  final String satuan;
  final double hargaBeli;
  final double hargaJual;
  final int stok;

  Barang({
    required this.id,
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.hargaBeli,
    required this.hargaJual,
    required this.stok,
  });

  factory Barang.fromJson(Map<String, dynamic> json) => Barang(
        // Respons create backend hanya berisi kode & nama, jadi id bisa absen.
        id: json['id'] == null ? 0 : (json['id'] as num).toInt(),
        kode: json['kode']?.toString() ?? '',
        nama: json['nama']?.toString() ?? '',
        satuan: json['satuan']?.toString() ?? '',
        hargaBeli: double.tryParse(json['harga_beli']?.toString() ?? '0') ?? 0,
        hargaJual: double.tryParse(json['harga_jual']?.toString() ?? '0') ?? 0,
        stok: (json['stok'] as num?)?.toInt() ?? 0,
      );

  /// Payload create — kode digenerate otomatis oleh backend.
  Map<String, dynamic> toCreateJson() => {
        'nama': nama,
        'satuan': satuan,
        'harga_beli': hargaBeli,
        'harga_jual': hargaJual,
      };

  /// Payload update — kode tidak bisa diubah, stok hanya via penerimaan.
  Map<String, dynamic> toUpdateJson() => {
        'nama': nama,
        'satuan': satuan,
        'harga_beli': hargaBeli,
        'harga_jual': hargaJual,
      };
}

class BarangPage {
  final List<Barang> items;
  final int page;
  final int limit;
  final int total;

  BarangPage({required this.items, required this.page, required this.limit, required this.total});

  bool get hasMore => page * limit < total;
}
