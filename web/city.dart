library city;

import 'dart:math' as Math;

import 'package:chronosgl/chronosgl.dart' as CGL;
import 'package:vector_math/vector_math.dart' as VM;

import 'building.dart';
import 'floorplan.dart' as FLOORPLAN;
import 'geometry.dart';
import 'theme.dart' as THEME;
import 'torus.dart' as TORUS;


void ExtractTransformsAtTorusSurfaceCity(
    TORUS.TorusKnotHelper tkhelper,
    int kWidth,
    int kHeight,
    Rect base,
    double height,
    VM.Matrix4 mat,
    VM.Matrix3 matNormal) {
  VM.Vector3 GetVertex(int x, int y) {
    //assert(y < kHeight);
    //assert(x < kWidth);
    tkhelper.surfacePoint(y / kHeight * 2.0 * Math.pi, TORUS.kTubeRadius,
        x / kWidth * 2.0 * Math.pi);
    //var a2 = torus.vertices[x + y * (kWidth + 1)];
    //var a1 = tkhelper.point;
    //print("$x $kWidth  $y $kHeight    $a1  va $a2");

    return tkhelper.point.clone();
  }

  final int y = base.x.floor();
  final int x = base.y.floor();
  final int h = base.w.floor();
  final int w = base.h.floor();
  VM.Vector3 center = GetVertex(x + w ~/ 2, y + h ~/ 2);
  VM.Vector3 centerW = GetVertex(x + w ~/ 2 + 1, y + h ~/ 2);
  VM.Vector3 centerH = GetVertex(x + w ~/ 2, y + h ~/ 2 + 1);

  VM.Vector3 dir1 = centerW - center;
  VM.Vector3 dir2 = centerH - center;
  VM.Vector3 dir3 = dir1.cross(dir2)..normalize();
  VM.Vector3 pos = center.scaled(0.99);
  //node.setPosFromVec(pos);
  //VM.setViewMatrix(node.transform, pos, center, dir1);
  VM.setViewMatrix(mat, VM.Vector3.zero(), dir3, dir1);
  mat.invert();
  mat.rotateX(-Math.pi / 2.0);
  mat.setTranslation(pos);
  // TODO: this is not quite correct
  mat.copyRotation(matNormal);
}

void _AddOneBuilding(Shape shape, Math.Random rng, THEME.BuildingColors colors,
    RoofOptions roofOpt, THEME.RoofFeatures rf, FLOORPLAN.Building b) {
  //print ("building ${b}");
  switch (b.kind) {
    case FLOORPLAN.kTileBuildingTower:
      var opt = BuildingTowerOptions(rng, colors, b.height > 40.0);
      AddBuildingTower(shape, rng, b.base, b.height, opt, roofOpt, rf);
      break;
    case FLOORPLAN.kTileBuildingBlocky:
      var opt = BuildingBlockyOptions(rng, colors);

      AddBuildingBlocky(shape, rng, b.base, b.height, opt, roofOpt, rf);
      break;
    case FLOORPLAN.kTileBuildingModern:
      var opt = BuildingModernOptions(rng, colors, rf, b.height > 48.0);
      AddBuildingModern(shape, rng, b.base, b.height, opt);
      break;
    case FLOORPLAN.kTileBuildingSimple:
      var opt = BuildingSimpleOptions(rng, colors);
      AddBuildingSimple(shape, rng, b.base, b.height, opt);
      break;
    default:
      print("BAD ${b.kind}");
      assert(false);
  }
}

Shape MakeBuildings(
    CGL.ChronosGL cgl,
    Math.Random rng,
    double seed,
    List<FLOORPLAN.Building> buildings,
    TORUS.TorusKnotHelper tkhelper,
    int kWidth,
    int kHeight,
    List<String> logos,
    THEME.Theme theme) {
  print("Errecting building");
  Shape out = Shape([CGL.aNormal, CGL.aColor, CGL.aCenter, CGL.aTexUV], []);
  int count = 0;
  VM.Matrix4 mat = VM.Matrix4.zero();
  VM.Matrix3 matNormal = VM.Matrix3.zero();

  for (FLOORPLAN.Building b in buildings) {
    if (count % 100 == 0) {
      print("initialize buidings ${count}");
    }
    count++;
    Shape tmp = Shape([CGL.aNormal, CGL.aColor, CGL.aCenter, CGL.aTexUV], []);
    final THEME.BuildingColors colors = theme.colorFun(rng);
    final RoofOptions roofOpt = RoofOptions(rng, colors);
    final THEME.RoofFeatures rf = theme.roofFeatures;

    ExtractTransformsAtTorusSurfaceCity(
        tkhelper, kWidth, kHeight, b.base, b.height, mat, matNormal);

    Rect oldbase = b.base;

    b.base = Rect(-b.base.w, -b.base.h, b.base.w * 2.0, b.base.h * 2.0);
    _AddOneBuilding(tmp, rng, colors, roofOpt, rf, b);
    b.base = oldbase;

    for (String cm in tmp.builders.keys) {
      out.Get(cm).MergeAndTakeOwnership(tmp.builders[cm], mat, matNormal);
    }
  }
  print("Generate Mesh for Buildings");
  return out;
}
