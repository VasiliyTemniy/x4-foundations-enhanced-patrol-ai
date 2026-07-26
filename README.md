# Enhanced Patrol AI

Makes the **Patrol** order actually patrol. Instead of idly looping a waypoint
while hostiles sit in the same sector, a patrolling ship periodically sweeps the
whole sector, weighs whether it can win the fight, and engages - picking targets
it can take, joining attacks already in progress, and letting capital patrol
groups open assaults on hostile stations. It applies to AI factions by default,
so the universe fights its own wars more convincingly, but it works for
player-owned ships just as well.

## Why

Have you ever wondered why some heavy-metal double-XL capital ship with a huge
subordinate fleet, sitting on a **Patrol** order, just drifts around the sector
like that South Park policeman - *"Nothing to see here!"* - while an enemy
station is being assembled right in its face? The enemy slowly but surely crawls
outward with economy and defence stations, and the patrol just shrugs: *"Nah,
not worth my attention."* (e.g. ANT + ARG patrol ships in The Void sector at
the start of the TER invasion)

Then this mod might be for you. Before using it, though, read the
**Compatibility** section first.

## Game version compatibility

- **9.00 release (build 611726)** - developed and tested here.

This mod performs heavy AI-script injections into several vanilla combat and
movement scripts. It may well keep working across many future patches - or it may
simply break on the next one with no warning. There is **no guarantee** of
forward compatibility; treat each game update as "verify before trusting it."

## Dependencies

- **[VAS] Combat Logic** - hard dependency. The sector scan engine, force math and
  attack issuing all live there. It has no options of its own; install it and
  forget it.
