class_name Falas
extends RefCounted

const ERRO := 0
const BOM := 1
const OTIMO := 2
const PERFEITO := 3
const INTERVALO_S := 20.0
const DURACAO_S := 2.0
const ARRASTA_S := 0.060
const CORRE_S := -0.040
const TODOS_S := 1.5
const SEGUIDOS := 3
const COMBO_DA_EQUIPE := 15
const VOLTOU := 5
const DO_EVENTO := {
	"combo_equipe": ["Frequência travada!", "Ninguém nos apaga!"],
	"arrastando": ["Segura menos!", "Vai com o baixo!"],
	"correndo": ["Calma, espera o bumbo!"],
	"todos_erraram": ["Tá tudo desafinado!"],
	"voltou": ["De novo, do começo."],
	"ajudou": ["Deixa comigo o refrão!"],
	"vencedor": ["Faltou ginga pra eles.", "A forja canta de novo."],
}


static func do_julgamento(j: int, no_treino := false, desvio_s := 0.0) -> String:
	if j <= ERRO or j > PERFEITO:
		return ""
	if no_treino and j != PERFEITO and desvio_s != 0.0:
		return "Cedo" if desvio_s < 0.0 else "Tarde"
	return ["", "Quase", "Afinado", "Ressonância!"][j]
