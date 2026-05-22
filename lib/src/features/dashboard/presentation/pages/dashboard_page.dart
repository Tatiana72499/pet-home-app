import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/appointments/data/appointments_service.dart';
import 'package:pethome_app/src/features/auth/domain/auth_user.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/data/catalogo_service.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/models/catalogo_producto.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/presentation/pages/catalogo_page.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/presentation/pages/product_detail_page.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/widgets/catalogo_widgets.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.user,
    required this.petsService,
    required this.appointmentsService,
    required this.catalogoService,
  });

  final AuthUser user;
  final PetsService petsService;
  final AppointmentsService appointmentsService;
  final CatalogoService catalogoService;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_DashboardSummary> _summaryFuture = _loadSummary();

  bool _autoRetriedAfterError = false;

  Future<_DashboardSummary> _loadSummary() async {
    List<Pet> pets = <Pet>[];
    List<Appointment> appointments = <Appointment>[];
    List<CatalogoProducto> destacados = <CatalogoProducto>[];
    List<CatalogoProducto> novedades = <CatalogoProducto>[];
    List<CatalogoProducto> promociones = <CatalogoProducto>[];

    try {
      pets = await widget.petsService.getPets();
    } catch (_) {
      // Evita que falle todo el dashboard.
    }

    try {
      appointments = await widget.appointmentsService.getAppointments();
    } catch (_) {
      // Evita que falle todo el dashboard.
    }

    try {
      final results = await Future.wait([
        widget.catalogoService.getProductosDestacados(),
        widget.catalogoService.getProductosNovedades(),
        widget.catalogoService.getProductosPromociones(),
      ]);

      destacados = results[0];
      novedades = results[1];
      promociones = results[2];
    } catch (_) {
      // El servicio ya usa mock si el endpoint aun no existe.
    }

    final upcoming = appointments
        .where(
          (appointment) =>
              appointment.status == 'PENDIENTE' ||
              appointment.status == 'CONFIRMADA',
        )
        .length;

    return _DashboardSummary(
      pets: pets.length,
      appointments: appointments.length,
      upcoming: upcoming,
      destacados: destacados,
      novedades: novedades,
      promociones: promociones,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: RefreshIndicator(
          color: petPurple,
          onRefresh: () async {
            setState(() {
              _summaryFuture = _loadSummary();
            });

            try {
              await _summaryFuture;
            } catch (_) {}
          },
          child: FutureBuilder<_DashboardSummary>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              final summary = snapshot.data;

              if (snapshot.hasError && !_autoRetriedAfterError) {
                _autoRetriedAfterError = true;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  setState(() {
                    _summaryFuture = _loadSummary();
                  });
                });
              }

              if (snapshot.hasData) {
                _autoRetriedAfterError = false;
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  _GreetingHeader(user: widget.user),
                  const SizedBox(height: 18),
                  CatalogoBanner(onTap: _openCatalogo),
                  const SizedBox(height: 20),
                  const CatalogoSectionTitle(title: 'Compra por mascota'),
                  const SizedBox(height: 10),
                  _PetTypeAccesses(onOpenCatalogo: _openCatalogo),
                  const SizedBox(height: 20),
                  CatalogoSectionTitle(
                    title: 'Categorias destacadas',
                    actionText: 'Ver todo',
                    onAction: _openCatalogo,
                  ),
                  const SizedBox(height: 8),
                  _FeaturedCategories(onOpenCatalogo: _openCatalogo),
                  const SizedBox(height: 20),
                  _HomeProductRailSection(
                    title: 'Productos destacados',
                    actionText: 'Ver todo',
                    onAction: () => _openCatalogo(destacado: true),
                    products: summary?.destacados ?? const <CatalogoProducto>[],
                    onProductTap: _showProductDetail,
                    emptyTitle: 'Aún no hay productos destacados',
                    emptySubtitle:
                        'Marca productos con destacado para mostrarlos aquí.',
                  ),
                  const SizedBox(height: 18),
                  _HomeProductRailSection(
                    title: 'Novedades',
                    actionText: 'Ver todo',
                    onAction: () => _openCatalogo(novedad: true),
                    products: summary?.novedades ?? const <CatalogoProducto>[],
                    onProductTap: _showProductDetail,
                    emptyTitle: 'Sin novedades por ahora',
                    emptySubtitle:
                        'Las novedades aparecerán aquí cuando tengan fechas activas.',
                    hideWhenEmpty: true,
                  ),
                  const SizedBox(height: 18),
                  _HomeProductRailSection(
                    title: '¡Modo ahorro!',
                    actionText: 'Ver todo',
                    onAction: () => _openCatalogo(promocion: true),
                    products: summary?.promociones ?? const <CatalogoProducto>[],
                    onProductTap: _showProductDetail,
                    emptyTitle: 'Sin ofertas activas',
                    emptySubtitle:
                        'Cuando existan promociones activas, las verás aquí.',
                    hideWhenEmpty: true,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _openCatalogo,
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Ver todo el catalogo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: petOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CatalogoSectionTitle(title: 'Tus opciones'),
                  const SizedBox(height: 10),
                  CatalogSystemCard(
                    title: 'Mascotas',
                    subtitle: '${summary?.pets ?? 0} registradas',
                    icon: Icons.pets_rounded,
                  ),
                  CatalogSystemCard(
                    title: 'Citas proximas',
                    subtitle:
                        '${summary?.upcoming ?? 0} pendientes o confirmadas',
                    icon: Icons.calendar_today_rounded,
                    orange: true,
                  ),
                  CatalogSystemCard(
                    title: 'Historial de reservas',
                    subtitle: '${summary?.appointments ?? 0} reservas en total',
                    icon: Icons.check_circle_rounded,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openCatalogo({
    TipoMascotaCatalogo? tipoMascota,
    String? categoria,
    bool? mostrarGenerales,
    bool destacado = false,
    bool novedad = false,
    bool promocion = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatalogoPage(
          catalogoService: widget.catalogoService,
          initialTipoMascota: tipoMascota,
          initialCategoria: categoria,
          initialMostrarGenerales: mostrarGenerales ?? false,
          initialDestacado: destacado,
          initialNovedad: novedad,
          initialPromocion: promocion,
        ),
      ),
    );
  }

  void _showProductDetail(CatalogoProducto product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final nombre = (user.nombre?.trim().isNotEmpty ?? false)
        ? user.nombre!.trim()
        : user.correo;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3E8FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [petPurpleDark, petPurple, petOrange],
              ),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $nombre',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Encuentra productos y revisa tus servicios PetHome.',
                  style: TextStyle(color: Color(0xFF6B7280), height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetTypeAccesses extends StatelessWidget {
  const _PetTypeAccesses({required this.onOpenCatalogo});

  final void Function({
    TipoMascotaCatalogo? tipoMascota,
    String? categoria,
    bool? mostrarGenerales,
  })
  onOpenCatalogo;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, IconData icon, TipoMascotaCatalogo? tipo})>[
      (
        label: 'Tienda para perros',
        icon: Icons.pets_rounded,
        tipo: TipoMascotaCatalogo.perro,
      ),
      (
        label: 'Tienda para gatos',
        icon: Icons.cruelty_free_rounded,
        tipo: TipoMascotaCatalogo.gato,
      ),
      (
        label: 'Otros productos',
        icon: Icons.auto_awesome_rounded,
        tipo: TipoMascotaCatalogo.otro,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PetTypeAccessCard(
                label: item.label,
                icon: item.icon,
                onTap: () => onOpenCatalogo(tipoMascota: item.tipo),
              ),
            ),
          ),
          PetTypeAccessCard(
            label: 'Productos generales',
            icon: Icons.inventory_2_rounded,
            onTap: () => onOpenCatalogo(mostrarGenerales: true),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCategories extends StatelessWidget {
  const _FeaturedCategories({required this.onOpenCatalogo});

  final void Function({
    TipoMascotaCatalogo? tipoMascota,
    String? categoria,
    bool? mostrarGenerales,
  })
  onOpenCatalogo;

  static const categories = <({String label, IconData icon})>[
    (label: 'Alimentos', icon: Icons.restaurant_rounded),
    (label: 'Premios', icon: Icons.stars_rounded),
    (label: 'Juguetes', icon: Icons.sports_esports_rounded),
    (label: 'Higiene', icon: Icons.spa_rounded),
    (label: 'Accesorios', icon: Icons.shopping_bag_rounded),
    (label: 'Medicamentos', icon: Icons.medication_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return CatalogCategoryChip(
            label: category.label,
            icon: category.icon,
            onTap: () => onOpenCatalogo(categoria: category.label),
          );
        }).toList(),
      ),
    );
  }
}

class _DashboardSummary {
  const _DashboardSummary({
    required this.pets,
    required this.appointments,
    required this.upcoming,
    required this.destacados,
    required this.novedades,
    required this.promociones,
  });

  final int pets;
  final int appointments;
  final int upcoming;
  final List<CatalogoProducto> destacados;
  final List<CatalogoProducto> novedades;
  final List<CatalogoProducto> promociones;
}

class _HomeProductRailSection extends StatelessWidget {
  const _HomeProductRailSection({
    required this.title,
    required this.actionText,
    required this.onAction,
    required this.products,
    required this.onProductTap,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.hideWhenEmpty = false,
  });

  final String title;
  final String actionText;
  final VoidCallback onAction;
  final List<CatalogoProducto> products;
  final ValueChanged<CatalogoProducto> onProductTap;
  final String emptyTitle;
  final String emptySubtitle;
  final bool hideWhenEmpty;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty && hideWhenEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CatalogoSectionTitle(
          title: title,
          actionText: actionText,
          onAction: onAction,
        ),
        const SizedBox(height: 10),
        if (products.isEmpty)
          CatalogSystemCard(
            title: emptyTitle,
            subtitle: emptySubtitle,
            icon: Icons.inventory_2_outlined,
          )
        else
          SizedBox(
            height: 320,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                return CatalogProductCard(
                  product: product,
                  onTap: () => onProductTap(product),
                );
              },
            ),
          ),
      ],
    );
  }
}
