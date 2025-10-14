import 'dart:async';
import 'package:flutter/material.dart';

/// Carousel customizado da aplicação
class CustomCarousel extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool showIndicators;
  final Color? indicatorColor;
  final Color? activeIndicatorColor;
  final double indicatorSize;
  final double spacing;
  final PageController? controller;
  final Function(int)? onPageChanged;
  
  const CustomCarousel({
    super.key,
    required this.children,
    this.height = 200,
    this.width,
    this.padding,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.showIndicators = true,
    this.indicatorColor,
    this.activeIndicatorColor,
    this.indicatorSize = 8,
    this.spacing = 8,
    this.controller,
    this.onPageChanged,
  });
  
  @override
  State<CustomCarousel> createState() => _CustomCarouselState();
}

class _CustomCarouselState extends State<CustomCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _pageController = widget.controller ?? PageController();
    
    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    if (widget.controller == null) {
      _pageController.dispose();
    }
    super.dispose();
  }
  
  void _startAutoPlay() {
    _timer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentIndex + 1) % widget.children.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  
  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          width: widget.width,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              widget.onPageChanged?.call(index);
            },
            itemCount: widget.children.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: widget.padding ?? EdgeInsets.zero,
                child: widget.children[index],
              );
            },
          ),
        ),
        if (widget.showIndicators && widget.children.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildIndicators(),
          ),
      ],
    );
  }
  
  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.children.length,
        (index) => Container(
          margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
          width: widget.indicatorSize,
          height: widget.indicatorSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentIndex
                ? (widget.activeIndicatorColor ?? Colors.blue)
                : (widget.indicatorColor ?? Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}

/// Item de carousel para banners
class CarouselBannerItem extends StatelessWidget {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? overlayColor;
  
  const CarouselBannerItem({
    super.key,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.onTap,
    this.overlayColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                (overlayColor ?? Colors.black).withOpacity(0.7),
              ],
            ),
          ),
          child: title != null || subtitle != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
