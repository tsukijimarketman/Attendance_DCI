import 'package:attendance_app/widget/custom_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedTextField extends StatefulWidget {
  final bool obscureText;
  final TextEditingController? controller;
  final String label;
  final Widget? suffix;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode; // Add focusNode property
  final VoidCallback? onEditingComplete; // Add onEditingComplete property
  final TextInputAction? textInputAction; // Add textInputAction property

  const AnimatedTextField({
    Key? key,
    required this.label,
    required this.suffix,
    this.obscureText = false,
    this.controller,
    required this.readOnly,
    this.inputFormatters,
    this.focusNode, // Initialize focusNode
    this.onEditingComplete, // Initialize onEditingComplete
    this.textInputAction, // Initialize textInputAction
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
    
    // Add listener to focusNode if it exists
    if (widget.focusNode != null) {
      widget.focusNode!.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    // Remove listener from focusNode if it exists
    if (widget.focusNode != null) {
      widget.focusNode!.removeListener(_handleFocusChange);
    }
    controller.dispose();
    super.dispose();
  }
  
  // Handle focus changes from external sources
  void _handleFocusChange() {
    if (widget.focusNode != null) {
      _toggleAnimation(widget.focusNode!.hasFocus);
    }
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
            focusNode: widget.focusNode, // Use the provided focusNode
            textInputAction: widget.textInputAction ?? TextInputAction.next, // Use textInputAction or default to next
            onEditingComplete: () {
              _toggleAnimation(false);
              // Execute the provided onEditingComplete callback if it exists
              if (widget.onEditingComplete != null) {
                widget.onEditingComplete!();
              }
            },
            onTap: () => _toggleAnimation(true),
            inputFormatters: widget.inputFormatters,
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