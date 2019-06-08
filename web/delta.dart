import 'dart:html' as HTML;
import 'dart:math' as Math;

import 'package:chronosgl/chronosgl.dart' as CGL;
import 'package:vector_math/vector_math.dart' as VM;

import 'city.dart' as CITY;
import 'floorplan.dart';
import 'fractal.dart' as FRACTAL;
import 'geometry.dart';
import 'gol.dart' as GOL;
import 'logging.dart';
import 'meshes.dart';
import 'mondrianjs.dart';
import 'portal.dart' as PORTAL;
import 'shaders.dart';
import 'sky.dart' as SKY;
import 'textures.dart';
import 'theme.dart' as THEME;

final HTML.SelectElement gMode =
    HTML.document.querySelector('#mode') as HTML.SelectElement;

final HTML.SelectElement gCameraRoute =
    HTML.document.querySelector('#routecam') as HTML.SelectElement;

final HTML.SelectElement gTheme =
    HTML.document.querySelector('#theme') as HTML.SelectElement;

final HTML.Element gClock = HTML.document.querySelector('#clock');

final HTML.Element gStatus = HTML.document.querySelector('#status');

final HTML.AudioElement gSoundtrack =
    HTML.document.querySelector("#soundtrack");

final HTML.Element gMusic = HTML.document.querySelector('#music');

const bool FAST_START_NO_BUILDINGS = false;

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

