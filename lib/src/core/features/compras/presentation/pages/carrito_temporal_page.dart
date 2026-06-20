import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pethome_app/src/core/features/compras/presentation/widgets/carrito_item_card.dart';
import 'package:pethome_app/src/core/features/compras/presentation/widgets/carrito_total_card.dart';
import 'package:pethome_app/src/core/features/compras/presentation/widgets/empty_cart_widget.dart';
import 'package:pethome_app/src/core/features/compras/providers/carrito_provider.dart';
import 'package:pethome_app/src/core/widgets/notification_bell.dart';
import 'package:pethome_app/src/core/features/compras/presentation/pages/checkout_page.dart';
import 'package:pethome_app/src/features/appointments/presentation/pages/citas_page.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';

class CarritoTemporalPage extends StatelessWidget {
  const CarritoTemporalPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CarritoProvider>(context, listen: false).loadCarrito();
    });
    return const _CarritoTemporalView();
  }
}

class _CarritoTemporalView extends StatelessWidget {
  const _CarritoTemporalView();

  @override
  Widget build(BuildContext context) {
    return Consumer<CarritoProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F4F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF4F4F5),
            elevation: 0,
            title: const Text(
              'PetHome',
              style: TextStyle(
                color: Color(0xFF6A11CB),
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: const [NotificationBell(), SizedBox(width: 8)],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFF6D28D9),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: const Text(
                  'Carrito temporal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF6D28D9),
                  onRefresh: provider.loadCarrito,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      Wrap(
                        runSpacing: 12,
                        spacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const SizedBox(
                            width: 230,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mi carrito',
                                  style: TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 35 / 2,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Productos, servicios y citas pendientes de pago',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: provider.isLoading ? null : provider.loadCarrito,
                            icon: provider.isLoading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded),
                            label: const Text('Actualizar'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0E7FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${provider.carrito.cantidadItems} items',
                              style: const TextStyle(
                                color: Color(0xFF6D28D9),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'El carrito guarda productos y servicios. Las citas pendientes tambien se pueden pagar aqui.',
                            style: TextStyle(color: Color(0xFF4B5563)),
                          ),
                        ],
                      ),
                      if (provider.isLoadingAppointments)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: LinearProgressIndicator(color: Color(0xFF6D28D9)),
                        )
                      else if (provider.pendingAppointments.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Citas pendientes de pago',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 25 / 2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...provider.pendingAppointments.map(
                          (appointment) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE9D5FF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF0E7FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.event_available_rounded,
                                        color: Color(0xFF6D28D9),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appointment.serviceName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${appointment.petName} · ${appointment.date} · ${appointment.time}',
                                            style: const TextStyle(
                                              color: Color(0xFF6B7280),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            appointment.modality,
                                            style: const TextStyle(
                                              color: Color(0xFF6D28D9),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if ((appointment.address ?? '').isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              appointment.address!,
                                              style: const TextStyle(
                                                color: Color(0xFF4B5563),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  runSpacing: 10,
                                  spacing: 10,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Bs. ${double.tryParse(appointment.price)?.toStringAsFixed(2) ?? appointment.price}',
                                      style: const TextStyle(
                                        color: Color(0xFF6D28D9),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    FilledButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => CheckoutPage(
                                              mode: CheckoutMode.CITA_SERVICIO,
                                              citaData: {
                                                'id': appointment.id,
                                                'petId': appointment.petId,
                                                'serviceId': appointment.serviceId,
                                                'priceId': appointment.priceId,
                                                'serviceName': appointment.serviceName,
                                                'petName': appointment.petName,
                                                'date': appointment.date,
                                                'time': appointment.time,
                                                'modality': appointment.modality,
                                                'address': appointment.address,
                                                'description': appointment.description,
                                                'price': appointment.price,
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.payment_rounded),
                                      label: const Text('Pagar cita'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF6D28D9),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Text(
                            'Items en el carrito',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 25 / 2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _openSolicitarCita(context, provider),
                            icon: const Icon(Icons.add_box_outlined),
                            label: const Text('Agregar cita'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (provider.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            provider.errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      if (provider.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (provider.carrito.detalles.isEmpty)
                        const EmptyCartWidget()
                      else
                        ...provider.carrito.detalles.map(
                          (item) => CarritoItemCard(
                            item: item,
                            enabled: !provider.isUpdatingCantidad &&
                                !provider.isRemovingItem &&
                                !provider.isClearing,
                            onIncrement: () => _onChangeQuantity(
                              context,
                              provider,
                              item.idDetalleCarrito,
                              item.cantidad + 1,
                            ),
                            onDecrement: () {
                              if (item.cantidad <= 1) {
                                _onDeleteItem(context, provider, item.idDetalleCarrito);
                                return;
                              }
                              _onChangeQuantity(
                                context,
                                provider,
                                item.idDetalleCarrito,
                                item.cantidad - 1,
                              );
                            },
                            onDelete: () => _onDeleteItem(
                              context,
                              provider,
                              item.idDetalleCarrito,
                            ),
                          ),
                        ),
                      CarritoTotalCard(
                        subtotalEstimado: provider.carrito.subtotalEstimado,
                        totalEstimado: provider.carrito.totalEstimado,
                      ),
                      if (provider.carrito.detalles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              print('[Checkout] Tap en Realizar Pedido');
                              print('[Checkout] Navegando a CheckoutPage');
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CheckoutPage(mode: CheckoutMode.PEDIDO_MOVIL),
                                ),
                              );
                            },
                            icon: const Icon(Icons.payment_rounded),
                            label: const Text('Realizar Pedido'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6D28D9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: provider.isClearing
                                  ? null
                                  : () => _onClearCart(context, provider),
                              icon: provider.isClearing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.delete_sweep_outlined),
                              label: const Text('Vaciar carrito'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6D28D9),
                                side: const BorderSide(color: Color(0xFF6D28D9)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.explore_outlined),
                              label: const Text('Seguir explorando'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSolicitarCita(
    BuildContext context,
    CarritoProvider provider,
  ) async {
    final authService = AuthService();

    try {
      final session = await authService.getSession();
      if (!context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CitasPage(
            petsService: provider.petsService,
            appointmentsService: provider.appointmentsService,
            permissions: session.permissions,
          ),
        ),
      );

      if (!context.mounted) return;
      await provider.loadCarrito();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la pantalla de citas.')),
      );
    }
  }

  Future<void> _onChangeQuantity(
    BuildContext context,
    CarritoProvider provider,
    int detailId,
    double newQuantity,
  ) async {
    final ok = await provider.updateCantidad(
      detalleId: detailId,
      cantidad: newQuantity % 1 == 0
          ? newQuantity.toInt().toString()
          : newQuantity.toStringAsFixed(2),
    );
    if (!context.mounted || ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.errorMessage ?? 'No se pudo actualizar la cantidad.')),
    );
  }

  Future<void> _onDeleteItem(
    BuildContext context,
    CarritoProvider provider,
    int detailId,
  ) async {
    final ok = await provider.removeItem(detalleId: detailId);
    if (!context.mounted || ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.errorMessage ?? 'No se pudo eliminar el item.')),
    );
  }

  Future<void> _onClearCart(
    BuildContext context,
    CarritoProvider provider,
  ) async {
    final ok = await provider.clearCarrito();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Carrito vaciado.' : (provider.errorMessage ?? 'No se pudo vaciar el carrito.')),
      ),
    );
  }
}
