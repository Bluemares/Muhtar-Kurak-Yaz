# MUHTAR: KURAK YAZ (Version 4.6 — 3D Antalya Village) — Jury Presentation (English Summary)

## Game Overview

**MUHTAR: KURAK YAZ (Muhtar: Dry Summer)** is a **3D climate-resilient village management and food-security strategy game** with a freely rotating diorama camera, built in Godot 4 for the COP31 Türkiye / HP - ICPSD - UNDP Game Jam. Set in a sun-drenched **Antalya village** framed by the Taurus Mountains and red pine forests to the north and the Mediterranean coast, olive groves, orange orchards, plastic-tunnel greenhouses, and whitewashed tile-roofed houses to the south, you play as the **Muhtar** (village head) appointed on probation by COP31.

Your primary mission is to **feed the village and ensure food security** through three increasingly harsh 4.5-minute (270 s) summer months (~14 minutes total): June (31°C, 20% drought), July (36°C, 50% drought), and August (42°C, 90% drought). As drought intensifies, the river narrows, heat stress lowers welfare, dry soil slows crop growth, and wildfires spark as a consequence of drought. Players choose crops in both fields and greenhouses (vegetables/carrot, melon, corn, or drought-tolerant wheat), store harvests in granaries, trade in the market, and invest in drip irrigation. At summer's end, the final report highlights **Food Security (% of time villagers were fed)** alongside **Prevention Spent vs. Fire Damage**, proving the core message: **"Every degree is one more field." In climate change, prevention is cheaper than response.**

---

## How to Play

### Food Security & Version 4.6 (3D Antalya Village) Features
- **Primary Goal — Food Security & Star Conditions:** Keeping villagers fed (`0.1` food/s per villager) through escalating drought is at the heart of every run:
  - **June Mission ("Feed the village"):** Have at least 2 intact fields by month's end and keep villagers fed.
  - **July Mission ("Fill the granary"):** End the month with at least **2 days of food** stored in the granary and no hunger.
  - **August Mission ("A table in the drought"):** Grow at least **3 kinds of crops** (vegetables, melon, corn, wheat, greenhouse) by month's end with no hunger.
  - **Food Security Indicator & 1–3 Stars:** Track how many days of food remain in the mission panel, and see *"Food security: villagers fed X% of the time"* on the final screen. Earning **3 stars** requires completing all 3 main missions, keeping villagers **fed at least 90% of the time**, and having at most **2 burned buildings** (**2 stars** requires 80%+ welfare and at least 2 missions; **1 star** requires 60%+ welfare).
- **Crop Selection (Fields & Greenhouses) & Variety Bonus:** Click any **field or greenhouse** and press **Choose crop** (3D plants grow according to the chosen crop, with a `»` **Recommended crop** tip based on current drought and water reserves):
  - **Vegetables (carrot):** 100% water · 100% yield · 1.0x time (balanced default).
  - **Melon:** 135% water · 140% yield · 1.15x time (highest yield when water is plentiful).
  - **Corn:** 115% water · 120% yield · 1.05x time (strong yield).
  - **Wheat:** 55% water · 80% yield · 1.0x time (**drought-tolerant**, needs very little water).
  - **Crop Variety:** Growing 2 / 3 / 4 different crop types grants **+3 / +6 / +10 target welfare**.
