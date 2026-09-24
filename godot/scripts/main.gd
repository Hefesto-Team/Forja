extends Node3D
## 4-player local DualSense tech demo. USB 0x02 only.

const COLORS := [
	Color(0.36, 0.55, 0.94),
	Color(0.91, 0.36, 0.36),
	Color(0.30, 0.69, 0.48),
	Color(0.91, 0.54, 0.71),
]
const LANES := [-4.5, -1.5, 1.5, 4.5]
const STATIONS := [
	{ "id": "galeria", "name": "Galeria", "pos": Vector3(-4.2, 0, -5.2) },
	{ "id": "impacto", "name": "Impacto", "pos": Vector3(4.2, 0, -5.2) },
	{ "id": "giro", "name": "Viga", "pos": Vector3(0, 0, -5.5) },
	{ "id": "prova", "name": "A Prova", "pos": Vector3(0, 0, 0.2) },
]

var pads: Array[DualSensePad] = []
var players: Array[ForjaPlayer] = []
var mode := "hub"
var thesis := "O jogo envia USB 0x02 no DualSense do player index. O vizinho apagado é o aceite."
var message := "Ande até um portão. Espaço / X entra. 1 dispara P1 · 3 P3 toma da esquerda."
var near_station := ""
var time_in := 0.0
var bolts: Array = []
var shots: Array = []
var targets: Array = []
var hud: Label
var pad_hud: Label
## Sound and motion, found the way a game finds them (A-FORJA-VALIDA-O-SOM-01):
## the controller speaker by the name the game shows, the default microphone,
## and the IMU from report 0x01. None of them knows any daemon.
var alto_falante: AltoFalanteDoControle
var microfone: MicrofoneDoControle
var movimentos: Array[MovimentoDoControle] = []
var som_hud: Label
var _procura_em := 0.0
var _giro_base := 0.0


func _ready() -> void:
	randomize()
	_build_world()
	hud = $HUD/Title
	pad_hud = $HUD/Pads
	for i in 4:
		var p := DualSensePad.new()
		p.name = "Pad%d" % i
		p.player_index = i
		p.set_lightbar(COLORS[i])
		p.set_triggers(DualSensePad.Trigger.OFF, DualSensePad.Trigger.OFF)
		add_child(p)
		pads.append(p)
		var actor := ForjaPlayer.new()
		actor.name = "P%d" % (i + 1)
		actor.setup(i, p, COLORS[i])
		add_child(actor)
		players.append(actor)
	alto_falante = AltoFalanteDoControle.new()
	alto_falante.name = "AltoFalante"
	add_child(alto_falante)
	microfone = MicrofoneDoControle.new()
	microfone.name = "Microfone"
	add_child(microfone)
	for i in 4:
		var m := MovimentoDoControle.new()
		m.name = "Movimento%d" % i
		m.player_index = i
		add_child(m)
		movimentos.append(m)
	som_hud = Label.new()
	som_hud.name = "Som"
	som_hud.position = Vector2(24, 588)
	som_hud.add_theme_font_size_override("font_size", 14)
	som_hud.add_theme_color_override("font_color", Color(0.96, 0.86, 0.62))
	$HUD.add_child(som_hud)
	_rebind_joys()
	reset_hub()
	Input.joy_connection_changed.connect(_on_joy)
	_abrir_na_sala_pedida()


## `-- --sala=voz` opens the game straight in a room, the way a test sheet asks
## for it ("open the game on the Voice room for controller 2"). Unknown rooms
## are ignored: the hub is always a valid place to start.
func _abrir_na_sala_pedida() -> void:
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--sala="):
			continue
		var sala := arg.substr(7)
		if sala == "viga":
			sala = "giro"
		if sala in ["galeria", "impacto", "giro", "prova", "voz"]:
			start_mode(sala)


func _on_joy(_device: int, _connected: bool) -> void:
	_rebind_joys()
	## A controller that comes or goes changes the speaker list too.
	alto_falante.procurar_em_fundo()


## Sensors only run in the room that uses them: an open microphone lights the
## controller's mic LED for the whole match, and nobody knows why.
func _parar_os_sensores() -> void:
	microfone.desligar()
	for m in movimentos:
		m.desligar()


