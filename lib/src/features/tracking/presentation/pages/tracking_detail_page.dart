import 'package:flutter/material.dart';

import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:pethome_app/src/features/tracking/data/tracking_service.dart';
import 'package:pethome_app/src/features/tracking/models/tracking_models.dart';
import 'package:pethome_app/src/features/tracking/presentation/controllers/tracking_controller.dart';

enum TrackingDetailType {
  seguimiento,
  pedido,
}

class TrackingDetailPage extends StatefulWidget {
  const TrackingDetailPage.seguimiento({
    super.key,
    required this.authService,
    required this.idSeguimiento,
  })  : idPedido = null,
        type = TrackingDetailType.seguimiento;

  const TrackingDetailPage.pedido({
    super.key,
    required this.authService,
    required this.idPedido,
  })  : idSeguimiento = null,
        type = TrackingDetailType.pedido;

  final AuthService authService;
  final int? idSeguimiento;
  final int? idPedido;
  final TrackingDetailType type;

  @override
  State<TrackingDetailPage> createState() => _TrackingDetailPageState();
}

class _TrackingDetailPageState extends State<TrackingDetailPage> {
  static const _purple = Color(0xFF6A11CB);
  static const _orange = Color(0xFFFF9800);
  static const _softPurple = Color(0xFFF2EAF7);

  late final TrackingService _trackingService = TrackingService(authService: widget.authService);

