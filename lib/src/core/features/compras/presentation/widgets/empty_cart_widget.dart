import 'package:flutter/material.dart';

class EmptyCartWidget extends StatelessWidget {
  const EmptyCartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAD9FF)),
      ),
      child: const Column(
        children: [
          Icon(Icons.shopping_cart_outlined, color: Color(0xFF7C3AED), size: 36),
          SizedBox(height: 10),
          Text(
            'Tu carrito esta vacio.',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Agrega productos o servicios desde el catalogo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
