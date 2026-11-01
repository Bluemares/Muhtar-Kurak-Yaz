extends Node
## Tüm denge sayıları ve veri tabloları burada. Oyunu ayarlamak için yalnızca bu dosyayı düzenle.

# --- Harita ---
const GRID_W := 32
const GRID_H := 22
const CELL := 64
const RENDER_3D := true  # false: Sürüm 3 pixel görünümü (yedek)
const ROAD_ROWS := [10]
const ROAD_COLS := [16]
## COP31 seviyesine göre açık alan (seviye 1: köy merkezi, 2: orta halka, 3: tüm vadi)
const UNLOCK_RECTS := [Rect2i(), Rect2i(9, 6, 16, 10), Rect2i(5, 3, 22, 16), Rect2i(0, 0, 32, 22)]
const RIVER_WELL_DIST := 2.5  # nehre bu kadar yakın kuyu bonus alır (hücre)
const RIVER_WELL_BONUS := 0.5  # kurak değilken +%50 su; kuraklıkla azalır (nehir kurur)

# --- Zaman / turlar ---
const ROUND_SECONDS := 270.0
const MONTH_KEYS := ["MONTH_JUNE", "MONTH_JULY", "MONTH_AUGUST"]
const MISSION_KEYS := ["MISSION_JUNE", "MISSION_JULY", "MISSION_AUGUST"]
const MISSION_DESC_KEYS := ["MISSION_JUNE_DESC", "MISSION_JULY_DESC", "MISSION_AUGUST_DESC"]
const DROUGHT := [0.2, 0.5, 0.9]
const TEMPERATURE := [31, 36, 42]
const MISSION_REWARD_MONEY := 100
## Ay içi yan görevler: [id, ödül para]. Koşullar game.gd _side_done() içinde.
const SIDE_MISSIONS := [
	[["road2", 40], ["house3", 40], ["river_well", 60]],
	[["drip", 50], ["spray", 30], ["cop2", 80]],
	[["full_tank", 60], ["station_near", 50], ["fields4", 60]],
]
const FULL_TANK_SECONDS := 30.0
# --- COP31 politika kartları (ay sonu 3'ten 1) ---
const POLICIES := ["solar_pump", "crop_insurance", "early_warning", "fire_watch", "local_market",
	"rain_harvest", "seed_bank", "community_kitchen", "green_fund"]
const POLICY_ICONS := {"solar_pump": ["sun", -1], "crop_insurance": ["", 9], "early_warning": ["clock", -1],
	"fire_watch": ["", 83], "local_market": ["coin", -1], "rain_harvest": ["", 73], "seed_bank": ["", 68],
	"community_kitchen": ["", 125], "green_fund": ["heart", -1]}
# --- Gündüz-gece ---
const DAY_SECONDS := 90.0  # ay başına 3 gün
const DAY_START_PHASE := 0.12  # ay sabah başlar
const NIGHT_FIRE_MULT := 0.5  # gece serin: yangın riski yarıya iner
const NOON_FIRE_MULT := 1.15
const MISSION_REWARD_WELFARE := 5.0

# --- Başlangıç ---
const START_MONEY := 300
const START_WORKERS := 4
const START_FOOD := 40.0
const START_WATER := 40.0
const START_WELFARE := 70.0
const START_LAYOUT := [
	["cop31", Vector2i(14, 8)],
	["fire_station", Vector2i(21, 7)],
	["well", Vector2i(14, 12)],
	["field", Vector2i(17, 12)],
	["house", Vector2i(11, 8)],
	["house", Vector2i(11, 12)],
]

# --- Nüfus ---
const WORKERS_PER_HOUSE := 2
const MAX_WORKERS_BY_COP_LEVEL := [0, 6, 10, 14]

# --- Su (birim / sn) ---
const WELL_SEASON_MULT := [1.0, 0.96, 0.90]  # Kuru aylarda kuyu verimi azalır.
const WELL_WATER := [0.0, 2.2, 3.4, 5.0]
const WATER_CAP_BASE := 60.0
const WATER_CAP_PER_WELL_LEVEL := 30.0
const FIELD_WATER := 0.8
const WORKER_WATER := 0.12
const DROUGHT_WATER_FACTOR := 0.5

# --- Ürün ---
const HARVEST_TIME := [0.0, 16.0, 13.0, 10.0]
const HARVEST_YIELD := [0.0, 20.0, 25.0, 32.0]
const FOOD_PER_WORKER := 0.1
const CROP_PRICE := 1.25
const PEST_YIELD_MULT := 0.5
const AUTO_HARVEST_DELAY := 4.0  # olgun ürün tıklanmazsa bu kadar sn sonra kendiliğinden toplanır
const TAP_HARVEST_BONUS := 1.15  # dokunarak hasat bonusu

