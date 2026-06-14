import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/caregiver_hub_view_model.dart';

class CaregiverAddProfileView extends StatefulWidget {
  const CaregiverAddProfileView({super.key, required this.viewModel});

  final CaregiverHubViewModel viewModel;

  @override
  State<CaregiverAddProfileView> createState() =>
      _CaregiverAddProfileViewState();
}

class _CaregiverAddProfileViewState extends State<CaregiverAddProfileView> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await widget.viewModel.redeemNewCode(_codeController.text);
    if (!mounted) return;

    if (ok) {
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil ajouté avec succès')),
      );
      return;
    }

    if (widget.viewModel.errorMessage != null &&
        widget.viewModel.errorMessage!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.viewModel.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final profiles = widget.viewModel.profiles;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Ajout profil'),
            centerTitle: true,
            backgroundColor: AppTheme.softPink,
            foregroundColor: Colors.black,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Associer un nouveau profil',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saisissez le code de partage unique fourni par l\'utilisateur.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Code de partage',
                      hintText: 'Ex: A8B2CD',
                      filled: true,
                      fillColor: const Color(0xFFF2F2F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.viewModel.isSubmittingCode
                          ? null
                          : _submit,
                      child: widget.viewModel.isSubmittingCode
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Valider le code'),
                    ),
                  ),
                  if (profiles.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          'Personnes aidées',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        if (widget.viewModel.isLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...profiles.map((profile) {
                      final isActive =
                          profile.patientId ==
                          widget.viewModel.activeProfile?.patientId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.primaryPink
                                : const Color(0xFFE5E5E5),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.softPink,
                            backgroundImage:
                                profile.picture == null ||
                                    profile.picture!.isEmpty
                                ? null
                                : NetworkImage(profile.picture!),
                            child:
                                profile.picture == null ||
                                    profile.picture!.isEmpty
                                ? const Icon(Icons.person_outline)
                                : null,
                          ),
                          title: Text(profile.fullName),
                          subtitle: Text(profile.status),
                          trailing: isActive
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryPink,
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () async {
                            await widget.viewModel.selectProfile(profile);
                            if (!context.mounted) return;
                            Navigator.of(context).pop(true);
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
