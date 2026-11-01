extends CanvasModulate
## Gündüz-gece ışığı: dünyayı (canvas katmanı 0) saate göre boyar. HUD etkilenmez.

const DAWN := Color(0.95, 0.78, 0.7)
const DAY := Color(1, 1, 1)
const DUSK := Color(1.0, 0.72, 0.5)
const NIGHT := Color(0.42, 0.47, 0.72)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	color = tint(GameState.day_phase())


## phase 0..1: 0 şafak, 0.1–0.55 gün, 0.65 akşam, 0.75–0.95 gece.
static func tint(p: float) -> Color:
	if p < 0.1:
		return DAWN.lerp(DAY, p / 0.1)
	if p < 0.55:
		return DAY
	if p < 0.67:
		return DAY.lerp(DUSK, (p - 0.55) / 0.12)
	if p < 0.77:
		return DUSK.lerp(NIGHT, (p - 0.67) / 0.1)
	if p < 0.93:
		return NIGHT
	return NIGHT.lerp(DAWN, (p - 0.93) / 0.07)
