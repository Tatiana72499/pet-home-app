import 'package:flutter/material.dart';

class CarritoTotalCard extends StatelessWidget {
  const CarritoTotalCard({
    super.key,
    required this.subtotalEstimado,
    required this.totalEstimado,
  });

  final double subtotalEstimado;
  final double totalEstimado;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 30 / 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _Line(label: 'Subtotal estimado', value: _money(subtotalEstimado)),
          const SizedBox(height: 6),
          _Line(
            label: 'Total estimado',
            value: _money(totalEstimado),
            bold: true,
          ),
          const SizedBox(height: 8),
          const Text(
            'El total final sera validado por la veterinaria.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static String _money(double value) => 'Bs ${value.toStringAsFixed(2)}';
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: const Color(0xFF1F2937),
      fontSize: 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(value, style: style),
      ],
    );
  }
}
