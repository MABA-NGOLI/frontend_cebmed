import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/reminder_timeline_view_model.dart';

class ReminderTimelineView extends StatefulWidget {
  const ReminderTimelineView({super.key, this.initialDay});

  final DateTime? initialDay;

  @override
  State<ReminderTimelineView> createState() => _ReminderTimelineViewState();
}

class _ReminderTimelineViewState extends State<ReminderTimelineView> {
  late final ReminderTimelineViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ReminderTimelineViewModel(initialDay: widget.initialDay);
    _vm.initialize();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text('Mes rappels', style: Theme.of(context).textTheme.titleMedium),
          backgroundColor: AppTheme.background,
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildWeekNav(context),
            _buildDaySelector(context),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            _buildAdherenceBanner(context),
            Expanded(
              child: _vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _vm.entries.isEmpty
                      ? _buildEmpty(context)
                      : _buildTimeline(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigation semaine ──────────────────────────────────────────────────────

  Widget _buildWeekNav(BuildContext context) {
    final start = _vm.weekStart;
    final end = start.add(const Duration(days: 6));
    final label =
        '${DateFormat('d MMM', 'fr_FR').format(start)} – ${DateFormat('d MMM', 'fr_FR').format(end)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _vm.goPreviousWeek,
            icon: const Icon(Icons.chevron_left),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          IconButton(
            onPressed: _vm.goNextWeek,
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ── Sélecteur de jour ────────────────────────────────────────────────────────

  Widget _buildDaySelector(BuildContext context) {
    const letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final days = _vm.weekDays;
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final day = days[i];
          final isSelected = _vm.isSameDay(day, _vm.selectedDay);
          final isToday = _vm.isSameDay(day, now);

          return GestureDetector(
            onTap: () => _vm.selectDay(day),
            child: Column(
              children: [
                Text(
                  letters[i],
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.primaryPink : Colors.black45,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.primaryPink : Colors.transparent,
                    border: isToday && !isSelected
                        ? Border.all(color: AppTheme.primaryPink, width: 1.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Builder(builder: (_) {
                  final dotColor = _vm.dotColorForDay(day);
                  if (dotColor == null) return const SizedBox(height: 6);
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.75)
                          : dotColor,
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Résumé d'adhérence semaine ───────────────────────────────────────────────

  Widget _buildAdherenceBanner(BuildContext context) {
    final taken = _vm.weekTakenCount;
    final total = _vm.weekTotalCount;

    if (total == 0) return const SizedBox.shrink();

    final allDone = taken == total;
    final ratio = taken / total;

    final Color barColor;
    if (allDone) {
      barColor = const Color(0xFF4CAF50);
    } else if (ratio >= 0.5) {
      barColor = const Color(0xFFFFB74D);
    } else {
      barColor = const Color(0xFFE57373);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: allDone ? const Color(0xFFEEF7EE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  allDone ? Icons.check_circle_outline : Icons.bar_chart_outlined,
                  size: 15,
                  color: barColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Cette semaine',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black45),
                ),
                const Spacer(),
                Text(
                  allDone ? 'Tout pris ✓' : '$taken / $total prises effectuées',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── État vide ────────────────────────────────────────────────────────────────

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none, size: 52, color: Colors.black26),
          const SizedBox(height: 12),
          Text('Aucun rappel ce jour',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black45)),
        ],
      ),
    );
  }

  // ── Timeline ─────────────────────────────────────────────────────────────────

  Widget _buildTimeline(BuildContext context) {
    final entries = _vm.entries;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: entries.length,
      itemBuilder: (context, i) => _buildTimelineItem(
        context,
        entries[i],
        isLast: i == entries.length - 1,
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    ReminderEntry entry, {
    required bool isLast,
  }) {
    final Color dotColor;
    final Color cardBg;
    final Color textColor;

    if (entry.isValidated) {
      dotColor = const Color(0xFF4CAF50);
      cardBg = const Color(0xFFEEF7EE);
      textColor = Colors.black54;
    } else if (entry.isMissed) {
      dotColor = const Color(0xFFE57373);
      cardBg = const Color(0xFFFFF0F0);
      textColor = Colors.black45;
    } else if (entry.isPast) {
      dotColor = Colors.black26;
      cardBg = const Color(0xFFF3F3F3);
      textColor = Colors.black38;
    } else if (entry.isNext) {
      dotColor = AppTheme.primaryPink;
      cardBg = AppTheme.softPink;
      textColor = Colors.black87;
    } else {
      dotColor = const Color(0xFFCCCCCC);
      cardBg = Colors.white;
      textColor = Colors.black87;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heure
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                entry.timeLabel,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: entry.isPast ? Colors.black38 : Colors.black87,
                ),
              ),
            ),
          ),
          // Point + ligne
          SizedBox(
            width: 22,
            child: Column(
              children: [
                _buildDot(entry, dotColor),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFFE0E0E0)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Carte cliquable
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: (entry.isPast || entry.isValidated)
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x10000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showIntakeModal(context, entry),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          if (entry.isValidated) ...[
                            const Icon(Icons.check_circle_outline,
                                color: Color(0xFF4CAF50), size: 16),
                            const SizedBox(width: 8),
                          ] else if (entry.isMissed) ...[
                            const Icon(Icons.cancel_outlined,
                                color: Color(0xFFE57373), size: 16),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              entry.medicationName,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: entry.isNext
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: entry.isPast ? Colors.black26 : Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(ReminderEntry entry, Color color) {
    final size = entry.isNext ? 16.0 : 13.0;
    final topMargin = entry.isNext ? 8.0 : 9.5;

    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.only(top: topMargin, left: (22 - size) / 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (entry.isValidated || entry.isMissed || entry.isNext) ? color : Colors.white,
        border: Border.all(color: color, width: entry.isNext ? 2 : 1.5),
      ),
      // ✓ uniquement pour les prises validées
      child: entry.isValidated
          ? const Icon(Icons.check, size: 8, color: Colors.white)
          : entry.isMissed
              ? const Icon(Icons.close, size: 8, color: Colors.white)
              : null,
    );
  }

  void _showIntakeModal(BuildContext context, ReminderEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IntakeDetailSheet(
        entry: entry,
        onValidate: () => _vm.validateEntry(entry.intakeId),
      ),
    );
  }
}

// ── Modale détail prise ────────────────────────────────────────────────────────

class _IntakeDetailSheet extends StatefulWidget {
  const _IntakeDetailSheet({required this.entry, required this.onValidate});

  final ReminderEntry entry;
  final Future<void> Function() onValidate;

  @override
  State<_IntakeDetailSheet> createState() => _IntakeDetailSheetState();
}

class _IntakeDetailSheetState extends State<_IntakeDetailSheet> {
  bool _isValidating = false;
  bool _validated = false;

  @override
  void initState() {
    super.initState();
    _validated = widget.entry.isValidated;
  }

  Future<void> _handleValidate() async {
    setState(() => _isValidating = true);
    try {
      await widget.onValidate();
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        _validated = true;
      });
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // minutesUntil > 0 : prise dans le futur · < 0 : prise passée
    final minutesUntil = widget.entry.scheduledAt.difference(now).inMinutes;
    final notDone = !_validated && !widget.entry.isValidated && !widget.entry.isMissed;
    final tooEarly  = notDone && minutesUntil > 720;           // > 12h avant
    final canValidate = notDone && minutesUntil >= -300 && minutesUntil <= 720; // fenêtre [-5h, +12h]
    final tooLate   = notDone && minutesUntil < -300;          // > 5h après

    final iconBg = _validated
        ? const Color(0xFFEEF7EE)
        : (widget.entry.isValidated ? const Color(0xFFEEF7EE) : AppTheme.softPink);
    final iconColor = _validated || widget.entry.isValidated
        ? const Color(0xFF4CAF50)
        : AppTheme.primaryPink;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Icône
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(
              _validated ? Icons.check_circle_outline : Icons.medication_outlined,
              color: iconColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          // Nom
          Text(
            widget.entry.medicationName,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Lignes détail
          _buildRow(context, 'Heure prévue', widget.entry.timeLabel),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          if (widget.entry.dosage.isNotEmpty) ...[
            _buildRow(context, 'Dosage', widget.entry.dosage),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ],
          _buildRow(
            context,
            'Statut',
            _validated
                ? 'Prise effectuée'
                : (widget.entry.isValidated
                    ? 'Prise effectuée'
                    : (widget.entry.isMissed
                        ? 'Prise manquée'
                        : (widget.entry.isPast ? 'Non prise' : 'À prendre'))),
            valueColor: (_validated || widget.entry.isValidated)
                ? const Color(0xFF4CAF50)
                : (widget.entry.isMissed
                    ? const Color(0xFFE57373)
                    : (widget.entry.isPast ? Colors.black38 : Colors.black87)),
          ),
          const SizedBox(height: 20),
          // Zone action
          if (_validated || widget.entry.isValidated)
            _buildConfirmedBadge(context)
          else if (widget.entry.isMissed)
            Text(
              'Cette prise a été manquée',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFFE57373)),
            )
          else if (canValidate)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isValidating ? null : _handleValidate,
                child: _isValidating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Valider la prise'),
              ),
            )
          else if (tooEarly)
            _buildTooEarlyMessage(context, minutesUntil)
          else if (tooLate)
            _buildTooLateMessage(context),
          if (widget.entry.note != null && widget.entry.note!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Note',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black45)),
            ),
            const SizedBox(height: 6),
            Text(
              widget.entry.note!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmedBadge(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline,
            color: Color(0xFF4CAF50), size: 22),
        const SizedBox(width: 8),
        Text('Prise confirmée',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: const Color(0xFF4CAF50))),
      ],
    );
  }

  Widget _buildTooLateMessage(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.lock_outline, color: Colors.black38, size: 28),
        const SizedBox(height: 8),
        Text(
          'Délai dépassé\nValidation possible jusqu\'à 5h après la prise',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildTooEarlyMessage(BuildContext context, int minutesUntil) {
    final hours = minutesUntil ~/ 60;
    final mins = minutesUntil % 60;
    final timeStr = hours > 0
        ? 'dans ${hours}h${mins > 0 ? mins.toString().padLeft(2, '0') : ''}'
        : 'dans ${mins}min';

    return Column(
      children: [
        const Icon(Icons.lock_clock_outlined, color: Colors.black38, size: 28),
        const SizedBox(height: 8),
        Text(
          'Validation disponible 12h avant la prise\n($timeStr)',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black45)),
          const Spacer(),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  )),
        ],
      ),
    );
  }
}
