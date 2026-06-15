import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/caregiver_profile_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/caregiver_hub_view_model.dart';
import '../../viewmodels/profile_view_model.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    required this.onLogout,
    required this.onChangeRole,
    this.isCaregiver = false,
    this.caregiverHub,
    this.onRequestAddProfile,
  });

  final VoidCallback onLogout;
  final VoidCallback onChangeRole;
  final bool isCaregiver;
  final CaregiverHubViewModel? caregiverHub;
  final VoidCallback? onRequestAddProfile;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _viewModel;
  List<CaregiverProfileModel> _myCaregivers = const [];
  bool _isLoadingCaregivers = false;
  final Set<int> _savingPermissionIds = <int>{};

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.initialize();
    if (!widget.isCaregiver) {
      _loadMyCaregivers();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // Charge les aidants autorisés à suivre ce patient pour afficher leurs permissions.
  Future<void> _loadMyCaregivers() async {
    setState(() {
      _isLoadingCaregivers = true;
    });

    try {
      final caregivers = await ApiService.getMyPatientCaregivers();
      if (!mounted) return;
      setState(() {
        _myCaregivers = caregivers;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _myCaregivers = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCaregivers = false;
        });
      }
    }
  }

  Future<void> _updateCaregiverPermission({
    required CaregiverProfileModel caregiver,
    bool? canViewAgenda,
    bool? canEditAgenda,
    bool? canViewDocuments,
    bool? canUploadDocuments,
  }) async {
    final relationId = caregiver.relationId;
    if (relationId == null) return;

    setState(() {
      _savingPermissionIds.add(relationId);
    });

    try {
      await ApiService.updateCaregiverPermissions(
        relationId: relationId,
        canViewAgenda: canViewAgenda,
        canEditAgenda: canEditAgenda,
        canViewDocuments: canViewDocuments,
        canUploadDocuments: canUploadDocuments,
      );
      await _loadMyCaregivers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mise à jour impossible : $e')));
    } finally {
      if (mounted) {
        setState(() {
          _savingPermissionIds.remove(relationId);
        });
      }
    }
  }

  Future<void> _save() async {
    final ok = await _viewModel.saveProfile();
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil mis a jour')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_viewModel.errorMessage ?? 'Mise a jour impossible'),
      ),
    );
  }

  Future<void> _editIdentity() async {
    final fullNameController = TextEditingController(
      text: '${_viewModel.firstName} ${_viewModel.lastName}'.trim(),
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier votre identite'),
          content: TextField(
            controller: fullNameController,
            decoration: const InputDecoration(labelText: 'Nom complet'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) return;
    if (!mounted) return;

    final fullName = fullNameController.text.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom complet est obligatoire')),
      );
      return;
    }
    final parts = fullName.split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1
        ? parts.sublist(1).join(' ')
        : parts.first;

    final ok = await _viewModel.updateIdentity(
      firstName: firstName,
      lastName: lastName,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Nom et prénom modifiés' : (_viewModel.errorMessage ?? 'Erreur'),
        ),
      ),
    );
  }

  Future<void> _editPhone() async {
    final countryCodes = <String>[
      '+33',
      '+1',
      '+44',
      '+32',
      '+41',
      '+49',
      '+34',
      '+39',
    ];
    final rawPhone = _viewModel.phoneController.text.trim();
    String selectedCode = '+33';
    String localNumber = rawPhone;
    final match = RegExp(r'^(\+\d{1,3})\s*(.*)$').firstMatch(rawPhone);
    if (match != null) {
      final code = match.group(1) ?? '+33';
      if (countryCodes.contains(code)) {
        selectedCode = code;
      }
      localNumber = (match.group(2) ?? '').trim();
    }
    final phoneController = TextEditingController(text: localNumber);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le telephone'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCode,
                    decoration: const InputDecoration(labelText: 'Pays'),
                    items: countryCodes
                        .map(
                          (code) => DropdownMenuItem<String>(
                            value: code,
                            child: Text(code),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedCode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telephone',
                      hintText: 'Ex: 6 12 34 56 78',
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) return;
    final trimmed = phoneController.text.trim();
    _viewModel.phoneController.text = trimmed.isEmpty
        ? ''
        : '$selectedCode $trimmed';
    await _save();
  }

  Future<void> _editAddress() async {
    final addressController = TextEditingController(
      text: _viewModel.addressController.text,
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier l\'adresse'),
          content: TextField(
            controller: addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              hintText: 'Ex: 12 Rue de la Paix, 75002 Paris',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) return;
    _viewModel.addressController.text = addressController.text.trim();
    await _save();
  }

  Future<void> _toggleNotifications(bool value) async {
    final ok = await _viewModel.setNotificationsEnabled(value);
    if (!mounted) return;
    if (!ok && value) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notifications desactivees'),
          content: const Text(
            'Pour activer les rappels, autorisez les notifications dans les paramètres de l\'application.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Plus tard'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ouvrir les paramètres'),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        await openAppSettings();
      }
    }
  }

  Future<void> _confirmDeleteHelpedProfile(
    CaregiverProfileModel profile,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce profil ?'),
        content: Text(
          'Vous ne suivrez plus ${profile.fullName}. Le compte patient ne sera pas supprimé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final ok =
        await widget.caregiverHub?.deleteProfileRelation(profile) ?? false;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Profil retiré de votre liste'
              : (widget.caregiverHub?.errorMessage ?? 'Suppression impossible'),
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le compte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cette action est definitive. Entrez votre mot de passe pour confirmer.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    if (passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mot de passe obligatoire')));
      return;
    }

    try {
      await ApiService.deleteMyAccount(
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Compte supprimé')));
      widget.onLogout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Échec suppression: $e')));
    }
  }

  // Affiche les permissions que le patient donne à chacun de ses aidants.
  Widget _buildMyCaregiversSection(BuildContext context) {
    if (_isLoadingCaregivers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_myCaregivers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.supervisor_account_outlined, size: 18),
            const SizedBox(width: 6),
            Text('MES AIDANTS', style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        ..._myCaregivers.map((caregiver) {
          final relationId = caregiver.relationId;
          final isSaving =
              relationId != null && _savingPermissionIds.contains(relationId);

          final activePermissions = [
            caregiver.canViewAgenda,
            caregiver.canEditAgenda,
            caregiver.canViewDocuments,
            caregiver.canUploadDocuments,
          ].where((enabled) => enabled).length;
          final permissionLabel = activePermissions == 0
              ? 'Aucune permission active'
              : '$activePermissions permission${activePermissions > 1 ? 's' : ''} active${activePermissions > 1 ? 's' : ''}';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.softPink,
                  backgroundImage:
                      caregiver.picture == null || caregiver.picture!.isEmpty
                      ? null
                      : NetworkImage(caregiver.picture!),
                  child: caregiver.picture == null || caregiver.picture!.isEmpty
                      ? const Icon(Icons.person_outline, size: 18)
                      : null,
                ),
                title: Text(
                  caregiver.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(permissionLabel),
                trailing: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                children: [
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Voir agenda'),
                    value: caregiver.canViewAgenda,
                    onChanged: isSaving
                        ? null
                        : (value) => _updateCaregiverPermission(
                            caregiver: caregiver,
                            canViewAgenda: value ?? false,
                          ),
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Modifier agenda'),
                    value: caregiver.canEditAgenda,
                    onChanged: isSaving
                        ? null
                        : (value) => _updateCaregiverPermission(
                            caregiver: caregiver,
                            canEditAgenda: value ?? false,
                          ),
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Voir documents'),
                    value: caregiver.canViewDocuments,
                    onChanged: isSaving
                        ? null
                        : (value) => _updateCaregiverPermission(
                            caregiver: caregiver,
                            canViewDocuments: value ?? false,
                          ),
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ajouter documents'),
                    value: caregiver.canUploadDocuments,
                    onChanged: isSaving
                        ? null
                        : (value) => _updateCaregiverPermission(
                            caregiver: caregiver,
                            canUploadDocuments: value ?? false,
                          ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final fullName = '${_viewModel.firstName} ${_viewModel.lastName}'
            .trim();

        ImageProvider? avatarProvider;
        if (_viewModel.localPicturePath != null &&
            _viewModel.localPicturePath!.isNotEmpty &&
            !kIsWeb) {
          avatarProvider = FileImage(File(_viewModel.localPicturePath!));
        } else if (_viewModel.pictureUrl != null &&
            _viewModel.pictureUrl!.isNotEmpty) {
          avatarProvider = NetworkImage(_viewModel.pictureUrl!);
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Profil'),
            centerTitle: true,
            backgroundColor: AppTheme.softPink,
            foregroundColor: Colors.black,
          ),
          body: SafeArea(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: _viewModel.pickPictureFromGallery,
                              child: CircleAvatar(
                                radius: 52,
                                backgroundColor: Colors.white,
                                backgroundImage: avatarProvider,
                                child: avatarProvider == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 52,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _viewModel.pickPictureFromGallery,
                                borderRadius: BorderRadius.circular(16),
                                child: Ink(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryPink,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName.isEmpty ? 'Utilisateur' : fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _viewModel.createdSinceLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _editIdentity,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 34),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Modifier'),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD8D8D8)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COORDONNEES',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Email'),
                          Text(
                            _viewModel.email,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Telephone'),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: _editPhone,
                                child: const Icon(Icons.edit, size: 16),
                              ),
                            ],
                          ),
                          Text(
                            _viewModel.phoneController.text.isEmpty
                                ? '-'
                                : _viewModel.phoneController.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Adresse'),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: _editAddress,
                                child: const Icon(Icons.edit, size: 16),
                              ),
                            ],
                          ),
                          Text(
                            _viewModel.addressController.text.isEmpty
                                ? '-'
                                : _viewModel.addressController.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (widget.isCaregiver &&
                              widget.caregiverHub != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE5E5E5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.group_outlined,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'AJOUTER UN PROFIL',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...widget.caregiverHub!.profiles.map(
                                    (p) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      leading: const Icon(
                                        Icons.person_outline,
                                        size: 18,
                                      ),
                                      title: Text(p.fullName),
                                      trailing: IconButton(
                                        tooltip: 'Supprimer ce profil',
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _confirmDeleteHelpedProfile(p),
                                      ),
                                      onTap: () async {
                                        await widget.caregiverHub!
                                            .selectProfile(p);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: widget.onRequestAddProfile,
                                      child: const Text('Ajouter'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (!widget.isCaregiver) ...[
                            const SizedBox(height: 12),
                            _buildMyCaregiversSection(context),
                            const SizedBox(height: 10),
                          ],
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Autoriser les notifications'),
                            value: _viewModel.notificationsEnabled,
                            onChanged: _toggleNotifications,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.onChangeRole,
                        child: const Text('Changer de rôle'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await ApiService.logout();
                          widget.onLogout();
                        },
                        child: const Text('Deconnexion'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _deleteAccount,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Supprimer le compte'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
