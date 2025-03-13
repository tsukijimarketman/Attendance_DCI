import 'package:flutter/material.dart';

class TextReveal extends StatefulWidget {
  final Widget child;
  final double maxHeight;
  final AnimationController textController;
  final Animation<double>? textRevealAnimation;
  final Animation<double>? textOpacityAnimation;
  const TextReveal(
      {super.key,
      required this.child,
      required this.maxHeight,
      required this.textController,
      required this.textRevealAnimation,
      required this.textOpacityAnimation});

  @override
  State<TextReveal> createState() => _TextRevealState();
}

class _TextRevealState extends State<TextReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController textController;
  late Animation<double> textRevealAnimation;
  late Animation<double> textOpacityAnimation;

  @override
  void initState() {
    textController = widget.textController;
    textRevealAnimation = widget.textRevealAnimation ??
        Tween<double>(begin: 100, end: 0).animate(CurvedAnimation(
            parent: textController,
            curve: Interval(0.0, 0.3, curve: Curves.easeOut)));
    textOpacityAnimation = widget.textOpacityAnimation ??
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
            parent: textController,
            curve: Interval(0.0, 0.3, curve: Curves.easeOut)));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: textController,
      builder: ((context, child) {
        return LimitedBox(
          maxHeight: widget.maxHeight,
          child: Container(
            padding: EdgeInsets.only(top: textRevealAnimation.value),
            child: FadeTransition(
                opacity: textOpacityAnimation, child: widget.child),
          ),
        );
      }),
    );
  }
}
