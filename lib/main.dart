import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/barang_provider.dart';
import 'providers/pembelian_provider.dart';
import 'providers/penerimaan_provider.dart';
import 'providers/supplier_provider.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

void main() {
  runApp(const TesDjadjaApp());
}

class TesDjadjaApp extends StatelessWidget {
  const TesDjadjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SupplierProvider()..load(reset: true)),
        ChangeNotifierProvider(create: (_) => BarangProvider()..load(reset: true)),
        ChangeNotifierProvider(create: (_) => PembelianProvider()..load()),
        ChangeNotifierProvider(create: (_) => PenerimaanProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Studi kasus 3',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeShell(),
      ),
    );
  }
}
