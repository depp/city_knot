library city;

import 'dart:math' as Math;

import 'package:chronosgl/chronosgl.dart' as CGL;
import 'package:vector_math/vector_math.dart' as VM;

import 'building.dart';
import 'config.dart';
import 'facade.dart' as FACADE;
import 'floorplan.dart' as FLOORPLAN;
import 'geometry.dart';
import 'rgb.dart';
import 'theme.dart' as THEME;

CGL.GeometryBuilder _MakeOneBuilding(double dx, double dy, double dz) {
  CGL.GeometryBuilder gb = CGL.CubeGeometry(
      x: dx, y: dy, z: dz, uMin: 0.0, uMax: 1.0, vMin: 0.0, vMax: 1.0);
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

void ExtractTransformsAtTorusSurface(CGL.GeometryBuilder torus, int kWidth,
    Rect base, double height, VM.Matrix4 mat, VM.Matrix3 matNormal) {
  VM.Vector3 GetVertex(int x, int y) {
    return torus.vertices[x + y * (kWidth + 1)];
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
  VM.Vector3 pos = center + dir3.scaled(height);
  //node.setPosFromVec(pos);

  //VM.setViewMatrix(node.transform, pos, center, dir1);
  VM.setViewMatrix(mat, VM.Vector3.zero(), dir3, dir1);
  mat.invert();
  mat.setTranslation(pos);

  // TODO: this is not quite correct
  mat.copyRotation(matNormal);
}

void ExtractTransformsAtTorusSurfaceCity(CGL.GeometryBuilder torus, int kWidth,
    Rect base, double height, VM.Matrix4 mat, VM.Matrix3 matNormal) {
  VM.Vector3 GetVertex(int x, int y) {
    return torus.vertices[x + y * (kWidth + 1)];
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

CGL.GeometryBuilder MakeSimpleBuildings(
    List<FLOORPLAN.Building> buildings, CGL.GeometryBuilder torus, int kWidth) {
  print("building stats ${buildings.length}");

  CGL.GeometryBuilder out = CGL.GeometryBuilder();
  out.EnableAttribute(CGL.aColor);
  out.EnableAttribute(CGL.aNormal);
  out.EnableAttribute(CGL.aTexUV);
  out.EnableAttribute(CGL.aCenter);

  VM.Matrix4 mat = VM.Matrix4.zero();
  VM.Matrix3 matNormal = VM.Matrix3.zero();

  for (FLOORPLAN.Building b in buildings) {
    final int h = b.base.w.floor();
    final int w = b.base.h.floor();
    final CGL.GeometryBuilder gb = _MakeOneBuilding(h + 0.0, w + 0.0, b.height);

    ExtractTransformsAtTorusSurface(
        torus, kWidth, b.base, b.height, mat, matNormal);
    out.MergeAndTakeOwnership(gb, mat, matNormal);
  }
  print("final building gb ${out}");
  return out;
}

List<CGL.Material> MakeWallMaterials(
    CGL.ChronosGL cgl, Math.Random rng, double seed, int style) {
  switch (style) {
    case THEME.kWallStyleNone:
      return [CGL.Material("no-wall")];
    case THEME.kWallStyleDay:
      return FACADE.MakeWindowWalls(cgl, seed, kRGBwhite, false);
    case THEME.kWallStyleNight:
      return FACADE.MakeWindowWalls(cgl, seed, kRGBblack, true);
    case THEME.kWallStyleSketch:
      CGL.Texture noise = FACADE.MakeNoiseTesture(cgl, Math.Random());
      return [CGL.Material("sketch")..SetUniform(CGL.uTexture, noise)];
    default:
      assert(false, "unknown mode ${style}");
      return [];
  }
}

void _AddOneBuilding(
    Shape shape,
    Math.Random rng,
    BuildingParameters params,
    THEME.BuildingColors colors,
    RoofOptions roofOpt,
    THEME.RoofFeatures rf,
    FLOORPLAN.Building b) {
    //print ("building ${b}");
  switch (b.kind) {
    case FLOORPLAN.kTileBuildingTower:
      var opt = BuildingTowerOptions(rng, params, colors, b.height > 40.0);

      AddBuildingTower(shape, rng, b.base, b.height, opt, roofOpt, rf);
      break;
    case FLOORPLAN.kTileBuildingBlocky:
      var opt = BuildingBlockyOptions(rng, params, colors);

      AddBuildingBlocky(shape, rng, b.base, b.height, opt, roofOpt, rf);
      break;
    case FLOORPLAN.kTileBuildingModern:
      var opt = BuildingModernOptions(rng, params, colors, rf, b.height > 48.0);
      AddBuildingModern(shape, rng, b.base, b.height, opt);
      break;
    case FLOORPLAN.kTileBuildingSimple:
      var opt = BuildingSimpleOptions(rng, params, colors);
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
    CGL.GeometryBuilder torus,
    int kWidth,
    List<String> logos,
    THEME.Theme theme) {
  print("Make building materials");

  final CGL.Material logo = theme.roofFeatures.allowLogo
      ? FACADE.MakeLogo(cgl, logos, theme.logoFgColor, theme.logoBgColor)
      : CGL.Material("dummy");

  final BuildingParameters params = BuildingParameters()
    ..wallMats = MakeWallMaterials(cgl, rng, seed, theme.wallStyle)
    ..logoMat = logo
    ..lightTrimMat = FACADE.MakeLightTrims(cgl)
    ..pointLightMat = FACADE.MakePointLight(cgl)
    ..flashingLightMat = FACADE.MakeFlashingLight(cgl)
    ..radioTowerMat = FACADE.MakeRadioTower(cgl)
    ..num_logos = kNumBuildingLogos
    ..solidMat = FACADE.MakeSolid(cgl);

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
    final RoofOptions roofOpt = RoofOptions(rng, params, colors);
    final THEME.RoofFeatures rf = theme.roofFeatures;

    ExtractTransformsAtTorusSurfaceCity(
        torus, kWidth, b.base, b.height, mat, matNormal);

    Rect oldbase = b.base;

    b.base = Rect(-b.base.w,  -b.base.h , b.base.w * 2.0, b.base.h * 2.0);
    _AddOneBuilding(tmp, rng, params, colors, roofOpt, rf, b);
    b.base = oldbase;

    for (CGL.Material cm in tmp.builders.keys) {
      out.Get(cm).MergeAndTakeOwnership(tmp.builders[cm], mat, matNormal);
    }
  }
  print("Generate Mesh for Buildings");
  return out;
}
