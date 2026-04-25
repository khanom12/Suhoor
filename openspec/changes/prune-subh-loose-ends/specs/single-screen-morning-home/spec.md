## MODIFIED Requirements

### Requirement: Single Home Surface
The app SHALL use a single Subh home surface for the completed-user MVP experience and SHALL not retain compiled production entry points for retired tab-era surfaces.

#### Scenario: Completed user opens app
- **GIVEN** onboarding is complete
- **WHEN** the app launches
- **THEN** the user SHALL see the Subh home inside one navigation stack
- **AND** the app SHALL not expose legacy Today, Plans, Progress, Wake-list, fasting planning, Qada planning, or old alarm customization screens as production surfaces.

#### Scenario: Settings remains reachable
- **GIVEN** the user is on the Subh home
- **WHEN** they select Settings
- **THEN** settings SHALL open from the home top bar without a bottom tab shell.
