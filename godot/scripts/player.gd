class_name ForjaPlayer
extends Node3D
## One local operator. Keyboard always drives slot 0.
## DualSense left stick drives the bound joy device.

const SPEED := 5.2
const BOUND := 6.4

var slot: int = 0
var is_bot: bool = true
var hp: float = 100.0
var yaw: float = PI
var cooldown: float = 0.0
var pad: DualSensePad
var moving: bool = false
var score: int = 0
var body: MeshInstance3D


func setup(p_slot: int, p_pad: DualSensePad, color: Color) -> void:
	slot = p_slot
	pad = p_pad
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.28
	mesh.height = 1.15
	body = MeshInstance3D.new()
	body.mesh = mesh
	body.position.y = 0.58
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.35
	body.material_override = mat
	add_child(body)
	var shadow := CSGCylinder3D.new()
	shadow.radius = 0.32
	shadow.height = 0.04
	shadow.position.y = 0.02
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0, 0, 0, 0.35)
	shadow.material = sm
	add_child(shadow)


func hp_color(base: Color) -> Color:
	var k := clampf(hp / 100.0, 0.12, 1.0)
	return base.lerp(Color(0.07, 0.06, 0.05), 1.0 - k)


func clamp_pos(mode: String) -> void:
	if mode == "giro":
		position.x = clampf(position.x, -BOUND, BOUND)
		position.z = clampf(position.z, -0.28, 0.28)
	else:
		position.x = clampf(position.x, -BOUND, BOUND)
		position.z = clampf(position.z, -BOUND, BOUND)


func read_move() -> Vector2:
	var mx := 0.0
	var my := 0.0
	if slot == 0:
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			mx -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			mx += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			my -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			my += 1.0
	if pad and pad.device >= 0:
		mx += Input.get_joy_axis(pad.device, JOY_AXIS_LEFT_X)
		my += Input.get_joy_axis(pad.device, JOY_AXIS_LEFT_Y)
	var mag := Vector2(mx, my).length()
	if mag > 1.0:
		mx /= mag
		my /= mag
	return Vector2(mx, my)


func wants_fire() -> bool:
	if cooldown > 0.0:
		return false
	if slot == 0 and (Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_ENTER)):
		return true
	if pad and pad.device >= 0:
		if Input.get_joy_axis(pad.device, JOY_AXIS_TRIGGER_RIGHT) > 0.55:
			return true
		if Input.is_joy_button_pressed(pad.device, JOY_BUTTON_X):
			return true
	return false


func tick(dt: float, mode: String, bot_dir: Vector2) -> void:
	if cooldown > 0.0:
		cooldown -= dt
	var mv := read_move()
	if is_bot and mv.length() < 0.12:
		mv = bot_dir
	position.x += mv.x * SPEED * dt
	position.z += mv.y * SPEED * dt
	clamp_pos(mode)
	moving = mv.length() > 0.18
	if moving:
		yaw = atan2(-mv.x, -mv.y)
		rotation.y = yaw
	if hp <= 0.0:
		visible = false
	else:
		visible = true
