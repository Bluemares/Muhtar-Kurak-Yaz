class_name ClimateReport
extends RefCounted
## Capture BEFORE the final backdrop resets the simulation. Store keys, not translations.

static func snapshot(period: Dictionary) -> Dictionary:
	var gs := GameState
	var daily := gs.food_consumption_per_second() * Bal.DAY_SECONDS
	var counts := {"drip": 0, "grove": 0, "water_tower": 0, "granary": 0}
	for b in gs.buildings:
		if not is_instance_valid(b) or not b.is_operational():
			continue
		if b.type in ["grove", "water_tower", "granary"]:
			counts[b.type] += 1
		if b.type == "field" and b.drip:
			counts.drip += 1
	var measures: Array = []
	if counts.drip > 0:
		measures.append(["REPORT_DRIP", [counts.drip, roundi((1.0 - Bal.DRIP_WATER_MULT) * 100)]])
	if counts.water_tower > 0:
		measures.append(["REPORT_TOWERS", [counts.water_tower, int(counts.water_tower * Bal.TOWER_CAP)]])
	if counts.granary > 0:
		measures.append(["REPORT_GRANARIES", [counts.granary, int(counts.granary * Bal.GRANARY_CAP)]])
	if counts.grove > 0:
		measures.append(["REPORT_GROVES", [counts.grove, roundi((1.0 - Bal.GROVE_WATER_MULT) * 100), roundi((1.0 - Bal.GROVE_FIRE_MULT) * 100)]])
	for id in ["water_saving", "volunteers", "stubble_banned"]:
		if gs.flags.get(id, false):
			measures.append(["REPORT_" + id.to_upper(), []])
	for id in gs.policies():
		measures.append(["POL_" + String(id).to_upper() + "_DESC", []])
	return {"population": gs.workers.size(), "stock": gs.food,
		"stock_days": gs.food / daily if daily > 0.0 else 0.0,
		"produced_days": float(period.get("produced", 0.0)) / daily if daily > 0.0 else 0.0,
		"water_demand_avoided": period.get("water_demand_avoided", 0.0),
		"food_saved": period.get("food_saved", 0.0), "measures": measures}

static func add_to(parent: Control, report: Dictionary, width: float) -> void:
	if report.is_empty():
		return
	var panel := UI.panel()
	panel.add_theme_stylebox_override("panel", UI.skin("panel_inlay", 8, 12))
	parent.add_child(panel)
	var box := UI.vbox(5)
	panel.add_child(box)
	_line(box, "REPORT_FOOD_TITLE", [], width, 18, UI.ACCENT)
	if int(report.population) > 0:
		_line(box, "REPORT_STOCK", [report.stock, report.stock_days], width)
		_line(box, "REPORT_PRODUCED", [report.produced_days, report.population], width)
	else:
		_line(box, "REPORT_NO_POPULATION", [report.stock], width)
	_line(box, "REPORT_BASIS", [], width, 14, Color(0.75, 0.8, 0.75))
	_line(box, "REPORT_RESILIENCE_TITLE", [], width, 18, UI.ACCENT)
	_line(box, "REPORT_SAVINGS", [report.water_demand_avoided, report.food_saved], width)
	_line(box, "REPORT_ACTIVE", [], width, 14, Color(0.75, 0.8, 0.75))
	if report.measures.is_empty():
		_line(box, "REPORT_NONE", [], width)
	for entry in report.measures:
		_line(box, entry[0], entry[1], width)

static func _line(parent: Node, key: String, args: Array, width: float, font_size := 16, color := UI.TEXT) -> void:
	var text := String(TranslationServer.translate(key))
	if key.begins_with("POL_") and key.ends_with("_DESC"):
		text = "• " + String(TranslationServer.translate(key.trim_suffix("_DESC"))) + ": " + text
	if not args.is_empty():
		text = text % args
	var label := UI.label(text, font_size, color)
	label.custom_minimum_size.x = width
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
