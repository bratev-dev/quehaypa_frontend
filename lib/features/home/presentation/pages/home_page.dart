import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../authentication/presentation/atoms/app_snackbar.dart';
import '../../../authentication/presentation/controllers/authentication_controller.dart';
import '../../../authentication/presentation/controllers/authentication_state.dart';
import '../organisms/home_auth_actions.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/Home.mp4');
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _controller.initialize();
    if (!mounted) return;
    await _controller.setLooping(true);
    if (!mounted) return;
    await _controller.setVolume(0.0);
    if (!mounted) return;
    await _controller.play();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authenticationControllerProvider, (previous, next) {
      if (next.status == AuthenticationStatus.error &&
          next.errorMessage != null) {
        AppSnackbar.show(
          context,
          message: next.errorMessage!,
          type: SnackbarType.error,
        );
      }
    });
    return Scaffold(
      body: Stack(
        children: [
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
          Container(color: Colors.black.withValues(alpha: 0.4)),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: HomeAuthActions(),
            ),
          ),
        ],
      ),
    );
  }
}
