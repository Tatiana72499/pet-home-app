import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:pethome_app/src/features/tracking/data/tracking_service.dart';
import 'package:pethome_app/src/features/tracking/models/tracking_models.dart';
import 'package:pethome_app/src/features/tracking/presentation/controllers/tracking_controller.dart';
import 'package:pethome_app/src/features/tracking/presentation/pages/tracking_detail_page.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({
    super.key,
    required this.authService,
    required this.roleNombre,
    this.trackingService,
  });

  final AuthService authService;
  final String roleNombre;
  final TrackingService? trackingService;

  static const String routeName = '/tracking';

  bool get _isSuperAdmin => roleNombre.trim().toUpperCase() == 'SUPERADMIN';

  @override
  Widget build(BuildContext context) {
    if (_isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Seguimiento'),
          backgroundColor: const Color(0xFF6A11CB),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Sin permisos para acceder a este modulo.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => TrackingController(
        service: trackingService ?? TrackingService(authService: authService),
      )..loadInitial(),
      child: _TrackingPageView(authService: authService),
    );
  }
}

class _TrackingPageView extends StatefulWidget {
  const _TrackingPageView({required this.authService});

  final AuthService authService;

  @override
  State<_TrackingPageView> createState() => _TrackingPageViewState();
}

class _TrackingPageViewState extends State<_TrackingPageView> {
  static const _purple = Color(0xFF6A11CB);
  //static const _softPurple = Color(0xFFF2EAF7);
  static const _orange = Color(0xFFFF9800);