func _rebind_joys() -> void:
	var joys := Input.get_connected_joypads()
	for i in 4:
		pads[i].device = -1
		players[i].is_bot = i != 0
		if i < joys.size():
			pads[i].bind_joy(joys[i])
			players[i].is_bot = false
		pads[i].flush()


func _build_world() -> void:
	var floor := CSGBox3D.new()
	floor.size = Vector3(14.2, 0.2, 14.2)
	floor.position.y = -0.1
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.42, 0.36, 0.28)
	floor.material = fm
	add_child(floor)
	_wall(Vector3(0, 1.2, -7.1), Vector3(14.2, 2.6, 0.28))
	_wall(Vector3(0, 1.2, 7.1), Vector3(14.2, 2.6, 0.28))
	_wall(Vector3(-7.1, 1.2, 0), Vector3(0.28, 2.6, 14.2))
	_wall(Vector3(7.1, 1.2, 0), Vector3(0.28, 2.6, 14.2))
	for s in STATIONS:
		if s["id"] == "prova":
			continue
		_gate(s["pos"], s["name"])
	_try_kenney()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.06, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.28, 0.22, 0.18)
	env.fog_enabled = true
	env.fog_light_color = Color(0.12, 0.09, 0.07)
	env.fog_density = 0.018
	$Camera3D.environment = env


func _wall(pos: Vector3, size: Vector3) -> void:
	var w := CSGBox3D.new()
	w.size = size
	w.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.22, 0.18, 0.14)
	w.material = m
	add_child(w)


func _gate(pos: Vector3, label: String) -> void:
	var g := CSGBox3D.new()
	g.size = Vector3(1.6, 2.2, 0.35)
	g.position = pos + Vector3(0, 1.1, 0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.42, 0.22)
	m.emission_enabled = true
	m.emission = Color(0.7, 0.45, 0.12)
	m.emission_energy_multiplier = 0.4
	g.material = m
	add_child(g)
	var l := Label3D.new()
	l.text = label
	l.font_size = 42
	l.position = pos + Vector3(0, 2.4, 0.2)
	l.modulate = Color(0.96, 0.9, 0.78)
	add_child(l)


func _try_kenney() -> void:
	var paths := [
		["res://assets/kenney/barrel.glb", Vector3(-5.6, 0, 5.4)],
		["res://assets/kenney/barrel.glb", Vector3(5.4, 0, 5.6)],
		["res://assets/kenney/gate.glb", Vector3(-4.2, 0, -5.2)],
		["res://assets/kenney/gate.glb", Vector3(4.2, 0, -5.2)],
	]
	for p in paths:
		var res = load(p[0])
		if res is PackedScene:
			var n: Node3D = res.instantiate()
			n.position = p[1]
			add_child(n)


func reset_hub() -> void:
	_parar_os_sensores()
	mode = "hub"
	_clear_fx_nodes()
	message = "Ande até um portão. Espaço / X entra."
	thesis = "Quatro DualSense. Relatório USB 0x02 por player index — ou o vizinho acende."
	for i in 4:
		players[i].hp = 100
		players[i].position = Vector3((i - 1.5) * 1.4, 0, 4.3)
		players[i].rotation.y = PI
		players[i].visible = true
		pads[i].set_triggers(DualSensePad.Trigger.OFF, DualSensePad.Trigger.OFF)
		pads[i].set_lightbar(COLORS[i])
		pads[i].set_rumble(0, 0, 0.05)
		pads[i].flush()
	_aim_cam(Vector3(0, 9.2, 12.5), Vector3.ZERO)


