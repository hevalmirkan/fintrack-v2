import '../entities/installment.dart';

abstract class IInstallmentRepository {
  Stream<List<Installment>> getInstallments();
  Future<void> addInstallment(Installment installment,
      {int initiallyPaidCount = 0});
  Future<void> payInstallment({
    required String installmentId,
    required InstallmentPaymentType paymentType,
  });
  Future<void> deleteInstallment(String id);
}
