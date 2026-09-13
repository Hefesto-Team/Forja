class_name DualSensePad
extends Node
## One DualSense, addressed by player index (0..3).
## Packs USB report 0x02 as SDL/Sony do. Never packs 0x31.
## Never mentions Hefesto, MAC, or IPC.

const USB_REPORT_ID := 0x02
const PLAYER_LED := [0x04, 0x0A, 0x15, 0x1B]
const HID_OFF := 0x05
const HID_FEEDBACK := 0x21
const HID_WEAPON := 0x25
const HID_VIBRATION := 0x26

enum Trigger { OFF, FEEDBACK, WEAPON, VIBRATION }

@export var player_index: int = 0
var device: int = -1
var last_report: PackedByteArray = PackedByteArray()

var rumble_l: int = 0
var rumble_r: int = 0
var l2: int = Trigger.OFF
var r2: int = Trigger.OFF
var lightbar := Color(0.36, 0.55, 0.94)
var mic_led: int = 0
var rumble_ttl: float = 0.0
var _last_key := ""
var _send_bin_cache := ""


func bind_joy(joy_id: int) -> void:
	device = joy_id


func set_rumble(left: int, right: int, ttl := 0.22) -> void:
	rumble_l = clampi(left, 0, 255)
	rumble_r = clampi(right, 0, 255)
	rumble_ttl = ttl


func set_triggers(left_mode: int, right_mode: int) -> void:
	l2 = left_mode
	r2 = right_mode


func set_lightbar(c: Color) -> void:
	lightbar = c


func _process(dt: float) -> void:
	if rumble_ttl <= 0.0:
		return
	rumble_ttl -= dt
	if rumble_ttl <= 0.0:
		rumble_l = 0
		rumble_r = 0
		flush()


func pack_trigger(mode: int, a := 0, b := 0, c := 0) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(11)
	match mode:
		Trigger.FEEDBACK:
			var pos := a if a <= 9 else 2
			var strg := b if b > 0 else 6
			if strg > 8:
				strg = 8
			return _zones(HID_FEEDBACK, pos, 9, strg, 0)
		Trigger.WEAPON:
			var start := a if a >= 2 else 2
			var endp := b if b > start else 6
			var strg := c if c > 0 else 8
			return _weapon(start, endp, strg)
		Trigger.VIBRATION:
			var pos := a if a <= 9 else 0
			var amp := b if b > 0 else 7
			var freq := c if c > 0 else 32
			return _zones(HID_VIBRATION, pos, 9, amp, freq)
		_:
			out[0] = HID_OFF
	return out


func _force3(strength: int) -> int:
	var s := clampi(strength, 1, 8)
	return (s - 1) & 0x07


func _zones(mode: int, from_pos: int, to_pos: int, strength: int, freq: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(11)
	var active := 0
	var forces := 0
	var fv := _force3(strength)
	for i in range(from_pos, to_pos + 1):
		active |= 1 << i
		forces |= fv << (3 * i)
	out[0] = mode
	out[1] = active & 0xff
	out[2] = (active >> 8) & 0xff
	out[3] = forces & 0xff
	out[4] = (forces >> 8) & 0xff
	out[5] = (forces >> 16) & 0xff
	out[6] = (forces >> 24) & 0xff
	out[9] = freq
	return out


func _weapon(start: int, endp: int, strength: int) -> PackedByteArray:
	start = clampi(start, 2, 7)
	endp = clampi(maxi(start + 1, endp), 3, 8)
	var out := PackedByteArray()
	out.resize(11)
	var active := (1 << start) | (1 << endp)
	var forces := _force3(strength) << (3 * endp)
	out[0] = HID_WEAPON
	out[1] = active & 0xff
	out[2] = (active >> 8) & 0xff
	out[3] = forces & 0xff
	out[4] = (forces >> 8) & 0xff
	out[5] = (forces >> 16) & 0xff
	out[6] = (forces >> 24) & 0xff
	return out


func pack_usb_report() -> PackedByteArray:
	var fx := PackedByteArray()
	fx.resize(47)
	fx[0] = 0x01 | 0x04 | 0x08 ## rumble + R2 + L2
	fx[1] = 0x04 | 0x10 | 0x01 ## lightbar + player LED + mic LED
	fx[2] = rumble_r
	fx[3] = rumble_l
	var rt := pack_trigger(r2)
	var lt := pack_trigger(l2)
	for i in 11:
		fx[10 + i] = rt[i]
		fx[21 + i] = lt[i]
	fx[8] = mic_led
	fx[38] = 0x02
	fx[41] = 0x02
	fx[43] = PLAYER_LED[clampi(player_index, 0, 3)] | 0x20
	fx[44] = int(lightbar.r * 255.0)
	fx[45] = int(lightbar.g * 255.0)
	fx[46] = int(lightbar.b * 255.0)
	var report := PackedByteArray()
	report.resize(64)
	report[0] = USB_REPORT_ID
	for i in 47:
		report[1 + i] = fx[i]
	last_report = report
	return report


func _mode_name(mode: int) -> String:
	match mode:
		Trigger.FEEDBACK:
			return "feedback"
		Trigger.WEAPON:
			return "weapon"
		Trigger.VIBRATION:
			return "vibration"
		_:
			return "off"


func _send_bin() -> String:
	if _send_bin_cache != "" and FileAccess.file_exists(_send_bin_cache):
		return _send_bin_cache
	var root := ProjectSettings.globalize_path("res://")
	var candidates := [
		root.path_join("../bin/forja-send").simplify_path(),
		root.path_join("../../bin/forja-send").simplify_path(),
		OS.get_executable_path().get_base_dir().path_join("forja-send"),
		OS.get_executable_path().get_base_dir().path_join("../bin/forja-send"),
	]
	for c in candidates:
		if FileAccess.file_exists(c):
			_send_bin_cache = c
			return c
	return ""


func flush() -> void:
	var report := pack_usb_report()
	assert(report[0] == USB_REPORT_ID)
	assert(report[0] != 0x31)
	var key := "%d:%d:%d:%d:%d:%d:%d" % [
		rumble_l, rumble_r, l2, r2,
		int(lightbar.r * 255.0), int(lightbar.g * 255.0), int(lightbar.b * 255.0),
	]
	if key == _last_key:
		return
	_last_key = key
	if device >= 0:
		var weak := rumble_r / 255.0
		var strong := rumble_l / 255.0
		Input.start_joy_vibration(device, weak, strong, 0.18)
	if Engine.has_singleton("Steam"):
		_steam_flush()
	_hidraw_flush()


func _hidraw_flush() -> void:
	var bin := _send_bin()
	if bin == "":
		return
	var args := PackedStringArray([
		"--player", str(player_index),
		"--left", str(rumble_l),
		"--right", str(rumble_r),
		"--r2", _mode_name(r2),
		"--l2", _mode_name(l2),
		"--lightbar",
		str(int(lightbar.r * 255.0)),
		str(int(lightbar.g * 255.0)),
		str(int(lightbar.b * 255.0)),
		"--quiet",
	])
	OS.create_process(bin, args)


func _steam_flush() -> void:
	var steam := Engine.get_singleton("Steam")
	if steam == null:
		return
	if not steam.has_method("triggerVibration"):
		return
	## Handles come from Steam.getConnectedControllers(); map by player_index
	## in the game, never by MAC.
