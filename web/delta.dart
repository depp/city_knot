import 'dart:html' as HTML;
import 'dart:math' as Math;

import 'package:chronosgl/chronosgl.dart' as CGL;
import 'package:vector_math/vector_math.dart' as VM;

import 'floorplan.dart';
import 'gol.dart' as GOL;
import 'logging.dart';
import 'meshes.dart';
import 'mondrianjs.dart';
import 'shaders.dart';
import 'textures.dart';

final HTML.InputElement gManualCamera =
    HTML.document.querySelector('#manualcam') as HTML.InputElement;

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
    double u = timeMs / 6000;
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
  InitialApproachCamera() : super("camera:orbit");

  final VM.Vector3 cameraIntroStartPoint = VM.Vector3(60.0, -70.0, 150.0);
  final VM.Vector3 cameraIntroEndPoint = VM.Vector3.zero();
  double radius = 1.0;
  double azimuth = 0.0;
  double polar = 0.0;
  final VM.Vector3 _lookAtPos = VM.Vector3.zero();

  void animate(double timeMs) {
    // azimuth += 0.03;
    azimuth = timeMs * 0.0001;
    azimuth = azimuth % (2.0 * Math.pi);
    polar = polar.clamp(-Math.pi / 2 + 0.1, Math.pi / 2 - 0.1);
    double r = radius - timeMs * 0.1;
    setPosFromSpherical(r * 2.0, azimuth, polar);
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

class Scene {
  Scene();

  Scene.OutsideStreet(
      CGL.ChronosGL cgl, Floorplan floorplan, CGL.GeometryBuilder torus) {
    mat = CGL.Material("street")
      ..SetUniform(CGL.uTexture, MakeFloorplanTexture(cgl, floorplan))
      ..SetUniform(CGL.uColor, VM.Vector3.zero());
    program = CGL.RenderProgram(
        "street", cgl, texturedVertexShader, texturedFragmentShader);
    mesh = CGL.GeometryBuilderToMeshData("torusknot", program, torus);
  }

  Scene.OutsideWireframeBuildings(
      CGL.ChronosGL cgl, CGL.GeometryBuilder building) {
    mat = CGL.Material("wf")
      ..SetUniform(uWidth, 1.5)
      ..SetUniform(CGL.uColor, VM.Vector3(1.0, 1.0, 0.0))
      ..SetUniform(CGL.uColorAlpha, VM.Vector4(1.0, 0.0, 0.0, 1.0))
      ..SetUniform(CGL.uColorAlpha2, VM.Vector4(0.1, 0.0, 0.0, 1.0));

    program = CGL.RenderProgram(
        "wf", cgl, wireframeVertexShader, wireframeFragmentShader);
    mesh = CGL.GeometryBuilderToMeshData("wf", program, building);
  }

  Scene.OutsideNightBuildings(
      CGL.ChronosGL cgl, CGL.GeometryBuilder buildings) {
    mat = CGL.Material("building");
    program = CGL.RenderProgram(
        "building", cgl, multiColorVertexShader, multiColorFragmentShader);
    mesh = CGL.GeometryBuilderToMeshData("buildings", program, buildings);
  }

  Scene.InsidePlasma(CGL.ChronosGL cgl, CGL.GeometryBuilder torus) {
    mat = CGL.Material("plasma")
      ..ForceUniform(CGL.cBlendEquation, CGL.BlendEquationStandard);
    program = CGL.RenderProgram("plasma", cgl, CGL.perlinNoiseVertexShader,
        CGL.makePerlinNoiseColorFragmentShader(false));
    mesh = CGL.GeometryBuilderToMeshData("plasma", program, torus);
  }

  Scene.InsideWireframe(CGL.ChronosGL cgl, CGL.GeometryBuilder torus) {
    mat = CGL.Material("wf")
      ..SetUniform(uWidth, 1.5)
      ..ForceUniform(CGL.cBlendEquation, CGL.BlendEquationStandard)
      ..SetUniform(CGL.uColorAlpha, VM.Vector4(0.0, 0.0, 1.0, 1.0))
      ..SetUniform(CGL.uColorAlpha2, VM.Vector4(0.0, 0.0, 0.1, 0.1));

    program = CGL.RenderProgram(
        "wf", cgl, wireframeVertexShader, wireframeFragmentShader);
    mesh = CGL.GeometryBuilderToMeshData("wf", program, torus);
  }

  void Draw(CGL.ChronosGL cgl, CGL.Perspective perspective) {
    program.Draw(mesh, [perspective, dummyMat, mat]);
  }

  CGL.Material mat;
  CGL.RenderProgram program;
  CGL.MeshData mesh;
  final CGL.Material dummyMat = CGL.Material("")
    ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity());
}

