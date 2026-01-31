import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/installment.dart';
import '../../domain/repositories/i_installment_repository.dart';
import '../../../transactions/domain/entities/transaction_enums.dart';

class InstallmentRepositoryImpl implements IInstallmentRepository {
  final FirebaseFirestore _firestore;
  final String? _userId;

  InstallmentRepositoryImpl({
    required FirebaseFirestore firestore,
    required String? userId,
  })  : _firestore = firestore,
        _userId = userId;

  static const String _mockUserId = 'user_dev_01';

  CollectionReference<Map<String, dynamic>> _getCollection() {
    final effectiveUserId = _userId ?? _mockUserId;
    return _firestore
        .collection('users')
        .doc(effectiveUserId)
        .collection('installments');
  }

  CollectionReference<Map<String, dynamic>> _getTransactionsCollection() {
    final effectiveUserId = _userId ?? _mockUserId;
    return _firestore
        .collection('users')
        .doc(effectiveUserId)
        .collection('transactions');
  }

  @override
  Stream<List<Installment>> getInstallments() {
    if (_userId == null) return const Stream.empty();
    return _getCollection()
        .orderBy('nextDueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  @override
  Future<void> addInstallment(Installment installment,
      {int initiallyPaidCount = 0}) async {
    Map<String, dynamic> data = _toFirestore(installment);

    if (initiallyPaidCount > 0) {
      int paid = initiallyPaidCount;
      if (paid > installment.totalInstallments) {
        paid = installment.totalInstallments;
      }

      int totalCalculated = 0;
      for (int i = 0; i < paid; i++) {
        bool isLast = (i + 1) == installment.totalInstallments;
        if (isLast) {
          totalCalculated = installment.totalAmount;
        } else {
          totalCalculated += installment.amountPerInstallment;
        }
      }

      int newRemaining = installment.totalAmount - totalCalculated;

      // Update Date
      DateTime newNextDueDate = installment.startDate;
      for (int i = 0; i < paid; i++) {
        newNextDueDate = _incrementMonth(newNextDueDate);
      }

      data['paidInstallments'] = paid;
      data['remainingAmount'] = newRemaining;
      data['nextDueDate'] = Timestamp.fromDate(newNextDueDate);
    }

    await _getCollection().add(data);
  }

  @override
  Future<void> deleteInstallment(String id) async {
    await _getCollection().doc(id).delete();
  }

  @override
  Future<void> payInstallment({
    required String installmentId,
    required InstallmentPaymentType paymentType,
  }) async {
    final installmentRef = _getCollection().doc(installmentId);
    final transactionRef = _getTransactionsCollection().doc();

    await _firestore.runTransaction((transaction) async {
      // 1. Read Installment
      final snapshot = await transaction.get(installmentRef);
      if (!snapshot.exists) {
        throw Exception('Installment not found');
      }

      // 2. AGGRESSIVE CASTING: Read fields directly from snapshot
      final data = snapshot.data()!;

      // Cast EVERY numeric field to int via num
      final int totalAmount = (data['totalAmount'] as num).toInt();
      final int remainingAmount = (data['remainingAmount'] as num).toInt();
      final int totalInstallments = (data['totalInstallments'] as num).toInt();
      final int paidInstallments = (data['paidInstallments'] as num).toInt();
      final int amountPerInstallment =
          (data['amountPerInstallment'] as num).toInt();
      final String title = data['title'] ?? '';
      final DateTime startDate = (data['startDate'] as Timestamp).toDate();
      final DateTime nextDueDate = (data['nextDueDate'] as Timestamp).toDate();

      // Validation
      if (paidInstallments >= totalInstallments) {
        throw Exception('Installment already fully paid');
      }

      // 3. Calculate Payment Amount
      int paymentAmount;
      bool isLastPayment = (paidInstallments + 1) == totalInstallments;

      if (isLastPayment) {
        paymentAmount = remainingAmount;
      } else {
        paymentAmount = amountPerInstallment;
      }

      // 4. Update Installment Data
      final newPaidCount = paidInstallments + 1;
      final newRemaining = remainingAmount - paymentAmount;
      final newNextDueDate = _incrementMonth(nextDueDate);

      // 5. ATOMIC WRITES
      transaction.update(installmentRef, {
        'paidInstallments': newPaidCount,
        'remainingAmount': newRemaining,
        'nextDueDate': Timestamp.fromDate(newNextDueDate),
      });

      // 6. Create Transaction (ONLY IF payNow)
      if (paymentType == InstallmentPaymentType.payNow) {
        final transactionData = {
          'assetId': null,
          'title': '$title - Taksit Ödemesi',
          'category': 'Taksit / Borç',
          'quantityMinor': 0,
          'pricePerUnitMinor': 0,
          'feeMinor': 0,
          'totalMinor': paymentAmount,
          'date': Timestamp.fromDate(DateTime.now()),
          'type': TransactionType.expense.name,
          'metadata': {
            'installmentId': installmentId,
            'installmentIndex': paidInstallments + 1,
          },
        };
        transaction.set(transactionRef, transactionData);
      }
    });
  }

  DateTime _incrementMonth(DateTime date) {
    int newYear = date.year;
    int newMonth = date.month + 1;
    if (newMonth > 12) {
      newYear++;
      newMonth = 1;
    }

    int daysInNewMonth = _getDaysInMonth(newYear, newMonth);
    int newDay = date.day;
    if (newDay > daysInNewMonth) {
      newDay = daysInNewMonth;
    }

    return DateTime(
        newYear, newMonth, newDay, date.hour, date.minute, date.second);
  }

  int _getDaysInMonth(int year, int month) {
    if (month == 2) {
      final bool isLeapYear =
          (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const daysInMonth = [31, -1, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonth[month - 1];
  }

  // Mapper
  Map<String, dynamic> _toFirestore(Installment installment) {
    return {
      'title': installment.title,
      'totalAmount': installment.totalAmount,
      'remainingAmount': installment.remainingAmount,
      'totalInstallments': installment.totalInstallments,
      'paidInstallments': installment.paidInstallments,
      'amountPerInstallment': installment.amountPerInstallment,
      'startDate': Timestamp.fromDate(installment.startDate),
      'nextDueDate': Timestamp.fromDate(installment.nextDueDate),
    };
  }

  Installment _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Installment(
      id: doc.id,
      title: data['title'] ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toInt() ?? 0,
      remainingAmount: (data['remainingAmount'] as num?)?.toInt() ?? 0,
      totalInstallments: (data['totalInstallments'] as num?)?.toInt() ?? 1,
      paidInstallments: (data['paidInstallments'] as num?)?.toInt() ?? 0,
      amountPerInstallment:
          (data['amountPerInstallment'] as num?)?.toInt() ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      nextDueDate: (data['nextDueDate'] as Timestamp).toDate(),
    );
  }
}