VM.Vector3 getRoute(VM.Vector3 v1, VM.Vector3 v2, String route) {
  switch (route) {
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

  // point inside/on torus
  final VM.Vector3 point = VM.Vector3.zero();

  // point inside/on torus slightly ahead
  final VM.Vector3 target = VM.Vector3.zero();

  // tangent (target - point)
  final VM.Vector3 tangent = VM.Vector3.zero();

  // tangent plane
  final VM.Vector3 v1 = VM.Vector3.zero();
  final VM.Vector3 v2 = VM.Vector3.zero();

  void animate(double timeMs, String route) {
    double u = timeMs / 6000;
    CGL.TorusKnotGetPos(u, q, p, radius, heightScale, point);
    //p1.scale((p1.length + kTubeRadius * 1.1) / p1.length);

    CGL.TorusKnotGetPos(u + _TorusEpsilon, q, p, radius, heightScale, target);
    tangent
      ..setFrom(target)
      ..sub(point);

    buildPlaneVectors(tangent, v1, v2);
    VM.Vector3 offset = getRoute(v1, v2, route);
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

class CameraInterpolation {
  VM.Quaternion qsrc = VM.Quaternion.identity();
  VM.Vector3 tsrc = VM.Vector3.zero();
  VM.Vector3 ssrc = VM.Vector3.zero();

  VM.Quaternion qdst = VM.Quaternion.identity();
  VM.Vector3 tdst = VM.Vector3.zero();
  VM.Vector3 sdst = VM.Vector3.zero();

  VM.Vector3 ptmp = VM.Vector3.zero();
  VM.Quaternion qtmp = VM.Quaternion.identity();
  VM.Matrix3 mtmp = VM.Matrix3.identity();

  void setSrc(VM.Matrix4 src) {
    src.decompose(tsrc, qsrc, ssrc);
  }

  void setDst(VM.Matrix4 dst) {
    dst.decompose(tdst, qdst, sdst);
  }

  void setInterpolated(VM.Matrix4 m, double x) {
    m.setFromTranslationRotationScale(
        //
        tsrc + (tdst - tsrc).scaled(x),
        qsrc + (qdst - qsrc).scaled(x),
        ssrc + (sdst - ssrc).scaled(x));
  }
}

class InitialApproachCamera extends CGL.Spatial {
  InitialApproachCamera() : super("camera:orbit");

  CameraInterpolation ci = CameraInterpolation();

  final VM.Matrix4 cameraTransitionState = null;
  final VM.Vector3 cameraFinalPos = VM.Vector3.zero();

  double range = 100000.0;
  double radius = 1.0;
  double azimuth = 0.0;
  double polar = 0.0;
  double lastTime = 0.0;
  final VM.Vector3 _lookAtPos = VM.Vector3.zero();

  void animate(double timeMs) {
    range = (transform.getTranslation() - ci.tdst).length;

    // hard coded duration
    if (timeMs >= 20000) {
      if (lastTime < 20000) {
        ci.setSrc(transform);
      }
      double t = (timeMs - 20000) / (25000.0 - 20000.0);
      if (t > 1.0) {
        return;
      }
      ci.setInterpolated(transform, t);
    } else {
      // azimuth += 0.03;
      azimuth = Math.pi + timeMs * 0.0001;
      azimuth = azimuth % (2.0 * Math.pi);
      polar = polar.clamp(-Math.pi / 2 + 0.1, Math.pi / 2 - 0.1);
      double r = radius - timeMs * 0.1;
      setPosFromSpherical(r * 2.0, azimuth, polar);
      addPosFromVec(_lookAtPos);
      lookAt(_lookAtPos);
    }
    lastTime = timeMs;
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
      ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity())
      ..SetUniform(CGL.uTexture, MakeFloorplanTexture(cgl, floorplan))
      ..SetUniform(CGL.uColor, VM.Vector3.zero());
    program = CGL.RenderProgram(
        "street", cgl, texturedVertexShader, texturedFragmentShader);
    mesh = CGL.GeometryBuilderToMeshData("torusknot", program, torus);
  }

  Scene.OutsideWireframeBuildings(
      CGL.ChronosGL cgl, CGL.GeometryBuilder building) {
    mat = CGL.Material("wf")
      ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity())
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
    mat = CGL.Material("building")
      ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity());
    program = CGL.RenderProgram(
        "building", cgl, multiColorVertexShader, multiColorFragmentShader);
    mesh = CGL.GeometryBuilderToMeshData("buildings", program, buildings);
  }

  Scene.InsidePlasma(CGL.ChronosGL cgl, CGL.GeometryBuilder torus) {
    mat = CGL.Material("plasma")
      ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity())
      ..ForceUniform(CGL.cBlendEquation, CGL.BlendEquationStandard);
    program = CGL.RenderProgram("plasma", cgl, CGL.perlinNoiseVertexShader,
        CGL.makePerlinNoiseColorFragmentShader(false));
    mesh = CGL.GeometryBuilderToMeshData("plasma", program, torus);
  }

  Scene.InsideWireframe(CGL.ChronosGL cgl, CGL.GeometryBuilder torus) {
    mat = CGL.Material("wf")
      ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity())
      ..SetUniform(uWidth, 1.5)
      ..ForceUniform(CGL.cBlendEquation, CGL.BlendEquationStandard)
      ..SetUniform(CGL.uColorAlpha, VM.Vector4(0.0, 0.0, 1.0, 1.0))
      ..SetUniform(CGL.uColorAlpha2, VM.Vector4(0.0, 0.0, 0.1, 0.1));

    program = CGL.RenderProgram(
        "wf", cgl, wireframeVertexShader, wireframeFragmentShader);
    mesh = CGL.GeometryBuilderToMeshData("wf", program, torus);
  }

  Scene.Portal(CGL.ChronosGL cgl) {
    mat = CGL.Material("portal")
      ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity())
      ..SetUniform(CGL.uTime, 0.0)
      ..SetUniform(CGL.uPointSize, 400.0);

    program = CGL.RenderProgram(
        "portal", cgl, PORTAL.VertexShader, PORTAL.FragmentShader);

    mesh = PORTAL.MakePortal(program);
  }

  Scene.Finale(CGL.ChronosGL cgl) {
    mat = CGL.Material("finale")
      ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity())
      ..SetUniform(CGL.uTransformationMatrix, VM.Matrix4.zero())
      ..SetUniform(CGL.uTime, 0.0);

    program = CGL.RenderProgram("finale", cgl, CGL.perlinNoiseVertexShader,
        CGL.makePerlinNoiseColorFragmentShader(false));
    mesh = CGL.ShapeTorusKnot(program);
  }

  Scene.InsideFractal(CGL.ChronosGL cgl, int w, int h) {
    program = CGL.RenderProgram(
        "fractal", cgl, FRACTAL.VertexShader, FRACTAL.FragmentShader);
    mesh = CGL.ShapeQuad(program, 1);
    if (1 == 1) {
      mat = CGL.Material("fractal");
      return;
    }

    int tw = 4 * 1024;
    int th = 4 * 1024;
    CGL.Framebuffer fb = CGL.Framebuffer.Default(cgl, tw, th);
    fb.Activate(CGL.GL_CLEAR_ALL, 0, 0, tw, th);

    mat = CGL.Material("fractal")
      ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity());

    program.Draw(mesh, [mat]);
    mat
      ..SetUniform(CGL.uTexture, fb.colorTexture)
      ..SetUniform(CGL.uColor, VM.Vector3(0.1, 0.0, 0.0));

    program = CGL.RenderProgram(
        "fractal", cgl, texturedVertexShader, texturedFragmentShader);

    CGL.GeometryBuilder torus = InsideTorusKTexture(kHeight ~/ 8, kWidth ~/ 8);

    mesh = CGL.GeometryBuilderToMeshData("fractal", program, torus);

    // switch back to default screen
    CGL.Framebuffer.Screen(cgl).Activate(CGL.GL_CLEAR_ALL, 0, 0, w, h);
  }

  Scene.Sky(CGL.ChronosGL cgl, int w, int h) {
    program = CGL.RenderProgram(
      "sky", cgl, SKY.VertexShader, SKY.FragmentShader);
    mesh = CGL.ShapeQuad(program, 1);
    mat = CGL.Material('sky');
  }

  void Draw(CGL.ChronosGL cgl, CGL.Perspective perspective) {
    program.Draw(mesh, [perspective, mat]);
  }

  CGL.Material mat;
  CGL.RenderProgram program;
  CGL.MeshData mesh;
}


