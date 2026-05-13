import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/document_model.dart';
import '../services/api_service.dart';

class DocumentActionResult {
  const DocumentActionResult({required this.success, required this.message});

  final bool success;
  final String message;
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

  Future<DocumentActionResult?> importDocument() async {
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
      return const DocumentActionResult(
        success: false,
        message: 'Fichier invalide',
      );
    }

    final bytes = picked.bytes ?? await File(picked.path!).readAsBytes();

    return _uploadNewDocument(
      fileName: picked.name,
      bytes: bytes,
      defaultName: picked.name,
    );
  }

  Future<DocumentActionResult?> scanDocument() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (photo == null) {
      return null;
    }

    final bytes = await photo.readAsBytes();

    return _uploadNewDocument(
      fileName: photo.name,
      bytes: bytes,
      defaultName: 'Ordonnance ${DateTime.now().toIso8601String()}',
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
