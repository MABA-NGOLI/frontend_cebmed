import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/stock_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/stock_update_view_model.dart';

class StockUpdateView extends StatefulWidget {
  const StockUpdateView({super.key, required this.item});

  final StockItem item;

  @override
  State<StockUpdateView> createState() => _StockUpdateViewState();
}

class _StockUpdateViewState extends State<StockUpdateView> {
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  late final StockUpdateViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StockUpdateViewModel();
    _quantityController.text = widget.item.quantity.toString();
    _locationController.text = widget.item.location;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _locationController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _onUpdate() async {
    final quantity = int.tryParse(_quantityController.text.trim());
    final location = _locationController.text.trim();
    final ok = await _viewModel.updateStock(
      id: widget.item.id,
      quantity: quantity,
      location: location.isEmpty ? null : location,
    );
    if (!mounted) return;
    if (ok) {
      _showFeedback('Stock mis à jour');
      Navigator.of(context).pop(true);
    } else {
      _showFeedback(_viewModel.error ?? 'Erreur', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  color: AppTheme.softPink,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
                      Expanded(
                        child: Text(
                          'Modifier le stock',
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        widget.item.medication.name,
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.item.quantity} unité${widget.item.quantity != 1 ? 's' : ''} actuellement en stock',
                        style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),

                      _SectionCard(
                        title: 'Modifier les informations',
                        icon: Icons.edit_outlined,
                        iconColor: AppTheme.primaryPink,
                        child: Column(
                          children: [
                            TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: _inputDecoration('Quantité exacte'),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _locationController,
                              decoration: _inputDecoration('Lieu de stockage'),
                            ),
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: _viewModel.isLoading ? null : _onUpdate,
                              child: _viewModel.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Enregistrer'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFEAEAEA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
