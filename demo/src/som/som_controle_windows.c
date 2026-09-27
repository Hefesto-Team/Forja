/* O som de cada controle, no Windows — e no .exe sob Proton.
 *
 * O caminho dos jogos que casam o áudio pelo container (ValveSoftware/Proton
 * #5900 cita Ghostwire: Tokyo e Deathloop): o HID do controle tem um
 * ContainerId (o CfgMgr32 lê do nó do dispositivo), cada endpoint de áudio
 * tem o dele (o WASAPI lê do repositório de propriedades), e o endpoint do
 * MESMO container é o do controle. Sob Proton, o Wine tira os dois do mesmo
 * pai USB no Linux — o do HID pelo winebus; o do endpoint pelo mmdevapi, a
 * partir do sysfs.path que o winepulse entrega (wine!359 e wine!7238) —, e é
 * por isso que o caminho funciona lá também, no cabo. Depende da versão do
 * Proton: com o winepipewire no lugar do winepulse, o container pode não vir
 * (proton-cachyos#296); aí sobra o caminho pelo nome.
 *
 * O SDL mostra o endpoint pelo FriendlyName; é por ele que o que o WASAPI
 * disse volta para a lista do jogo. */
#include "som_controle.h"

#if defined(_WIN32)

#define COBJMACROS
#define WIN32_LEAN_AND_MEAN
#include <initguid.h>
#include <windows.h>

/* a ordem importa: o mmdeviceapi traz o PROPERTYKEY que os outros usam */
#include <mmdeviceapi.h>
#include <functiondiscoverykeys_devpkey.h>
#include <devpkey.h>
#include <cfgmgr32.h>

#include "../app.h"

#include <stdio.h>

/* PKEY_Device_ContainerId: o mesmo GUID do DEVPKEY_Device_ContainerId. */
DEFINE_PROPERTYKEY(FORJA_PKEY_ContainerId, 0x8c7ed206, 0x3f8a, 0x4827, 0xb3, 0xab, 0xae, 0x9e, 0x1f, 0xae, 0xfc, 0x6c, 2);

static void guid_texto(const GUID *g, char *out, size_t tam) {
  WCHAR w[64];
  out[0] = '\0';
  if (StringFromGUID2(g, w, 64) > 0)
    WideCharToMultiByte(CP_UTF8, 0, w, -1, out, (int)tam, NULL, NULL);
}

