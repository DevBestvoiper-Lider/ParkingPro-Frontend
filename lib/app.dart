import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class ParkingProApp extends ConsumerWidget {
  const ParkingProApp({super.key, this.fuentesDeGoogle = true});

  /// En tests se desactiva para no descargar la fuente Inter.
  final bool fuentesDeGoogle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ParkingPro',
      debugShowCheckedModeBanner: false,
      theme: construirTema(fuentesDeGoogle: fuentesDeGoogle),
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
