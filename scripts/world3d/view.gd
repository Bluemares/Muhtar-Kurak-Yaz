class_name View
extends RefCounted
## 2D oyun mantığı ile görüntü katmanı arasındaki köprü.
## Mantık dünya pikseli (Bal.CELL = 1 hücre) kullanır; 3D'de 1 hücre = 1 birim.
## Kamera 3D ise dünya↔ekran dönüşümleri ışın/izdüşümle yapılır, değilse canvas dönüşümüyle.

static var camera = null  # camera_rig_3d.gd örneği; null → 2D
static var risk_map := false  # yangın riski haritası açık mı (F)
static var moist_map := false  # toprak nemi haritası (F ile risk → nem → kapalı)

const RISK_LOW := 0.05  # dakikada %5 altı düşük
const RISK_HIGH := 0.12  # %12 üstü yüksek


## Nem 0..1: mavi iyi, sarı orta, kırmızı kuru.
static func moist_color(m: float) -> Color:
	if m > 0.6:
		return Color(0.3, 0.7, 1.0)
	if m > 0.35:
		return Color(1.0, 0.8, 0.2)
	return Color(1.0, 0.3, 0.15)


static func risk_color(r: float) -> Color:
	if r < RISK_LOW:
		return Color(0.3, 0.85, 0.35)
	if r < RISK_HIGH:
		return Color(1.0, 0.8, 0.2)
	return Color(1.0, 0.25, 0.15)


static func is_3d() -> bool:
	return camera != null and is_instance_valid(camera)


## Dünya pikseli → 3D konum (zemin yüksekliği h).
static func to3(p: Vector2, h := 0.0) -> Vector3:
	return Vector3(p.x / Bal.CELL, h, p.y / Bal.CELL)


static func to2(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z) * Bal.CELL


## Dünya pikseli → ekran (HUD) koordinatı. h: zeminden yükseklik (birim).
static func to_screen(node: Node, p: Vector2, h := 0.0) -> Vector2:
	if is_3d():
		return camera.world_to_screen(p, h)
	return node.get_viewport().get_canvas_transform() * p


## Faredeki dünya pikseli (3D'de zemin düzlemine ışın).
static func mouse_world(node: CanvasItem) -> Vector2:
	if is_3d():
		return camera.screen_to_world(node.get_viewport().get_mouse_position())
	return node.get_global_mouse_position()
