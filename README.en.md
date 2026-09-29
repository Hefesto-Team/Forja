<p align="center">
  <img src="docs/imagens/salao.jpg" alt="The forge hall: four players, the room gates and the anvil in the middle" width="100%">
</p>

<h1 align="center">Forja — the Hefesto Tech Demo</h1>

<p align="center">
  <b>A local 3D party game for up to four DualSense controllers —<br>
  that measures, while you play, what actually reached each controller.</b>
</p>

<p align="center"><a href="README.md">Português</a> · English</p>

---

## What it is

Forja uses everything the DualSense has — buttons, sticks, adaptive
triggers, gyroscope, accelerometer, touchpad, both rumble motors, the light
bar, the player LEDs, the speaker, the voice-coil haptics and the microphone
with its mute button — the way commercial games use them, in nine short rooms
for four people on the same couch.

While you play, each room measures what reached each controller and gives,
per player, a verdict for every feature: **passed**, **failed** (with what was
measured) or **not measured** (with the reason). At the end, the session book
shows the table, and the report is written to disk.

This is how [Hefesto](https://github.com/Hefesto-Team/hefesto-dualsense4unix)
is validated: by playing. The game speaks DualSense the way Sony and Steam
document it — USB report `0x02`, the four official trigger modes, player
index 0..3 — and never talks to Hefesto. Whatever sits in front of the
controller is invisible; four controllers in four hands are the oracle. The
law of the repository is [CONTRATO.md](CONTRATO.md) (in Portuguese).

## The party

In the hall, □ at the anvil starts a **match**: 3, 5 or all 9 rooms, in the
route order or shuffled, at a pace (first time, normal, fast). Each room gives
night points by placement (4, 3, 2, 1), the scoreboard shows up between rooms,
and the podium closes the night. Every room also plays with 1, 2 or 3
controllers and says what changes.

Before getting ready in the lobby, △ opens the **options**: per seat, the
triggers (off, weak, strong) and rumble (0 to 100%); per session, TV and
controller volume, camera shake, flashes, fullscreen, larger text and the
**language** (Português or English). The music is synthwave, synthesized by
the game itself.

## The rooms

| room | validates |
| --- | --- |
| A Centelha (The Spark) | buttons, sticks, analog triggers |
| A Viga (The Beam) | gyroscope, accelerometer |
| O Molde (The Mold) | two-finger touchpad, click |
| O Impacto (The Impact) | strong and weak motors, isolation between controllers, light bar |
| A Galeria (The Gallery) | trigger resistance, weapon and vibration modes; player LEDs |
| O Canto (The Song) | controller speaker |
| Os Caminhos (The Paths) | audio haptics (channels 3 and 4) |
| A Voz (The Voice) | microphone, mute, mute LED |
| A Prova (The Trial) | everything at once, in two teams |

## Download and play

Each tagged version is published as a GitHub release with three packages:
`forja-linux-x86_64.tar.gz`, `FORJA-x86_64.AppImage` and
`forja-windows-x86_64.zip` (the `.exe`, which also runs through Proton with
Steam Input turned off for the game). Every CI run also leaves them as
artifacts.

On the controller: ✕ joins and readies, Create opens the live diagnostics,
Options pauses. With no controller at all, the title screen offers to play on
the keyboard (it becomes a simulated DualSense).

## Build from source

```sh
./run-local.sh                       # builds the native module and opens the game
./run-local.sh -- --simular=4 --robo # four simulated controllers, and the robot plays
scripts/exportar.sh tudo             # the Linux build and the .exe
scripts/exportar.sh appimage         # the AppImage, from the Linux build
```

## Tests without hardware

```sh
bash tests/prova_do_jogo.sh     # the game, headless, with four simulated DualSense
bash tests/prova_de_poucos.sh   # every room with 1, 2 and 3 controllers, the paces, the options, the cable pulled mid-room
scripts/gauntlet.sh             # the same test again with each fake defect: it must fail
bash tests/telas.sh fotos out/  # screenshots, compared in CI against the previous version
```

## What stays in Portuguese

The screens are translated. The explanation under each verdict (what was
measured and why) and the session report come from the native core and stay in
Portuguese, as does the documentation in `docs/`.
