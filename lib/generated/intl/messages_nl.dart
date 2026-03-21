// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a nl locale. All the
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
  String get localeName => 'nl';

  static String m0(count) => "${count} berichten per seconde";

  static String m1(interval) => "1 bericht elke ${interval}";

  static String m2(seq) => "Bericht #${seq} bekijken";

  static String m3(count) =>
      "${count} ${Intl.plural(count, one: 'uur', other: 'uur')}";

  static String m4(count) =>
      "${count} ${Intl.plural(count, one: 'minuut', other: 'minuten')}";

  static String m5(count) =>
      "${count} ${Intl.plural(count, one: 'seconde', other: 'seconden')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aboutPanelAuthor": MessageLookupByLibrary.simpleMessage("Auteur"),
    "aboutPanelChangelog": MessageLookupByLibrary.simpleMessage("Changelog"),
    "aboutPanelCommitHash": MessageLookupByLibrary.simpleMessage("Commit Hash"),
    "aboutPanelLicense": MessageLookupByLibrary.simpleMessage("Licentie"),
    "aboutPanelReportIssue": MessageLookupByLibrary.simpleMessage(
      "Probleem melden",
    ),
    "aboutPanelSectionDetails": MessageLookupByLibrary.simpleMessage("Details"),
    "aboutPanelSectionResources": MessageLookupByLibrary.simpleMessage(
      "Bronnen",
    ),
    "aboutPanelSourceCode": MessageLookupByLibrary.simpleMessage("Broncode"),
    "aboutPanelSupportProject": MessageLookupByLibrary.simpleMessage(
      "Project steunen",
    ),
    "aboutPanelTitle": MessageLookupByLibrary.simpleMessage("Over"),
    "aboutPanelVersion": MessageLookupByLibrary.simpleMessage(
      "Versie 1.0.0  ·  Build 1",
    ),
    "add": MessageLookupByLibrary.simpleMessage("Toevoegen"),
    "back": MessageLookupByLibrary.simpleMessage("Terug"),
    "brokerDialogAddSubscription": MessageLookupByLibrary.simpleMessage(
      "Abonnement toevoegen",
    ),
    "brokerDialogAddTitle": MessageLookupByLibrary.simpleMessage(
      "Broker toevoegen",
    ),
    "brokerDialogEditTitle": MessageLookupByLibrary.simpleMessage(
      "Broker bewerken",
    ),
    "brokerDialogFieldClientId": MessageLookupByLibrary.simpleMessage(
      "Client-ID",
    ),
    "brokerDialogFieldColor": MessageLookupByLibrary.simpleMessage("Kleur"),
    "brokerDialogFieldHost": MessageLookupByLibrary.simpleMessage("Host"),
    "brokerDialogFieldName": MessageLookupByLibrary.simpleMessage("Naam"),
    "brokerDialogFieldPassword": MessageLookupByLibrary.simpleMessage(
      "Wachtwoord",
    ),
    "brokerDialogFieldPort": MessageLookupByLibrary.simpleMessage("Poort"),
    "brokerDialogFieldUsername": MessageLookupByLibrary.simpleMessage(
      "Gebruikersnaam",
    ),
    "brokerDialogRandomSuffix": MessageLookupByLibrary.simpleMessage(
      "Willekeurig achtervoegsel",
    ),
    "brokerDialogRandomSuffixSubtitle": MessageLookupByLibrary.simpleMessage(
      "Voegt een willekeurig 6-cijferig hex-achtervoegsel toe aan het Client-ID",
    ),
    "brokerDialogSectionAuthentication": MessageLookupByLibrary.simpleMessage(
      "Verificatie",
    ),
    "brokerDialogSectionConnection": MessageLookupByLibrary.simpleMessage(
      "Verbinding",
    ),
    "brokerDialogSectionTopics": MessageLookupByLibrary.simpleMessage(
      "Onderwerpen",
    ),
    "brokerDialogUseSSL": MessageLookupByLibrary.simpleMessage(
      "SSL / TLS gebruiken",
    ),
    "brokerDialogUseSSLSubtitle": MessageLookupByLibrary.simpleMessage(
      "Versleutelt de verbinding met TLS",
    ),
    "brokerDialogValidateCertificates": MessageLookupByLibrary.simpleMessage(
      "Certificaten valideren",
    ),
    "brokerDialogValidateCertificatesSubtitle":
        MessageLookupByLibrary.simpleMessage(
          "Valideert de SSL/TLS-certificaten van de broker",
        ),
    "brokerDialogValidateHost": MessageLookupByLibrary.simpleMessage(
      "Voer een host in",
    ),
    "brokerDialogValidateName": MessageLookupByLibrary.simpleMessage(
      "Voer een naam in",
    ),
    "brokersPanelAddBroker": MessageLookupByLibrary.simpleMessage(
      "Broker toevoegen",
    ),
    "brokersPanelDescription": MessageLookupByLibrary.simpleMessage(
      "MQTT-brokers configureren.",
    ),
    "brokersPanelNoBrokersMessage": MessageLookupByLibrary.simpleMessage(
      "Druk op \'Broker toevoegen\' om je eerste broker aan te maken.",
    ),
    "brokersPanelNoBrokersTitle": MessageLookupByLibrary.simpleMessage(
      "Nog geen brokers",
    ),
    "brokersPanelSectionConnections": MessageLookupByLibrary.simpleMessage(
      "Verbindingen",
    ),
    "brokersPanelTitle": MessageLookupByLibrary.simpleMessage("Brokers"),
    "cancel": MessageLookupByLibrary.simpleMessage("Annuleren"),
    "collapseAll": MessageLookupByLibrary.simpleMessage("Alles inklappen"),
    "dashboardDialogEditTitle": MessageLookupByLibrary.simpleMessage(
      "Dashboard bewerken",
    ),
    "dashboardDialogFieldName": MessageLookupByLibrary.simpleMessage("Naam"),
    "dashboardDialogNewTitle": MessageLookupByLibrary.simpleMessage(
      "Nieuw dashboard",
    ),
    "dashboardDialogScopeBrokersSubtitle": MessageLookupByLibrary.simpleMessage(
      "Alleen voor geselecteerde brokers",
    ),
    "dashboardDialogScopeGlobalSubtitle": MessageLookupByLibrary.simpleMessage(
      "Dashboard gebruiken voor alle brokers",
    ),
    "dashboardDialogSectionDetails": MessageLookupByLibrary.simpleMessage(
      "Details",
    ),
    "dashboardDialogSectionScope": MessageLookupByLibrary.simpleMessage(
      "Bereik",
    ),
    "dashboardDialogValidateName": MessageLookupByLibrary.simpleMessage(
      "Naam is verplicht",
    ),
    "dashboardEraseHistory": MessageLookupByLibrary.simpleMessage(
      "Geschiedenis wissen",
    ),
    "dashboardPanelAddDashboard": MessageLookupByLibrary.simpleMessage(
      "Dashboard toevoegen",
    ),
    "dashboardPanelChartType": MessageLookupByLibrary.simpleMessage(
      "Grafiektype",
    ),
    "dashboardPanelColor": MessageLookupByLibrary.simpleMessage("Kleur"),
    "dashboardPanelDashboards": MessageLookupByLibrary.simpleMessage(
      "Dashboards",
    ),
    "dashboardPanelDefaults": MessageLookupByLibrary.simpleMessage(
      "Standaardwaarden",
    ),
    "dashboardPanelDescription": MessageLookupByLibrary.simpleMessage(
      "Beheer opgeslagen dashboardlay-outs.",
    ),
    "dashboardPanelDotSize": MessageLookupByLibrary.simpleMessage(
      "Puntgrootte",
    ),
    "dashboardPanelInterpolation": MessageLookupByLibrary.simpleMessage(
      "Interpolatie",
    ),
    "dashboardPanelMaxSamples": MessageLookupByLibrary.simpleMessage(
      "Meetpunten",
    ),
    "dashboardPanelMaxSamplesHint": MessageLookupByLibrary.simpleMessage(
      "0 = onbeperkt",
    ),
    "dashboardPanelNoDashboardsMessage": MessageLookupByLibrary.simpleMessage(
      "Maak een dashboard of sla op vanuit de dashboardweergave",
    ),
    "dashboardPanelNoDashboardsTitle": MessageLookupByLibrary.simpleMessage(
      "Nog geen dashboards",
    ),
    "dashboardPanelTitle": MessageLookupByLibrary.simpleMessage("Dashboard"),
    "delete": MessageLookupByLibrary.simpleMessage("Verwijderen"),
    "detailMessages": MessageLookupByLibrary.simpleMessage("Berichten"),
    "detailNo": MessageLookupByLibrary.simpleMessage("Nee"),
    "detailPinnedToDashboard": MessageLookupByLibrary.simpleMessage(
      "Vastgezet op dashboard",
    ),
    "detailQoS": MessageLookupByLibrary.simpleMessage("QoS"),
    "detailRate": MessageLookupByLibrary.simpleMessage("Frequentie"),
    "detailRatePerSecond": m0,
    "detailRateValue": m1,
    "detailReceived": MessageLookupByLibrary.simpleMessage("Ontvangen"),
    "detailRetained": MessageLookupByLibrary.simpleMessage("Vastgehouden"),
    "detailShowLatest": MessageLookupByLibrary.simpleMessage("Toon nieuwste"),
    "detailSize": MessageLookupByLibrary.simpleMessage("Grootte"),
    "detailViewingMessage": m2,
    "detailWaitingForMessages": MessageLookupByLibrary.simpleMessage(
      "Wachten op berichten…",
    ),
    "detailYes": MessageLookupByLibrary.simpleMessage("Ja"),
    "disconnect": MessageLookupByLibrary.simpleMessage("Verbinding verbreken"),
    "durationHours": m3,
    "durationLessThanSecond": MessageLookupByLibrary.simpleMessage(
      "< 1 seconde",
    ),
    "durationMinutes": m4,
    "durationSeconds": m5,
    "expandAll": MessageLookupByLibrary.simpleMessage("Alles uitklappen"),
    "filterNoMatchingTopics": MessageLookupByLibrary.simpleMessage(
      "Geen overeenkomende topics",
    ),
    "filterNoMatchingTopicsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Probeer het filter aan te passen of te wissen.",
    ),
    "languageNameDe": MessageLookupByLibrary.simpleMessage("Duits"),
    "languageNameEn": MessageLookupByLibrary.simpleMessage("Engels"),
    "languageNameEs": MessageLookupByLibrary.simpleMessage("Spaans"),
    "languageNameFr": MessageLookupByLibrary.simpleMessage("Frans"),
    "languageNameNl": MessageLookupByLibrary.simpleMessage("Nederlands"),
    "languagePanelChangesNote": MessageLookupByLibrary.simpleMessage(
      "Wijzigingen worden toegepast bij de volgende start.",
    ),
    "languagePanelDescription": MessageLookupByLibrary.simpleMessage(
      "Selecteer de interfacetaal.",
    ),
    "languagePanelSectionLabel": MessageLookupByLibrary.simpleMessage(
      "Interfacetaal",
    ),
    "languagePanelTitle": MessageLookupByLibrary.simpleMessage("Taal"),
    "monitoringPanelClearAll": MessageLookupByLibrary.simpleMessage(
      "Alles wissen",
    ),
    "monitoringPanelDescription": MessageLookupByLibrary.simpleMessage(
      "Configureer berichtgeschiedenis per topic.",
    ),
    "monitoringPanelHistoryBuffer": MessageLookupByLibrary.simpleMessage(
      "Geschiedenisbuffer",
    ),
    "monitoringPanelIncreasedBufferHint": MessageLookupByLibrary.simpleMessage(
      "Berichten voor gemonitorde topics",
    ),
    "monitoringPanelIncreasedBufferSize": MessageLookupByLibrary.simpleMessage(
      "Verhoogde buffergrootte",
    ),
    "monitoringPanelIncreasedMonitoring": MessageLookupByLibrary.simpleMessage(
      "Verhoogde monitoring",
    ),
    "monitoringPanelRateSampleHint": MessageLookupByLibrary.simpleMessage(
      "Berichten voor frequentieberekening",
    ),
    "monitoringPanelRateSampleSize": MessageLookupByLibrary.simpleMessage(
      "Frequentie berekengrootte",
    ),
    "monitoringPanelStandardBufferHint": MessageLookupByLibrary.simpleMessage(
      "Berichten opgeslagen per topic",
    ),
    "monitoringPanelStandardBufferSize": MessageLookupByLibrary.simpleMessage(
      "Standaard buffergrootte",
    ),
    "monitoringPanelTitle": MessageLookupByLibrary.simpleMessage("Monitoring"),
    "noBroker": MessageLookupByLibrary.simpleMessage("Geen broker"),
    "noMessagesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Nog geen berichten ontvangen.",
    ),
    "noMessagesTitle": MessageLookupByLibrary.simpleMessage(
      "Wachten op berichten",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("Optioneel"),
    "publishBadJson": MessageLookupByLibrary.simpleMessage("Ongeldige JSON"),
    "publishFailed": MessageLookupByLibrary.simpleMessage("Mislukt"),
    "publishNoTopic": MessageLookupByLibrary.simpleMessage("Geen topic"),
    "publishOffline": MessageLookupByLibrary.simpleMessage("Offline"),
    "publishPrettifyJson": MessageLookupByLibrary.simpleMessage("JSON opmaken"),
    "publishRetain": MessageLookupByLibrary.simpleMessage("Retain"),
    "publishSent": MessageLookupByLibrary.simpleMessage("Verzonden"),
    "publishTopicHint": MessageLookupByLibrary.simpleMessage(
      "Topic  bijv. home/temp",
    ),
    "reconnect": MessageLookupByLibrary.simpleMessage("Opnieuw verbinden"),
    "remove": MessageLookupByLibrary.simpleMessage("Verwijderen"),
    "save": MessageLookupByLibrary.simpleMessage("Opslaan"),
    "scopeGlobal": MessageLookupByLibrary.simpleMessage("Globaal"),
    "scopeSelectedBrokers": MessageLookupByLibrary.simpleMessage(
      "Geselecteerde brokers",
    ),
    "scopeSpecificBrokers": MessageLookupByLibrary.simpleMessage(
      "Specifieke brokers",
    ),
    "searchHint": MessageLookupByLibrary.simpleMessage("Zoeken"),
    "searchScopeAll": MessageLookupByLibrary.simpleMessage("Alles"),
    "searchScopeTopic": MessageLookupByLibrary.simpleMessage("Topic"),
    "searchScopeValue": MessageLookupByLibrary.simpleMessage("Waarde"),
    "sectionAbout": MessageLookupByLibrary.simpleMessage("Over"),
    "sectionBrokers": MessageLookupByLibrary.simpleMessage("Brokers"),
    "sectionDashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
    "sectionLanguage": MessageLookupByLibrary.simpleMessage("Taal"),
    "sectionMonitoring": MessageLookupByLibrary.simpleMessage("Monitoring"),
    "sectionShortcuts": MessageLookupByLibrary.simpleMessage("Snelkoppelingen"),
    "sectionUI": MessageLookupByLibrary.simpleMessage("Gebruikersinterface"),
    "sectionVariables": MessageLookupByLibrary.simpleMessage("Variabelen"),
    "settings": MessageLookupByLibrary.simpleMessage("Instellingen"),
    "shortcutDialogAddTitle": MessageLookupByLibrary.simpleMessage(
      "Snelkoppeling toevoegen",
    ),
    "shortcutDialogEditTitle": MessageLookupByLibrary.simpleMessage(
      "Snelkoppeling bewerken",
    ),
    "shortcutDialogFieldColor": MessageLookupByLibrary.simpleMessage("Kleur"),
    "shortcutDialogFieldName": MessageLookupByLibrary.simpleMessage("Naam"),
    "shortcutDialogFieldTopic": MessageLookupByLibrary.simpleMessage("Topic"),
    "shortcutDialogRetain": MessageLookupByLibrary.simpleMessage("Retain"),
    "shortcutDialogRetainSubtitle": MessageLookupByLibrary.simpleMessage(
      "Broker slaat het bericht op voor nieuwe abonnees",
    ),
    "shortcutDialogScopeBrokersSubtitle": MessageLookupByLibrary.simpleMessage(
      "Alleen voor geselecteerde brokers",
    ),
    "shortcutDialogScopeGlobalSubtitle": MessageLookupByLibrary.simpleMessage(
      "Beschikbaar voor alle brokers",
    ),
    "shortcutDialogValidateName": MessageLookupByLibrary.simpleMessage(
      "Voer een naam in",
    ),
    "shortcutDialogValidateTopic": MessageLookupByLibrary.simpleMessage(
      "Voer een topic in",
    ),
    "shortcutsPanelAddShortcut": MessageLookupByLibrary.simpleMessage(
      "Snelkoppeling toevoegen",
    ),
    "shortcutsPanelDefinedShortcuts": MessageLookupByLibrary.simpleMessage(
      "Gedefinieerde snelkoppelingen",
    ),
    "shortcutsPanelDescription": MessageLookupByLibrary.simpleMessage(
      "Definieer publiceer snelkoppelingen om snel berichten naar topics te sturen.",
    ),
    "shortcutsPanelNoShortcutsMessage": MessageLookupByLibrary.simpleMessage(
      "Voeg een snelkoppeling toe om snel\nnaar je favoriete topics te publiceren.",
    ),
    "shortcutsPanelNoShortcutsTitle": MessageLookupByLibrary.simpleMessage(
      "Nog geen snelkoppelingen",
    ),
    "shortcutsPanelTitle": MessageLookupByLibrary.simpleMessage(
      "Snelkoppelingen",
    ),
    "sidebarHistory": MessageLookupByLibrary.simpleMessage("GESCHIEDENIS"),
    "sidebarMessageDetail": MessageLookupByLibrary.simpleMessage(
      "BERICHTDETAILS",
    ),
    "sidebarNoSelectionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Kies een topic uit de boom\nom berichtdetails te bekijken",
    ),
    "sidebarNoSelectionTitle": MessageLookupByLibrary.simpleMessage(
      "Selecteer een topic om te bekijken",
    ),
    "sidebarPublish": MessageLookupByLibrary.simpleMessage("PUBLICEREN"),
    "subscriptionDialogAddTitle": MessageLookupByLibrary.simpleMessage(
      "Abonnement toevoegen",
    ),
    "subscriptionDialogEditTitle": MessageLookupByLibrary.simpleMessage(
      "Abonnement bewerken",
    ),
    "subscriptionDialogFieldDisplayName": MessageLookupByLibrary.simpleMessage(
      "Weergavenaam",
    ),
    "subscriptionDialogFieldTopicFilter": MessageLookupByLibrary.simpleMessage(
      "Onderwerpfilter",
    ),
    "subscriptionDialogHintDisplayName": MessageLookupByLibrary.simpleMessage(
      "Optionele vriendelijke naam",
    ),
    "subscriptionDialogQoS0Description": MessageLookupByLibrary.simpleMessage(
      "Maximaal één keer",
    ),
    "subscriptionDialogQoS0Label": MessageLookupByLibrary.simpleMessage(
      "QoS 0",
    ),
    "subscriptionDialogQoS1Description": MessageLookupByLibrary.simpleMessage(
      "Minimaal één keer",
    ),
    "subscriptionDialogQoS1Label": MessageLookupByLibrary.simpleMessage(
      "QoS 1",
    ),
    "subscriptionDialogQoS2Description": MessageLookupByLibrary.simpleMessage(
      "Precies één keer",
    ),
    "subscriptionDialogQoS2Label": MessageLookupByLibrary.simpleMessage(
      "QoS 2",
    ),
    "subscriptionDialogQoSLabel": MessageLookupByLibrary.simpleMessage(
      "Servicekwaliteit",
    ),
    "subscriptionDialogValidateTopicFilter":
        MessageLookupByLibrary.simpleMessage("Voer een onderwerpfilter in"),
    "uiPanelDescription": MessageLookupByLibrary.simpleMessage(
      "Uiterlijk en lay-outvoorkeuren.",
    ),
    "uiPanelPersistLayout": MessageLookupByLibrary.simpleMessage(
      "Lay-out bewaren",
    ),
    "uiPanelPersistLayoutSubtitle": MessageLookupByLibrary.simpleMessage(
      "Panelgrootten en -posities herstellen bij opstart",
    ),
    "uiPanelPulseFade": MessageLookupByLibrary.simpleMessage("Pulsvervaging"),
    "uiPanelPulseFadeSubtitle": MessageLookupByLibrary.simpleMessage(
      "Duur van de animatie",
    ),
    "uiPanelPulseRate": MessageLookupByLibrary.simpleMessage("Pulsnelheid"),
    "uiPanelPulseRateSubtitle": MessageLookupByLibrary.simpleMessage(
      "Maximum activiteitspulsen per seconde",
    ),
    "uiPanelRateInterval": MessageLookupByLibrary.simpleMessage(
      "Update-interval",
    ),
    "uiPanelRateIntervalSubtitle": MessageLookupByLibrary.simpleMessage(
      "Hoe vaak de berichtensnelheid wordt herberekend",
    ),
    "uiPanelSectionAppearance": MessageLookupByLibrary.simpleMessage(
      "Uiterlijk",
    ),
    "uiPanelSectionConnection": MessageLookupByLibrary.simpleMessage(
      "Verbinding",
    ),
    "uiPanelSectionDataDisplay": MessageLookupByLibrary.simpleMessage(
      "Data weergave",
    ),
    "uiPanelSectionLayout": MessageLookupByLibrary.simpleMessage("Lay-out"),
    "uiPanelShowActivity": MessageLookupByLibrary.simpleMessage(
      "Activiteit tonen",
    ),
    "uiPanelShowActivitySubtitle": MessageLookupByLibrary.simpleMessage(
      "Pluseer topic bij activiteit",
    ),
    "uiPanelShowStatusBar": MessageLookupByLibrary.simpleMessage(
      "Statusbalk tonen",
    ),
    "uiPanelShowStatusBarSubtitle": MessageLookupByLibrary.simpleMessage(
      "Toont de statusbalk onder het scherm",
    ),
    "uiPanelStartupBehavior": MessageLookupByLibrary.simpleMessage(
      "Opstartgedrag",
    ),
    "uiPanelStartupConnect": MessageLookupByLibrary.simpleMessage("Verbinden"),
    "uiPanelStartupDisconnected": MessageLookupByLibrary.simpleMessage(
      "Verbroken",
    ),
    "uiPanelStartupLastStatus": MessageLookupByLibrary.simpleMessage(
      "Laatste status",
    ),
    "uiPanelThemeDark": MessageLookupByLibrary.simpleMessage("Donker"),
    "uiPanelThemeLight": MessageLookupByLibrary.simpleMessage("Licht"),
    "uiPanelThemeMode": MessageLookupByLibrary.simpleMessage("Thema"),
    "uiPanelThemeSystem": MessageLookupByLibrary.simpleMessage("Systeem"),
    "uiPanelTitle": MessageLookupByLibrary.simpleMessage("Gebruikersinterface"),
    "variableDialogAddOption": MessageLookupByLibrary.simpleMessage(
      "Optie toevoegen",
    ),
    "variableDialogAddTitle": MessageLookupByLibrary.simpleMessage(
      "Variabele toevoegen",
    ),
    "variableDialogDisplayName": MessageLookupByLibrary.simpleMessage(
      "Weergavenaam",
    ),
    "variableDialogEditTitle": MessageLookupByLibrary.simpleMessage(
      "Variabele bewerken",
    ),
    "variableDialogFieldName": MessageLookupByLibrary.simpleMessage("Naam"),
    "variableDialogNameExists": MessageLookupByLibrary.simpleMessage(
      "Een variabele met deze naam bestaat al",
    ),
    "variableDialogNameInvalid": MessageLookupByLibrary.simpleMessage(
      "Naam mag geen spaties of speciale tekens bevatten",
    ),
    "variableDialogOptionsHint": MessageLookupByLibrary.simpleMessage(
      "Met opties kun je kiezen uit een lijst in het dashboard in plaats van elke keer te typen.",
    ),
    "variableDialogPredefinedOptions": MessageLookupByLibrary.simpleMessage(
      "Voorgedefinieerde opties",
    ),
    "variableDialogScopeBrokersSubtitle": MessageLookupByLibrary.simpleMessage(
      "Alleen voor geselecteerde brokers",
    ),
    "variableDialogScopeGlobalSubtitle": MessageLookupByLibrary.simpleMessage(
      "Beschikbaar voor alle brokers",
    ),
    "variableDialogValidateName": MessageLookupByLibrary.simpleMessage(
      "Voer een variabelenaam in",
    ),
    "variableDialogValue": MessageLookupByLibrary.simpleMessage("Waarde"),
    "variablesPanelAddVariable": MessageLookupByLibrary.simpleMessage(
      "Variabele toevoegen",
    ),
    "variablesPanelDefinedVariables": MessageLookupByLibrary.simpleMessage(
      "Gedefinieerde variabelen",
    ),
    "variablesPanelDescription": MessageLookupByLibrary.simpleMessage(
      "Definieer omgevingsvariabelen voor gebruik als placeholders in grafiek-topicstrings.",
    ),
    "variablesPanelNoOptions": MessageLookupByLibrary.simpleMessage(
      "Geen opties",
    ),
    "variablesPanelNoVariablesMessage": MessageLookupByLibrary.simpleMessage(
      "Voeg een variabele toe als placeholder\nin je grafiek-topicstrings.",
    ),
    "variablesPanelNoVariablesTitle": MessageLookupByLibrary.simpleMessage(
      "Nog geen variabelen",
    ),
    "variablesPanelTitle": MessageLookupByLibrary.simpleMessage("Variabelen"),
  };
}