class SceneGOL extends Scene {
  SceneGOL(CGL.ChronosGL cgl, Floorplan floorplan) {
    mat = CGL.Material("street")
      ..SetUniform(CGL.uTexture, MakeFloorplanTexture(cgl, floorplan))
      ..SetUniform(CGL.uColor, VM.Vector3(0.1, 0.0, 0.0));
    CGL.GeometryBuilder torus = InsideTorusKTexture(kHeight ~/ 8, kWidth ~/ 8);
    program = CGL.RenderProgram(
        "street", cgl, texturedVertexShader, texturedFragmentShader);
    mesh = CGL.GeometryBuilderToMeshData("torusknot", program, torus);
  }
}

class SceneSketch extends Scene {
  SceneSketch(CGL.ChronosGL cgl, Math.Random rng, this.w, this.h,
      CGL.GeometryBuilder buildings) {
    fb = CGL.Framebuffer.Default(cgl, w, h);

    final VM.Vector3 dirLight = VM.Vector3(2.0, -1.2, 0.5);
    CGL.Light light = CGL.DirectionalLight(
        "dir", dirLight, CGL.ColorWhite, CGL.ColorBlack, 1000.0);

    illumination = CGL.Illumination()..AddLight(light);

    screen = CGL.Framebuffer.Screen(cgl);

    mat = CGL.Material("")
      ..SetUniform(CGL.uShininess, 10.0)
      ..SetUniform(CGL.uTexture2, fb.colorTexture)
      ..SetUniform(CGL.uTexture, MakeNoiseTesture(cgl, rng));

    programPrep = CGL.RenderProgram(
        "sketch-prep", cgl, sketchPrepVertexShader, sketchPrepFragmentShader);
    program = CGL.RenderProgram(
        "final", cgl, sketchVertexShader, sketchFragmentShader);
    mesh = CGL.GeometryBuilderToMeshData("sketch", program, buildings);
  }

  void Draw(CGL.ChronosGL cgl, CGL.Perspective perspective) {
    fb.Activate(CGL.GL_CLEAR_ALL, 0, 0, w, h);
    programPrep.Draw(mesh, [perspective, illumination, dummyMat, mat]);
    screen.Activate(CGL.GL_CLEAR_ALL, 0, 0, w, h);
    program.Draw(mesh, [perspective, illumination, dummyMat, mat]);
  }

  int w, h;
  CGL.Framebuffer fb;
  CGL.Illumination illumination;
  CGL.RenderProgram programPrep;
  CGL.Framebuffer screen;
}

