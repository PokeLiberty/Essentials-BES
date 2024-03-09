#===============================================================================
# * El ancho de la pantalla por defecto (a escala 1.0; el tamaño es de la
#      mitad a escala 0.5).
# * La altura de la pantalla por defecto (a escala 1.0).
# * La escala de la pantalla por defecto (1.0 significa que cada tile es
#      de 32x32 pixeles, 0.5 significa que cada tile es de 16x16 pixeles,
#      2.0 significa que cada tile es de 64x64 pixeles).
# * Indica, en el modo de pantalla completa, si se permite que la imágen de los
#      bordes salga de los límites de la pantalla (true) o si se debe forzar que
#      la misma debe ser mostrada completamente dentro de la pantalla (false).
# * El ancho de los bordes izquierdo y derecho de la pantalla. Éstos se suman al
#      valor indicado como ancho de la pantalla, cuando el borde está activo.
# * La altura de los bordes superior e inferior de la pantalla. Éstos se suman
#      al valor indicado como altura de la pantalla, sólo cuando el borde
#      está activo.
# * Modo de vista del mapa (0=original, 1=personalizado, 2=perspectiva).
#===============================================================================
DEFAULTSCREENWIDTH   = 512
DEFAULTSCREENHEIGHT  = 384
DEFAULTSCREENZOOM    = 1.0
FULLSCREENBORDERCROP = false
BORDERWIDTH          = 80
BORDERHEIGHT         = 80
MAPVIEWMODE          = 1
# Para evitar que el jugador cambie el tamaño de la pantalla, comente o elimine
# el código correspondiente en la sección del script PScreen_Options.

#===============================================================================
# * El nivel máximo que pueden alcanzar los Pokémon.
# * El nivel de un Pokémon al salir del huevo.
# * La probabilidad de que un Pokémon sea shiny al momento de su creación
#   (entre 65536).
# * La probabilidad de que un Pokémon tenga Pokérus al momento de su creación
#   (entre 65536).
#===============================================================================
MAXIMUMLEVEL       = 100
EGGINITIALLEVEL    = 1
SHINYPOKEMONCHANCE = 16
POKERUSCHANCE      = 3

#===============================================================================
# * Indica si un Pokémon envenenado pierde PS mientras el entrenador camina.
# * Indica si un Pokémon envenenado puede debilitarse mientras el entrenador
#      camina (true) o si sobrevivirá con 1 PS (false).
# * Indica si, al pescar, el Pokémon es enganchado automáticamente (en false,
#      se agrega una prueba de reacción).
# * Indica si el jugador puede emergir en cualquier lugar cuando bucea (true)
#      o si puede hacerlo solamente en los mismos lugares donde puede
#      sumergirse (false).
# * Indica si las bayas plantadas crecen según la mecánica de la Gen 4 (true)
#      o de la Gen 3 (false).
# * Indica si las MTs se pueden usar infinitamente como en la Gen 5 (true)
#      o tiene un sólo uso como en las generaciones anteriores (false).
#===============================================================================
POISONINFIELD         = true
POISONFAINTINFIELD    = false
FISHINGAUTOHOOK       = false
DIVINGSURFACEANYWHERE = false
NEWBERRYPLANTS        = true
INFINITETMS           = true

#===============================================================================
# * Indica si la categoría física/especial de los movimientos depende de la
#      definición de dicho movimiento como en las generaciones más nuevas (true)
#      o si depende de su tipo como en las generaciones más viejas (false).
# * Indica si la mecánica de las batallas responde a la Gen 6 (true)
#      o a la Gen 5 (false).
# * Indica si la Exp ganada al derrotar a un Pokémon debería ser escalada
#      dependiendo en el nivel de los participantes como en la Gen 5 (true),
#      o no, como en las generaciones anteriores (false).
# * Indica si la Exp ganada al derrotar a un Pokémon debería ser dividida
#      equitativamente entre los participantes (false) o si cada uno de ellos
#      debería ganar el total de la Exp. Esto también aplica a la Exp ganada
#      mediante el Repartir Exp (la versión portable) siendo repartida en todos
#      los que llevan Repartir Exp. Esta característica es true en la Gen 6
#      y false de todas las anteriores.
# * Indica si se aplica la mecánica de captura crítica (true) o no (false).
#      Esta mecánica se basa en un total de más de 600 especies (es decir,
#      cuántas especies necesitan ser capturadas para conseguir el mayor
#      índice de captura crítica de 2.5x), y puede haber un número menor de
#      especies en tu juego.
# * Indica si se gana Exp al capturar a un Pokémon (true) o no (false).
#===============================================================================
USEMOVECATEGORY       = true
USENEWBATTLEMECHANICS = true
USESCALEDEXPFORMULA   = true
NOSPLITEXP            = true
USECRITICALCAPTURE    = false # NO ACTIVAR, BUGEADO
GAINEXPFORCAPTURE     = true

