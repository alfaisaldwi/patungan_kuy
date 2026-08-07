import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/person_order.dart';
import '../bloc/calculator_bloc.dart';

class EditPersonDialog extends StatefulWidget {
  final PersonOrder order;
  const EditPersonDialog({super.key, required this.order});

  @override
  State<EditPersonDialog> createState() => _EditPersonDialogState();
}

class _EditPersonDialogState extends State<EditPersonDialog> {
  late final _nameCtrl = TextEditingController(text: widget.order.name);
  late final _itemCtrls = widget.order.items
      .map(
        (item) => (
          name: TextEditingController(text: item.name),
          price: TextEditingController(text: AppTheme.formatRupiah(item.price)),
        ),
      )
      .toList();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _itemCtrls) {
      c.name.dispose();
      c.price.dispose();
    }
    super.dispose();
  }

  void _add() => setState(
    () => _itemCtrls.add((
      name: TextEditingController(),
      price: TextEditingController(),
    )),
  );

  void _remove(int i) {
    if (_itemCtrls.length <= 1) return;
    setState(() {
      _itemCtrls[i].name.dispose();
      _itemCtrls[i].price.dispose();
      _itemCtrls.removeAt(i);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final items = _itemCtrls
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
        const SnackBar(content: Text('Minimal satu item valid, ya.')),
      );
      return;
    }
    context.read<CalculatorBloc>().add(
      UpdatePersonOrder(
        id: widget.order.id,
        name: _nameCtrl.text.trim(),
        items: items,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ubah Pesanan', style: AppTheme.heading3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: AppTheme.inputDecoration(label: 'Nama'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: AppTheme.spaceLg),
                Text('Item', style: AppTheme.label),
                const SizedBox(height: AppTheme.spaceSm),
                ...List.generate(_itemCtrls.length, (i) {
                  final c = _itemCtrls[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: c.name,
                            decoration: AppTheme.inputDecoration(
                              label: 'Item',
                              hint: 'opsional',
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
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
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
                        if (_itemCtrls.length > 1)
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: AppTheme.error,
                              size: 20,
                            ),
                            onPressed: () => _remove(i),
                          ),
                      ],
                    ),
                  );
                }),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah Item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}
