@JS('WSCapture')
library wscapture;

import 'package:js/js.dart';

@JS('startRecording')
external void startRecording();

@JS('stopRecording')
external void stopRecording();

@JS('stealContext')
external void stealContext();

@JS('currentTimeMS')
external double currentTimeMS(double timeMS);

@JS('beginFrame')
external bool beginFrame();

@JS('endFrame')
external void endFrame();