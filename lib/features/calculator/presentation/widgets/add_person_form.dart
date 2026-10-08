import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/person_order.dart';
import '../bloc/calculator_bloc.dart';
import 'small_icon_button.dart';

class AddPersonForm extends StatefulWidget {
  const AddPersonForm({super.key});

  @override
  State<AddPersonForm> createState() => AddPersonFormState();
}

class AddPersonFormState extends State<AddPersonForm> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _itemControllers =
      <({TextEditingController name, TextEditingController price})>[];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _addItemRow();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _itemControllers) {
      c.name.dispose();
      c.price.dispose();
    }
    super.dispose();
  }

  void _addItemRow() => setState(
    () => _itemControllers.add((
      name: TextEditingController(),
      price: TextEditingController(),
    )),
  );

  void expand() {
    if (!_isExpanded) setState(() => _isExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeItemRow(int i) {
    if (_itemControllers.length <= 1) return;
    setState(() {
      _itemControllers[i].name.dispose();
      _itemControllers[i].price.dispose();
      _itemControllers.removeAt(i);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final items = _itemControllers
        .map(
          (c) => OrderItem(
            name: c.name.text.trim(),
            price: AppTheme.parseRupiah(c.price.text),
          ),
        )
        .where((i) => i.price > 0)
        .toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal satu item harus ada harganya, ya.'),
        ),
      );
      return;
    }
    context.read<CalculatorBloc>().add(
      AddPersonOrder(name: _nameController.text.trim(), items: items),
    );
    _nameController.clear();
    for (final c in _itemControllers) {
      c.name.dispose();
      c.price.dispose();
    }
    _itemControllers.clear();
    _addItemRow();
    setState(() => _isExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLg),
            ),
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingCard,
                  vertical: AppTheme.spaceMd,
                ),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Text('Tambah Orang', style: AppTheme.heading3),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _isExpanded
                            ? AppTheme.primaryLight
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        _isExpanded ? 'Tutup' : 'Buka',
                        style: AppTheme.caption.copyWith(
                          color: _isExpanded
                              ? AppTheme.primary
                              : AppTheme.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.paddingCard,
                0,
                AppTheme.paddingCard,
                AppTheme.paddingCard,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      const SizedBox(height: AppTheme.spaceSm),
                    TextFormField(
                      controller: _nameController,
                      decoration: AppTheme.inputDecoration(
                        label: 'Nama',
                        hint: 'Misal: Budi',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            '${_itemControllers.length}',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Item', style: AppTheme.label),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    ...List.generate(_itemControllers.length, (i) {
                      final c = _itemControllers[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: c.name,
                                decoration: AppTheme.inputDecoration(
                                  label: 'Nama item',
                                  hint: 'Nasi Goreng',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: c.price,
                                decoration: AppTheme.inputDecoration(
                                  label: 'Harga',
                                  hint: '25000',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [AppTheme.rupiahFormatter],
                                validator: i == 0
                                    ? (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Wajib diisi';
                                        }
                                        final p = AppTheme.parseRupiah(v);
                                        if (p <= 0) return 'Nggak valid';
                                        return null;
                                      }
                                    : null,
                              ),
                            ),
                            SizedBox(
                              width: 44,
                              child: _itemControllers.length > 1
                                  ? Center(
                                      child: SmallIconButton(
                                        icon: Icons.remove_rounded,
                                        color: AppTheme.error,
                                        tooltip: 'Hapus item',
                                        onTap: () => _removeItemRow(i),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addItemRow,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Tambah Item'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.person_add_alt, size: 18),
                        label: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}
