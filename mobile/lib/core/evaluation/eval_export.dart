import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/evaluation/eval_logger.dart';
import 'package:mobile/core/evaluation/evaluation_mode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes every logged event to a CSV file and opens the share sheet (T073).
/// The file starts with `#` header lines (session id, export time, device,
/// Android version, row count), then a column header and one line per event.
/// Throws when the file cannot be written or shared; the caller shows a message.
Future<void> exportEvalEvents(WidgetRef ref) async {
  final events = await ref.read(evalLoggerProvider).allEvents();
  final sessionId = ref.read(evaluationModeProvider).sessionId ?? 'none';
  final info = await DeviceInfoPlugin().androidInfo;
  final now = DateTime.now().toUtc();

  final lines = <String>[
    '# session_id,${_csvField(sessionId)}',
    '# exported_at,${now.toIso8601String()}',
    '# device,${_csvField('${info.manufacturer} ${info.model}')}',
    '# android,${_csvField('${info.version.release} (SDK ${info.version.sdkInt})')}',
    '# events,${events.length}',
    'seq,session_id,event_type,entity_id,at,duration_ms,payload',
    for (final e in events)
      [
        e.seq.toString(),
        e.sessionId,
        e.eventType,
        e.entityId ?? '',
        e.at.toUtc().toIso8601String(),
        e.durationMs?.toString() ?? '',
        e.payload,
      ].map(_csvField).join(','),
  ];

  final dir = await getTemporaryDirectory();
  final stamp = now
      .toIso8601String()
      .replaceAll(RegExp(r'[-:]'), '')
      .substring(0, 13);
  final shortId = sessionId.length > 8 ? sessionId.substring(0, 8) : sessionId;
  final file = File('${dir.path}/eval_${shortId}_$stamp.csv');
  await file.writeAsString('${lines.join('\n')}\n');

  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], subject: 'Evaluation events'),
  );
}

/// Quotes a CSV value when it holds a comma, a double quote or a newline, and
/// doubles any double quote inside.
String _csvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
