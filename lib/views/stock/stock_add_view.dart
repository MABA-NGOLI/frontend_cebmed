import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/stock_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/stock_add_view_model.dart';

class StockAddView extends StatefulWidget {
  const StockAddView({super.key});

  @override
  State<StockAddView> createState() => _StockAddViewState();
}

class _StockAddViewState extends State<StockAddView> {
  late final StockAddViewModel _viewModel;
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final List<TextEditingController> _slotQuantityControllers = [
    TextEditingController(text: '1'),
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = StockAddViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    for (final c in _slotQuantityControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSlot() {
    _viewModel.addScheduleSlot();
    _slotQuantityControllers.add(TextEditingController(text: '1'));
  }

  void _removeSlot(int index) {
    _viewModel.removeScheduleSlot(index);
    _slotQuantityControllers[index].dispose();
    _slotQuantityControllers.removeAt(index);
  }

  Future<void> _onSubmit() async {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showSnack('Quantité invalide', isError: true);
      return;
    }
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      _showSnack('Veuillez renseigner un lieu de stockage', isError: true);
      return;
    }

    final slotQuantities = _slotQuantityControllers
        .map((c) => double.tryParse(c.text.trim()) ?? 1.0)
        .toList();

    final ok = await _viewModel.createStock(
      quantity: quantity,
      location: location,
      slotQuantities: slotQuantities,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _showSnack(_viewModel.error ?? 'Erreur lors de la création', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _displayDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) _viewModel.setStartDate(picked);
  }

  Future<void> _pickEndDate() async {
    final initial = _viewModel.endDate ??
        _viewModel.startDate.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _viewModel.startDate,
      lastDate: DateTime(2035),
    );
    if (picked != null) _viewModel.setEndDate(picked);
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
                          'Ajouter un médicament',
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
                      Text('Sélection & Période', style: textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        'Configurez les détails de base de votre nouveau traitement.',
                        style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),

                      // Barre de recherche
                      TextField(
                        controller: _searchController,
                        onChanged: _viewModel.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un médicament...',
                          hintStyle: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            color: Colors.black38,
                          ),
                          prefixIcon: const Icon(Icons.search, color: Colors.black45),
                          suffixIcon: const Icon(
                            Icons.qr_code_scanner_outlined,
                            color: Colors.black45,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFEAEAEA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Résultats de recherche
                      if (_viewModel.isSearching)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        ..._viewModel.searchResults.map(
                          (med) => _SearchResultTile(
                            med: med,
                            onTap: () {
                              _searchController.clear();
                              _viewModel.selectMedication(med);
                            },
                          ),
                        ),

                      // Contenu après sélection
                      if (_viewModel.selectedMedication != null) ...[
                        _SelectedMedicationCard(
                          med: _viewModel.selectedMedication!,
                          onClear: _viewModel.clearSelection,
                        ),
                        const SizedBox(height: 20),

                        // Détails du stock
                        _StockDetailsCard(
                          quantityController: _quantityController,
                          locationController: _locationController,
                        ),
                        const SizedBox(height: 12),

                        // Toggle traitement
                        _TreatmentToggleRow(
                          value: _viewModel.isTreatment,
                          onChanged: _viewModel.toggleTreatment,
                        ),

                        // Formulaire traitement
                        if (_viewModel.isTreatment) ...[
                          const SizedBox(height: 12),

                          // Dates
                          _DatesCard(
                            startDate: _viewModel.startDate,
                            endDate: _viewModel.endDate,
                            hasEndDate: _viewModel.hasEndDate,
                            displayDate: _displayDate,
                            onPickStart: _pickStartDate,
                            onToggleEndDate: _viewModel.toggleHasEndDate,
                            onPickEnd: _pickEndDate,
                          ),
                          const SizedBox(height: 16),

                          // Jours de la semaine
                          _DaySelectorRow(
                            selectedDays: _viewModel.selectedDays,
                            onToggle: _viewModel.toggleDay,
                            reminderText: _viewModel.reminderText,
                          ),
                          const SizedBox(height: 16),

                          // Créneaux horaires
                          _ScheduleSlotsCard(
                            medicationName: _viewModel.selectedMedication!.name,
                            frequency: _viewModel.frequency,
                            slotTimes: _viewModel.scheduleSlotTimes,
                            slotQuantityControllers: _slotQuantityControllers,
                            onTimeUpdate: _viewModel.updateSlotTime,
                            onAddSlot: _addSlot,
                            onRemoveSlot: _removeSlot,
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Bouton de validation
                        FilledButton(
                          onPressed: _viewModel.isSubmitting ? null : _onSubmit,
                          child: _viewModel.isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _viewModel.isTreatment
                                      ? 'Ajouter au stock et au traitement'
                                      : 'Ajouter au stock',
                                ),
                        ),
                        const SizedBox(height: 20),
                      ],
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

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        color: Colors.black38,
      ),
      filled: true,
      fillColor: const Color(0xFFEAEAEA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets privés
// ---------------------------------------------------------------------------

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.med, required this.onTap});

  final MedicationSearchResult med;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (med.pharmaceuticalForm.isNotEmpty)
                    Text(
                      med.pharmaceuticalForm,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _SelectedMedicationCard extends StatelessWidget {
  const _SelectedMedicationCard({required this.med, required this.onClear});

  final MedicationSearchResult med;
  final VoidCallback onClear;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.cancel_outlined, size: 24, color: Colors.black54),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Sélectionné',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppTheme.softBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.name, style: textTheme.bodyLarge),
                    if (med.pharmaceuticalForm.isNotEmpty)
                      Text(
                        med.pharmaceuticalForm,
                        style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockDetailsCard extends StatelessWidget {
  const _StockDetailsCard({
    required this.quantityController,
    required this.locationController,
  });

  final TextEditingController quantityController;
  final TextEditingController locationController;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.inventory_2_outlined,
      title: 'Détails du stock',
      child: Column(
        children: [
          TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration('Quantité'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: locationController,
            decoration: _inputDecoration('Lieu de stockage'),
          ),
        ],
      ),
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

class _TreatmentToggleRow extends StatelessWidget {
  const _TreatmentToggleRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          const Icon(Icons.alarm_outlined, color: AppTheme.primaryPink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text("C'est un traitement", style: textTheme.bodyLarge),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryPink,
          ),
        ],
      ),
    );
  }
}

class _DatesCard extends StatelessWidget {
  const _DatesCard({
    required this.startDate,
    required this.endDate,
    required this.hasEndDate,
    required this.displayDate,
    required this.onPickStart,
    required this.onToggleEndDate,
    required this.onPickEnd,
  });

