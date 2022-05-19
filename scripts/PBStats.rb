begin
  module PBStats
    HP       = 0
    ATTACK   = 1
    DEFENSE  = 2
    SPEED    = 3
    SPATK    = 4
    SPDEF    = 5
    ACCURACY = 6
    EVASION  = 7

    def PBStats.getName(id)
      names=[
         _INTL("PS"),
         _INTL("Ataque"),
         _INTL("Defensa"),
         _INTL("Velocidad"),
         _INTL("Ataque Especial"),
         _INTL("Defensa Especial"),
         _INTL("Precisión"),
         _INTL("Evasión")
      ]
      return names[id]
    end  end

rescue Exception
  if $!.is_a?(SystemExit) || "#{$!.class}"=="Reset"
    raise $!
  end
end