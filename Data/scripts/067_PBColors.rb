# Los colores deben comenzar en el 0 sin omitir ningún número
module PBColors
  Red    = 0
  Blue   = 1
  Yellow = 2
  Green  = 3
  Black  = 4
  Brown  = 5
  Purple = 6
  Gray   = 7
  White  = 8
  Pink   = 9

  def PBColors.maxValue; 9; end
  def PBColors.getCount; 10; end

  def PBColors.getName(id)
    names=[_INTL("Rojo"),
           _INTL("Azul"),
           _INTL("Amarillo"),
           _INTL("Verde"),
           _INTL("Negro"),
           _INTL("Marrón"),
           _INTL("Morado"),
           _INTL("Gris"),
           _INTL("Blanco"),
           _INTL("Rosa")
    ]
    return names[id]
  end
end