#===============================================================================
# * Los nombres de cada uno de los bolsillos de la Mochila.
#   Dejar el primer elemento en blanco.
# * La capacidad máxima de objetos distintos de cada bolsillo (-1 indica una
#      cantidad infinita). Se ignora el primer número (0).
# * La cantidad máxima de un mismo objeto que se puede llevar en la Mochila.
# * Indica por cada bolsillo si se ordena automáticamente por el número ID
#   del objeto. Se ignora el primer número (0).
# * Indica el número del bolsillo que contiene todas las bayas. Se usa para
#      identificar el bolsillo que se debe mostrar cuando se está por plantar
#      una baya, y no se puede cambiar la vista a otro bolsillo.
#===============================================================================
def pbPocketNames; return ["",
   _INTL("Objetos"),
   _INTL("Medicinas"),
   _INTL("Poké Balls"),
   _INTL("MTs / MOs"),
   _INTL("Bayas"),
   _INTL("Cristales Z"),
   _INTL("Obj. Batallas"),
   _INTL("Obj. Claves")
]; end
MAXPOCKETSIZE  = [0,-1,-1,-1,-1,-1,-1,-1,-1]
BAGMAXPERSLOT  = 99
POCKETAUTOSORT = [0,false,false,false,true,true,false,false,false]
BERRYPOCKET    = 5

#===============================================================================
# * La cantidad mínima de medallas necesarias para potencias cada una de las
#      características de los Pokémon del jugador en 1.1x, usado en combate.
# * Indica si la restricción del uso de ciertos movimientos ocultos depende
#      de la cantidad de medallas conseguidas (true) o de conseguir una medalla
#      en particular (false).
# * Dependiendo de HIDDENMOVESCOUNTBADGES, puede indicar la cantidad de medallas
#      necesarias para usar cada uno de los movimientos ocultos o el número de
#      la medalla específica que se necesita para poder usarlos. Recuerda que la
#      medalla 0 es la primera, la medalla 1 es la segunda, y así sucesivamente.
# Por ejemplo: Para restringir Corte con la segunda medalla,
#                 se usa HIDDENMOVESCOUNTBADGES = false y BADGEFORCUT = 1.
#              Para restringir Surf con dos medallas, se usa false y 1.
#                 se usa HIDDENMOVESCOUNTBADGES = true y BADGEFORSURF = 2.
#===============================================================================
BADGESBOOSTATTACK      = 16
BADGESBOOSTDEFENSE     = 16
BADGESBOOSTSPEED       = 16
BADGESBOOSTSPATK       = 16
BADGESBOOSTSPDEF       = 16
HIDDENMOVESCOUNTBADGES = false
BADGEFORCUT            = 1
BADGEFORROCKSMASH      = 2
BADGEFORSURF           = 3
BADGEFORFLY            = 4
BADGEFORSTRENGTH       = 5
BADGEFORDIVE           = 6
BADGEFORWATERFALL      = 7
BADGEFORROCKCLIMB      = 8

#===============================================================================
# * Indica si los mapas exteriores deberían presentar sombras según la hora.
#===============================================================================
ENABLESHADING = true

#===============================================================================
# * Par de IDs de mapas, entre los cuales no se mostrará el letrero de ubicación
#      cuando el jugador pasa de uno al otro (y viceversa). Usado para rutas o
#      pueblos grandes que se expanden sobre varios mapas.
#   Por ejemplo [4,5,16,17,42,43] serán pares de mapas los (4,5), (16,17) y
#      (42,43).
#   De todas formas, al pasar entre dos mapas que tienen exactamente el mismo
#      nombre, no se muestra el letrero de ubicación; así que no es necesario
#      listar aquí esos mapas.
#===============================================================================
NOSIGNPOSTS = []

#===============================================================================
# * El nombre del creador del Sistema de Almacenamiento de Pokémon.
# * La cantidad de cajas que tiene el Sistema de Almacenamiento.
#===============================================================================
def pbStorageCreator
  return _INTL("Bill")
end
STORAGEBOXES = 35

