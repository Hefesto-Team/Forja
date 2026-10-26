#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "forja_controles.h"

using namespace godot;

static void iniciar(ModuleInitializationLevel nivel) {
  if (nivel != MODULE_INITIALIZATION_LEVEL_SCENE)
    return;
  GDREGISTER_CLASS(ForjaControles);
}

static void encerrar(ModuleInitializationLevel nivel) { (void)nivel; }

extern "C" GDExtensionBool GDE_EXPORT forja_iniciar_biblioteca(GDExtensionInterfaceGetProcAddress endereco,
                                                               const GDExtensionClassLibraryPtr biblioteca,
                                                               GDExtensionInitialization *inicio) {
  GDExtensionBinding::InitObject init(endereco, biblioteca, inicio);
  init.register_initializer(iniciar);
  init.register_terminator(encerrar);
  init.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
  return init.init();
}