func start_mode(id: String) -> void:
	_parar_os_sensores()
	mode = id
	time_in = 0.0
	_clear_fx_nodes()
	for i in 4:
		players[i].hp = 100
		players[i].cooldown = 0.4 * i
		players[i].visible = true
		pads[i].set_lightbar(COLORS[i])
		match id:
			"galeria", "impacto":
				players[i].position = Vector3(LANES[i], 0, 4.7)
				players[i].rotation.y = PI
			"giro":
				players[i].position = Vector3(LANES[i], 0, 0)
				players[i].rotation.y = -PI / 2.0
			"voz":
				players[i].position = Vector3((i - 1.5) * 1.4, 0, 2.0)
				players[i].rotation.y = PI
			_:
				players[i].position = Vector3(-4.2 if i < 2 else 4.2, 0, 3.3 if i % 2 == 0 else -3.3)
	match id:
		"galeria":
			message = "R2 / Espaço — cada lane é um DualSense. R2 = Vibration."
			thesis = "O R2 Vibration do P1 não pode endurecer o R2 do P3."
			_spawn_targets()
			for i in 4:
				pads[i].set_triggers(DualSensePad.Trigger.OFF, DualSensePad.Trigger.VIBRATION)
				pads[i].flush()
			_aim_cam(Vector3(0, 10, 11), Vector3(0, 0, -1))
		"impacto":
			message = "Desvie. Tiro da esquerda = motor L daquele pad."
			thesis = "Tiro vindo da esquerda vibra só o motor esquerdo daquele DualSense."
			_aim_cam(Vector3(0, 10, 11), Vector3(0, 0, -1))
		"giro":
			message = "Gire o controle — o boneco gira junto. Sem IMU: stick / A D, flick = 180."
			thesis = "IMU no DualSense do player. O yaw do P3 não vira o P1."
			_giro_base = -PI / 2.0
			for m in movimentos:
				m.ligar()
			_aim_cam(Vector3(0, 8, 8), Vector3(0, 0, 0))
		"voz":
			message = "Fale no controle — a barra sobe com a voz. O botão de mudo zera a barra."
			thesis = "O microfone padrão do sistema, como um jogo pede. Qualquer máscara."
			if not microfone.ligar():
				thesis = "sem entrada de áudio: o jogo nasceu sem audio/driver/enable_input"
			_aim_cam(Vector3(0, 9.2, 12.5), Vector3.ZERO)
		"prova":
			message = "2v2 · P1+P3 vs P2+P4. Lightbar cai com a vida."
			thesis = "Se aguentou as salas, aguenta um round. Zero vazamento."
			for i in 4:
				pads[i].set_triggers(DualSensePad.Trigger.FEEDBACK, DualSensePad.Trigger.WEAPON)
				pads[i].flush()
			_aim_cam(Vector3(0, 11, 12), Vector3.ZERO)


func _aim_cam(from: Vector3, to: Vector3) -> void:
	$Camera3D.position = from
	$Camera3D.look_at(to)


func _clear_fx_nodes() -> void:
	for b in bolts:
		if is_instance_valid(b.get("node")):
			b.node.queue_free()
	bolts.clear()
	for s in shots:
		if is_instance_valid(s.get("node")):
			s.node.queue_free()
	shots.clear()
	for t in targets:
		if is_instance_valid(t):
			t.queue_free()
	targets.clear()


func _spawn_targets() -> void:
	for i in 4:
		var n := CSGSphere3D.new()
		n.radius = 0.32
		n.position = Vector3(LANES[i], 0.7, -4.4)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.9, 0.75, 0.2)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.8, 0.2)
		n.material = m
		add_child(n)
		targets.append(n)


func _process(dt: float) -> void:
	var d := minf(dt, 0.1)
	time_in += d
	near_station = ""
	if mode == "hub":
		_tick_hub(d)
	elif mode == "galeria":
		_tick_galeria(d)
	elif mode == "impacto":
		_tick_impacto(d)
	elif mode == "giro":
		_tick_giro(d)
	elif mode == "voz":
		_tick_voz(d)
	else:
		_tick_prova(d)
	_tick_projectiles(d)
	_procura_em -= d
	if _procura_em <= 0.0:
		_procura_em = 3.0
		alto_falante.procurar_em_fundo()
	_update_hud()


func _tick_hub(dt: float) -> void:
	for i in 4:
		var bot := Vector2.ZERO
		if players[i].is_bot:
			bot = Vector2(sin(time_in + i), cos(time_in * 0.4 + i)) * 0.15
		players[i].tick(dt, mode, bot)
	var p0 := players[0]
	for s in STATIONS:
		if s["id"] == "prova":
			continue
		if p0.position.distance_to(s["pos"]) < 1.35:
			near_station = s["id"]
			message = "Espaço / X — entrar em %s" % s["name"]
	if near_station != "" and players[0].wants_fire():
		start_mode(near_station)
		players[0].cooldown = 0.4


func _tick_galeria(dt: float) -> void:
	for i in 4:
		var bot := Vector2.ZERO
		players[i].tick(dt, mode, bot)
		players[i].position.x = LANES[i]
		if players[i].wants_fire() or (players[i].is_bot and fmod(time_in + i, 1.6) < dt * 2.0):
			_fire(i)


