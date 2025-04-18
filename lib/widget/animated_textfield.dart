import 'package:attendance_app/widget/custom_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedTextField extends StatefulWidget {
  final bool obscureText;
  final TextEditingController? controller;
  final String label;
  final Widget? suffix;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters; // 👈 Add this


  const AnimatedTextField({
    Key? key,
    required this.label,
    required this.suffix,
    this.obscureText = false,
    this.controller,
    required this.readOnly,
    this.inputFormatters,
  }) : super(key: key);

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> alpha;
  bool isFocused = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    final Animation<double> curve =
        CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    alpha = Tween(begin: 0.0, end: 1.0).animate(curve);

    controller.addListener(() {
      setState(() {});
    });
  }

  void _toggleAnimation(bool focus) {
    setState(() => isFocused = focus);
    if (focus) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color labelColor = isFocused ? Colors.blueAccent : Colors.grey;
    final Color suffixColor = isFocused ? Colors.blueAccent : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Theme(
        data: ThemeData(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Color(0xFF2c2d6c),
              ),
        ),
        child: CustomPaint(
          painter: CustomAnimateBorder(alpha.value),
          child: TextField(
            style: TextStyle(fontSize: MediaQuery.of(context).size.width/100),
            controller: widget.controller,
            obscureText: widget.obscureText,
            readOnly: widget.readOnly,
            onTap: () => _toggleAnimation(true),
            onEditingComplete: () => _toggleAnimation(false),
            inputFormatters: widget.inputFormatters, // 👈 This is important#
            decoration: InputDecoration(
              label: Text(
                widget.label,
                style: TextStyle(color: labelColor, fontSize: MediaQuery.of(context).size.width/90),
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width/80, vertical: MediaQuery.of(context).size.width/150),
              suffixIcon: widget.suffix != null
                  ? IconTheme(
                      data: IconThemeData(color: suffixColor),
                      child: widget.suffix!,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
