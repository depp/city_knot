import 'dart:html' as HTML;
import 'dart:math' as Math;

import 'package:chronosgl/chronosgl.dart' as CGL;
import 'package:vector_math/vector_math.dart' as VM;

import 'floorplan.dart';
import 'logging.dart';

VM.Vector3 p1 = VM.Vector3.zero();

const int magicMult = 1;
const double kRadius = 500.0 * magicMult;
const double kHeightScale = 1.0;
const double kTubeRadius = 100.0 * magicMult;
final int kWidth = 200 * magicMult;
final int kHeight = 2400 * magicMult;
const double kBuildingDim = 20;

final HTML.InputElement gCameraMode =
HTML.document.querySelector('#toruscam') as HTML.InputElement;

final HTML.SelectElement gCameraRoute =
HTML.document.querySelector('#routecam') as HTML.SelectElement;

final HTML.SelectElement gTheme =
HTML.document.querySelector('#theme') as HTML.SelectElement;

final HTML.Element gClock = HTML.document.querySelector('#clock');

void buildPlaneVectors(final VM.Vector3 planeNormal, VM.Vector3 u,
    VM.Vector3 v) {
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
  TorusKnotCamera({this.radius = kRadius,
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

CGL.Scene MakeStarScene(CGL.ChronosGL cgl, CGL.UniformGroup perspective,
    int num) {
  CGL.Scene scene = CGL.Scene(
      "stars",
      CGL.RenderProgram("stars", cgl, CGL.pointSpritesVertexShader,
          CGL.pointSpritesFragmentShader),
      [perspective]);
  scene.add(CGL.Utils.MakeParticles(scene.program, num));
  return scene;
}

CGL.GeometryBuilder TorusKnot(int segmentsR, int segmentsT) {
  LogInfo("start torus gb ${kWidth}x${kHeight}");
  final CGL.GeometryBuilder gb = CGL.TorusKnotGeometry(
      heightScale: kHeightScale,
      radius: kRadius,
      tubeRadius: kTubeRadius,
      segmentsR: segmentsR,
      segmentsT: segmentsT,
      computeUVs: true,
      computeNormals: false);
  //gb.GenerateWireframeCenters();
  //assert(gb.vertices.length == w * h);
  LogInfo("done torus gb ${gb}");

  return gb;
}

CGL.GeometryBuilder TorusKnotWireframe(int segmentsR, int segmentsT) {
  LogInfo("start torus gb ${kWidth}x${kHeight}");
  final CGL.GeometryBuilder gb = CGL.TorusKnotGeometryWireframeFriendly(
      heightScale: kHeightScale,
      radius: kRadius,
      tubeRadius: kTubeRadius,
      segmentsR: segmentsR,
      segmentsT: segmentsT,
      computeUVs: false,
      computeNormals: false,
      inside: true);
  gb.GenerateWireframeCenters();
  //assert(gb.vertices.length == w * h);
  LogInfo("done torus-wireframe gb ${gb}");

  return gb;
}

CGL.MeshData Sphere(CGL.RenderProgram program, double scale) {
  CGL.GeometryBuilder gb = CGL.IcosahedronGeometry(
      subdivisions: 4, scale: scale, computeNormals: true);
  gb.EnableAttribute(CGL.aColor);
  VM.Vector3 c = VM.Vector3(1.0, 0.0, 0.0);

  final List<VM.Vector3> colors = [];

  for (int n = 0; n < gb.vertices.length; n++) {
    colors.add(c);
  }
  gb.AddAttributesVector3(CGL.aColor, colors);

  return CGL.GeometryBuilderToMeshData("icosahedron-${4}", program, gb);
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

CGL.GeometryBuilder MakeOneBuilding(double dx, double dy, double dz) {
  CGL.GeometryBuilder gb = CGL.CubeGeometry(
      x: dx,
      y: dy,
      z: dz,
      uMin: 0.0,
      uMax: 1.0,
      vMin: 0.0,
      vMax: 1.0);
  gb.EnableAttribute(CGL.aColor);
  final List<VM.Vector3> colors = [];
  VM.Vector3 c = VM.Vector3.random();
  VM.Vector3 black = VM.Vector3.zero();
  for (int n = 0; n < gb.vertices.length; n++) {
    if (n ~/ 4 == 1) {
      colors.add(black);
    } else {
      colors.add(c);
    }
  }

  gb.AddAttributesVector3(CGL.aColor, colors);
  gb.GenerateWireframeCenters();
  return gb;
}

CGL.GeometryBuilder MakeBuildings(Floorplan floorplan,
    CGL.GeometryBuilder torus) {
  print("building statr ${floorplan
      .GetBuildings()
      .length}");

  VM.Vector3 GetVertex(int x, int y) {
    return torus.vertices[x + y * (kWidth + 1)];
  }

  CGL.GeometryBuilder out = CGL.GeometryBuilder();
  out.EnableAttribute(CGL.aColor);
  out.EnableAttribute(CGL.aNormal);
  out.EnableAttribute(CGL.aTexUV);
  out.EnableAttribute(CGL.aCenter);

  for (Building b in floorplan.GetBuildings()) {
    final int y = b.base.x.floor();
    final int x = b.base.y.floor();
    final int h = b.base.w.floor();
    final int w = b.base.h.floor();
    VM.Vector3 center = GetVertex(x + w ~/ 2, y + h ~/ 2);
    VM.Vector3 centerW = GetVertex(x + w ~/ 2 + 1, y + h ~/ 2);
    VM.Vector3 centerH = GetVertex(x + w ~/ 2, y + h ~/ 2 + 1);

    final CGL.GeometryBuilder gb = MakeOneBuilding(h + 0.0, w + 0.0, b.height);
    VM.Vector3 dir1 = centerW - center;
    VM.Vector3 dir2 = centerH - center;
    VM.Vector3 dir3 = dir1.cross(dir2)
      ..normalize();
    VM.Vector3 pos = center + dir3.scaled(b.height);
    //node.setPosFromVec(pos);

    //VM.setViewMatrix(node.transform, pos, center, dir1);
    CGL.Spatial transform = CGL.Spatial("tmp");
    transform.lookAt(dir3, dir1);
    transform.transform.invert();
    transform.setPosFromVec(pos);

    out.MergeAndTakeOwnership(gb, transform.transform);
  }
  print("final building gb ${out}");
  return out;
}

void main() {
  CGL.StatsFps fps =
  CGL.StatsFps(HTML.document.getElementById("stats"), "blue", "gray");

  HTML.CanvasElement canvas = HTML.document.querySelector('#webgl-canvas');
  CGL.ChronosGL cgl = CGL.ChronosGL(canvas);
  cgl.enable(CGL.GL_CULL_FACE);
  final TorusKnotCamera tkc = TorusKnotCamera();
  final CGL.OrbitCamera oc = CGL.OrbitCamera(kRadius * 3.5, 0.0, 0.0, canvas)
    ..mouseWheelFactor = -0.2;
  final CGL.Perspective perspective = CGL.Perspective(tkc, 0.1, 20000.0);
  perspective.UpdateFov(60.0);

  final Math.Random rng = Math.Random(0);

  final Floorplan floorplan = Floorplan(kHeight, kWidth, 10, rng);

  final CGL.Material mat = CGL.Material("center")
    ..SetUniform(
        CGL.uTexture, MakeFloorplanTexture(cgl, floorplan))..SetUniform(
        CGL.uColor, VM.Vector3.zero());

  final CGL.Material matBuilding = CGL.Material("center")
    ..SetUniform(CGL.uColor, VM.Vector3(1.0, 1.0, 0.0))..SetUniform(
        CGL.uColorAlpha, VM.Vector4(1.0, 0.0, 0.0, 1.0))..SetUniform(
        CGL.uColorAlpha2, VM.Vector4(0.1, 0.0, 0.0, 1.0));

  final CGL.Material matTorusknotWireframe = CGL.Material("center")
    ..ForceUniform(CGL.cBlendEquation, CGL.BlendEquationStandard)
    ..SetUniform(CGL.uColor, VM.Vector3(1.0, 1.0, 0.0))..SetUniform(
        CGL.uColorAlpha, VM.Vector4(0.0, 0.0, 1.0, 0.5))..SetUniform(
        CGL.uColorAlpha2, VM.Vector4(0.0, 0.0, 0.1, 0.0));

  final CGL.Scene sceneTorus = CGL.Scene(
      "objects",
      CGL.RenderProgram(
          "torus", cgl, CGL.texturedVertexShader, CGL.texturedFragmentShader),
      [perspective]);

  final CGL.Scene sceneBuildingNight = CGL.Scene(
      "objects",
      CGL.RenderProgram("building", cgl, CGL.multiColorVertexShader,
          CGL.multiColorFragmentShader),
      [perspective]);

  final CGL.Scene sceneBuildingWireframe = CGL.Scene(
      "objects",
      CGL.RenderProgram("building", cgl, CGL.wireframeVertexShader,
          CGL.wireframeFragmentShader),
      [perspective]);

  final CGL.RenderPhaseResizeAware phase =
  CGL.RenderPhaseResizeAware("main", cgl, canvas, perspective)
    ..add(sceneTorus)..add(sceneBuildingNight)..add(sceneBuildingWireframe);

  final CGL.GeometryBuilder torus = TorusKnot(kHeight, kWidth);
  final CGL.GeometryBuilder buildings = MakeBuildings(floorplan, torus);

  final CGL.Node buildingsNight = CGL.Node(
      "",
      CGL.GeometryBuilderToMeshData(
          "buildings", sceneBuildingNight.program, buildings),
      matBuilding);
  sceneBuildingNight.add(buildingsNight);

  final CGL.Node buildingsWireframe = CGL.Node(
      "wireframe-buildings",
      CGL.GeometryBuilderToMeshData(
          "buildings", sceneBuildingWireframe.program, buildings),
      matBuilding);
  sceneBuildingWireframe.add(buildingsWireframe);


  final CGL.GeometryBuilder torusWF =
  TorusKnotWireframe(kHeight ~/ 4, kWidth ~/ 4);
  final tkWireframe = CGL.Node(
      "wireframe KN",
      CGL.GeometryBuilderToMeshData(
          "buildings", sceneBuildingWireframe.program, torusWF),
      matTorusknotWireframe);
  sceneBuildingWireframe.add(tkWireframe);


  final tkStreet = CGL.Node(
      "torus",
      CGL.GeometryBuilderToMeshData("torusknot", sceneTorus.program, torus),
      mat);
  sceneTorus.add(tkStreet);

  CGL.Node mover = CGL.Node("moving-ball", Sphere(sceneTorus.program, 25), mat);
  sceneTorus.add(mover);

  double _lastTimeMs = 0.0;
  void animate(num timeMs) {
    double elapsed = timeMs - _lastTimeMs;
    _lastTimeMs = timeMs + 0.0;
    // animate the camera a little
    // oc.azimuth += 0.003;
    // allow the camera to also reflect mouse movement.
    oc.animate(elapsed);

    tkc.animate(_lastTimeMs * 0.5);
    mover.transform.setFrom(tkc.transform);
    //updateTorusTexture(timeMs / 1000, canvas2d);
    perspective.UpdateCamera(gCameraMode.checked ? tkc : oc);

    switch (gTheme.value) {
      case "wireframe-outside":
        buildingsWireframe.enabled = true;
        buildingsNight.enabled = false;
        tkStreet.enabled = true;
        tkWireframe.enabled = false;

        tkc.SetTubeRadius(kTubeRadius + 50.0);

        break;
      case "wireframe-inside":
        buildingsWireframe.enabled = true;
        buildingsNight.enabled = false;
        tkStreet.enabled = false;
        tkWireframe.enabled = true;

        tkc.SetTubeRadius(1.0);

        break;
      case "night-outside":
      default:
        buildingsWireframe.enabled = false;
        buildingsNight.enabled = true;
        tkStreet.enabled = true;
        tkWireframe.enabled = false;

        tkc.SetTubeRadius(kTubeRadius + 50.0);

        break;
    }
    phase.Draw();
    gClock.text = DurationFormat(timeMs);
    HTML.window.animationFrame.then(animate);
    fps.UpdateFrameCount(_lastTimeMs);
  }

  animate(0.0);
}
