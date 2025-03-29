import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoader extends StatelessWidget {
  const CustomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(  // Wrap in a Dialog
      backgroundColor: Colors.transparent, 
      elevation: 0,
      child: Center(
        child: Lottie.asset(
          'assets/lda.json',
          width: MediaQuery.of(context).size.width / 6,
          height: MediaQuery.of(context).size.width / 6,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