# --- Refah ---
const WELFARE_RATE := 0.6  # hedefe yükselme hızı (puan/sn)
const HOMELESS_DROP := 20.0  # tüm köylüler evsizse hedeften düşülen puan
const WELFARE_FALL_RATE := 0.8  # hedefe düşme hızı (puan/sn)
const CRISIS_TARGET_DROP := 80.0  # tam açlık/susuzlukta hedeften düşülen puan (eksikle orantılı)
const WELFARE_GROWTH_THRESHOLD := 60.0
const GROWTH_INTERVAL := 30.0
const HUNGER_ROUND_PENALTY := 10.0
const WIN_WELFARE := 60.0
const GOOD_WELFARE := 80.0

# --- Yol (köy altyapısı, tek yükseltme) ---
const ROAD_SPEED := [0.0, 1.0, 1.25, 1.5]
const ROAD_UPGRADE_COST := [0, 0, 100, 200]
const ROAD_MAX_LEVEL := 3

# --- Hareket ---
const WORKER_SPEED := 55.0
const ROAD_TILE_COST := 10  # oyuncunun döşediği yol hücresi
const ROAD_TILE_REFUND := 5
const ROAD_YIELD_MULT := 1.0  # yol artık şart (yolsuz bina çalışmaz); ek verim yok
# Başlangıç binalarını ana yola bağlayan kısa yollar (COP31 hariç her bina yola bitişik olmalı)
const START_ROADS := [Vector2i(21, 8), Vector2i(21, 9), Vector2i(14, 11), Vector2i(11, 9), Vector2i(11, 11)]
# Tarla ürünleri: su çarpanı, verim çarpanı, süre çarpanı. Buğday kurakta dayanıklı (az su).
const CROPS := {
	"veg": {"name": "CROP_VEG", "water": 1.0, "yield": 1.0, "time": 1.0},
	"melon": {"name": "CROP_MELON", "water": 1.35, "yield": 1.4, "time": 1.15},
	"corn": {"name": "CROP_CORN", "water": 1.15, "yield": 1.2, "time": 1.05},
	"wheat": {"name": "CROP_WHEAT", "water": 0.55, "yield": 0.8, "time": 1.0},
}
const CROP_ORDER := ["veg", "melon", "corn", "wheat"]
# Arazi temizleme (COP31 büyüyünce açılan alandaki kaya/orman). Orman kesmek refahı biraz düşürür.
const CLEAR_COST := {"rock": 40, "forest": 25}
const FOREST_CLEAR_WELFARE := 1.5
const CLEAR_TIME := 4.0  # bir köylünün kayayı/ağacı kaldırma süresi (sn)
# Köylüler kuyudan depoya su taşır (boşta kalanlar)
const CARRY_CHANCE := 0.35
const CARRY_WATER := 4.0
const CARRY_FILL_TIME := 1.5
# Yangında hortum tankı köyün su deposundan dolar
const DEPOT_REFILL := 70.0
const HOSE_PER_EXTRA_FIRE := 40.0  # aynı anda yanan her ek bina için tanka eklenen  # sn başına depodan tanka
const LAMP_RANGE := 5.5
const SELL_REFUND := 0.5
const NO_ROAD_NEEDED := ["cop31", "grove"]  # yol şartı olmayan binalar (köy merkezi, koruluk)
const HEAT_STRESS := 22.0  # sıcak stresi: refah hedefi − kuraklık × 22 × (1 − depo doluluğu × 0.6 − koruluk etkisi)
const MOIST_GROWTH_MIN := 0.35  # kupkuru tarla bu hızda büyür  # satılan binanın geri ödenen payı
const OFFROAD_SPEED := 0.85  # çimende yürüme hızı çarpanı
const ONROAD_SPEED := 1.25  # yolda (yol seviyesiyle çarpılır)
const TRUCK_SPEED := 80.0
const TRUCK_OFFROAD := 0.4  # yol dışında hız çarpanı
const MOVE_DURATION := 5.0

# --- Tehditler ---
const FIRE_BASE := {"field": 0.0007, "house": 0.00025, "granary": 0.0003}  # sn başına; kuraklık ile çarpılır
const FIRE_DRY_MULT := 1.8  # su deposu boşken yangın riski çarpanı
const FIRE_WET_MULT := 0.5  # su deposu doluyken yangın riski çarpanı
const FIRE_DROUGHT_MULT := 2.0
const FIRE_SPREAD_PER_SEC := 0.035
const FIRE_SPREAD_DIST := 1.6  # hücre cinsinden kenar boşluğu
const GUARANTEED_FIRE_ROUND := 1  # demo: Temmuz'da en az bir yangın
const GUARANTEED_FIRE_AT := 60.0  # tur başından itibaren sn
const FIRE_GRACE_SECONDS := 90.0  # Haziran başında rastgele yangın yok (öğrenme süresi)
const AID_MONEY := 120  # COP31 Kayıp ve Zarar Fonu: çöküşte tur başına bir kez
const PEST_START_ROUND := 1
const PEST_CHANCE := 0.004
const SPRAY_COST := 40
const DRIP_COST := 60  # damla sulama: tarla başına tek seferlik önlem
const DRIP_WATER_MULT := 0.6  # damla sulamalı tarla bu oranda su içer
const SPRAY_DURATION := 180.0
const REPAIR_FACTOR := 0.5

