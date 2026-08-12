import 'dart:convert';

/// Validates MQTT topic filters and matches concrete topics against them.
abstract final class MqttTopicFilter {
  static const int _maximumUtf8Bytes = 65535;

  /// Returns a validation message, or `null` when [filter] is valid.
  static String? validate(String filter) {
    if (filter.isEmpty) return 'A topic filter is required.';
    if (filter.contains('\u0000')) {
      return 'Topic filters cannot contain a null character.';
    }
    if (utf8.encode(filter).length > _maximumUtf8Bytes) {
      return 'The topic filter is longer than MQTT allows.';
    }

    final shared = _sharedFilter(filter);
    if (filter.startsWith(r'$share/')) {
      if (shared == null) {
        return 'Shared subscriptions require a group and topic filter.';
      }
      final group = filter.split('/')[1];
      if (group.contains('+') || group.contains('#')) {
        return 'Shared subscription groups cannot contain wildcards.';
      }
      return validate(shared);
    }

    final levels = filter.split('/');
    for (var index = 0; index < levels.length; index++) {
      final level = levels[index];
      if (level.contains('#') && (level != '#' || index != levels.length - 1)) {
        return 'The # wildcard must occupy the final topic level.';
      }
      if (level.contains('+') && level != '+') {
        return 'The + wildcard must occupy an entire topic level.';
      }
    }
    return null;
  }

  /// Returns whether [filter] accepts the concrete MQTT [topic].
  static bool matches(String filter, String topic) {
    if (validate(filter) != null || topic.isEmpty || topic.contains('\u0000')) {
      return false;
    }
    final effectiveFilter = _sharedFilter(filter) ?? filter;
    if (topic.startsWith(r'$') && !effectiveFilter.startsWith(r'$')) {
      return false;
    }

    final filterLevels = effectiveFilter.split('/');
    final topicLevels = topic.split('/');
    var topicIndex = 0;
    for (final filterLevel in filterLevels) {
      if (filterLevel == '#') return true;
      if (topicIndex >= topicLevels.length) return false;
      if (filterLevel != '+' && filterLevel != topicLevels[topicIndex]) {
        return false;
      }
      topicIndex++;
    }
    return topicIndex == topicLevels.length;
  }

  static String? _sharedFilter(String filter) {
    if (!filter.startsWith(r'$share/')) return null;
    final levels = filter.split('/');
    if (levels.length < 3 || levels[1].isEmpty) return null;
    final sharedFilter = levels.skip(2).join('/');
    return sharedFilter.isEmpty ? null : sharedFilter;
  }
}
