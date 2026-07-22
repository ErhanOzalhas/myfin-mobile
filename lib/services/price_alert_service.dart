import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/price_alert.dart';
import 'market/market_service.dart';
import 'portfolio_profile_service.dart';

class PriceAlertService {
  PriceAlertService._();

  static final PriceAlertService instance = PriceAlertService._();

  static const _storageKey = 'myfin_price_alerts_v1';
  String get _profileStorageKey =>
      '$_storageKey::${PortfolioProfileService.instance.activeProfileId.value}';
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _checking;

  Future<void> initialize() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _notifications.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) return false;
    if (Platform.isIOS) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    if (Platform.isAndroid) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          true;
    }
    return true;
  }

  Future<List<PriceAlert>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw =
        preferences.getString(_profileStorageKey) ??
        (PortfolioProfileService.instance.activeProfileId.value ==
                PortfolioProfileService.defaultProfileId
            ? preferences.getString(_storageKey)
            : null);
    if (raw == null || raw.isEmpty) return <PriceAlert>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <PriceAlert>[];
      return decoded
          .whereType<Map>()
          .map((item) => PriceAlert.fromJson(Map<String, dynamic>.from(item)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return <PriceAlert>[];
    }
  }

  Future<void> save(PriceAlert alert) async {
    final alerts = await load();
    final index = alerts.indexWhere((item) => item.id == alert.id);
    if (index >= 0) {
      alerts[index] = alert;
    } else {
      alerts.insert(0, alert);
    }
    await _write(alerts);
  }

  Future<void> delete(String id) async {
    final alerts = await load()
      ..removeWhere((item) => item.id == id);
    await _write(alerts);
  }

  Future<void> setEnabled(PriceAlert alert, bool enabled) {
    return save(
      alert.copyWith(enabled: enabled, clearLastTriggeredAt: enabled),
    );
  }

  Future<void> checkNow() {
    return _checking ??= _checkNow().whenComplete(() => _checking = null);
  }

  Future<void> _checkNow() async {
    await initialize();
    final alerts = await load();
    if (alerts.isEmpty) return;
    final updated = <PriceAlert>[];

    for (final alert in alerts) {
      if (!alert.enabled) {
        updated.add(alert);
        continue;
      }
      try {
        final quote = await MarketService.instance.getQuote(
          alert.symbol,
          exchange: alert.exchange,
          forceRefresh: true,
        );
        final meetsCondition = alert.isTriggeredBy(quote.price);
        final wasOnOtherSide = alert.lastObservedPrice == null
            ? true
            : !alert.isTriggeredBy(alert.lastObservedPrice!);
        final shouldNotify =
            meetsCondition &&
            wasOnOtherSide &&
            (alert.repeat == PriceAlertRepeat.repeating ||
                alert.lastTriggeredAt == null);

        if (shouldNotify) {
          await _showNotification(alert, quote.price);
        }
        updated.add(
          alert.copyWith(
            enabled: shouldNotify && alert.repeat == PriceAlertRepeat.once
                ? false
                : alert.enabled,
            lastObservedPrice: quote.price,
            lastTriggeredAt: shouldNotify ? DateTime.now() : null,
          ),
        );
      } catch (error) {
        debugPrint('PRICE ALERT CHECK (${alert.symbol}) failed: $error');
        updated.add(alert);
      }
    }
    await _write(updated);
  }

  Future<void> _showNotification(PriceAlert alert, double currentPrice) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'myfin_price_alerts',
        'Fiyat Alarmları',
        channelDescription: 'MyFin varlık fiyat alarm bildirimleri',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'myfin_price_alerts',
      ),
    );
    final direction = alert.direction == PriceAlertDirection.above
        ? 'üstüne çıktı'
        : 'altına indi';
    await _notifications.show(
      id: alert.id.hashCode & 0x7fffffff,
      title: '${alert.symbol} fiyat alarmı',
      body:
          '${alert.name} ${alert.targetPrice.toStringAsFixed(2)} ${alert.currency} '
          '$direction. Güncel: ${currentPrice.toStringAsFixed(2)} ${alert.currency}',
      notificationDetails: details,
      payload: alert.id,
    );
  }

  Future<void> _write(List<PriceAlert> alerts) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _profileStorageKey,
      jsonEncode(alerts.map((item) => item.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Alarm cihaz hafızasına yazılamadı.');
    }
  }
}
