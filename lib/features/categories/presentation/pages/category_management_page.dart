import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/category_provider.dart';
import '../widgets/category_icon.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Manage Categories'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses', icon: Icon(Icons.arrow_outward_rounded)),
              Tab(text: 'Income', icon: Icon(Icons.arrow_downward_rounded)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CategoryListTab(isExpense: true),
            CategoryListTab(isExpense: false),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddCategorySheet(context),
          label: const Text('Add Category'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const AddCategorySheet(),
    );
  }
}

class CategoryListTab extends StatelessWidget {
  final bool isExpense;

  const CategoryListTab({super.key, required this.isExpense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<CategoryProvider>(context);
    final cats = isExpense ? provider.expenseCategories : provider.incomeCategories;

    if (cats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No categories found',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cats.length,
      itemBuilder: (context, index) {
        final cat = cats[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isExpense
                  ? Colors.redAccent.withOpacity(0.1)
                  : Colors.greenAccent.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: CategoryIcon(
                  categoryName: cat.name,
                  isExpense: cat.isExpense,
                  size: 24,
                ),
              ),
            ),
            title: Text(
              cat.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              cat.isCustom ? 'Custom Category' : 'System Category',
              style: TextStyle(
                color: cat.isCustom ? theme.colorScheme.primary : Colors.grey,
                fontSize: 12,
              ),
            ),
            trailing: cat.isCustom
                ? IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    onPressed: () {
                      _showDeleteConfirmation(context, provider, cat.id, cat.name);
                    },
                  )
                : const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    CategoryProvider provider,
    String id,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$name"? Existing transactions in this category will keep their records but fallback to default icons.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteCategory(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({super.key});

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _nameController = TextEditingController();
  bool _isExpense = true;
  String? _pickedImagePath;
  int? _selectedIconCodePoint;

  // List of preselected Material Icons for custom categories
  final List<int> _availableIcons = [
    Icons.restaurant.codePoint,
    Icons.receipt_long.codePoint,
    Icons.home.codePoint,
    Icons.medical_services.codePoint,
    Icons.school.codePoint,
    Icons.flight.codePoint,
    Icons.shopping_bag.codePoint,
    Icons.face.codePoint,
    Icons.movie.codePoint,
    Icons.directions_car.codePoint,
    Icons.card_giftcard.codePoint,
    Icons.subscriptions.codePoint,
    Icons.volunteer_activism.codePoint,
    Icons.payment.codePoint,
    Icons.pets.codePoint,
    Icons.fitness_center.codePoint,
    Icons.sports_esports.codePoint,
    Icons.work.codePoint,
    Icons.more_horiz.codePoint,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (image != null) {
        setState(() {
          _pickedImagePath = image.path;
          _selectedIconCodePoint = null; // Clear icon if image is picked
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _saveCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    if (_pickedImagePath == null && _selectedIconCodePoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an icon or upload an image')),
      );
      return;
    }

    final provider = Provider.of<CategoryProvider>(context, listen: false);
    provider.addCustomCategory(
      name,
      _isExpense,
      pickedImagePath: _pickedImagePath,
      iconCodePoint: _selectedIconCodePoint,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Category "$name" added successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Custom Category',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                filled: true,
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Type Segmented Button
            const Text(
              'Category Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Expense')),
                    selected: _isExpense,
                    onSelected: (val) {
                      setState(() {
                        _isExpense = true;
                      });
                    },
                    selectedColor: Colors.redAccent.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _isExpense ? Colors.redAccent : theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Income')),
                    selected: !_isExpense,
                    onSelected: (val) {
                      setState(() {
                        _isExpense = false;
                      });
                    },
                    selectedColor: Colors.greenAccent.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: !_isExpense ? Colors.green : theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Visual Icon Preview Row
            Row(
              children: [
                const Text(
                  'Visual Asset',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                if (_pickedImagePath != null || _selectedIconCodePoint != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('Preview: ', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        if (_pickedImagePath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              File(_pickedImagePath!),
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (_selectedIconCodePoint != null)
                          Icon(
                            getIconDataFromCodePoint(_selectedIconCodePoint!),
                            size: 24,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 12),

            // Custom Image Upload Button
            ElevatedButton.icon(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.grey[850] : Colors.grey[100],
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              icon: const Icon(Icons.image_outlined),
              label: const Text('Pick Image from Gallery'),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('OR CHOOSE ICON', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            // Preselected Material Icons Grid
            SizedBox(
              height: 150,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _availableIcons.length,
                itemBuilder: (context, index) {
                  final codePoint = _availableIcons[index];
                  final iconData = getIconDataFromCodePoint(codePoint);
                  final isSelected = _selectedIconCodePoint == codePoint;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIconCodePoint = codePoint;
                        _pickedImagePath = null; // Clear image if icon is picked
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        iconData,
                        color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Save Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
