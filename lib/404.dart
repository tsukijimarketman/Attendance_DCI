import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';  // Import Lottie package

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Add Lottie animation here and center it
            Center(
              child: Lottie.asset(
                'assets/404.json',  // Path to your Lottie animation
                width: screenWidth / 1.5,  // Set a custom width and height as per your design
                height: screenHeight / 1.5,
                fit: BoxFit.contain,  // To make sure it fits within the given dimensions
              ),
            ),
            SizedBox(height: screenHeight  / 150),
            SizedBox(
              height: screenHeight / 15, 
              width: screenWidth / 1.5,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                  )
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/');
                },
                child: Text("Go Home", style: TextStyle(color: Colors.white, fontSize: screenWidth / 25),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
