// lib/utils/date_time_utils.dart

import 'package:intl/intl.dart';

class DateTimeUtils {
  // Converte qualsiasi formato in DateTime con standardizzazione a UTC
  static DateTime? fromJsonNullable(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    } else if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
    } else if (value is String) {
      DateTime parsedDate = DateTime.parse(value);
      return parsedDate.isUtc ? parsedDate : parsedDate.toUtc();
    }
    return null;
  }

  // Converte DateTime in intero per JSON con standardizzazione a UTC
  static int? toJsonNullable(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }
    return dateTime.toUtc().millisecondsSinceEpoch;
  }

  static DateTime fromJson(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    } else if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
    } else if (value is String) {
      DateTime parsedDate = DateTime.parse(value);
      return parsedDate.isUtc ? parsedDate : parsedDate.toUtc();
    }
    return value;
  }

  // Converte DateTime in intero per JSON con standardizzazione a UTC
  static int toJson(DateTime dateTime) {
    return dateTime.toUtc().millisecondsSinceEpoch;
  }

  // Formatta data/ora per la visualizzazione all'utente (in locale)
  static String formatForUser(DateTime? dateTime) {
    if (dateTime == null) return '';
    final localTime = dateTime.toLocal();
    return DateFormat.Hm().format(localTime);
  }

  // Formatta la data per i separatori nelle chat
  static String formatDateSeparator(DateTime? dateTime) {
    if (dateTime == null) return '';

    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(localTime.year, localTime.month, localTime.day);

    if (messageDate == today) {
      return 'Oggi';
    } else if (messageDate == yesterday) {
      return 'Ieri';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat.EEEE('it').format(localTime); // Nome giorno completo
    } else {
      return DateFormat.yMMMd('it').format(localTime); // 21 gen 2023
    }
  }

  // Verifica se due date sono nello stesso giorno
  static bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;

    final d1 = date1.toLocal();
    final d2 = date2.toLocal();

    return d1.year == d2.year &&
        d1.month == d2.month &&
        d1.day == d2.day;
  }

  // Ordina una lista di messaggi per timestamp (più recente prima)
  static List<T> sortByTimestamp<T>(List<T> items, DateTime? Function(T) getTimestamp) {
    final sortedItems = List<T>.from(items);
    sortedItems.sort((a, b) {
      final timestampA = getTimestamp(a);
      final timestampB = getTimestamp(b);

      if (timestampA == null) return 1;  // Null timestamps go at the end
      if (timestampB == null) return -1;

      return timestampB.compareTo(timestampA);  // Descending order (newest first)
    });
    return sortedItems;
  }

  // Per il debug - mostra informazioni dettagliate su un timestamp
  static String debugTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'null';

    return '''
    ISO: ${timestamp.toIso8601String()}
    UTC: ${timestamp.toUtc().toIso8601String()}
    Local: ${timestamp.toLocal().toIso8601String()}
    isUTC: ${timestamp.isUtc}
    Milliseconds: ${timestamp.millisecondsSinceEpoch}
    ''';
  }
}