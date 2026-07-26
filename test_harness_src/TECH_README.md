# Enhanced Patrol AI - Test Harness

Technical dev/test mod (`save="0"`) that makes patrol behaviour
observable without roaming the galaxy hunting for live patrols. It spawns
deterministic opposing task forces in fixed technical test sectors, sets the
faction relations the test needs, and guarantees shared vision.

## Scenario Sectors

| Sector | Sector macro | Matchup |
|---|---|---|
| s01 ARG vs TER Military | `vas_th_sector01_macro` | Argon military force vs Terran military force |
| s02 ARG vs TER Defence Stations | `vas_th_sector02_macro` | Argon military force vs Terran defence stations |
| s03 ARG vs TER Civil Ships | `vas_th_sector03_macro` | Argon military force vs Terran civilian/economy ships |
| s04 ARG vs TER Civil Stations | `vas_th_sector04_macro` | Argon military force vs Terran civilian/economy stations |
| s05 Player vs PAR Defence Stations | `vas_th_sector05_macro` | Player-side force vs Paranid defence stations |
| s06 Player vs PAR Civil Stations | `vas_th_sector06_macro` | Player-side force vs Paranid civilian/economy stations |
| s07 Player vs PAR Military | `vas_th_sector07_macro` | Player-side force vs Paranid military force |
| s08 Player vs PAR Civil Ships | `vas_th_sector08_macro` | Player-side force vs Paranid civilian/economy ships |
| s09 Highway Pursuit | `vas_th_sector09_macro` | ARG/TER pursuit across a local highway |
| s10 Gate Pursuit A | `vas_th_sector10_macro` | ARG/TER gate-pursuit origin sector |
| s11 Gate Pursuit B | `vas_th_sector11_macro` | ARG/TER gate-pursuit destination sector |
| s12 Distance Pursuit | `vas_th_sector12_macro` | ARG/TER max pursuit travelled distance test |
| s13 Player Highway Pursuit | `vas_th_sector13_macro` | Player/PAR pursuit across a local highway |
| s14 Player Gate Pursuit A | `vas_th_sector14_macro` | Player/PAR gate-pursuit origin sector |
| s15 Player Gate Pursuit B | `vas_th_sector15_macro` | Player/PAR gate-pursuit destination sector |
| s16 Player Distance Pursuit | `vas_th_sector16_macro` | Player/PAR max pursuit travelled distance test |
| s17 Direct TER/ARG Size Pursuit | `vas_th_sector17_macro` | Direct Attack orders against L/XL targets, bypassing scanner/bravery selection |
| s18 Direct Player/PAR Size Pursuit | `vas_th_sector18_macro` | Player/PAR direct Attack orders against L/XL targets |
| s19 Active Fight Pursuit | `vas_th_sector19_macro` | Long approach into active combat to test pursuit-budget combat guard |
| s20 Targeting Friendly Bystander | `vas_th_sector20_macro` | TER patrol, ARG target, friendly player bystander |
| s21 Targeting VFF Secondary | `vas_th_sector21_macro` | TER patrol vs ARG VFF scout group |
| s22 Targeting Civilian Secondary Scan | `vas_th_sector22_macro` | TER patrol, closer ARG civilian miners, farther ARG scout |
| s23 MoveGeneric Gate Pursuit A | `vas_th_sector23_macro` | TER patrol starts 200 km from gate; ARG scout starts 10 km from gate |
| s24 MoveGeneric Gate Pursuit B | `vas_th_sector24_macro` | MoveGeneric destination sector for the s23 scout |

Pursuit-specific ships and orders are MD-spawned in `md/vas_epai_pursuit_tests.xml`.
Targeting-specific ships and orders are MD-spawned in `md/vas_epai_targeting_tests.xml`,
except the s21 VFF group, which uses jobs for subordinate assignment.

## Files

- `content.xml` - id `vas_epai_test_harness`, `save="0"`, optional dependency on the patrol mod.
- `md/vas_epai_test_harness.xml` - bootstrap, relations, player-owned shipyard, satellites, and station targets.
- `md/vas_epai_pursuit_tests.xml` - tightly controlled pursuit scenarios.
- `libraries/jobs.xml` - larger standing task forces and civilian/economy traffic.
- `assets/props/equipment/satelite/macros/eq_arg_satellite_02_macro.xml` - widened advanced satellite radar for full-sector test vision.
- `t/0001-l044.xml` - technical sector and job display names.

## Faction Relations

- Argon <-> Terran: hostile enough for the intended ARG/TER tests.
- Player <-> Paranid: hostile enough for the intended player/PAR tests.
- Test allies stay friendly so friendly-fire regressions can be isolated.

Use relation bands deliberately: `-0.2` is useful for military-only hostility,
while `-1.0` makes civilian/economy assets mayattackable too.
