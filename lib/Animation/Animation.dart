import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class AnimatedGlbViewer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      src: "assets/dci.glb",
      alt: "A 3D logo",
      autoRotate: true,
      disableZoom: true,
      cameraControls: false,
      backgroundColor: Colors.transparent,
      cameraOrbit: "0deg 90deg 3m", // Move the camera back
      fieldOfView: "35deg", // Increase field of view
      autoRotateDelay: 0,
      rotationPerSecond: "60deg",
    );
  }
}