func _tick_impacto(dt: float) -> void:
	for i in 4:
		var bot := Vector2(0, sin(time_in * 2.0 + i) * 0.4)
		players[i].tick(dt, mode, bot)
		players[i].position.x = LANES[i]
	if fmod(time_in, 1.35) < dt * 2.0:
		var slot := randi() % 4
		var from_left := (randi() % 2) == 0
		_spawn_bolt(slot, from_left)


func _tick_giro(dt: float) -> void:
	for i in 4:
		var mx := 0.0
		if i == 0:
			if Input.is_physical_key_pressed(KEY_A):
				mx -= 1.0
			if Input.is_physical_key_pressed(KEY_D):
				mx += 1.0
		if pads[i].device >= 0:
			mx += Input.get_joy_axis(pads[i].device, JOY_AXIS_RIGHT_X)
			mx += Input.get_joy_axis(pads[i].device, JOY_AXIS_LEFT_X) * 0.35
		if players[i].is_bot:
			mx += sin(time_in * 1.3 + i) * 0.25
		players[i].position.x = clampf(players[i].position.x + mx * 3.4 * dt, -6.2, 6.2)
		players[i].position.z = 0.0
		if movimentos[i].tem_imu:
			## The controller's own yaw turns THIS player only; the stick still
			## walks. Turning the pad 90 degrees turns the character 90.
			players[i].rotation.y = _giro_base + deg_to_rad(movimentos[i].yaw_acumulado)
			continue
		if absf(mx) > 0.92:
			players[i].rotation.y += PI
			pads[i].set_rumble(0, 180)
			pads[i].flush()
			thesis = "player index %d · USB 0x02 · flick 180 · vizinho intocado" % i
		elif absf(mx) > 0.55:
			pads[i].set_rumble(int(absf(mx) * 40.0), int(absf(mx) * 90.0), 0.12)
			pads[i].flush()


func _tick_voz(dt: float) -> void:
	for i in 4:
		players[i].tick(dt, "hub", Vector2.ZERO)
	if microfone.ligado:
		thesis = "microfone %s %d dB" % [MicrofoneDoControle.barra(microfone.ultimo_db), int(microfone.ultimo_db)]


func _tick_prova(dt: float) -> void:
	for i in 4:
		var bot := Vector2.ZERO
		if players[i].is_bot:
			var enemy := players[i ^ 1]
			bot = Vector2(enemy.position.x - players[i].position.x, enemy.position.z - players[i].position.z).normalized() * 0.6
		players[i].tick(dt, mode, bot)
		var k := clampf(players[i].hp / 100.0, 0.12, 1.0)
		pads[i].set_lightbar(COLORS[i] * k)
		if players[i].wants_fire() or (players[i].is_bot and fmod(time_in + i * 0.37, 1.1) < dt * 2.0):
			_fire(i)
		pads[i].flush()


func _fire(slot: int) -> void:
	var a := players[slot]
	if a.cooldown > 0.0 or a.hp <= 0.0:
		return
	a.cooldown = 0.22
	if mode == "galeria" and not a.is_bot:
		## The shot sounds on the shooter's own controller speaker, and only there.
		pads[slot].tocar_sfx(1300.0, 90)
	pads[slot].set_rumble(30, 170)
	pads[slot].set_triggers(DualSensePad.Trigger.OFF, DualSensePad.Trigger.VIBRATION)
	pads[slot].flush()
	thesis = "player index %d · USB 0x02 · R2 Vibration · motor R" % slot
	var n := CSGSphere3D.new()
	n.radius = 0.12
	n.position = a.position + Vector3(0, 0.7, 0) + Vector3(sin(a.rotation.y), 0, cos(a.rotation.y)) * -0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLORS[slot]
	mat.emission_enabled = true
	mat.emission = COLORS[slot]
	n.material = mat
	add_child(n)
	var dir := Vector3(sin(a.rotation.y), 0, cos(a.rotation.y)) * -14.0
	if mode == "galeria" or mode == "impacto":
		dir = Vector3(0, 0, -16)
		n.position = Vector3(a.position.x, 0.7, a.position.z - 0.5)
	shots.append({ "node": n, "vel": dir, "owner": slot, "ttl": 1.4 })