  final DateTime startDate;
  final DateTime? endDate;
  final bool hasEndDate;
  final String Function(DateTime) displayDate;
  final VoidCallback onPickStart;
  final ValueChanged<bool> onToggleEndDate;
  final VoidCallback onPickEnd;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date de début', style: textTheme.bodyLarge),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onPickStart,
            child: _datePill(context, displayDate(startDate)),
          ),
          const SizedBox(height: 4),
          Text(
            '* Champ obligatoire',
            style: textTheme.bodyMedium?.copyWith(color: Colors.black45, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('Date de fin', style: textTheme.bodyLarge)),
              Switch(
                value: hasEndDate,
                onChanged: onToggleEndDate,
                activeThumbColor: AppTheme.primaryPink,
              ),
            ],
          ),
          if (hasEndDate) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onPickEnd,
              child: _datePill(
                context,
                endDate != null ? displayDate(endDate!) : 'Sélectionner une date',
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '* Optionnel',
            style: textTheme.bodyMedium?.copyWith(color: Colors.black45, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _datePill(BuildContext context, String label) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Text(label, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _DaySelectorRow extends StatelessWidget {
  const _DaySelectorRow({
    required this.selectedDays,
    required this.onToggle,
    required this.reminderText,
  });

  final List<int> selectedDays;
  final ValueChanged<int> onToggle;
  final String reminderText;

  // Ordre d'affichage : Lun → Dim (0=Dim à la fin)
  static const _order = [1, 2, 3, 4, 5, 6, 0];
  static const _labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = _order[i];
            final selected = selectedDays.contains(day);
            return GestureDetector(
              onTap: () => onToggle(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryPink : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryPink, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppTheme.primaryPink,
                  ),
                ),
              ),
            );
          }),
        ),
        if (reminderText.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            reminderText,
            style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      ],
    );
  }
}

class _ScheduleSlotsCard extends StatelessWidget {
  const _ScheduleSlotsCard({
    required this.medicationName,
    required this.frequency,
    required this.slotTimes,
    required this.slotQuantityControllers,
    required this.onTimeUpdate,
    required this.onAddSlot,
    required this.onRemoveSlot,
  });

  final String medicationName;
  final String frequency;
  final List<String> slotTimes;
  final List<TextEditingController> slotQuantityControllers;
  final void Function(int index, String time) onTimeUpdate;
  final VoidCallback onAddSlot;
  final void Function(int index) onRemoveSlot;

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
          // En-tête : nom + fréquence
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  medicationName,
                  style: textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (frequency.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  frequency,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),

          // En-têtes colonnes
          Row(
            children: [
              Expanded(
                child: Text(
                  'HEURE',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.black45,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'QUANTITÉ',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.black45,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 8),

          // Lignes de créneaux
          for (int i = 0; i < slotTimes.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  // Heure
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final parts = slotTimes[i].split(':');
                        final initial = TimeOfDay(
                          hour: int.tryParse(parts[0]) ?? 8,
                          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                        );
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: initial,
                          builder: (ctx, child) => MediaQuery(
                            data: MediaQuery.of(ctx)
                                .copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          onTimeUpdate(
                            i,
                            '${picked.hour.toString().padLeft(2, '0')}:'
                            '${picked.minute.toString().padLeft(2, '0')}',
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(slotTimes[i], style: textTheme.bodyMedium),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.expand_more,
                              size: 16,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Quantité
                  Expanded(
                    child: TextField(
                      controller: i < slotQuantityControllers.length
                          ? slotQuantityControllers[i]
                          : null,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        suffixText: 'unit.',
                        suffixStyle: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFEAEAEA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Supprimer
                  GestureDetector(
                    onTap: slotTimes.length > 1 ? () => onRemoveSlot(i) : null,
                    child: Icon(
                      Icons.remove_circle_outline,
                      size: 22,
                      color: slotTimes.length > 1
                          ? Colors.red.shade300
                          : Colors.black26,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 4),
          // Bouton ajout créneau
          GestureDetector(
            onTap: onAddSlot,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline,
                      color: AppTheme.primaryPink, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Ajouter un créneau',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryPink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
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
              Icon(icon, color: AppTheme.primaryPink, size: 20),
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
