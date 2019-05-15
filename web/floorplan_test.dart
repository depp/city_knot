
import 'dart:html' as HTML;
import 'dart:math' as Math;
import 'package:vector_math/vector_math.dart' as VM;

import 'floorplan.dart' as FLOORPLAN;



void main() {
  print("configure all options");
  final HTML.Element gContainer = HTML.document.getElementById("test");

  final Math.Random gRng = Math.Random();
  final FLOORPLAN.Floorplan floorplan = FLOORPLAN.Floorplan(900, 300, 10, gRng);

  HTML.CanvasElement canvas = FLOORPLAN.RenderCanvasWorldMap(floorplan.world_map,
      VM.Vector3(0.25, 0.25, 0.25), VM.Vector3(0.1, 0.1, 0.1));
  gContainer.children.add(canvas);
}

