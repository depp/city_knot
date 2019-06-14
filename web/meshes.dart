/// This file contains the code for creating GeometryBuilders
///

import 'package:chronosgl/chronosgl.dart' as CGL;

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
const int GOLWidth = kWidth ~/ 2;
const int GOLHeight = kHeight ~/ 2;

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

