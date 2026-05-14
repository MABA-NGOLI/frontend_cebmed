import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document_model.dart';
import 'package:frontend_cebmed/services/api_service.dart';

class DocumentActionResult {
  const DocumentActionResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class PendingDocumentUpload {
  const PendingDocumentUpload({
    required this.fileName,
    required this.bytes,
    required this.suggestedName,
  });

  final String fileName;
  final List<int> bytes;
  final String suggestedName;
}

class DocumentViewModel extends ChangeNotifier {
  final ImagePicker _imagePicker = ImagePicker();

  bool isLoading = true;
  bool isUploading = false;
  String? error;
  List<DocumentModel> _documents = const [];
  String _searchQuery = '';

  List<DocumentModel> get documents => _documents;

  List<DocumentModel> get filteredDocuments {
    if (_searchQuery.isEmpty) {
      return _documents;
    }

    return _documents.where((doc) {
      return doc.name.toLowerCase().contains(_searchQuery) ||
          doc.type.toLowerCase().contains(_searchQuery) ||
          (doc.description?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  void updateSearchQuery(String value) {
    _searchQuery = value.trim().toLowerCase();
    notifyListeners();
  }

  Future<void> loadDocuments() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _documents = await ApiService.getDocuments();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<PendingDocumentUpload?> importDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final picked = result.files.first;
    if (picked.bytes == null && picked.path == null) {
      return null;
    }

    final bytes = picked.bytes ?? await File(picked.path!).readAsBytes();
    return PendingDocumentUpload(
      fileName: picked.name,
      bytes: bytes,
      suggestedName: _suggestNameFromFile(picked.name),
    );
  }

  Future<PendingDocumentUpload?> scanDocument() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (photo == null) {
      return null;
    }

    final bytes = await photo.readAsBytes();
    return PendingDocumentUpload(
      fileName: photo.name,
      bytes: bytes,
      suggestedName: 'Ordonnance',
    );
  }

  Future<DocumentActionResult> confirmUpload({
    required PendingDocumentUpload pending,
    required String chosenName,
  }) async {
    final cleanName = chosenName.trim();
    if (cleanName.isEmpty) {
      return const DocumentActionResult(
        success: false,
        message: 'Le nom du document est obligatoire',
      );
    }

    return _uploadNewDocument(
      fileName: pending.fileName,
      bytes: pending.bytes,
      defaultName: cleanName,
    );
  }

  Future<DocumentActionResult> updateDocument({
    required int id,
    required String name,
    required String type,
    String? description,
  }) async {
    try {
      await ApiService.updateDocument(
        id: id,
        name: name.trim(),
        type: type.trim(),
        description: description,
      );

      await loadDocuments();

      return const DocumentActionResult(
        success: true,
        message: 'Document modifié',
      );
    } catch (e) {
      return DocumentActionResult(
        success: false,
        message: 'Modification échouée: $e',
      );
    }
  }

  Future<DocumentActionResult> deleteDocument(int id) async {
    try {
      await ApiService.deleteDocument(id);
      await loadDocuments();

      return const DocumentActionResult(
        success: true,
        message: 'Document supprimé',
      );
    } catch (e) {
      return DocumentActionResult(
        success: false,
        message: 'Suppression échouée: $e',
      );
    }
  }

  Future<DocumentActionResult> shareDocument(DocumentModel doc) async {
    try {
      final bytes = await ApiService.downloadDocument(
        id: doc.id,
        fileUrl: doc.fileUrl,
      );

      final ext = doc.filePath.contains('.')
          ? doc.filePath.split('.').last.toLowerCase()
          : 'pdf';
      final mimeType = _mimeTypeFromExtension(ext);
      final safeName = doc.name.trim().isEmpty ? 'document_${doc.id}' : doc.name.trim();

      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: mimeType,
        name: '$safeName.$ext',
      );

      await Share.shareXFiles(
        [xFile],
        text: safeName,
      );

      return const DocumentActionResult(
        success: true,
        message: 'Partage ouvert',
      );
    } catch (e) {
      return DocumentActionResult(
        success: false,
        message: 'Partage échoué: $e',
      );
    }
  }

  String detectType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'PDF';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'IMAGE';
      default:
        return 'AUTRE';
    }
  }

  String _mimeTypeFromExtension(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  String _suggestNameFromFile(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index <= 0) {
      return fileName;
    }
    return fileName.substring(0, index);
  }

  Future<DocumentActionResult> _uploadNewDocument({
    required String fileName,
    required List<int> bytes,
    required String defaultName,
  }) async {
    isUploading = true;
    notifyListeners();

    try {
      await ApiService.createDocument(
        name: defaultName,
        type: detectType(fileName),
        description: null,
        fileName: fileName,
        bytes: bytes,
      );

      await loadDocuments();

      return const DocumentActionResult(
        success: true,
        message: 'Document ajouté avec succès',
      );
    } catch (e) {
      return DocumentActionResult(
        success: false,
        message: 'Ajout échoué: $e',
      );
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }
}


