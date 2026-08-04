import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../shared/format_helpers.dart';
import '../../shared/widgets/payload_editor.dart';

/// Monitor-scoped state for the Send Message form. It deliberately lives
/// above the collapsible sidebar so layout changes cannot dispose the draft.
class PublishDraftController extends ChangeNotifier {
  PublishDraftController() {
    payloadController.addListener(_onPayloadChanged);
  }

  final topicController = TextEditingController();
  final payloadController = HighlightingController();

  int _qos = 0;
  bool _retain = false;
  PayloadFormat _format = PayloadFormat.text;
  String? _validationError;

  int get qos => _qos;
  bool get retain => _retain;
  PayloadFormat get format => _format;
  String? get validationError => _validationError;

  void setQos(int value) {
    if (_qos == value) return;
    _qos = value;
    notifyListeners();
  }

  void setRetain(bool value) {
    if (_retain == value) return;
    _retain = value;
    notifyListeners();
  }

  void setFormat(PayloadFormat value) {
    if (_format == value) return;
    _format = value;
    payloadController.highlightJson = value == PayloadFormat.json;
    _updateValidation();
    notifyListeners();
  }

  void _onPayloadChanged() {
    if (_updateValidation()) notifyListeners();
  }

  bool _updateValidation() {
    final next = _format == PayloadFormat.json
        ? validateJson(payloadController.text)
        : null;
    if (next == _validationError) return false;
    _validationError = next;
    return true;
  }

  @override
  void dispose() {
    payloadController.removeListener(_onPayloadChanged);
    topicController.dispose();
    payloadController.dispose();
    super.dispose();
  }
}
