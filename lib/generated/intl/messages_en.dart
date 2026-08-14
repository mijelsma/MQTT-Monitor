// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(count) => "${count} messages per second";

  static String m1(interval) => "1 message every ${interval}";

  static String m2(seq) => "Viewing message #${seq}";

  static String m3(count) =>
      "${count} ${Intl.plural(count, one: 'hour', other: 'hours')}";

  static String m4(count) =>
      "${count} ${Intl.plural(count, one: 'minute', other: 'minutes')}";

  static String m5(count) =>
      "${count} ${Intl.plural(count, one: 'second', other: 'seconds')}";

  static String m6(count, rate) => "${count} msgs · ${rate}/s";

  static String m7(count) =>
      "${count} ${Intl.plural(count, one: 'option', other: 'options')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aboutPanelAuthor": MessageLookupByLibrary.simpleMessage("Author"),
    "aboutPanelChangelog": MessageLookupByLibrary.simpleMessage("Changelog"),
    "aboutPanelCommitHash": MessageLookupByLibrary.simpleMessage("Commit Hash"),
    "aboutPanelLicense": MessageLookupByLibrary.simpleMessage("License"),
    "aboutPanelReportIssue": MessageLookupByLibrary.simpleMessage(
      "Report an Issue",
    ),
    "aboutPanelSectionDetails": MessageLookupByLibrary.simpleMessage("Details"),
    "aboutPanelSectionResources": MessageLookupByLibrary.simpleMessage(
      "Resources",
    ),
    "aboutPanelSourceCode": MessageLookupByLibrary.simpleMessage("Source Code"),
    "aboutPanelSupportProject": MessageLookupByLibrary.simpleMessage(
      "Support the Project",
    ),
    "aboutPanelTitle": MessageLookupByLibrary.simpleMessage("About"),
    "aboutPanelVersion": MessageLookupByLibrary.simpleMessage(
      "Version 1.0.0  ·  Build 1",
    ),
    "aboutPanelVersionDetail": MessageLookupByLibrary.simpleMessage("Version"),
    "add": MessageLookupByLibrary.simpleMessage("Add"),
    "advancedPanelAffectedBuffers": MessageLookupByLibrary.simpleMessage(
      "Live topic buffers",
    ),
    "advancedPanelAffectedDefault": MessageLookupByLibrary.simpleMessage(
      "New-subscription default",
    ),
    "advancedPanelAffectedSubscriptions": MessageLookupByLibrary.simpleMessage(
      "Saved subscription policies",
    ),
    "advancedPanelDefaultRetention": MessageLookupByLibrary.simpleMessage(
      "Default retention",
    ),
    "advancedPanelDefaultRetentionHint": MessageLookupByLibrary.simpleMessage(
      "Messages retained by each new subscription",
    ),
    "advancedPanelDescription": MessageLookupByLibrary.simpleMessage(
      "Adjusting these settings may significantly affect performance. Change them with care.",
    ),
    "advancedPanelHistoryBuffer": MessageLookupByLibrary.simpleMessage(
      "History buffer",
    ),
    "advancedPanelLogFile": MessageLookupByLibrary.simpleMessage(
      "Diagnostic log",
    ),
    "advancedPanelLogFileHint": MessageLookupByLibrary.simpleMessage(
      "Redacted diagnostic events from current and previous sessions",
    ),
    "advancedPanelMaximumConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Affected policies and live buffers will be clamped. Existing messages beyond the new limit will be removed.",
    ),
    "advancedPanelMaximumConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Reduce history maximum?",
    ),
    "advancedPanelMaximumRetention": MessageLookupByLibrary.simpleMessage(
      "Maximum retention",
    ),
    "advancedPanelMaximumRetentionHint": MessageLookupByLibrary.simpleMessage(
      "Upper bound enforced for every subscription and live history buffer",
    ),
    "advancedPanelNewSubscriptionHistory": MessageLookupByLibrary.simpleMessage(
      "New subscription history",
    ),
    "advancedPanelNewSubscriptionHistoryHint":
        MessageLookupByLibrary.simpleMessage(
          "Collect bounded history for subscriptions created from now on",
        ),
    "advancedPanelOpenFolder": MessageLookupByLibrary.simpleMessage(
      "Open folder",
    ),
    "advancedPanelOpenLocationFailed": MessageLookupByLibrary.simpleMessage(
      "The location could not be opened.",
    ),
    "advancedPanelOpenLog": MessageLookupByLibrary.simpleMessage("Open log"),
    "advancedPanelResetAction": MessageLookupByLibrary.simpleMessage(
      "Select data to reset",
    ),
    "advancedPanelResetBrokers": MessageLookupByLibrary.simpleMessage(
      "Broker profiles",
    ),
    "advancedPanelResetCleanupWarning": MessageLookupByLibrary.simpleMessage(
      "The selected data was reset, but some broker files or credentials could not be removed.",
    ),
    "advancedPanelResetConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Selected data will be permanently removed or restored to its defaults. Unchecked data is kept.",
    ),
    "advancedPanelResetConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Choose what to reset",
    ),
    "advancedPanelResetConnection": MessageLookupByLibrary.simpleMessage(
      "Connection preferences",
    ),
    "advancedPanelResetDashboards": MessageLookupByLibrary.simpleMessage(
      "Dashboards",
    ),
    "advancedPanelResetFailed": MessageLookupByLibrary.simpleMessage(
      "Settings could not be reset. No broker resources were removed.",
    ),
    "advancedPanelResetHint": MessageLookupByLibrary.simpleMessage(
      "Choose which settings and saved data to reset or reset everything",
    ),
    "advancedPanelResetHistory": MessageLookupByLibrary.simpleMessage(
      "History preferences",
    ),
    "advancedPanelResetPublishing": MessageLookupByLibrary.simpleMessage(
      "Publishing preferences",
    ),
    "advancedPanelResetSection": MessageLookupByLibrary.simpleMessage("Reset"),
    "advancedPanelResetSelectAll": MessageLookupByLibrary.simpleMessage(
      "Select all",
    ),
    "advancedPanelResetSelectedAction": MessageLookupByLibrary.simpleMessage(
      "Reset selected",
    ),
    "advancedPanelResetShortcuts": MessageLookupByLibrary.simpleMessage(
      "Shortcuts",
    ),
    "advancedPanelResetSuccess": MessageLookupByLibrary.simpleMessage(
      "The selected data was reset.",
    ),
    "advancedPanelResetTitle": MessageLookupByLibrary.simpleMessage(
      "Reset application data",
    ),
    "advancedPanelResetUpdates": MessageLookupByLibrary.simpleMessage(
      "Update preferences",
    ),
    "advancedPanelResetUserInterface": MessageLookupByLibrary.simpleMessage(
      "User interface",
    ),
    "advancedPanelResetVariables": MessageLookupByLibrary.simpleMessage(
      "Variables",
    ),
    "advancedPanelSettingsLocation": MessageLookupByLibrary.simpleMessage(
      "Settings location",
    ),
    "advancedPanelSettingsLocationHint": MessageLookupByLibrary.simpleMessage(
      "Application preferences are stored here. Broker passwords remain in the operating system credential store.",
    ),
    "advancedPanelStorageSection": MessageLookupByLibrary.simpleMessage(
      "Storage and diagnostics",
    ),
    "advancedPanelTitle": MessageLookupByLibrary.simpleMessage("Advanced"),
    "back": MessageLookupByLibrary.simpleMessage("Back"),
    "brokerDialogAddSubscription": MessageLookupByLibrary.simpleMessage(
      "Add Subscription",
    ),
    "brokerDialogAddTitle": MessageLookupByLibrary.simpleMessage("Add Broker"),
    "brokerDialogDefaultSubscriptionName": MessageLookupByLibrary.simpleMessage(
      "Every topic",
    ),
    "brokerDialogEditTitle": MessageLookupByLibrary.simpleMessage(
      "Edit Broker",
    ),
    "brokerDialogFieldClientId": MessageLookupByLibrary.simpleMessage(
      "Client ID",
    ),
    "brokerDialogFieldColor": MessageLookupByLibrary.simpleMessage("Color"),
    "brokerDialogFieldHost": MessageLookupByLibrary.simpleMessage("Host"),
    "brokerDialogFieldName": MessageLookupByLibrary.simpleMessage("Name"),
    "brokerDialogFieldPassword": MessageLookupByLibrary.simpleMessage(
      "Password",
    ),
    "brokerDialogFieldPort": MessageLookupByLibrary.simpleMessage("Port"),
    "brokerDialogFieldUsername": MessageLookupByLibrary.simpleMessage(
      "Username",
    ),
    "brokerDialogHistoryDisabled": MessageLookupByLibrary.simpleMessage(
      "History off",
    ),
    "brokerDialogHistoryMessages": MessageLookupByLibrary.simpleMessage(
      "history messages",
    ),
    "brokerDialogRandomSuffix": MessageLookupByLibrary.simpleMessage(
      "Random Suffix",
    ),
    "brokerDialogRandomSuffixSubtitle": MessageLookupByLibrary.simpleMessage(
      "Appends a random 6-digit hex suffix to the Client ID",
    ),
    "brokerDialogSectionAuthentication": MessageLookupByLibrary.simpleMessage(
      "Authentication",
    ),
    "brokerDialogSectionConnection": MessageLookupByLibrary.simpleMessage(
      "Connection",
    ),
    "brokerDialogSectionTopics": MessageLookupByLibrary.simpleMessage("Topics"),
    "brokerDialogUseSSL": MessageLookupByLibrary.simpleMessage("Use SSL / TLS"),
    "brokerDialogUseSSLSubtitle": MessageLookupByLibrary.simpleMessage(
      "Encrypts the connection using TLS",
    ),
    "brokerDialogValidateCertificates": MessageLookupByLibrary.simpleMessage(
      "Validate Certificates",
    ),
    "brokerDialogValidateCertificatesSubtitle":
        MessageLookupByLibrary.simpleMessage(
          "Validates the broker\'s SSL/TLS certificates",
        ),
    "brokerDialogValidateHost": MessageLookupByLibrary.simpleMessage(
      "Enter a host",
    ),
    "brokerDialogValidateName": MessageLookupByLibrary.simpleMessage(
      "Enter a name",
    ),
    "brokerProfilesUnavailable": MessageLookupByLibrary.simpleMessage(
      "Broker profiles unavailable",
    ),
    "brokersPanelAddBroker": MessageLookupByLibrary.simpleMessage("Add Broker"),
    "brokersPanelDescription": MessageLookupByLibrary.simpleMessage(
      "Configure MQTT brokers.",
    ),
    "brokersPanelNoBrokersMessage": MessageLookupByLibrary.simpleMessage(
      "Tap \'Add Broker\' to create your first broker.",
    ),
    "brokersPanelNoBrokersTitle": MessageLookupByLibrary.simpleMessage(
      "No brokers yet",
    ),
    "brokersPanelSectionConnections": MessageLookupByLibrary.simpleMessage(
      "Connections",
    ),
    "brokersPanelTitle": MessageLookupByLibrary.simpleMessage("Brokers"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "clearAllTopics": MessageLookupByLibrary.simpleMessage("Clear all topics"),
    "collapseAll": MessageLookupByLibrary.simpleMessage("Collapse all"),
    "copy": MessageLookupByLibrary.simpleMessage("Copy"),
    "dashboardDialogEditTitle": MessageLookupByLibrary.simpleMessage(
      "Edit Dashboard",
    ),
    "dashboardDialogFieldName": MessageLookupByLibrary.simpleMessage("Name"),
    "dashboardDialogNewTitle": MessageLookupByLibrary.simpleMessage(
      "New Dashboard",
    ),
    "dashboardDialogScopeBrokersSubtitle": MessageLookupByLibrary.simpleMessage(
      "Only for selected brokers",
    ),
    "dashboardDialogScopeGlobalSubtitle": MessageLookupByLibrary.simpleMessage(
      "Use dashboard across all brokers",
    ),
    "dashboardDialogSectionDetails": MessageLookupByLibrary.simpleMessage(
      "Details",
    ),
    "dashboardDialogSectionScope": MessageLookupByLibrary.simpleMessage(
      "Scope",
    ),
    "dashboardDialogValidateName": MessageLookupByLibrary.simpleMessage(
      "Name is required",
    ),
    "dashboardEraseHistory": MessageLookupByLibrary.simpleMessage(
      "Erase history",
    ),
    "dashboardPanelAddDashboard": MessageLookupByLibrary.simpleMessage(
      "Add dashboard",
    ),
    "dashboardPanelChartType": MessageLookupByLibrary.simpleMessage(
      "Chart type",
    ),
    "dashboardPanelColor": MessageLookupByLibrary.simpleMessage("Color"),
    "dashboardPanelDashboards": MessageLookupByLibrary.simpleMessage(
      "Dashboards",
    ),
    "dashboardPanelDefaults": MessageLookupByLibrary.simpleMessage("Defaults"),
    "dashboardPanelDescription": MessageLookupByLibrary.simpleMessage(
      "Manage saved dashboard layouts.",
    ),
    "dashboardPanelDotSize": MessageLookupByLibrary.simpleMessage("Dot size"),
    "dashboardPanelDotSizeHint": MessageLookupByLibrary.simpleMessage(
      "Marker size for data points in new line graphs. Choose 0 to hide markers.",
    ),
    "dashboardPanelInterpolation": MessageLookupByLibrary.simpleMessage(
      "Interpolation",
    ),
    "dashboardPanelMaxSamples": MessageLookupByLibrary.simpleMessage("Samples"),
    "dashboardPanelMaxSamplesHint": MessageLookupByLibrary.simpleMessage(
      "Maximum number of recent values retained by each new graph.",
    ),
    "dashboardPanelNoDashboardsMessage": MessageLookupByLibrary.simpleMessage(
      "Create dashboard or save from dashboard view",
    ),
    "dashboardPanelNoDashboardsTitle": MessageLookupByLibrary.simpleMessage(
      "No dashboards yet",
    ),
    "dashboardPanelTitle": MessageLookupByLibrary.simpleMessage("Dashboard"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "detailClearRetained": MessageLookupByLibrary.simpleMessage(
      "Clear retained message",
    ),
    "detailDeleteTopic": MessageLookupByLibrary.simpleMessage("Delete topic"),
    "detailMessages": MessageLookupByLibrary.simpleMessage("Messages"),
    "detailNo": MessageLookupByLibrary.simpleMessage("No"),
    "detailPinnedToDashboard": MessageLookupByLibrary.simpleMessage(
      "Pinned to dashboard",
    ),
    "detailQoS": MessageLookupByLibrary.simpleMessage("QoS"),
    "detailRate": MessageLookupByLibrary.simpleMessage("Rate"),
    "detailRatePerSecond": m0,
    "detailRateValue": m1,
    "detailReceived": MessageLookupByLibrary.simpleMessage("Received"),
    "detailRetained": MessageLookupByLibrary.simpleMessage("Retained"),
    "detailRetainedClearFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to clear — not connected",
    ),
    "detailRetainedCleared": MessageLookupByLibrary.simpleMessage(
      "Retained message cleared",
    ),
    "detailShowLatest": MessageLookupByLibrary.simpleMessage("Show latest"),
    "detailSize": MessageLookupByLibrary.simpleMessage("Size"),
    "detailTopicDeleted": MessageLookupByLibrary.simpleMessage("Topic deleted"),
    "detailViewingMessage": m2,
    "detailWaitingForMessages": MessageLookupByLibrary.simpleMessage(
      "Waiting for messages…",
    ),
    "detailYes": MessageLookupByLibrary.simpleMessage("Yes"),
    "disconnect": MessageLookupByLibrary.simpleMessage("Disconnect"),
    "dismiss": MessageLookupByLibrary.simpleMessage("Dismiss"),
    "durationHours": m3,
    "durationLessThanSecond": MessageLookupByLibrary.simpleMessage(
      "< 1 second",
    ),
    "durationMinutes": m4,
    "durationSeconds": m5,
    "expandAll": MessageLookupByLibrary.simpleMessage("Expand all"),
    "filterNoMatchingTopics": MessageLookupByLibrary.simpleMessage(
      "No matching topics",
    ),
    "filterNoMatchingTopicsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Try adjusting or clearing the filter.",
    ),
    "hideDetails": MessageLookupByLibrary.simpleMessage("Hide details"),
    "historyPanelClear": MessageLookupByLibrary.simpleMessage("Clear"),
    "historyPanelDisabled": MessageLookupByLibrary.simpleMessage(
      "History disabled",
    ),
    "historyPanelDisabledHint": MessageLookupByLibrary.simpleMessage(
      "Live values continue, but new history is not stored",
    ),
    "historyPanelNoHistory": MessageLookupByLibrary.simpleMessage(
      "No history yet",
    ),
    "historyPanelNoHistoryHint": MessageLookupByLibrary.simpleMessage(
      "Messages will appear here as they arrive",
    ),
    "historyPanelNotSubscribed": MessageLookupByLibrary.simpleMessage(
      "No matching subscription",
    ),
    "historyPanelNotSubscribedHint": MessageLookupByLibrary.simpleMessage(
      "This topic is not covered by the active broker subscriptions",
    ),
    "historyPanelRetainingUpTo": MessageLookupByLibrary.simpleMessage(
      "Retaining up to",
    ),
    "historyPanelStored": MessageLookupByLibrary.simpleMessage("stored"),
    "languageNameDe": MessageLookupByLibrary.simpleMessage("German"),
    "languageNameEn": MessageLookupByLibrary.simpleMessage("English"),
    "languageNameEs": MessageLookupByLibrary.simpleMessage("Spanish"),
    "languageNameFr": MessageLookupByLibrary.simpleMessage("French"),
    "languageNameNl": MessageLookupByLibrary.simpleMessage("Dutch"),
    "languagePanelChangesNote": MessageLookupByLibrary.simpleMessage(
      "Changes will apply on next launch.",
    ),
    "languagePanelDescription": MessageLookupByLibrary.simpleMessage(
      "Select the interface language.",
    ),
    "languagePanelSectionLabel": MessageLookupByLibrary.simpleMessage(
      "Interface Language",
    ),
    "languagePanelTitle": MessageLookupByLibrary.simpleMessage("Language"),
    "monitoringPanelClearAll": MessageLookupByLibrary.simpleMessage(
      "Clear all",
    ),
    "monitoringPanelDescription": MessageLookupByLibrary.simpleMessage(
      "Configure live message-rate sampling.",
    ),
    "monitoringPanelIncreasedBufferHint": MessageLookupByLibrary.simpleMessage(
      "Messages for monitored topics",
    ),
    "monitoringPanelIncreasedBufferSize": MessageLookupByLibrary.simpleMessage(
      "Increased buffer size",
    ),
    "monitoringPanelIncreasedMonitoring": MessageLookupByLibrary.simpleMessage(
      "Increased monitoring",
    ),
    "monitoringPanelRateSampleHint": MessageLookupByLibrary.simpleMessage(
      "Messages used to calculate rate",
    ),
    "monitoringPanelRateSampleSize": MessageLookupByLibrary.simpleMessage(
      "Rate sample size",
    ),
    "monitoringPanelRateSampling": MessageLookupByLibrary.simpleMessage(
      "Rate sampling",
    ),
    "monitoringPanelTitle": MessageLookupByLibrary.simpleMessage("Monitoring"),
    "noBroker": MessageLookupByLibrary.simpleMessage("No Broker"),
    "noMessagesSubtitle": MessageLookupByLibrary.simpleMessage(
      "No messages received yet.",
    ),
    "noMessagesTitle": MessageLookupByLibrary.simpleMessage(
      "Waiting for messages",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("Optional"),
    "publishAcknowledged": MessageLookupByLibrary.simpleMessage("Sent"),
    "publishBadJson": MessageLookupByLibrary.simpleMessage("Bad JSON"),
    "publishDelivered": MessageLookupByLibrary.simpleMessage("Delivered"),
    "publishFailed": MessageLookupByLibrary.simpleMessage("Failed"),
    "publishInvalidQos": MessageLookupByLibrary.simpleMessage(
      "QoS must be 0, 1, or 2",
    ),
    "publishInvalidTemplate": MessageLookupByLibrary.simpleMessage(
      "Put the variable name inside dollar-sign braces",
    ),
    "publishInvalidTopic": MessageLookupByLibrary.simpleMessage(
      "Enter a valid MQTT topic name",
    ),
    "publishMissingVariables": MessageLookupByLibrary.simpleMessage(
      "Set every topic variable before publishing",
    ),
    "publishNoTopic": MessageLookupByLibrary.simpleMessage("No topic"),
    "publishOffline": MessageLookupByLibrary.simpleMessage("Offline"),
    "publishPrettifyJson": MessageLookupByLibrary.simpleMessage(
      "Prettify JSON",
    ),
    "publishRetain": MessageLookupByLibrary.simpleMessage("Retain"),
    "publishSending": MessageLookupByLibrary.simpleMessage("Sending…"),
    "publishSent": MessageLookupByLibrary.simpleMessage("Sent"),
    "publishTimedOut": MessageLookupByLibrary.simpleMessage("Timed out"),
    "publishTopicHint": MessageLookupByLibrary.simpleMessage("example/topic"),
    "reconnect": MessageLookupByLibrary.simpleMessage("Reconnect"),
    "remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "scopeGlobal": MessageLookupByLibrary.simpleMessage("Global"),
    "scopeSelectedBrokers": MessageLookupByLibrary.simpleMessage(
      "Selected brokers",
    ),
    "scopeSpecificBrokers": MessageLookupByLibrary.simpleMessage(
      "Specific brokers",
    ),
    "searchHint": MessageLookupByLibrary.simpleMessage("Search"),
    "searchScopeAll": MessageLookupByLibrary.simpleMessage("All"),
    "searchScopeTopic": MessageLookupByLibrary.simpleMessage("Topic"),
    "searchScopeValue": MessageLookupByLibrary.simpleMessage("Value"),
    "sectionAbout": MessageLookupByLibrary.simpleMessage("About"),
    "sectionAdvanced": MessageLookupByLibrary.simpleMessage("Advanced"),
    "sectionBrokers": MessageLookupByLibrary.simpleMessage("Brokers"),
    "sectionDashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
    "sectionLanguage": MessageLookupByLibrary.simpleMessage("Language"),
    "sectionMonitoring": MessageLookupByLibrary.simpleMessage("Monitoring"),
    "sectionShortcuts": MessageLookupByLibrary.simpleMessage("Shortcuts"),
    "sectionUI": MessageLookupByLibrary.simpleMessage("User Interface"),
    "sectionVariables": MessageLookupByLibrary.simpleMessage("Variables"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "shortcutDialogAddTitle": MessageLookupByLibrary.simpleMessage(
      "Add Shortcut",
    ),
    "shortcutDialogEditTitle": MessageLookupByLibrary.simpleMessage(
      "Edit Shortcut",
    ),
    "shortcutDialogFieldColor": MessageLookupByLibrary.simpleMessage("Color"),
    "shortcutDialogFieldName": MessageLookupByLibrary.simpleMessage("Name"),
    "shortcutDialogFieldTopic": MessageLookupByLibrary.simpleMessage("Topic"),
    "shortcutDialogInvalidTemplate": MessageLookupByLibrary.simpleMessage(
      "Put the variable name inside dollar-sign braces",
    ),
    "shortcutDialogInvalidTopic": MessageLookupByLibrary.simpleMessage(
      "Enter a valid MQTT topic name",
    ),
    "shortcutDialogRetain": MessageLookupByLibrary.simpleMessage("Retain"),
    "shortcutDialogRetainSubtitle": MessageLookupByLibrary.simpleMessage(
      "Broker stores the message for new subscribers",
    ),
    "shortcutDialogScopeBrokersSubtitle": MessageLookupByLibrary.simpleMessage(
      "Only for selected brokers",
    ),
    "shortcutDialogScopeGlobalSubtitle": MessageLookupByLibrary.simpleMessage(
      "Available across all brokers",
    ),
    "shortcutDialogValidateName": MessageLookupByLibrary.simpleMessage(
      "Enter a name",
    ),
    "shortcutDialogValidateTopic": MessageLookupByLibrary.simpleMessage(
      "Enter a topic",
    ),
    "shortcutsPanelAddShortcut": MessageLookupByLibrary.simpleMessage(
      "Add Shortcut",
    ),
    "shortcutsPanelDefinedShortcuts": MessageLookupByLibrary.simpleMessage(
      "Defined Shortcuts",
    ),
    "shortcutsPanelDescription": MessageLookupByLibrary.simpleMessage(
      "Define publish shortcuts for quickly sending messages to topics.",
    ),
    "shortcutsPanelNoShortcutsMessage": MessageLookupByLibrary.simpleMessage(
      "Add a shortcut to quickly publish\nto your favorite topics.",
    ),
    "shortcutsPanelNoShortcutsTitle": MessageLookupByLibrary.simpleMessage(
      "No shortcuts yet",
    ),
    "shortcutsPanelTitle": MessageLookupByLibrary.simpleMessage("Shortcuts"),
    "showDetails": MessageLookupByLibrary.simpleMessage("Show details"),
    "sidebarHistory": MessageLookupByLibrary.simpleMessage("HISTORY"),
    "sidebarMessageDetail": MessageLookupByLibrary.simpleMessage(
      "MESSAGE DETAIL",
    ),
    "sidebarNoSelectionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Choose a topic from the tree\nto view message details",
    ),
    "sidebarNoSelectionTitle": MessageLookupByLibrary.simpleMessage(
      "Select a topic to inspect",
    ),
    "sidebarPublish": MessageLookupByLibrary.simpleMessage("PUBLISH"),
    "sidebarResizeDetailHistory": MessageLookupByLibrary.simpleMessage(
      "Resize Message Detail and History",
    ),
    "sidebarResizeDetailPublish": MessageLookupByLibrary.simpleMessage(
      "Resize Message Detail and Publish",
    ),
    "sidebarResizeDetailShortcuts": MessageLookupByLibrary.simpleMessage(
      "Resize Message Detail and Shortcuts",
    ),
    "sidebarResizeHistoryPublish": MessageLookupByLibrary.simpleMessage(
      "Resize History and Publish",
    ),
    "sidebarResizeHistoryShortcuts": MessageLookupByLibrary.simpleMessage(
      "Resize History and Shortcuts",
    ),
    "sidebarResizePublishShortcuts": MessageLookupByLibrary.simpleMessage(
      "Resize Publish and Shortcuts",
    ),
    "sidebarShortcuts": MessageLookupByLibrary.simpleMessage("SHORTCUTS"),
    "sidebarShortcutsEmpty": MessageLookupByLibrary.simpleMessage(
      "No shortcuts available.\nAdd shortcuts in Settings.",
    ),
    "sidebarShortcutsManage": MessageLookupByLibrary.simpleMessage(
      "Manage Shortcuts",
    ),
    "statusConnected": MessageLookupByLibrary.simpleMessage("Connected"),
    "statusConnecting": MessageLookupByLibrary.simpleMessage("Connecting"),
    "statusConnectionRefused": MessageLookupByLibrary.simpleMessage(
      "Connection refused",
    ),
    "statusDisconnected": MessageLookupByLibrary.simpleMessage("Disconnected"),
    "statusError": MessageLookupByLibrary.simpleMessage("Error"),
    "statusHostNotFound": MessageLookupByLibrary.simpleMessage(
      "Host not found",
    ),
    "statusMessages": m6,
    "statusMqtt311Detail": MessageLookupByLibrary.simpleMessage(
      "MQTT 3.1.1 — broker does not return delivery reasons",
    ),
    "statusMqtt5Detail": MessageLookupByLibrary.simpleMessage(
      "MQTT 5.0 — reason codes and properties available",
    ),
    "statusNotPermitted": MessageLookupByLibrary.simpleMessage("Not permitted"),
    "statusOpenUpdateSettings": MessageLookupByLibrary.simpleMessage(
      "Open update settings",
    ),
    "statusTlsFailed": MessageLookupByLibrary.simpleMessage("TLS failed"),
    "statusUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "Update available",
    ),
    "subscriptionDialogAddTitle": MessageLookupByLibrary.simpleMessage(
      "Add Subscription",
    ),
    "subscriptionDialogDuplicateTopicFilter":
        MessageLookupByLibrary.simpleMessage(
          "This broker already has that topic filter",
        ),
    "subscriptionDialogEditTitle": MessageLookupByLibrary.simpleMessage(
      "Edit Subscription",
    ),
    "subscriptionDialogFieldDisplayName": MessageLookupByLibrary.simpleMessage(
      "Display Name",
    ),
    "subscriptionDialogFieldTopicFilter": MessageLookupByLibrary.simpleMessage(
      "Topic Filter",
    ),
    "subscriptionDialogHintDisplayName": MessageLookupByLibrary.simpleMessage(
      "Optional friendly name",
    ),
    "subscriptionDialogHistoryEnabled": MessageLookupByLibrary.simpleMessage(
      "Store message history",
    ),
    "subscriptionDialogHistoryEnabledHint":
        MessageLookupByLibrary.simpleMessage(
          "Live messages remain available when history is off",
        ),
    "subscriptionDialogHistoryLabel": MessageLookupByLibrary.simpleMessage(
      "History",
    ),
    "subscriptionDialogHistoryOverlapHint": MessageLookupByLibrary.simpleMessage(
      "When enabled filters overlap, the largest matching retention is used.",
    ),
    "subscriptionDialogHistoryRetention": MessageLookupByLibrary.simpleMessage(
      "Retention",
    ),
    "subscriptionDialogHistoryRetentionHint":
        MessageLookupByLibrary.simpleMessage(
          "Messages kept for topics matched by this subscription",
        ),
    "subscriptionDialogInvalidTopicFilter":
        MessageLookupByLibrary.simpleMessage("Enter a valid MQTT topic filter"),
    "subscriptionDialogQoS0Description": MessageLookupByLibrary.simpleMessage(
      "At most once",
    ),
    "subscriptionDialogQoS0Label": MessageLookupByLibrary.simpleMessage(
      "QoS 0",
    ),
    "subscriptionDialogQoS1Description": MessageLookupByLibrary.simpleMessage(
      "At least once",
    ),
    "subscriptionDialogQoS1Label": MessageLookupByLibrary.simpleMessage(
      "QoS 1",
    ),
    "subscriptionDialogQoS2Description": MessageLookupByLibrary.simpleMessage(
      "Exactly once",
    ),
    "subscriptionDialogQoS2Label": MessageLookupByLibrary.simpleMessage(
      "QoS 2",
    ),
    "subscriptionDialogQoSLabel": MessageLookupByLibrary.simpleMessage(
      "Quality of Service",
    ),
    "subscriptionDialogValidateTopicFilter":
        MessageLookupByLibrary.simpleMessage("Enter a topic filter"),
    "uiPanelAccentColor": MessageLookupByLibrary.simpleMessage("Accent color"),
    "uiPanelDefaultBrokerProtocol": MessageLookupByLibrary.simpleMessage(
      "Default protocol for new brokers",
    ),
    "uiPanelDefaultPublishQos": MessageLookupByLibrary.simpleMessage(
      "Default publish QoS",
    ),
    "uiPanelDefaultPublishQosSubtitle": MessageLookupByLibrary.simpleMessage(
      "QoS used for new publish messages",
    ),
    "uiPanelDefaultShortcutQos": MessageLookupByLibrary.simpleMessage(
      "Default shortcut QoS",
    ),
    "uiPanelDefaultShortcutQosSubtitle": MessageLookupByLibrary.simpleMessage(
      "QoS used for new publish shortcuts",
    ),
    "uiPanelDefaultStateCollapsed": MessageLookupByLibrary.simpleMessage(
      "Collapsed",
    ),
    "uiPanelDefaultStateExpanded": MessageLookupByLibrary.simpleMessage(
      "Expanded",
    ),
    "uiPanelDefaultStateLastStatus": MessageLookupByLibrary.simpleMessage(
      "Last Status",
    ),
    "uiPanelDefaultSubscribeQos": MessageLookupByLibrary.simpleMessage(
      "Default subscribe QoS",
    ),
    "uiPanelDefaultSubscribeQosSubtitle": MessageLookupByLibrary.simpleMessage(
      "QoS used for new subscriptions",
    ),
    "uiPanelDescription": MessageLookupByLibrary.simpleMessage(
      "Appearance and layout preferences.",
    ),
    "uiPanelDisableSelectionHighlight": MessageLookupByLibrary.simpleMessage(
      "Disable selection highlight",
    ),
    "uiPanelDisableSelectionHighlightSubtitle":
        MessageLookupByLibrary.simpleMessage(
          "Hide the selected-topic highlight so activity pulses stay visible on the active topic",
        ),
    "uiPanelPersistLayout": MessageLookupByLibrary.simpleMessage(
      "Persist Layout",
    ),
    "uiPanelPersistLayoutSubtitle": MessageLookupByLibrary.simpleMessage(
      "Restore panel sizes and positions on restart",
    ),
    "uiPanelPulseFade": MessageLookupByLibrary.simpleMessage("Pulse fade"),
    "uiPanelPulseFadeSubtitle": MessageLookupByLibrary.simpleMessage(
      "Duration of the fade-out animation",
    ),
    "uiPanelPulseRate": MessageLookupByLibrary.simpleMessage("Pulse rate"),
    "uiPanelPulseRateSubtitle": MessageLookupByLibrary.simpleMessage(
      "Maximum activity pulses per second",
    ),
    "uiPanelQosOptionLastUsed": MessageLookupByLibrary.simpleMessage(
      "Last used",
    ),
    "uiPanelQosOptionLastUsedSubtitle": MessageLookupByLibrary.simpleMessage(
      "Reuse the QoS you most recently picked",
    ),
    "uiPanelRateInterval": MessageLookupByLibrary.simpleMessage(
      "Rate update interval",
    ),
    "uiPanelRateIntervalSubtitle": MessageLookupByLibrary.simpleMessage(
      "How often the message rate is recalculated",
    ),
    "uiPanelSectionAppearance": MessageLookupByLibrary.simpleMessage(
      "Appearance",
    ),
    "uiPanelSectionConnection": MessageLookupByLibrary.simpleMessage(
      "Connection",
    ),
    "uiPanelSectionDataDisplay": MessageLookupByLibrary.simpleMessage(
      "Data Display",
    ),
    "uiPanelSectionDefaults": MessageLookupByLibrary.simpleMessage("Defaults"),
    "uiPanelSectionLayout": MessageLookupByLibrary.simpleMessage("Layout"),
    "uiPanelSectionSidebarPanels": MessageLookupByLibrary.simpleMessage(
      "Sidebar Panels",
    ),
    "uiPanelShowActivity": MessageLookupByLibrary.simpleMessage(
      "Show activity",
    ),
    "uiPanelShowActivitySubtitle": MessageLookupByLibrary.simpleMessage(
      "Pulse topic when activity occurs",
    ),
    "uiPanelShowStatusBar": MessageLookupByLibrary.simpleMessage(
      "Show status bar",
    ),
    "uiPanelShowStatusBarSubtitle": MessageLookupByLibrary.simpleMessage(
      "Shows the bottom status bar",
    ),
    "uiPanelSidebarAnimationSpeed": MessageLookupByLibrary.simpleMessage(
      "Panel animation speed",
    ),
    "uiPanelSidebarAnimationSpeedSubtitle":
        MessageLookupByLibrary.simpleMessage(
          "How quickly right sidebar panels move",
        ),
    "uiPanelSidebarAnimations": MessageLookupByLibrary.simpleMessage(
      "Right panel animations",
    ),
    "uiPanelSidebarAnimationsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Animate panels when they expand or collapse",
    ),
    "uiPanelStartupBehavior": MessageLookupByLibrary.simpleMessage(
      "Startup Behavior",
    ),
    "uiPanelStartupConnect": MessageLookupByLibrary.simpleMessage("Connect"),
    "uiPanelStartupDisconnected": MessageLookupByLibrary.simpleMessage(
      "Disconnected",
    ),
    "uiPanelStartupLastStatus": MessageLookupByLibrary.simpleMessage(
      "Last Status",
    ),
    "uiPanelThemeDark": MessageLookupByLibrary.simpleMessage("Dark"),
    "uiPanelThemeLight": MessageLookupByLibrary.simpleMessage("Light"),
    "uiPanelThemeMode": MessageLookupByLibrary.simpleMessage("Theme Mode"),
    "uiPanelThemeSystem": MessageLookupByLibrary.simpleMessage("System"),
    "uiPanelTitle": MessageLookupByLibrary.simpleMessage("User Interface"),
    "variableDialogAddOption": MessageLookupByLibrary.simpleMessage(
      "Add Option",
    ),
    "variableDialogAddTitle": MessageLookupByLibrary.simpleMessage(
      "Add Variable",
    ),
    "variableDialogDisplayName": MessageLookupByLibrary.simpleMessage(
      "Display name",
    ),
    "variableDialogEditTitle": MessageLookupByLibrary.simpleMessage(
      "Edit Variable",
    ),
    "variableDialogFieldName": MessageLookupByLibrary.simpleMessage("Name"),
    "variableDialogNameExists": MessageLookupByLibrary.simpleMessage(
      "A variable with this name already exists",
    ),
    "variableDialogNameInvalid": MessageLookupByLibrary.simpleMessage(
      "Name cannot contain spaces or special characters",
    ),
    "variableDialogOptionsHint": MessageLookupByLibrary.simpleMessage(
      "Options let you pick from a list in the dashboard instead of typing each time.",
    ),
    "variableDialogPredefinedOptions": MessageLookupByLibrary.simpleMessage(
      "Pre-defined Options",
    ),
    "variableDialogScopeBrokersSubtitle": MessageLookupByLibrary.simpleMessage(
      "Only for selected brokers",
    ),
    "variableDialogScopeGlobalSubtitle": MessageLookupByLibrary.simpleMessage(
      "Available across all brokers",
    ),
    "variableDialogValidateName": MessageLookupByLibrary.simpleMessage(
      "Enter a variable name",
    ),
    "variableDialogValue": MessageLookupByLibrary.simpleMessage("Value"),
    "variablesPanelAddVariable": MessageLookupByLibrary.simpleMessage(
      "Add Variable",
    ),
    "variablesPanelDefinedVariables": MessageLookupByLibrary.simpleMessage(
      "Defined Variables",
    ),
    "variablesPanelDescription": MessageLookupByLibrary.simpleMessage(
      "Define environment variables to use as placeholders in chart topic strings.",
    ),
    "variablesPanelNoOptions": MessageLookupByLibrary.simpleMessage(
      "No options",
    ),
    "variablesPanelNoVariablesMessage": MessageLookupByLibrary.simpleMessage(
      "Add a variable to use as a placeholder\nin your chart topic strings.",
    ),
    "variablesPanelNoVariablesTitle": MessageLookupByLibrary.simpleMessage(
      "No variables yet",
    ),
    "variablesPanelOptionsCount": m7,
    "variablesPanelTitle": MessageLookupByLibrary.simpleMessage("Variables"),
  };
}
