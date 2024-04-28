module PBRibbons
  HOENNCOOL          = 1
  HOENNCOOLSUPER     = 2
  HOENNCOOLHYPER     = 3
  HOENNCOOLMASTER    = 4
  HOENNBEAUTY        = 5
  HOENNBEAUTYSUPER   = 6
  HOENNBEAUTYHYPER   = 7
  HOENNBEAUTYMASTER  = 8
  HOENNCUTE          = 9
  HOENNCUTESUPER     = 10
  HOENNCUTEHYPER     = 11
  HOENNCUTEMASTER    = 12
  HOENNSMART         = 13
  HOENNSMARTSUPER    = 14
  HOENNSMARTHYPER    = 15
  HOENNSMARTMASTER   = 16
  HOENNTOUGH         = 17
  HOENNTOUGHSUPER    = 18
  HOENNTOUGHHYPER    = 19
  HOENNTOUGHMASTER   = 20
  SINNOHCOOL         = 21
  SINNOHCOOLSUPER    = 22
  SINNOHCOOLHYPER    = 23
  SINNOHCOOLMASTER   = 24
  SINNOHBEAUTY       = 25
  SINNOHBEAUTYSUPER  = 26
  SINNOHBEAUTYHYPER  = 27
  SINNOHBEAUTYMASTER = 28
  SINNOHCUTE         = 29
  SINNOHCUTESUPER    = 30
  SINNOHCUTEHYPER    = 31
  SINNOHCUTEMASTER   = 32
  SINNOHSMART        = 33
  SINNOHSMARTSUPER   = 34
  SINNOHSMARTHYPER   = 35
  SINNOHSMARTMASTER  = 36
  SINNOHTOUGH        = 37
  SINNOHTOUGHSUPER   = 38
  SINNOHTOUGHHYPER   = 39
  SINNOHTOUGHMASTER  = 40
  WINNING            = 41
  VICTORY            = 42
  ABILITY            = 43
  GREATABILITY       = 44
  DOUBLEABILITY      = 45
  MULTIABILITY       = 46
  PAIRABILITY        = 47
  WORLDABILITY       = 48
  CHAMPION           = 49
  SINNOHCHAMP        = 50
  RECORD             = 51
  EVENT              = 52
  LEGEND             = 53
  GORGEOUS           = 54
  ROYAL              = 55
  GORGEOUSROYAL      = 56
  ALERT              = 57
  SHOCK              = 58
  DOWNCAST           = 59
  CARELESS           = 60
  RELAX              = 61
  SNOOZE             = 62
  SMILE              = 63
  FOOTPRINT          = 64
  ARTIST             = 65
  EFFORT             = 66
  BIRTHDAY           = 67
  SPECIAL            = 68
  CLASSIC            = 69
  PREMIER            = 70
  SOUVENIR           = 71
  WISHING            = 72
  NATIONAL           = 73
  COUNTRY            = 74
  BATTLECHAMPION     = 75
  REGIONALCHAMPION   = 76
  EARTH              = 77
  WORLD              = 78
  NATIONALCHAMPION   = 79
  WORLDCHAMPION      = 80

  def PBRibbons.maxValue; 80; end
  def PBRibbons.getCount; 80; end

  def PBRibbons.getName(id)
    names=["",
    _INTL("Cinta Carisma"),
    _INTL("Cinta Carisma Alto"),
    _INTL("Cinta Carisma Avanzado"),
    _INTL("Cinta Carisma Experto"),
    _INTL("Cinta Belleza"),
    _INTL("Cinta Belleza Alto"),
    _INTL("Cinta Belleza Avanzado"),
    _INTL("Cinta Belleza Experto"),
    _INTL("Cinta Dulzura"),
    _INTL("Cinta Dulzura Alto"),
    _INTL("Cinta Dulzura Avanzado"),
    _INTL("Cinta Dulzura Experto"),
    _INTL("Cinta Ingenio"),
    _INTL("Cinta Ingenio Alto"),
    _INTL("Cinta Ingenio Avanzado"),
    _INTL("Cinta Ingenio Experto"),
    _INTL("Cinta Dureza"),
    _INTL("Cinta Dureza Alto"),
    _INTL("Cinta Dureza Avanzado"),
    _INTL("Cinta Dureza Experto"),
    _INTL("Cinta Carisma"),
    _INTL("Cinta Carisma Difícil"),
    _INTL("Cinta Carisma Superior"),
    _INTL("Cinta Carisma Experto"),
    _INTL("Cinta de Belleza"),
    _INTL("Cinta Belleza Difícil"),
    _INTL("Cinta Belleza Superior"),
    _INTL("Cinta Belleza Experto"),
    _INTL("Cinta Dulzura"),
    _INTL("Cinta Dulzura Difícil"),
    _INTL("Cinta Dulzura Superior"),
    _INTL("Cinta Dulzura Experto"),
    _INTL("Cinta Ingenio"),
    _INTL("Cinta Ingenio Difícil"),
    _INTL("Cinta Ingenio Superior"),
    _INTL("Cinta Ingenio Experto"),
    _INTL("Cinta Dureza"),
    _INTL("Cinta Dureza Difícil"),
    _INTL("Cinta Dureza Superior"),
    _INTL("Cinta Dureza Experto"),
    _INTL("Cinta Ganador"),
    _INTL("Cinta Victoria"),
    _INTL("Cinta Habilidad"),
    _INTL("Cinta Gran Habilidad"),
    _INTL("Cinta Doble Habilidad"),
    _INTL("Cinta Habilidad Múltiple"),
    _INTL("Cinta Habilidad Par"),
    _INTL("Cinta Habilidad Mundial"),
    _INTL("Cinta Campeón"),
    _INTL("Cinta Campeón"),
    _INTL("Cinta Récord"),
    _INTL("Cinta Evento"),
    _INTL("Cinta Leyenda"),
    _INTL("Cinta Maravilla"),
    _INTL("Cinta Realeza"),
    _INTL("Cinta Realeza Maravilla"),
    _INTL("Cinta Alerta"),
    _INTL("Cinta Impacto"),
    _INTL("Cinta Abatimiento"),
    _INTL("Cinta Descuido"),
    _INTL("Cinta Relax"),
    _INTL("Cinta Cabezada"),
    _INTL("Cinta Sonrisa"),
    _INTL("Cinta Huella"),
    _INTL("Cinta Artista"),
    _INTL("Cinta Esfuerzo"),
    _INTL("Cinta Cumpleaños"),
    _INTL("Cinta Especial"),
    _INTL("Cinta Clásica"),
    _INTL("Cinta Principal"),
    _INTL("Cinta Recuerdo"),
    _INTL("Cinta Deseo"),
    _INTL("Cinta Nacional"),
    _INTL("Cinta Campo"),
    _INTL("Cinta de Campeón de Torneo"),
    _INTL("Cinta Campeón de Área"),
    _INTL("Cinta Planeta"),
    _INTL("Cinta Mundo"),
    _INTL("Cinta Campeón Nacional"),
    _INTL("Cinta Campeón Mundial")
    ]
    return names[id]
  end

  def PBRibbons.getDescription(id)
    desc=["",
    _INTL("¡Ganador de la categoría Normal del Concurso Carisma!"),
    _INTL("¡Ganador de la categoría Alto del Concurso Carisma!"),
    _INTL("¡Ganador de la categoría Avanzado del Concurso Carisma!"),
    _INTL("¡Ganador de la categoría Experto del Concurso Carisma!"),
    _INTL("¡Ganador de la categoría Normal del Concurso de Belleza!"),
    _INTL("¡Ganador de la categoría Alto del Concurso de Belleza!"),
    _INTL("¡Ganador de la categoría Avanzado del Concurso de Belleza!"),
    _INTL("¡Ganador de la categoría Experto del Concurso de Belleza!"),
    _INTL("¡Ganador de la categoría Normal del Concurso de Dulzura!"),
    _INTL("¡Ganador de la categoría Alto del Concurso de Dulzura!"),
    _INTL("¡Ganador de la categoría Avanzado del Concurso de Dulzura!"),
    _INTL("¡Ganador de la categoría Experto del Concurso de Dulzura!"),
    _INTL("¡Ganador de la categoría Normal del Concurso de Ingenio!"),
    _INTL("¡Ganador de la categoría Alto del Concurso de Ingenio!"),
    _INTL("¡Ganador de la categoría Avanzado del Concurso de Ingenio!"),
    _INTL("¡Ganador de la categoría Experto del Concurso de Ingenio!"),
    _INTL("¡Ganador de la categoría Normal del Concurso de Dureza!"),
    _INTL("¡Ganador de la categoría Alto del Concurso de Dureza!"),
    _INTL("¡Ganador de la categoría Avanzado del Concurso de Dureza!"),
    _INTL("¡Ganador de la categoría Experto del Concurso de Dureza!"),
    _INTL("¡Ganador de la categoría Normal del Súper concurso de Categoría Carisma!"),
    _INTL("¡Ganador de la categoría Difícil del Súper concurso de Categoría Carisma!"),
    _INTL("¡Ganador de la categoría Superior del Súper concurso de Categoría Carisma!"),
    _INTL("¡Ganador de la categoría Experto del Súper concurso de Categoría Carisma!"),
    _INTL("¡Ganador de la categoría Normal del Súper concurso de Categoría Belleza!"),
    _INTL("¡Ganador de la categoría Difícil del Súper concurso de Categoría Belleza!"),
    _INTL("¡Ganador de la categoría Superior del Súper concurso de Categoría Belleza!"),
    _INTL("¡Ganador de la categoría Experto del Súper concurso de Categoría Belleza!"),
    _INTL("¡Ganador de la categoría Normal del Súper concurso de Categoría Dulzura!"),
    _INTL("¡Ganador de la categoría Difícil del Súper concurso de Categoría Dulzura!"),
    _INTL("¡Ganador de la categoría Superior del Súper concurso de Categoría Dulzura!"),
    _INTL("¡Ganador de la categoría Experto del Súper concurso de Categoría Dulzura!"),
    _INTL("¡Ganador de la categoría Normal del Súper concurso de Categoría Ingenio!"),
    _INTL("¡Ganador de la categoría Difícil del Súper concurso de Categoría Ingenio!"),
    _INTL("¡Ganador de la categoría Superior del Súper concurso de Categoría Ingenio!"),
    _INTL("¡Ganador de la categoría Experto del Súper concurso de Categoría Ingenio!"),
    _INTL("¡Ganador de la categoría Normal del Súper concurso de Categoría Dureza!"),
    _INTL("¡Ganador de la categoría Difícil del Súper concurso de Categoría Dureza!"),
    _INTL("¡Ganador de la categoría Superior del Súper concurso de Categoría Dureza!"),
    _INTL("¡Ganador de la categoría Experto del Súper concurso de Categoría Dureza!"),
    _INTL("Cinta otorgada por superar el desafío de nivel 50 de la Torre Batalla."),
    _INTL("Cinta otorgada por superar el desafío de nivel 100 de la Torre Batalla."),
    _INTL("Cinta obtenida por vencer por primera vez al Amo Torre en la Torre Batalla."),
    _INTL("Cinta obtenida por vencer por segunda vez al Amo Torre en la Torre Batalla."),
    _INTL("Una cinta otorgada por completar el desafío de Doble de la Torre Batalla."),
    _INTL("Una cinta otorgada por completar el desafío Multi de la Torre Batalla."),
    _INTL("Una cinta otorgada por completar el desafío Multi Conexión de la Torre Batalla."),
    _INTL("Una cinta otorgada por completar el desafío de la Torre Batalla Wi-Fi."),
    _INTL("Cinta por superar la Liga Pokémon e ingresar al Salón de la Fama."),
    _INTL("Cinta otorgada por vencer al Campeón e ingresar al Salón de la Fama de Sinnoh."),
    _INTL("Una cinta otorgada por establecer un récord increíble."),
    _INTL("Una cinta otorgada por establecer un récord histórico."),
    _INTL("Una cinta otorgada por establecer un récord legendario."),
    _INTL("Una cinta extremadamente bonita y extravagante."),
    _INTL("Una cinta increíblemente majestuosa y con un aire aristocrático."),
    _INTL("Una cinta preciosa y majestuosa que es de lo más fabulosa y maravillosa."),
    _INTL("Una cinta para recordar un evento vigorizante que creó energía vital."),
    _INTL("Una cinta para recordar un evento excionante que hizo la vida más interesante."),
    _INTL("Una cinta para recordar sentimientos tristes que añadieron interés a la vida."),
    _INTL("Una cinta para recordar descuidos que ayudaron a tomar decisiones vitales."),
    _INTL("Una cinta para recordar una anécdota refrescante que añadió chispa a la vida."),
    _INTL("Una cinta para recordar un sueño profundo que hizo que la vida fuera calmada."),
    _INTL("Una cinta para recordar que las sonrisas mejoran la calidad de vida."),
    _INTL("Una cinta otorgada a un Pokémon que deja huellas de primera."),
    _INTL("Cinta otorgada por ser elegido como supermodelo en Hoenn."),
    _INTL("Cinta otorgada por ser un excelente trabajador."),
    _INTL("Una cinta para celebrar un cumpleaños."),
    _INTL("Una cinta para conmemorar un día especial."),
    _INTL("Una cinta que proclama amor por los Pokémon."),
    _INTL("Cinta de vacaciones especiales."),
    _INTL("Una cinta conmemorativa obtenida en un lugar misterioso."),
    _INTL("Una cinta conmemorativa obtenida en un lugar misterioso."),
    _INTL("Una cinta otorgada por superar todos los desafíos difíciles."),
    _INTL("Cinta de Campeón."),
    _INTL("Cinta de Campeón de Competición de Batalla."),
    _INTL("Cinta Campeón de Área"),
    _INTL("Una cinta otorgada por ganar 100 combates seguidos."),
    _INTL("Cinta de Campeón."),
    _INTL("Cinta de Campeón Nacional del Campeonato Mundial de Videojuegos Pokémon."),
    _INTL("Cinta de Campeón Mundial del Campeonato Mundial de Videojuegos Pokémon")
    ]
    return desc[id]
  end
end