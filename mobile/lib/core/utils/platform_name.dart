import 'package:flutter/foundation.dart';

/// Short name of the platform the app runs on (`android`, `ios`, `web`,
/// `macos`, `windows`, `linux`, `fuchsia`), for example to tag feedback.
String currentPlatformName() => kIsWeb ? 'web' : defaultTargetPlatform.name;
