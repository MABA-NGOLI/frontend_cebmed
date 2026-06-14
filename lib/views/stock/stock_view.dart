import 'package:flutter/material.dart';

import '../../models/stock_model.dart';
import '../../models/treatment_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/stock_view_model.dart';
import 'stock_add_view.dart';
import 'stock_update_view.dart';

class StockView extends StatefulWidget {
  const StockView({super.key, this.canEditStock = true});

  final bool canEditStock;

  @override
  State<StockView> createState() => _StockViewState();
}

class _StockViewState extends State<StockView> {
  late final StockViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StockViewModel();
    _viewModel.loadStock();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final count = _viewModel.attentionCount;
        final subtitle =
            'Gérez votre traitement avec précision. '
            '$count article${count != 1 ? 's' : ''} '
            'nécessite${count != 1 ? 'nt' : ''} votre attention.';

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
                      const SizedBox(width: 28),
                      Expanded(
                        child: Text(
                          'Mon stock',
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 28),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _viewModel.loadStock,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('Votre inventaire', style: textTheme.titleLarge),
                        const SizedBox(height: 8),
                        if (_viewModel.isLoading)
                          const SizedBox(
                            height: 16,
                            child: LinearProgressIndicator(),
                          )
                        else if (_viewModel.error != null)
                          Text(
                            'Erreur : ${_viewModel.error}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.red,
                            ),
                          )
                        else ...[
                          Text(
                            subtitle,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (widget.canEditStock)
                            GestureDetector(
                              onTap: () async {
                                final created = await Navigator.of(context)
                                    .push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => const StockAddView(),
                                      ),
                                    );
                                if (created == true) {
                                  _viewModel.loadStock();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Médicament ajouté au stock',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const _AddMedicamentCard(),
                            ),
                          const SizedBox(height: 24),
                          if (_viewModel.items.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: Text(
                                  'Pas de stock créé / trouvé',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.black45,
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._viewModel.items.map(
                              (item) => _StockItemCard(
                                item: item,
                                canEditStock: widget.canEditStock,
                                treatment: _viewModel
                                    .activeTreatments[item.medicationId],
                                onDeleted: _viewModel.loadStock,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _StockItemCard extends StatelessWidget {
  const _StockItemCard({
    required this.item,
    required this.canEditStock,
    this.treatment,
    this.onDeleted,
  });

  final StockItem item;
  final bool canEditStock;
  final TreatmentItem? treatment;
  final VoidCallback? onDeleted;

  void _openDetail(BuildContext context) async {
    final deleted = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height:
            MediaQuery.of(context).size.height *
            (treatment != null ? 0.78 : 0.50),
        child: _StockDetailSheet(
          item: item,
          treatment: treatment,
          canEditStock: canEditStock,
        ),
      ),
    );
    if (deleted == true) onDeleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasTreatment = treatment != null;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medication_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.medication.name,
                          style: textTheme.bodyLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.medication.pharmaceuticalForm,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.quantity < 5
                          ? const Color(0xFFE53935)
                          : const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.quantity < 5 ? 'STOCK FAIBLE' : 'STOCK OK',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${item.quantity} unité${item.quantity != 1 ? 's' : ''} '
                'restante${item.quantity != 1 ? 's' : ''}',
                style: textTheme.titleMedium,
              ),

              // Indicateur traitement
              if (hasTreatment) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.alarm_outlined,
                      size: 14,
                      color: AppTheme.primaryPink,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Traitement actif',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryPink,
                        fontSize: 13,
                      ),
                    ),
                    if (treatment!.endDate != null) ...[
                      const Spacer(),
                      Text(
                        'Fin : ${_fmt(treatment!.endDate!)}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ---------------------------------------------------------------------------

class _StockDetailSheet extends StatefulWidget {
  const _StockDetailSheet({
    required this.item,
    required this.canEditStock,
    this.treatment,
  });

  final StockItem item;
  final bool canEditStock;
  final TreatmentItem? treatment;

  @override
  State<_StockDetailSheet> createState() => _StockDetailSheetState();
}

class _StockDetailSheetState extends State<_StockDetailSheet> {
  List<TreatmentSchedule>? _schedules;
  bool _loadingSchedules = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.treatment != null) _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _loadingSchedules = true);
    try {
      final schedules = await ApiService.getTreatmentSchedules(
        widget.treatment!.id,
      );
      if (mounted) setState(() => _schedules = schedules);
    } catch (_) {
      if (mounted) setState(() => _schedules = const []);
    } finally {
      if (mounted) setState(() => _loadingSchedules = false);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteAll() async {
    final hasTreatment = widget.treatment != null;
    final ok = await _confirm(
      'Supprimer',
      hasTreatment
          ? 'Supprimer "${widget.item.medication.name}" du stock et arrêter le traitement actif ?'
          : 'Supprimer "${widget.item.medication.name}" de votre stock ?',
    );
    if (!ok || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      if (hasTreatment) {
        await ApiService.deleteTreatment(widget.treatment!.id);
      }
      await ApiService.deleteStock(widget.item.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Pill handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bouton fermer
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.cancel_outlined, size: 28),
                  ),
                ),
                const SizedBox(height: 16),

                // Nom du médicament
                Text(
                  widget.item.medication.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.medication.pharmaceuticalForm,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // Section stock
                _SectionHeader(
                  icon: Icons.inventory_2_outlined,
                  label: 'Stock',
                ),
                const SizedBox(height: 10),
                _InfoCard(
                  children: [
                    _InfoRow(
                      label: 'Quantité',
                      value:
                          '${widget.item.quantity} unité${widget.item.quantity != 1 ? 's' : ''}',
                    ),
                    const _Divider(),
                    _InfoRow(label: 'Lieu', value: widget.item.location),
                  ],
                ),

                // Section traitement
                if (widget.treatment != null) ...[
                  const SizedBox(height: 24),
                  _SectionHeader(
                    icon: Icons.alarm_outlined,
                    label: 'Traitement actif',
                    color: AppTheme.primaryPink,
                  ),
                  const SizedBox(height: 10),
                  _InfoCard(
                    children: [
                      if (widget.treatment!.frequency.isNotEmpty) ...[
                        _InfoRow(
                          label: 'Fréquence',
                          value: widget.treatment!.frequency,
                        ),
                        const _Divider(),
                      ],
                      _InfoRow(
                        label: 'Début',
                        value: _fmt(widget.treatment!.startDate),
                      ),
                      if (widget.treatment!.endDate != null) ...[
                        const _Divider(),
                        _InfoRow(
                          label: 'Fin',
                          value: _fmt(widget.treatment!.endDate!),
                        ),
                      ],
                      if (widget.treatment!.daysOfWeek.isNotEmpty) ...[
                        const _Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Text(
                                'Jours',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.black45),
                              ),
                              const Spacer(),
                              _DaysDisplay(
                                activeDays: widget.treatment!.daysOfWeek,
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Créneaux
                      if (_loadingSchedules) ...[
                        const _Divider(),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ] else if (_schedules != null &&
                          _schedules!.isNotEmpty) ...[
                        const _Divider(),
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'HEURE',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.black45,
                                        fontSize: 11,
                                        letterSpacing: 0.8,
                                      ),
                                ),
                              ),
                              Text(
                                'QUANTITÉ',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.black45,
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        for (final s in _schedules!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.timeOfDay,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ),
                                Text(
                                  '${s.quantity % 1 == 0 ? s.quantity.toInt() : s.quantity} unit.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ],

                if (widget.canEditStock) ...[
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => StockUpdateView(item: widget.item),
                        ),
                      );
                      if (updated == true && mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    child: const Text('Mettre à jour le stock'),
                  ),
                  const SizedBox(height: 8),
                  _DeleteButton(
                    label: widget.treatment != null
                        ? 'Supprimer le stock et le traitement'
                        : 'Supprimer du stock',
                    isLoading: _isDeleting,
                    onPressed: _deleteAll,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ---------------------------------------------------------------------------
// Petits widgets utilitaires du sheet
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    this.color = Colors.black87,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
          ),
          const Spacer(),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFF5F5F5));
  }
}

class _DaysDisplay extends StatelessWidget {
  const _DaysDisplay({required this.activeDays});

  final List<int> activeDays;

  static const _order = [1, 2, 3, 4, 5, 6, 0];
  static const _labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final active = activeDays.contains(_order[i]);
        return Container(
          margin: const EdgeInsets.only(left: 4),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryPink : const Color(0xFFEEEEEE),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _labels[i],
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : Colors.black38,
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.red,
                strokeWidth: 2,
              ),
            )
          : Text(label),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte "Ajouter un médicament"
// ---------------------------------------------------------------------------

class _AddMedicamentCard extends StatelessWidget {
  const _AddMedicamentCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppTheme.primaryPink,
        borderRadius: 18,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppTheme.softPink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'Ajouter un médicament / traitement',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Suivez un nouveau traitement, une vitamine ou un complément.',
              style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
