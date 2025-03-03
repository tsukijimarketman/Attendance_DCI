import 'package:attendance_app/widget/custom_animation.dart';
import 'package:flutter/material.dart';

class AnimatedTextField extends StatefulWidget {
  final bool obscureText;
  final TextEditingController? controller;
  final String label;
  final Widget? suffix;
  final bool readOnly; // <-- Added readOnly as a required parameter

  const AnimatedTextField({
    Key? key,
    required this.label,
    required this.suffix,
    this.obscureText = false,
    this.controller,
    required this.readOnly, // <-- Make it required
  }) : super(key: key);

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;
  late Animation<double> alpha;
  final focusNode = FocusNode();

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    final Animation<double> curve =
        CurvedAnimation(parent: controller!, curve: Curves.easeInOut);
    alpha = Tween(begin: 0.0, end: 1.0).animate(curve);

    controller?.addListener(() {
      setState(() {});
    });
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        controller?.forward();
      } else {
        controller?.reverse();
      }
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Color labelColor =
        focusNode.hasFocus ? Colors.blueAccent : Colors.grey;
    final Color suffixColor =
        focusNode.hasFocus ? Colors.blueAccent : Colors.grey;

    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.all(Radius.circular(8))),
      child: Theme(
        data: ThemeData(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Color(0xFF2c2d6c),
                )),
        child: CustomPaint(
          painter: CustomAnimateBorder(alpha.value),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.obscureText,
            focusNode: focusNode,
            readOnly: widget.readOnly, // <-- Make the field uneditable when required
            decoration: InputDecoration(
                label: Text(widget.label,
                    style: TextStyle(
                      color: labelColor,
                    )),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: widget.suffix != null
                    ? IconTheme(
                        data: IconThemeData(color: suffixColor),
                        child: widget.suffix!)
                    : null),
          ),
        ),
      ),
    );
  }
}
