import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({Key? key}) : super(key: key);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  final PageController _pageController = PageController();
  int _currentPromoIndex = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _promos = [
    {
      'title': 'Gojek',
      'subtitle': 'One solution for every needs',
      'gradient': [Color(0xFF00AA13), Color(0xFF00D41C)],
      'icon': Icons.delivery_dining,
      'url': 'https://www.gojek.com/en-id',
      'imageUrl': 'https://cdn1.katadata.co.id/media/images/temp/2019/07/22/2019_07_22-16_00_36_d8dadac5536b3c563d3d4739301900b8.jpg',
    },
    {
      'title': 'Traveloka',
      'subtitle': 'Book flights, hotels & more',
      'gradient': [Color(0xFF0770CD), Color(0xFF0D8CFF)],
      'icon': Icons.flight_takeoff,
      'url': 'https://www.traveloka.com/en-id',
      'imageUrl': 'https://ik.imagekit.io/tvlk/image/imageResource/2023/08/20/1692542740890-c1667d10b894823b5d01900c8af5dde6.jpeg?tr=q-75', // Replace with actual image URL
    },
    {
      'title': 'KakaoTalk',
      'subtitle': 'Connect with friends easily',
      'gradient': [Color(0xFFFAE100), Color(0xFFFFEB3B)],
      'icon': Icons.chat_bubble,
      'url': 'https://www.kakaocorp.com/page/service/service/KakaoTalk?lang=en',
      'imageUrl': 'https://tse3.mm.bing.net/th/id/OIP.4tFoW0Zr1WgJmP5E7k5y_QHaDq?rs=1&pid=ImgDetMain&o=7&rm=3', // Replace with actual image URL
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPromoIndex + 1) % _promos.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $urlString'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLogo(),
        const SizedBox(height: 20),
        _buildPromoBanner(),
      ],
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ).createShader(bounds),
          child: const Text(
            'AI Photo Studio',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Transform your photos into stunning scenes',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Column(
      children: [
        // Use LayoutBuilder to make it responsive
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate height based on screen width for better responsiveness
            // Aspect ratio of 16:6 works well for banners
            final height = constraints.maxWidth * 0.35;
            final clampedHeight = height.clamp(140.0, 200.0);
            
            return SizedBox(
              height: clampedHeight,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPromoIndex = index;
                  });
                },
                itemCount: _promos.length,
                itemBuilder: (context, index) {
                  return _buildPromoCard(_promos[index]);
                },
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        
        // Carousel Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _promos.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentPromoIndex == entry.key ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentPromoIndex == entry.key
                    ? AppColors.primary
                    : AppColors.borderLight,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    return GestureDetector(
      onTap: () => _launchURL(promo['url']),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: promo['gradient'][0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image with better fitting
              Positioned.fill(
                child: Image.network(
                  promo['imageUrl'],
                  fit: BoxFit.cover, // Cover ensures no empty spaces
                  alignment: Alignment.center, // Center the image
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to gradient if image fails to load
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: promo['gradient'],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: promo['gradient'],
                        ),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Stronger gradient overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Content - Responsive layout
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launchURL(promo['url']),
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Adjust icon size based on available width
                        final iconSize = constraints.maxWidth > 300 ? 56.0 : 48.0;
                        final iconInnerSize = constraints.maxWidth > 300 ? 28.0 : 24.0;
                        
                        return Row(
                          children: [
                            // Icon with backdrop for visibility
                            Container(
                              width: iconSize,
                              height: iconSize,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                promo['icon'],
                                color: Colors.white,
                                size: iconInnerSize,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Text Content with better contrast
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    promo['title'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: constraints.maxWidth > 300 ? 20 : 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      shadows: const [
                                        Shadow(
                                          offset: Offset(0, 2),
                                          blurRadius: 8,
                                          color: Colors.black54,
                                        ),
                                        Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 4,
                                          color: Colors.black87,
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    promo['subtitle'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: constraints.maxWidth > 300 ? 14 : 13,
                                      fontWeight: FontWeight.w500,
                                      shadows: const [
                                        Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 6,
                                          color: Colors.black54,
                                        ),
                                        Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 3,
                                          color: Colors.black87,
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Arrow Icon with backdrop
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}