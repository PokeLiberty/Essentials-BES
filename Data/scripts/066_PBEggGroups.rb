module PBEggGroups
  Monster      = 1
  Water1       = 2
  Bug          = 3
  Flying       = 4
  Field        = 5 # Ground
  Fairy        = 6
  Grass        = 7 # Plant
  Humanlike    = 8 # Humanoid, Humanshape, Human
  Water3       = 9
  Mineral      = 10
  Amorphous    = 11 # Indeterminate
  Water2       = 12
  Ditto        = 13
  Dragon       = 14
  Undiscovered = 15 # NoEggs, None, NA

  def PBEggGroups.maxValue; 15; end
  def PBEggGroups.getCount; 15; end

  def PBEggGroups.getName(id)
    names=["",
       _INTL("Monstruo"),
       _INTL("Agua 1"),
       _INTL("Bicho"),
       _INTL("Volador"),
       _INTL("Campo"),
       _INTL("Hada"),
       _INTL("Planta"),
       _INTL("Humanoide"),
       _INTL("Agua 3"),
       _INTL("Mineral"),
       _INTL("Amorfo"),
       _INTL("Agua 2"),
       _INTL("Ditto"),
       _INTL("Dragón"),
       _INTL("Ninguno")
    ]
    return names[id]
  end
end