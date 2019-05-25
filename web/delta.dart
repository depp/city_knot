import 'dart:html' as HTML;
import 'dart:math' as Math;

import 'package:chronosgl/chronosgl.dart' as CGL;
import 'package:vector_math/vector_math.dart' as VM;

import 'floorplan.dart';
import 'logging.dart';
import 'meshes.dart';
import 'shaders.dart';

VM.Vector3 p1 = VM.Vector3.zero();

final HTML.InputElement gCameraMode =
    HTML.document.querySelector('#toruscam') as HTML.InputElement;

final HTML.SelectElement gCameraRoute =
    HTML.document.querySelector('#routecam') as HTML.SelectElement;

final HTML.SelectElement gTheme =
    HTML.document.querySelector('#theme') as HTML.SelectElement;

final HTML.Element gClock = HTML.document.querySelector('#clock');


Map<String, String> HashParameters() {
  final Map<String, String> out = {};

  String hash = HTML.window.location.hash;
  if (hash == "") return out;
  for (String p in hash.substring(1).split("&")) {
    List<String> tv = p.split("=");
    if (tv.length == 1) {
      tv.add("");
    }
    out[tv[0]] = tv[1];
  }
  return out;
}

void buildPlaneVectors(
    final VM.Vector3 planeNormal, VM.Vector3 u, VM.Vector3 v) {
  final double a =
      planeNormal.x * planeNormal.x + planeNormal.y * planeNormal.y;
  final double k = 1.0 / Math.sqrt(a);
  u
    ..x = -planeNormal.y * k
    ..y = planeNormal.x * k
    ..z = 0.0
    ..normalize();

  v
    ..x = -planeNormal.z * planeNormal.x * k
    ..y = -planeNormal.y * planeNormal.z * k
    ..z = a * k
    ..normalize();
}

VM.Vector3 getRoute(VM.Vector3 v1, VM.Vector3 v2) {
  switch (gCameraRoute.value) {
    case "0":
      return v1;
    case "3":
      return v2;
    case "6":
      return -v1;
    case "9":
      return -v2;
    default:
      return v1;
  }
}

// Camera flying through a TorusKnot like through a tunnel
class TorusKnotCamera extends CGL.Spatial {
  TorusKnotCamera(
      {this.radius = kRadius,
      this.p = 2,
      this.q = 3,
      this.heightScale = kHeightScale})
      : super("camera:torusknot");

  final double radius;
  double _tubeRadius = 1.0;
  final int p;
  final int q;
  final double heightScale;
  final double _TorusEpsilon = 0.01;

  final VM.Vector3 point = VM.Vector3.zero();
  final VM.Vector3 target = VM.Vector3.zero();

  final VM.Vector3 tangent = VM.Vector3.zero();

  void animate(double timeMs) {
    double u = timeMs / 3000;
    CGL.TorusKnotGetPos(u, q, p, radius, heightScale, point);
    //p1.scale((p1.length + kTubeRadius * 1.1) / p1.length);

    CGL.TorusKnotGetPos(u + _TorusEpsilon, q, p, radius, heightScale, target);
    tangent
      ..setFrom(target)
      ..sub(point);

    VM.Vector3 v1 = VM.Vector3.zero();

    VM.Vector3 v2 = VM.Vector3.zero();
    buildPlaneVectors(tangent, v1, v2);
    VM.Vector3 offset = getRoute(v1, v2);
    offset.scale(this._tubeRadius);

    //offset.scale(-1.0);
    point.add(offset);
    target.add(offset);

    setPosFromVec(point);
    lookAt(target, offset);
  }

  void SetTubeRadius(double tr) {
    this._tubeRadius = tr;
  }
}

class InitialApproachCamera extends CGL.Spatial {
  InitialApproachCamera(this._radius) : super("camera:orbit");

  final VM.Vector3 cameraIntroStartPoint = VM.Vector3(60.0, -70.0, 150.0);
  final VM.Vector3 cameraIntroEndPoint = VM.Vector3.zero();
  double _radius;
  double azimuth = 0.0;
  double polar = 0.0;
  final VM.Vector3 _lookAtPos = VM.Vector3.zero();

  void animate(double timeMs) {
    // azimuth += 0.03;
    azimuth = timeMs * 0.0001;
    azimuth = azimuth % (2.0 * Math.pi);
    polar = polar.clamp(-Math.pi / 2 + 0.1, Math.pi / 2 - 0.1);
    double radius = _radius * 6.0 - timeMs * 0.1;
    setPosFromSpherical(radius * 2.0, azimuth, polar);
    addPosFromVec(_lookAtPos);
    lookAt(_lookAtPos);
  }
}

CGL.Texture MakeFloorplanTexture(CGL.ChronosGL cgl, Floorplan floorplan) {
  LogInfo("make floorplan");

  HTML.CanvasElement canvas =
      RenderCanvasWorldMap(floorplan.world_map, kTileToColorsStandard);
  //dynamic ctx = canvas.getContext("2d");
  // ctx.fillText("Hello World", 10, 50);
  // CGL.TextureProperties tp = CGL.TextureProperties()..flipY;
  CGL.TextureProperties tp = CGL.TexturePropertiesMipmap;
  LogInfo("make floorplan done");
  return CGL.ImageTexture(cgl, "noise", canvas, tp);
}

