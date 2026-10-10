class_name Falas
extends RefCounted
## As falas curtas do cavaleiro e a palavra do visor (07, as falas): uma frase por evento, rara, ligada ao que
## acabou de acontecer. Estático: a `SalaJogo` sorteia pela semente e o `Visor` desenha.

## A numeração do julgamento do Ritmo (13): ERRO 0, BOM 1, OTIMO 2, PERFEITO 3.
const ERRO := 0
const BOM := 1
const OTIMO := 2
const PERFEITO := 3
const INTERVALO_S := 20.0   ## uma fala a cada 20 s por lugar (07)
const DURACAO_S := 2.0      ## quanto a fala fica na tela; nunca duas ao mesmo tempo
const ARRASTA_S := 0.060    ## três toques seguidos acima de +60 ms: «arrastando»
const CORRE_S := -0.040     ## três abaixo de −40 ms: «correndo»
const TODOS_S := 1.5        ## todos erraram dentro de 1,5 s
const SEGUIDOS := 3         ## quantos toques do mesmo lado puxam a fala do lado
const COMBO_DA_EQUIPE := 15 ## acertos seguidos da equipe que puxam «combo_equipe»
const VOLTOU := 5           ## erros seguidos antes do acerto que puxa «voltou»
const DO_EVENTO := {
	"combo_equipe": ["Frequência travada!", "Ninguém nos apaga!"],
	"arrastando": ["Segura menos!", "Vai com o baixo!"],
	"correndo": ["Calma, espera o bumbo!"],
	"todos_erraram": ["Tá tudo desafinado!"],
	"voltou": ["De novo, do começo."],
	"ajudou": ["Deixa comigo o refrão!"],
	"vencedor": ["Faltou ginga pra eles.", "A forja canta de novo."],
}


## A palavra do visor. No treino, o que não é perfeito diz o lado:
## «Cedo» (desvio < 0) ou «Tarde» (desvio > 0); desvio 0 fica com a palavra do julgamento.
static func do_julgamento(j: int, no_treino := false, desvio_s := 0.0) -> String:
	if j <= ERRO or j > PERFEITO:
		return ""
	if no_treino and j != PERFEITO and desvio_s != 0.0:
		return "Cedo" if desvio_s < 0.0 else "Tarde"
	return ["", "Quase", "Afinado", "Ressonância!"][j]
