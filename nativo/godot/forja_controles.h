/* ForjaControles: o nó que o jogo 3D põe na árvore para falar com os
 * DualSense. Um só por jogo.
 *
 * Cada quadro ele bombeia os eventos do SDL3; o GDScript lê a entrada por
 * lugar (P1..P4 = 0..3, o player index) e manda as saídas pelo mesmo lugar:
 * vibração, lightbar, LEDs de jogador, LED do microfone, os quatro modos de
 * gatilho e o volume do alto-falante — tudo pelo payload USB 0x02 que o SDL
 * monta, como o contrato pede. O relatório da sessão (JSON e texto), a linha
 * do tempo e o registro também passam por aqui.
 */
#ifndef FORJA_GODOT_CONTROLES_H
#define FORJA_GODOT_CONTROLES_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class ForjaControles : public Node {
  GDCLASS(ForjaControles, Node)

  bool aberto_ = false;

protected:
  static void _bind_methods();

public:
  ForjaControles() = default;
  ~ForjaControles() override;

  void _process(double delta) override;
  void _exit_tree() override;

  /* a sessão */
  bool abrir(const String &pasta, int simular, bool robo, int64_t semente);
  void fechar();
  bool simular(int n);
  bool aberto() const { return aberto_; }
  String versao() const;
  String pasta_relatorios() const;
  String sessao() const;
  int64_t semente() const;
  bool simulado() const;
  bool contrato_estrito() const;
  int aviso_seq() const;
  String aviso() const;
  void intensidade(float v);

  /* os controles e os lugares */
  int conectados() const;
  int jogadores() const;
  Array pads() const;
  Dictionary pad(int indice) const;
  int pad_do_lugar(int lugar) const;
  Dictionary lugar(int lugar) const;
  int entrar(int indice);
  void sair(int lugar);

  /* a entrada */
  bool pad_apertou(int indice, int botao) const;
  bool pad_segura(int indice, int botao) const;
  bool apertou(int lugar, int botao) const;
  bool soltou(int lugar, int botao) const;
  bool segura(int lugar, int botao) const;
  float eixo(int lugar, int eixo) const;
  Vector3 giro(int lugar) const;
  Vector3 acel(int lugar) const;
  Vector3 dedo(int lugar, int i) const;
  Vector2 postura(int lugar) const;
  float giro_hz(int lugar) const;
  int status_cru(int lugar) const;

  /* as saídas */
  bool vibrar(int lugar, float forte, float fraco, int ms);
  bool luz(int lugar, const Color &c);
  bool luz_do_lugar(int lugar);
  bool gatilho(int lugar, int lado, int modo, int a, int b, int c);
  bool gatilhos_off(int lugar);
  bool led_mic(int lugar, int modo);
  bool leds_jogador(int lugar, int mascara);
  bool leds_do_lugar(int lugar);
  bool alto_falante(int lugar, int volume, int rota, int preamp);
  void silencio(int lugar);
  void silencio_todos();
  PackedStringArray saidas(int lugar) const;
  Dictionary estado_saida(int lugar) const;
  Color cor_do_lugar(int lugar) const;

  /* o relatório */
  Array salas() const;
  Array features() const;
  void nota(const String &texto);
  void veredito(int lugar, int feature, int resultado, int nivel, const String &pedido, const String &medido,
                const String &obs);
  Dictionary ultimo_veredito(int lugar, int feature) const;
  Dictionary controle_do_relatorio(int lugar) const;
  bool gravar_relatorio();
  void registrar(const String &linha);
  void evento(const String &tipo, int jogador, const Dictionary &campos);
  PackedStringArray registro_recente(int n) const;

  /* o simulador e o robô */
  void em_sala(bool v);
  String defeitos(const String &lista);
  void simulador_selecionar(int sim);
  void simulador_botao(int sim, int botao, bool baixo);
  void simulador_eixo(int sim, int eixo, float v);
  void simulador_giro(int sim, const Vector3 &g);
  void simulador_dedo(int sim, int dedo, bool baixo, float x, float y);
  void robo_apertar(int indice, int botao, float s);
  void robo_eixo(int indice, int eixo, float v, float s);
  void robo_girar(int indice, const Vector3 &g, float s);
  void robo_sacudir(int indice, float g, float s);
  void robo_tocar(int indice, int dedo, float x, float y, float s);
  Dictionary percepcao(int indice) const;

  /* as medidas das salas de entrada (medidas.h), amostradas a cada quadro */
  bool med_comecar(int lugar, int64_t botoes);
  void med_parar(int lugar);
  void med_retomar(int lugar);
  void med_pedido(int lugar, int botao);
  void med_repouso(int lugar, bool sim);
  void med_pedir(int lugar, const String &o_que);
  void med_faixa(int lugar, int lado);
  void med_tracou(int lugar);
  void med_martelada(int lugar);
  Dictionary med_estado(int lugar) const;
  Dictionary med_veredito(int lugar, const String &chave, int nivel);

  /* A Prova: a carga da partida (medidas.h) e o veredito de tudo junto */
  bool carga_comecar(int lugar);
  void carga_parar(int lugar);
  void carga_saida(int lugar, bool ok);
  void carga_placar(int lugar, int tiros, int acertos, int derrubadas);
  Dictionary carga_estado(int lugar) const;
  Dictionary carga_veredito(int lugar, const Dictionary &leds, const Dictionary &cor, bool mexeu);

  /* as provas às cegas das salas de saída (cegas.h): os planos pelo sorteio
   * do núcleo, e o veredito das respostas guardadas pela sala */
  Array cega_plano_tiros(const PackedInt32Array &slots, int por_lado, int64_t semente) const;
  PackedInt32Array cega_plano_armas(int vezes, int64_t semente) const;
  PackedInt32Array cega_plano_fontes(const PackedInt32Array &fontes, const PackedInt32Array &vezes, int64_t semente) const;
  bool cega_decidida(const String &tipo, const Dictionary &cega) const;
  Dictionary cega_veredito(int lugar, const String &chave, const Dictionary &dados);

  /* o som de cada controle (som/som_controle.h): papel 0 alto-falante, 1
   * háptica, 2 microfone; os sons pelo nome (som/sons_salas.h) */
  void som_preparar(int papel);
  void som_encerrar();
  bool som_preparado() const;
  bool som_tem(int lugar, int papel) const;
  bool som_estereo(int lugar, int papel) const;
  String som_nome(int lugar, int papel) const;
  String som_como(int lugar, int papel) const;
  String som_plataforma() const;
  void som_trocar(int lugar, int papel, int direcao);
  int som_falante(int lugar, const String &som, float ganho);
  int som_haptica(int lugar, const String &esq, const String &dir, float ganho);
  void som_parar(int lugar);
  Dictionary som_mic(int lugar) const;
  Dictionary som_virtual(int lugar) const;
  void robo_falar(int indice, float nivel, float s);
  void simulador_falar(int sim, float nivel);
  bool simulador_cabo(int sim, bool ligado);
  bool som_registrar(const String &nome, const PackedByteArray &pcm16, int taxa);
  int chao_do_envelope(const PackedFloat32Array &env) const;
  Dictionary mic_veredito(int lugar, const String &chave, const Dictionary &dados);

  /* a bancada dos experimentos (experimental/): a escuta crua do microfone,
   * a análise (analise.h), o report cru e o resultado de cada medida */
  bool som_escutar(int lugar, float segundos);
  PackedFloat32Array som_escuta(int lugar) const;
  void som_escuta_parar(int lugar);
  int exp_ataque(const PackedFloat32Array &a, float vezes, float minimo) const;
  float exp_rms_db(const PackedFloat32Array &a, int ini, int n) const;
  float exp_mediana(const PackedFloat32Array &v) const;
  Dictionary exp_diagonal(const PackedFloat32Array &niveis, int n) const;
  PackedByteArray relatorio_cru(int lugar) const;
  void experimento(int lugar, const String &chave, const String &o, int resultado, const String &texto);

  /* os sons da forja, sintetizados (som/sintese.h): mono, 48 kHz, float */
  PackedFloat32Array sintetizar(const String &tipo, const Dictionary &p) const;
  /* o mesmo som em PCM de 16 bits (o que a AudioStreamWAV do Godot toca) */
  PackedByteArray sintetizar_pcm16(const String &tipo, const Dictionary &p) const;

private:
  void med_quadro();
  void med_zerar_tudo();
};

} // namespace godot

#endif
