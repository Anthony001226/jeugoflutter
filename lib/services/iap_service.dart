import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  InAppPurchase? _iap;

  static const String gemPack10 = 'gem_pack_10';
  static const String gemPack50 = 'gem_pack_50';
  static const String gemPack150 = 'gem_pack_150';
  static const String gemPack500 = 'gem_pack_500';

  static const Set<String> _kIds = {
    gemPack10,
    gemPack50,
    gemPack150,
    gemPack500,
  };

  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final Function(int) onGemsPurchased;

  IAPService({required this.onGemsPurchased});

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    if (kIsWeb ||
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _isAvailable = false;
      return;
    }

    try {
      _iap = InAppPurchase.instance;
      _isAvailable = await _iap!.isAvailable();

      if (_isAvailable) {
        final Stream<List<PurchaseDetails>> purchaseUpdated =
            _iap!.purchaseStream;
        _subscription = purchaseUpdated.listen(_onPurchaseUpdate, onDone: () {
          _subscription?.cancel();
        }, onError: (error) {
        });

        await _loadProducts();
      } else {
      }
    } catch (e) {
      _isAvailable = false;
    }
  }

  Future<void> _loadProducts() async {
    if (_iap == null) return;

    final ProductDetailsResponse response =
        await _iap!.queryProductDetails(_kIds);

    if (response.notFoundIDs.isNotEmpty) {
    }

    _products = response.productDetails;

    _products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
  }

  void buyProduct(ProductDetails product) {
    if (_iap == null) return;

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    if (Platform.isAndroid) {
      _iap!.buyConsumable(purchaseParam: purchaseParam);
    } else {
      _iap!.buyConsumable(purchaseParam: purchaseParam);
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            _deliverProduct(purchaseDetails);
          } else {
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap!.completePurchase(purchaseDetails);
        }
      }
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    return true;
  }

  void _deliverProduct(PurchaseDetails purchaseDetails) {

    int gemsToAdd = 0;
    switch (purchaseDetails.productID) {
      case gemPack10:
        gemsToAdd = 10;
        break;
      case gemPack50:
        gemsToAdd = 50;
        break;
      case gemPack150:
        gemsToAdd = 150;
        break;
      case gemPack500:
        gemsToAdd = 500;
        break;
    }

    if (gemsToAdd > 0) {
      onGemsPurchased(gemsToAdd);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
