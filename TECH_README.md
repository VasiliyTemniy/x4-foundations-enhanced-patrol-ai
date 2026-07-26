# Critical

One of the main goals of this mod is to reproduce the "pursuetargets" attack behavior, but somewhat bound with pursuedistance and sector change. On the way to reach the goal, there was an implementation attempt that involved injections modifying "@$target.zone.isclass.highway" conditions, which caused a really hard several days long debug session. Conclusion - any skip of "@$target.zone.isclass.highway" checks causes some unknown internal game engine infinite loop that loads CPU, does not produce any visible\readable error, totally untrackable by any logs - vanilla logs with debugchance=100 and own injected logs. So - never try to change "@$target.zone.isclass.highway" again.

Observed patrol control flow around EPAI-created attacks: `order.fight.patrol` calls `move.seekenemies` from the `patrol` loop, and `move.seekenemies` can return normally even after EPAI has selected a target and issued an immediate `Attack` order. A debug line injected immediately after the `run_script name="'move.seekenemies'"` call does run, and a second debug line injected immediately before the following vanilla `wait min="1s" max="2s"` also runs. A debug line injected immediately after that wait does not run. Later, after the EPAI attack finishes or the order state settles, `order.fight.patrol` is observed entering again from `label name="start"` by normal top-down entry/re-entry: both debug probes inserted before and after `label name="start"` fire at the same player age. This means the post-attack chain is not reliably "move.seekenemies returns -> wait completes -> resume find_patrolzone". In practice, the vanilla wait after `move.seekenemies` is a handoff point where the current Patrol script instance can be preempted/restarted/ended by the order state created by the immediate Attack. Local AIScript variables set before `move.seekenemies` are not a safe signal for the next Patrol entry. A durable signal must be stored outside the local script frame, e.g. a global per-ship map such as `global.$vas_epai_should_scan_at_patrol_start.{this.ship}`. The consumer should be anchored after `label name="start"` because that is the stable re-entry point after an EPAI attack finishes. The EPAI scan itself does not need Patrol's `$space`; it scans from `this.ship` / current sector, so the start-label consumer can clear the durable marker and run EPAI scan/attack before vanilla Patrol decides to fly back to its patrol space.

Critical save-import constraint found in normal saves: the start-label consumer must not place new Patrol-side `<run_script>` helper callsites before vanilla Patrol's existing `run_script name="'move.seekenemies'"` call. A save made before EPAI, then loaded with the Patrol follow-up block containing `run_script name="'lib.vas.epai.scan'"` near `label name="start"`, produced many common-log errors like: `Error on AI director import: Script 'move.seekenemies' with temp ID ... is not compatible with caller context order.fight.patrol`. Commenting that block removed the errors. Later evidence showed that the follow-up scan can run without those import errors when the early start-label injection only gates and resumes to a label, while the new helper `<run_script>` callsites are appended near the end of `order.fight.patrol` actions, after the vanilla `move.seekenemies` callsite. Working rule for EPAI: keep the start-label injection tiny, and put new Patrol-side helper `run_script` calls after vanilla Patrol's existing `run_script` calls. This is observed engine behavior, not a documented rule.

# Roadmap

