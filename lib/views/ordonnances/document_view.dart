import 'package:flutter/material.dart';

import 'package:frontend_cebmed/models/document_model.dart';
import 'package:frontend_cebmed/theme/app_theme.dart';
import 'package:frontend_cebmed/viewmodels/document_view_model.dart';

class DocumentView extends StatefulWidget {
  const DocumentView({super.key});

  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView> {
  final TextEditingController _searchController = TextEditingController();
  late final DocumentViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DocumentViewModel();
    _viewModel.loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _runAction(Future<DocumentActionResult?> future) async {
    final result = await future;
    if (!mounted || result == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _startUploadFlow(Future<PendingDocumentUpload?> future) async {
    final pending = await future;
    if (!mounted || pending == null) {
      return;
    }

    final nameController = TextEditingController(text: pending.suggestedName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nom du document'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nom',
              hintText: 'Ex: Ordonnance cardiologue',
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
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(
      _viewModel.confirmUpload(
        pending: pending,
        chosenName: nameController.text,
      ),
    );
  }

  Future<void> _editDocument(DocumentModel doc) async {
    final nameController = TextEditingController(text: doc.name);
    final typeController = TextEditingController(text: doc.type);
    final descriptionController = TextEditingController(text: doc.description ?? '');

    final validated = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le document'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
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
        );
      },
    );

    if (validated != true) {
      return;
    }

    await _runAction(
      _viewModel.updateDocument(
        id: doc.id,
        name: nameController.text,
        type: typeController.text,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      ),
    );
  }

  Future<void> _deleteDocument(DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le document'),
          content: Text('Supprimer "${doc.name}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await _runAction(_viewModel.deleteDocument(doc.id));
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
                      const SizedBox(width: 28),
                      Expanded(
                        child: Text(
                          'Mes ordonnances',
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
                    onRefresh: _viewModel.loadDocuments,
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                        Text('Nouvelle ordonnance ?', style: textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Importez ou scannez vos documents médicaux en un clic pour un suivi simplifié de vos traitements.',
                          style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryPink),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              _actionCard(
                                icon: Icons.qr_code_scanner,
                                title: 'Scanner l\'ordonnance',
                                subtitle: 'Camera téléphone',
                                onTap: _viewModel.isUploading
                                    ? null
                                    : () => _startUploadFlow(_viewModel.scanDocument()),
                              ),
                              const SizedBox(height: 10),
                              _actionCard(
                                icon: Icons.note_add_outlined,
                                title: 'Importer un fichier',
                                subtitle: 'PDF, JPG ou PNG (Max 10 Mo)',
                                onTap: _viewModel.isUploading
                                    ? null
                                    : () => _startUploadFlow(_viewModel.importDocument()),
                              ),
                            ],
                          ),
                        ),
                        if (_viewModel.isUploading) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                        ],
                        const SizedBox(height: 18),
                        TextField(
                          controller: _searchController,
                          onChanged: _viewModel.updateSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Rechercher un document...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: const Color(0xFFEAEAEA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_viewModel.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_viewModel.error != null)
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Erreur: ${_viewModel.error}',
                                  style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _viewModel.loadDocuments,
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          )
                        else if (_viewModel.filteredDocuments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'Aucun document trouvé',
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ..._viewModel.filteredDocuments.map((doc) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.softPink,
                                  child: Icon(
                                    doc.type == 'PDF' ? Icons.picture_as_pdf : Icons.image,
                                    color: AppTheme.primaryPink,
                                  ),
                                ),
                                title: Text(doc.name),
                                subtitle: Text(
                                  doc.description?.isNotEmpty == true
                                      ? doc.description!
                                      : 'Type: ${doc.type}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'share') {
                                      _runAction(_viewModel.shareDocument(doc));
                                    } else if (value == 'edit') {
                                      _editDocument(doc);
                                    } else if (value == 'delete') {
                                      _deleteDocument(doc);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'share', child: Text('Partager')),
                                    PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
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

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.softPink),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.softPink,
                child: Icon(icon, color: AppTheme.primaryPink),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

