import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service to manage Google Mobile Ads integration.
class AdManager {
  static final AdManager instance = AdManager._internal();

  AdManager._internal();

  // Test Ad Unit IDs from Google
  static const String _androidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _androidRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  static const String _iosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _iosRewardedId = 'ca-app-pub-3940256099942544/1712485313';

  /// Get the appropriate Banner Ad Unit ID based on platform.
  /// REPLACE these test IDs with your production Ad Unit IDs from Google AdMob.
  String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _androidBannerId : _iosBannerId;
    }
    // Production AdMob Banner Unit ID
    return Platform.isAndroid 
        ? 'ca-app-pub-3714262893174384/8829355041' 
        : _iosBannerId;
  }

  /// Get the appropriate Rewarded Ad Unit ID based on platform.
  /// REPLACE these test IDs with your production Ad Unit IDs from Google AdMob.
  String get rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _androidRewardedId : _iosRewardedId;
    }
    // TODO: Put your production AdMob Rewarded Unit IDs here
    return Platform.isAndroid 
        ? _androidRewardedId // Replace with real Android Rewarded ID
        : _iosRewardedId;    // Replace with real iOS Rewarded ID
  }

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  /// Preload the Rewarded Ad so it is ready when the user requests a solution.
  void loadRewardedAd({VoidCallback? onAdLoaded}) {
    if (_isRewardedAdLoading || _rewardedAd != null) return;

    _isRewardedAdLoading = true;
    if (kDebugMode) {
      print('AdManager: Loading Rewarded Ad...');
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (kDebugMode) {
            print('AdManager: Rewarded Ad loaded successfully.');
          }
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          onAdLoaded?.call();

          // Set full screen content callbacks
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              if (kDebugMode) {
                print('AdManager: Rewarded Ad dismissed.');
              }
              ad.dispose();
              _rewardedAd = null;
              // Preload the next rewarded ad immediately
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              if (kDebugMode) {
                print('AdManager: Rewarded Ad failed to show: $error');
              }
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) {
            print('AdManager: Rewarded Ad failed to load: $error');
          }
          _rewardedAd = null;
          _isRewardedAdLoading = false;
          // Retry loading after a delay (e.g. 10 seconds)
          Future.delayed(const Duration(seconds: 10), () => loadRewardedAd());
        },
      ),
    );
  }

  /// Show the rewarded ad and trigger [onRewardEarned] if the user completes it.
  /// If no ad is loaded, runs [onAdNotReady] so the user experience isn't blocked.
  void showRewardedAd({
    required VoidCallback onRewardEarned,
    required VoidCallback onAdNotReady,
  }) {
    if (_rewardedAd == null) {
      if (kDebugMode) {
        print('AdManager: Rewarded ad not loaded. Directing straight to content.');
      }
      onAdNotReady();
      loadRewardedAd(); // Try loading for next time
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        if (kDebugMode) {
          print('AdManager: User earned reward: ${reward.amount} ${reward.type}');
        }
        onRewardEarned();
      },
    );
  }

  /// Create and load a Banner Ad. The caller is responsible for disposing it.
  BannerAd createBannerAd({
    required VoidCallback onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailedToLoad(error);
        },
      ),
    )..load();
  }
}
