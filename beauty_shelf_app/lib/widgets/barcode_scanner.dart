import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BarcodeScanner extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;
  final Function(String barcode) onBarcodeLookup;

  const BarcodeScanner({
    super.key,
    required this.onBarcodeScanned,
    required this.onBarcodeLookup,
  });

  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  final _controller = TextEditingController();
  bool _isLookingUp = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _lookup() {
    final barcode = _controller.text.trim();
    if (barcode.length >= 8) {
      widget.onBarcodeLookup(barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Штрихкод (EAN/UPC)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _lookup(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  // TODO: Implement camera scanning
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Сканирование камерой скоро будет доступно'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: Color(0xFF8A8A8A)),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _lookup,
                child: const Text('Найти'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
