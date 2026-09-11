import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/router/animations/circular_reveal_transition.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../authentication/presentation/pages/register_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/Home.mp4')
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0.0);
        _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- CAPA 1: Video de fondo ---
          if (_controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            Container(color: Colors.black),

          // --- CAPA 2: Oscurecedor semitransparente para legibilidad ---
          Container(color: Colors.black.withValues(alpha: 0.4)),

          // --- CAPA 3: Botones de Iniciar Sesión y Registrarse ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 48.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botón 1: Iniciar Sesión (Expansión circular con fondo amarillo del login)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                          ) => const LoginPage(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return AnimatedBuilder(
                                  animation: animation,
                                  builder: (context, childWidget) {
                                    return Stack(
                                      children: [
                                        Container(
                                          color: const Color(0xFFFFD600),
                                        ), // Color de fondo del Login
                                        ClipPath(
                                          clipper: CircularRevealClipper(
                                            progress: animation.value,
                                            alignment: const Alignment(0.0, 0.4), // Origen de la expansión (cerca del botón)
                                          ),
                                          child: childWidget,
                                        ),
                                      ],
                                    );
                                  },
                                  child: child,
                                );
                              },
                          transitionDuration: const Duration(milliseconds: 500),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A47ED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botón 2: Registrarse (Expansión circular con fondo azul del registro)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                          ) => const RegisterPage(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return AnimatedBuilder(
                                  animation: animation,
                                  builder: (context, childWidget) {
                                    return Stack(
                                      children: [
                                        Container(
                                          color: const Color(0xFF0A47ED),
                                        ), // Color de fondo del Registro
                                        ClipPath(
                                          clipper: CircularRevealClipper(
                                            progress: animation.value,
                                            alignment: const Alignment(0.0, 0.7), // Origen de la expansión (cerca del botón)
                                          ),
                                          child: childWidget,
                                        ),
                                      ],
                                    );
                                  },
                                  child: child,
                                );
                              },
                          transitionDuration: const Duration(milliseconds: 500),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFFFD600,
                      ), // Fondo amarillo
                      foregroundColor:
                          Colors.black87, // Texto oscuro para contraste
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Registrarse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
