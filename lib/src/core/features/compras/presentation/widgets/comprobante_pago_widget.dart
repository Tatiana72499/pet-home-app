import 'package:flutter/material.dart';

class ComprobantePagoWidget extends StatelessWidget {
  const ComprobantePagoWidget({
    super.key,
    required this.comprobante,
  });

  final Map<String, dynamic> comprobante;

  @override
  Widget build(BuildContext context) {
    final tipo = comprobante['tipo_comprobante'] ?? 'RECIBO';
    final numero = comprobante['numero_comprobante'] ?? '';
    final montoStr = comprobante['monto'] ?? '0.00';
    final metodo = (comprobante['metodo_pago'] ?? '').toString().toUpperCase();
    final fechaRaw = comprobante['fecha_emision'] ?? '';
    final estado = comprobante['estado'] ?? 'EMITIDO';

    DateTime? fecha;
    if (fechaRaw.isNotEmpty) {
      try {
        fecha = DateTime.parse(fechaRaw).toLocal();
      } catch (_) {}
    }

    final detallesMap = comprobante['detalle_items'] as Map<String, dynamic>?;
    final List<dynamic> items = (detallesMap != null ? detallesMap['items'] : null) ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo/Encabezado
          const Center(
            child: Column(
              children: [
                Text(
                  'PET HOME',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cuidado y Amor para tu Mascota',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE4E4E7), height: 1, thickness: 1),
          const SizedBox(height: 14),

          // Badge de tipo y número de comprobante
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '$tipo · $numero',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metadatos
          _buildRowDetail('Fecha Emisión', fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}' : '-'),
          _buildRowDetail('Método de Pago', metodo),
          _buildRowDetail(
            'Estado',
            estado,
            valueColor: estado == 'EMITIDO' ? const Color(0xFF10B981) : Colors.redAccent,
            valueFontWeight: FontWeight.bold,
          ),
          _buildRowDetail('ID Pago', '#${comprobante['id_pago'] ?? '-'}'),
          const SizedBox(height: 16),

          const Text(
            'DETALLE DE COMPRA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF71717A),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          // Items table
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF4F4F5)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFFE4E4E7), height: 1),
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                final desc = item['descripcion'] ?? '-';
                final cant = item['cantidad'] ?? 1;
                final sub = double.tryParse(item['subtotal']?.toString() ?? '') ?? 0.0;
                final itemTipo = item['tipo'] ?? 'PRODUCTO';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              desc,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              itemTipo,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'x$cant',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Bs. ${sub.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Totales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Final:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                'Bs. ${double.tryParse(montoStr)?.toStringAsFixed(2) ?? montoStr}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6D28D9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE4E4E7), height: 1, thickness: 1),
          const SizedBox(height: 12),

          // Pie de ticket
          const Center(
            child: Text(
              '¡Gracias por tu confianza!\nConserva este ticket digital.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowDetail(
    String label,
    String value, {
    Color valueColor = const Color(0xFF374151),
    FontWeight valueFontWeight = FontWeight.w600,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: valueColor,
              fontWeight: valueFontWeight,
            ),
          ),
        ],
      ),
    );
  }
}
