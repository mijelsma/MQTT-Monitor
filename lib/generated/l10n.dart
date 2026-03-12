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

  /// `Hello`
  String get hello {
    return Intl.message('Hello', name: 'hello', desc: '', args: []);
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

  /// `Brokers`
  String get sectionBrokers {
    return Intl.message('Brokers', name: 'sectionBrokers', desc: '', args: []);
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

  /// `UI`
  String get uiPanelTitle {
    return Intl.message('UI', name: 'uiPanelTitle', desc: '', args: []);
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
  String get brokerModalEditTitle {
    return Intl.message(
      'Edit Broker',
      name: 'brokerModalEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add Broker`
  String get brokerModalAddTitle {
    return Intl.message(
      'Add Broker',
      name: 'brokerModalAddTitle',
      desc: '',
      args: [],
    );
  }

  /// `Connection`
  String get brokerModalSectionConnection {
    return Intl.message(
      'Connection',
      name: 'brokerModalSectionConnection',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get brokerModalFieldName {
    return Intl.message(
      'Name',
      name: 'brokerModalFieldName',
      desc: '',
      args: [],
    );
  }

  /// `Color`
  String get brokerModalFieldColor {
    return Intl.message(
      'Color',
      name: 'brokerModalFieldColor',
      desc: '',
      args: [],
    );
  }

  /// `Enter a name`
  String get brokerModalValidateName {
    return Intl.message(
      'Enter a name',
      name: 'brokerModalValidateName',
      desc: '',
      args: [],
    );
  }

  /// `Host`
  String get brokerModalFieldHost {
    return Intl.message(
      'Host',
      name: 'brokerModalFieldHost',
      desc: '',
      args: [],
    );
  }

  /// `Enter a host`
  String get brokerModalValidateHost {
    return Intl.message(
      'Enter a host',
      name: 'brokerModalValidateHost',
      desc: '',
      args: [],
    );
  }

  /// `Port`
  String get brokerModalFieldPort {
    return Intl.message(
      'Port',
      name: 'brokerModalFieldPort',
      desc: '',
      args: [],
    );
  }

  /// `Use SSL / TLS`
  String get brokerModalUseSSL {
    return Intl.message(
      'Use SSL / TLS',
      name: 'brokerModalUseSSL',
      desc: '',
      args: [],
    );
  }

  /// `Encrypts the connection using TLS`
  String get brokerModalUseSSLSubtitle {
    return Intl.message(
      'Encrypts the connection using TLS',
      name: 'brokerModalUseSSLSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Validate Certificates`
  String get brokerModalValidateCertificates {
    return Intl.message(
      'Validate Certificates',
      name: 'brokerModalValidateCertificates',
      desc: '',
      args: [],
    );
  }

  /// `Validates the broker's SSL/TLS certificates`
  String get brokerModalValidateCertificatesSubtitle {
    return Intl.message(
      'Validates the broker\'s SSL/TLS certificates',
      name: 'brokerModalValidateCertificatesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Client ID`
  String get brokerModalFieldClientId {
    return Intl.message(
      'Client ID',
      name: 'brokerModalFieldClientId',
      desc: '',
      args: [],
    );
  }

  /// `Random Suffix`
  String get brokerModalRandomSuffix {
    return Intl.message(
      'Random Suffix',
      name: 'brokerModalRandomSuffix',
      desc: '',
      args: [],
    );
  }

  /// `Appends a random 6-digit hex suffix to the Client ID`
  String get brokerModalRandomSuffixSubtitle {
    return Intl.message(
      'Appends a random 6-digit hex suffix to the Client ID',
      name: 'brokerModalRandomSuffixSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Authentication`
  String get brokerModalSectionAuthentication {
    return Intl.message(
      'Authentication',
      name: 'brokerModalSectionAuthentication',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get brokerModalFieldUsername {
    return Intl.message(
      'Username',
      name: 'brokerModalFieldUsername',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get brokerModalFieldPassword {
    return Intl.message(
      'Password',
      name: 'brokerModalFieldPassword',
      desc: '',
      args: [],
    );
  }

  /// `Topics`
  String get brokerModalSectionTopics {
    return Intl.message(
      'Topics',
      name: 'brokerModalSectionTopics',
      desc: '',
      args: [],
    );
  }

  /// `Add Subscription`
  String get brokerModalAddSubscription {
    return Intl.message(
      'Add Subscription',
      name: 'brokerModalAddSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Edit Subscription`
  String get subscriptionModalEditTitle {
    return Intl.message(
      'Edit Subscription',
      name: 'subscriptionModalEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add Subscription`
  String get subscriptionModalAddTitle {
    return Intl.message(
      'Add Subscription',
      name: 'subscriptionModalAddTitle',
      desc: '',
      args: [],
    );
  }

  /// `Topic Filter`
  String get subscriptionModalFieldTopicFilter {
    return Intl.message(
      'Topic Filter',
      name: 'subscriptionModalFieldTopicFilter',
      desc: '',
      args: [],
    );
  }

  /// `Enter a topic filter`
  String get subscriptionModalValidateTopicFilter {
    return Intl.message(
      'Enter a topic filter',
      name: 'subscriptionModalValidateTopicFilter',
      desc: '',
      args: [],
    );
  }

  /// `Display Name`
  String get subscriptionModalFieldDisplayName {
    return Intl.message(
      'Display Name',
      name: 'subscriptionModalFieldDisplayName',
      desc: '',
      args: [],
    );
  }

  /// `Optional friendly name`
  String get subscriptionModalHintDisplayName {
    return Intl.message(
      'Optional friendly name',
      name: 'subscriptionModalHintDisplayName',
      desc: '',
      args: [],
    );
  }

  /// `Quality of Service`
  String get subscriptionModalQoSLabel {
    return Intl.message(
      'Quality of Service',
      name: 'subscriptionModalQoSLabel',
      desc: '',
      args: [],
    );
  }

  /// `QoS 0`
  String get subscriptionModalQoS0Label {
    return Intl.message(
      'QoS 0',
      name: 'subscriptionModalQoS0Label',
      desc: '',
      args: [],
    );
  }

  /// `At most once`
  String get subscriptionModalQoS0Description {
    return Intl.message(
      'At most once',
      name: 'subscriptionModalQoS0Description',
      desc: '',
      args: [],
    );
  }

  /// `QoS 1`
  String get subscriptionModalQoS1Label {
    return Intl.message(
      'QoS 1',
      name: 'subscriptionModalQoS1Label',
      desc: '',
      args: [],
    );
  }

  /// `At least once`
  String get subscriptionModalQoS1Description {
    return Intl.message(
      'At least once',
      name: 'subscriptionModalQoS1Description',
      desc: '',
      args: [],
    );
  }

  /// `QoS 2`
  String get subscriptionModalQoS2Label {
    return Intl.message(
      'QoS 2',
      name: 'subscriptionModalQoS2Label',
      desc: '',
      args: [],
    );
  }

  /// `Exactly once`
  String get subscriptionModalQoS2Description {
    return Intl.message(
      'Exactly once',
      name: 'subscriptionModalQoS2Description',
      desc: '',
      args: [],
    );
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
