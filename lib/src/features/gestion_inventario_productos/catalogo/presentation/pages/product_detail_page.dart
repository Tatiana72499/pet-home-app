import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/features/compras/presentation/pages/carrito_temporal_page.dart';
import 'package:pethome_app/src/core/features/compras/presentation/widgets/add_producto_carrito_button.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/models/catalogo_producto.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/widgets/catalogo_widgets.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final CatalogoProducto product;

  @override
  Widget build(BuildContext context) {
    final hasPromocion = product.tienePromocionActiva;
    final hasNovedad = product.esNovedadActiva;
    final availabilityLabel = product.visibleCatalogo && product.estado
        ? 'Disponible en catálogo'
        : 'No visible en catálogo';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: petPurple,
        title: const Text(
          'Detalle del producto',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Mi carrito',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CarritoTemporalPage()),
              );
            },
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [petPurpleDark, petPurple, petPurpleSoft],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            ProductImageBox(product: product, height: 280),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ProductBadge(label: product.categoria, color: petPurple),
                ProductBadge(
                  label: tipoMascotaLabel(product.tipoMascota),
                  color: petOrange,
                ),
                if (product.destacado)
                  const ProductBadge(label: 'Destacado', color: petPurple),
                if (hasNovedad)
                  const ProductBadge(label: 'Nuevo', color: petPurple),
                if (hasPromocion)
                  ProductBadge(
                    label: product.etiquetaPromocion,
                    color: petOrange,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              product.nombre,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.descripcion,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                height: 1.45,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEDE9FE)),
                boxShadow: [
                  BoxShadow(
                    color: petPurpleDark.withValues(alpha: 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Precio',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasPromocion)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bs ${product.precioVenta.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bs ${product.precioVisible.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: petOrange,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Bs ${product.precioVisible.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: petOrange,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  const SizedBox(height: 14),
                  _InfoRow(label: 'Categoría', value: product.categoria),
                  _InfoRow(
                    label: 'Tipo de mascota',
                    value: tipoMascotaLabel(product.tipoMascota),
                  ),
                  _InfoRow(label: 'Estado visual', value: availabilityLabel),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF3E8FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Disponibilidad',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    availabilityLabel,
                    style: const TextStyle(color: Color(0xFF6B7280), height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Consulta de disponibilidad preparada para futuro uso.'),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Consultar disponibilidad'),
              style: FilledButton.styleFrom(
                backgroundColor: petPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 10),
            AddProductoCarritoButton(productoId: product.idProducto),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
