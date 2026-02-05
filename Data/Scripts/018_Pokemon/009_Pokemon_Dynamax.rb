class PokeBattle_Pokemon
  attr_accessor :dynamax
  attr_accessor :gigantamax
  attr_accessor :dynamax_lvl
  attr_accessor :gmaxfactor
  attr_accessor :reverted
  attr_accessor :max_ace     #Si es true el Pokémon dynamaxeara (solo usado en entrenadores)
  ################################################################################
  # Dynamax Properties
  ################################################################################
  alias dynamax_initialize initialize
  def initialize(species,level,player=nil,withMoves=true)
    dynamax_initialize(species,level,player,withMoves)
    @dynamax     ||= false
    @dynamax_lvl ||= 0
    @gmaxfactor  ||= false
    @max_ace     ||= false
    @reverted    ||= false
  end
  
  # Dynamax
  def makeDynamax
    @dynamax = true
    @reverted = false
  end
  
  def makeUndynamax
    @dynamax = false
    @reverted = true
  end
  
  def isDynamax?
    return @dynamax
  end
  
  def pbReversion(revert=false)
    @reverted = true  if revert
    @reverted = false if !revert
  end
  
  def reverted?
    return @reverted
  end
  
  def hasGigantamax?
    return @gigantamax
  end
  
  def dynamax_lvl
    return @dynamax_lvl || 0
  end
  
  def giveGMaxFactor
    @gmaxfactor = true
  end
  
  def removeGMaxFactor
    @gmaxfactor = false
  end
  
  def gmaxFactor?
    return @gmaxfactor 
  end
end

ItemHandlers::UseOnPokemon.add(:DYNAMAXCANDY,proc { |item,pkmn,scene|
  if pkmn.dynamax_lvl>=10 || (pkmn.species==PBSpecies::ZACIAN) ||
                             (pkmn.species==PBSpecies::ZAMAZENTA) || 
                             (pkmn.species==PBSpecies::ETERNATUS)
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
  pkmn.dynamax_lvl+=1
  pbSEPlay("Pkmn move learnt")
  scene.pbDisplay(_INTL("¡El nivel Dinamax de {1} ha aumentado 1 punto!",pkmn.name))
  scene.pbHardRefresh
  next true
})

ItemHandlers::UseOnPokemon.add(:MAXMUSHROOMS,proc { |item,pkmn,scene|
  if !pkmn.hasGigantamaxForm?
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
  if !pkmn.gmaxFactor?
    pkmn.giveGMaxFactor
    pbSEPlay("Pkmn move learnt")
    scene.pbDisplay(_INTL("¡Ahora {1} puede gigamaxizarse!",pkmn.name))
  else
    pkmn.removeGMaxFactor
    pbSEPlay("Pkmn move learnt")
    scene.pbDisplay(_INTL("¡Ahora {1} puede dinamaxizarse!",pkmn.name))
  end
  scene.pbHardRefresh
  next true
})

class PokeBattle_Pokemon
  def hasGigantamaxForm?
    v=MultipleForms.call("getGigantamaxForm",self)
    return v!=nil
  end

  def isGigantamax?
    v=MultipleForms.call("getGigantamaxForm",self)
    return v!=nil && v==@form && @gigantamax
  end

  def makeGigantamax
    v=MultipleForms.call("getGigantamaxForm",self)
    if v!=nil
      self.form=v
      @gigantamax=true
    end
  end

  def makeUngigantamax
    if @gigantamax
      v=MultipleForms.call("getUngigantamaxForm",self)
      if v!=nil
        self.form=v
      else
        self.form=0
      end
      @gigantamax=false
    end
  end
  
  def makeUnmax
    if @dynamax
      makeUndynamax
      if @gigantamax
        makeUngigantamax
      end
    end
  end
  

end


MultipleForms.add(:CHARIZARD,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:VENUSAUR,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:BLASTOISE,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

# Ejemplo: Pikachu Gigantamax
MultipleForms.add(:PIKACHU,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

# Ejemplo: Meowth Gigantamax
MultipleForms.add(:MEOWTH,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30 if pokemon.form==0
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

# Ejemplo: Butterfree Gigantamax
MultipleForms.add(:BUTTERFREE,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

# Ejemplo: Machamp Gigantamax
MultipleForms.add(:MACHAMP,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:GENGAR,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:KINGLER,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:LAPRAS,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:EEVEE,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:SNORLAX,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:GARBORDOR,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:MELMETAL,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:RILLABOOM,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:CINDERACE,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:INTELLEON,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:CORVIKNIGHT,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:ORBEETLE,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:DREDNAW,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:COALOSSAL,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:FLAPPLE,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:APPLETUN,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:SANDACONDA,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:TOXTRICITY,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:CENTISKORCH,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:GRIMMSNARL,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:HATTERENE,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:ALCREMIE,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

MultipleForms.add(:COPPERAJAH,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})


MultipleForms.add(:DURALUDON,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})


MultipleForms.add(:URSHIFU,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30 if pokemon.form==0
    next 31
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
    next 1 if pokemon.form==31
  }
})


MultipleForms.add(:ETERNATUS,{
  "getGigantamaxForm"=>proc{|pokemon|
    next 30
    next
  },
  "getUngigantamaxForm"=>proc{|pokemon|
    next 0
  }
})

Events.onWildPokemonCreate+=proc {|sender,e|
   pokemon=e[0]
  pokemon.max_ace=true if $PokemonTemp.battle_rules["wildDynamax"]
  if $PokemonTemp.battle_rules["wildGigamaxFactor"]
    pokemon.giveGMaxFactor if pokemon.hasGigantamaxForm?
  end
}