import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureApp extends StatefulWidget {
      final SignatureController controller; // Pass controller from parent

  const SignatureApp({Key? key, required this.controller}) : super(key: key);

  @override
  _SignatureAppState createState() => _SignatureAppState();
}

class _SignatureAppState extends State<SignatureApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 20),
              Signature(
                controller:  widget.controller,
                width: double.infinity,
                height: 300,
                backgroundColor: Colors.grey.shade300,
              ),
            ],
          ),
          // Buttons positioned at the top-right corner
          Positioned(
            top: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () =>  widget.controller.clear(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Clear",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