class SceneGOL extends Scene {
  SceneGOL(CGL.ChronosGL cgl, this.w, this.h) {
    CGL.GeometryBuilder torus =
        InsideTorusKTexture(GOLHeight ~/ 16, GOLWidth ~/ 16);
    program = CGL.RenderProgram(
        "gol", cgl, texturedVertexShader, texturedFragmentShader);
    mesh = CGL.GeometryBuilderToMeshData("gol", program, torus);

    fb = CGL.Framebuffer.Default(cgl, GOLHeight * 4, GOLWidth * 4);
    gol = GOL.Life(cgl, GOLHeight, GOLWidth, 4, true);

    screen = CGL.Framebuffer.Screen(cgl);

    mat = CGL.Material("gol")
      ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity())
      ..SetUniform(CGL.uTexture, fb.colorTexture)
      ..SetUniform(CGL.uColor, VM.Vector3(0.1, 0.0, 0.0));
  }

  factory SceneGOL.Variant1(CGL.ChronosGL cgl, int w, int h, Math.Random rng) {
    var res = SceneGOL(cgl, w, h);
    res.gol
      ..SetRandom(rng, 10)
      ..SetRules(rng, "23/3")
      ..SetPalette("Regular", [0, 255, 0], [0, 0, 0]);
    return res;
  }

  factory SceneGOL.Variant2(CGL.ChronosGL cgl, int w, int h, Math.Random rng) {
    var res = SceneGOL(cgl, w, h);
    res.gol
      ..SetRandom(rng, 35)
      ..SetRules(rng, "45678/3")
      ..SetPalette("Blur", [255, 0, 0], [0, 0, 128]);
    for (int i = 0; i < 100; ++i) res.gol.Step(false, rng);
    return res;
  }

  void Draw(CGL.ChronosGL cgl, CGL.Perspective perspective) {
    if (count % 3 == 0) {
      gol.Step(false, null);
    }
    ++count;
    fb.Activate(CGL.GL_CLEAR_ALL, 0, 0, kHeight * 4, kWidth * 4);
    gol.DrawToScreen();
    screen.Activate(CGL.GL_CLEAR_ALL, 0, 0, w, h);
    program.Draw(mesh, [perspective, mat]);
  }

  int count = 0;
  CGL.Framebuffer fb;
  int w, h;
  GOL.Life gol;
  CGL.Framebuffer screen;
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
      ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity())
      ..SetUniform(CGL.uShininess, 10.0)
      ..SetUniform(CGL.uTexture2, fb.colorTexture)
      ..SetUniform(CGL.uTexture, MakeNoiseTexture(cgl, rng));

    programPrep = CGL.RenderProgram(
        "sketch-prep", cgl, sketchPrepVertexShader, sketchPrepFragmentShader);
    program = CGL.RenderProgram(
        "final", cgl, sketchVertexShader, sketchFragmentShader);
    mesh = CGL.GeometryBuilderToMeshData("sketch", program, buildings);
  }

  void Draw(CGL.ChronosGL cgl, CGL.Perspective perspective) {
    fb.Activate(CGL.GL_CLEAR_ALL, 0, 0, w, h);
    programPrep.Draw(mesh, [perspective, illumination, mat]);
    screen.Activate(CGL.GL_CLEAR_ALL, 0, 0, w, h);
    program.Draw(mesh, [perspective, illumination, mat]);
  }

  int w, h;
  CGL.Framebuffer fb;
  CGL.Illumination illumination;
  CGL.RenderProgram programPrep;
  CGL.Framebuffer screen;
}

