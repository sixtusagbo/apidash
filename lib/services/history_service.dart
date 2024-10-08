import 'package:apidash/models/models.dart';
import 'package:apidash/utils/utils.dart';
import 'package:apidash/consts.dart';
import 'hive_services.dart';

Future<void> autoClearHistory() async {
  final settingsMap = hiveHandler.settings;
  final retentionPeriod = settingsMap['historyRetentionPeriod'];

  HistoryRetentionPeriod historyRetentionPeriod =
      HistoryRetentionPeriod.oneWeek;
  if (retentionPeriod != null) {
    historyRetentionPeriod =
        HistoryRetentionPeriod.values.byName(retentionPeriod);
  }
  DateTime? retentionDate = getRetentionDate(historyRetentionPeriod);

  if (retentionDate == null) {
    return;
  } else {
    List<String>? historyIds = hiveHandler.getHistoryIds();
    List<String> toRemoveIds = [];

    if (historyIds == null || historyIds.isEmpty) {
      return;
    }

    for (var historyId in historyIds) {
      var jsonModel = hiveHandler.getHistoryMeta(historyId);
      if (jsonModel != null) {
        var jsonMap = Map<String, Object?>.from(jsonModel);
        HistoryMetaModel historyMetaModelFromJson =
            HistoryMetaModel.fromJson(jsonMap);
        if (historyMetaModelFromJson.timeStamp.isBefore(retentionDate)) {
          toRemoveIds.add(historyId);
        }
      }
    }

    if (toRemoveIds.isEmpty) {
      return;
    }

    for (var id in toRemoveIds) {
      await hiveHandler.deleteHistoryRequest(id);
      hiveHandler.deleteHistoryMeta(id);
    }
    hiveHandler.setHistoryIds(
        historyIds..removeWhere((id) => toRemoveIds.contains(id)));
  }
}
