#70925035
begin
  module PBStatuses
    SLEEP     = 1
    POISON    = 2
    BURN      = 3
    PARALYSIS = 4
    FROZEN    = 5

    def PBStatuses.getName(id)
      if FROSTBITE_REPLACES_FREEZE #BES-T
        names=[
           _INTL("saludable"),
           _INTL("dormido"),
           _INTL("envenenado"),
           _INTL("quemado"),
           _INTL("paralizado"),
           _INTL("congelado")
        ]
      else
         names=[
           _INTL("saludable"),
           _INTL("dormido"),
           _INTL("envenenado"),
           _INTL("quemado"),
           _INTL("paralizado"),
           _INTL("helado")
        ]
      end
    return names[id]
    end  end

rescue Exception
  if $!.is_a?(SystemExit) || "#{$!.class}"=="Reset"
    raise $!
  end
end