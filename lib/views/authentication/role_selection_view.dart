import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum UserRole {
  patient,
  caregiver,
}

class RoleSelectionView extends StatelessWidget {
  const RoleSelectionView({
    super.key,
    required this.onSelectRole,
  });

  final ValueChanged<UserRole> onSelectRole;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              const SizedBox(height: 64),
              Text(
                'Quel est votre role?',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 28),
              _RoleTile(
                title: 'Patient',
                logoPath: 'assets/images/logo.png',
                onTap: () => onSelectRole(UserRole.patient),
              ),
              const SizedBox(height: 22),
              _RoleTile(
                title: 'Aidant',
                logoPath: 'assets/images/logo_two.png',
                logoOnRight: true,
                logoSize: 56,
                onTap: () => onSelectRole(UserRole.caregiver),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.title,
    required this.logoPath,
    required this.onTap,
    this.logoOnRight = false,
    this.logoSize = 48,
  });

  final String title;
  final String logoPath;
  final VoidCallback onTap;
  final bool logoOnRight;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x22000000)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              if (!logoOnRight) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    logoPath,
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium,
                ),
              ),
              if (logoOnRight) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    logoPath,
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
