import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E3A8A),
              const Color(0xFF1E3A8A).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: const SizedBox(height: 0),
                        ),
                        // Logo and Title Section
                        FadeTransition(
                          opacity: _fadeInAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, 55),
                                  child: Image.asset(
                                    'assets/logos/udd_merch.png',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                 Transform.translate(
                                   offset: const Offset(0, -10),
                                   child: Container(
                                     height: 220,
                                     width: 450,
                                     child: Image.asset(
                                       'assets/logos/uddess_black.png',
                                       fit: BoxFit.contain,
                                       errorBuilder: (context, error, stackTrace) {
                                         return const Text(
                                           'UDD ESSENTIALS',
                                           style: TextStyle(
                                             fontSize: 32,
                                             fontWeight: FontWeight.bold,
                                             color: Colors.white,
                                           ),
                                         );
                                       },
                                     ),
                                   ),
                                 ),
                                Transform.translate(
                                  offset: const Offset(0, -20),
                                  child: const Text(
                                    'Your One-Stop Shop for UDD Merchandise',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                       fontSize: 16,
                                       color: Colors.white70,
                                     ),
                                   ),
                                 ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Features Section
                        FadeTransition(
                          opacity: _fadeInAnimation,
                          child: Column(
                            children: [
                              _buildFeatureItem(
                                icon: Icons.verified_user,
                                title: 'Authentic Products',
                                description:
                                    'Official UDD merchandise guaranteed',
                              ),
                              Transform.translate(
                                offset: const Offset(0, -90),
                                child: const SizedBox(height: 20),
                              ),
                              _buildFeatureItem(
                                icon: Icons.local_shipping,
                                title: 'Easy Pickup',
                                description:
                                    'Convenient pickup locations around campus',
                              ),
                              Transform.translate(
                                offset: const Offset(0, -50),
                                child: const SizedBox(height: 20),
                              ),
                              _buildFeatureItem(
                                icon: Icons.security,
                                title: 'Secure Payments',
                                description:
                                    'Safe and reliable payment methods',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Buttons Section
              FadeTransition(
                opacity: _fadeInAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, 0),
                        child: const SizedBox(height: 15),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E3A8A),
                            side: const BorderSide(color: Color(0xFF1E3A8A)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'REGISTER',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, 0),
                  child: const SizedBox(height: 2),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
