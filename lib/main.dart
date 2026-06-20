import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:pethome_app/src/core/router/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/env");

  if (!kIsWeb) {
    final stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (stripePublishableKey != null && stripePublishableKey.trim().isNotEmpty) {
      Stripe.publishableKey = stripePublishableKey.trim();
      await Stripe.instance.applySettings();
    }

    await Firebase.initializeApp();
  }

  runApp(const PetHomeApp());
}
