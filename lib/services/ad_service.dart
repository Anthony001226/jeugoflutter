import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;

  // Test Ad Unit IDs (use these during development)
  // IMPORTANT: Replace with real IDs before publishing to production
  static const String _androidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // Google Test ID
  static const String _iosInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910'; // Google Test ID

  /// Initialize the Google Mobile Ads SDK
  Future<void> initialize() async {
    // Skip on web and desktop platforms
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      print('⚠️ AdMob not supported on this platform');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      print('✅ AdMob initialized successfully');

      // Pre-load first interstitial ad
      _loadInterstitialAd();
    } catch (e) {
      print('⚠️ Error initializing AdMob: $e');
    }
  }

  /// Load an interstitial ad
  void _loadInterstitialAd() {
    // Skip on unsupported platforms
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    final adUnitId = Platform.isAndroid
        ? _androidInterstitialAdUnitId
        : _iosInterstitialAdUnitId;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Interstitial ad loaded');
          _interstitialAd = ad;
          _isInterstitialReady = true;

          // Set up callbacks
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('📺 Interstitial ad shown');
            },
            onAdDismissedFullScreenContent: (ad) {
              print('✅ Interstitial ad dismissed');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;

              // Pre-load next ad
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ Interstitial ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;

              // Try loading another ad
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('❌ Interstitial ad failed to load: $error');
          _interstitialAd = null;
          _isInterstitialReady = false;

          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 30), () {
            _loadInterstitialAd();
          });
        },
      ),
    );
  }

  /// Show interstitial ad (e.g., on player death)
  /// Returns a Future that completes when the ad is closed or fails
  Future<void> showInterstitial() async {
    // Skip on unsupported platforms
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      print('⚠️ Ads not supported on this platform, skipping...');
      return;
    }

    if (_isInterstitialReady && _interstitialAd != null) {
      try {
        await _interstitialAd!.show();
        // The ad callback will handle cleanup and preloading next ad
      } catch (e) {
        print('⚠️ Error showing interstitial ad: $e');
        // Clean up and preload
        _interstitialAd?.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
        _loadInterstitialAd();
      }
    } else {
      print('⚠️ Interstitial ad not ready yet, skipping...');
      // Try loading if not already loading
      if (_interstitialAd == null) {
        _loadInterstitialAd();
      }
    }
  }

  /// Clean up when service is disposed
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialReady = false;
  }

  /// Check if an ad is ready to show
  bool get isAdReady => _isInterstitialReady;
}
