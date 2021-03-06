import 'package:battery/battery.dart' as plugin;
import 'package:flutter/cupertino.dart';

/// Charging/Discharging state of the device's battery.
enum BatteryState {
  charging,
  discharging
}

/// Provides information about device's battery level and state.
class BatteryNotifier extends ValueNotifier<BatteryState> {
  BatteryNotifier() : super(null) {
    _source.onBatteryStateChanged.listen((state) =>
      super.value = _convert(state)
    );
  }

  static Future<int> get batteryLevel => _source.batteryLevel;
}

var _source = plugin.Battery();

BatteryState _convert(plugin.BatteryState state) {
  switch (state) {
    case plugin.BatteryState.charging:
      return BatteryState.charging;
    case plugin.BatteryState.discharging:
      return BatteryState.discharging;
    case plugin.BatteryState.full:
      return BatteryState.charging;
    default:
      return BatteryState.discharging;
  }
}