- **Granary Storage & Dynamic Market:** Harvests fill your **Granary** first (40 base capacity in COP31 + 100 per **Granary** building); only overflow is auto-sold. Click the top food pill, COP31, or a Granary to open the **Market** (buy/sell in lots of 10). Crop prices rise with drought (`1.5 × (1 + drought × 0.8)`), and buying food during a shortage costs **1.6x** the sell price.
- **Heat Stress & Dry Soil Growth Penalty:** Rising drought causes **heat stress** that lowers target welfare (up to `drought × 22`, shown as *"Heat stress −X"* in the mission panel), mitigated by full water storage and groves. In addition, **dry fields grow significantly slower** (down to 35% speed on bone-dry soil, `MOIST_GROWTH_MIN = 0.35`).
- **3D Antalya Valley (32×22) & Living Village Life:** Surrounded by the **Taurus Mountains** in the north/east/west and the **Mediterranean Sea** in the south, accompanied by a daytime **cicada chorus**. Upgrading the stone COP31 hall expands buildable land twice (Lv.1: 14×10 & 6 villagers; Lv.2 [350 gold]: 22×16 & 10 villagers; Lv.3 [600 gold]: full 32×22 valley & 14 villagers). Villagers work with a **hoe** in fields and greenhouses, use an **axe** when clearing trees/rocks, and when idle, **draw buckets of water from the well and carry them to the water tower** (or COP31 if no tower is built, +4 water).
- **Road Requirement, Road Erase & Land Clearing:** **Every building except COP31 and groves must touch a road to operate** (groves work without a road). From Build → Infrastructure, drag to lay roads (**10 gold/tile**), toggle the **Erase road** button to turn left-click into an eraser (right-click also removes for a +5 gold refund), upgrade road levels (Lv.2: 100, Lv.3: 200), or **Clear land** (rocks: 40 gold, trees: 25 gold — an idle villager chops/clears it in 4 s; cutting forest reduces welfare by 1.5).
- **3D Buildings, Rotation (R) & Selling Buildings:** Open the **Build** shop (**Farming / Water / Housing / Infrastructure** tabs with 3D model previews). Rotate any building with the **R** key or the on-building **Rotate** button (both while placing and when selected). Any building except COP31 and the Fire Station can be demolished via the **Sell** button (with confirmation) for a **50% gold refund**:
  - **Field (150 gold, 2×2, 1 worker):** Grows selected crops; add **Drip Irrigation (60 gold)** to cut water use by 40%.
  - **Greenhouse (260 gold, 2×1, 1 worker):** Antalya-style plastic tunnel; grows 2×4 plants of the selected crop, uses 40% of a field's water (0.32/s), immune to drought, pests, and fire.
  - **Granary (160 gold, 2×1):** Adds +100 food storage capacity.
  - **Well (200 gold, 1×1) & Water Tower (180 gold, 1×1):** Wells produce 2.2 / 3.4 / 5.0 water/s (+50% near river) and expand hose tanks (150 / 210 / 280); Water Towers add +100 storage and +40 hose tank capacity.
  - **Grove (40 gold, 1×1):** Needs no road; irrigated orange/olive trees cut adjacent building fire risk by 40%, field water use by 10%, and ease heat stress.
  - **House (120 gold, 1×1) & Street Lamp (30 gold, 1×1):** Whitewashed Antalya homes (2 villagers each) and road-connected lamps that illuminate a 5.5-unit radius at night.
- **Separate Fire Risk (F) & Soil Moisture (N) Maps:** Two dedicated buttons and hotkeys at the bottom right: **F (Risk — flame icon)** displays per-minute ignition probability on flammable buildings, and **N (Moisture — droplet icon)** shows soil moisture (Moist/Fair/Dry). When fire breaks out, the 3D fire truck dispatches along the road network into a 25-second **hose minigame** over a live 3D camera view.
- **9-Card How to Play, 6 Characters & Progression:** Includes a **9-card How to Play** guide (*Goal, Produce, Granary & market, Roads matter, Pick crops, Fire, Prevent, COP31, Controls*), 3D portraits for 6 characters (*Uncle Hasan, Elif, Murat, Teacher Zeynep, Aunt Fatma, Kerem*), 9 COP31 policies, 9 side tasks, 9 achievements, and autosave.

### Controls
- **Left Click:** Select buildings, click on-building circular action buttons (*Upgrade, Choose crop, Drip irrigation, Spray, Repair, Move, Rotate, Sell, Market*), tap ripe crop bubbles (+15% bonus), drag to lay/erase roads; hold and sweep in the firefighting minigame to spray water. (**Double-click** a building to focus the camera on it.)
- **Right-Click Drag:** Freely **rotate and tilt** the 3D diorama camera.
- **Q / E:** Rotate the camera left / right.
- **Middle-Click Drag or WASD / Arrow Keys:** Pan the camera across the valley.
- **Mouse Wheel:** Zoom in / out.
- **B Key:** Open / close the categorized **Build** shop.
- **F Key:** Toggle the **Fire Risk** map overlay (flame button).
- **N Key:** Toggle the **Soil Moisture** map overlay (droplet button).
- **R Key:** Rotate a selected building or a building being placed by 90°.
- **Right Click (Single):** Cancel building/moving mode; remove road tiles in road mode (+5 gold refund).
- **Esc:** Deselect building/mode or open the pause menu (includes the 9-card **How to Play** guide and TR/EN toggle).

