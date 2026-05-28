import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/features/compras/presentation/pages/carrito_temporal_page.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/data/catalogo_service.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/models/catalogo_producto.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/presentation/pages/product_detail_page.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/widgets/catalogo_widgets.dart';

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({
    super.key,
    required this.catalogoService,
    this.initialTipoMascota,
    this.initialCategoria,
    this.initialMostrarGenerales = false,
    this.initialDestacado = false,
    this.initialNovedad = false,
    this.initialPromocion = false,
  });

  final CatalogoService catalogoService;
  final TipoMascotaCatalogo? initialTipoMascota;
  final String? initialCategoria;
  final bool initialMostrarGenerales;
  final bool initialDestacado;
  final bool initialNovedad;
  final bool initialPromocion;

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  late Future<List<CatalogoProducto>> _productosFuture = widget.catalogoService
      .getProductosCatalogo();

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _categoria;
  TipoMascotaCatalogo? _tipoMascota;
  bool _mostrarGenerales = false;
  bool _soloDestacados = false;
  bool _soloNovedades = false;
  bool _soloPromociones = false;

  @override
  void initState() {
    super.initState();
    _categoria = widget.initialCategoria;
    _tipoMascota = widget.initialTipoMascota;
    _mostrarGenerales = widget.initialMostrarGenerales;
    _soloDestacados = widget.initialDestacado;
    _soloNovedades = widget.initialNovedad;
    _soloPromociones = widget.initialPromocion;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _productosFuture = widget.catalogoService.getProductosCatalogo();
    });
    await _productosFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: petPurple,
        title: const Text(
          'Catalogo PetHome',
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
        child: RefreshIndicator(
          color: petPurple,
          onRefresh: _refresh,
          child: FutureBuilder<List<CatalogoProducto>>(
            future: _productosFuture,
            builder: (context, snapshot) {
              final productos = snapshot.data ?? const <CatalogoProducto>[];
              final filtrados = _filtrar(productos);

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SearchBox(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() => _query = value.trim());
                            },
                          ),
                          const SizedBox(height: 16),
                          _SpecialFilters(
                            selectedDestacados: _soloDestacados,
                            selectedNovedades: _soloNovedades,
                            selectedPromociones: _soloPromociones,
                            onAll: () {
                              setState(() {
                                _soloDestacados = false;
                                _soloNovedades = false;
                                _soloPromociones = false;
                              });
                            },
                            onDestacados: () {
                              setState(() {
                                _soloDestacados = true;
                                _soloNovedades = false;
                                _soloPromociones = false;
                              });
                            },
                            onNovedades: () {
                              setState(() {
                                _soloDestacados = false;
                                _soloNovedades = true;
                                _soloPromociones = false;
                              });
                            },
                            onPromociones: () {
                              setState(() {
                                _soloDestacados = false;
                                _soloNovedades = false;
                                _soloPromociones = true;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          _PetTypeFilters(
                            selected: _tipoMascota,
                            showGeneral: _mostrarGenerales,
                            onAll: () {
                              setState(() {
                                _tipoMascota = null;
                                _mostrarGenerales = false;
                              });
                            },
                            onGeneral: () {
                              setState(() {
                                _tipoMascota = null;
                                _mostrarGenerales = true;
                              });
                            },
                            onType: (tipo) {
                              setState(() {
                                _tipoMascota = tipo;
                                _mostrarGenerales = false;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          _CategoryFilters(
                            selected: _categoria,
                            onSelected: (categoria) {
                              setState(() => _categoria = categoria);
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${filtrados.length} productos disponibles',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (filtrados.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyCatalog(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      sliver: SliverGrid.builder(
                        itemCount: filtrados.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 230,
                              mainAxisExtent: 300,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                        itemBuilder: (context, index) {
                          final product = filtrados[index];
                          return CatalogProductCard(
                            product: product,
                            compact: true,
                            onTap: () => _showProductDetail(product),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<CatalogoProducto> _filtrar(List<CatalogoProducto> productos) {
    final query = _query.toLowerCase();

    return productos.where((producto) {
      if (_soloDestacados && !producto.destacado) {
        return false;
      }

      if (_soloNovedades && !producto.esNovedadActiva) {
        return false;
      }

      if (_soloPromociones && !producto.tienePromocionActiva) {
        return false;
      }

      if (_categoria != null && !_matchesCategoria(producto.categoria, _categoria!)) {
        return false;
      }

      if (_mostrarGenerales && producto.tipoMascota != null) {
        return false;
      }

      if (!_mostrarGenerales &&
          _tipoMascota != null &&
          producto.tipoMascota != _tipoMascota) {
        return false;
      }

      if (query.isEmpty) return true;

      final contenido = [
        producto.nombre,
        producto.descripcion,
        producto.categoria,
        producto.proveedor ?? '',
        tipoMascotaLabel(producto.tipoMascota),
      ].join(' ').toLowerCase();

      return contenido.contains(query);
    }).toList();
  }

  bool _matchesCategoria(String productoCategoria, String filtroCategoria) {
    final normalizedProducto = _normalizeText(productoCategoria);
    final normalizedFiltro = _normalizeText(filtroCategoria);

    if (normalizedProducto == normalizedFiltro) {
      return true;
    }

    final aliases = _categoryAliases[normalizedFiltro] ?? const <String>[];
    for (final alias in aliases) {
      if (normalizedProducto.contains(alias)) {
        return true;
      }
    }

    return normalizedProducto.contains(normalizedFiltro);
  }

  void _showProductDetail(CatalogoProducto product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
    );
  }

  static const Map<String, List<String>> _categoryAliases = {
    'alimentos': ['alimentos'],
    'premios': ['premios', 'snacks', 'snack'],
    'juguetes': ['juguetes'],
    'higiene': ['higiene', 'limpieza'],
    'accesorios': ['accesorios'],
    'medicamentos': ['medicamentos', 'medicina', 'farmacia'],
  };

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar alimentos, juguetes, accesorios...',
        prefixIcon: const Icon(Icons.search_rounded, color: petPurple),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFE9D5FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: petPurple, width: 1.4),
        ),
      ),
    );
  }
}

class _SpecialFilters extends StatelessWidget {
  const _SpecialFilters({
    required this.selectedDestacados,
    required this.selectedNovedades,
    required this.selectedPromociones,
    required this.onAll,
    required this.onDestacados,
    required this.onNovedades,
    required this.onPromociones,
  });

  final bool selectedDestacados;
  final bool selectedNovedades;
  final bool selectedPromociones;
  final VoidCallback onAll;
  final VoidCallback onDestacados;
  final VoidCallback onNovedades;
  final VoidCallback onPromociones;

  @override
  Widget build(BuildContext context) {
    final allSelected =
        !selectedDestacados && !selectedNovedades && !selectedPromociones;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CatalogCategoryChip(
            label: 'Todo',
            icon: Icons.apps_rounded,
            selected: allSelected,
            onTap: onAll,
          ),
          CatalogCategoryChip(
            label: 'Destacados',
            icon: Icons.star_rounded,
            selected: selectedDestacados,
            onTap: onDestacados,
          ),
          CatalogCategoryChip(
            label: 'Novedades',
            icon: Icons.auto_awesome_rounded,
            selected: selectedNovedades,
            onTap: onNovedades,
          ),
          CatalogCategoryChip(
            label: 'Ofertas',
            icon: Icons.local_offer_rounded,
            selected: selectedPromociones,
            onTap: onPromociones,
          ),
        ],
      ),
    );
  }
}

class _PetTypeFilters extends StatelessWidget {
  const _PetTypeFilters({
    required this.selected,
    required this.showGeneral,
    required this.onAll,
    required this.onGeneral,
    required this.onType,
  });

  final TipoMascotaCatalogo? selected;
  final bool showGeneral;
  final VoidCallback onAll;
  final VoidCallback onGeneral;
  final ValueChanged<TipoMascotaCatalogo> onType;

  @override
  Widget build(BuildContext context) {
    final filters = <_FilterItem>[
      _FilterItem(
        'Todos',
        Icons.apps_rounded,
        onAll,
        selected == null && !showGeneral,
      ),
      _FilterItem(
        'Perros',
        Icons.pets_rounded,
        () => onType(TipoMascotaCatalogo.perro),
        selected == TipoMascotaCatalogo.perro,
      ),
      _FilterItem(
        'Gatos',
        Icons.cruelty_free_rounded,
        () => onType(TipoMascotaCatalogo.gato),
        selected == TipoMascotaCatalogo.gato,
      ),
      _FilterItem(
        'Aves',
        Icons.flutter_dash_rounded,
        () => onType(TipoMascotaCatalogo.ave),
        selected == TipoMascotaCatalogo.ave,
      ),
      _FilterItem(
        'Roedores',
        Icons.pets_rounded,
        () => onType(TipoMascotaCatalogo.roedor),
        selected == TipoMascotaCatalogo.roedor,
      ),
      _FilterItem(
        'Peces',
        Icons.water_drop_rounded,
        () => onType(TipoMascotaCatalogo.pez),
        selected == TipoMascotaCatalogo.pez,
      ),
      _FilterItem(
        'Generales',
        Icons.inventory_2_rounded,
        onGeneral,
        showGeneral,
      ),
      _FilterItem(
        'Otros',
        Icons.auto_awesome_rounded,
        () => onType(TipoMascotaCatalogo.otro),
        selected == TipoMascotaCatalogo.otro,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: PetTypeAccessCard(
                  label: item.label,
                  icon: item.icon,
                  selected: item.selected,
                  onTap: item.onTap,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  static const _categories = <({String label, IconData icon})>[
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
        children: [
          CatalogCategoryChip(
            label: 'Todas',
            icon: Icons.tune_rounded,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          ..._categories.map(
            (category) => CatalogCategoryChip(
              label: category.label,
              icon: category.icon,
              selected: selected == category.label,
              onTap: () => onSelected(category.label),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: petPurple,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No hay productos para estos filtros',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Prueba otra categoria, tipo de mascota o busqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterItem {
  const _FilterItem(this.label, this.icon, this.onTap, this.selected);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
}