class SceneSketch2 extends Scene {
  SceneSketch2(CGL.ChronosGL cgl, Math.Random rng, this.w, this.h,
      Floorplan floorplan, CGL.GeometryBuilder torus, int kWidth) {
    final Shape shape = CITY.MakeBuildings(
        cgl,
        rng,
        666.0,
        floorplan.GetBuildings(),
        torus,
        kWidth,
        ["delta", "alpha"],
        THEME.allThemes[THEME.kModeSketch]);

    fb = CGL.Framebuffer.Default(cgl, w, h);

    final VM.Vector3 dirLight = VM.Vector3(2.0, -1.2, 0.5);
    CGL.Light light = CGL.DirectionalLight(
        "dir", dirLight, CGL.ColorWhite, CGL.ColorBlack, 1000.0);

    illumination = CGL.Illumination()..AddLight(light);

    screen = CGL.Framebuffer.Screen(cgl);

    programPrep = CGL.RenderProgram(
        "sketch-prep", cgl, sketchPrepVertexShader, sketchPrepFragmentShader);
    program = CGL.RenderProgram(
        "final", cgl, sketchVertexShader, sketchFragmentShader);
    print(">>>>>>> ${shape}");
    CGL.Texture noise = MakeNoiseTexture(cgl, rng);
    for (CGL.Material m in shape.builders.keys) {
      m
        ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity())
        ..SetUniform(CGL.uShininess, 10.0)
        ..SetUniform(CGL.uTexture2, fb.colorTexture)
        ..ForceUniform(CGL.uTexture, noise);
      meshes[m] = CGL.GeometryBuilderToMeshData("", program, shape.builders[m]);
    }
  }

  void Draw(CGL.ChronosGL cgl, CGL.Perspective perspective) {
    fb.Activate(CGL.GL_CLEAR_ALL, 0, 0, w, h);
    for (CGL.Material m in meshes.keys) {
      programPrep.Draw(meshes[m], [perspective, illumination, m]);
    }
    screen.Activate(CGL.GL_CLEAR_ALL, 0, 0, w, h);
    for (CGL.Material m in meshes.keys) {
      program.Draw(meshes[m], [perspective, illumination, m]);
    }
  }

  int w, h;
  CGL.Framebuffer fb;
  CGL.Illumination illumination;
  CGL.RenderProgram programPrep;
  CGL.Framebuffer screen;
  Map<CGL.Material, CGL.MeshData> meshes = {};
}

