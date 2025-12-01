import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../game/renegade_dungeon_game.dart';

class GemShopScreen extends StatefulWidget {
  final RenegadeDungeonGame game;
  final VoidCallback onClose;

  const GemShopScreen({
    Key? key,
    required this.game,
    required this.onClose,
  }) : super(key: key);

  @override
  _GemShopScreenState createState() => _GemShopScreenState();
}

class _GemShopScreenState extends State<GemShopScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    // Wait a bit for initialization if needed, or just refresh state
    // In a real app, we might want to listen to a stream of products
    // For now, we assume service is initialized in game

    setState(() {
      _isLoading = false;
    });

    if (!widget.game.iapService.isAvailable) {
      setState(() {
        _errorMessage = 'Store not available';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Center(
        child: Container(
          width: 600,
          height: 500,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.diamond, color: Colors.cyanAccent, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'GEM SHOP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PixelFont', // Assuming font exists
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.amber))
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                      _errorMessage = null;
                                    });
                                    _loadProducts();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _buildProductGrid(),
              ),

              // Footer info
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black26,
                child: const Text(
                  'Purchases are processed securely by Google Play',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = widget.game.iapService.products;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.remove_shopping_cart,
                color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No products found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make sure you are connected to the internet',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(products[index]);
      },
    );
  }

  Widget _buildProductCard(ProductDetails product) {
    // Extract gem amount from title or ID if possible, otherwise hardcode for display based on ID
    int gemAmount = 0;
    Color cardColor = Colors.blueGrey;

    if (product.id.contains('10')) {
      gemAmount = 10;
      cardColor = Colors.blue[900]!;
    } else if (product.id.contains('50')) {
      gemAmount = 50;
      cardColor = Colors.purple[900]!;
    } else if (product.id.contains('150')) {
      gemAmount = 150;
      cardColor = Colors.orange[900]!;
    } else if (product.id.contains('500')) {
      gemAmount = 500;
      cardColor = Colors.red[900]!;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardColor.withOpacity(0.6), cardColor.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.diamond, color: Colors.cyanAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            '$gemAmount Gems',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              widget.game.iapService.buyProduct(product);
            },
            child: Text(
              product.price,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