  Future<void> _openFiltersSheet({
    required TrackingController controller,
    required bool isSeguimientos,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: _FilterCard(
                isSeguimientos: isSeguimientos,
                search: controller.search,
                onSearchChanged: controller.setSearch,
                seguimientoTipo: controller.seguimientoTipo,
                seguimientoEstado: controller.seguimientoEstado,
                onSeguimientoTipoChanged: controller.setSeguimientoTipo,
                onSeguimientoEstadoChanged: controller.setSeguimientoEstado,
                pedidoEstado: controller.pedidoEstado,
                pedidoTipoEntrega: controller.pedidoTipoEntrega,
                onPedidoEstadoChanged: controller.setPedidoEstado,
                onPedidoTipoEntregaChanged: controller.setPedidoTipoEntrega,
                seguimientoFechaDesde: controller.seguimientoFechaDesde,
                seguimientoFechaHasta: controller.seguimientoFechaHasta,
                pedidoFechaDesde: controller.pedidoFechaDesde,
                pedidoFechaHasta: controller.pedidoFechaHasta,
                onSeguimientoFechaDesdeChanged: controller.setSeguimientoDesde,
                onSeguimientoFechaHastaChanged: controller.setSeguimientoHasta,
                onPedidoFechaDesdeChanged: controller.setPedidoDesde,
                onPedidoFechaHastaChanged: controller.setPedidoHasta,
                onApply: () {
                  if (isSeguimientos) {
                    controller.applySeguimientosFilters();
                  } else {
                    controller.applyPedidosFilters();
                  }
                  Navigator.of(context).pop();
                },
                onClear: () {
                  if (isSeguimientos) {
                    controller.clearSeguimientosFilters();
                  } else {
                    controller.clearPedidosFilters();
                  }
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingController>(
      builder: (context, controller, _) {
        final isSeguimientos =
            controller.section == TrackingSection.seguimientos;
        final errorMessage = controller.currentError;
        final errorCode = controller.currentErrorCode;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F3F3),
          appBar: AppBar(
            title: const Text('Seguimiento'),
            backgroundColor: _purple,
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mis seguimientos',
                              style: TextStyle(
                                fontSize: 35,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Citas, servicios y pedidos en proceso',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: controller.isLoadingCurrent
                            ? null
                            : controller.refreshCurrent,
                        style: FilledButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text(
                          'Actualizar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionToggle(
                    value: controller.section,
                    onChanged: controller.setSection,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _openFiltersSheet(
                      controller: controller,
                      isSeguimientos: isSeguimientos,
                    ),
                    icon: const Icon(Icons.tune),
                    label: const Text('Filtros'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _purple,
                      side: const BorderSide(color: _purple),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSeguimientos
                        ? 'Seguimientos recientes'
                        : 'Pedidos recientes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildCurrentList(
                      context: context,
                      controller: controller,
                      isSeguimientos: isSeguimientos,
                      errorMessage: errorMessage,
                      errorCode: errorCode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentList({
    required BuildContext context,
    required TrackingController controller,
    required bool isSeguimientos,
    required String? errorMessage,
    required int? errorCode,
  }) {
    if (controller.isLoadingCurrent && !controller.loadedAtLeastOnce) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.isLoadingCurrent &&
        (isSeguimientos
            ? controller.seguimientosVisible.isNotEmpty
            : controller.pedidosVisible.isNotEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && errorMessage.isNotEmpty) {
      return _ErrorState(
        message: errorMessage,
        statusCode: errorCode,
        onRetry: controller.refreshCurrent,
        onLogin: () => _goToLogin(context),
      );
    }

    if (isSeguimientos) {
      final items = controller.seguimientosVisible;
      if (items.isEmpty) {
        return const _EmptyState(
          text: 'No hay seguimientos para los filtros seleccionados.',
        );
      }
      return RefreshIndicator(
        onRefresh: controller.refreshSeguimientos,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 90),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _SeguimientoCard(
              item: item,
              onTap: () => _openSeguimientoDetalle(context, item),
            );
          },
        ),
      );
    }

    final orders = controller.pedidosVisible;
    if (orders.isEmpty) {
      return const _EmptyState(
        text: 'No hay pedidos para los filtros seleccionados.',
      );
    }
    return RefreshIndicator(
      onRefresh: controller.refreshPedidos,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final item = orders[index];
          return _PedidoCard(
            item: item,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrackingDetailPage.pedido(
                    authService: widget.authService,
                    idPedido: item.idPedido,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openSeguimientoDetalle(BuildContext context, SeguimientoItem item) {
    if (item.tipoSeguimiento == 'PEDIDO' && item.pedido != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrackingDetailPage.pedido(
            authService: widget.authService,
            idPedido: item.pedido!.idPedido,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackingDetailPage.seguimiento(
          authService: widget.authService,
          idSeguimiento: item.idSeguimiento,
        ),
      ),
    );
  }

  Future<void> _goToLogin(BuildContext context) async {
    await widget.authService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage(authService: widget.authService)),
      (route) => false,
    );
  }
}

class _SectionToggle extends StatelessWidget {
  const _SectionToggle({required this.value, required this.onChanged});

  final TrackingSection value;
  final ValueChanged<TrackingSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              selected: value == TrackingSection.seguimientos,
              label: 'Seguimientos',
              onTap: () => onChanged(TrackingSection.seguimientos),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ToggleButton(
              selected: value == TrackingSection.pedidos,
              label: 'Pedidos',
              onTap: () => onChanged(TrackingSection.pedidos),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6A11CB) : const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.isSeguimientos,
    required this.search,
    required this.onSearchChanged,
    required this.seguimientoTipo,
    required this.seguimientoEstado,
    required this.onSeguimientoTipoChanged,
    required this.onSeguimientoEstadoChanged,
    required this.pedidoEstado,
    required this.pedidoTipoEntrega,
    required this.onPedidoEstadoChanged,
    required this.onPedidoTipoEntregaChanged,
    required this.seguimientoFechaDesde,
    required this.seguimientoFechaHasta,
    required this.pedidoFechaDesde,
    required this.pedidoFechaHasta,
    required this.onSeguimientoFechaDesdeChanged,
    required this.onSeguimientoFechaHastaChanged,
    required this.onPedidoFechaDesdeChanged,
    required this.onPedidoFechaHastaChanged,
    required this.onApply,
    required this.onClear,
  });

  final bool isSeguimientos;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final String? seguimientoTipo;
  final String? seguimientoEstado;
  final ValueChanged<String?> onSeguimientoTipoChanged;
  final ValueChanged<String?> onSeguimientoEstadoChanged;
  final String? pedidoEstado;
  final String? pedidoTipoEntrega;
  final ValueChanged<String?> onPedidoEstadoChanged;
  final ValueChanged<String?> onPedidoTipoEntregaChanged;
  final DateTime? seguimientoFechaDesde;
  final DateTime? seguimientoFechaHasta;
  final DateTime? pedidoFechaDesde;
  final DateTime? pedidoFechaHasta;
  final ValueChanged<DateTime?> onSeguimientoFechaDesdeChanged;
  final ValueChanged<DateTime?> onSeguimientoFechaHastaChanged;
  final ValueChanged<DateTime?> onPedidoFechaDesdeChanged;
  final ValueChanged<DateTime?> onPedidoFechaHastaChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  static const _purple = Color(0xFF6A11CB);

  @override
  Widget build(BuildContext context) {
    final desde = isSeguimientos ? seguimientoFechaDesde : pedidoFechaDesde;
    final hasta = isSeguimientos ? seguimientoFechaHasta : pedidoFechaHasta;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          TextFormField(
            key: ValueKey('tracking_search_${isSeguimientos}_$search'),
            onChanged: onSearchChanged,
            initialValue: search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Buscar',
              fillColor: const Color(0xFFF1F1F1),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: isSeguimientos ? 'Tipo' : 'Estado',
                  value: isSeguimientos ? seguimientoTipo : pedidoEstado,
                  options: isSeguimientos
                      ? const <String>['CITA', 'SERVICIO', 'PEDIDO', 'RUTA']
                      : const <String>[
                          'PENDIENTE',
                          'CONFIRMADO',
                          'EN_PREPARACION',
                          'EN_CAMINO',
                          'ENTREGADO',
                          'CANCELADO',
                        ],
                  onChanged: isSeguimientos
                      ? onSeguimientoTipoChanged
                      : onPedidoEstadoChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterDropdown(
                  label: isSeguimientos ? 'Estado' : 'Entrega',
                  value: isSeguimientos ? seguimientoEstado : pedidoTipoEntrega,
                  options: isSeguimientos
                      ? const <String>[
                          'PENDIENTE',
                          'CONFIRMADA',
                          'EN_CAMINO',
                          'COMPLETADA',
                          'CANCELADA',
                          'EN_PREPARACION',
                          'ENTREGADO',
                        ]
                      : const <String>['DOMICILIO', 'RECOJO'],
                  onChanged: isSeguimientos
                      ? onSeguimientoEstadoChanged
                      : onPedidoTipoEntregaChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await _pickDate(context, initialDate: desde);
                    if (isSeguimientos) {
                      onSeguimientoFechaDesdeChanged(picked);
                    } else {
                      onPedidoFechaDesdeChanged(picked);
                    }
                  },
                  child: Text(_formatDateLabel('Desde', desde)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await _pickDate(context, initialDate: hasta);
                    if (isSeguimientos) {
                      onSeguimientoFechaHastaChanged(picked);
                    } else {
                      onPedidoFechaHastaChanged(picked);
                    }
                  },
                  child: Text(_formatDateLabel('Hasta', hasta)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(backgroundColor: _purple),
                  child: const Text('Aplicar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Limpiar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('tracking_${label}_${value ?? 'all'}'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        fillColor: const Color(0xFFF1F1F1),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
      ),
      items: <DropdownMenuItem<String>>[
        const DropdownMenuItem<String>(value: null, child: Text('Todos')),
        ...options.map(
          (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SeguimientoCard extends StatelessWidget {
  const _SeguimientoCard({required this.item, required this.onTap});

  final SeguimientoItem item;
  final VoidCallback onTap;

  static const _softPurple = Color(0xFFF2EAF7);
  static const _orange = Color(0xFFFF9800);
  static const _purple = Color(0xFF6A11CB);

  @override
  Widget build(BuildContext context) {
    final title = _titleFromSeguimiento(item);
    final subtitle = _subtitleFromSeguimiento(item);
    final amountLabel = item.pedido == null ? null : 'Bs ${item.pedido!.total}';
    final status = _displayStatus(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: _softPurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.purple.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _orange,
                child: Icon(
                  _iconForType(item.tipoSeguimiento),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      _secondaryRow(item, amountLabel),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    _StatusChip(status: status),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _purple),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'PEDIDO':
        return Icons.inventory_2_outlined;
      case 'CITA':
        return Icons.calendar_today;
      case 'SERVICIO':
      case 'RUTA':
        return Icons.route;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  String _titleFromSeguimiento(SeguimientoItem item) {
    if (item.tipoSeguimiento == 'PEDIDO' && item.pedido != null) {
      return 'Pedido #${item.pedido!.idPedido}';
    }
    if (item.cita?.servicio?.nombre != null &&
        item.cita!.servicio!.nombre.isNotEmpty) {
      return item.cita!.servicio!.nombre;
    }
    return _toLabel(item.tipoSeguimiento);
  }

  String _subtitleFromSeguimiento(SeguimientoItem item) {
    final date = _formatDateTime(item.fechaHora);
    if (item.descripcion != null && item.descripcion!.isNotEmpty) {
      return item.descripcion!;
    }
    return date;
  }

  String _secondaryRow(SeguimientoItem item, String? amountLabel) {
    final left = <String>[
      _toLabel(item.tipoSeguimiento),
      if (item.pedido != null) _toLabel(item.pedido!.tipoEntrega),
    ].join(' · ');
    if (amountLabel == null) return left;
    return '$left · $amountLabel';
  }

  String _displayStatus(SeguimientoItem item) {
    final citaEstado = item.cita?.estado.trim();
    if (citaEstado != null && citaEstado.isNotEmpty) {
      return citaEstado;
    }
    return item.estadoActual;
  }
}

class _PedidoCard extends StatelessWidget {
  const _PedidoCard({required this.item, required this.onTap});

  final PedidoListItem item;
  final VoidCallback onTap;

  static const _softPurple = Color(0xFFF2EAF7);
  static const _orange = Color(0xFFFF9800);
  static const _purple = Color(0xFF6A11CB);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: _softPurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.purple.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: _orange,
                child: Icon(Icons.inventory_2_outlined, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #${item.idPedido}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(item.estadoPedido),
                    const SizedBox(height: 2),
                    Text(
                      '${_toLabel(item.tipoEntrega)} · Bs ${item.total}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if ((item.estadoPago ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Pago: ${_toLabel(item.estadoPago!)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _StatusChip(status: item.estadoPedido),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _purple),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();
    Color color = Colors.grey.shade300;
    if (normalized == 'CONFIRMADA' ||
        normalized == 'CONFIRMADO' ||
        normalized == 'ENTREGADO') {
      color = const Color(0xFFD8F2DA);
    } else if (normalized == 'PENDIENTE') {
      color = const Color(0xFFFFF1D7);
    } else if (normalized == 'EN_PREPARACION' || normalized == 'EN_CAMINO') {
      color = const Color(0xFFE9E2F9);
    } else if (normalized == 'CANCELADO') {
      color = const Color(0xFFFFE3E3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        normalized,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.statusCode,
    required this.onRetry,
    required this.onLogin,
  });

  final String message;
  final int? statusCode;
  final VoidCallback onRetry;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final is401 = statusCode == 401;
    final is403 = statusCode == 403;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              is401
                  ? Icons.lock_clock_outlined
                  : is403
                  ? Icons.gpp_bad_outlined
                  : Icons.wifi_tethering_error_rounded,
              size: 36,
              color: Colors.black54,
            ),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (is401)
              ElevatedButton(
                onPressed: onLogin,
                child: const Text('Volver al login'),
              )
            else
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
          ],
        ),
      ),
    );
  }
}

Future<DateTime?> _pickDate(
  BuildContext context, {
  required DateTime? initialDate,
}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initialDate ?? now,
    firstDate: DateTime(2020, 1, 1),
    lastDate: DateTime(2100, 12, 31),
  );
}

String _formatDateLabel(String prefix, DateTime? value) {
  if (value == null) return prefix;
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$prefix $year-$month-$day';
}

String _formatDateTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final local = parsed.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

String _toLabel(String value) {
  final normalized = value.trim().toUpperCase();
  switch (normalized) {
    case 'DOMICILIO':
      return 'Domicilio';
    case 'RECOJO':
      return 'Recojo';
    case 'CITA':
      return 'Cita';
    case 'SERVICIO':
      return 'Servicio';
    case 'PEDIDO':
      return 'Pedido';
    case 'RUTA':
      return 'Ruta';
    default:
      return normalized.replaceAll('_', ' ');
  }
}
