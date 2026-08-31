import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_model.dart';

/// Holds cart/sale context when resuming a pending transaction in POS.
class PosResumeState {
  final CartState? initialCart;
  final String? resumeSaleId;
  final String? resumeDraftId;

  const PosResumeState({
    this.initialCart,
    this.resumeSaleId,
    this.resumeDraftId,
  });

  bool get hasResume => initialCart != null;

  PosResumeState copyWith({
    CartState? initialCart,
    String? resumeSaleId,
    String? resumeDraftId,
    bool clear = false,
  }) {
    if (clear) return const PosResumeState();
    return PosResumeState(
      initialCart: initialCart ?? this.initialCart,
      resumeSaleId: resumeSaleId ?? this.resumeSaleId,
      resumeDraftId: resumeDraftId ?? this.resumeDraftId,
    );
  }
}

class PosResumeNotifier extends StateNotifier<PosResumeState> {
  PosResumeNotifier() : super(const PosResumeState());

  void setResume({
    required CartState cart,
    String? saleId,
    String? draftId,
  }) {
    state = PosResumeState(
      initialCart: cart,
      resumeSaleId: saleId,
      resumeDraftId: draftId,
    );
  }

  void clear() => state = const PosResumeState();
}

final posResumeProvider =
    StateNotifierProvider<PosResumeNotifier, PosResumeState>(
  (ref) => PosResumeNotifier(),
);

final openDraftsRefreshProvider = StateProvider<int>((ref) => 0);

/// Tracks the local draft id autosaved from the active POS cart session.
final activePosDraftIdProvider = StateProvider<String?>((ref) => null);
