/// Controls the default state of a right-hand sidebar panel on startup.
///
/// Used together with the "Persist Layout" setting:
///   - [collapsed] — always start collapsed.
///   - [expanded] — always start expanded.
///   - [lastStatus] — restore the last state the user chose. The last state
///     is only persisted when "Persist Layout" is on; otherwise the panel's
///     built-in default is used.
enum SidebarPanelDefault {
  collapsed,
  expanded,
  lastStatus,
}