# --- Yangın minigame ---
const MINIGAME_SECONDS := 25.0
const HOSE_TANK := [0.0, 150.0, 210.0, 280.0]
const HOSE_RADIUS := [0.0, 46.0, 56.0, 68.0]
const HOSE_DRAIN := 18.0
const HOSE_REFILL := 6.0
const FLAME_START := 3
const FLAME_GROW := 0.09
const FLAME_DOUSE := 2.0
const FLAME_SPAWN_INTERVAL := 3.2
const CINEMATIC_MAX := 5.5

# --- Yapılar (yeni bina = yeni satır) ---
const BUILDINGS := {
	"cop31": {"name": "B_COP31", "size": Vector2i(2, 2), "movable": false, "flammable": false, "cost": 0, "max_level": 3, "upgrade": [0, 0, 350, 600], "workers": 0, "color": Color("4a7fbf")},
	"fire_station": {"name": "B_FIRE_STATION", "size": Vector2i(2, 2), "movable": true, "flammable": false, "cost": 0, "max_level": 1, "upgrade": [0, 0], "workers": 0, "color": Color("c0392b")},
	"well": {"name": "B_WELL", "size": Vector2i(1, 1), "movable": true, "flammable": false, "cost": 200, "max_level": 3, "upgrade": [0, 0, 100, 200], "workers": 0, "color": Color("3d8fd1")},
	"field": {"name": "B_FIELD", "size": Vector2i(2, 2), "movable": true, "flammable": true, "cost": 150, "max_level": 3, "upgrade": [0, 0, 100, 200], "workers": 1, "color": Color("8a6a3b")},
	"greenhouse": {"name": "B_GREENHOUSE", "size": Vector2i(2, 1), "movable": true, "flammable": false, "cost": 260, "max_level": 1, "upgrade": [0, 0], "workers": 1, "color": Color("9fd8e8")},
	"water_tower": {"name": "B_WATER_TOWER", "size": Vector2i(1, 1), "movable": true, "flammable": false, "cost": 180, "max_level": 1, "upgrade": [0, 0], "workers": 0, "color": Color("6fa8dc")},
	"granary": {"name": "B_GRANARY", "size": Vector2i(2, 1), "movable": true, "flammable": true, "cost": 160, "max_level": 1, "upgrade": [0, 0], "workers": 0, "color": Color("b08850")},
	"lamp": {"name": "B_LAMP", "size": Vector2i(1, 1), "movable": true, "flammable": false, "cost": 30, "max_level": 1, "upgrade": [0, 0], "workers": 0, "color": Color("f2c744")},
	"grove": {"name": "B_GROVE", "size": Vector2i(1, 1), "movable": true, "flammable": false, "cost": 40, "max_level": 1, "upgrade": [0, 0], "workers": 0, "color": Color("3c8d3c")},
	"house": {"name": "B_HOUSE", "size": Vector2i(1, 1), "movable": true, "flammable": true, "cost": 120, "max_level": 1, "upgrade": [0, 0], "workers": 0, "color": Color("d9a066")},
}
const BUILDABLE := ["field", "well", "house", "greenhouse", "water_tower", "grove", "lamp", "granary"]
# --- Gıda güvenliği ---
const FOOD_CAP_BASE := 65.0  # COP31 kilerinin kapasitesi
const GRANARY_CAP := 100.0  # ambar başına
const SELL_DROUGHT := 0.8  # kuraklıkla pazar fiyatı artar: fiyat × (1 + kuraklık × 0.8)
const BUY_MULT := 1.6  # pazardan almak satmaktan pahalı
const MARKET_LOT := 10
const DIVERSITY_BONUS := [0.0, 0.0, 3.0, 6.0, 10.0, 10.0]  # farklı ürün sayısına göre refah hedefi
const JULY_FOOD_DAYS := 2.0
const AUGUST_CROP_KINDS := 3
# --- Yeni binalar ---
const GREENHOUSE_TIME := 14.0
const GREENHOUSE_YIELD := 19.0
const GREENHOUSE_WATER := 0.32  # tarlanın %40'ı; kuraklıktan etkilenmez
const TOWER_CAP := 100.0  # su kulesi depo kapasitesi
const TOWER_HOSE := 40.0  # yangında hortum tankına eklenen
const GROVE_FIRE_MULT := 0.6  # korulukların yanındaki binalarda yangın riski çarpanı
const GROVE_WATER_MULT := 0.9  # koruluk komşusu tarlanın su tüketimi çarpanı
const GROVE_DIST := 1.6  # hücre cinsinden kenar boşluğu


func bdata(type: String) -> Dictionary:
	return BUILDINGS[type]
