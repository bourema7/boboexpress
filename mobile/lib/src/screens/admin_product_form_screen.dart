import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/api_service.dart';

class AdminProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const AdminProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  static const Color _pageColor = Color(0xFFFFFFFF);
  static const Color _textColor = Color(0xFF111827);
  static const Color _mutedTextColor = Color(0xFF6B7280);
  static const Color _fieldColor = Color(0xFFF3F4F6);
  static const Color _borderColor = Color(0xFFE5E7EB);

  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _discountPriceController;

  bool _isNew = false;
  bool _isPromo = false;

  int? _selectedCategoryId;
  List<dynamic> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  // Gestion des variantes
  List<Map<String, dynamic>> _variants = [];

  XFile? _imageFile;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?['name']);
    _descriptionController =
        TextEditingController(text: widget.product?['description']);
    _priceController =
        TextEditingController(text: widget.product?['price']?.toString());
    _stockController = TextEditingController(
        text: widget.product?['stock']?.toString() ?? '10');
    _discountPriceController = TextEditingController(
        text: widget.product?['discount_price']?.toString());
    _isNew = widget.product?['is_new'] ?? false;
    _isPromo = widget.product?['is_promo'] ?? false;
    _selectedCategoryId = widget.product?['category_id'];

    // Charger les variantes existantes si modification
    if (widget.product != null && widget.product!['variants'] != null) {
      _variants = List<Map<String, dynamic>>.from(widget.product!['variants']);
    }

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _apiService.getCategories();
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
        if (_selectedCategoryId == null && cats.isNotEmpty) {
          _selectedCategoryId = cats.first['id'];
        }
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sélectionnez une catégorie')));
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'price': _priceController.text,
      'stock': _stockController.text,
      'category_id': _selectedCategoryId.toString(),
      'is_active': 'true',
      'is_new': _isNew.toString(),
      'is_promo': _isPromo.toString(),
      if (_isPromo && _discountPriceController.text.isNotEmpty)
        'discount_price': _discountPriceController.text,
    };

    final res = await _apiService.saveProductDetails(
      data: data,
      imageBytes: _imageBytes,
      fileName: _imageFile?.name,
      productId: widget.product?['id'],
    );

    if (res['success']) {
      try {
        final int productId = widget.product?['id'] ?? res['data']['id'];

        // Enregistrer les nouvelles variantes (celles qui n'ont pas encore d'ID)
        for (var variant in _variants) {
          if (variant['id'] == null) {
            await _apiService.createVariant(productId, variant);
          }
        }

        setState(() => _isSaving = false);
        Navigator.pop(context, true);
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur (${res['status']}): ${res['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: _pageColor,
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier le Produit' : 'Ajouter un Produit',
            style: const TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w600,
            )),
        backgroundColor: _pageColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textColor),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 32),
                    _buildLabel('Nom du produit'),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: _textColor),
                      decoration: _inputDecoration('Ex: Robe de soirée...'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Catégorie'),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      dropdownColor: _pageColor,
                      style: const TextStyle(color: _textColor, fontSize: 16),
                      iconEnabledColor: _mutedTextColor,
                      decoration: _inputDecoration('Choisir une catégorie'),
                      items: _categories.map<DropdownMenuItem<int>>((cat) {
                        return DropdownMenuItem<int>(
                          value: cat['id'],
                          child: Text(
                            cat['name'],
                            style: const TextStyle(color: _textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategoryId = val),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Prix (XOF)'),
                              TextFormField(
                                controller: _priceController,
                                style: const TextStyle(color: _textColor),
                                decoration: _inputDecoration('0.00'),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Requis' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Stock'),
                              TextFormField(
                                controller: _stockController,
                                style: const TextStyle(color: _textColor),
                                decoration: _inputDecoration('Quantité'),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Requis' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Description'),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: _textColor),
                      decoration: _inputDecoration('Détails du produit...'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    // Options Nouveauté et Promotion
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Nouveauté',
                                style: TextStyle(
                                  color: _textColor,
                                  fontWeight: FontWeight.bold,
                                )),
                            subtitle: const Text(
                                'Mettre en avant dans la section Nouveautés',
                                style: TextStyle(
                                  color: _mutedTextColor,
                                  fontSize: 12,
                                )),
                            value: _isNew,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (val) => setState(() => _isNew = val),
                          ),
                          const Divider(),
                          SwitchListTile(
                            title: const Text('En Promotion',
                                style: TextStyle(
                                  color: _textColor,
                                  fontWeight: FontWeight.bold,
                                )),
                            subtitle: const Text(
                                'Afficher dans la section Promotions',
                                style: TextStyle(
                                  color: _mutedTextColor,
                                  fontSize: 12,
                                )),
                            value: _isPromo,
                            activeColor: Colors.red,
                            onChanged: (val) => setState(() => _isPromo = val),
                          ),
                          if (_isPromo) ...[
                            const SizedBox(height: 12),
                            _buildLabel('Prix Réduit (XOF)'),
                            TextFormField(
                              controller: _discountPriceController,
                              style: const TextStyle(color: _textColor),
                              decoration:
                                  _inputDecoration('Prix après réduction...'),
                              keyboardType: TextInputType.number,
                              validator: (v) => _isPromo &&
                                      (v == null || v.isEmpty)
                                  ? 'Le prix réduit est requis pour une promotion'
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section des Variantes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Variantes (Couleurs, Tailles...)'),
                        TextButton.icon(
                          onPressed: _showAddVariantDialog,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    if (_variants.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _borderColor,
                              style: BorderStyle.solid),
                        ),
                        child: const Text(
                          'Aucune variante ajoutée. Parfait pour les articles sans options.',
                          style:
                              TextStyle(color: _mutedTextColor, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _variants
                            .map((v) => Chip(
                                  label: Text(
                                      '${v['name']} (+${v['price_extra']} XOF)'),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () =>
                                      setState(() => _variants.remove(v)),
                                  backgroundColor: Colors.grey.shade100,
                                ))
                            .toList(),
                      ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          primary: Colors.black,
                          onPrimary: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                isEdit
                                    ? 'METTRE À JOUR'
                                    : 'ENREGISTRER LE PRODUIT',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text,
          style: const TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          )),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _mutedTextColor),
      labelStyle: const TextStyle(color: _textColor),
      floatingLabelStyle: const TextStyle(color: _textColor),
      filled: true,
      fillColor: _fieldColor,
      errorStyle: const TextStyle(color: Color(0xFFB91C1C)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _textColor, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _fieldColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
          image: _imageBytes != null
              ? DecorationImage(
                  image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
              : (widget.product?['image'] != null
                  ? DecorationImage(
                      image: NetworkImage(widget.product!['image']),
                      fit: BoxFit.cover)
                  : null),
        ),
        child: _imageBytes == null && widget.product?['image'] == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_a_photo_outlined,
                      size: 40, color: _mutedTextColor),
                  SizedBox(height: 12),
                  Text('Ajouter une photo',
                      style: TextStyle(color: _mutedTextColor)),
                ],
              )
            : Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(12),
                child: const CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 18,
                  child: Icon(Icons.edit, size: 18, color: Colors.white),
                ),
              ),
      ),
    );
  }

  void _showAddVariantDialog() {
    final priceExtraController = TextEditingController(text: '0');
    final stockController = TextEditingController(text: '10');

    final List<String> predefinedColors = [
      'Bleu',
      'Noir',
      'Rouge',
      'Blanc',
      'Vert',
      'Jaune',
      'Gris',
      'Rose',
      'Marron',
      'Orange',
      'Violet'
    ];
    final List<String> predefinedSizes = [
      'XS',
      'S',
      'M',
      'L',
      'XL',
      'XXL',
      '35',
      '36',
      '37',
      '38',
      '39',
      '40',
      '41',
      '42',
      '43',
      '44',
      '45',
      '46'
    ];

    List<String> selectedColors = [];
    List<String> selectedSizes = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            title: const Text('Générer des Variantes'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Couleurs',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: predefinedColors.map((color) {
                      final isSelected = selectedColors.contains(color);
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            if (isSelected) {
                              selectedColors.remove(color);
                            } else {
                              selectedColors.add(color);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? colorScheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.grey.shade300),
                          ),
                          child: Text(
                            color,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Tailles / Pointures',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: predefinedSizes.map((size) {
                      final isSelected = selectedSizes.contains(size);
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            if (isSelected) {
                              selectedSizes.remove(size);
                            } else {
                              selectedSizes.add(size);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? colorScheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.grey.shade300),
                          ),
                          child: Text(
                            size,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: priceExtraController,
                    decoration: const InputDecoration(
                        labelText: 'Prix Supplémentaire (XOF)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stockController,
                    decoration: const InputDecoration(
                        labelText: 'Stock (pour chaque variante)'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (selectedSizes.isEmpty) selectedSizes.add('');
                    if (selectedColors.isEmpty) selectedColors.add('');

                    for (var color in selectedColors) {
                      for (var size in selectedSizes) {
                        if (color.isEmpty && size.isEmpty) continue;

                        List<String> parts = [];
                        if (color.isNotEmpty) parts.add(color);
                        if (size.isNotEmpty) parts.add(size);
                        String variantName = parts.join(' - ');

                        _variants.add({
                          'name': variantName,
                          'color': color,
                          'size': size,
                          'price_extra': priceExtraController.text,
                          'stock': stockController.text,
                        });
                      }
                    }
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Générer'),
              ),
            ],
          );
        },
      ),
    );
  }
}
