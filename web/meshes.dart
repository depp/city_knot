/// This file contains the code for creating GeometryBuilders
///
import 'dart:math' as Math;

import 'package:chronosgl/chronosgl.dart' as CGL;
import 'package:vector_math/vector_math.dart' as VM;

import 'logging.dart';

// The final version will set magicMutl to 2 but this is slow
// to start up so during development it will be 1
const int magicMult = 4;
const double kRadius = 125.0 * magicMult;
const double kHeightScale = 1.0;
const double kTubeRadius = 25.0 * magicMult;
const int kWidth = 60 * magicMult; // divisible by 3 and 8
const int kHeight = 800 * magicMult; // divisible by 3 and 8

const double kBuildingDim = 20;

// Note, this is too large for most graphic cards and you may want
// to divide this by 2 or 4 during development
const int GOLWidth = kWidth;
const int GOLHeight = kHeight;

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

CGL.GeometryBuilder InsideTorusKnotWireframe(int segmentsR, int segmentsT) {
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

CGL.GeometryBuilder InsideTorusKTexture(int segmentsR, int segmentsT) {
  LogInfo("start torus gb ${kWidth}x${kHeight}");

  final CGL.GeometryBuilder gb = CGL.TorusKnotGeometry(
      heightScale: kHeightScale,
      radius: kRadius,
      tubeRadius: kTubeRadius,
      segmentsR: segmentsR,
      segmentsT: segmentsT,
      computeUVs: true,
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


