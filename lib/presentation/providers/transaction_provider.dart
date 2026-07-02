import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/transaction_model.dart';
import '../../core/database/db_helper.dart';

class TransactionState {
  final List<TransactionModel> allTransactions;
  final List<TransactionModel> recentTransactions;
  final double mainBalance;
  final double bankBalance; // Menyimpan Saldo Rekening Manual (Running Balance)
  final double currentMonthIncome;
  final double currentMonthExpense;
  final bool isLoading;

  const TransactionState({
    this.allTransactions = const [],
    this.recentTransactions = const [],
    this.mainBalance = 0.0,
    this.bankBalance = 0.0,
    this.currentMonthIncome = 0.0,
    this.currentMonthExpense = 0.0,
    this.isLoading = false,
  });

  TransactionState copyWith({
    List<TransactionModel>? allTransactions,
    List<TransactionModel>? recentTransactions,
    double? mainBalance,
    double? bankBalance,
    double? currentMonthIncome,
    double? currentMonthExpense,
    bool? isLoading,
  }) {
    return TransactionState(
      allTransactions: allTransactions ?? this.allTransactions,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      mainBalance: mainBalance ?? this.mainBalance,
      bankBalance: bankBalance ?? this.bankBalance,
      currentMonthIncome: currentMonthIncome ?? this.currentMonthIncome,
      currentMonthExpense: currentMonthExpense ?? this.currentMonthExpense,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TransactionNotifier extends Notifier<TransactionState> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  TransactionState build() {
    Future.microtask(() => loadTransactions());
    return const TransactionState();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final results = await Future.wait([
        _dbHelper.getAllTransactions(),
        _dbHelper.getTransactionsByDateRange(sevenDaysAgo, now),
        _dbHelper.getLifetimeIncome(),
        _dbHelper.getLifetimeExpense(),
        _dbHelper.getTotalIncome(startOfMonth, endOfMonth),
        _dbHelper.getTotalExpense(startOfMonth, endOfMonth),
      ]);

      state = state.copyWith(
        allTransactions: results[0] as List<TransactionModel>,
        recentTransactions: results[1] as List<TransactionModel>,
        mainBalance: (results[2] as double) - (results[3] as double),
        bankBalance: prefs.getDouble('manual_bank_balance') ?? 0.0, // Muat dari penyimpanan lokal
        currentMonthIncome: results[4] as double,
        currentMonthExpense: results[5] as double,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint('Error loading transactions: $e');
    }
  }

  // Fungsi khusus untuk memperbarui Saldo Rekening secara langsung (Manual / Sinkronisasi)
  Future<void> updateBankBalance(double newBalance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('manual_bank_balance', newBalance);
    state = state.copyWith(bankBalance: newBalance);
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    state = state.copyWith(isLoading: true);
    await _dbHelper.insertTransaction(transaction);

    // --- SINKRONISASI SALDO REKENING OTOMATIS ---
    final prefs = await SharedPreferences.getInstance();
    double currentBank = prefs.getDouble('manual_bank_balance') ?? 0.0;
    if (transaction.type == 'income') {
      currentBank += transaction.amount;
    } else {
      currentBank -= transaction.amount;
    }
    await prefs.setDouble('manual_bank_balance', currentBank);
    
    await loadTransactions();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    state = state.copyWith(isLoading: true);
    
    // --- MENGHITUNG ULANG SELISIH SALDO REKENING ---
    final oldTxIndex = state.allTransactions.indexWhere((t) => t.id == transaction.id);
    if (oldTxIndex != -1) {
      final oldTx = state.allTransactions[oldTxIndex];
      final prefs = await SharedPreferences.getInstance();
      double currentBank = prefs.getDouble('manual_bank_balance') ?? 0.0;
      
      // Membalikkan efek transaksi lama
      if (oldTx.type == 'income') {
        currentBank -= oldTx.amount;
      } else {
        currentBank += oldTx.amount;
      }

      // Menerapkan efek transaksi baru
      if (transaction.type == 'income') {
        currentBank += transaction.amount;
      } else {
        currentBank -= transaction.amount;
      }
      
      await prefs.setDouble('manual_bank_balance', currentBank);
    }

    await _dbHelper.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    state = state.copyWith(isLoading: true);
    
    // --- KEMBALIKAN SALDO JIKA TRANSAKSI DIHAPUS ---
    final txIndex = state.allTransactions.indexWhere((t) => t.id == id);
    if (txIndex != -1) {
      final tx = state.allTransactions[txIndex];
      final prefs = await SharedPreferences.getInstance();
      double currentBank = prefs.getDouble('manual_bank_balance') ?? 0.0;
      
      if (tx.type == 'income') {
        currentBank -= tx.amount; // Uang masuk dihapus -> saldo berkurang
      } else {
        currentBank += tx.amount; // Uang keluar dihapus -> saldo kembali utuh
      }
      
      await prefs.setDouble('manual_bank_balance', currentBank);
    }

    await _dbHelper.deleteTransaction(id);
    await loadTransactions();
  }

  Future<void> clearAllData() async {
    state = state.copyWith(isLoading: true);
    await _dbHelper.clearAllData();
    
    // Reset juga saldo rekening saat reset data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('manual_bank_balance', 0.0);
    
    await loadTransactions();
  }
}

final transactionProvider = NotifierProvider<TransactionNotifier, TransactionState>(() {
  return TransactionNotifier();
});