class SceneCityNight extends Scene {
  SceneCityNight(CGL.ChronosGL cgl, Math.Random rng, this.w, this.h,
      Floorplan floorplan, CGL.GeometryBuilder torus, int kWidth) {
    screen = CGL.Framebuffer.Screen(cgl);

    program = CGL.RenderProgram(
        "final", cgl, pcTexturedVertexShader, pcTexturedFragmentShader);

    Shape shape = CITY.MakeBuildings(cgl, rng, 666.0, floorplan.GetBuildings(),
        torus, kWidth, ["delta", "alpha"], THEME.allThemes[THEME.kModeNight]);
    print(">>>>>>> ${shape}");
    for (CGL.Material m in shape.builders.keys) {
      m.SetUniform(CGL.uModelMatrix, VM.Matrix4.identity());
      meshes[m] = CGL.GeometryBuilderToMeshData("", program, shape.builders[m]);
    }
  }

  void Draw(CGL.ChronosGL cgl, CGL.Perspective perspective) {
    screen.Activate(CGL.GL_CLEAR_ALL, 0, 0, w, h);
    for (CGL.Material m in meshes.keys)
      program.Draw(meshes[m], [perspective, m]);
  }

  int w, h;
  Map<CGL.Material, CGL.MeshData> meshes = {};
  CGL.Framebuffer screen;
}

class SceneCityWireframe extends Scene {
  SceneCityWireframe(CGL.ChronosGL cgl, Math.Random rng, this.w, this.h,
      Floorplan floorplan, CGL.GeometryBuilder torus, int kWidth) {
    screen = CGL.Framebuffer.Screen(cgl);

    program = CGL.RenderProgram(
        "final", cgl, wireframeVertexShader, wireframeFragmentShader);

    Shape shape = CITY.MakeBuildings(
        cgl,
        rng,
        666.0,
        floorplan.GetBuildings(),
        torus,
        kWidth,
        ["delta", "alpha"],
        THEME.allThemes[THEME.kModeWireframe]);
    print(">>>>>>> ${shape}");
    for (CGL.Material m in shape.builders.keys) {
      m
        ..SetUniform(CGL.uModelMatrix, VM.Matrix4.identity())
        ..SetUniform(uWidth, 1.5)
        ..SetUniform(CGL.uColor, VM.Vector3(1.0, 1.0, 0.0))
        ..SetUniform(CGL.uColorAlpha, VM.Vector4(1.0, 0.0, 0.0, 1.0))
        ..SetUniform(CGL.uColorAlpha2, VM.Vector4(0.1, 0.0, 0.0, 1.0));

      meshes[m] = CGL.GeometryBuilderToMeshData("", program, shape.builders[m]);
    }
  }

  void Draw(CGL.ChronosGL cgl, CGL.Perspective perspective) {
    screen.Activate(CGL.GL_CLEAR_ALL, 0, 0, w, h);
    for (CGL.Material m in meshes.keys)
      program.Draw(meshes[m], [perspective, m]);
  }

  int w, h;
  Map<CGL.Material, CGL.MeshData> meshes = {};
  CGL.Framebuffer screen;
}

