import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';


/// This widget displays a 3D model using the ModelViewer package.
/// It uses a GLB file located in the assets folder.
/// The model is set to auto-rotate and has a transparent background.
/// The camera is positioned to provide a better view of the model.
/// The field of view is increased for a wider perspective.
/// The rotation speed is set to 60 degrees per second.
/// The auto-rotate delay is set to 0, meaning it starts rotating immediately.
/// The camera controls are disabled to
/// prevent user interaction with the camera.
/// The model is displayed with a transparent background.
/// The camera orbit is set to "0deg 90deg 3m", which means the camera is positioned at a distance of 3 meters from the model, looking down at it from a 90-degree angle.
/// The field of view is set to "35deg", which provides a wider perspective of the model.
class AnimatedGlbViewer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      src: "assets/assets/dci.glb",
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
