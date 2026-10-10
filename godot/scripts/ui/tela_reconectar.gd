class_name TelaReconectar
extends Control

const RESPIRO_BATIDAS := 5.0
const FUNDO_MIN := 0.58
const FUNDO_RESPIRO := 0.16
const FUNDO_RESPIRO_REDUZIDO := 0.07

var lugares: Array = []
var sala: Node = null
var batidas := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(dt: float) -> void:
	visible = not (is_instance_valid(sala) and bool(sala.get("congelada")))
	batidas += dt * maxf(Ritmo.bpm, 1.0) / 60.0
	queue_redraw()


func respiro() -> float:
	var f := fposmod(batidas / RESPIRO_BATIDAS, 1.0)
	var inspira := 1.0 / RESPIRO_BATIDAS
	return f / inspira if f < inspira else pow(1.0 - (f - inspira) / (1.0 - inspira), 2.0)


func pulso() -> float:
	return pow(1.0 - fposmod(batidas, 1.0), 3.0)


func _draw() -> void:
	if lugares.is_empty():
		return
	var l: int = int(lugares[0])
	var cor_lugar := Forja.cor_do_lugar(l)
	var cor_id := Tema.tom_para_a_borda(cor_lugar)
	var amplo := FUNDO_RESPIRO_REDUZIDO if Opcoes.reduzido() else FUNDO_RESPIRO
	var r_ := respiro()
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.FITA, FUNDO_MIN + amplo * (1.0 - r_)))
	var larg := 760.0
	var alt := 330.0
	var r := Rect2(Vector2((size.x - larg) * 0.5, (size.y - alt) * 0.5), Vector2(larg, alt))
	for k in 4:
		var a := (0.05 + 0.10 * r_) * (1.0 if not Opcoes.reduzido() else 0.6) * (1.0 - k * 0.22)
		Desenho.caixa(self, r.grow(18.0 + k * 22.0 * (0.6 + 0.4 * r_)), Color(cor_lugar, a), Tema.RAIO_QUADRO + 6 + k * 8)
	Desenho.moldura(self, r, Tema.CASCO, cor_id, 4, Tema.RAIO_QUADRO)
	var nomes: Array = []
	for x in lugares:
		nomes.append("P%d" % (int(x) + 1))
	var titulo := " · ".join(nomes)
	Desenho.texto(self, r.position + Vector2(48, 92), titulo, Tema.bungee(), Tema.T_TITULO, cor_id)
	var lado := 22.0
	var mascara: int = Forja.LEDS_DO_LUGAR[clampi(l, 0, 3)]
	var w := 5.0 * lado + 6.0 * lado * 0.5
	var pos_leds := Vector2(r.end.x - 48.0 - w, r.position.y + 58.0)
	var brilho := 0.35 + 0.65 * pulso() if not Opcoes.reduzido() else 0.6 + 0.4 * pulso()
	draw_rect(Rect2(pos_leds - Vector2(14, 14), Vector2(w + 28, lado + 28)), Color(cor_lugar, 0.25 * brilho))
	Desenho.leds(self, pos_leds, mascara, lado)
	Desenho.texto(self, r.position + Vector2(48, 182), "O controle saiu.", Tema.archivo(600), Tema.T_CORPO, Tema.ETIQUETA)
	Desenho.texto(self, r.position + Vector2(48, 246), "Religue o mesmo para voltar.", Tema.archivo(500), Tema.T_CORPO,
		Tema.ETIQUETA_SOMBRA)
