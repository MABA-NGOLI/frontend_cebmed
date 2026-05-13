import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AppointmentSectionLabel extends StatelessWidget {
  const AppointmentSectionLabel({super.key, required this.text, this.compact = false});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class AppointmentTextField extends StatelessWidget {
  const AppointmentTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.compact = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 48.0 : 52.0;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 16 : 18, color: Colors.black54),
            SizedBox(width: compact ? 8 : 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black38),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentPickerField extends StatelessWidget {
  const AppointmentPickerField({
    super.key,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: compact ? 48 : 52,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEAEA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: compact ? 16 : 18, color: Colors.black54),
            SizedBox(width: compact ? 8 : 10),
            Flexible(
              child: Text(
                hasValue ? value : placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: hasValue ? Colors.black87 : Colors.black45,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsultationTypeField extends StatelessWidget {
  const ConsultationTypeField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.compact = false,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool compact;

  String _labelForType(String type) {
    switch (type) {
      case 'PRESENTIAL':
        return 'Présentiel';
      case 'VIDEO':
        return 'Visio';
      case 'PHONE':
        return 'Téléphone';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeValue = options.contains(value) ? value : options.first;

    return Container(
      height: compact ? 48 : 52,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.medical_services_outlined, size: compact ? 16 : 18, color: Colors.black54),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeValue,
                isExpanded: true,
                icon: const Icon(Icons.expand_more, color: Colors.black54),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                items: options
                    .map((type) => DropdownMenuItem(value: type, child: Text(_labelForType(type))))
                    .toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.enabled,
    required this.onToggle,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.compact = false,
  });

  final bool enabled;
  final ValueChanged<bool> onToggle;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 14, compact ? 10 : 12, compact ? 12 : 14, compact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E9E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 26 : 30,
                height: compact ? 26 : 30,
                decoration: const BoxDecoration(color: AppTheme.softPink, shape: BoxShape.circle),
                child: Icon(Icons.notifications, size: compact ? 14 : 16, color: AppTheme.primaryPink),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(child: Text('Activer le rappel', style: textTheme.titleMedium)),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: AppTheme.softPink,
                activeTrackColor: AppTheme.primaryPink,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          Text('DÉLAI DE RAPPEL', style: textTheme.bodyMedium?.copyWith(color: Colors.black54, fontSize: compact ? 12 : null)),
          SizedBox(height: compact ? 8 : 10),
          Wrap(
            spacing: compact ? 5 : 6,
            runSpacing: compact ? 5 : 6,
            children: options.map((delay) {
              final isSelected = selected == delay;
              return ChoiceChip(
                label: Text(delay),
                selected: isSelected,
                onSelected: (_) => onSelect(delay),
                selectedColor: AppTheme.primaryPink,
                backgroundColor: AppTheme.softBlue,
                labelStyle: textTheme.bodyMedium?.copyWith(fontSize: compact ? 11 : 12, color: isSelected ? AppTheme.white : AppTheme.black),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class SaveAppointmentButton extends StatelessWidget {
  const SaveAppointmentButton({super.key, required this.isSaving, required this.onPressed, this.compact = false});

  final bool isSaving;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 46 : 50,
      child: FilledButton.icon(
        onPressed: isSaving ? null : onPressed,
        icon: isSaving
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.save_outlined, size: compact ? 16 : 18),
        label: Text(
          isSaving ? 'Enregistrement...' : 'Enregistrer le rendez-vous',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryPink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
        ),
      ),
    );
  }
}
