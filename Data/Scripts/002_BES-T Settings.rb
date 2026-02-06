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
# * Indica si quieres que el Text Skip activado solo en el modo debug, tecla Q.
# * Indica si quieres que los pokémon ganan Experiencia en la guardería(true) o no (false).
#
# * Indica si quieres que la hierba no cubra al personaje cuando se mueve.
# * Indica si quieres que la hierba alta suene cuando la pisas.
# * Indica si quieres que la hierba no tenga animacion.
#      Puede ayudar con el rendimiento y queda mejor con tiles de hierba más modernos.
# * Divisor para las ventas en la tienda. Default: 2. 
#      Las generaciones más recientes usan el 4.
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
SKIPTEXT_DEBUG            = false
LEVEL_DAYCARE             = false

GRASS_SOUND               = true
GRASS_NO_ANIM             = false

SELL_ITEMPRICE            = 2
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
  TERATONES=[Color.new(142,143,107,100),#Normal
             Color.new(143,11,1,100),   #Lucha
             Color.new(93,87,143,100),  #Volador
             Color.new(112,10,143,100), #Veneno
             Color.new(143,71,0,100),   #Tierra
             Color.new(143,103,34,100), #Roca
             Color.new(157,196,0,100),  #Bicho
             Color.new(76,0,117,100),   #Fantasma
             Color.new(128,128,128,100),#Metal
             Color.new(0,0,0,0),       #¿¿??
             Color.new(245,53,0,100),   #Fuego
             Color.new(0,24,245,100),   #Agua
             Color.new(22,156,2,100),   #Planta
             Color.new(240,240,5,100),  #Eléctrico
             Color.new(255,15,119,100), #Psíquico
             Color.new(15,255,235,100), #Hielo
             Color.new(58,15,255,100),  #Dragón
             Color.new(53,5,78,100),    #Siniestro
             Color.new(225,38,125,100), #Hada
             Color.new(53,5,78,100),    #Oscuro
             Color.new(20,111,193,100)] #Astral 
           
  DYNATONE     = [Color.new(217,29,71,128),Color.new(56,160,193,128)]
  DYNAMAXMAPS  = [] # Mapas donde el dynamax estará activo.

  MEGARINGS=[:MEGARING,:MEGABRACELET,:MEGACUFF,:MEGACHARM]
  TERAORBS=[:TERAORB]
  ZRINGS=[:ZRING]
  DBANDS=[:DYNAMAXBAND]
  
  def pbHasMegaRing
    return false if !$PokemonBag
    for i in MEGARINGS
      next if !hasConst?(PBItems,i)
      return true if $PokemonBag.pbQuantity(i)>0
    end
    return false
  end

  def pbHasZRing
    return false if !$PokemonBag
    for i in ZRINGS
      next if !hasConst?(PBItems,i)
      return true if $PokemonBag.pbQuantity(i)>0
    end
    return false
  end

  def pbHasTeraOrb
    return false if !$PokemonBag
    for i in TERAORBS
      next if !hasConst?(PBItems,i)
      return true if $PokemonBag.pbQuantity(i)>0
    end
    return false
  end
  
  NO_DYNAMAX = NO_MEGA_EVOLUTION
  
  def pbHasDBand
    return false if !$PokemonBag
    for i in DBANDS
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