class AllScenes {
  AllScenes(CGL.ChronosGL cgl, Math.Random rng, int w, int h) {
    // Building Scenes

    LogInfo("creating building scenes");
    if (FAST_START_NO_BUILDINGS) {
      LogInfo("NO BUINDINGS");
      outsideSteet = Scene();

      outsideSketch = Scene();
      outsideSketch2 = Scene();

      outsideWireframeBuildings = Scene();
      outsideWireframeBuildings2 = Scene();

      outsideNightBuildings = Scene();
      outsideNightBuildings2 = Scene();
    } else {
      final Floorplan floorplan = Floorplan(kHeight, kWidth, 10, rng);
      final CGL.GeometryBuilder torus = TorusKnot(kHeight, kWidth);
      final CGL.GeometryBuilder buildings =
          CITY.MakeSimpleBuildings(floorplan.GetBuildings(), torus, kWidth);

      outsideSteet = Scene.OutsideStreet(cgl, floorplan, torus);

      outsideNightBuildings2 = Scene.OutsideNightBuildings(cgl, buildings);
      outsideNightBuildings =
          SceneCityNight(cgl, rng, w, h, floorplan, torus, kWidth);

      outsideWireframeBuildings2 =
          Scene.OutsideWireframeBuildings(cgl, buildings);
      outsideWireframeBuildings =
          SceneCityWireframe(cgl, rng, w, h, floorplan, torus, kWidth);

      outsideSketch2 = SceneSketch(cgl, rng, w, h, buildings);
      outsideSketch = SceneSketch2(cgl, rng, w, h, floorplan, torus, kWidth);
    }
    LogInfo("creating buildingcenes done");

    // Other Scenes
    LogInfo("creating other scenes");
    final CGL.GeometryBuilder torusWF =
        InsideTorusKnotWireframe(kHeight ~/ 8, kWidth ~/ 8);
    final torusWFeHex = TorusKnotWireframeHexagons(kHeight ~/ 8, kWidth ~/ 8);

    insidePlasma = Scene.InsidePlasma(cgl, torusWF);
    insideWireframe = Scene.InsideWireframe(cgl, torusWF);
    insideWireframeHex = Scene.InsideWireframe(cgl, torusWFeHex);
    insideGOL1 = SceneGOL.Variant1(cgl, w, h, rng);
    insideGOL2 = SceneGOL.Variant2(cgl, w, h, rng);
    insideFractal = Scene.InsideFractal(cgl, w, h);

    sky = Scene.Sky(cgl, w, h);
    portal = Scene.Portal(cgl);
    finale = Scene.Finale(cgl);

    LogInfo("creating other scenes done");
    CGL.Framebuffer.Screen(cgl).Activate(CGL.GL_CLEAR_ALL, 0, 0, w, h);
  }

  Scene outsideSteet;

  Scene outsideWireframeBuildings;
  Scene outsideWireframeBuildings2;

  Scene outsideNightBuildings;
  Scene outsideNightBuildings2;

  Scene outsideSketch;
  Scene outsideSketch2;

  Scene insidePlasma;
  Scene insideWireframe;
  Scene insideWireframeHex;
  Scene insideGOL1;
  Scene insideGOL2;
  Scene insideFractal;

  Scene portal;
  Scene finale;
  Scene sky;

  void UpdateCameras(String name, CGL.Perspective perspective, double timeMs,
      TorusKnotCamera tkc, InitialApproachCamera iac, CGL.OrbitCamera oc) {
    switch (name) {
      case "wireframe-orbit":
        perspective.UpdateCamera(iac);
        iac.radius = kRadius * 6.0;
        iac.animate(timeMs);
        break;
      case "night-orbit":
        perspective.UpdateCamera(iac);
        iac.radius = kRadius * 6.0;
        iac.animate(timeMs);
        break;
      case "wireframe-outside":
      case "night-outside":
      case "sketch-outside":
        tkc.SetTubeRadius(kTubeRadius + 50.0);
        // hard coded duration
        tkc.animate(25000, gCameraRoute.value);
        (portal.mat.GetUniforms()[CGL.uModelMatrix] as VM.Matrix4)
            .setTranslation(tkc.point);
        perspective.UpdateCamera(tkc);
        tkc.animate(timeMs, gCameraRoute.value);
        break;
      case "plasma-inside":
      case "wireframe-inside-hexagon":
      case "wireframe-inside":
      case "wireframe-inside-varying-width":
      case "gol-inside":
      case "gol2-inside":
      case "fractal-inside":
        tkc.SetTubeRadius(1.0);
        // hard coded duration
        tkc.animate(20000, gCameraRoute.value);
        (portal.mat.GetUniforms()[CGL.uModelMatrix] as VM.Matrix4)
            .setTranslation(tkc.point);
        perspective.UpdateCamera(tkc);
        tkc.animate(timeMs, gCameraRoute.value);
        break;
      case "finale":
        oc.azimuth = timeMs / 1000.0;
        oc.animate(timeMs);
        perspective.UpdateCamera(oc);
        break;
      default:
        assert(false, "unexepected theme ${name}");
    }
  }