0. DONE! Add some actual testing suite\harness!
1. DONE! Add visibility helpers with global cache per faction per scanned ship to abstract visibility calculations from the main engine. Goal - achieve main engine\script readability, gain ability to quickly check any ships' visibility status from the faction's perspective (which will be used for fleet force calculations later to filter subordinates by visibility).
2. DONE! Introduce concept of VFF - visible fleet flagman. Depending on the visibility config, these can be "fleet top commander's ship in the sector" or mere "highest visible branch commander's ship". Will be used for "force vs force" comparisons.
3. DONE! Add power calculation helper with global cache per faction per VFF to abstract power calculations from the main engine. This helper will always calculate "the visible fleet flagman with subordinates total power", but it must be affected with precalculated visible enemy ships cache from point 1 of these steps - only subordinates that are considered visible must be included in the calculation.
4. DONE! Update the station attack join\init script, reusing the new vff force helpers.
5. DONE! Change ships engangement decision from "me vs him" to "my joint force vs his (vff) joint force"
6. DONE! Change helpers to preprocessors to make game engine happy
7. DONE! Use md wake_up_patrol heartbeat solely to trigger the mod logic. Leave vanilla interrupts intact - if they are triggered, mod logic must not be involved at all.
8. DONE! Add tunable randomizer to actual decision making. Random value must be recalculated right before the force comparison happens.
9. DONE! Try to simplify the mod logic that touches "civilian" and "friendly" ships attack orders. Right now the mod injects lots of "skip_this" and "skip_that" to make sure that stupid vanilla approach of "don't touch some hostile ship if it has no guns, we're pacifists" is gone. The way to go is start using "checkrelation="false"". Previous attempt to use that flag caused patrol ships to attack everyone in their vision, real actual friends included, so this must be thought through.
10. DONE! Try to simplify the logic that tries to reproduce "pursuetargets". Instead of lots of injections, just use that darn "pursuetargets"! BUT - add just a few or even just one injection to some interrupt that would make the pursuit to stop. There's even an event for that matter - object_changed_sector or like that. Sector change should be the only real way to stop pursuit - that's the goal. Maybe adding some decision-making for stopping after some distance would also help, so it's like an invert of current mod approach - instead of trying to mostly mimic "pursuetargets" using "pursuedistance" and stuff, we will try to mimic "pursuedistance" with "pursuetargets".
11. DONE! Rename pursuedistance so it's obvious that it's not vanilla pursuedistance anymore to not mess with it and not introduce any misunderstanding to any future reader. Rename to something like "maxpursuedecisionmakingtravelleddistanceingodknowswhichunitsthatshitisstoredactuallywhateverjustnotpursueandnotdistancethatsit". Also add some checks that if any actual fighting is happening already - no abort must be issued, only abort if no active fight when interrupt is called.
12. DONE! Add some target priority calculations. move.seekenemies scans the sector and finds lots of targets. It would be really good to control the target priority. What's a prioritized target vs what's not is a matter of discuss.
13. DONE! Consider doing something to make sure that instead of coming back to the patrol zone, ships reevaluate situation and consider attacking again - maybe with the same move.seekenemies script. Problem is: station test setups from test harness show that when one station is destroyed, all involved VFFs get a "patrol" order that makes them move all those hundreds of kilometers back to the beginning, there they seem to trigger the move.seekenemies again - and then they move back to the stations - another several hundreds of kilometers. Something must trigger the move.seekenemies right after attack finishes - instead of moving the patrol to the beginning right away.
14. DONE! Update the garbage collector that that would clean global vas_epai_should_scan_at_patrol_start map removing entries for destroyed ships.
15. DONE! Add something to adjust target score based on any enemy VFF or station is on the way to the target. If any enemy is on the way (calculation must be somewhat laxed, like e.g.: x.y.z: patrol 0.0.0 target 10.0.0 and some station 5.2.0 must still account that station as "on the way". The allowed deviation from line between patrol and target is a matter of discuss) then the score must be lowered. It's also a matter of discuss whether enemy power must be considered here. If enemy power is considered - then it's not "check the first enemy along the way", but "check the enemy power along the way", maybe with some threshold or max tracked power-along-the-way-divided-to-self-power ratio.
16. DONE! Add some logic to move around hostile stations that cannot be overpowered. E.g. some big defence station is situated between a patrol and an attackable ship or station - if that big defence station cannot be overpowered, it must be moved around to make sure no useless attacks happen.
17. Split this mod into three mods: lib helpers mod, vanilla patrol order mutation mod, "clear that sector" (name must be better! it's a draft for name) aiscript mod


## Roadmap steps details

### Test harness - DONE!
Taking example from CHEAT_JOBS mod - write a jobs.xml file that would spawn forces on a game start.
Sectors:
- Argon Prime (Zone001_Cluster_14_Sector001_macro) (maybe Cluster_14_Sector001_macro is the sector center? who knows)
- The Reach (Cluster_07_Sector001_macro)
- Morning Star III (Cluster_30_Sector001_macro)
- Morning Star IV (Cluster_46_Sector001_macro)
- Second Contact II Flashpoint (Cluster_13_Sector001_macro)
- The Void (Cluster_27_Sector001_macro)
- Frontier Edge (Cluster_49_Sector001_macro)
- Silent Witness XI (Cluster_44_Sector001_macro)
Sector faction changes:
- Second Contact II Flashpoint - make the sector player-owned
- The Void - make the sector player-owned
- Frontier Edge - make the sector player-owned
- Silent Witness XI - make the sector player-owned
For each sector, pick these factions and task forces:
- Argon Prime - Argon military ships vs Terran military ships
- The Reach - Argon military ships vs Terran military stations
- Morning Star III - Argon military ships vs Terran civil ships
- Morning Star IV - Argon military ships vs Terran civil stations
- Second Contact II Flashpoint - Player military ships vs Paranid military ships
- The Void - Player military ships vs Paranid civil ships
- Frontier Edge - Player military ships vs Paranid military stations
- Silent Witness XI - Player military ships vs Paranid civil stations
Faction relation changes required:
- Argon and Terran must become max hostile enemies between each other
- Argon and Terran must become max friendly to the player
- Paranid must become max hostile to the player
Task forces. Each layer means subordinance. Each layer means "N per ship of the higher layer", so 2 Carriers from the beginning of the "Military ships" task force would get 4\*2 = 8 M ships total, 2\*12 + 2\*4\*4 = 56 S ships total:
"Military ships":
. 2 Carriers
.. 4 M ships
... 4 S ships
.. 12 S ships each
. 4 Destroyers
.. 2 Destroyers
... 1 M ship
.... 2 S ships
.. 1 M ship
... 2 S ships

"Civil ships":
. 2 M solid miners
. 2 L solid miners
. 2 M liquid \ gas miners
. 2 L liquid \ gas miners
. 2 M traders
. 2 L traders

"Military stations":
. Defence station
. Defence station

"Civil stations":
. Any trading station (without turrets!)
. Any production station (without turrets!)


To grant each faction true sector-wide shared vision, would have to modify advanced satellite vision range to 800km and place a single advanced satellite in each listed sector's center - one for each participating faction per sector, so vision is not a concern for any of them.


### VFF fleet force calculations and helper - DONE!

VFF - visible fleet flagman.

I need a helper library "lib.vas.epai.calc.visiblefleetforce.withcache.xml". It takes vff_ship, patrol_ship, friendly_sector_objects as a parameter and returns normalized "visible-in-sector" fleet force power. vff_ship could be allied or enemy ship. Fleet force power is the sum of per-ship power items, but it can get out of float64 as I suspect. So - normalization must be applied, using L ship reference values for every ship class.
For example, destroyers. ingame median DPS of destroyers is ~5000. Ingame median hull of a destroyer is ~100000 HP, median shields sum of a destroyer is ~150000 MJ. I suggest this formula:
1. Calculate DPS power by dividing ship DPS over 5000, store into some variable.
2. Calculate durability power by dividing ship hull + shields over 250000, store into another variable.
3. Calculate cruise mobility power by dividing ship maxspeed over 120m.
4. Calculate travel mobility power: (ship travel maxspeed / 4000m) * 2 / (1 + ship travel chargetime / 8s). Baseline travel speed and 8s charge time gives power 1; zero charge time gives power 2.
5. Calculate mobility power: cruise mobility power * 0.7 + travel mobility power * 0.3.
6. Calculate ship force power: DPS power * durability power * mobility power.
No class-specific coefficients are needed because mobility is accounted. Smaller ships are more mobile, thus are a bit more impactful having otherwise less dps and durability impact.
Iterating over ships, calculating these force power items and summarizing them would give us the visible fleet force power.

Visible fleet force power must be stored in a global var like "global.vas_epai_fleetforce_cache" which must be a map by faction by ship id, where faction is the patrol_ship.owner and ship id is the VFF ship id and values are calculated fleet force powers. Cache must have 0.5 * vas_epai_interval TTL but no less then 5 seconds. Overall, cache should not outlive the scan loop iteration to make sure that scan loop always has fresh data. "Outlive" here means TTL and expiracy, so expired values are considered "does not outlive". The main goal of this cache is to prevent repeated calculations of the same values on the same patrol ship scan, but it is totally acceptable to be usable by different patrol scanners.

Helper "lib.vas.epai.calc.visiblefleetforce.withcache.xml" must:
1. Try to get cached value by patrol_ship's faction and VFF ship id.
2. If found - return it, if not found - next step.
3. Get flat ships list of that fleet branch rooted at the VFF ship - there's "lib.vas.epai.flatten.subordinates" (it includes the commander's ship).
4. Filter ships from step 3 by visibility using "lib.vas.epai.check.shipvisible.withcache.xml" - visibility must be already calculated and stored in the cache at this point.
5. Iterate over all ships from step 4, calculating each ship's force power.
6. Store calculated value into the cache.
7. Return calculated value.

