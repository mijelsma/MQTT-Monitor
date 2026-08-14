// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Add`
  String get add {
    return Intl.message('Add', name: 'add', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `Remove`
  String get remove {
    return Intl.message('Remove', name: 'remove', desc: '', args: []);
  }

  /// `Back`
  String get back {
    return Intl.message('Back', name: 'back', desc: '', args: []);
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Optional`
  String get optional {
    return Intl.message('Optional', name: 'optional', desc: '', args: []);
  }

  /// `No Broker`
  String get noBroker {
    return Intl.message('No Broker', name: 'noBroker', desc: '', args: []);
  }

  /// `Retry`
  String get retry {
    return Intl.message('Retry', name: 'retry', desc: '', args: []);
  }

  /// `Broker profiles unavailable`
  String get brokerProfilesUnavailable {
    return Intl.message(
      'Broker profiles unavailable',
      name: 'brokerProfilesUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Copy`
  String get copy {
    return Intl.message('Copy', name: 'copy', desc: '', args: []);
  }

  /// `Dismiss`
  String get dismiss {
    return Intl.message('Dismiss', name: 'dismiss', desc: '', args: []);
  }

  /// `Show details`
  String get showDetails {
    return Intl.message(
      'Show details',
      name: 'showDetails',
      desc: '',
      args: [],
    );
  }

  /// `Hide details`
  String get hideDetails {
    return Intl.message(
      'Hide details',
      name: 'hideDetails',
      desc: '',
      args: [],
    );
  }

  /// `Brokers`
  String get sectionBrokers {
    return Intl.message('Brokers', name: 'sectionBrokers', desc: '', args: []);
  }

  /// `Dashboard`
  String get sectionDashboard {
    return Intl.message(
      'Dashboard',
      name: 'sectionDashboard',
      desc: '',
      args: [],
    );
  }

  /// `Variables`
  String get sectionVariables {
    return Intl.message(
      'Variables',
      name: 'sectionVariables',
      desc: '',
      args: [],
    );
  }

  /// `Shortcuts`
  String get sectionShortcuts {
    return Intl.message(
      'Shortcuts',
      name: 'sectionShortcuts',
      desc: '',
      args: [],
    );
  }

  /// `Monitoring`
  String get sectionMonitoring {
    return Intl.message(
      'Monitoring',
      name: 'sectionMonitoring',
      desc: '',
      args: [],
    );
  }

  /// `User Interface`
  String get sectionUI {
    return Intl.message(
      'User Interface',
      name: 'sectionUI',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get sectionLanguage {
    return Intl.message(
      'Language',
      name: 'sectionLanguage',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get sectionAbout {
    return Intl.message('About', name: 'sectionAbout', desc: '', args: []);
  }

  /// `Brokers`
  String get brokersPanelTitle {
    return Intl.message(
      'Brokers',
      name: 'brokersPanelTitle',
      desc: '',
      args: [],
    );
  }

  /// `Configure MQTT brokers.`
  String get brokersPanelDescription {
    return Intl.message(
      'Configure MQTT brokers.',
      name: 'brokersPanelDescription',
      desc: '',
      args: [],
    );
  }

  /// `No brokers yet`
  String get brokersPanelNoBrokersTitle {
    return Intl.message(
      'No brokers yet',
      name: 'brokersPanelNoBrokersTitle',
      desc: '',
      args: [],
    );
  }

  /// `Tap 'Add Broker' to create your first broker.`
  String get brokersPanelNoBrokersMessage {
    return Intl.message(
      'Tap \'Add Broker\' to create your first broker.',
      name: 'brokersPanelNoBrokersMessage',
      desc: '',
      args: [],
    );
  }

  /// `Connections`
  String get brokersPanelSectionConnections {
    return Intl.message(
      'Connections',
      name: 'brokersPanelSectionConnections',
      desc: '',
      args: [],
    );
  }

  /// `Add Broker`
  String get brokersPanelAddBroker {
    return Intl.message(
      'Add Broker',
      name: 'brokersPanelAddBroker',
      desc: '',
      args: [],
    );
  }

  /// `Dashboard`
  String get dashboardPanelTitle {
    return Intl.message(
      'Dashboard',
      name: 'dashboardPanelTitle',
      desc: '',
      args: [],
    );
  }

  /// `Manage saved dashboard layouts.`
  String get dashboardPanelDescription {
    return Intl.message(
      'Manage saved dashboard layouts.',
      name: 'dashboardPanelDescription',
      desc: '',
      args: [],
    );
  }

  /// `Defaults`
  String get dashboardPanelDefaults {
    return Intl.message(
      'Defaults',
      name: 'dashboardPanelDefaults',
      desc: '',
      args: [],
    );
  }

  /// `Color`
  String get dashboardPanelColor {
    return Intl.message(
      'Color',
      name: 'dashboardPanelColor',
      desc: '',
      args: [],
    );
  }

  /// `Chart type`
  String get dashboardPanelChartType {
    return Intl.message(
      'Chart type',
      name: 'dashboardPanelChartType',
      desc: '',
      args: [],
    );
  }

  /// `Interpolation`
  String get dashboardPanelInterpolation {
    return Intl.message(
      'Interpolation',
      name: 'dashboardPanelInterpolation',
      desc: '',
      args: [],
    );
  }

  /// `Dot size`
  String get dashboardPanelDotSize {
    return Intl.message(
      'Dot size',
      name: 'dashboardPanelDotSize',
      desc: '',
      args: [],
    );
  }

  /// `Marker size for data points in new line graphs. Choose 0 to hide markers.`
  String get dashboardPanelDotSizeHint {
    return Intl.message(
      'Marker size for data points in new line graphs. Choose 0 to hide markers.',
      name: 'dashboardPanelDotSizeHint',
      desc: '',
      args: [],
    );
  }

  /// `Samples`
  String get dashboardPanelMaxSamples {
    return Intl.message(
      'Samples',
      name: 'dashboardPanelMaxSamples',
      desc: '',
      args: [],
    );
  }

  /// `Maximum number of recent values retained by each new graph.`
  String get dashboardPanelMaxSamplesHint {
    return Intl.message(
      'Maximum number of recent values retained by each new graph.',
      name: 'dashboardPanelMaxSamplesHint',
      desc: '',
      args: [],
    );
  }

  /// `Dashboards`
  String get dashboardPanelDashboards {
    return Intl.message(
      'Dashboards',
      name: 'dashboardPanelDashboards',
      desc: '',
      args: [],
    );
  }

  /// `No dashboards yet`
  String get dashboardPanelNoDashboardsTitle {
    return Intl.message(
      'No dashboards yet',
      name: 'dashboardPanelNoDashboardsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Create dashboard or save from dashboard view`
  String get dashboardPanelNoDashboardsMessage {
    return Intl.message(
      'Create dashboard or save from dashboard view',
      name: 'dashboardPanelNoDashboardsMessage',
      desc: '',
      args: [],
    );
  }

  /// `Add dashboard`
  String get dashboardPanelAddDashboard {
    return Intl.message(
      'Add dashboard',
      name: 'dashboardPanelAddDashboard',
      desc: '',
      args: [],
    );
  }

  /// `Edit Dashboard`
  String get dashboardDialogEditTitle {
    return Intl.message(
      'Edit Dashboard',
      name: 'dashboardDialogEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `New Dashboard`
  String get dashboardDialogNewTitle {
    return Intl.message(
      'New Dashboard',
      name: 'dashboardDialogNewTitle',
      desc: '',
      args: [],
    );
  }

  /// `Details`
  String get dashboardDialogSectionDetails {
    return Intl.message(
      'Details',
      name: 'dashboardDialogSectionDetails',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get dashboardDialogFieldName {
    return Intl.message(
      'Name',
      name: 'dashboardDialogFieldName',
      desc: '',
      args: [],
    );
  }

  /// `Name is required`
  String get dashboardDialogValidateName {
    return Intl.message(
      'Name is required',
      name: 'dashboardDialogValidateName',
      desc: '',
      args: [],
    );
  }

  /// `Scope`
  String get dashboardDialogSectionScope {
    return Intl.message(
      'Scope',
      name: 'dashboardDialogSectionScope',
      desc: '',
      args: [],
    );
  }

  /// `Use dashboard across all brokers`
  String get dashboardDialogScopeGlobalSubtitle {
    return Intl.message(
      'Use dashboard across all brokers',
      name: 'dashboardDialogScopeGlobalSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Only for selected brokers`
  String get dashboardDialogScopeBrokersSubtitle {
    return Intl.message(
      'Only for selected brokers',
      name: 'dashboardDialogScopeBrokersSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Variables`
  String get variablesPanelTitle {
    return Intl.message(
      'Variables',
      name: 'variablesPanelTitle',
      desc: '',
      args: [],
    );
  }

  /// `Define environment variables to use as placeholders in chart topic strings.`
  String get variablesPanelDescription {
    return Intl.message(
      'Define environment variables to use as placeholders in chart topic strings.',
      name: 'variablesPanelDescription',
      desc: '',
      args: [],
    );
  }

  /// `No variables yet`
  String get variablesPanelNoVariablesTitle {
    return Intl.message(
      'No variables yet',
      name: 'variablesPanelNoVariablesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add a variable to use as a placeholder\nin your chart topic strings.`
  String get variablesPanelNoVariablesMessage {
    return Intl.message(
      'Add a variable to use as a placeholder\nin your chart topic strings.',
      name: 'variablesPanelNoVariablesMessage',
      desc: '',
      args: [],
    );
  }

  /// `Defined Variables`
  String get variablesPanelDefinedVariables {
    return Intl.message(
      'Defined Variables',
      name: 'variablesPanelDefinedVariables',
      desc: '',
      args: [],
    );
  }

  /// `Add Variable`
  String get variablesPanelAddVariable {
    return Intl.message(
      'Add Variable',
      name: 'variablesPanelAddVariable',
      desc: '',
      args: [],
    );
  }

  /// `No options`
  String get variablesPanelNoOptions {
    return Intl.message(
      'No options',
      name: 'variablesPanelNoOptions',
      desc: '',
      args: [],
    );
  }

  /// `{count} {count, plural, =1{option} other{options}}`
  String variablesPanelOptionsCount(int count) {
    return Intl.message(
      '$count ${Intl.plural(count, one: 'option', other: 'options')}',
      name: 'variablesPanelOptionsCount',
      desc: '',
      args: [count],
    );
  }

  /// `Edit Variable`
  String get variableDialogEditTitle {
    return Intl.message(
      'Edit Variable',
      name: 'variableDialogEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add Variable`
  String get variableDialogAddTitle {
    return Intl.message(
      'Add Variable',
      name: 'variableDialogAddTitle',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get variableDialogFieldName {
    return Intl.message(
      'Name',
      name: 'variableDialogFieldName',
      desc: '',
      args: [],
    );
  }

  /// `Enter a variable name`
  String get variableDialogValidateName {
    return Intl.message(
      'Enter a variable name',
      name: 'variableDialogValidateName',
      desc: '',
      args: [],
    );
  }

  /// `A variable with this name already exists`
  String get variableDialogNameExists {
    return Intl.message(
      'A variable with this name already exists',
      name: 'variableDialogNameExists',
      desc: '',
      args: [],
    );
  }

  /// `Name cannot contain spaces or special characters`
  String get variableDialogNameInvalid {
    return Intl.message(
      'Name cannot contain spaces or special characters',
      name: 'variableDialogNameInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Pre-defined Options`
  String get variableDialogPredefinedOptions {
    return Intl.message(
      'Pre-defined Options',
      name: 'variableDialogPredefinedOptions',
      desc: '',
      args: [],
    );
  }

  /// `Options let you pick from a list in the dashboard instead of typing each time.`
  String get variableDialogOptionsHint {
    return Intl.message(
      'Options let you pick from a list in the dashboard instead of typing each time.',
      name: 'variableDialogOptionsHint',
      desc: '',
      args: [],
    );
  }

  /// `Add Option`
  String get variableDialogAddOption {
    return Intl.message(
      'Add Option',
      name: 'variableDialogAddOption',
      desc: '',
      args: [],
    );
  }

  /// `Available across all brokers`
  String get variableDialogScopeGlobalSubtitle {
    return Intl.message(
      'Available across all brokers',
      name: 'variableDialogScopeGlobalSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Only for selected brokers`
  String get variableDialogScopeBrokersSubtitle {
    return Intl.message(
      'Only for selected brokers',
      name: 'variableDialogScopeBrokersSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Display name`
  String get variableDialogDisplayName {
    return Intl.message(
      'Display name',
      name: 'variableDialogDisplayName',
      desc: '',
      args: [],
    );
  }

  /// `Value`
  String get variableDialogValue {
    return Intl.message(
      'Value',
      name: 'variableDialogValue',
      desc: '',
      args: [],
    );
  }

  /// `Shortcuts`
  String get shortcutsPanelTitle {
    return Intl.message(
      'Shortcuts',
      name: 'shortcutsPanelTitle',
      desc: '',
      args: [],
    );
  }

  /// `Define publish shortcuts for quickly sending messages to topics.`
  String get shortcutsPanelDescription {
    return Intl.message(
      'Define publish shortcuts for quickly sending messages to topics.',
      name: 'shortcutsPanelDescription',
      desc: '',
      args: [],
    );
  }

  /// `No shortcuts yet`
  String get shortcutsPanelNoShortcutsTitle {
    return Intl.message(
      'No shortcuts yet',
      name: 'shortcutsPanelNoShortcutsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add a shortcut to quickly publish\nto your favorite topics.`
  String get shortcutsPanelNoShortcutsMessage {
    return Intl.message(
      'Add a shortcut to quickly publish\nto your favorite topics.',
      name: 'shortcutsPanelNoShortcutsMessage',
      desc: '',
      args: [],
    );
  }

  /// `Defined Shortcuts`
  String get shortcutsPanelDefinedShortcuts {
    return Intl.message(
      'Defined Shortcuts',
      name: 'shortcutsPanelDefinedShortcuts',
      desc: '',
      args: [],
    );
  }

  /// `Add Shortcut`
  String get shortcutsPanelAddShortcut {
    return Intl.message(
      'Add Shortcut',
      name: 'shortcutsPanelAddShortcut',
      desc: '',
      args: [],
    );
  }

  /// `Edit Shortcut`
  String get shortcutDialogEditTitle {
    return Intl.message(
      'Edit Shortcut',
      name: 'shortcutDialogEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add Shortcut`
  String get shortcutDialogAddTitle {
    return Intl.message(
      'Add Shortcut',
      name: 'shortcutDialogAddTitle',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get shortcutDialogFieldName {
    return Intl.message(
      'Name',
      name: 'shortcutDialogFieldName',
      desc: '',
      args: [],
    );
  }

  /// `Enter a name`
  String get shortcutDialogValidateName {
    return Intl.message(
      'Enter a name',
      name: 'shortcutDialogValidateName',
      desc: '',
      args: [],
    );
  }

  /// `Topic`
  String get shortcutDialogFieldTopic {
    return Intl.message(
      'Topic',
      name: 'shortcutDialogFieldTopic',
      desc: '',
      args: [],
    );
  }

  /// `Enter a topic`
  String get shortcutDialogValidateTopic {
    return Intl.message(
      'Enter a topic',
      name: 'shortcutDialogValidateTopic',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid MQTT topic name`
  String get shortcutDialogInvalidTopic {
    return Intl.message(
      'Enter a valid MQTT topic name',
      name: 'shortcutDialogInvalidTopic',
      desc: '',
      args: [],
    );
  }

  /// `Put the variable name inside dollar-sign braces`
  String get shortcutDialogInvalidTemplate {
    return Intl.message(
      'Put the variable name inside dollar-sign braces',
      name: 'shortcutDialogInvalidTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Color`
  String get shortcutDialogFieldColor {
    return Intl.message(
      'Color',
      name: 'shortcutDialogFieldColor',
      desc: '',
      args: [],
    );
  }

  /// `Retain`
  String get shortcutDialogRetain {
    return Intl.message(
      'Retain',
      name: 'shortcutDialogRetain',
      desc: '',
      args: [],
    );
  }

  /// `Broker stores the message for new subscribers`
  String get shortcutDialogRetainSubtitle {
    return Intl.message(
      'Broker stores the message for new subscribers',
      name: 'shortcutDialogRetainSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Available across all brokers`
  String get shortcutDialogScopeGlobalSubtitle {
    return Intl.message(
      'Available across all brokers',
      name: 'shortcutDialogScopeGlobalSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Only for selected brokers`
  String get shortcutDialogScopeBrokersSubtitle {
    return Intl.message(
      'Only for selected brokers',
      name: 'shortcutDialogScopeBrokersSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Monitoring`
  String get monitoringPanelTitle {
    return Intl.message(
      'Monitoring',
      name: 'monitoringPanelTitle',
      desc: '',
      args: [],
    );
  }

  /// `Configure live message-rate sampling.`
  String get monitoringPanelDescription {
    return Intl.message(
      'Configure live message-rate sampling.',
      name: 'monitoringPanelDescription',
      desc: '',
      args: [],
    );
  }

  /// `Rate sampling`
  String get monitoringPanelRateSampling {
    return Intl.message(
      'Rate sampling',
      name: 'monitoringPanelRateSampling',
      desc: '',
      args: [],
    );
  }

  /// `Increased buffer size`
  String get monitoringPanelIncreasedBufferSize {
    return Intl.message(
      'Increased buffer size',
      name: 'monitoringPanelIncreasedBufferSize',
      desc: '',
      args: [],
    );
  }

  /// `Messages for monitored topics`
  String get monitoringPanelIncreasedBufferHint {
    return Intl.message(
      'Messages for monitored topics',
      name: 'monitoringPanelIncreasedBufferHint',
      desc: '',
      args: [],
    );
  }

  /// `Increased monitoring`
  String get monitoringPanelIncreasedMonitoring {
    return Intl.message(
      'Increased monitoring',
      name: 'monitoringPanelIncreasedMonitoring',
      desc: '',
      args: [],
    );
  }

  /// `Clear all`
  String get monitoringPanelClearAll {
    return Intl.message(
      'Clear all',
      name: 'monitoringPanelClearAll',
      desc: '',
      args: [],
    );
  }

  /// `Rate sample size`
  String get monitoringPanelRateSampleSize {
    return Intl.message(
      'Rate sample size',
      name: 'monitoringPanelRateSampleSize',
      desc: '',
      args: [],
    );
  }

  /// `Messages used to calculate rate`
  String get monitoringPanelRateSampleHint {
    return Intl.message(
      'Messages used to calculate rate',
      name: 'monitoringPanelRateSampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Advanced`
  String get sectionAdvanced {
    return Intl.message(
      'Advanced',
      name: 'sectionAdvanced',
      desc: '',
      args: [],
    );
  }

  /// `Advanced`
  String get advancedPanelTitle {
    return Intl.message(
      'Advanced',
      name: 'advancedPanelTitle',
      desc: '',
      args: [],
    );
  }

  /// `Adjusting these settings may significantly affect performance. Change them with care.`
  String get advancedPanelDescription {
    return Intl.message(
      'Adjusting these settings may significantly affect performance. Change them with care.',
      name: 'advancedPanelDescription',
      desc: '',
      args: [],
    );
  }

  /// `History buffer`
  String get advancedPanelHistoryBuffer {
    return Intl.message(
      'History buffer',
      name: 'advancedPanelHistoryBuffer',
      desc: '',
      args: [],
    );
  }

  /// `New subscription history`
  String get advancedPanelNewSubscriptionHistory {
    return Intl.message(
      'New subscription history',
      name: 'advancedPanelNewSubscriptionHistory',
      desc: '',
      args: [],
    );
  }

  /// `Collect bounded history for subscriptions created from now on`
  String get advancedPanelNewSubscriptionHistoryHint {
    return Intl.message(
      'Collect bounded history for subscriptions created from now on',
      name: 'advancedPanelNewSubscriptionHistoryHint',
      desc: '',
      args: [],
    );
  }

  /// `Default retention`
  String get advancedPanelDefaultRetention {
    return Intl.message(
      'Default retention',
      name: 'advancedPanelDefaultRetention',
      desc: '',
      args: [],
    );
  }

  /// `Messages retained by each new subscription`
  String get advancedPanelDefaultRetentionHint {
    return Intl.message(
      'Messages retained by each new subscription',
      name: 'advancedPanelDefaultRetentionHint',
      desc: '',
      args: [],
    );
  }

  /// `Maximum retention`
  String get advancedPanelMaximumRetention {
    return Intl.message(
      'Maximum retention',
      name: 'advancedPanelMaximumRetention',
      desc: '',
      args: [],
    );
  }

  /// `Upper bound enforced for every subscription and live history buffer`
  String get advancedPanelMaximumRetentionHint {
    return Intl.message(
      'Upper bound enforced for every subscription and live history buffer',
      name: 'advancedPanelMaximumRetentionHint',
      desc: '',
      args: [],
    );
  }

  /// `Reduce history maximum?`
  String get advancedPanelMaximumConfirmTitle {
    return Intl.message(
      'Reduce history maximum?',
      name: 'advancedPanelMaximumConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Affected policies and live buffers will be clamped. Existing messages beyond the new limit will be removed.`
  String get advancedPanelMaximumConfirmBody {
    return Intl.message(
      'Affected policies and live buffers will be clamped. Existing messages beyond the new limit will be removed.',
      name: 'advancedPanelMaximumConfirmBody',
      desc: '',
      args: [],
    );
  }

  /// `Saved subscription policies`
  String get advancedPanelAffectedSubscriptions {
    return Intl.message(
      'Saved subscription policies',
      name: 'advancedPanelAffectedSubscriptions',
      desc: '',
      args: [],
    );
  }

  /// `New-subscription default`
  String get advancedPanelAffectedDefault {
    return Intl.message(
      'New-subscription default',
      name: 'advancedPanelAffectedDefault',
      desc: '',
      args: [],
    );
  }

  /// `Live topic buffers`
  String get advancedPanelAffectedBuffers {
    return Intl.message(
      'Live topic buffers',
      name: 'advancedPanelAffectedBuffers',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get advancedPanelResetSection {
    return Intl.message(
      'Reset',
      name: 'advancedPanelResetSection',
      desc: '',
      args: [],
    );
  }

  /// `Reset application data`
  String get advancedPanelResetTitle {
    return Intl.message(
      'Reset application data',
      name: 'advancedPanelResetTitle',
      desc: '',
      args: [],
    );
  }

  /// `Choose which settings and saved data to reset or reset everything`
  String get advancedPanelResetHint {
    return Intl.message(
      'Choose which settings and saved data to reset or reset everything',
      name: 'advancedPanelResetHint',
      desc: '',
      args: [],
    );
  }

  /// `Select data to reset`
  String get advancedPanelResetAction {
    return Intl.message(
      'Select data to reset',
      name: 'advancedPanelResetAction',
      desc: '',
      args: [],
    );
  }

  /// `Reset selected`
  String get advancedPanelResetSelectedAction {
    return Intl.message(
      'Reset selected',
      name: 'advancedPanelResetSelectedAction',
      desc: '',
      args: [],
    );
  }

  /// `Choose what to reset`
  String get advancedPanelResetConfirmTitle {
    return Intl.message(
      'Choose what to reset',
      name: 'advancedPanelResetConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Selected data will be permanently removed or restored to its defaults. Unchecked data is kept.`
  String get advancedPanelResetConfirmBody {
    return Intl.message(
      'Selected data will be permanently removed or restored to its defaults. Unchecked data is kept.',
      name: 'advancedPanelResetConfirmBody',
      desc: '',
      args: [],
    );
  }

  /// `Select all`
  String get advancedPanelResetSelectAll {
    return Intl.message(
      'Select all',
      name: 'advancedPanelResetSelectAll',
      desc: '',
      args: [],
    );
  }

  /// `Broker profiles`
  String get advancedPanelResetBrokers {
    return Intl.message(
      'Broker profiles',
      name: 'advancedPanelResetBrokers',
      desc: '',
      args: [],
    );
  }

  /// `Dashboards`
  String get advancedPanelResetDashboards {
    return Intl.message(
      'Dashboards',
      name: 'advancedPanelResetDashboards',
      desc: '',
      args: [],
    );
  }

  /// `Variables`
  String get advancedPanelResetVariables {
    return Intl.message(
      'Variables',
      name: 'advancedPanelResetVariables',
      desc: '',
      args: [],
    );
  }

  /// `Shortcuts`
  String get advancedPanelResetShortcuts {
    return Intl.message(
      'Shortcuts',
      name: 'advancedPanelResetShortcuts',
      desc: '',
      args: [],
    );
  }

  /// `History preferences`
  String get advancedPanelResetHistory {
    return Intl.message(
      'History preferences',
      name: 'advancedPanelResetHistory',
      desc: '',
      args: [],
    );
  }

  /// `Connection preferences`
  String get advancedPanelResetConnection {
    return Intl.message(
      'Connection preferences',
      name: 'advancedPanelResetConnection',
      desc: '',
      args: [],
    );
  }

  /// `Publishing preferences`
  String get advancedPanelResetPublishing {
    return Intl.message(
      'Publishing preferences',
      name: 'advancedPanelResetPublishing',
      desc: '',
      args: [],
    );
  }

  /// `User interface`
  String get advancedPanelResetUserInterface {
    return Intl.message(
      'User interface',
      name: 'advancedPanelResetUserInterface',
      desc: '',
      args: [],
    );
  }

  /// `Update preferences`
  String get advancedPanelResetUpdates {
    return Intl.message(
      'Update preferences',
      name: 'advancedPanelResetUpdates',
      desc: '',
      args: [],
    );
  }

  /// `The selected data was reset.`
  String get advancedPanelResetSuccess {
    return Intl.message(
      'The selected data was reset.',
      name: 'advancedPanelResetSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Settings could not be reset. No broker resources were removed.`
  String get advancedPanelResetFailed {
    return Intl.message(
      'Settings could not be reset. No broker resources were removed.',
      name: 'advancedPanelResetFailed',
      desc: '',
      args: [],
    );
  }

  /// `The selected data was reset, but some broker files or credentials could not be removed.`
  String get advancedPanelResetCleanupWarning {
    return Intl.message(
      'The selected data was reset, but some broker files or credentials could not be removed.',
      name: 'advancedPanelResetCleanupWarning',
      desc: '',
      args: [],
    );
  }

  /// `Storage and diagnostics`
  String get advancedPanelStorageSection {
    return Intl.message(
      'Storage and diagnostics',
      name: 'advancedPanelStorageSection',
      desc: '',
      args: [],
    );
  }

  /// `Settings location`
  String get advancedPanelSettingsLocation {
    return Intl.message(
      'Settings location',
      name: 'advancedPanelSettingsLocation',
      desc: '',
      args: [],
    );
  }

  /// `Application preferences are stored here. Broker passwords remain in the operating system credential store.`
  String get advancedPanelSettingsLocationHint {
    return Intl.message(
      'Application preferences are stored here. Broker passwords remain in the operating system credential store.',
      name: 'advancedPanelSettingsLocationHint',
      desc: '',
      args: [],
    );
  }

  /// `Open folder`
  String get advancedPanelOpenFolder {
    return Intl.message(
      'Open folder',
      name: 'advancedPanelOpenFolder',
      desc: '',
      args: [],
    );
  }

  /// `Diagnostic log`
  String get advancedPanelLogFile {
    return Intl.message(
      'Diagnostic log',
      name: 'advancedPanelLogFile',
      desc: '',
      args: [],
    );
  }

  /// `Redacted diagnostic events from current and previous sessions`
  String get advancedPanelLogFileHint {
    return Intl.message(
      'Redacted diagnostic events from current and previous sessions',
      name: 'advancedPanelLogFileHint',
      desc: '',
      args: [],
    );
  }

  /// `Open log`
  String get advancedPanelOpenLog {
    return Intl.message(
      'Open log',
      name: 'advancedPanelOpenLog',
      desc: '',
      args: [],
    );
  }

  /// `The location could not be opened.`
  String get advancedPanelOpenLocationFailed {
    return Intl.message(
      'The location could not be opened.',
      name: 'advancedPanelOpenLocationFailed',
      desc: '',
      args: [],
    );
  }

  /// `User Interface`
  String get uiPanelTitle {
    return Intl.message(
      'User Interface',
      name: 'uiPanelTitle',
      desc: '',
      args: [],
    );
  }

  /// `Appearance and layout preferences.`
  String get uiPanelDescription {
    return Intl.message(
      'Appearance and layout preferences.',
      name: 'uiPanelDescription',
      desc: '',
      args: [],
    );
  }

  /// `Appearance`
  String get uiPanelSectionAppearance {
    return Intl.message(
      'Appearance',
      name: 'uiPanelSectionAppearance',
      desc: '',
      args: [],
    );
  }

  /// `Theme Mode`
  String get uiPanelThemeMode {
    return Intl.message(
      'Theme Mode',
      name: 'uiPanelThemeMode',
      desc: '',
      args: [],
    );
  }

  /// `System`
  String get uiPanelThemeSystem {
    return Intl.message(
      'System',
      name: 'uiPanelThemeSystem',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get uiPanelThemeLight {
    return Intl.message('Light', name: 'uiPanelThemeLight', desc: '', args: []);
  }

  /// `Dark`
  String get uiPanelThemeDark {
    return Intl.message('Dark', name: 'uiPanelThemeDark', desc: '', args: []);
  }

  /// `Accent color`
  String get uiPanelAccentColor {
    return Intl.message(
      'Accent color',
      name: 'uiPanelAccentColor',
      desc: '',
      args: [],
    );
  }

  /// `Show status bar`
  String get uiPanelShowStatusBar {
    return Intl.message(
      'Show status bar',
      name: 'uiPanelShowStatusBar',
      desc: '',
      args: [],
    );
  }

  /// `Shows the bottom status bar`
  String get uiPanelShowStatusBarSubtitle {
    return Intl.message(
      'Shows the bottom status bar',
      name: 'uiPanelShowStatusBarSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Rate update interval`
  String get uiPanelRateInterval {
    return Intl.message(
      'Rate update interval',
      name: 'uiPanelRateInterval',
      desc: '',
      args: [],
    );
  }

  /// `How often the message rate is recalculated`
  String get uiPanelRateIntervalSubtitle {
    return Intl.message(
      'How often the message rate is recalculated',
      name: 'uiPanelRateIntervalSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Data Display`
  String get uiPanelSectionDataDisplay {
    return Intl.message(
      'Data Display',
      name: 'uiPanelSectionDataDisplay',
      desc: '',
      args: [],
    );
  }

  /// `Show activity`
  String get uiPanelShowActivity {
    return Intl.message(
      'Show activity',
      name: 'uiPanelShowActivity',
      desc: '',
      args: [],
    );
  }

  /// `Pulse topic when activity occurs`
  String get uiPanelShowActivitySubtitle {
    return Intl.message(
      'Pulse topic when activity occurs',
      name: 'uiPanelShowActivitySubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Disable selection highlight`
  String get uiPanelDisableSelectionHighlight {
    return Intl.message(
      'Disable selection highlight',
      name: 'uiPanelDisableSelectionHighlight',
      desc: '',
      args: [],
    );
  }

  /// `Hide the selected-topic highlight so activity pulses stay visible on the active topic`
  String get uiPanelDisableSelectionHighlightSubtitle {
    return Intl.message(
      'Hide the selected-topic highlight so activity pulses stay visible on the active topic',
      name: 'uiPanelDisableSelectionHighlightSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Pulse rate`
  String get uiPanelPulseRate {
    return Intl.message(
      'Pulse rate',
      name: 'uiPanelPulseRate',
      desc: '',
      args: [],
    );
  }

  /// `Maximum activity pulses per second`
  String get uiPanelPulseRateSubtitle {
    return Intl.message(
      'Maximum activity pulses per second',
      name: 'uiPanelPulseRateSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Pulse fade`
  String get uiPanelPulseFade {
    return Intl.message(
      'Pulse fade',
      name: 'uiPanelPulseFade',
      desc: '',
      args: [],
    );
  }

  /// `Duration of the fade-out animation`
  String get uiPanelPulseFadeSubtitle {
    return Intl.message(
      'Duration of the fade-out animation',
      name: 'uiPanelPulseFadeSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Layout`
  String get uiPanelSectionLayout {
    return Intl.message(
      'Layout',
      name: 'uiPanelSectionLayout',
      desc: '',
      args: [],
    );
  }

  /// `Persist Layout`
  String get uiPanelPersistLayout {
    return Intl.message(
      'Persist Layout',
      name: 'uiPanelPersistLayout',
      desc: '',
      args: [],
    );
  }

  /// `Restore panel sizes and positions on restart`
  String get uiPanelPersistLayoutSubtitle {
    return Intl.message(
      'Restore panel sizes and positions on restart',
      name: 'uiPanelPersistLayoutSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Right panel animations`
  String get uiPanelSidebarAnimations {
    return Intl.message(
      'Right panel animations',
      name: 'uiPanelSidebarAnimations',
      desc: '',
      args: [],
    );
  }

  /// `Animate panels when they expand or collapse`
  String get uiPanelSidebarAnimationsSubtitle {
    return Intl.message(
      'Animate panels when they expand or collapse',
      name: 'uiPanelSidebarAnimationsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Panel animation speed`
  String get uiPanelSidebarAnimationSpeed {
    return Intl.message(
      'Panel animation speed',
      name: 'uiPanelSidebarAnimationSpeed',
      desc: '',
      args: [],
    );
  }

  /// `How quickly right sidebar panels move`
  String get uiPanelSidebarAnimationSpeedSubtitle {
    return Intl.message(
      'How quickly right sidebar panels move',
      name: 'uiPanelSidebarAnimationSpeedSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Sidebar Panels`
  String get uiPanelSectionSidebarPanels {
    return Intl.message(
      'Sidebar Panels',
      name: 'uiPanelSectionSidebarPanels',
      desc: '',
      args: [],
    );
  }

  /// `Collapsed`
  String get uiPanelDefaultStateCollapsed {
    return Intl.message(
      'Collapsed',
      name: 'uiPanelDefaultStateCollapsed',
      desc: '',
      args: [],
    );
  }

  /// `Expanded`
  String get uiPanelDefaultStateExpanded {
    return Intl.message(
      'Expanded',
      name: 'uiPanelDefaultStateExpanded',
      desc: '',
      args: [],
    );
  }

  /// `Last Status`
  String get uiPanelDefaultStateLastStatus {
    return Intl.message(
      'Last Status',
      name: 'uiPanelDefaultStateLastStatus',
      desc: '',
      args: [],
    );
  }

  /// `Connection`
  String get uiPanelSectionConnection {
    return Intl.message(
      'Connection',
      name: 'uiPanelSectionConnection',
      desc: '',
      args: [],
    );
  }

  /// `Startup Behavior`
  String get uiPanelStartupBehavior {
    return Intl.message(
      'Startup Behavior',
      name: 'uiPanelStartupBehavior',
      desc: '',
      args: [],
    );
  }

  /// `Connect`
  String get uiPanelStartupConnect {
    return Intl.message(
      'Connect',
      name: 'uiPanelStartupConnect',
      desc: '',
      args: [],
    );
  }

  /// `Last Status`
  String get uiPanelStartupLastStatus {
    return Intl.message(
      'Last Status',
      name: 'uiPanelStartupLastStatus',
      desc: '',
      args: [],
    );
  }

  /// `Disconnected`
  String get uiPanelStartupDisconnected {
    return Intl.message(
      'Disconnected',
      name: 'uiPanelStartupDisconnected',
      desc: '',
      args: [],
    );
  }

  /// `Default protocol for new brokers`
  String get uiPanelDefaultBrokerProtocol {
    return Intl.message(
      'Default protocol for new brokers',
      name: 'uiPanelDefaultBrokerProtocol',
      desc: '',
      args: [],
    );
  }

  /// `Defaults`
  String get uiPanelSectionDefaults {
    return Intl.message(
      'Defaults',
      name: 'uiPanelSectionDefaults',
      desc: '',
      args: [],
    );
  }

  /// `Default publish QoS`
  String get uiPanelDefaultPublishQos {
    return Intl.message(
      'Default publish QoS',
      name: 'uiPanelDefaultPublishQos',
      desc: '',
      args: [],
    );
  }

  /// `QoS used for new publish messages`
  String get uiPanelDefaultPublishQosSubtitle {
    return Intl.message(
      'QoS used for new publish messages',
      name: 'uiPanelDefaultPublishQosSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Default shortcut QoS`
  String get uiPanelDefaultShortcutQos {
    return Intl.message(
      'Default shortcut QoS',
      name: 'uiPanelDefaultShortcutQos',
      desc: '',
      args: [],
    );
  }

  /// `QoS used for new publish shortcuts`
  String get uiPanelDefaultShortcutQosSubtitle {
    return Intl.message(
      'QoS used for new publish shortcuts',
      name: 'uiPanelDefaultShortcutQosSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Default subscribe QoS`
  String get uiPanelDefaultSubscribeQos {
    return Intl.message(
      'Default subscribe QoS',
      name: 'uiPanelDefaultSubscribeQos',
      desc: '',
      args: [],
    );
  }

  /// `QoS used for new subscriptions`
  String get uiPanelDefaultSubscribeQosSubtitle {
    return Intl.message(
      'QoS used for new subscriptions',
      name: 'uiPanelDefaultSubscribeQosSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Last used`
  String get uiPanelQosOptionLastUsed {
    return Intl.message(
      'Last used',
      name: 'uiPanelQosOptionLastUsed',
      desc: '',
      args: [],
    );
  }

  /// `Reuse the QoS you most recently picked`
  String get uiPanelQosOptionLastUsedSubtitle {
    return Intl.message(
      'Reuse the QoS you most recently picked',
      name: 'uiPanelQosOptionLastUsedSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get languagePanelTitle {
    return Intl.message(
      'Language',
      name: 'languagePanelTitle',
      desc: '',
      args: [],
    );
  }

  /// `Select the interface language.`
  String get languagePanelDescription {
    return Intl.message(
      'Select the interface language.',
      name: 'languagePanelDescription',
      desc: '',
      args: [],
    );
  }

  /// `Interface Language`
  String get languagePanelSectionLabel {
    return Intl.message(
      'Interface Language',
      name: 'languagePanelSectionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Changes will apply on next launch.`
  String get languagePanelChangesNote {
    return Intl.message(
      'Changes will apply on next launch.',
      name: 'languagePanelChangesNote',
      desc: '',
      args: [],
    );
  }

  /// `English`
  String get languageNameEn {
    return Intl.message('English', name: 'languageNameEn', desc: '', args: []);
  }

  /// `German`
  String get languageNameDe {
    return Intl.message('German', name: 'languageNameDe', desc: '', args: []);
  }

  /// `French`
  String get languageNameFr {
    return Intl.message('French', name: 'languageNameFr', desc: '', args: []);
  }

  /// `Dutch`
  String get languageNameNl {
    return Intl.message('Dutch', name: 'languageNameNl', desc: '', args: []);
  }

  /// `Spanish`
  String get languageNameEs {
    return Intl.message('Spanish', name: 'languageNameEs', desc: '', args: []);
  }

  /// `About`
  String get aboutPanelTitle {
    return Intl.message('About', name: 'aboutPanelTitle', desc: '', args: []);
  }

  /// `Details`
  String get aboutPanelSectionDetails {
    return Intl.message(
      'Details',
      name: 'aboutPanelSectionDetails',
      desc: '',
      args: [],
    );
  }

  /// `Commit Hash`
  String get aboutPanelCommitHash {
    return Intl.message(
      'Commit Hash',
      name: 'aboutPanelCommitHash',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get aboutPanelVersionDetail {
    return Intl.message(
      'Version',
      name: 'aboutPanelVersionDetail',
      desc: '',
      args: [],
    );
  }

  /// `License`
  String get aboutPanelLicense {
    return Intl.message(
      'License',
      name: 'aboutPanelLicense',
      desc: '',
      args: [],
    );
  }

  /// `Author`
  String get aboutPanelAuthor {
    return Intl.message('Author', name: 'aboutPanelAuthor', desc: '', args: []);
  }

  /// `Resources`
  String get aboutPanelSectionResources {
    return Intl.message(
      'Resources',
      name: 'aboutPanelSectionResources',
      desc: '',
      args: [],
    );
  }

  /// `Source Code`
  String get aboutPanelSourceCode {
    return Intl.message(
      'Source Code',
      name: 'aboutPanelSourceCode',
      desc: '',
      args: [],
    );
  }

  /// `Changelog`
  String get aboutPanelChangelog {
    return Intl.message(
      'Changelog',
      name: 'aboutPanelChangelog',
      desc: '',
      args: [],
    );
  }

  /// `Report an Issue`
  String get aboutPanelReportIssue {
    return Intl.message(
      'Report an Issue',
      name: 'aboutPanelReportIssue',
      desc: '',
      args: [],
    );
  }

  /// `Support the Project`
  String get aboutPanelSupportProject {
    return Intl.message(
      'Support the Project',
      name: 'aboutPanelSupportProject',
      desc: '',
      args: [],
    );
  }

  /// `Edit Broker`
  String get brokerDialogEditTitle {
    return Intl.message(
      'Edit Broker',
      name: 'brokerDialogEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add Broker`
  String get brokerDialogAddTitle {
    return Intl.message(
      'Add Broker',
      name: 'brokerDialogAddTitle',
      desc: '',
      args: [],
    );
  }

  /// `Connection`
  String get brokerDialogSectionConnection {
    return Intl.message(
      'Connection',
      name: 'brokerDialogSectionConnection',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get brokerDialogFieldName {
    return Intl.message(
      'Name',
      name: 'brokerDialogFieldName',
      desc: '',
      args: [],
    );
  }

  /// `Color`
  String get brokerDialogFieldColor {
    return Intl.message(
      'Color',
      name: 'brokerDialogFieldColor',
      desc: '',
      args: [],
    );
  }

  /// `Enter a name`
  String get brokerDialogValidateName {
    return Intl.message(
      'Enter a name',
      name: 'brokerDialogValidateName',
      desc: '',
      args: [],
    );
  }

  /// `Host`
  String get brokerDialogFieldHost {
    return Intl.message(
      'Host',
      name: 'brokerDialogFieldHost',
      desc: '',
      args: [],
    );
  }

  /// `Enter a host`
  String get brokerDialogValidateHost {
    return Intl.message(
      'Enter a host',
      name: 'brokerDialogValidateHost',
      desc: '',
      args: [],
    );
  }

  /// `Port`
  String get brokerDialogFieldPort {
    return Intl.message(
      'Port',
      name: 'brokerDialogFieldPort',
      desc: '',
      args: [],
    );
  }

  /// `Use SSL / TLS`
  String get brokerDialogUseSSL {
    return Intl.message(
      'Use SSL / TLS',
      name: 'brokerDialogUseSSL',
      desc: '',
      args: [],
    );
  }

  /// `Encrypts the connection using TLS`
  String get brokerDialogUseSSLSubtitle {
    return Intl.message(
      'Encrypts the connection using TLS',
      name: 'brokerDialogUseSSLSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Validate Certificates`
  String get brokerDialogValidateCertificates {
    return Intl.message(
      'Validate Certificates',
      name: 'brokerDialogValidateCertificates',
      desc: '',
      args: [],
    );
  }

  /// `Validates the broker's SSL/TLS certificates`
  String get brokerDialogValidateCertificatesSubtitle {
    return Intl.message(
      'Validates the broker\'s SSL/TLS certificates',
      name: 'brokerDialogValidateCertificatesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Client ID`
  String get brokerDialogFieldClientId {
    return Intl.message(
      'Client ID',
      name: 'brokerDialogFieldClientId',
      desc: '',
      args: [],
    );
  }

  /// `Random Suffix`
  String get brokerDialogRandomSuffix {
    return Intl.message(
      'Random Suffix',
      name: 'brokerDialogRandomSuffix',
      desc: '',
      args: [],
    );
  }

  /// `Appends a random 6-digit hex suffix to the Client ID`
  String get brokerDialogRandomSuffixSubtitle {
    return Intl.message(
      'Appends a random 6-digit hex suffix to the Client ID',
      name: 'brokerDialogRandomSuffixSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Authentication`
  String get brokerDialogSectionAuthentication {
    return Intl.message(
      'Authentication',
      name: 'brokerDialogSectionAuthentication',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get brokerDialogFieldUsername {
    return Intl.message(
      'Username',
      name: 'brokerDialogFieldUsername',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get brokerDialogFieldPassword {
    return Intl.message(
      'Password',
      name: 'brokerDialogFieldPassword',
      desc: '',
      args: [],
    );
  }

  /// `Topics`
  String get brokerDialogSectionTopics {
    return Intl.message(
      'Topics',
      name: 'brokerDialogSectionTopics',
      desc: '',
      args: [],
    );
  }

  /// `Add Subscription`
  String get brokerDialogAddSubscription {
    return Intl.message(
      'Add Subscription',
      name: 'brokerDialogAddSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Every topic`
  String get brokerDialogDefaultSubscriptionName {
    return Intl.message(
      'Every topic',
      name: 'brokerDialogDefaultSubscriptionName',
      desc: '',
      args: [],
    );
  }

  /// `History off`
  String get brokerDialogHistoryDisabled {
    return Intl.message(
      'History off',
      name: 'brokerDialogHistoryDisabled',
      desc: '',
      args: [],
    );
  }

  /// `history messages`
  String get brokerDialogHistoryMessages {
    return Intl.message(
      'history messages',
      name: 'brokerDialogHistoryMessages',
      desc: '',
      args: [],
    );
  }

  /// `Edit Subscription`
  String get subscriptionDialogEditTitle {
    return Intl.message(
      'Edit Subscription',
      name: 'subscriptionDialogEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add Subscription`
  String get subscriptionDialogAddTitle {
    return Intl.message(
      'Add Subscription',
      name: 'subscriptionDialogAddTitle',
      desc: '',
      args: [],
    );
  }

  /// `Topic Filter`
  String get subscriptionDialogFieldTopicFilter {
    return Intl.message(
      'Topic Filter',
      name: 'subscriptionDialogFieldTopicFilter',
      desc: '',
      args: [],
    );
  }

  /// `Enter a topic filter`
  String get subscriptionDialogValidateTopicFilter {
    return Intl.message(
      'Enter a topic filter',
      name: 'subscriptionDialogValidateTopicFilter',
      desc: '',
      args: [],
    );
  }

  /// `Display Name`
  String get subscriptionDialogFieldDisplayName {
    return Intl.message(
      'Display Name',
      name: 'subscriptionDialogFieldDisplayName',
      desc: '',
      args: [],
    );
  }

  /// `Optional friendly name`
  String get subscriptionDialogHintDisplayName {
    return Intl.message(
      'Optional friendly name',
      name: 'subscriptionDialogHintDisplayName',
      desc: '',
      args: [],
    );
  }

  /// `Quality of Service`
  String get subscriptionDialogQoSLabel {
    return Intl.message(
      'Quality of Service',
      name: 'subscriptionDialogQoSLabel',
      desc: '',
      args: [],
    );
  }

  /// `QoS 0`
  String get subscriptionDialogQoS0Label {
    return Intl.message(
      'QoS 0',
      name: 'subscriptionDialogQoS0Label',
      desc: '',
      args: [],
    );
  }

  /// `At most once`
  String get subscriptionDialogQoS0Description {
    return Intl.message(
      'At most once',
      name: 'subscriptionDialogQoS0Description',
      desc: '',
      args: [],
    );
  }

  /// `QoS 1`
  String get subscriptionDialogQoS1Label {
    return Intl.message(
      'QoS 1',
      name: 'subscriptionDialogQoS1Label',
      desc: '',
      args: [],
    );
  }

  /// `At least once`
  String get subscriptionDialogQoS1Description {
    return Intl.message(
      'At least once',
      name: 'subscriptionDialogQoS1Description',
      desc: '',
      args: [],
    );
  }

  /// `QoS 2`
  String get subscriptionDialogQoS2Label {
    return Intl.message(
      'QoS 2',
      name: 'subscriptionDialogQoS2Label',
      desc: '',
      args: [],
    );
  }

  /// `Exactly once`
  String get subscriptionDialogQoS2Description {
    return Intl.message(
      'Exactly once',
      name: 'subscriptionDialogQoS2Description',
      desc: '',
      args: [],
    );
  }

  /// `History`
  String get subscriptionDialogHistoryLabel {
    return Intl.message(
      'History',
      name: 'subscriptionDialogHistoryLabel',
      desc: '',
      args: [],
    );
  }

  /// `Store message history`
  String get subscriptionDialogHistoryEnabled {
    return Intl.message(
      'Store message history',
      name: 'subscriptionDialogHistoryEnabled',
      desc: '',
      args: [],
    );
  }

  /// `Live messages remain available when history is off`
  String get subscriptionDialogHistoryEnabledHint {
    return Intl.message(
      'Live messages remain available when history is off',
      name: 'subscriptionDialogHistoryEnabledHint',
      desc: '',
      args: [],
    );
  }

  /// `Retention`
  String get subscriptionDialogHistoryRetention {
    return Intl.message(
      'Retention',
      name: 'subscriptionDialogHistoryRetention',
      desc: '',
      args: [],
    );
  }

  /// `Messages kept for topics matched by this subscription`
  String get subscriptionDialogHistoryRetentionHint {
    return Intl.message(
      'Messages kept for topics matched by this subscription',
      name: 'subscriptionDialogHistoryRetentionHint',
      desc: '',
      args: [],
    );
  }

  /// `When enabled filters overlap, the largest matching retention is used.`
  String get subscriptionDialogHistoryOverlapHint {
    return Intl.message(
      'When enabled filters overlap, the largest matching retention is used.',
      name: 'subscriptionDialogHistoryOverlapHint',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid MQTT topic filter`
  String get subscriptionDialogInvalidTopicFilter {
    return Intl.message(
      'Enter a valid MQTT topic filter',
      name: 'subscriptionDialogInvalidTopicFilter',
      desc: '',
      args: [],
    );
  }

  /// `This broker already has that topic filter`
  String get subscriptionDialogDuplicateTopicFilter {
    return Intl.message(
      'This broker already has that topic filter',
      name: 'subscriptionDialogDuplicateTopicFilter',
      desc: '',
      args: [],
    );
  }

  /// `No history yet`
  String get historyPanelNoHistory {
    return Intl.message(
      'No history yet',
      name: 'historyPanelNoHistory',
      desc: '',
      args: [],
    );
  }

  /// `Messages will appear here as they arrive`
  String get historyPanelNoHistoryHint {
    return Intl.message(
      'Messages will appear here as they arrive',
      name: 'historyPanelNoHistoryHint',
      desc: '',
      args: [],
    );
  }

  /// `History disabled`
  String get historyPanelDisabled {
    return Intl.message(
      'History disabled',
      name: 'historyPanelDisabled',
      desc: '',
      args: [],
    );
  }

  /// `Live values continue, but new history is not stored`
  String get historyPanelDisabledHint {
    return Intl.message(
      'Live values continue, but new history is not stored',
      name: 'historyPanelDisabledHint',
      desc: '',
      args: [],
    );
  }

  /// `No matching subscription`
  String get historyPanelNotSubscribed {
    return Intl.message(
      'No matching subscription',
      name: 'historyPanelNotSubscribed',
      desc: '',
      args: [],
    );
  }

  /// `This topic is not covered by the active broker subscriptions`
  String get historyPanelNotSubscribedHint {
    return Intl.message(
      'This topic is not covered by the active broker subscriptions',
      name: 'historyPanelNotSubscribedHint',
      desc: '',
      args: [],
    );
  }

  /// `Retaining up to`
  String get historyPanelRetainingUpTo {
    return Intl.message(
      'Retaining up to',
      name: 'historyPanelRetainingUpTo',
      desc: '',
      args: [],
    );
  }

  /// `stored`
  String get historyPanelStored {
    return Intl.message(
      'stored',
      name: 'historyPanelStored',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get historyPanelClear {
    return Intl.message('Clear', name: 'historyPanelClear', desc: '', args: []);
  }

  /// `Waiting for messages`
  String get noMessagesTitle {
    return Intl.message(
      'Waiting for messages',
      name: 'noMessagesTitle',
      desc: '',
      args: [],
    );
  }

  /// `No messages received yet.`
  String get noMessagesSubtitle {
    return Intl.message(
      'No messages received yet.',
      name: 'noMessagesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Erase history`
  String get dashboardEraseHistory {
    return Intl.message(
      'Erase history',
      name: 'dashboardEraseHistory',
      desc: '',
      args: [],
    );
  }

  /// `Global`
  String get scopeGlobal {
    return Intl.message('Global', name: 'scopeGlobal', desc: '', args: []);
  }

  /// `Selected brokers`
  String get scopeSelectedBrokers {
    return Intl.message(
      'Selected brokers',
      name: 'scopeSelectedBrokers',
      desc: '',
      args: [],
    );
  }

  /// `Specific brokers`
  String get scopeSpecificBrokers {
    return Intl.message(
      'Specific brokers',
      name: 'scopeSpecificBrokers',
      desc: '',
      args: [],
    );
  }

  /// `Version 1.0.0  ·  Build 1`
  String get aboutPanelVersion {
    return Intl.message(
      'Version 1.0.0  ·  Build 1',
      name: 'aboutPanelVersion',
      desc: '',
      args: [],
    );
  }

  /// `Waiting for messages…`
  String get detailWaitingForMessages {
    return Intl.message(
      'Waiting for messages…',
      name: 'detailWaitingForMessages',
      desc: '',
      args: [],
    );
  }

  /// `QoS`
  String get detailQoS {
    return Intl.message('QoS', name: 'detailQoS', desc: '', args: []);
  }

  /// `Retained`
  String get detailRetained {
    return Intl.message('Retained', name: 'detailRetained', desc: '', args: []);
  }

  /// `Yes`
  String get detailYes {
    return Intl.message('Yes', name: 'detailYes', desc: '', args: []);
  }

  /// `No`
  String get detailNo {
    return Intl.message('No', name: 'detailNo', desc: '', args: []);
  }

  /// `Received`
  String get detailReceived {
    return Intl.message('Received', name: 'detailReceived', desc: '', args: []);
  }

  /// `Size`
  String get detailSize {
    return Intl.message('Size', name: 'detailSize', desc: '', args: []);
  }

  /// `Messages`
  String get detailMessages {
    return Intl.message('Messages', name: 'detailMessages', desc: '', args: []);
  }

  /// `Pinned to dashboard`
  String get detailPinnedToDashboard {
    return Intl.message(
      'Pinned to dashboard',
      name: 'detailPinnedToDashboard',
      desc: '',
      args: [],
    );
  }

  /// `Viewing message #{seq}`
  String detailViewingMessage(int seq) {
    return Intl.message(
      'Viewing message #$seq',
      name: 'detailViewingMessage',
      desc: '',
      args: [seq],
    );
  }

  /// `Show latest`
  String get detailShowLatest {
    return Intl.message(
      'Show latest',
      name: 'detailShowLatest',
      desc: '',
      args: [],
    );
  }

  /// `Rate`
  String get detailRate {
    return Intl.message('Rate', name: 'detailRate', desc: '', args: []);
  }

  /// `1 message every {interval}`
  String detailRateValue(String interval) {
    return Intl.message(
      '1 message every $interval',
      name: 'detailRateValue',
      desc: '',
      args: [interval],
    );
  }

  /// `{count} messages per second`
  String detailRatePerSecond(String count) {
    return Intl.message(
      '$count messages per second',
      name: 'detailRatePerSecond',
      desc: '',
      args: [count],
    );
  }

  /// `No matching topics`
  String get filterNoMatchingTopics {
    return Intl.message(
      'No matching topics',
      name: 'filterNoMatchingTopics',
      desc: '',
      args: [],
    );
  }

  /// `Try adjusting or clearing the filter.`
  String get filterNoMatchingTopicsSubtitle {
    return Intl.message(
      'Try adjusting or clearing the filter.',
      name: 'filterNoMatchingTopicsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get searchScopeAll {
    return Intl.message('All', name: 'searchScopeAll', desc: '', args: []);
  }

  /// `Topic`
  String get searchScopeTopic {
    return Intl.message('Topic', name: 'searchScopeTopic', desc: '', args: []);
  }

  /// `Value`
  String get searchScopeValue {
    return Intl.message('Value', name: 'searchScopeValue', desc: '', args: []);
  }

  /// `Search`
  String get searchHint {
    return Intl.message('Search', name: 'searchHint', desc: '', args: []);
  }

  /// `Collapse all`
  String get collapseAll {
    return Intl.message(
      'Collapse all',
      name: 'collapseAll',
      desc: '',
      args: [],
    );
  }

  /// `Expand all`
  String get expandAll {
    return Intl.message('Expand all', name: 'expandAll', desc: '', args: []);
  }

  /// `Disconnect`
  String get disconnect {
    return Intl.message('Disconnect', name: 'disconnect', desc: '', args: []);
  }

  /// `Reconnect`
  String get reconnect {
    return Intl.message('Reconnect', name: 'reconnect', desc: '', args: []);
  }

  /// `example/topic`
  String get publishTopicHint {
    return Intl.message(
      'example/topic',
      name: 'publishTopicHint',
      desc: '',
      args: [],
    );
  }

  /// `Prettify JSON`
  String get publishPrettifyJson {
    return Intl.message(
      'Prettify JSON',
      name: 'publishPrettifyJson',
      desc: '',
      args: [],
    );
  }

  /// `Retain`
  String get publishRetain {
    return Intl.message('Retain', name: 'publishRetain', desc: '', args: []);
  }

  /// `Sending…`
  String get publishSending {
    return Intl.message('Sending…', name: 'publishSending', desc: '', args: []);
  }

  /// `Delivered`
  String get publishDelivered {
    return Intl.message(
      'Delivered',
      name: 'publishDelivered',
      desc: '',
      args: [],
    );
  }

  /// `Sent`
  String get publishSent {
    return Intl.message('Sent', name: 'publishSent', desc: '', args: []);
  }

  /// `Sent`
  String get publishAcknowledged {
    return Intl.message(
      'Sent',
      name: 'publishAcknowledged',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get publishFailed {
    return Intl.message('Failed', name: 'publishFailed', desc: '', args: []);
  }

  /// `Timed out`
  String get publishTimedOut {
    return Intl.message(
      'Timed out',
      name: 'publishTimedOut',
      desc: '',
      args: [],
    );
  }

  /// `Offline`
  String get publishOffline {
    return Intl.message('Offline', name: 'publishOffline', desc: '', args: []);
  }

  /// `No topic`
  String get publishNoTopic {
    return Intl.message('No topic', name: 'publishNoTopic', desc: '', args: []);
  }

  /// `Bad JSON`
  String get publishBadJson {
    return Intl.message('Bad JSON', name: 'publishBadJson', desc: '', args: []);
  }

  /// `Enter a valid MQTT topic name`
  String get publishInvalidTopic {
    return Intl.message(
      'Enter a valid MQTT topic name',
      name: 'publishInvalidTopic',
      desc: '',
      args: [],
    );
  }

  /// `Put the variable name inside dollar-sign braces`
  String get publishInvalidTemplate {
    return Intl.message(
      'Put the variable name inside dollar-sign braces',
      name: 'publishInvalidTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Set every topic variable before publishing`
  String get publishMissingVariables {
    return Intl.message(
      'Set every topic variable before publishing',
      name: 'publishMissingVariables',
      desc: '',
      args: [],
    );
  }

  /// `QoS must be 0, 1, or 2`
  String get publishInvalidQos {
    return Intl.message(
      'QoS must be 0, 1, or 2',
      name: 'publishInvalidQos',
      desc: '',
      args: [],
    );
  }

  /// `MESSAGE DETAIL`
  String get sidebarMessageDetail {
    return Intl.message(
      'MESSAGE DETAIL',
      name: 'sidebarMessageDetail',
      desc: '',
      args: [],
    );
  }

  /// `HISTORY`
  String get sidebarHistory {
    return Intl.message('HISTORY', name: 'sidebarHistory', desc: '', args: []);
  }

  /// `PUBLISH`
  String get sidebarPublish {
    return Intl.message('PUBLISH', name: 'sidebarPublish', desc: '', args: []);
  }

  /// `SHORTCUTS`
  String get sidebarShortcuts {
    return Intl.message(
      'SHORTCUTS',
      name: 'sidebarShortcuts',
      desc: '',
      args: [],
    );
  }

  /// `No shortcuts available.\nAdd shortcuts in Settings.`
  String get sidebarShortcutsEmpty {
    return Intl.message(
      'No shortcuts available.\nAdd shortcuts in Settings.',
      name: 'sidebarShortcutsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Manage Shortcuts`
  String get sidebarShortcutsManage {
    return Intl.message(
      'Manage Shortcuts',
      name: 'sidebarShortcutsManage',
      desc: '',
      args: [],
    );
  }

  /// `Select a topic to inspect`
  String get sidebarNoSelectionTitle {
    return Intl.message(
      'Select a topic to inspect',
      name: 'sidebarNoSelectionTitle',
      desc: '',
      args: [],
    );
  }

  /// `Choose a topic from the tree\nto view message details`
  String get sidebarNoSelectionSubtitle {
    return Intl.message(
      'Choose a topic from the tree\nto view message details',
      name: 'sidebarNoSelectionSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Resize Message Detail and History`
  String get sidebarResizeDetailHistory {
    return Intl.message(
      'Resize Message Detail and History',
      name: 'sidebarResizeDetailHistory',
      desc: '',
      args: [],
    );
  }

  /// `Resize Message Detail and Publish`
  String get sidebarResizeDetailPublish {
    return Intl.message(
      'Resize Message Detail and Publish',
      name: 'sidebarResizeDetailPublish',
      desc: '',
      args: [],
    );
  }

  /// `Resize Message Detail and Shortcuts`
  String get sidebarResizeDetailShortcuts {
    return Intl.message(
      'Resize Message Detail and Shortcuts',
      name: 'sidebarResizeDetailShortcuts',
      desc: '',
      args: [],
    );
  }

  /// `Resize History and Publish`
  String get sidebarResizeHistoryPublish {
    return Intl.message(
      'Resize History and Publish',
      name: 'sidebarResizeHistoryPublish',
      desc: '',
      args: [],
    );
  }

  /// `Resize History and Shortcuts`
  String get sidebarResizeHistoryShortcuts {
    return Intl.message(
      'Resize History and Shortcuts',
      name: 'sidebarResizeHistoryShortcuts',
      desc: '',
      args: [],
    );
  }

  /// `Resize Publish and Shortcuts`
  String get sidebarResizePublishShortcuts {
    return Intl.message(
      'Resize Publish and Shortcuts',
      name: 'sidebarResizePublishShortcuts',
      desc: '',
      args: [],
    );
  }

  /// `< 1 second`
  String get durationLessThanSecond {
    return Intl.message(
      '< 1 second',
      name: 'durationLessThanSecond',
      desc: '',
      args: [],
    );
  }

  /// `{count} {count, plural, =1{second} other{seconds}}`
  String durationSeconds(int count) {
    return Intl.message(
      '$count ${Intl.plural(count, one: 'second', other: 'seconds')}',
      name: 'durationSeconds',
      desc: '',
      args: [count],
    );
  }

  /// `{count} {count, plural, =1{minute} other{minutes}}`
  String durationMinutes(int count) {
    return Intl.message(
      '$count ${Intl.plural(count, one: 'minute', other: 'minutes')}',
      name: 'durationMinutes',
      desc: '',
      args: [count],
    );
  }

  /// `{count} {count, plural, =1{hour} other{hours}}`
  String durationHours(int count) {
    return Intl.message(
      '$count ${Intl.plural(count, one: 'hour', other: 'hours')}',
      name: 'durationHours',
      desc: '',
      args: [count],
    );
  }

  /// `Delete topic`
  String get detailDeleteTopic {
    return Intl.message(
      'Delete topic',
      name: 'detailDeleteTopic',
      desc: '',
      args: [],
    );
  }

  /// `Topic deleted`
  String get detailTopicDeleted {
    return Intl.message(
      'Topic deleted',
      name: 'detailTopicDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Clear retained message`
  String get detailClearRetained {
    return Intl.message(
      'Clear retained message',
      name: 'detailClearRetained',
      desc: '',
      args: [],
    );
  }

  /// `Retained message cleared`
  String get detailRetainedCleared {
    return Intl.message(
      'Retained message cleared',
      name: 'detailRetainedCleared',
      desc: '',
      args: [],
    );
  }

  /// `Failed to clear — not connected`
  String get detailRetainedClearFailed {
    return Intl.message(
      'Failed to clear — not connected',
      name: 'detailRetainedClearFailed',
      desc: '',
      args: [],
    );
  }

  /// `Connected`
  String get statusConnected {
    return Intl.message(
      'Connected',
      name: 'statusConnected',
      desc: '',
      args: [],
    );
  }

  /// `Connecting`
  String get statusConnecting {
    return Intl.message(
      'Connecting',
      name: 'statusConnecting',
      desc: '',
      args: [],
    );
  }

  /// `Disconnected`
  String get statusDisconnected {
    return Intl.message(
      'Disconnected',
      name: 'statusDisconnected',
      desc: '',
      args: [],
    );
  }

  /// `Host not found`
  String get statusHostNotFound {
    return Intl.message(
      'Host not found',
      name: 'statusHostNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Not permitted`
  String get statusNotPermitted {
    return Intl.message(
      'Not permitted',
      name: 'statusNotPermitted',
      desc: '',
      args: [],
    );
  }

  /// `Connection refused`
  String get statusConnectionRefused {
    return Intl.message(
      'Connection refused',
      name: 'statusConnectionRefused',
      desc: '',
      args: [],
    );
  }

  /// `TLS failed`
  String get statusTlsFailed {
    return Intl.message(
      'TLS failed',
      name: 'statusTlsFailed',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get statusError {
    return Intl.message('Error', name: 'statusError', desc: '', args: []);
  }

  /// `{count} msgs · {rate}/s`
  String statusMessages(int count, int rate) {
    return Intl.message(
      '$count msgs · $rate/s',
      name: 'statusMessages',
      desc: '',
      args: [count, rate],
    );
  }

  /// `Update available`
  String get statusUpdateAvailable {
    return Intl.message(
      'Update available',
      name: 'statusUpdateAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Open update settings`
  String get statusOpenUpdateSettings {
    return Intl.message(
      'Open update settings',
      name: 'statusOpenUpdateSettings',
      desc: '',
      args: [],
    );
  }

  /// `MQTT 5.0 — reason codes and properties available`
  String get statusMqtt5Detail {
    return Intl.message(
      'MQTT 5.0 — reason codes and properties available',
      name: 'statusMqtt5Detail',
      desc: '',
      args: [],
    );
  }

  /// `MQTT 3.1.1 — broker does not return delivery reasons`
  String get statusMqtt311Detail {
    return Intl.message(
      'MQTT 3.1.1 — broker does not return delivery reasons',
      name: 'statusMqtt311Detail',
      desc: '',
      args: [],
    );
  }

  /// `Clear all topics`
  String get clearAllTopics {
    return Intl.message(
      'Clear all topics',
      name: 'clearAllTopics',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'nl'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
