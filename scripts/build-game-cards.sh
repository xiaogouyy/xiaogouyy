#!/usr/bin/env bash
# Builds the two game cards shown in README.md:
#   assets/recently-played.svg   (top card, replaces "last jammed out to")
#   assets/favorite-games.svg    (three columns: all time / yearly / current)
#
# Icons live in assets/games/<slug>.jpg and are embedded as base64,
# because GitHub will not load external images from inside an SVG.
#
# To change a list, edit the arrays below and run:
#   bash scripts/build-game-cards.sh
# Each entry is "slug|Game name|Studio".

set -euo pipefail
cd "$(dirname "$0")/.."

RECENT=(
  "dota-2|Dota 2|Valve"
  "genshin-impact|Genshin Impact|HoYoverse"
)

ALL_TIME=(
  "elden-ring|ELDEN RING|FromSoftware"
  "sekiro|Sekiro: Shadows Die Twice|FromSoftware"
  "baldurs-gate-3|Baldur's Gate 3|Larian Studios"
  "silent-hill-2|Silent Hill 2|Bloober Team"
  "genshin-impact|Genshin Impact|HoYoverse"
)

YEARLY=(
  "resident-evil-requiem|Resident Evil Requiem|Capcom"
  "ace-combat-8|Ace Combat 8|Bandai Namco"
  "ea-fc-27|EA Sports FC 27|EA Sports"
  "diablo-4|Diablo IV|Blizzard"
  "battlefield-1|Battlefield 1|DICE"
)

CURRENT=(
  "genshin-impact|Genshin Impact|HoYoverse"
  "dota-2|Dota 2|Valve"
  "overwatch|Overwatch|Blizzard"
  "super-mario-party|Super Mario Party|Nintendo"
  "splatoon-3|Splatoon 3|Nintendo"
)

FONT="-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif,Apple Color Emoji,Segoe UI Emoji"

# Shared look: light cards by default, dark cards when GitHub is in dark mode.
COMMON_CSS='
* { margin: 0; box-sizing: border-box; }
p { display: block; opacity: 0; }
.title {
  color: rgba(115, 115, 115, .8);
  font-family: '"$FONT"';
  font-size: 18px; font-weight: 600; line-height: 1.5;
  text-align: center;
  animation: appear 300ms ease-out forwards;
}
.game {
  display: flex; align-items: center;
  background: rgba(255, 255, 255, .6);
  border: 1px solid rgba(0, 0, 0, .1);
  border-radius: .3rem;
  padding: .7rem;
}
.game .details {
  display: flex; flex: 1; flex-direction: column;
  margin-top: -4px; margin-left: 10px;
}
.name, .studio {
  font-family: '"$FONT"';
  font-size: 14px; line-height: 1.5;
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  animation: appear 300ms ease-out forwards;
}
.name { color: #1f2328; font-weight: 600; animation-delay: 400ms; }
.studio { color: #59636e; font-weight: 400; animation-delay: 500ms; }
.icon {
  width: 40px; height: 40px; border-radius: 4px; flex-shrink: 0;
  opacity: 0;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1), 0 3px 10px rgba(0,0,0,0.05);
  animation: icon-appear 300ms ease-out 300ms forwards;
}
@media (prefers-color-scheme: dark) {
  .game { background: rgba(255, 255, 255, .05); border-color: rgba(255, 255, 255, .15); }
  .name { color: #f0f6fc; }
  .studio { color: #9198a1; }
}
@keyframes appear {
  from { opacity: 0; transform: translateX(-8px); }
  to { opacity: 1; transform: translateX(0); }
}
@keyframes icon-appear {
  from { opacity: 0; transform: scale(0.8); }
  to { opacity: 1; transform: scale(1); }
}
'

# game_card "slug|Name|Studio" -> one card of HTML
game_card() {
  local slug name studio file
  IFS='|' read -r slug name studio <<< "$1"
  file="assets/games/$slug.jpg"
  [[ -f "$file" ]] || { echo "missing icon: $file" >&2; exit 1; }
  name=${name//&/&amp;}; studio=${studio//&/&amp;}
  printf '<div class="game"><img class="icon" src="data:image/jpeg;base64,%s"/><div class="details"><p class="name">%s</p><p class="studio">%s</p></div></div>' \
    "$(base64 -w0 "$file")" "$name" "$studio"
}

svg_open() { # width height
  printf '<svg width="%s" height="%s" viewBox="0 0 %s %s" fill="none" xmlns="http://www.w3.org/2000/svg"><foreignObject width="%s" height="%s"><div xmlns="http://www.w3.org/1999/xhtml">' "$1" "$2" "$1" "$2" "$1" "$2"
}
svg_close() { printf '</div></foreignObject></svg>\n'; }

# ---------- recently played ----------
bars() { # side
  printf '<div class="bars %s"><div class="bar" style="--offset:0"></div><div class="bar" style="--offset:1"></div><div class="bar" style="--offset:2"></div></div>' "$1"
}
{
  svg_open 640 130
  printf '<style>%s
.title { margin: .5rem; }
.recent { display: flex; justify-content: center; align-items: center; }
.recent .game { margin: 0 .4rem; }
.recent .name, .recent .studio { width: 140px; }
.bars { display: flex; flex-direction: column; justify-content: center; width: 80px; }
.bars.left { align-items: flex-end; }
.bars.right { align-items: flex-start; }
.bar {
  --offset: 0;
  background: rgba(102, 192, 244, .7);
  height: 10px; margin: 2px 0; width: 50px;
  animation: bars 1.7s ease calc(var(--offset) * -.5s) infinite;
}
@keyframes bars { 0%% { width: 25%%; } 50%% { width: 90%%; } 100%% { width: 25%%; } }
</style>' "$COMMON_CSS"
  printf '<p class="title">recently played</p><div class="recent">'
  bars left
  for g in "${RECENT[@]}"; do game_card "$g"; done
  bars right
  printf '</div>'
  svg_close
} > assets/recently-played.svg

# ---------- favorites, three columns ----------
column() { # title, entries...
  local title=$1; shift
  printf '<div class="column"><p class="title">%s</p>' "$title"
  for g in "$@"; do game_card "$g"; done
  printf '</div>'
}
{
  svg_open 840 450
  printf '<style>%s
.wrapper { display: flex; justify-content: space-around; }
.title { margin: .5rem .5rem 1rem; }
.column .game { margin: 0 .5rem 1rem; }
.column .name, .column .studio { width: 190px; }
</style>' "$COMMON_CSS"
  printf '<div class="wrapper">'
  column "all time favorites" "${ALL_TIME[@]}"
  column "yearly favorites" "${YEARLY[@]}"
  column "current favorites" "${CURRENT[@]}"
  printf '</div>'
  svg_close
} > assets/favorite-games.svg

echo "wrote assets/recently-played.svg and assets/favorite-games.svg"
