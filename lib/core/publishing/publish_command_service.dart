import '../mqtt/mqtt_topic_name.dart';
import 'json_payload_validator.dart';
import 'publish_command.dart';
import 'publish_command_failure.dart';
import 'publish_command_result.dart';
import 'template_resolver.dart';
import 'publish_transport.dart';

/// Applies shared publish validation and delegates valid commands to MQTT.
class PublishCommandService {
  const PublishCommandService(this._session, this._resolver, {JsonPayloadValidator jsonValidator = const JsonPayloadValidator()}) : _jsonValidator = jsonValidator;

  final PublishTransport _session;
  final TemplateResolver _resolver;
  final JsonPayloadValidator _jsonValidator;

  Future<PublishCommandResult> execute(PublishCommand command, Map<String, String> variableValues, {void Function()? onDispatch}) async {
    final template = command.topicTemplate.trim();
    if (template.isEmpty) {
      return const PublishCommandResult.failure(PublishCommandFailure.emptyTopic);
    }
    final templateError = _resolver.validateTemplate(template);
    if (templateError != null) {
      return PublishCommandResult.failure(PublishCommandFailure.invalidTemplate, detail: templateError);
    }
    final resolution = _resolver.resolve(template, variableValues);
    if (!resolution.isComplete) {
      return PublishCommandResult.failure(PublishCommandFailure.missingVariables, detail: resolution.missingVariables.join(', '));
    }
    final topicError = MqttTopicName.validate(resolution.value);
    if (topicError != null) {
      return PublishCommandResult.failure(PublishCommandFailure.invalidTopic, detail: topicError);
    }
    if (command.qos < 0 || command.qos > 2) {
      return const PublishCommandResult.failure(PublishCommandFailure.invalidQos, detail: 'QoS must be between 0 and 2.');
    }
    if (command.payloadIsJson && !_jsonValidator.isValid(command.payload)) {
      return const PublishCommandResult.failure(PublishCommandFailure.invalidJson);
    }
    onDispatch?.call();
    final pending = _session.publish(resolution.value, command.payload, qos: command.qos, retain: command.retain);
    if (pending == null) {
      return const PublishCommandResult.failure(PublishCommandFailure.offline);
    }
    return PublishCommandResult.sent(await pending);
  }
}