#===============================================================================
# * Indica si la lista de accesos al Dex que se muestra corresponde a la región
#      donde se encuentra el jugador (true) o si se muestra un menú para
#      que el jugador elija manualmente la Dex que quiere consultar (false).
# * Los nombres de cada unos de los accesos a la Dex del juego, en orden y con
#      la Pokédex Nacional al final. Es el mismo orden que está en 
#      $PokemonGlobal.pokedexUnlocked, que registra cuáles son las Dex
#      desbloqueadas (la primera está desbloqueada por defecto).
#      Se puede vincular una Dex en particular a una región. De esta forma,
#      al acceder a la Dex indicada, siempre se mostrará el mapa de la región
#      definida independientemente de la región en la que se encuentre el
#      jugador en ese momento. Para definir esto. Para hacer esto, se ponen en
#      un mismo arreglo el nombre de la Dex y el número de la región. Las Dex
#      de Kanto y Jotho son dos ejemplo de ésto. La Dex Nacional no se
#      encuentra asociada a una región, por lo que el mapa que muestre será
#      el de la región donde se encuentre el jugador en cada momento.
# * Indica si estarán disponibles en la Dex todas las formas que pueda tener una
#      especie inmediatamente desde el momento en que se encuentra una de sus
#      formas (true) o si es necesario avistar específicamente cada una de las
#      formas para registrarlas en la Dex (false).
# * Un arreglo de números, donde cada número corresponde a una Dex (la Dex
#      Nacional es el -1). Todas las Dex incluidas aquí tendrán el número de
#      especie reducido en 1, haciendo que la primer especie listada tenga el
#      número 0 (por ejemplo, Victini en la Dex Unova).
#===============================================================================
DEXDEPENDSONLOCATION = false
def pbDexNames; return [
   [_INTL("Pokédex"),0],
   [_INTL("Pokédex Paradoja"),1],
   _INTL("Pokédex Nacional")
]; end
ALWAYSSHOWALLFORMS = false
DEXINDEXOFFSETS    = []

#===============================================================================
# * La cantidad de dinero con la que el jugador inicia el juego.
# * La cantidad máxima de dinero que puede tener el jugador.
# * La cantidad máxima de cupones del Rincón de Juegos que se pueden llevar.
# * La cantidad máxima de Puntos de Batalla que se pueden llevar.
#===============================================================================
INITIALMONEY = 3000
MAXMONEY     = 999999
MAXCOINS     = 99999

#===============================================================================
# * Un conjunto de arreglos que contiene un tipo de entrenador seguido del
#      número de una Variable Global. Si la variable no contiene un 0, entonces
#      todos los entrenadores asociados al tipo de entrenador indicado tendrá
#      el nombre que se haya establecido como valor de esa variable.
#===============================================================================
RIVALNAMES = [
   [:RIVAL1,12],
   [:RIVAL2,12],
   [:CHAMPION,12]
]

#===============================================================================
# * Una lista de mapas usada por Pokémon errantes. Cada mapa contiene un arreglo
#      de los otros mapas a los que puede saltar el Pokémon.
# * Un conjunto de arreglos que contiene los datos de un Pokémon errante.
#      La información que contienen es la siguiente:
#      - Especie.
#      - Nivel.
#      - Interruptor Global; el Pokémon está viajando mientras está encendido.
#      - Tipo de encuentro (0=cualquiera, 1=hierba/caminando en cueva,
#           2=surfeando, 3=pescando, 4=surfeando/pescando). Consulta las listas
#           al final de PField_RoamingPokemon.
#      - El nombre del BGM (Música de fondo) que se pasa en el encuentro (opcional).
#      - Las areas específicas donde este Pokémon puede aparecer (opcional).
#===============================================================================
RoamingAreas = {
   5  => [21,28,31,39,41,44,47,66,69],
   21 => [5,28,31,39,41,44,47,66,69],
   28 => [5,21,31,39,41,44,47,66,69],
   31 => [5,21,28,39,41,44,47,66,69],
   39 => [5,21,28,31,41,44,47,66,69],
   41 => [5,21,28,31,39,44,47,66,69],
   44 => [5,21,28,31,39,41,47,66,69],
   47 => [5,21,28,31,39,41,44,66,69],
   66 => [5,21,28,31,39,41,44,47,69],
   69 => [5,21,28,31,39,41,44,47,66]
}
RoamingSpecies = [
   [:LATIAS, 30, 53, 0, "002-Battle02x"],
   [:LATIOS, 30, 53, 0, "002-Battle02x"],
   [:KYOGRE, 40, 54, 2, nil, {
       2  => [21,31],
       21 => [2,31,69],
       31 => [2,21,69],
       69 => [21,31]
       }],
   [:ENTEI, 40, 55, 1, nil]
]

#===============================================================================
# * Un conjunto de arreglos que contiene los detalles de un encuentro salvaje
#      que sólo puede ocurrir mediante el uso del Poké Radar. Los datos son
#      los siguientes:
#      - ID del Mapa en el que puede ocurrir el encuentro.
#      - Probabilidad en la que puede ocurrir el encuentro (como un porcentaje).
#      - Especie.
#      - Nivel mínimo posible.
#      - Nivel máximo posible (opcional).
#===============================================================================
POKERADAREXCLUSIVES=[
   [5,  20, :STARLY,     12, 15],
   [21, 10, :STANTLER,   14],
   [28, 20, :BUTTERFREE, 15, 18],
   [28, 20, :BEEDRILL,   15, 18]
]