Justification for cache structure (per faction per VFF) - different factions can have different sector shared vision, thus visiblefleetforce calculations must be faction-dependent. E.g. one scan iteration can find 10 ships out of some 100-ships fleet and consider it the whole force, while some other faction can potentially see a lot more ships from the same fleet. Also - the "enemy" faction is in the eyes of patrol_ship. The same helper is applicable for both friendly and enemy forces - friendlies are always visible but enemies are not.

### Scanner-root cache preprocessing - DONE!

Current per-object helpers are clean, but AIScript scheduler can complain when small fleets make them start and return immediately many times in one scan. Adding 1ms waits to helper calls is not acceptable because nested visibility and force checks could add hundreds of ms to one scan and make the snapshot stale.

Planned direction: do the preprocessing directly at move.seekenemies scanner root. No helper calls, no waits, no artificial asynchronicity. The engine stays happy because there are no tiny helper scripts returning immediately, and the scan stays synchronous.

Scanner-root preprocessing phases:
1. Build VFF branch cache - flatten all VFF branches that could be needed by the scan and store flat ship lists per faction per VFF.
2. Build visibility cache - calculate all ship and station visibility values needed by the scan, stored per faction per target ship/station.
3. Build fleet force cache - calculate all visible fleet force values needed by the scan, using the branch and visibility caches.

