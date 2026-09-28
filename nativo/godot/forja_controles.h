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
};

} // namespace godot

#endif
