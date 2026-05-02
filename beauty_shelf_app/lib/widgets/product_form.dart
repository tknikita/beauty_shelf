import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/storage_io.dart';
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
  
  // Abbreviate category names for dropdown
  String _abbr(String name) {
    if (name.length <= 10) return name;
    return '${name.substring(0, 8)}…';
  }
  
  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  late TextEditingController _purposeController;
  late String _type;
  late String _category;
  late DateTime _expiryDate;
  late bool _isOpened;
  DateTime? _openedDate;
  late int _expiryDaysAfterOpen;
  String? _imageUrl;
  bool _isUploadingImage = false;
  
  bool _isLookingUp = false;
  String? _lookupResult;
  String? _lookupError; // 'network', 'not_found', 'empty'

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
    _imageUrl = p?.imageUrl;
    
    // Listen for theme changes
    AppTheme.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _purposeController.dispose();
    AppTheme.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _lookupBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.length < 8) {
      setState(() {
        _lookupResult = null;
        _lookupError = null;
      });
      return;
    }
    
    setState(() {
      _isLookingUp = true;
      _lookupResult = null;
      _lookupError = null;
    });
    
    // Barcode lookup requires network - show offline message for mobile
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _lookupResult = 'Поиск по штрихкоду недоступен в офлайн режиме';
      _lookupError = 'network';
      _isLookingUp = false;
    });
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
        imageUrl: _imageUrl,
      );
      widget.onSave(product);
    }
  }

  Future<void> _uploadImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    
    if (image == null) return;
    
    setState(() => _isUploadingImage = true);
    
    try {
      // Copy image to local storage
      final storage = MobileStorageService();
      final localPath = await storage.saveImage(image.path);
      
      if (localPath != null && mounted) {
        setState(() => _imageUrl = localPath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Изображение добавлено'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ошибка загрузки изображения'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    final categories = theme.getCategoriesByType(_type);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom + 24;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: bottomPadding,
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 24),
              
              // Barcode
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _barcodeController,
                      style: TextStyle(color: theme.textColor),
                      decoration: InputDecoration(
                        labelText: 'Штрихкод (EAN/UPC)',
                        labelStyle: TextStyle(color: theme.textColor),
                        hintStyle: TextStyle(color: theme.textLightColor),
                        border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
                        filled: true,
                        fillColor: theme.backgroundColor,
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
                        border: Border.all(color: theme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.qr_code_scanner, color: theme.textLightColor),
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
                _LookupResultBanner(
                  lookupResult: _lookupResult,
                  lookupError: _lookupError,
                  onRetry: _lookupBarcode,
                  onDismiss: () => setState(() {
                    _lookupResult = null;
                    _lookupError = null;
                  }),
                ),
              ],
              const SizedBox(height: 16),

              // Image picker
              Row(
                children: [
                  if (_imageUrl != null) ...[
                    GestureDetector(
                      onTap: () => _showImagePreview(context, _imageUrl!),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Product.isLocalPath(_imageUrl!)
                              ? Image.file(
                                  File(_imageUrl!),
                                  fit: BoxFit.cover,
                                  cacheWidth: 160,
                                  cacheHeight: 160,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                )
                              : Image.network(
                                  Product.getDisplayUrl(_imageUrl) ?? _imageUrl!,
                                  fit: BoxFit.cover,
                                  cacheWidth: 160,
                                  cacheHeight: 160,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _isUploadingImage ? null : _uploadImage,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.image),
                    label: Text(_imageUrl != null ? 'Заменить фото' : 'Добавить фото'),
                  ),
                  if (_imageUrl != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => _imageUrl = null),
                      icon: const Icon(Icons.delete_outline),
                      color: theme.warningColor,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  labelText: 'Название',
                  labelStyle: TextStyle(color: theme.textColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),

              // Type & Category row
              // Type & Category - stacked on narrow screens
              DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: theme.surfaceColor,
                decoration: InputDecoration(
                  labelText: 'Тип',
                  labelStyle: TextStyle(color: theme.textColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
                ),
                items: [
                  DropdownMenuItem(value: 'care', child: Text('Уходовая', style: TextStyle(color: theme.textColor))),
                  DropdownMenuItem(value: 'decorative', child: Text('Декоративная', style: TextStyle(color: theme.textColor))),
                ],
                onChanged: (v) {
                  setState(() {
                    _type = v!;
                    final cats = theme.getCategoriesByType(_type);
                    _category = cats.keys.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: categories.containsKey(_category) ? _category : categories.keys.first,
                dropdownColor: theme.surfaceColor,
                decoration: InputDecoration(
                  labelText: 'Категория',
                  labelStyle: TextStyle(color: theme.textColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
                ),
                items: categories.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: TextStyle(color: theme.textColor))))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),

              // Purpose
              TextFormField(
                controller: _purposeController,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  labelText: 'Назначение',
                  labelStyle: TextStyle(color: theme.textColor),
                  hintStyle: TextStyle(color: theme.textLightColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
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
                    border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                    suffixIcon: Icon(Icons.calendar_today, color: theme.textLightColor),
                  ),
                  child: Text(
                    '${_expiryDate.day}.${_expiryDate.month.toString().padLeft(2, '0')}.${_expiryDate.year}',
                    style: TextStyle(color: theme.textColor),
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
                title: Text('Вскрыта упаковка', style: TextStyle(color: theme.textColor)),
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
                            border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                          ),
                          child: Text(
                            _openedDate != null
                                ? '${_openedDate!.day}.${_openedDate!.month.toString().padLeft(2, '0')}.${_openedDate!.year}'
                                : 'Выберите дату',
                            style: TextStyle(color: theme.textColor),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextFormField(
                        initialValue: _expiryDaysAfterOpen.toString(),
                        style: TextStyle(color: theme.textColor),
                        decoration: InputDecoration(
                          labelText: 'Срок после вскрытия (дней)',
                          labelStyle: TextStyle(color: theme.textColor),
                          border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
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

  void _showImagePreview(BuildContext context, String imageUrl) {
    final theme = AppTheme.instance;
    final isLocal = Product.isLocalPath(imageUrl);
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: isLocal
                    ? Image.file(
                        File(imageUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildPreviewError(theme),
                      )
                    : Image.network(
                        Product.getDisplayUrl(imageUrl) ?? imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildPreviewError(theme),
                      ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.isDarkMode ? Colors.black54 : Colors.white70,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: theme.textColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Separate widget for lookup result to isolate rebuilds
class _LookupResultBanner extends StatelessWidget {
  final String? lookupResult;
  final String? lookupError;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const _LookupResultBanner({
    this.lookupResult,
    this.lookupError,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (lookupResult == null) return const SizedBox.shrink();

    final theme = AppTheme.instance;
    final hasError = lookupError != null;
    final isNotFound = lookupError == 'not_found';
    final isNetwork = lookupError == 'network';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasError
            ? (isNotFound ? theme.warningBgColor : theme.expiredBgColor)
            : theme.successBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            hasError
                ? (isNotFound ? Icons.search_off : Icons.cloud_off)
                : Icons.check_circle,
            size: 18,
            color: hasError
                ? (isNotFound ? theme.warningColor : theme.expiredColor)
                : theme.successColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lookupResult!,
              style: TextStyle(
                fontSize: 13,
                color: hasError
                    ? (isNotFound ? theme.warningColor : theme.expiredColor)
                    : theme.successColor,
              ),
            ),
          ),
          if (isNetwork)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Повторить', style: TextStyle(fontSize: 12, color: theme.expiredColor)),
            ),
          if (isNotFound)
            IconButton(
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.close, size: 16, color: theme.warningColor),
            ),
        ],
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AlertDialog(
      backgroundColor: theme.surfaceColor,
      title: Text('Введите штрихкод', style: TextStyle(color: theme.textColor)),
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomPadding),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            style: TextStyle(color: theme.textColor),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '1234567890123',
              hintStyle: TextStyle(color: theme.textLightColor),
              border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
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

Widget _buildPreviewError(AppTheme theme) {
  return Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: theme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      Icons.image_not_supported,
      size: 64,
      color: theme.textLightColor,
    ),
  );
}
