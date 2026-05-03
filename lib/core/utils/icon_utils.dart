import 'package:flutter/material.dart';

IconData createMaterialIcon(int codePoint) {
  return IconData(
    codePoint,
    fontFamily: 'MaterialIcons',
  );
}
