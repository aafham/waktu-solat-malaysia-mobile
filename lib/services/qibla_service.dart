import 'dart:math';

class QiblaService {
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  double getQiblaBearing({required double latitude, required double longitude}) {
    final lat1 = _degToRad(latitude);
    final lon1 = _degToRad(longitude);
    final lat2 = _degToRad(_kaabaLat);
    final lon2 = _degToRad(_kaabaLng);

    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x =
        cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = (_radToDeg(atan2(y, x)) + 360) % 360;
    return bearing;
  }

  double _degToRad(double degree) => degree * pi / 180;
  double _radToDeg(double radian) => radian * 180 / pi;
}
