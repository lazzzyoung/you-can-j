# Changelog

## [0.5.0] - 2026-11-08
### Added
- Delete a routine from just one day or from every day.
- Star important days; starred days get a rotating rainbow border on the calendar.
- Routines have a From/Until date range (defaults to the month on screen; empty Until = no end).
- Tap an event or routine in the day list to edit it.

### Changed
- End time now defaults to the start time, so +10m/+30m/+1h add up from the start.
- Renamed the app from month.do to You can J.

### Fixed
- After signing out, the next user on the same browser could start with the previous user's items.

## [0.4.0] - 2026-11-02
Baseline imported into git. Versions below 0.4.0 were built before the repository existed and are recorded here from the feedback rounds.

### Added
- Google sign-in alongside email code sign-in; sessions persist until sign-out.
- Privacy policy page and footer link.
- Start/End time fields with +10m, +30m, +1h buttons instead of a duration field.

### Fixed
- Dialogs centered on screen.
- Form fields no longer overflow on phones; inputs are 16px so iOS Safari doesn't zoom.

## [0.3.0] - 2026-11-02
### Added
- Supabase sync with email one-time-code sign-in; row-level security per user.
- Deployed to Vercel.

## [0.2.0] - 2026-11-02
### Added
- Color groups: create, rename, recolor, delete; pick a group when adding an event.

### Changed
- UI in English; routines apply to every matching weekday of the month.
- Add buttons moved below the calendar; Today button removed.

### Fixed
- Adding events failed outside https (`crypto.randomUUID` unavailable).

## [0.1.0] - 2026-11-02
### Added
- Month calendar, one-off events, weekly routines, 24-hour dial per day with done checkboxes.
