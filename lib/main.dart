import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/app.dart';

void main() async {
  await dotenv.load(fileName: "assets/.env");
  runApp(const PetHomeApp());
}