  bool _isLoading = true;
  String? _errorMessage;
  int? _errorCode;
  SeguimientoItem? _seguimiento;
  PedidoDetail? _pedido;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorCode = null;
      _errorMessage = null;
    });

    try {
      if (widget.type == TrackingDetailType.pedido) {
        _pedido = await _trackingService.getPedidoDetail(widget.idPedido!);
      } else {
        _seguimiento = await _trackingService.getSeguimientoDetail(widget.idSeguimiento!);
      }
    } on ClientException catch (error) {
      _errorCode = error.statusCode;
      _errorMessage = TrackingController.mapDetailErrorMessage(
        statusCode: error.statusCode,
        fallback: error.message,
        resourceName: widget.type == TrackingDetailType.pedido ? 'pedido' : 'seguimiento',
      );
    } on AuthException catch (error) {
      _errorCode = error.statusCode;
      _errorMessage = TrackingController.mapDetailErrorMessage(
        statusCode: error.statusCode,
        fallback: error.message,
        resourceName: widget.type == TrackingDetailType.pedido ? 'pedido' : 'seguimiento',
      );
    } catch (_) {
      _errorCode = 500;
      _errorMessage = 'No se pudo cargar el detalle.';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: const Text('Detalle seguimiento'),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      final is401 = _errorCode == 401;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              if (is401)
                ElevatedButton(
                  onPressed: _goToLogin,
                  child: const Text('Volver al login'),
                )
              else
                OutlinedButton(
                  onPressed: _load,
                  child: const Text('Reintentar'),
                ),
            ],
          ),
        ),
      );
    }

    if (widget.type == TrackingDetailType.pedido && _pedido != null) {
      return _buildPedidoDetail(_pedido!);
    }
    if (widget.type == TrackingDetailType.seguimiento && _seguimiento != null) {
      return _buildSeguimientoDetail(_seguimiento!);
    }

    return const Center(
      child: Text('No se encontro informacion de detalle.'),
    );
  }

  Widget _buildPedidoDetail(PedidoDetail detail) {
    final publicHistory =
        detail.seguimientos.where((item) => item.visibleCliente).toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Pedido #${detail.idPedido}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
              ),
            ),
            _StatusChip(status: detail.estadoPedido),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Actualizado: ${_formatDateTime(detail.fechaActualizacion)}',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _softPurple,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.purple.shade100),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 19,
                backgroundColor: _orange,
                child: Icon(Icons.inventory_2_outlined, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.tipoEntrega == 'DOMICILIO'
                          ? 'Entrega a domicilio'
                          : 'Entrega por recojo',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    const SizedBox(height: 3),
                    Text(detail.direccionEntrega ?? 'Direccion no disponible'),
                    const SizedBox(height: 6),
                    Text(
                      'Total: Bs ${detail.total}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pedido realizado: ${_formatDateTime(detail.fechaPedido)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    _StatusChip(status: detail.tipoEntrega),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Productos',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        ...detail.detalles.map((item) => _buildProductCard(item)),
        if (detail.detalles.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('No hay productos asociados.'),
          ),
        const SizedBox(height: 14),
        const Text(
          'Historial publico',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        _PublicTimeline(items: publicHistory),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            child: const Text('Volver a seguimientos'),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(PedidoDetalleItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: _orange,
              child: Icon(Icons.inventory_2_outlined, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productoNombre,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text('Cantidad: ${item.cantidad} · Bs ${item.precioUnitario} c/u'),
                ],
              ),
            ),
            Text(
              'Bs ${item.subtotal}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeguimientoDetail(SeguimientoItem item) {
    final pedido = item.pedido;
    final cita = item.cita;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _seguimientoTitle(item),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              ),
            ),
            _StatusChip(status: _displaySeguimientoStatus(item)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Actualizado: ${_formatDateTime(item.fechaHora)}',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _softPurple,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.purple.shade100),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _toLabel(item.tipoSeguimiento),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('Fecha/hora: ${_formatDateTime(item.fechaHora)}'),
              if (item.descripcion != null && item.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Descripcion: ${item.descripcion}'),
              ],
              if (cita != null) ...[
                const SizedBox(height: 6),
                Text('Cita: ${cita.fechaProgramada} ${_shortTime(cita.horaInicio)}'),
                Text('Estado cita: ${cita.estado}'),
                Text('Servicio: ${cita.servicio?.nombre ?? 'No disponible'}'),
              ],
              if (pedido != null) ...[
                const SizedBox(height: 6),
                Text('Pedido #${pedido.idPedido}'),
                Text('Entrega: ${_toLabel(pedido.tipoEntrega)}'),
                Text(
                  'Total: Bs ${pedido.total}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            child: const Text('Volver a seguimientos'),
          ),
        ),
      ],
    );
  }

  Future<void> _goToLogin() async {
    await widget.authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage(authService: widget.authService)),
      (route) => false,
    );
  }

  String _seguimientoTitle(SeguimientoItem item) {
    if (item.tipoSeguimiento == 'PEDIDO' && item.pedido != null) {
      return 'Pedido #${item.pedido!.idPedido}';
    }
    if (item.cita?.servicio?.nombre != null && item.cita!.servicio!.nombre.isNotEmpty) {
      return item.cita!.servicio!.nombre;
    }
    return _toLabel(item.tipoSeguimiento);
  }

  String _displaySeguimientoStatus(SeguimientoItem item) {
    final citaEstado = item.cita?.estado.trim();
    if (citaEstado != null && citaEstado.isNotEmpty) {
      return citaEstado;
    }
    return item.estadoActual;
  }
}

class _PublicTimeline extends StatelessWidget {
  const _PublicTimeline({required this.items});

  final List<PedidoSeguimientoItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('No hay historial publico disponible.'),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: List<Widget>.generate(items.length, (index) {
            final item = items[index];
            final isLast = index == items.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: index == 0 ? const Color(0xFFFF9800) : const Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _toLabel(item.estadoActual),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            _formatDateTime(item.fechaHora),
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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
    } else if (normalized == 'DOMICILIO' || normalized == 'RECOJO') {
      color = const Color(0xFFECECEC);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        normalized,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
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

String _shortTime(String raw) {
  if (raw.length >= 5) return raw.substring(0, 5);
  return raw;
}

String _toLabel(String value) {
  final normalized = value.trim().toUpperCase();
  switch (normalized) {
    case 'DOMICILIO':
      return 'Domicilio';
    case 'RECOJO':
      return 'Recojo';
    case 'PEDIDO':
      return 'Pedido';
    case 'SERVICIO':
      return 'Servicio';
    case 'CITA':
      return 'Cita';
    case 'RUTA':
      return 'Ruta';
    default:
      return normalized.replaceAll('_', ' ');
  }
}
