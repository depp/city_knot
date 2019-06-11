library torus;

import 'dart:math' as Math;

import 'package:chronosgl/chronosgl.dart' as CGL;
import 'package:vector_math/vector_math.dart' as VM;

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

class TorusKnotHelper {
  TorusKnotHelper(this._radius, this._p, this._q, this._heightScale);

  final double _radius;
  final int _p;
  final int _q;
  final double _heightScale;
  final double _TorusEpsilon = 0.01;

  // point in center / on surface
  final VM.Vector3 point = VM.Vector3.zero();

  // point in center / on surface slightly ahead
  final VM.Vector3 target = VM.Vector3.zero();

  // tangent (target - point)
  final VM.Vector3 tangent = VM.Vector3.zero();

  // vector from center to surface
  final VM.Vector3 offset = VM.Vector3.zero();

  // tangent plane
  final VM.Vector3 v1 = VM.Vector3.zero();
  final VM.Vector3 v2 = VM.Vector3.zero();

  void surfacePoint(double u, double tubeRadius, double tubeAzimuth) {
    CGL.TorusKnotGetPos(u, _q, _p, _radius, _heightScale, point);
    //p1.scale((p1.length + kTubeRadius * 1.1) / p1.length);

    CGL.TorusKnotGetPos(
        u + _TorusEpsilon, _q, _p, _radius, _heightScale, target);
    tangent
      ..setFrom(target)
      ..sub(point);

    buildPlaneVectors(tangent, v1, v2);
    offset
      ..setZero()
      ..addScaled(v1, tubeRadius * Math.cos(tubeAzimuth))
      ..addScaled(v2, tubeRadius * Math.sin(tubeAzimuth));

    point.add(offset);
    target.add(offset);
  }
}

// Camera flying through a TorusKnot like through a tunnel
class TorusKnotCamera extends CGL.Spatial {
  TorusKnotCamera(double radius, int p, int q, double heightScale)
      : _tkhelper = TorusKnotHelper(radius, p, q, heightScale),
        super("camera:torusknot");

  TorusKnotHelper _tkhelper;
  double _tubeRadius = 1.0;

  VM.Vector3 getPoint() => _tkhelper.point;

  void animate(double timeMs, double speed, String route) {
    double u = timeMs * speed / 6000;

    _tkhelper.surfacePoint(
        u, _tubeRadius, int.parse(route) / 12.0 * 2.0 * Math.pi);

    setPosFromVec(_tkhelper.point);
    lookAt(_tkhelper.target, _tkhelper.offset);
  }

  void SetTubeRadius(double tr) {
    this._tubeRadius = tr;
  }
}