---

## Jury Criteria Alignment

| Criterion | Implementation in MUHTAR: KURAK YAZ (Version 4.6) |
|---|---|
| **Theme Alignment (Food Security, Climate Resilience & COP31)** | Places **food security** front and center: crop choices in fields and greenhouses (thirsty melon vs. drought-tolerant wheat), crop variety welfare bonuses, granary storage, drought-driven market pricing, heat stress, slow growth on dry soil, separate soil moisture (`N`) and fire risk (`F`) overlays, drip irrigation (-40% water), COP31 local climate action policies, and the COP27/COP31 Loss and Damage Fund (+120 emergency aid). Final screen reports both *Food Security (% time fed)* and *Prevention vs. Fire Damage*. |
| **Creativity & Originality** | Brings an authentic **3D Antalya village** (Taurus Mountains, Mediterranean coast, greenhouses, citrus/olive groves, cicada audio) to life with a freely rotating diorama camera, 6 named village characters, road-network logistics, and a live-3D firefighting hose minigame. |
| **Gameplay & Design** | A ~14-minute campaign (3 months × 4.5 min) with camera & crop-selection onboarding, smart crop recommendations, a categorized 3D **Build Shop**, **on-building action buttons** (including rotation and half-price selling), road eraser mode, **tap-to-harvest (+15% bonus)**, and a **9-card How to Play** guide. **Difficulty balance** is verified by automated bots: passive play loses (0 welfare), greedy/unprepared play fails under heat stress and drought (6–8 welfare), while smart preventive play wins with 100 welfare and 2–3 stars. |
| **Technical Execution** | Built in Godot 4.7 (GL Compatibility, desktop & WebGL) using a clean **2D simulation logic + 3D presentation layer (`WorldView3D`)** architecture, MultiMesh forests/rocks, web-safe `CPUParticles3D`, road-weighted AStarGrid2D pathfinding, SubViewport 3D thumbnails, hot-swappable Blender `.glb` support (`docs/BLENDER_NAMING.md`), and multi-seed bot verification (~200 desktop FPS, 0 errors). |
| **Presentation & Communication** | Witcher-style vertical main menu over a live rotating sunset village, *Cinzel* & *Alegreya Sans* typography, animated 3D villagers working with hoes, axes, and water buckets (carrying water from wells to the water tower), chicks/cows/dogs, night window & street lamp lighting, yellowing trees, and a shrinking river. |
| **Time Management & Scope** | Progressed through all major iterations (base game → Version 2 valley → Version 3 UX → **Version 4.6 full 3D Antalya village, food security & difficulty tuning**) on schedule, preserving 2D backup builds (`build/backup_2d/`) while delivering complete 3D Windows and Web packages. |

---

## Credits

- **Design & Development:** Erdem Sosar, Berke Buyruk
- **3D Models & Sound Effects:** Kenney (`kenney.nl`) — *Nature Kit, Fantasy Town Kit, Car Kit, Mini Characters, Cube Pets, Interface / Impact / RPG Audio* (all CC0; custom Antalya palette adaptation). *(2D Pixel packs: Tiny Town, Tiny Farm, Pixel UI Pack — retained for the backup 2D build in `build/backup_2d/`, CC0).*
- **Fonts:** *Cinzel* and *Alegreya Sans* (Google Fonts, SIL Open Font License).
- **Music & Ambient Loops:** Procedurally generated in-project (`tools/synth_audio.py` — Hicaz makam theme and daytime cicada chorus).
- **Engine:** Godot Engine 4 (MIT licence)