void somc_plataforma_nos(SomControles *sc, char *rotulo, size_t tam) {
  HRESULT hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
  bool iniciou = hr == S_OK || hr == S_FALSE;
  IMMDeviceEnumerator *en = NULL;
  IMMDeviceCollection *col = NULL;
  hr = CoCreateInstance(&CLSID_MMDeviceEnumerator, NULL, CLSCTX_ALL, &IID_IMMDeviceEnumerator, (void **)&en);
  if (FAILED(hr) || !en) {
    snprintf(rotulo, tam, "sem WASAPI: só pelo nome");
    goto fim;
  }
  hr = IMMDeviceEnumerator_EnumAudioEndpoints(en, eAll, DEVICE_STATE_ACTIVE, &col);
  if (FAILED(hr) || !col) {
    snprintf(rotulo, tam, "sem endpoints no WASAPI: só pelo nome");
    goto fim;
  }
  UINT n = 0;
  IMMDeviceCollection_GetCount(col, &n);
  for (UINT i = 0; i < n; i++) {
    IMMDevice *dev = NULL;
    IPropertyStore *ps = NULL;
    if (FAILED(IMMDeviceCollection_Item(col, i, &dev)) || !dev)
      continue;
    if (FAILED(IMMDevice_OpenPropertyStore(dev, STGM_READ, &ps)) || !ps) {
      IMMDevice_Release(dev);
      continue;
    }
    char nome[160] = "", container[48] = "";
    PROPVARIANT pv;
    PropVariantInit(&pv);
    if (SUCCEEDED(IPropertyStore_GetValue(ps, &PKEY_Device_FriendlyName, &pv)) && pv.vt == VT_LPWSTR && pv.pwszVal)
      WideCharToMultiByte(CP_UTF8, 0, pv.pwszVal, -1, nome, (int)sizeof(nome), NULL, NULL);
    PropVariantClear(&pv);
    PropVariantInit(&pv);
    if (SUCCEEDED(IPropertyStore_GetValue(ps, &FORJA_PKEY_ContainerId, &pv)) && pv.vt == VT_CLSID && pv.puuid)
      guid_texto(pv.puuid, container, sizeof(container));
    PropVariantClear(&pv);
    EDataFlow fluxo = eRender;
    IMMEndpoint *ep = NULL;
    if (SUCCEEDED(IMMDevice_QueryInterface(dev, &IID_IMMEndpoint, (void **)&ep)) && ep) {
      IMMEndpoint_GetDataFlow(ep, &fluxo);
      IMMEndpoint_Release(ep);
    }
    IPropertyStore_Release(ps);
    IMMDevice_Release(dev);
    if (!nome[0] || !container[0])
      continue;
    /* volta para a lista do jogo pelo nome; entre nomes repetidos, o próximo
     * que ainda não tem container (as duas listas andam na mesma ordem) */
    for (int k = 0; k < sc->n; k++) {
      NoSom *no = &sc->nos[k];
      if (no->gravacao == (fluxo == eCapture) && !no->container[0] && !SDL_strcmp(no->nome, nome)) {
        SDL_strlcpy(no->container, container, sizeof(no->container));
        break;
      }
    }
  }
  snprintf(rotulo, tam, "WASAPI: o ContainerId do endpoint contra o do HID");
fim:
  if (col)
    IMMDeviceCollection_Release(col);
  if (en)
    IMMDeviceEnumerator_Release(en);
  if (iniciou)
    CoUninitialize();
}

/* "\\?\HID#VID_054C&PID_0CE6&MI_03#8&...&0000#{4d1e55b2-...}" vira o ID de
 * instância "HID\VID_054C&PID_0CE6&MI_03\8&...&0000". */
static bool instancia_do_caminho(const char *caminho, char *out, size_t tam) {
  const char *p = caminho;
  if (!SDL_strncmp(p, "\\\\?\\", 4) || !SDL_strncmp(p, "\\\\.\\", 4))
    p += 4;
  size_t n = SDL_strlen(p);
  const char *chave = SDL_strstr(p, "#{");
  if (chave)
    n = (size_t)(chave - p);
  if (n == 0 || n + 1 > tam)
    return false;
  for (size_t i = 0; i < n; i++)
    out[i] = p[i] == '#' ? '\\' : p[i];
  out[n] = '\0';
  return true;
}

bool somc_plataforma_pad(App *a, int slot, char *usb, size_t tam_usb, char *container, size_t tam_c) {
  (void)usb;
  (void)tam_usb;
  Pad *p = pads_do_slot(a, slot);
  if (!p || !p->gp)
    return false;
  const char *caminho = SDL_GetGamepadPath(p->gp);
  char inst[512];
  if (!caminho || !instancia_do_caminho(caminho, inst, sizeof(inst)))
    return false;
  WCHAR w[512];
  if (MultiByteToWideChar(CP_UTF8, 0, inst, -1, w, 512) <= 0)
    return false;
  DEVINST di;
  if (CM_Locate_DevNodeW(&di, w, CM_LOCATE_DEVNODE_NORMAL) != CR_SUCCESS)
    return false;
  DEVPROPTYPE tipo = 0;
  GUID g;
  ULONG t = sizeof(g);
  if (CM_Get_DevNode_PropertyW(di, &DEVPKEY_Device_ContainerId, &tipo, (PBYTE)&g, &t, 0) != CR_SUCCESS ||
      tipo != DEVPROP_TYPE_GUID)
    return false;
  guid_texto(&g, container, tam_c);
  return container[0] != '\0';
}

#endif