void main() {
  final CGL.StatsFps fps =
      CGL.StatsFps(HTML.document.getElementById("stats"), "blue", "gray");
  final params = HashParameters();
  LogInfo("Params: ${params}");

  IntroduceShaderVars();
  GOL.RegisterShaderVars();

  final HTML.CanvasElement canvas =
      HTML.document.querySelector('#webgl-canvas');
  final CGL.ChronosGL cgl = CGL.ChronosGL(canvas)..enable(CGL.GL_CULL_FACE);

  // Cameras

  final TorusKnotCamera tkc = TorusKnotCamera();
  final CGL.OrbitCamera oc = CGL.OrbitCamera(kRadius * 1.5, 0.0, 0.0, canvas)
    ..mouseWheelFactor = -0.2;

  final InitialApproachCamera iac = InitialApproachCamera();

  // Misc
  final CGL.Perspective perspective =
      CGL.PerspectiveResizeAware(cgl, canvas, tkc, 0.1, 20000.0)
        ..UpdateFov(60.0);

  final Math.Random rng = Math.Random(0);

  final Floorplan floorplan = Floorplan(kHeight, kWidth, 10, rng);

  // Geometries

  final CGL.GeometryBuilder torus = TorusKnot(kHeight, kWidth);
  final CGL.GeometryBuilder buildings = MakeBuildings(floorplan, torus);
  final CGL.GeometryBuilder torusWF =
      InsideTorusKnotWireframe(kHeight ~/ 8, kWidth ~/ 8);
  final torusWFeHex = TorusKnotWireframeHexagons(kHeight ~/ 8, kWidth ~/ 8);

  // Scenes
  LogInfo("creating scenes");
  final Scene outsideSteet = Scene.OutsideStreet(cgl, floorplan, torus);
  final Scene outsideWireframeBuildings =
      Scene.OutsideWireframeBuildings(cgl, buildings);
  final Scene outsideNightBuildings =
      Scene.OutsideNightBuildings(cgl, buildings);
  final Scene insidePlasma = Scene.InsidePlasma(cgl, torusWF);
  final Scene insideWireframe = Scene.InsideWireframe(cgl, torusWF);
  final Scene insideWireframeHex = Scene.InsideWireframe(cgl, torusWFeHex);
  final Scene insideGOL = SceneGOL(cgl, floorplan);
  final Scene outsideSketch =
      SceneSketch(cgl, rng, canvas.clientWidth, canvas.clientHeight, buildings);
  LogInfo("creating scenes done");

  double zeroTimeMs = 0.0;
  double lastTimeMs = 0.0;

  String lastTheme;

  void animate(num timeMs) {
    double elapsed = timeMs - lastTimeMs;
    lastTimeMs = timeMs + 0.0;

    tkc.animate(lastTimeMs * 0.5);

    if (gTheme.value != lastTheme) {
      zeroTimeMs = timeMs;
      iac.azimuth = 0.0;
      lastTheme = gTheme.value;
    }
    //updateTorusTexture(timeMs / 1000, canvas2d);
    if (gManualCamera.checked) {
      perspective.UpdateCamera(oc);
      // allow the camera to also reflect mouse movement.
      oc.animate(elapsed);
    } else {
      switch (gTheme.value) {
        case "wireframe-orbit-far":
          perspective.UpdateCamera(iac);
          iac.radius = kRadius * 6.0;
          break;
        case "night-orbit-near":
          perspective.UpdateCamera(iac);
          iac.radius = kRadius * 3.0;
          break;
        default:
          perspective.UpdateCamera(tkc);
      }
      oc.animate(elapsed);
      iac.animate(timeMs - zeroTimeMs);
      tkc.animate(timeMs - zeroTimeMs);
    }

    tkc.SetTubeRadius(1.0);

    if (gTheme.value == "wireframe-inside-varying-width" ||
        gTheme.value == "wireframe-inside-hexagon") {
      double alpha = Math.sin(timeMs / 2000.0) * 10.0 + 11.0;
      insideWireframe.mat.ForceUniform(uWidth, alpha);
      insideWireframeHex.mat.ForceUniform(uWidth, alpha);
    } else {
      insideWireframe.mat.ForceUniform(uWidth, 2.5);
      insideWireframeHex.mat.ForceUniform(uWidth, 2.5);
      //matBuilding.ForceUniform(uWidth, alpha);
    }

    insidePlasma.mat.ForceUniform(CGL.uTime, (timeMs - zeroTimeMs) / 5000.0);

    switch (gTheme.value) {
      case "wireframe-outside":
      case "wireframe-orbit-far":
        tkc.SetTubeRadius(kTubeRadius + 50.0);
        outsideWireframeBuildings.Draw(cgl, perspective);
        outsideSteet.Draw(cgl, perspective);
        break;
      case "plasma-inside":
        outsideWireframeBuildings.Draw(cgl, perspective);
        insidePlasma.Draw(cgl, perspective);
        break;
      case "wireframe-inside-hexagon":
        outsideWireframeBuildings.Draw(cgl, perspective);
        insideWireframeHex.Draw(cgl, perspective);
        break;
      case "wireframe-inside":
      case "wireframe-inside-varying-width":
        outsideWireframeBuildings.Draw(cgl, perspective);
        insideWireframe.Draw(cgl, perspective);
        break;
      case "gol-inside":
        insideGOL.Draw(cgl, perspective);
        break;
      case "sketch-outside":
        tkc.SetTubeRadius(kTubeRadius + 50.0);
        outsideSketch.Draw(cgl, perspective);
        outsideSteet.Draw(cgl, perspective);
        break;
      case "night-outside":
      default:
        tkc.SetTubeRadius(kTubeRadius + 50.0);
        outsideNightBuildings.Draw(cgl, perspective);
        outsideSteet.Draw(cgl, perspective);
        break;
    }

    gClock.text = DurationFormat(timeMs - zeroTimeMs);
    HTML.window.animationFrame.then(animate);
    fps.UpdateFrameCount(lastTimeMs);
  }

  HTML.document.querySelector('#music').onClick.listen((HTML.Event ev) {
    ev.preventDefault();
    ev.stopPropagation();
    playSong();
    return false;
  });

  animate(0.0);
}
