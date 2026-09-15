import 'package:flutter_test/flutter_test.dart';
import 'package:allo_docteur/core/constants/app_constants.dart';
import 'package:allo_docteur/providers/app_provider.dart';
import 'package:allo_docteur/services/bictorys_service.dart';

void main() {
  group('BictorysService Integration & Configuration Tests', () {
    test('BictorysService instance initializes with test_public key and sandbox URL', () {
      final service = BictorysService.instance;

      expect(service.publicKey, equals(AppConstants.bictorysPublicKey));
      expect(
        service.publicKey,
        equals(
          'test_public-1f408b1c-a65b-421a-bd8b-703b7cdfca1e.IbcwtwZHxjD0DzWDsS5Oc9idxdq3lruXFzl0JXCM4dlW3VfDa1j6kv2GS8S4wFrB',
        ),
      );
      expect(service.baseUrl, equals(AppConstants.bictorysTestApiUrl));
      expect(service.isSandbox, isTrue);
    });

    test('mapMethodToBictorys correctly maps internal PaymentMethod to Bictorys API types', () {
      final service = BictorysService.instance;

      expect(service.mapMethodToBictorys(PaymentMethod.wave), equals('wave_money'));
      expect(service.mapMethodToBictorys(PaymentMethod.orangeMoney), equals('orange_money'));
      expect(service.mapMethodToBictorys(PaymentMethod.mtnMoney), equals('mtn_money'));
      expect(service.mapMethodToBictorys(PaymentMethod.moovMoney), equals('moov'));
      expect(service.mapMethodToBictorys(PaymentMethod.visa), equals('card'));
      expect(service.mapMethodToBictorys(PaymentMethod.mastercard), equals('card'));
      expect(service.mapMethodToBictorys(PaymentMethod.djamo), equals('card'));
    });

    test('BictorysPaymentType enum has valid API values and human-readable labels', () {
      expect(BictorysPaymentType.waveMoney.apiValue, equals('wave_money'));
      expect(BictorysPaymentType.waveMoney.label, equals('Wave'));

      expect(BictorysPaymentType.orangeMoney.apiValue, equals('orange_money'));
      expect(BictorysPaymentType.orangeMoney.label, equals('Orange Money'));

      expect(BictorysPaymentType.mtnMoney.apiValue, equals('mtn_money'));
      expect(BictorysPaymentType.mtnMoney.label, equals('MTN Mobile Money'));

      expect(BictorysPaymentType.moov.apiValue, equals('moov'));
      expect(BictorysPaymentType.moov.label, equals('Moov Money'));

      expect(BictorysPaymentType.card.apiValue, equals('card'));
      expect(BictorysPaymentType.card.label, contains('Carte bancaire'));
    });

    test('BictorysPaymentResult displays proper reference priority', () {
      final resWithTx = BictorysPaymentResult(
        isSuccess: true,
        reference: 'REF-001',
        transactionId: 'tx-uuid-1234',
        chargeId: 'charge-uuid-5678',
        message: 'Success',
        amount: 2500,
      );
      expect(resWithTx.displayReference, equals('tx-uuid-1234'));

      final resWithCharge = BictorysPaymentResult(
        isSuccess: true,
        reference: 'REF-002',
        chargeId: 'charge-uuid-9999',
        message: 'Success',
        amount: 2500,
      );
      expect(resWithCharge.displayReference, equals('charge-uuid-9999'));

      final resFallback = BictorysPaymentResult(
        isSuccess: false,
        reference: 'REF-003',
        message: 'Failed',
        amount: 2500,
      );
      expect(resFallback.displayReference, equals('REF-003'));
    });

    test('BictorysService can be reconfigured for production and sandbox', () {
      final service = BictorysService.instance;

      service.configure(
        publicKey: 'public-live-key-xyz',
        isSandbox: false,
      );
      expect(service.publicKey, equals('public-live-key-xyz'));
      expect(service.baseUrl, equals(AppConstants.bictorysLiveApiUrl));
      expect(service.isSandbox, isFalse);

      // Revert to sandbox
      service.configure(
        publicKey: AppConstants.bictorysPublicKey,
        isSandbox: true,
      );
      expect(service.publicKey, equals(AppConstants.bictorysPublicKey));
      expect(service.baseUrl, equals(AppConstants.bictorysTestApiUrl));
      expect(service.isSandbox, isTrue);
    });
  });
}
