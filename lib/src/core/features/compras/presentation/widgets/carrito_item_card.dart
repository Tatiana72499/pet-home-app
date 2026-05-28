import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/features/compras/data/models/detalle_carrito_temporal_model.dart';
import 'package:pethome_app/src/core/features/compras/presentation/widgets/quantity_selector.dart';

class CarritoItemCard extends StatelessWidget {
  const CarritoItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    this.enabled = true,
  });

  final DetalleCarritoTemporalModel item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final icon = item.esProducto ? Icons.shopping_bag_outlined : Icons.medical_services_outlined;
    final badge = item.esProducto ? 'PRODUCTO' : 'SERVICIO';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2D8F0)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titulo,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.esProducto
                          ? 'Producto'
                          : 'Servicio${item.mascotaNombre == null ? '' : ' · ${item.mascotaNombre}'}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9D5FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Color(0xFF6D28D9),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Bs ${item.precioUnitarioEstimado.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w900,
                      fontSize: 24 / 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal Bs ${item.subtotalEstimado.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              QuantitySelector(
                quantity: item.cantidad,
                onDecrement: onDecrement,
                onIncrement: onIncrement,
                enabled: enabled,
              ),
              const Spacer(),
              IconButton(
                onPressed: enabled ? onDelete : null,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
