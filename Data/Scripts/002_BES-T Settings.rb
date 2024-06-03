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
# Interfaces
# Aquí se configuran las rutas de las carpetas de interfaces.
# En caso de que uses el formato antiguo o quieras ponerlas en otro sitio.
# El formato por defecto esta inspirado en la versión 17.
# * Información del menú summary expandida.
# * Elimina las opciones para cambiar la textbox desde opciones.
# * Muestra la opción de regalo misterioso desde el menu de Load, sin necesidad de activarlo durante la partida.
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
NO_TETXBOX_OPTIONS    = true
MYSTERYGIFTALWAYSSHOW = false

#===============================================================================
# Gimmicks
#===============================================================================

NO_Z_MOVE = NO_MEGA_EVOLUTION #Interruptor para bloquear el uso de movimientos Z
NO_TERA_CRISTAL = NO_MEGA_EVOLUTION #Interruptor para bloquear el uso de teracristalización

ZEROAREA=[66] #Lista de mapas considerados como Área Zero(El teraorbe tiene usos infinitos)
#Para recargar el Teraorbe use: pbCharge_TeraOrb()
MAX_ORB_ENERGY=1 #Energía máxima del teraorbe al inicio de la partida.
#Puedes aumentarla durante el progreso del juego con: pbUpgradeTeraorb(cantidad de usos)

#Tonos de cada teratipo.
TERATONES=[Tone.new(142,143,107,64),#Normal
  Tone.new(143,11,1,64),#Lucha
  Tone.new(93,87,143,64),#Volador
  Tone.new(112,10,143,64),#Veneno
  Tone.new(143,71,0,64),#Tierra
  Tone.new(143,103,34,64),#Roca
  Tone.new(157,196,0,64),#Bicho
  Tone.new(76,0,117,64),#Fantasma
  Tone.new(128,128,128,64),#Metal
  Tone.new(0,0,0,0),#¿¿??
  Tone.new(245,53,0,64),#Fuego
  Tone.new(0,24,245,64),#Agua
  Tone.new(22,156,2,64),#Planta
  Tone.new(240,240,5,32),#Eléctrico
  Tone.new(255,15,119,64),#Psíquico
  Tone.new(15,255,235,64),#Hielo
  Tone.new(58,15,255,64),#Dragón
  Tone.new(53,5,78,64),#Siniestro
  Tone.new(225,38,125,64),#Hada
  Tone.new(0,0,0,0),#Oscuro
  Tone.new(20,111,193,64)]#Astral

  MEGARINGS=[:MEGARING,:MEGABRACELET,:MEGACUFF,:MEGACHARM]
  TERAORBS=[:TERAORB]
  ZRINGS=[:ZRING]
  
  def pbHasMegaRing
    for i in MEGARINGS
      next if !hasConst?(PBItems,i)
      return true if $PokemonBag.pbQuantity(i)>0
    end
    return false
  end

  def pbHasZRing
    for i in ZRINGS
      next if !hasConst?(PBItems,i)
      return true if $PokemonBag.pbQuantity(i)>0
    end
    return false
  end

  def pbHasTeraOrb
    for i in TERAORBS
      next if !hasConst?(PBItems,i)
      return true if $PokemonBag.pbQuantity(i)>0
    end
    return false
  end

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