Existing short TTL caches are enough: scanner-root preprocessing checks freshness, skips already-fresh values, and refreshes missing or stale values. Cache can be considered stale only during the preprocessing phase. After preprocessing, the rest of move.seekenemies assumes cache freshness and just reads cached values without any more expiry checks, even if some entry expires while the main scan body is still running.

Garbage collector must not delete entries immediately at expiry time. Physical removal should happen only when expiry is older than expiry + 3s. This makes it extremely unlikely that a cache entry is deleted in the middle of a move.seekenemies scan body while that scan is still synchronously reading already-preprocessed values.


# New issues found only on normal game (not test harness)

1. FIXED. When the primary attack target is destroyed, attack script seemingly continues to attack nearby allied targets because of "checkrelation" being false.
2. FIXED/CRITICAL. `order.fight.patrol` second-pass injection was investigated. The follow-up mechanism is valid, but new Patrol-side helper `run_script` callsites must be placed after vanilla Patrol's existing `move.seekenemies` callsite, otherwise existing saves can fail AI director import with `move.seekenemies ... not compatible with caller context order.fight.patrol`.
3. NOT A BUG. Ships seemingly stopped regarding the bypass attack civilian ships flag. They always attack - seeminlgy. This was not observed in test setup. Could it be the secondary scan? --- Further log additions and observations have shown that that specific TER ship had special -1.0 relation towards ARG and BOR, which further justifies this mod's existence in terms of retaliation to things.