import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/catalogo_producto.dart';

const petPurple = Color(0xFF7C3AED);
const petPurpleAlt = Color(0xFF6A24D4);
const petPurpleDark = Color(0xFF6D28D9);
const petPurpleSoft = Color(0xFF8B5CF6);
const petOrange = Color(0xFFF97316);
const petOrangeDark = Color(0xFFEA580C);

class CatalogoSectionTitle extends StatelessWidget {
  const CatalogoSectionTitle({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: petOrange),
            child: Text(actionText!),
          ),
      ],
    );
  }
}

class CatalogoBanner extends StatelessWidget {
  const CatalogoBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 188),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4C1D95),
                petPurpleDark,
                petPurple,
                petPurpleSoft,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: petPurpleDark.withValues(alpha: 0.34),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -34,
                top: -42,
                child: Container(
                  width: 126,
                  height: 126,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: petOrange.withValues(alpha: 0.22),
                  ),
                ),
              ),
              Positioned(
                right: 22,
                bottom: -30,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Text(
                            'Catalogo para clientes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tienda PetHome',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Encuentra alimentos, premios, juguetes y accesorios para tu mascota',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            height: 1.25,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: petOrange,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: petOrangeDark.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Explorar catalogo',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetTypeAccessCard extends StatelessWidget {
  const PetTypeAccessCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFF3E8FF), Color(0xFFFFF7ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? petPurple : const Color(0xFFE9D5FF),
          ),
          boxShadow: _softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (selected ? petPurple : petOrange).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? petPurple : petOrange,
                size: 23,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? petPurpleDark : const Color(0xFF1F2937),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CatalogCategoryChip extends StatelessWidget {
  const CatalogCategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        avatar: Icon(
          icon,
          size: 17,
          color: selected ? Colors.white : petPurple,
        ),
        selectedColor: petPurple,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? petPurple : const Color(0xFFE9D5FF)),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1F2937),
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.compact = false,
  });

  final CatalogoProducto product;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasPromo = product.tienePromocionActiva;
    final visualAccent = hasPromo ? petOrange : petPurple;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: compact ? null : 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEDE9FE)),
            boxShadow: [
              BoxShadow(
                color: petPurpleDark.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImageBox(product: product, height: compact ? 124 : 118),
              const SizedBox(height: 10),
              Text(
                product.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.categoria,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (hasPromo)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bs ${product.precioVenta.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bs ${product.precioVisible.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: visualAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Bs ${product.precioVisible.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: visualAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (product.tienePromocionActiva)
                    ProductBadge(
                      label: product.etiquetaPromocion,
                      color: petOrange,
                    ),
                  if (product.esNovedadActiva)
                    const ProductBadge(label: 'Nuevo', color: petPurple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductImageBox extends StatelessWidget {
  const ProductImageBox({
    super.key,
    required this.product,
    required this.height,
    this.showBadges = true,
  });

  final CatalogoProducto product;
  final double height;
  final bool showBadges;

  @override
  Widget build(BuildContext context) {
    final image = product.imagen;
    final source = image?.trim();
    final hasNovedad = product.esNovedadActiva;
    final hasPromocion = product.tienePromocionActiva;
    final hasBadge = hasNovedad || hasPromocion;
    final accentColor = hasPromocion ? petOrange : petPurple;

    if (kDebugMode) {
      debugPrint(
        '[CatalogoProducto] ${product.idProducto} ${product.nombre} imagen=${product.imagen}',
      );
    }

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFFFF7ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: hasBadge ? 0.18 : 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: hasBadge ? 0.10 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          source == null || source.isEmpty
              ? const _ProductImagePlaceholder()
              : _CatalogImage(source: source),
          if (showBadges && hasBadge)
            Positioned(
              left: 10,
              top: 10,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (hasNovedad)
                    const ProductBadge(label: 'Nuevo', color: petPurple),
                  if (hasPromocion)
                    ProductBadge(
                      label: product.etiquetaPromocion,
                      color: petOrange,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CatalogImage extends StatelessWidget {
  const _CatalogImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final normalized = source.startsWith('asset:')
        ? source.replaceFirst('asset:', '')
        : source;
    final lower = normalized.toLowerCase();
    final isAsset = lower.startsWith('assets/');
    final isNetwork =
        lower.startsWith('http://') || lower.startsWith('https://');

    if (isAsset) {
      return Image.asset(
        normalized,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const _ProductImagePlaceholder(),
      );
    }

    if (!isNetwork) {
      return const _ProductImagePlaceholder();
    }

    return Image.network(
      normalized,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: petPurple.withValues(alpha: 0.75),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          const _ProductImagePlaceholder(),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          Icons.inventory_2_rounded,
          color: petPurple.withValues(alpha: 0.8),
          size: 30,
        ),
      ),
    );
  }
}

class ProductBadge extends StatelessWidget {
  const ProductBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CatalogSystemCard extends StatelessWidget {
  const CatalogSystemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.orange = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool orange;

  @override
  Widget build(BuildContext context) {
    final color = orange ? petOrange : petPurple;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3E8FF)),
        boxShadow: _softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<BoxShadow> get _softShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 18,
    offset: const Offset(0, 10),
  ),
];

String tipoMascotaLabel(TipoMascotaCatalogo? tipo) {
  switch (tipo) {
    case TipoMascotaCatalogo.perro:
      return 'Perros';
    case TipoMascotaCatalogo.gato:
      return 'Gatos';
    case TipoMascotaCatalogo.ave:
      return 'Aves';
    case TipoMascotaCatalogo.roedor:
      return 'Roedores';
    case TipoMascotaCatalogo.pez:
      return 'Peces';
    case TipoMascotaCatalogo.otro:
      return 'Otros';
    case null:
      return 'General';
  }
}
