import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const ProductForm({
    super.key,
    this.product,
    required this.onSave,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  
  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  late TextEditingController _purposeController;
  late String _type;
  late String _category;
  late DateTime _expiryDate;
  late bool _isOpened;
  DateTime? _openedDate;
  late int _expiryDaysAfterOpen;
  
  bool _isLookingUp = false;
  String? _lookupResult;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _barcodeController = TextEditingController(text: '');
    _nameController = TextEditingController(text: p?.name ?? '');
    _purposeController = TextEditingController(text: p?.purpose ?? '');
    _type = p?.type ?? 'care';
    _category = p?.category ?? 'basic_care';
    _expiryDate = p?.expiryDate ?? DateTime.now().add(const Duration(days: 180));
    _isOpened = p?.isOpened ?? false;
    _openedDate = p?.openedDate;
    _expiryDaysAfterOpen = p?.expiryDaysAfterOpen ?? 30;
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _lookupBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.length < 8) return;
    
    setState(() {
      _isLookingUp = true;
      _lookupResult = null;
    });
    
    try {
      final product = await _api.lookupBarcode(barcode);
      if (product.isNotEmpty) {
        final name = product['product_name'] ?? product['product_name_fr'] ?? product['name'];
        if (name != null && _nameController.text.isEmpty) {
          _nameController.text = name;
        }
        final brands = product['brands'];
        if (brands != null && _purposeController.text.isEmpty) {
          _purposeController.text = brands;
        }
        setState(() {
          _lookupResult = 'Найден: $name';
        });
      } else {
        setState(() {
          _lookupResult = 'Продукт не найден';
        });
      }
    } catch (e) {
      setState(() {
        _lookupResult = 'Ошибка поиска';
      });
    } finally {
      setState(() {
        _isLookingUp = false;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        type: _type,
        category: _category,
        purpose: _purposeController.text.trim().isEmpty ? null : _purposeController.text.trim(),
        expiryDate: _expiryDate,
        isOpened: _isOpened,
        openedDate: _isOpened ? _openedDate : null,
        expiryDaysAfterOpen: _expiryDaysAfterOpen,
      );
      widget.onSave(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = AppTheme.instance.getCategoriesByType(_type);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.product == null ? 'Добавить продукт' : 'Изменить продукт',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              
              // Barcode
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Штрихкод (EAN/UPC)',
                        border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.instance.borderColor)),
                        filled: true,
                        fillColor: AppTheme.instance.backgroundColor,
                        suffixIcon: _isLookingUp
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _lookupBarcode(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => _BarcodeEntryDialog(
                          onSubmit: (barcode) {
                            _barcodeController.text = barcode;
                            Navigator.pop(ctx);
                            _lookupBarcode();
                          },
                        ),
                      );
                    },
                    icon: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.instance.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.qr_code_scanner, color: AppTheme.instance.textLightColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _lookupBarcode,
                    child: const Text('Найти'),
                  ),
                ],
              ),
              if (_lookupResult != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _lookupResult!.startsWith('Найден') 
                        ? AppTheme.instance.okBgColor
                        : AppTheme.instance.warningBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _lookupResult!.startsWith('Найден') ? Icons.check_circle : Icons.warning,
                        size: 16,
                        color: _lookupResult!.startsWith('Найден') 
                            ? AppTheme.instance.okColor
                            : AppTheme.instance.warningColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lookupResult!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _lookupResult!.startsWith('Найден') 
                                ? AppTheme.instance.okColor
                                : AppTheme.instance.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.instance.borderColor)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),

              // Type & Category row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: InputDecoration(labelText: 'Тип', border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.instance.borderColor))),
                      items: const [
                        DropdownMenuItem(value: 'care', child: Text('Уходовая')),
                        DropdownMenuItem(value: 'decorative', child: Text('Декоративная')),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _type = v!;
                          final cats = AppTheme.instance.getCategoriesByType(_type);
                          _category = cats.keys.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: categories.containsKey(_category) ? _category : categories.keys.first,
                      decoration: InputDecoration(labelText: 'Категория', border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.instance.borderColor))),
                      items: categories.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Purpose
              TextFormField(
                controller: _purposeController,
                decoration: InputDecoration(
                  labelText: 'Назначение',
                  border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.instance.borderColor)),
                  hintText: 'Например: Для сухой кожи',
                ),
              ),
              const SizedBox(height: 16),

              // Expiry date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() => _expiryDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Годен до',
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.instance.borderColor)),
                    suffixIcon: Icon(Icons.calendar_today, color: AppTheme.instance.textLightColor),
                  ),
                  child: Text(
                    '${_expiryDate.day}.${_expiryDate.month.toString().padLeft(2, '0')}.${_expiryDate.year}',
                    style: TextStyle(color: AppTheme.instance.textColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Opened checkbox
              CheckboxListTile(
                value: _isOpened,
                onChanged: (v) => setState(() {
                  _isOpened = v ?? false;
                  if (_isOpened && _openedDate == null) {
                    _openedDate = DateTime.now();
                  }
                }),
                title: const Text('Вскрыта упаковка'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // Opened fields
              if (_isOpened) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _openedDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _openedDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Дата вскрытия',
                            border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.instance.borderColor)),
                          ),
                          child: Text(
                            _openedDate != null
                                ? '${_openedDate!.day}.${_openedDate!.month.toString().padLeft(2, '0')}.${_openedDate!.year}'
                                : 'Выберите дату',
                            style: TextStyle(color: AppTheme.instance.textColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _expiryDaysAfterOpen.toString(),
                        decoration: InputDecoration(
                          labelText: 'Срок после вскрытия (дней)',
                          border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.instance.borderColor)),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _expiryDaysAfterOpen = int.tryParse(v) ?? 30,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Сохранить'),
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

class _BarcodeEntryDialog extends StatefulWidget {
  final Function(String) onSubmit;

  const _BarcodeEntryDialog({required this.onSubmit});

  @override
  State<_BarcodeEntryDialog> createState() => _BarcodeEntryDialogState();
}

class _BarcodeEntryDialogState extends State<_BarcodeEntryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;

    return AlertDialog(
      title: const Text('Введите штрихкод'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '1234567890123',
              border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
              filled: true,
              fillColor: theme.backgroundColor,
            ),
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Text(
            'Введите код с упаковки или отсканируйте камерой',
            style: TextStyle(fontSize: 12, color: theme.textLightColor),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('ОК'),
        ),
      ],
    );
  }

  void _submit() {
    final barcode = _controller.text.trim();
    if (barcode.isNotEmpty) {
      widget.onSubmit(barcode);
    }
  }
}
