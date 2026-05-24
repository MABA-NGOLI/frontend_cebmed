import 'package:flutter/foundation.dart';

import '../models/stock_model.dart';
import '../models/treatment_model.dart';
import '../services/api_service.dart';

class StockViewModel extends ChangeNotifier {
  bool isLoading = true;
  String? error;
  int attentionCount = 0;
  List<StockItem> items = const [];
  Map<int, TreatmentItem> activeTreatments = const {};

  Future<void> loadStock() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final summary = await ApiService.getStock();
      attentionCount = summary.count;
      items = summary.items;

      // Traitements : échec silencieux, le stock reste visible
      try {
        final treatments = await ApiService.getTreatments();
        activeTreatments = {
          for (final t in treatments.where((t) => t.status == 'ACTIVE'))
            t.medicationId: t,
        };
      } catch (_) {
        activeTreatments = const {};
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
