import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configuración de animación visual del logo/spinner de carga
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();

    // Ejecutamos la carga dinámica de recursos en segundo plano
    _initializeAppResources();
  }

  Future<void> _initializeAppResources() async {
    // 1. Simula o espera la carga real de recursos (ej: inicializar caché, SDKs, etc.)
    await Future.wait([
      Future.delayed(
        const Duration(seconds: 2),
      ), // Tiempo base para lucir la animación
      // Aquí puedes agregar futures reales como precargar configuraciones o autenticación
    ]);

    if (!mounted) return;

    // 2. Navegación fluida hacia el Home una vez todo está listo
    context.go(RoutePaths.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Color de fondo corporativo/oscuro del splash
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o elemento visual principal
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD600),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Que hay pa?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 32),
              // Indicador de progreso dinámico
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD600),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
