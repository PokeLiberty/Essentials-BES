module PBNatures
  HARDY   = 0
  LONELY  = 1
  BRAVE   = 2
  ADAMANT = 3
  NAUGHTY = 4
  BOLD    = 5
  DOCILE  = 6
  RELAXED = 7
  IMPISH  = 8
  LAX     = 9
  TIMID   = 10
  HASTY   = 11
  SERIOUS = 12
  JOLLY   = 13
  NAIVE   = 14
  MODEST  = 15
  MILD    = 16
  QUIET   = 17
  BASHFUL = 18
  RASH    = 19
  CALM    = 20
  GENTLE  = 21
  SASSY   = 22
  CAREFUL = 23
  QUIRKY  = 24

  def PBNatures.maxValue; 24; end
  def PBNatures.getCount; 25; end

  def PBNatures.getName(id)
    names=[
       _INTL("Fuerte"),
       _INTL("Huraña"),
       _INTL("Audaz"),
       _INTL("Firme"),
       _INTL("Pícara"),
       _INTL("Osada"),
       _INTL("Dócil"),
       _INTL("Plácida"),
       _INTL("Agitada"),
       _INTL("Floja"),
       _INTL("Miedosa"),
       _INTL("Activa"),
       _INTL("Seria"),
       _INTL("Alegre"),
       _INTL("Ingenua"),
       _INTL("Modesta"),
       _INTL("Afable"),
       _INTL("Mansa"),
       _INTL("Tímida"),
       _INTL("Alocada"),
       _INTL("Serena"),
       _INTL("Amable"),
       _INTL("Grosera"),
       _INTL("Cauta"),
       _INTL("Rara")
    ]
    return names[id]
  end
end