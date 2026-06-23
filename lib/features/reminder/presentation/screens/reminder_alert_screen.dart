import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:math';

class ReminderAlertScreen extends StatefulWidget {
  final String title;
  final String time;
  final String message;

  const ReminderAlertScreen({
    super.key,
    required this.title,
    this.time = '',
    this.message = 'ถึงเวลาแล้วเจ้าคะ',
  });

  @override
  State<ReminderAlertScreen> createState() => _ReminderAlertScreenState();
}

class _ReminderAlertScreenState extends State<ReminderAlertScreen>
    with TickerProviderStateMixin {
  late AnimationController _bellController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late AnimationController _slideController;

  late Animation<double> _bellAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Bell ringing animation
    _bellController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _bellAnimation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.elasticInOut),
    );

    // Pulse glow animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sparkle animation
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Slide up + fade in animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _slideAnimation = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _bellController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _dismissAlert() {
    AwesomeNotifications().dismissAllNotifications();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dark gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xDD0D0D0D),
                  Color(0xEE1A0A2E),
                  Color(0xEE0D0D0D),
                ],
              ),
            ),
          ),

          // Animated sparkles background
          AnimatedBuilder(
            animation: _sparkleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _SparklePainter(_sparkleController.value),
                size: Size.infinite,
              );
            },
          ),

          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Dismissible(
                key: const Key('alert_dialog'),
                direction: DismissDirection.vertical,
                onDismissed: (direction) => _dismissAlert(),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32.0),
                    // Glassmorphism dark card
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1A1A2E),
                        Color(0xFF16213E),
                        Color(0xFF1A1A2E),
                      ],
                    ),
                    border: Border.all(
                      width: 1.5,
                      color: const Color(0x44FF69B4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF69B4).withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: const Color(0xFF9B59B6).withValues(alpha: 0.15),
                        blurRadius: 50,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32.0),
                    child: Stack(
                      children: [
                        // Subtle gradient overlay for glass effect
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.05),
                                  Colors.transparent,
                                  const Color(0xFF9B59B6).withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Bell icon + Title header
                              _buildHeader(),
                              const SizedBox(height: 20),

                              // Mage character image
                              _buildMageImage(),
                              const SizedBox(height: 20),

                              // Notification details
                              _buildNotificationDetails(),
                              const SizedBox(height: 28),

                              // Action buttons
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated bell
        AnimatedBuilder(
          animation: _bellAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _bellAnimation.value,
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Color.lerp(
                      const Color(0xFFFFD700),
                      const Color(0xFFFF69B4),
                      _pulseAnimation.value,
                    )!,
                    const Color(0xFFFFD700),
                  ],
                ).createShader(bounds),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFF69B4), // Hot Pink
              Color(0xFFDA70D6), // Orchid
              Color(0xFFFF1493), // Deep Pink
            ],
          ).createShader(bounds),
          child: const Text(
            'แจ้งเตือนจากเมจจัง ♪',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMageImage() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF69B4).withValues(
                  alpha: 0.15 + (_pulseAnimation.value * 0.1),
                ),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D1B4E), // Deep purple
              Color(0xFF1A1A2E), // Dark navy
              Color(0xFF2D1B3D), // Dark magenta
            ],
          ),
          border: Border.all(
            color: const Color(0x66FF69B4),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radial glow behind character
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        const Color(0xFFFF69B4).withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Mage character image
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  'assets/images/mage_notification.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 64,
                          color: const Color(0xFFFF69B4).withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Color(0xFFFF69B4),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              // "ถึงเวลาแล้วเจ้าคะ" overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF1A1A2E).withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Color(0xFFFFB6C1),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Color(0xFFFF69B4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationDetails() {
    return Column(
      children: [
        // Title with icon
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF2D1B4E).withValues(alpha: 0.6),
            border: Border.all(
              color: const Color(0x33DA70D6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📋', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color(0xFFE8D5F5),
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        if (widget.time.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⏰', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'เวลา: ${widget.time} น.',
                style: TextStyle(
                  color: const Color(0xFFDA70D6).withValues(alpha: 0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Primary action - gradient button
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF69B4), // Hot Pink
                  Color(0xFFDA70D6), // Orchid
                  Color(0xFF9B59B6), // Amethyst
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF69B4).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _dismissAlert,
              child: const Text(
                'รับทราบค่ะ~ ✨',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Secondary action - outlined button
        Expanded(
          flex: 2,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(
                color: Color(0x66DA70D6),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _dismissAlert,
            child: const Text(
              'ไว้ทีหลัง',
              style: TextStyle(
                color: Color(0xFFDA70D6),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for sparkle/star particles in the background
class _SparklePainter extends CustomPainter {
  final double progress;

  _SparklePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Fixed seed for consistent sparkle positions

    for (int i = 0; i < 25; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final sparkleProgress = (progress + (i * 0.04)) % 1.0;
      final opacity = (sin(sparkleProgress * pi * 2) * 0.5 + 0.5) * 0.6;
      final sparkleSize = 1.0 + random.nextDouble() * 2.5;

      final paint = Paint()
        ..color = (i % 3 == 0
                ? const Color(0xFFFF69B4) // Pink
                : i % 3 == 1
                    ? const Color(0xFFDA70D6) // Purple
                    : const Color(0xFFFFD700)) // Gold
            .withValues(alpha: opacity);

      // Draw star/sparkle shape
      _drawSparkle(canvas, Offset(x, y), sparkleSize, paint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * pi / 2);
      final outerX = center.dx + cos(angle) * size * 2;
      final outerY = center.dy + sin(angle) * size * 2;
      final innerAngle = angle + pi / 4;
      final innerX = center.dx + cos(innerAngle) * size * 0.5;
      final innerY = center.dy + sin(innerAngle) * size * 0.5;

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
