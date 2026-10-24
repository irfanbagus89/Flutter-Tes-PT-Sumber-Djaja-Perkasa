class Supplier {
  final int id;
  final String kode;
  final String nama;
  final String? telepon;
  final String? alamat;
  final String status;
  final int? jumlahPo;
  final double? totalBelanja;

  Supplier({
    required this.id,
    required this.kode,
    required this.nama,
    this.telepon,
    this.alamat,
    required this.status,
    this.jumlahPo,
    this.totalBelanja,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    final statistik = json['statistik'];
    return Supplier(
      // Respons create backend hanya berisi kode & nama, jadi id bisa absen.
      id: json['id'] == null ? 0 : (json['id'] as num).toInt(),
      kode: json['kode']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      telepon: json['telepon']?.toString(),
      alamat: json['alamat']?.toString(),
      status: json['status']?.toString() ?? 'aktif',
      jumlahPo: statistik is Map && statistik['jumlah_po'] != null
          ? (statistik['jumlah_po'] as num).toInt()
          : null,
      totalBelanja: statistik is Map && statistik['total_belanja'] != null
          ? double.tryParse(statistik['total_belanja'].toString())
          : null,
    );
  }

  /// Payload create
  Map<String, dynamic> toCreateJson() => {
        'nama': nama,
        'telepon': telepon ?? '',
        'alamat': alamat ?? '',
      };

  /// Payload update 
  Map<String, dynamic> toUpdateJson() => {
        'nama': nama,
        'telepon': telepon,
        'alamat': alamat,
        'status': status,
      };
}

class SupplierPage {
  final List<Supplier> items;
  final int page;
  final int limit;
  final int total;

  SupplierPage({required this.items, required this.page, required this.limit, required this.total});

  bool get hasMore => page * limit < total;
}
