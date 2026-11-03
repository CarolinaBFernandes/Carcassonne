# res://scripts/view/ui/user_settings.gd
class_name UserSettings
extends RefCounted

const PATH := "user://settings.cfg"

static var master_volume := 0.8     # 0.0 a 1.0
static var fullscreen := false


static func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		master_volume = clampf(float(cfg.get_value("audio", "master", master_volume)), 0.0, 1.0)
		fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	apply()


static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)


static func apply() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))
		AudioServer.set_bus_mute(bus, master_volume <= 0.001)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
				else DisplayServer.WINDOW_MODE_WINDOWED)
