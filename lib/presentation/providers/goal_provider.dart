import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/goal_model.dart';
import '../../core/database/db_helper.dart';

// Penting: Import transaction_provider untuk melakukan update silang ke Saldo Rekening
import 'transaction_provider.dart';

class GoalState {
  final List<GoalModel> goals;
  final bool isLoading;

  const GoalState({this.goals = const [], this.isLoading = false});

  GoalState copyWith({List<GoalModel>? goals, bool? isLoading}) {
    return GoalState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GoalNotifier extends Notifier<GoalState> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  GoalState build() {
    Future.microtask(() => loadGoals());
    return const GoalState();
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true);
    final goals = await _dbHelper.getAllGoals();
    state = state.copyWith(goals: goals, isLoading: false);
  }

  Future<void> addGoal(GoalModel goal) async {
    await _dbHelper.insertGoal(goal);
    await loadGoals();
  }

  Future<void> updateGoalAmount(int goalId, double newSavedAmount) async {
    final goalIndex = state.goals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      final goal = state.goals[goalIndex];
      
      // Menghitung selisih uang (Positif = Isi Tabungan, Negatif = Tarik Dana Darurat)
      final difference = newSavedAmount - goal.savedAmount; 

      final updatedGoal = goal.copyWith(savedAmount: newSavedAmount);
      await _dbHelper.updateGoal(updatedGoal);

      // --- SINKRONISASI DENGAN SALDO REKENING (TRANSACTION PROVIDER) ---
      // Jika difference positif (nabung), saldo rekening berkurang.
      // Jika difference negatif (narik), saldo rekening bertambah.
      final currentBank = ref.read(transactionProvider).bankBalance;
      final newBankBalance = currentBank - difference;
      
      await ref.read(transactionProvider.notifier).updateBankBalance(newBankBalance);
    }
    
    await loadGoals();
  }

  Future<void> deleteGoal(int id) async {
    final goalIndex = state.goals.indexWhere((g) => g.id == id);
    if (goalIndex != -1) {
      final goal = state.goals[goalIndex];
      
      // Jika target dihapus dan masih ada uang yang tersimpan di dalamnya, 
      // otomatis kembalikan (refund) uang tersebut ke Saldo Rekening
      if (goal.savedAmount > 0) {
        final currentBank = ref.read(transactionProvider).bankBalance;
        final newBankBalance = currentBank + goal.savedAmount;
        await ref.read(transactionProvider.notifier).updateBankBalance(newBankBalance);
      }
    }

    await _dbHelper.deleteGoal(id);
    await loadGoals();
  }
}

final goalProvider = NotifierProvider<GoalNotifier, GoalState>(() => GoalNotifier());