#===============================================================================
# BES-T FEATURES
# 
# * Indica si quieres que haya 60 fps, solo funciona desde game.exe.
# * Interruptor usado para bloquear capturas.
#
# * Indica si quieres que el repartir experiencia sea el de 8+ gen(true) o no (false).
#     Si se desactiva, se puede seguir usando entregando el objeto EXPALL.
# * Indica si quieres que el granizo se convierta en nieve (true) o no (false).
# * Indica si quieres que el estado Congelado se convierta en Helado de PLA (true) o no (false).
# * Recorta algunos textos del sistema, como el guardado, la recogida de bayas y otros.
# * Añade la opción de cambiar el mote desde el menú.
# * Añade la opción del recuerda movimientos desde el menú.
# * Aumenta ligeramente la velocidad del jugador.
# * Aumenta la velocidad de los combates. 
#      Puede ser incompatible con cambios de Framerate o el turbo.
# * Indica si quieres que el Turbo este activado siempre(Alt), pero que solo funcione con el debug. 
#      Si se desactiva, funcionara en cualquier situación.
# * Indica si quieres que el Text Skip activado solo en el modo turbo, tecla Q.
# * Indica si quieres que los pokémon ganan Experiencia en la guardería(true) o no (false).
#
# * Indica si quieres que la hierba no cubra al personaje cuando se mueve.
# * Indica si quieres que la hierba alta suene cuando la pisas.
# * Indica si quieres que la hierba no tenga animacion. 
#      Puede ayudar con el rendimiento y queda mejor con tiles de hierba más modernos.
#===============================================================================
FPS60                     = true
NO_CAPTURE_SWITCH         = 36

EXPALLWITHOUTITEM         = true
SNOW_REPLACES_HAIL        = true 
FROSTBITE_REPLACES_FREEZE = false # RECUERDA EDITAR EL GRAFICO
SHORTER_SYSTEM_TEXTS      = true  # A MEJORAR
MENU_NICKNAME             = true
MENU_MOVERELEANER         = true
FASTER_BATTLE             = false
TURBO_DEBUG               = false
SKIPTEXT_DEBUG            = true
LEVEL_DAYCARE             = false

GRASS_SOUND               = true
GRASS_NO_ANIM             = false


#===============================================================================
# Arreglo de posiciones en sprites animados.
# Activalo si vas a usar sprites animados y o los que tienes no se posicionan correctamente.
#===============================================================================
ANIMATEDFORMAT = false

#===============================================================================
# Interfaces
# Aquí se configuran las rutas de las carpetas de interfaces. 
# En caso de que uses el formato antiguo o quieras ponerlas en otro sitio.
# El formato por defecto esta inspirado en la versión 17.
# * Información del menú summary expandida.
# * Elimina las opciones para cambiar la textbox desde opciones. 
#===============================================================================

BAG_ROUTE      = "Pictures/Bag"
BATTLE_ROUTE   = "Pictures/Battle"
NAMING_ROUTE   = "Pictures/Naming"
PARTY_ROUTE    = "Pictures/Party"
POKEDEX_ROUTE  = "Pictures/Pokedex"
POKEGEAR_ROUTE = "Pictures/Pokegear"
STORAGE_ROUTE  = "Pictures/Storage"
SUMMARY_ROUTE  = "Pictures/Summary"

EXPANDED_SUMMARY_INFO = true
NO_TETXBOX_OPTIONS = true

#===============================================================================
# Gimmicks
#===============================================================================

NO_Z_MOVE = NO_MEGA_EVOLUTION #Interruptor para bloquear el uso de movimientos Z

#===============================================================================
# Shadow Config
# Te permite escoger nombres de evento donde no aparezcan sombras.
#===============================================================================
No_Shadow_If_Event_Name_Has = ["door",
                              "nurse",
                              "healing balls",
                              "Mart",
                              "boulder",
                              "tree",
                              "HeadbuttTree",
                              "BerryPlant",
                              "Luz",
                              "Puerta",
                              "noShadow",
                              
                   ]