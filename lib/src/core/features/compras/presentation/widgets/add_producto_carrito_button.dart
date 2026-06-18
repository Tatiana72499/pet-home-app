import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pethome_app/src/core/features/compras/providers/carrito_provider.dart';

class AddProductoCarritoButton extends StatefulWidget {
  const AddProductoCarritoButton({
    super.key,
    required this.productoId,
  });

  final int productoId;

  @override
  State<AddProductoCarritoButton> createState() => _AddProductoCarritoButtonState();
}

class _AddProductoCarritoButtonState extends State<AddProductoCarritoButton> {
  bool _isAdding = false;

  Future<void> _onTap() async {
    final quantity = await showDialog<double>(
      context: context,
      builder: (_) => const _CantidadDialog(),
    );

    if (!mounted || quantity == null || quantity <= 0) return;

    setState(() => _isAdding = true);

    final provider = Provider.of<CarritoProvider>(context, listen: false);

    final ok = await provider.addProducto(
      productoId: widget.productoId,
      cantidad: quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toStringAsFixed(2),
    );

    if (!mounted) return;

    setState(() => _isAdding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Producto agregado al carrito.' : (provider.errorMessage ?? 'No se pudo agregar el producto.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isAdding ? null : _onTap,
      icon: _isAdding
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.add_shopping_cart_rounded),
      label: Text(_isAdding ? 'Agregando...' : 'Agregar al carrito'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFF97316),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _CantidadDialog extends StatefulWidget {
  const _CantidadDialog();

  @override
  State<_CantidadDialog> createState() => _CantidadDialogState();
}

class _CantidadDialogState extends State<_CantidadDialog> {
  final TextEditingController _controller = TextEditingController(text: '1');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.replaceAll(',', '.').trim();
    final qty = double.tryParse(raw) ?? 0;
    if (qty <= 0) {
      setState(() => _error = 'Cantidad invalida.');
      return;
    }
    Navigator.of(context).pop(qty);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cantidad'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Cantidad',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