#===============================================================================
# * Un conjunto de arreglos que contiene los datos de los mapas adicionales que
#      se pueden mostrar en el mapa de una región según sea apropiado. Los
#      valores de cada arreglo son los siguientes:
#      - Número de la región.
#      - Interruptor Global; el gráfico se muestra si está encendido (no cuenta
#           en mapas de pared).
#      - Coordenada X del gráfico en el mapa, en cuadros.
#      - Coordenada Y del gráfico en el mapa, en cuadros.
#      - Nombre del gráfico, para identificarlo en la carpeta Graphics/Pictures.
#      - Indica si el gráfico será mostrado mostrado siempre (true) o nunca
#        (false) en un mapa de pared.
#===============================================================================
REGIONMAPEXTRAS = [
   [0,51,16,15,"mapHiddenBerth",false],
   [0,52,20,14,"mapHiddenFaraday",false]
]

#===============================================================================
# * El número de pasos disponibles en un juego de la Zona Safari (0=infinito).
# * La cantidad de segundos que dura un Concurso Cazabichos (0=infinito).
#===============================================================================
SAFARISTEPS    = 600
BUGCONTESTTIME = 1200

#===============================================================================
# * El Interruptor Global que se enciende cuando el jugador inicia el juego.
# * El Interruptor Global que se enciende cuando el jugador es informado sobre
#      el Pokérus en un Centro Pokémon, y no necesita que se le informe
#      nuevamente.
# * El Interruptor Global que, mientras está activo, hace que todos los Pokémon
#      salvajes sean creados con shiny.
# * El Interruptor Global que, mientras está activo, hace que todos los Pokémon
#      creados sean considerados como un encuentro fatídico.
# * El Interruptor Global que determina si el jugador pierde dinero cuando
#      pierde un combate (seguirá ganando dinero de los entrenadores que
#      derrote).
# * El Interruptor Global que, mientras está activo, impide que todos los
#      Pokémon pueden Mega evolucionar incluso cuando estén en condiciones.
#===============================================================================
STARTING_OVER_SWITCH      = 1
SEEN_POKERUS_SWITCH       = 2
SHINY_WILD_POKEMON_SWITCH = 31
FATEFUL_ENCOUNTER_SWITCH  = 32
NO_MONEY_LOSS             = 33
NO_MEGA_EVOLUTION         = 34
NO_ULTRA_BURST            = 35

#===============================================================================
# * El ID del evento común que se ejecuta cuando el jugador saca una caña de
#      pescar (se ejecuta en lugar de mostrar la animación de lanzamiento).
# * El ID del evento común que se ejecuta cuando el jugador guarda una caña de
#      pescar (se ejecuta en lugar de mostrar la animación de recogida).
#===============================================================================
FISHINGBEGINCOMMONEVENT   = -1
FISHINGENDCOMMONEVENT     = -1

#===============================================================================
# * El ID de la animación mostrada cuando el jugador pasa sobre la hierba
#      (muestra la hierba crujiendo).
# * El ID de la animación mostrada cuando el jugador cae sobre la tierra tras
#      saltar una cornisa (muestra un salto de polvo).
# * El ID de la animación mostrada cuando un entrenador avista al jugador
#      (muestra una burbuja de exclamación).
# * El ID de la animación mostrada cuando la hierba se sacude como respuesta
#      al Poké Radar.
# * El ID de la animación mostrada cuando la hierba se sacude enérgicamente
#      como respuesta al Poké Radar (especies raras).
# * El ID de la animación mostrada cuando la hierba se sacude y brilla como
#      respuesta al Poké Radar (encuentro shiny).
# * El ID de la animación mostrada cuando una planta de bayas crece mientras
#      el jugador está en el mapa (solamente aplica para la nueva mecánica de
#      crecimiento de plantas).
#===============================================================================
GRASS_ANIMATION_ID           = 1
DUST_ANIMATION_ID            = 2
EXCLAMATION_ANIMATION_ID     = 3
RUSTLE_NORMAL_ANIMATION_ID   = 1
RUSTLE_VIGOROUS_ANIMATION_ID = 5
RUSTLE_SHINY_ANIMATION_ID    = 6
PLANT_SPARKLE_ANIMATION_ID   = 7

#===============================================================================
# * Un arreglo con los lenguajes disponibles en el juego y su archivo
#      correspondiente en la carpeta Data. Edite solamente si su juego tiene dos
#      o más lenguajes disponibles.
#===============================================================================
LANGUAGES = [  
#  ["English","english.dat"],
#  ["Deutsch","deutsch.dat"]
]

#===============================================================================
# * Indica si los nombres son ingresados directamente desde el teclado (true) o
#      seleccionando una a una las teclas como en los juegos oficiales (false).
#===============================================================================
USEKEYBOARDTEXTENTRY = false