- **SirNukes Mod Support APIs** ([link](https://www.nexusmods.com/x4foundations/mods/503)) - hard
  dependency. Provides the Simple Menu / Options helpers used by the options menu.

## How it works

When a patrolling ship is interrupted while moving, the mod runs at most once
per configured **scan interval** and sweeps its sector for hostiles instead of
waiting to bump into one:

- **Shared sector sight.** A target counts as "seen" if this ship can see it, or
  if a friendly ship, station, or satellite in the sector can - so a patrol can
  react to a threat its own gravidar has not picked up yet. Optionally this can be
  widened from same-faction to all allied sensors, or made all-seeing.
- **Pick fights you can win.** For each hostile in range the mod runs a rough
  force comparison (DPS × durability, fleet vs. fleet). A
  ship engages on its own only if it expects to come out ahead; otherwise it will
  still pile onto an attack that is already live - up to an overcommit limit so a
  single target does not soak the whole sector.
- **Capital station assaults.** Stations are only initiated by capital patrols
  (and their subordinate group) once their combined force clears a threshold;
  nearby same-faction patrols are counted in, but discounted, since they may pick
  another target first. Smaller ships only join a station attack that a capital
  has already started.

Once a candidate is chosen, the mod reuses the game's own target-selection and
attack orders, so the actual fighting is vanilla - it just starts fights vanilla
never would.

Whether a given ship participates is a **per-ship** switch on the Patrol order
itself (**Use Enhanced Patrol AI**, on by default). Everything else is tuned
globally from Extension Options.

## Options (Extensions → Mod Options → Enhanced Patrol AI)

| Option | Default | What it does |
|---|---|---|
| Apply to NPC factions | on | Run for non-player factions. Off limits the mod to player-owned ships only. |
| Apply to Xenon | off | Also run for Xenon patrols. Off leaves the Xenon on vanilla patrol behaviour. |
| Apply to Kha'ak | off | Also run for Kha'ak patrols. |
| Attack ships | on | Include hostile **ships** as patrol targets. |
| Attack stations | on | Include hostile **stations** as targets, so capital patrols can open assaults. |
| Attack hostile civilian and economy ships | off | Engage hostile ships even when normal fire authorization says no (traders, miners, builders). Off keeps patrols off the civilian economy. |
| Attack hostile civilian and economy stations | on | Engage hostile stations even when fire authorization would normally hold fire - useful for countering invasions. |
| All-seeing - ignore own line of sight | off | Treat every hostile as visible, bypassing the sight check entirely. |
| Use allied shared vision, not only same faction | off | Accept spotting from any allied sensor, not just same-faction ones. |
| Scan interval | 10 s (1–60) | Minimum time between enhanced patrol sector sweeps for a given running patrol movement. |
| Engagement and max pursuit travelled distance | 800 km (50–500000) | Max initial engagement distance and max travelled pursuit budget before the patrol reconsiders. Movement while already inside combat range is not counted as pursuit travel. |
| Ship join threshold | 10 % (0–100) | Minimum committed friendly fleet force required before a patrol joins an existing ship attack. |
| Ship overcommit limit | 10 x (1–50) | Stop sending more friendly force at a ship target once committed force exceeds this multiple, so one target does not pull the whole sector. |
| Station join threshold | 3 % (0–100) | Minimum already-committed force on a station before this ship will pile on. |
| Station assault initiation threshold | 15 % (1–100) | Combined capital-group force required to *start* a fresh station assault. |
| Pending patrol force weight | 50 % (0–100) | How much nearby same-faction patrols (not yet committed) count toward the initiation threshold. |
| Debug logging | off | Writes per-ship logs under `VAS_EnhancedPatrolAI/`. |

## Compatibility

This mod injects into vanilla AI scripts in place - that is the whole point: it
changes how patrols decide and fight where that logic already lives. The patched
vanilla scripts are:

- `order.fight.patrol` - entry point; reads the per-ship toggle and the faction
  gates, and runs a follow-up scan after an attack finishes.
- `move.seekenemies` - turns the wake heartbeat into a throttled sector scan and
  hands the chosen target off to Combat Logic.

That is all of it. The decision engine is **not** a patch - it lives in Combat
Logic's own `lib.vas.cl.scan` and `lib.vas.cl.issue.attack` scripts, which are
new files and cannot conflict with anything. Combat Logic does additionally
patch `order.fight.attack.object` and `move.generic`; see its own README.

Any other mod that edits the **same** vanilla scripts can potentially interfere
with this mod's logic - not necessarily, but it is the most likely source of
trouble. If something behaves oddly, suspect an overlapping AI-script mod first.

## Credits

- Inspired by **Shibdib's Improved Patrol**
  ([Nexus](https://www.nexusmods.com/x4foundations/mods/1712) ·
  [source](https://github.com/shibdib/X4Mods/tree/master/shib_improvedpatrol))
- Built on **SirNukes Mod Support APIs**.
- By VasiliyTemniy.

## The pain

This mod was developed in several iterations. The first iteration was simple -
make patrol ships pay attention to enemy stations, inject changes to vanilla
script - it worked!

Then I've decided to enhance ships targeting. It was all good and along the
way I've decided to override vanilla aiscript's check
"stop attacking the enemy that hopped on some highway" - because why not?

Who knew it would trigger some horrible game engine infinite loop that has
no error message at all, no debug logs or traces could show what's going
wrong and why, total freeze for infinite amount of time, music plays, but
the frame is stale and CPU fans are on full throttle! Who knew?

Well, now I know. It took me three continuous days of 14 hours long debug
sessions each to narrow the problem. If only it would be consistent! Nope,
the freeze happened somewhere between 1 minute and 1 hour of real time with
ingame SETA on. Each check iteration took enormous amount of time.
Maybe somebody else would solve the problem earlier. Best ai models did
nothing more than increase frustration, agony, pain and hatred.
Finding that oh-so-obvious trigger was a real win.

It would be ok if it would be the only painful moment! Because after another
refactor iteration, several milestone features implemented, I've found out
that the game engine hates instant aiscripts! There's some vanilla aiscripts
that are used like functions - they take params, do some stuff, return values.
Simple, solid! It's the simplest programming abstraction, right? Along with
goto statements, that are also present as "labels" in these scripts.
Oh, those sweet findings. Oh, my sweet helpers!

I've made four *perfect* helpers:

- one that recursively iterates fleet commander's ship and its subordinate
  ships, constructing a flat list of all fleet ships
- two that abstract calculation of ships and stations shared vision with
  perfect tweakable configurable nuances like omni-vision (all-vision),
  shared vision per faction, shared ally\friendly vision, all the good
  stuff, with shared vision cache per faction per ship to make sure that no
  unnecessary iterations, calculations and other things are done
- one that abstracts calculation of visible fleet flagman (it's like a
  local top commander's ship) force value, many nuances hidden inside and
  same cache approach per faction per fleet - factions that are friends
  between each other have shared knowledge about allied fleets and enemy
  fleets, knowing only shared-vision-limited visible enemy fleet force
  data, while that enemy faction themselves can have similar cached data
  that is more filled with their fleets data and similarly vision-limited
  data about mentioned allies

Anyway. Helpers.
They were like a fresh breath amid an ... ocean?.. swamp of these xml scripts.

But - the game engine says (oh, irony!)

> "Nah, you won't have these. They are suspicious. Infinite loop detected HAHA!"...

The game engine has severe unhandled infinite loop somewhere deeper than
these aiscripts - there is totally no way that highway loop from above
was iterating inside of any aiscript!

But instead of showing any correct error message about *that* loop, it
spams debug error messages about *my* helpers - "Possibly infinite wake request loop".
POSSIBLY! yeah. "(Most likely cause: Script starts and returns immediately)"
Well, of course it returns immediately! It's cached!..

Just to clarify - there was no infinite loops in my aiscript injections, no
infinite loops in my helpers. The game ran perfectly fine with no fps drop
at all - helpers worked correctly, cache was working as expected, all things
good! Except for the overly-aggressive game engine infinite loop detector
that assumes that each and every short aiscript that performs in less then
1 millisecond has an infinite loop. Assumes that and farts error logs for
each such instant aiscript call. If only there was some aiscript prop to tell
the engine that this particular script was born to return instantly...

So - I am writing this having those four helpers wired sweet and neat to
the script body.

But I have to remove them. I am going to remove those four helpers and
replace them with three preprocessors per scan. I am totally not going
to add any "wait 1ms to make that engine happy" stuff! That would make
the script asynchronous which would cause too many potential errors inside.
Preprocessors would check the cache, refresh only what's stale and expired
and the script's bulk body will just eat those values, assuming
that cache is totally fresh and valid.

It should work! Make that engine happy again! Hallelujah!

*A few moments later*

// section about decision to make the test harness to make sure everything's correct after any refactor

*A few days later*

// section about preprocessors done, refactor with pursuetargets and checkrelations inversion planned

*A few weeks later*

// section about the pain of inversion, but a huge win at the end - a lot less injections, more readable code, the two real helpers, lots of features like target approach around static enemies (stations), and... the mod split planned

*A few mod versions later*

// section about being done with this mod

## Source

https://github.com/VasiliyTemniy/x4-foundations-enhanced-patrol-ai
