import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:frontend_cebmed/models/document_model.dart';
import 'package:frontend_cebmed/services/api_service.dart';
import 'package:frontend_cebmed/theme/app_theme.dart';
import 'package:frontend_cebmed/viewmodels/document_view_model.dart';

class DocumentView extends StatefulWidget {
  const DocumentView({super.key, this.canUploadDocuments = true});

  final bool canUploadDocuments;

  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView> {
  final TextEditingController _searchController = TextEditingController();
  late final DocumentViewModel _viewModel;
  final DateFormat _documentDateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _viewModel = DocumentViewModel()..loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _runAction(Future<DocumentActionResult?> future) async {
    final result = await future;
    if (!mounted || result == null) return;
    final message = result.message;
    if (message == null || message.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _scanDocument() async {
    final pending = await _viewModel.scanDocument();
    if (!mounted || pending == null) return;
    await _confirmUpload(pending);
  }

  Future<void> _importDocument() async {
    final pending = await _viewModel.importDocument();
    if (!mounted || pending == null) return;
    await _confirmUpload(pending);
  }

  Future<void> _confirmUpload(PendingDocumentUpload pending) async {
    final controller = TextEditingController(text: pending.suggestedName);

    final shouldUpload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nom du document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom',
            hintText: 'Ex: Ordonnance cardiologie',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (shouldUpload != true) return;

    await _runAction(
      _viewModel.confirmUpload(pending: pending, chosenName: controller.text),
    );
  }

  // Télécharge le fichier puis tente de créer un lien partageable pour le QR code.
  Future<void> _openDocument(DocumentModel doc) async {
    try {
      final bytes = await ApiService.downloadDocument(
        id: doc.id,
        fileUrl: doc.fileUrl,
      );
      // Si le backend distant n'a pas encore la route share-link, le QR reste simplement indisponible.
      String? shareUrl;
      try {
        shareUrl = await ApiService.createDocumentShareLink(doc.id);
      } catch (_) {
        shareUrl = null;
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _DocumentPreviewView(
            title: doc.name,
            type: doc.type,
            bytes: bytes,
            sharePayload: shareUrl,
            onShare: () => _runAction(_viewModel.shareDocument(doc)),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir le document: $e')),
      );
    }
  }

  Future<void> _deleteDocument(DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
    if (confirm == true) await _runAction(_viewModel.deleteDocument(doc.id));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Mes ordonnances'),
            centerTitle: true,
            backgroundColor: AppTheme.softPink,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Nouvelle ordonnance ?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Importez ou scannez vos documents médicaux en un clic pour un suivi simplifié de vos traitements.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.25,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryPink),
                ),
                child: Column(
                  children: [
                    _UploadActionCard(
                      icon: Icons.document_scanner_outlined,
                      title: "Scanner l'ordonnance",
                      subtitle: 'Caméra téléphone',
                      onTap: _viewModel.isUploading ? null : _scanDocument,
                    ),
                    const SizedBox(height: 10),
                    _UploadActionCard(
                      icon: Icons.note_add_outlined,
                      title: 'Importer un fichier',
                      subtitle: 'PDF, JPG ou PNG (Max 10 Mo)',
                      onTap: _viewModel.isUploading ? null : _importDocument,
                    ),
                  ],
                ),
              ),
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
                        textAlign: TextAlign.center,
                      ),
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
                ..._viewModel.filteredDocuments.map(
                  (doc) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.softPink,
                        child: Icon(
                          doc.type == 'PDF'
                              ? Icons.picture_as_pdf
                              : Icons.image,
                          color: AppTheme.primaryPink,
                        ),
                      ),
                      title: Text(doc.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            doc.description?.isNotEmpty == true
                                ? doc.description!
                                : 'Type: ${doc.type}',
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ajouté le ${_documentDateFormat.format(doc.createdAt.toLocal())}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.black54),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Ouvrir',
                            icon: const Icon(Icons.visibility_outlined),
                            onPressed: () => _openDocument(doc),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'share') {
                                _runAction(_viewModel.shareDocument(doc));
                              } else if (v == 'delete') {
                                _deleteDocument(doc);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'share',
                                child: Text('Partager'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Supprimer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _UploadActionCard extends StatelessWidget {
  const _UploadActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primaryPink.withValues(alpha: 0.55),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppTheme.softPink,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryPink),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentPreviewView extends StatelessWidget {
  const _DocumentPreviewView({
    required this.title,
    required this.type,
    required this.bytes,
    required this.sharePayload,
    required this.onShare,
  });

  final String title;
  final String type;
  final List<int> bytes;
  final String? sharePayload;
  final Future<void> Function() onShare;

  bool get _isPdf =>
      bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;

  bool get _isImage {
    if (bytes.length < 4) return false;
    final png =
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    final jpg = bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
    return png || jpg;
  }

  String get _ext => _isPdf || type.toUpperCase() == 'PDF'
      ? 'pdf'
      : (_isImage ? 'jpg' : 'bin');

  Future<File> _tempFile() async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.$_ext',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _download(BuildContext context) async {
    try {
      final file = await _tempFile();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Téléchargé: ${file.path.split(Platform.pathSeparator).last}',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Échec du téléchargement: $e')));
    }
  }

  Future<void> _share(BuildContext context) async {
    try {
      await onShare();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Échec du partage: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = Uint8List.fromList(bytes);
    final preview = bytes.isEmpty
        ? const Center(child: Text('Document vide ou introuvable'))
        : (_isPdf || type.toUpperCase() == 'PDF')
        ? SfPdfViewer.memory(data)
        : _isImage
        ? Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.memory(data, fit: BoxFit.contain),
            ),
          )
        : Center(
            child: Text('Format non pris en charge (${type.toUpperCase()})'),
          );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(child: preview),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 170,
                  child: FilledButton.icon(
                    onPressed: () => _download(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryPink,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Télécharger'),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    tooltip: 'Partager',
                    onPressed: () => _share(context),
                    icon: const Icon(Icons.ios_share_outlined),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD9D9D9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppTheme.softBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 18,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Présentation en pharmacie\nPrésentez ce QR Code directement à votre pharmacie.',
                          style: TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: sharePayload == null
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'QR indisponible pour le moment',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : QrImageView(
                            data: sharePayload!,
                            version: QrVersions.auto,
                            size: 150,
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
