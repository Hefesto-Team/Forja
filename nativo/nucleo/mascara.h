/* A máscara de endereço: nenhum MAC sai deste jogo inteiro.
 *
 * O jogo não LÊ endereço de hardware (o contrato proíbe `uniq`/MAC), mas um
 * texto que vem de fora pode trazer um: o nome de um nó de som do BlueZ
 * (`bluez_output.AA_BB_CC_DD_EE_FF.1`), o `iSerial` USB do DualSense (o MAC em
 * 12 hex), o "serial" que o SDL monta a partir do report 0x09. Todo texto que
 * vai para a tela, para o registro ou para o relatório passa por aqui.
 *
 * A regra é a da casa do Hefesto: zerar os octetos 4 e 5 — `14:3a:9a:00:00:ab`.
 * Fica o fabricante (os três primeiros) e o último, que bastam para diferenciar
 * dois controles numa mesa, e some o que identificaria o aparelho de alguém.
 */
#ifndef DEMO_MASCARA_H
#define DEMO_MASCARA_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Mascara no lugar. Reconhece seis pares hex separados por ':', '-' ou '_'
 * (o mesmo separador nos cinco lugares) e doze hex seguidos com pelo menos uma
 * letra a-f (uma data de doze dígitos não é MAC). Devolve quantos mascarou. */
int mascara_mac(char *texto);

/* Copia `de` para `para` (até `tam`, sempre terminado) e mascara a cópia. */
int mascara_mac_copia(const char *de, char *para, size_t tam);

#ifdef __cplusplus
}
#endif

#endif