void main() {
  final CGL.StatsFps fps =
      CGL.StatsFps(HTML.document.getElementById("stats"), "blue", "gray");
  final params = HashParameters();
  LogInfo("Params: ${params}");

  IntroduceShaderVars();
  final HTML.CanvasElement canvas =
      HTML.document.querySelector('#webgl-canvas');
  final CGL.ChronosGL cgl = CGL.ChronosGL(canvas)..enable(CGL.GL_CULL_FACE);
  final TorusKnotCamera tkc = TorusKnotCamera();
  final CGL.OrbitCamera oc = CGL.OrbitCamera(kRadius * 1.5, 0.0, 0.0, canvas)
    ..mouseWheelFactor = -0.2;
  final InitialApproachCamera iac = InitialApproachCamera(kRadius);

  final CGL.Perspective perspective =
      CGL.PerspectiveResizeAware(cgl, canvas, tkc, 0.1, 20000.0)
        ..UpdateFov(60.0);

  final Math.Random rng = Math.Random(0);

  final Floorplan floorplan = Floorplan(kHeight, kWidth, 10, rng);

  // Material
  final CGL.Material mat = CGL.Material("center")
    ..SetUniform(CGL.uTexture, MakeFloorplanTexture(cgl, floorplan))
    ..SetUniform(CGL.uColor, VM.Vector3.zero());

  final CGL.Material matBuilding = CGL.Material("building")
    ..SetUniform(uWidth, 1.5)
    ..SetUniform(CGL.uColor, VM.Vector3(1.0, 1.0, 0.0))
    ..SetUniform(CGL.uColorAlpha, VM.Vector4(1.0, 0.0, 0.0, 1.0))
    ..SetUniform(CGL.uColorAlpha2, VM.Vector4(0.1, 0.0, 0.0, 1.0));

  final CGL.Material matTorusknotWireframe = CGL.Material("tkWF")
    ..SetUniform(uWidth, 1.5)
    ..ForceUniform(CGL.cBlendEquation, CGL.BlendEquationStandard)
    ..SetUniform(CGL.uColor, VM.Vector3(1.0, 1.0, 0.0))
    ..SetUniform(CGL.uColorAlpha, VM.Vector4(0.0, 0.0, 1.0, 1.0))
    ..SetUniform(CGL.uColorAlpha2, VM.Vector4(0.0, 0.0, 0.1, 0.1));

  final dummyMat = CGL.Material("")
    ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity());

  // Programs
  final CGL.RenderProgram torusProg = CGL.RenderProgram(
      "torus", cgl, texturedVertexShader, texturedFragmentShader);

  final progMulticolor = CGL.RenderProgram(
      "building", cgl, multiColorVertexShader, multiColorFragmentShader);

  final wireframeProg = CGL.RenderProgram(
      "building", cgl, wireframeVertexShader, wireframeFragmentShader);

  final CGL.GeometryBuilder torus = TorusKnot(kHeight, kWidth);
  final CGL.GeometryBuilder buildings = MakeBuildings(floorplan, torus);

  // Meshes
  final buildingsNight =
      CGL.GeometryBuilderToMeshData("buildings", progMulticolor, buildings);

  final buildingsWireframe =
      CGL.GeometryBuilderToMeshData("buildings", wireframeProg, buildings);

  final CGL.GeometryBuilder torusWF =
      TorusKnotWireframe(kHeight ~/ 8, kWidth ~/ 8);
  final tkWireframe =
      CGL.GeometryBuilderToMeshData("buildings", wireframeProg, torusWF);

  final tkStreet = CGL.GeometryBuilderToMeshData("torusknot", torusProg, torus);

  double _lastTimeMs = 0.0;
  void animate(num timeMs) {
    double elapsed = timeMs - _lastTimeMs;
    _lastTimeMs = timeMs + 0.0;
    // animate the camera a little
    oc.azimuth += 0.003;
    // allow the camera to also reflect mouse movement.
    oc.animate(elapsed);
    iac.animate(timeMs);

    tkc.animate(_lastTimeMs * 0.5);
    //updateTorusTexture(timeMs / 1000, canvas2d);
    perspective.UpdateCamera(gCameraMode.checked ? tkc : oc);
    if (gTheme.value == "wireframe-inside-varying-width") {
      double alpha = Math.sin(timeMs / 2000.0) * 50.0 + 52.0;
      matTorusknotWireframe.ForceUniform(uWidth, alpha);
    } else {
      matTorusknotWireframe.ForceUniform(uWidth, 1.5);
      //matBuilding.ForceUniform(uWidth, alpha);
    }

    tkc.SetTubeRadius(1.0);

    if (gTheme.value == "wireframe-inside-varying-width") {
      double alpha = Math.sin(timeMs / 2000.0) * 50.0 + 52.0;
      matTorusknotWireframe.ForceUniform(uWidth, alpha);
    } else {
      matTorusknotWireframe.ForceUniform(uWidth, 1.5);
      //matBuilding.ForceUniform(uWidth, alpha);
    }
    switch (gTheme.value) {
      case "wireframe-outside":
        tkc.SetTubeRadius(kTubeRadius + 50.0);
        wireframeProg.Draw(
            buildingsWireframe, [matBuilding, perspective, dummyMat]);
        torusProg.Draw(tkStreet, [mat, perspective, dummyMat]);
        break;
      case "wireframe-inside":
      case "wireframe-inside-varying-width":
        wireframeProg.Draw(
            buildingsWireframe, [perspective, dummyMat, matBuilding]);
        wireframeProg.Draw(
            tkWireframe, [perspective, dummyMat, matTorusknotWireframe]);
        break;
      case "night-outside":
      default:
        tkc.SetTubeRadius(kTubeRadius + 50.0);
        progMulticolor.Draw(
            buildingsNight, [matBuilding, perspective, dummyMat]);

        torusProg.Draw(tkStreet, [mat, perspective, dummyMat]);
        break;
    }

    gClock.text = DurationFormat(timeMs);
    HTML.window.animationFrame.then(animate);
    fps.UpdateFrameCount(_lastTimeMs);
  }

  animate(0.0);
}