  void RenderScene(String name, CGL.ChronosGL cgl, CGL.Perspective perspective,
      double timeMs) {
    portal.mat.ForceUniform(CGL.uTime, timeMs);
    finale.mat.ForceUniform(CGL.uTime, timeMs / 1000.0);

    if (name == "wireframe-inside-varying-width" ||
        name == "wireframe-inside-hexagon") {
      double alpha = Math.sin(timeMs / 2000.0) * 10.0 + 11.0;
      insideWireframe.mat.ForceUniform(uWidth, alpha);
      insideWireframeHex.mat.ForceUniform(uWidth, alpha);
    } else {
      insideWireframe.mat.ForceUniform(uWidth, 2.5);
      insideWireframeHex.mat.ForceUniform(uWidth, 2.5);
      //matBuilding.ForceUniform(uWidth, alpha);
    }

    insidePlasma.mat.ForceUniform(CGL.uTime, timeMs / 5000.0);
    switch (name) {
      case "wireframe-outside":
        outsideWireframeBuildings.Draw(cgl, perspective);
        outsideSteet.Draw(cgl, perspective);
        portal.Draw(cgl, perspective);
        break;
      case "wireframe-orbit":
        outsideWireframeBuildings.Draw(cgl, perspective);
        outsideSteet.Draw(cgl, perspective);
        break;
      case "plasma-inside":
        outsideWireframeBuildings.Draw(cgl, perspective);
        insidePlasma.Draw(cgl, perspective);
        portal.Draw(cgl, perspective);
        break;
      case "wireframe-inside-hexagon":
        outsideWireframeBuildings.Draw(cgl, perspective);
        insideWireframeHex.Draw(cgl, perspective);
        portal.Draw(cgl, perspective);
        break;
      case "wireframe-inside":
      case "wireframe-inside-varying-width":
        outsideWireframeBuildings.Draw(cgl, perspective);
        insideWireframe.Draw(cgl, perspective);
        portal.Draw(cgl, perspective);
        break;
      case "gol-inside":
        insideGOL1.Draw(cgl, perspective);
        portal.Draw(cgl, perspective);
        break;
      case "gol2-inside":
        insideGOL2.Draw(cgl, perspective);
        portal.Draw(cgl, perspective);
        break;
      case "fractal-inside":
        insideFractal.Draw(cgl, perspective);
        portal.Draw(cgl, perspective);
        break;
      case "sketch-outside":
        outsideSketch.Draw(cgl, perspective);
        outsideSteet.Draw(cgl, perspective);
        portal.Draw(cgl, perspective);
        break;
      case "night-outside":
        outsideNightBuildings.Draw(cgl, perspective);
        outsideSteet.Draw(cgl, perspective);
        sky.Draw(cgl, perspective);
        portal.Draw(cgl, perspective);
        break;
      case "night-orbit":
        outsideNightBuildings.Draw(cgl, perspective);
        outsideSteet.Draw(cgl, perspective);
        break;
      case "finale":
        finale.Draw(cgl, perspective);
        break;
      default:
        assert(false, "unexepected theme ${name}");
    }
  }
}

class ScriptScene {
  ScriptScene(this.name, this.durationMs, this.route);

  final String name;
  final double durationMs;
  final int route;
}

double kTimeUnit = 1000;

final List<ScriptScene> gScript = [
  ScriptScene("night-orbit", 25.0 * kTimeUnit, 0),
  ScriptScene("night-outside", 25.0 * kTimeUnit, 9),
  ScriptScene("gol-inside", 20.0 * kTimeUnit, 6),
  ScriptScene("wireframe-outside", 25.0 * kTimeUnit, 3),
  ScriptScene("gol2-inside", 20.0 * kTimeUnit, 6),
  ScriptScene("sketch-outside", 25.0 * kTimeUnit, 0),
  ScriptScene("finale", 25.0 * kTimeUnit, 0),
];

