import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;

  // Product IDs - Must match Google Play Console
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

  // Callback to give gems to player
  final Function(int) onGemsPurchased;

  IAPService({required this.onGemsPurchased});

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();

    if (_isAvailable) {
      final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
      _subscription = purchaseUpdated.listen(_onPurchaseUpdate, onDone: () {
        _subscription?.cancel();
      }, onError: (error) {
        print('⚠️ IAP Error: $error');
      });

      await _loadProducts();
    } else {
      print('⚠️ Store not available');
    }
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(_kIds);

    if (response.notFoundIDs.isNotEmpty) {
      print('⚠️ Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    print('✅ Loaded ${_products.length} products');

    // Sort by price if possible, or by ID logic
    _products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
  }

  void buyProduct(ProductDetails product) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    if (Platform.isAndroid) {
      // Consumable (can be bought multiple times)
      _iap.buyConsumable(purchaseParam: purchaseParam);
    } else {
      _iap.buyConsumable(purchaseParam: purchaseParam);
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI if needed
        print('⏳ Purchase pending...');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          print('❌ Purchase error: ${purchaseDetails.error!}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            _deliverProduct(purchaseDetails);
          } else {
            print('❌ Invalid purchase verification');
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: Verify on backend for real production apps
    // For this school project, we assume it's valid if it comes from the store
    return true;
  }

  void _deliverProduct(PurchaseDetails purchaseDetails) {
    print('💎 Delivering product: ${purchaseDetails.productID}');

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
