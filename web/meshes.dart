/// This file contains the code for creating GeometryBuilders
///
import 'dart:math' as Math;

import 'package:chronosgl/chronosgl.dart' as CGL;
import 'package:vector_math/vector_math.dart' as VM;

import 'floorplan.dart';
import 'logging.dart';

const int magicMult = 1;
const double kRadius = 500.0 * magicMult;
const double kHeightScale = 1.0;
const double kTubeRadius = 100.0 * magicMult;
const int kWidth = 240 * magicMult; // divisible by 3 and 8
const int kHeight = 2400 * magicMult; // divisible by 3 and 8
const double kBuildingDim = 20;

/// Like ShapeTorusKnotGeometry but with duplicate Vertices to make it
/// possible to add aCenter attributes with GenerateWireframeCenters()
CGL.GeometryBuilder TorusKnotGeometryTriangularWireframeFriendly(
    {double radius = 20.0,
    double tubeRadius = 4.0,
    int segmentsR = 128,
    int segmentsT = 16,
    int p = 2,
    int q = 3,
    double heightScale = 1.0,
    bool inside = false}) {
  void curveFunc(double u, VM.Vector3 out) {
    CGL.TorusKnotGetPos(u, q, p, radius, heightScale, out);
  }

  final List<VM.Vector3> pointsAndTangents =
      CGL.ParametricCurvePointsAndTangents(
          curveFunc, 0.0, 2.0 * Math.pi, segmentsR,
          halfOpen: true);
  pointsAndTangents.add(pointsAndTangents[0]);
  pointsAndTangents.add(pointsAndTangents[1]);
  final int h = segmentsR + 1;
  assert(pointsAndTangents.length == 2 * h);
  final List<List<VM.Vector3>> bands =
      CGL.TubeHullBands(pointsAndTangents, segmentsT, tubeRadius);
  for (List<VM.Vector3> b in bands) {
    b.add(b[0]);
    b.add(b[1]);
  }
  assert(bands.length == h);

  final CGL.GeometryBuilder gb = CGL.GeometryBuilder();

  for (int i = 0; i < segmentsR; ++i) {
    for (int j = 0; j < segmentsT; j += 2) {
      final int jp = j + (i % 2) * 3;
      gb.AddFaces3(2);
      VM.Vector3 b(int x, int y) => bands[x % segmentsR][(y % segmentsT) * 2];

      if (inside) {
        gb.AddVerticesTakeOwnership([b(i, jp), b(i + 1, jp + 1), b(i, jp + 2)]);

        gb.AddVerticesTakeOwnership(
            [b(i, jp + 2), b(i + 1, jp + 1), b(i + 1, jp + 3)]);
      } else {
        // TODO: needs more work for triangle orientation
        gb.AddVerticesTakeOwnership([b(i, jp), b(i + 1, jp + 1), b(i, jp + 2)]);
        gb.AddVerticesTakeOwnership(
            [b(i, jp + 2), b(i + 1, jp + 1), b(i + 1, jp + 3)]);
      }
    }
  }

  return gb;
}

void MyGenerateWireframeCenters(CGL.GeometryBuilder gb) {
  List<VM.Vector4> center = List<VM.Vector4>(gb.vertices.length);

  List<VM.Vector4> center3 = [
    VM.Vector4(1.0, 100.0, 0.0, 0.0),
    VM.Vector4(100.0, 1.0, 0.0, 0.0),
    VM.Vector4(100.0, 100.0, 1.0, 0.0),
    VM.Vector4(1.0, 100.0, 100.0, 0.0),
    VM.Vector4(0.0, 1.0, 100.0, 0.0),
    VM.Vector4(0.0, 100.0, 1.0, 0.0),
    VM.Vector4(1.0, 100.0, 100.0, 0.0),
    VM.Vector4(0.0, 1.0, 100.0, 0.0),
    VM.Vector4(0.0, 100.0, 1.0, 0.0),
    VM.Vector4(1.0, 100.0, 0.0, 0.0),
    VM.Vector4(100.0, 1.0, 0.0, 0.0),
    VM.Vector4(100.0, 100.0, 1.0, 0.0),
    VM.Vector4(1.0, 0.0, 100.0, 0.0),
    VM.Vector4(100.0, 1.0, 100.0, 0.0),
    VM.Vector4(100.0, 0.0, 1.0, 0.0),
    VM.Vector4(1.0, 0.0, 100.0, 0.0),
    VM.Vector4(100.0, 1.0, 100.0, 0.0),
    VM.Vector4(100.0, 0.0, 1.0, 0.0),
  ];

  int count = 0;
  for (CGL.Face3 f in gb.faces3) {
    center[f.a] = center3[count + 0];
    center[f.b] = center3[count + 1];
    center[f.c] = center3[count + 2];
    count += 3;
    if (count == center3.length) count = 0;
  }

  VM.Vector4 a4 = VM.Vector4(1.0, 0.0, 0.0, 1.0);
  VM.Vector4 b4 = VM.Vector4(1.0, 1.0, 0.0, 1.0);
  VM.Vector4 c4 = VM.Vector4(0.0, 1.0, 0.0, 1.0);
  VM.Vector4 d4 = VM.Vector4(0.0, 0.0, 0.0, 1.0);

  for (CGL.Face4 f in gb.faces4) {
    center[f.a] = a4.clone();
    center[f.b] = b4.clone();
    center[f.c] = c4.clone();
    center[f.d] = d4.clone();
  }
  gb.attributes[CGL.aCenter] = center;
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

// This does not quite work yet
CGL.GeometryBuilder TorusKnotWireframeHexagons(int segmentsR, int segmentsT) {
  LogInfo("start torus gb ${kWidth}x${kHeight}");

  final CGL.GeometryBuilder gb = TorusKnotGeometryTriangularWireframeFriendly(
      heightScale: kHeightScale,
      radius: kRadius,
      tubeRadius: kTubeRadius,
      segmentsR: segmentsR,
      segmentsT: segmentsT,
      inside: true);

  MyGenerateWireframeCenters(gb);
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

CGL.GeometryBuilder MakeOneBuilding(double dx, double dy, double dz) {
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

CGL.GeometryBuilder MakeBuildings(
    Floorplan floorplan, CGL.GeometryBuilder torus) {
  print("building statr ${floorplan.GetBuildings().length}");

  VM.Vector3 GetVertex(int x, int y) {
    return torus.vertices[x + y * (kWidth + 1)];
  }

  CGL.GeometryBuilder out = CGL.GeometryBuilder();
  out.EnableAttribute(CGL.aColor);
  out.EnableAttribute(CGL.aNormal);
  out.EnableAttribute(CGL.aTexUV);
  out.EnableAttribute(CGL.aCenter);

  VM.Matrix3 matNormal = VM.Matrix3.zero();

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
    VM.Vector3 dir3 = dir1.cross(dir2)..normalize();
    VM.Vector3 pos = center + dir3.scaled(b.height);
    //node.setPosFromVec(pos);

    //VM.setViewMatrix(node.transform, pos, center, dir1);
    CGL.Spatial transform = CGL.Spatial("tmp");
    transform.lookAt(dir3, dir1);
    transform.transform.invert();
    transform.setPosFromVec(pos);

    // TODO: this is not quite correct
    transform.transform.copyRotation(matNormal);
    out.MergeAndTakeOwnership(gb, transform.transform, matNormal);
  }
  print("final building gb ${out}");
  return out;
}
