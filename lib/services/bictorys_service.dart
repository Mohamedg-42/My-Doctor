// lib/services/bictorys_service.dart
//
// Service d'intégration de la passerelle de paiement Bictorys
// Support Mobile Money (Wave, Orange Money, MTN MoMo, Moov) et Cartes bancaires.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../providers/app_provider.dart';

/// Type de paiement supporté par Bictorys
enum BictorysPaymentType {
  waveMoney('wave_money', 'Wave'),
  orangeMoney('orange_money', 'Orange Money'),
  mtnMoney('mtn_money', 'MTN Mobile Money'),
  moov('moov', 'Moov Money'),
  card('card', 'Carte bancaire (Visa / Mastercard)');

  final String apiValue;
  final String label;
  const BictorysPaymentType(this.apiValue, this.label);
}

/// Résultat d'une transaction ou initialisation de paiement Bictorys
class BictorysPaymentResult {
  final bool isSuccess;
  final String reference;
  final String? transactionId;
  final String? chargeId;
  final String? paymentLink;
  final String? qrCode;
  final String? responseType; // MobilePaymentObject, CheckoutLinkObject
  final String message;
  final double amount;
  final bool isSandbox;
  final Map<String, dynamic>? rawResponse;

  BictorysPaymentResult({
    required this.isSuccess,
    required this.reference,
    this.transactionId,
    this.chargeId,
    this.paymentLink,
    this.qrCode,
    this.responseType,
    required this.message,
    required this.amount,
    this.isSandbox = true,
    this.rawResponse,
  });

  /// Référence unique affichable pour le reçu patient
  String get displayReference =>
      transactionId ?? chargeId ?? reference;
}

class BictorysService {
  static final BictorysService _instance = BictorysService._internal();
  static BictorysService get instance => _instance;

  BictorysService._internal();

  /// Clé publique Bictorys
  String _publicKey = AppConstants.bictorysPublicKey;
  String get publicKey => _publicKey;

  /// URL de l'API (Sandbox par défaut)
  String _baseUrl = AppConstants.bictorysTestApiUrl;
  String get baseUrl => _baseUrl;

  /// Mode Sandbox ou Production
  bool _isSandbox = true;
  bool get isSandbox => _isSandbox;

  /// Configuration personnalisée (ex: passage en production)
  void configure({
    required String publicKey,
    bool isSandbox = false,
  }) {
    _publicKey = publicKey;
    _isSandbox = isSandbox;
    _baseUrl = isSandbox
        ? AppConstants.bictorysTestApiUrl
        : AppConstants.bictorysLiveApiUrl;
    debugPrint('⚙️ [BictorysService] Configuration mise à jour (Sandbox: $_isSandbox)');
  }

  /// Mappe le mode de paiement interne My-Doctor vers le type Bictorys
  String mapMethodToBictorys(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.wave:
        return BictorysPaymentType.waveMoney.apiValue;
      case PaymentMethod.orangeMoney:
        return BictorysPaymentType.orangeMoney.apiValue;
      case PaymentMethod.mtnMoney:
        return BictorysPaymentType.mtnMoney.apiValue;
      case PaymentMethod.moovMoney:
        return BictorysPaymentType.moov.apiValue;
      case PaymentMethod.visa:
      case PaymentMethod.mastercard:
      case PaymentMethod.djamo:
        return BictorysPaymentType.card.apiValue;
    }
  }

  /// Initialise un paiement via l'API Bictorys
  Future<BictorysPaymentResult> initiatePayment({
    required double amount,
    required String paymentReference,
    String? paymentType,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String country = AppConstants.bictorysDefaultCountry,
    String currency = AppConstants.bictorysDefaultCurrency,
    String? successRedirectUrl,
    String? errorRedirectUrl,
  }) async {
    final cleanPhone = customerPhone.trim().startsWith('+')
        ? customerPhone.trim()
        : '+225${customerPhone.trim().replaceAll(RegExp(r'\s+'), '')}';

    final uriString = paymentType != null && paymentType.isNotEmpty
        ? '$_baseUrl/pay/v1/charges?payment_type=$paymentType'
        : '$_baseUrl/pay/v1/charges';

    final headers = {
      'X-Api-Key': _publicKey,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final body = jsonEncode({
      'amount': amount.round(),
      'currency': currency,
      'country': country,
      'paymentReference': paymentReference,
      'successRedirectUrl': successRedirectUrl ?? 'https://mydoctor.ci/payment/success',
      'errorRedirectUrl': errorRedirectUrl ?? 'https://mydoctor.ci/payment/error',
      'customerObject': {
        'name': customerName.trim().isNotEmpty ? customerName.trim() : 'Patient My Doctor',
        'phone': cleanPhone,
        if (customerEmail != null && customerEmail.trim().isNotEmpty)
          'email': customerEmail.trim(),
      },
    });

    debugPrint('🚀 [BictorysService] Envoi requête vers $uriString');

    try {
      final response = await http
          .post(Uri.parse(uriString), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      debugPrint('📥 [BictorysService] Statut HTTP: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final type = data['type'] as String?;
        final txId = data['transactionId'] as String?;
        final chargeId = data['chargeId'] as String?;
        final link = data['link'] as String?;
        final qrCode = data['qrCode'] as String?;

        debugPrint('✅ [BictorysService] Charge initiée avec succès. TxId: $txId, Type: $type');

        return BictorysPaymentResult(
          isSuccess: true,
          reference: paymentReference,
          transactionId: txId,
          chargeId: chargeId,
          paymentLink: link,
          qrCode: qrCode,
          responseType: type,
          message: 'Paiement initié avec succès via Bictorys.',
          amount: amount,
          isSandbox: _isSandbox,
          rawResponse: data,
        );
      } else {
        debugPrint('⚠️ [BictorysService] Erreur API Bictorys: ${response.body}');
        Map<String, dynamic>? errorJson;
        try {
          errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}

        final errorMsg = errorJson?['details'] ??
            errorJson?['title'] ??
            errorJson?['message'] ??
            'Erreur serveur Bictorys (${response.statusCode})';

        return BictorysPaymentResult(
          isSuccess: false,
          reference: paymentReference,
          message: errorMsg.toString(),
          amount: amount,
          isSandbox: _isSandbox,
          rawResponse: errorJson,
        );
      }
    } catch (e) {
      debugPrint('❌ [BictorysService] Exception réseau Bictorys: $e');
      return BictorysPaymentResult(
        isSuccess: false,
        reference: paymentReference,
        message: 'Impossible de joindre la passerelle Bictorys : $e',
        amount: amount,
        isSandbox: _isSandbox,
      );
    }
  }

  /// Vérifie le statut d'une transaction Bictorys
  Future<String?> checkTransactionStatus(String transactionId) async {
    try {
      final uri = Uri.parse('$_baseUrl/pay/v1/transactions/$transactionId/status');
      final response = await http.get(uri, headers: {
        'X-Api-Key': _publicKey,
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['status'] as String?;
      }
    } catch (e) {
      debugPrint('⚠️ [BictorysService] Erreur vérification statut: $e');
    }
    return null;
  }
}
