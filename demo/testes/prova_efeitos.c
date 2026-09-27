/* O payload do SDL_SendGamepadEffect: cada bloco liga só o seu bit, carrega a
 * sombra inteira, e nunca liga o que o contrato proíbe. */
#include "prova.h"

#include "forja_dualsense.h"

static const uint8_t *b(const ForjaDs5Effect *fx) { return (const uint8_t *)fx; }

void provas_efeitos(void) {
  ForjaSombra s;
  ForjaDs5Effect fx;
  forja_sombra_zerar(&s);
  espera(s.gatilho_dir[0] == FORJA_HID_TRIGGER_OFF && s.gatilho_esq[0] == FORJA_HID_TRIGGER_OFF,
         "a sombra nasce com os dois gatilhos em Off");
  espera(s.audio == FORJA_AUDIO_BASE, "e com a base segura do áudio (0x0D)");

  /* Um rumble em curso: o SDL mandou 200/40. O payload do gatilho carrega os
   * motores, senão calaria a vibração (os bytes agem sem os bits). */
  s.motor_esq = 200;
  s.motor_dir = 40;
  ForjaTrigger arma = {FORJA_TRIGGER_WEAPON, 3, 6, 8};
  forja_fx_gatilho(&fx, &s, 1, arma);
  espera(b(&fx)[0] == FORJA_FX_R2, "gatilho direito: só o bit 0x04");
  espera(b(&fx)[1] == 0, "nada no valid_flag1");
  espera(b(&fx)[3] == 200 && b(&fx)[2] == 40, "carrega os motores do rumble em curso");
  espera(b(&fx)[10] == FORJA_HID_TRIGGER_WEAPON, "Weapon 0x25 no common[10]");
  espera(b(&fx)[21] == FORJA_HID_TRIGGER_OFF, "o esquerdo segue Off, sem o bit dele");
  espera(b(&fx)[38] == 0, "valid_flag2 nunca é nosso");

  ForjaTrigger res = {FORJA_TRIGGER_FEEDBACK, 2, 8, 0};
  forja_fx_gatilho(&fx, &s, 0, res);
  espera(b(&fx)[0] == FORJA_FX_L2, "gatilho esquerdo: só o bit 0x08");
  espera(b(&fx)[21] == FORJA_HID_TRIGGER_FEEDBACK, "Feedback 0x21 no common[21]");
  espera(b(&fx)[10] == FORJA_HID_TRIGGER_WEAPON, "o direito continua na sombra (Weapon)");

  ForjaTrigger vib = {FORJA_TRIGGER_VIBRATION, 0, 8, 30};
  ForjaTrigger off = {FORJA_TRIGGER_OFF, 0, 0, 0};
  forja_fx_gatilhos(&fx, &s, off, vib);
  espera(b(&fx)[0] == (FORJA_FX_R2 | FORJA_FX_L2), "os dois gatilhos de uma vez");
  espera(b(&fx)[10] == FORJA_HID_TRIGGER_VIBRATION && b(&fx)[19] == 30,
         "Vibration 0x26 com a frequência no byte 9 do bloco");

  forja_fx_led_mic(&fx, &s, 2);
  espera(b(&fx)[1] == FORJA_FX_MIC_LED && b(&fx)[0] == 0, "LED do mic: só o bit dele");
  espera(b(&fx)[8] == 2, "piscando = 2");
  forja_fx_led_mic(&fx, &s, 9);
  espera(b(&fx)[8] == 0, "fora da faixa 0..3 vira apagado (o firmware valida)");

  forja_fx_leds_jogador(&fx, &s, forja_leds_do_jogador(3), 1);
  espera(b(&fx)[1] == FORJA_FX_PLAYER_LED, "LEDs de jogador: só o bit 0x10");
  espera(b(&fx)[43] == (0x1B | 0x20), "P4 = xx-xx, sem fade");
  espera(forja_leds_do_jogador(0) == 0x04 && forja_leds_do_jogador(1) == 0x0A &&
             forja_leds_do_jogador(2) == 0x15 && forja_leds_do_jogador(4) == 0x1F,
         "as figuras canônicas do driver");

  forja_fx_alto_falante(&fx, &s, FORJA_VOL_FALANTE_PADRAO, FORJA_ROTA_FALANTE, FORJA_PREAMP_PADRAO);
  espera(b(&fx)[0] == (FORJA_FX_SPEAKER_VOL | FORJA_FX_AUDIO_CONTROL), "volume e rota");
  espera(b(&fx)[1] == FORJA_FX_PREAMP, "e o pré-amp pelo bit 0x80 do valid_flag1");
  espera(b(&fx)[5] == 0x64, "volume 0x64, o do driver");
  espera(b(&fx)[7] == (FORJA_AUDIO_BASE | (3 << 4)), "rota 3 sobre a base 0x0D");
  espera(b(&fx)[37] == 0x02, "pré-amp 2 no common[37]");

  forja_fx_volume_mic(&fx, &s, 0xFF);
  espera(b(&fx)[6] == 0x40, "o microfone tem teto 0x40");

  /* O que o contrato proíbe não sai nem se alguém pedir. */
  forja_fx_da_sombra(&fx, &s, 0xFF, 0xFF);
  espera((b(&fx)[0] & (FORJA_FX_RUMBLE | FORJA_FX_HAPTICS_SELECT)) == 0,
         "HAPTICS_SELECT e rumble nunca saem do payload (a háptica por áudio vive)");
  espera((b(&fx)[1] & FORJA_FX_POWER_SAVE) == 0, "o mudo nunca é nosso");
  espera(b(&fx)[9] == 0, "power_save zerado: HapticMute e HapticPowerSave desligados");
  espera(sizeof(ForjaDs5Effect) == 47, "o payload tem 47 bytes");
}
