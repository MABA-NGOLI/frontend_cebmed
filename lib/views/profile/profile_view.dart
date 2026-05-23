import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/profile_view_model.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    required this.onLogout,
  });

  final VoidCallback onLogout;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _editPhotoUrl() async {
    final controller = TextEditingController(text: _viewModel.pictureUrl ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la photo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Coller une URL image (https://...)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _viewModel.setPictureFromUrl(controller.text);
  }

  Future<void> _save() async {
    final ok = await _viewModel.saveProfile();
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis a jour')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.errorMessage ?? 'Mise a jour impossible')),
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

        final fullName = '${_viewModel.firstName} ${_viewModel.lastName}'.trim();

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Profil'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _editPhotoUrl,
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.white,
                        backgroundImage: _viewModel.pictureUrl == null
                            ? null
                            : NetworkImage(_viewModel.pictureUrl!),
                        child: _viewModel.pictureUrl == null
                            ? const Icon(Icons.person, size: 52, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName.isEmpty ? 'Utilisateur' : fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _viewModel.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _editPhotoUrl,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier la photo'),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD8D8D8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COORDONNEES',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          const Text('Prenom'),
                          TextFormField(
                            initialValue: _viewModel.firstName,
                            readOnly: true,
                          ),
                          const SizedBox(height: 10),
                          const Text('Nom'),
                          TextFormField(
                            initialValue: _viewModel.lastName,
                            readOnly: true,
                          ),
                          const SizedBox(height: 10),
                          const Text('Email'),
                          TextFormField(
                            initialValue: _viewModel.email,
                            readOnly: true,
                          ),
                          const SizedBox(height: 10),
                          const Text('Telephone'),
                          TextField(
                            controller: _viewModel.phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'Ex: +33 6 12 34 56 78',
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text('Adresse'),
                          TextField(
                            controller: _viewModel.addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Ex: 12 Rue de la Paix, 75002 Paris',
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _viewModel.isSaving ? null : _save,
                              child: Text(_viewModel.isSaving ? 'Enregistrement...' : 'Enregistrer'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: widget.onLogout,
                              child: const Text('Deconnexion'),
                            ),
                          ),
                        ],
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