func _spawn_bolt(slot: int, from_left: bool) -> void:
	var n := CSGBox3D.new()
	n.size = Vector3(0.45, 0.18, 0.18)
	var z := players[slot].position.z
	n.position = Vector3(-6.4 if from_left else 6.4, 0.7, z)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.85, 0.2)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.8, 0.15)
	n.material = m
	add_child(n)
	var vx := 9.5 if from_left else -9.5
	bolts.append({ "node": n, "slot": slot, "from_left": from_left, "vel": Vector3(vx, 0, 0), "ttl": 2.0 })


func hit_from_left(slot: int) -> void:
	_spawn_bolt(slot, true)
	_apply_side_hit(slot, true)


func _apply_side_hit(slot: int, from_left: bool) -> void:
	players[slot].hp = maxf(0.0, players[slot].hp - 18.0)
	if from_left:
		pads[slot].set_rumble(240, 12)
	else:
		pads[slot].set_rumble(12, 240)
	pads[slot].set_lightbar(players[slot].hp_color(COLORS[slot]))
	pads[slot].flush()
	thesis = "player index %d · USB 0x02 · motor %s = 240 · vizinho intocado no relatório" % [slot, "L" if from_left else "R"]


func _tick_projectiles(dt: float) -> void:
	var keep_b: Array = []
	for b in bolts:
		if not is_instance_valid(b.node):
			continue
		b.node.position += b.vel * dt
		b.ttl -= dt
		var slot: int = b.slot
		if players[slot].position.distance_to(b.node.position) < 0.7:
			_apply_side_hit(slot, b.from_left)
			b.node.queue_free()
			continue
		if b.ttl > 0.0:
			keep_b.append(b)
		else:
			b.node.queue_free()
	bolts = keep_b
	var keep_s: Array = []
	for s in shots:
		if not is_instance_valid(s.node):
			continue
		s.node.position += s.vel * dt
		s.ttl -= dt
		var dead := false
		if mode == "prova":
			for i in 4:
				if i == s.owner or players[i].hp <= 0.0:
					continue
				if players[i].position.distance_to(s.node.position) < 0.7:
					players[i].hp = maxf(0.0, players[i].hp - 22.0)
					pads[i].set_rumble(160, 40)
					pads[i].set_lightbar(players[i].hp_color(COLORS[i]))
					pads[i].flush()
					dead = true
					break
		if mode == "galeria":
			for t in targets:
				if is_instance_valid(t) and t.position.distance_to(s.node.position) < 0.55:
					t.position.y += 0.05
					dead = true
		if dead or s.ttl <= 0.0:
			s.node.queue_free()
		else:
			keep_s.append(s)
	shots = keep_s


func _update_hud() -> void:
	var njoy := Input.get_connected_joypads().size()
	var send := pads[0]._send_bin() if pads.size() else ""
	var send_ok := "forja-send ok" if send != "" else "forja-send ausente — só rumble SDL"
	hud.text = "FORJA  ·  %s  ·  %d DualSense no SDL  ·  %s\n%s\n%s" % [
		mode, njoy, send_ok, message, thesis,
	]
	var lines: PackedStringArray = PackedStringArray()
	for i in 4:
		var p := pads[i]
		var tag := "bot"
		if not players[i].is_bot:
			tag = "joy %d" % p.device
		var mark := "*" if (p.rumble_l > 8 or p.rumble_r > 8) else " "
		var linha := "P%d %s  L=%3d R=%3d  R2=%s  hp=%d %s" % [
			i + 1, tag, p.rumble_l, p.rumble_r, p._mode_name(p.r2), int(players[i].hp), mark,
		]
		if mode == "giro":
			linha += "  " + movimentos[i].linha_da_hud()
		lines.append(linha)
	pad_hud.text = "\n".join(lines)
	som_hud.text = alto_falante.linha_da_hud()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			reset_hub()
		KEY_1:
			_fire(0)
		KEY_2:
			_fire(1)
		KEY_3:
			hit_from_left(2)
		KEY_4:
			hit_from_left(1)
		KEY_F1, KEY_G:
			start_mode("galeria")
		KEY_F2, KEY_I:
			start_mode("impacto")
		KEY_F3, KEY_V:
			start_mode("giro")
		KEY_F4, KEY_P:
			start_mode("prova")
		KEY_F5:
			start_mode("voz")
		KEY_H:
			reset_hub()