void main() {
  final CGL.StatsFps fps =
      CGL.StatsFps(HTML.document.getElementById("stats"), "blue", "gray");
  final params = HashParameters();
  LogInfo("Params: ${params}");
  if (params.containsKey("demo")) {
    print("demo mode");
    for (HTML.Element e in HTML.document.querySelectorAll(".control")) {
      print("disable control: ${e}");
      e.style.display = "none";
    }
    gMode.value = "demo";
  }

  IntroduceShaderVars();
  GOL.RegisterShaderVars();
  FRACTAL.RegisterShaderVars();
  SKY.RegisterShaderVars();

  final HTML.CanvasElement canvas =
      HTML.document.querySelector('#webgl-canvas');
  final CGL.ChronosGL cgl = CGL.ChronosGL(canvas)..enable(CGL.GL_CULL_FACE);

  // Cameras

  final TorusKnotCamera tkc = TorusKnotCamera();
  // manual
  final CGL.OrbitCamera mc = CGL.OrbitCamera(kRadius * 1.5, 0.0, 0.0, canvas)
    ..mouseWheelFactor = -0.2;

  final CGL.OrbitCamera oc = CGL.OrbitCamera(100, 0.0, 0.0, canvas);

  final InitialApproachCamera iac = InitialApproachCamera();

  // Misc
  final CGL.Perspective perspective =
      CGL.PerspectiveResizeAware(cgl, canvas, tkc, 0.1, 20000.0)
        ..UpdateFov(60.0);

  final Math.Random rng = Math.Random(0);

  tkc.SetTubeRadius(kTubeRadius + 50.0);
  tkc.animate(0, "9");
  iac.ci.setDst(tkc.transform);
  iac.cameraFinalPos.setFrom(tkc.point);

  AllScenes allScenes =
      AllScenes(cgl, rng, canvas.clientWidth, canvas.clientHeight);

  double zeroTimeMs = 0.0;
  double lastTimeMs = 0.0;

  String lastTheme;

  void animate(num timeMs) {
    double elapsed = timeMs - lastTimeMs;
    lastTimeMs = timeMs + 0.0;

    if (gTheme.value != lastTheme) {
      zeroTimeMs = timeMs;
      iac.azimuth = 0.0;
      lastTheme = gTheme.value;
    }

    double t = timeMs - zeroTimeMs;
    if (gMode.value == "manual-camera") {
      perspective.UpdateCamera(mc);
      // allow the camera to also reflect mouse movement.
      mc.animate(elapsed);
      allScenes.RenderScene(gTheme.value, cgl, perspective, t);
    } else if (gMode.value == "demo") {
      if (gSoundtrack.ended || gSoundtrack.currentTime == 0.0) {
        print("Music started ${gSoundtrack.ended} ${gSoundtrack.currentTime}");
        gSoundtrack.play();
      } else {
        t = 1000.0 * gSoundtrack.currentTime;
        // also check gMusic.ended
        for (ScriptScene s in gScript) {
          if (t < s.durationMs) {
            gCameraRoute.selectedIndex = s.route ~/ 3;
            allScenes.UpdateCameras(s.name, perspective, t, tkc, iac, oc);
            allScenes.RenderScene(s.name, cgl, perspective, t);
            gTheme.value = s.name;
            break;
          }
          t -= s.durationMs;
        }
      }
    } else {
      allScenes.UpdateCameras(gTheme.value, perspective, t, tkc, iac, oc);
      allScenes.RenderScene(gTheme.value, cgl, perspective, t);
    }

    gClock.text = DurationFormat(t);
    HTML.window.animationFrame.then(animate);
    fps.UpdateFrameCount(lastTimeMs);
  }

  HTML.document.body.onKeyDown.listen((HTML.KeyboardEvent e) {
    LogInfo("key pressed ${e.which} ${e.target.runtimeType}");
    if (e.target.runtimeType == HTML.InputElement) {
      return;
    }
    String cmd = new String.fromCharCodes([e.which]);
    if (cmd == " ") {
      if (gSoundtrack.paused || gSoundtrack.currentTime == 0.0) {
        gSoundtrack.play();
      } else {
        gSoundtrack.pause();
      }
    }
  });

  // play midi song via mondrianjs
  gMusic.onClick.listen((HTML.Event ev) {
    ev.preventDefault();
    ev.stopPropagation();
    playSong();
    return false;
  });

  animate(0.0);
}
