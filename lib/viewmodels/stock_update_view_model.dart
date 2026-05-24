import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class StockUpdateViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  String? successMessage;

  Future<bool> addStock({required int id, required int amount}) async {
    return _run(() => ApiService.addStock(id: id, amount: amount));
  }

  Future<bool> removeStock({required int id, required int amount}) async {
    return _run(() => ApiService.removeStock(id: id, amount: amount));
  }

  Future<bool> updateStock({
    required int id,
    int? quantity,
    String? location,
  }) async {
    return _run(() => ApiService.updateStock(id: id, quantity: quantity, location: location));
  }

  Future<bool> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    successMessage = null;
    notifyListeners();

    try {
      await action();
      successMessage = 'Stock mis à jour avec succès';
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
