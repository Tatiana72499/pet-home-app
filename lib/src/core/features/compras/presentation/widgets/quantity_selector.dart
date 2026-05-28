import 'package:flutter/material.dart';

class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.enabled = true,
  });

  final double quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5D4FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: Icons.remove,
            onTap: enabled ? onDecrement : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ActionButton(
            icon: Icons.add,
            onTap: enabled ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? Colors.grey : const Color(0xFF7C3AED),
        ),
      ),
    );
  }
}
