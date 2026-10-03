import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/product.dart';
import '../screens/barcode_scanner_screen.dart';
import '../services/api_service.dart';
import '../services/storage_factory.dart';
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
  late TextEditingController _notificationDaysController;
  late int _quantity;
  
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
    final visibleTypes = AppTheme.instance.visibleTypes();
    _type = p?.type ?? (visibleTypes.isNotEmpty ? visibleTypes.first : 'care');
    _category = p?.category ?? 'basic_care';
    _expiryDate = p?.expiryDate ?? DateTime.now().add(const Duration(days: 180));
    _isOpened = p?.isOpened ?? false;
    _openedDate = p?.openedDate;
    _expiryDaysAfterOpen = p?.expiryDaysAfterOpen ?? 30;
    _imageUrl = p?.imageUrl;
    _notificationDaysController = TextEditingController(
      text: p?.notificationDays?.toString() ?? '',
    );
    _quantity = p?.quantity ?? 1;

    // Listen for theme changes
    AppTheme.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _purposeController.dispose();
    _notificationDaysController.dispose();
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
    
    try {
      final result = await ApiService.lookupBarcode(barcode);
      if (mounted) {
        setState(() {
          _isLookingUp = false;
          if (result != null) {
            _lookupResult = result['name'] ?? result['product_name'] ?? 'Найден товар';
            _lookupError = null;
            // Auto-fill name if empty
            if (_nameController.text.trim().isEmpty) {
              final name = result['name'] ?? result['product_name'];
              if (name != null) {
                _nameController.text = name;
              }
            }
          } else {
            _lookupResult = 'Товар не найден';
            _lookupError = 'not_found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLookingUp = false;
          _lookupResult = 'Ошибка поиска';
          _lookupError = 'network';
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final notificationDays = int.tryParse(_notificationDaysController.text.trim());
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
        notificationDays: notificationDays,
        quantity: _quantity,
      );
      widget.onSave(product);
    }
  }

  Future<void> _uploadImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Выберите источник', style: TextStyle(color: AppTheme.instance.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Камера'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 90);
    if (image == null) return;

    // Offer native cropping (uCrop on Android) right after picking.
    final cropped = await _cropImage(image);
    if (cropped == null) return; // user cancelled the crop

    setState(() => _isUploadingImage = true);

    try {
      // Persist the cropped image to local storage.
      final bytes = await cropped.readAsBytes();
      final storage = createStorageService();
      final url = await storage.saveImageBytes(bytes, cropped.path.split('/').last);

      if (url != null && mounted) {
        setState(() => _imageUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Изображение добавлено'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось сохранить изображение'),
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

  Future<CroppedFile?> _cropImage(XFile picked) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Обрезка фото',
            toolbarColor: AppTheme.instance.primaryColor,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
            hideBottomControls: false,
            initAspectRatio: CropAspectRatioPreset.original,
          ),
          IOSUiSettings(title: 'Обрезка фото'),
        ],
      );
    } catch (e) {
      debugPrint('crop error: $e');
      return null;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  /// Type options: visible types (+ the current one even if hidden).
  List<DropdownMenuItem<String>> _typeItems(AppTheme theme) {
    final types = AppTheme.instance.visibleTypes();
    if (!types.contains(_type)) types.add(_type);
    return types
        .map((t) => DropdownMenuItem(
              value: t,
              child: Text(
                AppTheme.instance.typeName(t),
                style: TextStyle(color: theme.textColor),
              ),
            ))
        .toList();
  }

  /// Grouped dropdown items: a disabled header per group, leaves indented.
  List<DropdownMenuItem<String>> _buildCategoryItems(AppTheme theme) {
    final items = <DropdownMenuItem<String>>[];
    for (final group in AppTheme.instance.getCategoryTree(_type)) {
      if (!group.isUngrouped) {
        items.add(DropdownMenuItem<String>(
          enabled: false,
          value: '_group_${group.key}',
          child: Text(
            group.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textLightColor,
            ),
          ),
        ));
      }
      for (final leaf in group.leaves.entries) {
        items.add(DropdownMenuItem<String>(
          value: leaf.key,
          child: Padding(
            padding: EdgeInsets.only(left: group.isUngrouped ? 0 : 12),
            child: Text(leaf.value, style: TextStyle(color: theme.textColor)),
          ),
        ));
      }
    }
    return items;
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => BarcodeScannerScreen(
                            onBarcodeDetected: (barcode) {
                              _barcodeController.text = barcode;
                              _lookupBarcode();
                            },
                          ),
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
                                  errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
                                )
                              : Image.network(
                                  Product.getDisplayUrl(_imageUrl) ?? _imageUrl!,
                                  fit: BoxFit.cover,
                                  cacheWidth: 160,
                                  cacheHeight: 160,
                                  errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
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
                initialValue: _type,
                dropdownColor: theme.surfaceColor,
                decoration: InputDecoration(
                  labelText: 'Тип',
                  labelStyle: TextStyle(color: theme.textColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
                ),
                items: _typeItems(theme),
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
                initialValue: categories.containsKey(_category) ? _category : categories.keys.first,
                dropdownColor: theme.surfaceColor,
                decoration: InputDecoration(
                  labelText: 'Категория',
                  labelStyle: TextStyle(color: theme.textColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
                ),
                items: _buildCategoryItems(theme),
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

              // Quantity stepper
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Row(
                  children: [
                    Text(
                      'Количество',
                      style: TextStyle(color: theme.textColor, fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: theme.primaryColor,
                      iconSize: 28,
                      visualDensity: VisualDensity.compact,
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add_circle_outline),
                      color: theme.primaryColor,
                      iconSize: 28,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
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
                    _formatDate(_expiryDate),
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notification days
              TextFormField(
                controller: _notificationDaysController,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  labelText: 'Уведомить за (дней, оставьте пустым чтобы не уведомлять)',
                  labelStyle: TextStyle(color: theme.textColor),
                  hintText: 'например: 7',
                  hintStyle: TextStyle(color: theme.textLightColor),
                  border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
                ),
                keyboardType: TextInputType.number,
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
                            _openedDate != null ? _formatDate(_openedDate!)
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
                        errorBuilder: (_, _, _) => _buildPreviewError(theme),
                      )
                    : Image.network(
                        Product.getDisplayUrl(imageUrl) ?? imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _buildPreviewError(theme),
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
