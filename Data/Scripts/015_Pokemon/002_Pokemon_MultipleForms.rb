class PokeBattle_Pokemon
  attr_accessor(:formTime)   # Hora cuando Furfrou/Hoopa cambió del forma

  def form
    return @forcedform if @forcedform!=nil
    v=MultipleForms.call("getForm",self)
    if v!=nil
      self.form=v if !@form || v!=@form
      return v
    end
    return @form || 0
  end

  def form=(value)
    @form=value
    MultipleForms.call("onSetForm",self,value)
    self.calcStats
    pbSeenForm(self)
  end

  def hasUltraForm?
    v=MultipleForms.call("getUltraForm",self)
    return v!=nil
  end

  def isUltra?
    v=MultipleForms.call("getUltraForm",self)
    return v!=nil && v==@form
  end

  def makeUltra
    v=MultipleForms.call("getUltraForm",self)
    if v!=nil
      @startform=self.form
      self.form=v
    end
  end

  def ultraName
    v=MultipleForms.call("getUltraName",self)
    return v if v!=nil
    return ""
  end

  def formNoCall=(value)
    @form=value
    self.calcStats
  end

  def forceForm(value)   # Usado solamente en el Pokédex
    @forcedform=value
  end

  alias __mf_baseStats baseStats
  alias __mf_ability ability
  alias __mf_getAbilityList getAbilityList
  alias __mf_type1 type1
  alias __mf_type2 type2
  alias __mf_height height
  alias __mf_weight weight
  alias __mf_getMoveList getMoveList
  alias __mf_isCompatibleWithMove? isCompatibleWithMove?
  alias __mf_wildHoldItems wildHoldItems
  alias __mf_baseExp baseExp
  alias __mf_evYield evYield
  alias __mf_kind kind
  alias __mf_dexEntry dexEntry
  alias __mf_initialize initialize

  def baseStats
    v=MultipleForms.call("getBaseStats",self)
    return v if v!=nil
    return self.__mf_baseStats
  end

  def ability   # OBSOLETO - no usar
    v=MultipleForms.call("ability",self)
    return v if v!=nil
    return self.__mf_ability
  end

  def getAbilityList
    v=MultipleForms.call("getAbilityList",self)
    return v if v!=nil && v.length>0
    return self.__mf_getAbilityList
  end

  def type1
   return self.teratype if self.isTera?
   v=MultipleForms.call("type1",self)
   return v if v!=nil
   return self.__mf_type1
 end

 def type2
   return self.teratype if self.isTera?
   v=MultipleForms.call("type2",self)
   return v if v!=nil
   return self.__mf_type2
 end

  def height
    v=MultipleForms.call("height",self)
    return v if v!=nil
    return self.__mf_height
  end

  def weight
    v=MultipleForms.call("weight",self)
    return v if v!=nil
    return self.__mf_weight
  end

  def getMoveList
    v=MultipleForms.call("getMoveList",self)
    return v if v!=nil
    return self.__mf_getMoveList
  end

  def isCompatibleWithMove?(move)
    v=MultipleForms.call("getMoveCompatibility",self)
    if v!=nil
      return v.any? {|j| j==move }
    end
    return self.__mf_isCompatibleWithMove?(move)
  end

  def wildHoldItems
    v=MultipleForms.call("wildHoldItems",self)
    return v if v!=nil
    return self.__mf_wildHoldItems
  end

  def baseExp
    v=MultipleForms.call("baseExp",self)
    return v if v!=nil
    return self.__mf_baseExp
  end

  def evYield
    v=MultipleForms.call("evYield",self)
    return v if v!=nil
    return self.__mf_evYield
  end

  def kind
    v=MultipleForms.call("kind",self)
    return v if v!=nil
    return self.__mf_kind
  end

  def dexEntry
    v=MultipleForms.call("dexEntry",self)
    return v if v!=nil
    return self.__mf_dexEntry
  end

  def initialize(*args)
    __mf_initialize(*args)
    f=MultipleForms.call("getFormOnCreation",self)
    if f
      self.form=f
      self.resetMoves
    end
  end
end

class PokeBattle_RealBattlePeer
  def pbOnEnteringBattle(battle,pokemon)
    f=MultipleForms.call("getFormOnEnteringBattle",pokemon)
    if f
      pokemon.form=f
    end
  end
end



module MultipleForms
  @@formSpecies=HandlerHash.new(:PBSpecies)

  def self.copy(sym,*syms)
    @@formSpecies.copy(sym,*syms)
  end

  def self.register(sym,hash)
    @@formSpecies.add(sym,hash)
  end

  def self.registerIf(cond,hash)
    @@formSpecies.addIf(cond,hash)
  end

  def self.hasFunction?(pokemon,func)
    spec=(pokemon.is_a?(Numeric)) ? pokemon : pokemon.species
    sp=@@formSpecies[spec]
    return sp && sp[func]
  end

  def self.getFunction(pokemon,func)
    spec=(pokemon.is_a?(Numeric)) ? pokemon : pokemon.species
    sp=@@formSpecies[spec]
    return (sp && sp[func]) ? sp[func] : nil
  end

  def self.call(func,pokemon,*args)
    sp=@@formSpecies[pokemon.species]
    return nil if !sp || !sp[func]
    return sp[func].call(pokemon,*args)
  end
end



def drawSpot(bitmap,spotpattern,x,y,red,green,blue)
  height=spotpattern.length
  width=spotpattern[0].length
  for yy in 0...height
    spot=spotpattern[yy]
    for xx in 0...width
      if spot[xx]==1
        xOrg=(x+xx)<<1
        yOrg=(y+yy)<<1
        color=bitmap.get_pixel(xOrg,yOrg)
        r=color.red+red
        g=color.green+green
        b=color.blue+blue
        color.red=[[r,0].max,255].min
        color.green=[[g,0].max,255].min
        color.blue=[[b,0].max,255].min
        bitmap.set_pixel(xOrg,yOrg,color)
        bitmap.set_pixel(xOrg+1,yOrg,color)
        bitmap.set_pixel(xOrg,yOrg+1,color)
        bitmap.set_pixel(xOrg+1,yOrg+1,color)
       end
    end
  end
end

def pbSpindaSpots(pokemon,bitmap)
  spot1=[
     [0,0,1,1,1,1,0,0],
     [0,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [0,1,1,1,1,1,1,0],
     [0,0,1,1,1,1,0,0]
  ]
  spot2=[
     [0,0,1,1,1,0,0],
     [0,1,1,1,1,1,0],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [0,1,1,1,1,1,0],
     [0,0,1,1,1,0,0]
  ]
  spot3=[
     [0,0,0,0,0,1,1,1,1,0,0,0,0],
     [0,0,0,1,1,1,1,1,1,1,0,0,0],
     [0,0,1,1,1,1,1,1,1,1,1,0,0],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1,1],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [0,0,1,1,1,1,1,1,1,1,1,0,0],
     [0,0,0,1,1,1,1,1,1,1,0,0,0],
     [0,0,0,0,0,1,1,1,0,0,0,0,0]
  ]
  spot4=[
     [0,0,0,0,1,1,1,0,0,0,0,0],
     [0,0,1,1,1,1,1,1,1,0,0,0],
     [0,1,1,1,1,1,1,1,1,1,0,0],
     [0,1,1,1,1,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,0],
     [0,1,1,1,1,1,1,1,1,1,1,0],
     [0,0,1,1,1,1,1,1,1,1,0,0],
     [0,0,0,0,1,1,1,1,1,0,0,0]
  ]
  id=pokemon.personalID
  h=(id>>28)&15
  g=(id>>24)&15
  f=(id>>20)&15
  e=(id>>16)&15
  d=(id>>12)&15
  c=(id>>8)&15
  b=(id>>4)&15
  a=(id)&15
  if pokemon.isShiny?
    drawSpot(bitmap,spot1,b+33,a+25,-75,-10,-150)
    drawSpot(bitmap,spot2,d+21,c+24,-75,-10,-150)
    drawSpot(bitmap,spot3,f+39,e+7,-75,-10,-150)
    drawSpot(bitmap,spot4,h+15,g+6,-75,-10,-150)
  else
    drawSpot(bitmap,spot1,b+33,a+25,0,-115,-75)
    drawSpot(bitmap,spot2,d+21,c+24,0,-115,-75)
    drawSpot(bitmap,spot3,f+39,e+7,0,-115,-75)
    drawSpot(bitmap,spot4,h+15,g+6,0,-115,-75)
  end
end

################################################################################

# UNOWN

MultipleForms.register(:UNOWN,{
"getFormOnCreation"=>proc{|pokemon|
   next rand(28)
}
})

# SPINDA

MultipleForms.register(:SPINDA,{
"alterBitmap"=>proc{|pokemon,bitmap|
   pbSpindaSpots(pokemon,bitmap)
}
})

# CASTFORM

MultipleForms.register(:CASTFORM,{
"type1"=>proc{|pokemon|
   next if pokemon.form==0            # Forma Normal
   case pokemon.form
   when 1; next getID(PBTypes,:FIRE)  # Forma Sol
   when 2; next getID(PBTypes,:WATER) # Forma Lluvia
   when 3; next getID(PBTypes,:ICE)   # Forma Nieve
   end
},
"type2"=>proc{|pokemon|
   next if pokemon.form==0            # Forma Normal
   case pokemon.form
   when 1; next getID(PBTypes,:FIRE)  # Forma Sol
   when 2; next getID(PBTypes,:WATER) # Forma Lluvia
   when 3; next getID(PBTypes,:ICE)   # Forma Nieve
   end
}
})

# DEOXYS

MultipleForms.register(:DEOXYS,{
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0               # Forma Normal
   case pokemon.form
   when 1; next [50,180, 20,150,180, 20] # Forma Ataque
   when 2; next [50, 70,160, 90, 70,160] # Forma Defensa
   when 3; next [50, 95, 90,180, 95, 90] # Forma Velocidad
   end
},
"evYield"=>proc{|pokemon|
   next if pokemon.form==0    # Forma Normal
   case pokemon.form
   when 1; next [0,2,0,0,1,0] # Forma Ataque
   when 2; next [0,0,2,0,0,1] # Forma Defensa
   when 3; next [0,0,0,3,0,0] # Forma Velocidad
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:LEER],[1,:WRAP],[9,:NIGHTSHADE],[17,:TELEPORT],
                     [25,:TAUNT],[33,:PURSUIT],[41,:PSYCHIC],[49,:SUPERPOWER],
                     [57,:PSYCHOSHIFT],[65,:ZENHEADBUTT],[73,:COSMICPOWER],
                     [81,:ZAPCANNON],[89,:PSYCHOBOOST],[97,:HYPERBEAM]]
   when 2; movelist=[[1,:LEER],[1,:WRAP],[9,:NIGHTSHADE],[17,:TELEPORT],
                     [25,:KNOCKOFF],[33,:SPIKES],[41,:PSYCHIC],[49,:SNATCH],
                     [57,:PSYCHOSHIFT],[65,:ZENHEADBUTT],[73,:IRONDEFENSE],
                     [73,:AMNESIA],[81,:RECOVER],[89,:PSYCHOBOOST],
                     [97,:COUNTER],[97,:MIRRORCOAT]]
   when 3; movelist=[[1,:LEER],[1,:WRAP],[9,:NIGHTSHADE],[17,:DOUBLETEAM],
                     [25,:KNOCKOFF],[33,:PURSUIT],[41,:PSYCHIC],[49,:SWIFT],
                     [57,:PSYCHOSHIFT],[65,:ZENHEADBUTT],[73,:AGILITY],
                     [81,:RECOVER],[89,:PSYCHOBOOST],[97,:EXTREMESPEED]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# BURMY

MultipleForms.register(:BURMY,{
"getFormOnCreation"=>proc{|pokemon|
   env=pbGetEnvironment()
   if !pbGetMetadata($game_map.map_id,MetadataOutdoor)
     next 2 # Trash Cloak
   elsif env==PBEnvironment::Sand ||
         env==PBEnvironment::Rock ||
         env==PBEnvironment::Cave
     next 1 # Sandy Cloak
   else
     next 0 # Plant Cloak
   end
},
"getFormOnEnteringBattle"=>proc{|pokemon|
   env=pbGetEnvironment()
   if !pbGetMetadata($game_map.map_id,MetadataOutdoor)
     next 2 # Trash Cloak
   elsif env==PBEnvironment::Sand ||
         env==PBEnvironment::Rock ||
         env==PBEnvironment::Cave
     next 1 # Sandy Cloak
   else
     next 0 # Plant Cloak
   end
}
})

# WORMADAM

MultipleForms.register(:WORMADAM,{
"getFormOnCreation"=>proc{|pokemon|
   env=pbGetEnvironment()
   if !pbGetMetadata($game_map.map_id,MetadataOutdoor)
     next 2 # Trash Cloak
   elsif env==PBEnvironment::Sand || env==PBEnvironment::Rock ||
      env==PBEnvironment::Cave
     next 1 # Sandy Cloak
   else
     next 0 # Plant Cloak
   end
},
"type2"=>proc{|pokemon|
   next if pokemon.form==0             # Tronco Planta
   case pokemon.form
   when 1; next getID(PBTypes,:GROUND) # Tronco Arena
   when 2; next getID(PBTypes,:STEEL)  # Tronco Basura
   end
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0            # Tronco Planta
   case pokemon.form
   when 1; next [60,79,105,36,59, 85] # Tronco Arena
   when 2; next [60,69, 95,36,69, 95] # Tronco Basura
   end
},
"evYield"=>proc{|pokemon|
   next if pokemon.form==0    # Tronco Planta
   case pokemon.form
   when 1; next [0,0,2,0,0,0] # Tronco Arena
   when 2; next [0,0,1,0,0,1] # Tronco Basura
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[0,:QUIVERDANCE],[1,:QUIVERDANCE],[1,:SUCKERPUNCH],[1,:PROTECT],[1,:BUGBITE],[1,:TACKLE],[10,:PROTECT],[15,:BUGBITE],[20,:HIDDENPOWER],
                     [23,:CONFUSION],[26,:ROCKBLAST],[29,:HARDEN],[32,:PSYBEAM],
                     [35,:CAPTIVATE],[38,:FLAIL],[41,:ATTRACT],[44,:PSYCHIC],
                     [47,:FISSURE],[50,:BUGBUZZ]]
   when 2; movelist=[[0,:QUIVERDANCE],[1,:QUIVERDANCE],[1,:METALBURST],[1,:SUCKERPUNCH],[1,:PROTECT],[1,:BUGBITE],[1,:TACKLE],[10,:PROTECT],[15,:BUGBITE],[20,:HIDDENPOWER],
                     [23,:CONFUSION],[26,:MIRRORSHOT],[29,:METALSOUND],
                     [32,:PSYBEAM],[35,:CAPTIVATE],[38,:FLAIL],[41,:ATTRACT],
                     [44,:PSYCHIC],[47,:IRONHEAD],[50,:BUGBUZZ]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs y tutores
                     :ALLYSWITCH,:ATTRACT,:BUGBITE,:BUGBUZZ,:BULLDOZE,:CONFIDE,
                     :DIG,:DOUBLETEAM,:DREAMEATER,:EARTHPOWER,:EARTHQUAKE,
                     :ELECTROWEB,:ENDEAVOR,:FACADE,:FLASH,:FRUSTRATION,:GIGAIMPACT,
                     :HIDDENPOWER,:HYPERBEAM,:INFESTATION,:PROTECT,:PSYCHUP,:PSYCHIC,
                     :RAINDANCE,:REST,:RETURN,:ROCKBLAST,:ROCKTOMB,:ROUND,:SAFEGUARD,
                     :SANDSTORM,:SECRETPOWER,:SHADOWBALL,:SIGNALBEAM,:SKILLSWAP,
                     :SLEEPTALK,:SNORE,:STEALTHROCK,:STRUGGLEBUG,:SUBSTITUTE,:SUNNYDAY,
                     :SWAGGER,:TELEKINESIS,:THIEF,:TOXIC,:UPROAR,:VENOSHOCK]
   when 2; movelist=[# MTs y tutores
                     :ALLYSWITCH,:ATTRACT,:BUGBITE,:BUGBUZZ,:FLASHCANNON,:CONFIDE,
                     :GUNKSHOT,:DOUBLETEAM,:DREAMEATER,:GYROBALL,:IRONDEFENSE,
                     :ELECTROWEB,:ENDEAVOR,:FACADE,:FLASH,:FRUSTRATION,:GIGAIMPACT,
                     :HIDDENPOWER,:HYPERBEAM,:INFESTATION,:PROTECT,:PSYCHUP,:PSYCHIC,
                     :RAINDANCE,:REST,:RETURN,:IRONHEAD,:ROUND,:SAFEGUARD,
                     :SECRETPOWER,:SHADOWBALL,:SIGNALBEAM,:SKILLSWAP,
                     :SLEEPTALK,:SNORE,:STEALTHROCK,:STRUGGLEBUG,:SUBSTITUTE,:SUNNYDAY,
                     :SWAGGER,:TELEKINESIS,:THIEF,:TOXIC,:UPROAR,:VENOSHOCK]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SHELLOS

MultipleForms.register(:SHELLOS,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[138]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
}
})

# GASTRODON

MultipleForms.copy(:SHELLOS,:GASTRODON)

# ROTOM

MultipleForms.register(:ROTOM,{
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0     # Forma Normal
   next [50,65,107,86,105,107] # Todas las formas alternativas
},
"type2"=>proc{|pokemon|
   next if pokemon.form==0             # Forma Normal
   case pokemon.form
   when 1; next getID(PBTypes,:FIRE)   # Calor, Microondas
   when 2; next getID(PBTypes,:WATER)  # Lavado, Lavadora
   when 3; next getID(PBTypes,:ICE)    # Frío, Refrigerador
   when 4; next getID(PBTypes,:FLYING) # Ventilador
   when 5; next getID(PBTypes,:GRASS)  # Corte, Cortacésped
   end
},
"onSetForm"=>proc{|pokemon,form|
   moves=[
      :OVERHEAT,  # Calor, Microondas
      :HYDROPUMP, # Lavado, Lavadora
      :BLIZZARD,  # Frío, Refrigerador
      :AIRSLASH,  # Ventilador
      :LEAFSTORM  # Corte, Cortacésped
   ]
   hasoldmove=-1
   for i in 0...4
     for j in 0...moves.length
       if isConst?(pokemon.moves[i].id,PBMoves,moves[j])
         hasoldmove=i; break
       end
     end
     break if hasoldmove>=0
   end
   if form>0
     newmove=moves[form-1]
     if newmove!=nil && hasConst?(PBMoves,newmove)
       if hasoldmove>=0
         # Remplaza automáticamente el movimiento especial de la forma vieja con el nuevo
         oldmovename=PBMoves.getName(pokemon.moves[hasoldmove].id)
         newmovename=PBMoves.getName(getID(PBMoves,newmove))
         pokemon.moves[hasoldmove]=PBMove.new(getID(PBMoves,newmove))
         Kernel.pbMessage(_INTL("\\se[]1,\\wt[4] 2,\\wt[4] y...\\wt[8] ...\\wt[8] ...\\wt[8] ¡Puf!\\se[balldrop]\1"))
         Kernel.pbMessage(_INTL("{1} ha olvidado cómo\r\nusar {2}.\1",pokemon.name,oldmovename))
         Kernel.pbMessage(_INTL("Y...\1"))
         Kernel.pbMessage(_INTL("\\se[]¡{1} ha aprendido {2}!\\se[MoveLearnt]",pokemon.name,newmovename))
       else
         # Intenta aprender el nuevo movimiento especial de esta forma
         pbLearnMove(pokemon,getID(PBMoves,newmove),true)
       end
     end
   else
     if hasoldmove>=0
       # Olvida el movimiento especial de la forma vieja
       oldmovename=PBMoves.getName(pokemon.moves[hasoldmove].id)
       pokemon.pbDeleteMoveAtIndex(hasoldmove)
       Kernel.pbMessage(_INTL("{1} ha olvidado {2}...",pokemon.name,oldmovename))
       if pokemon.moves.find_all{|i| i.id!=0}.length==0
         pbLearnMove(pokemon,getID(PBMoves,:THUNDERSHOCK))
       end
     end
   end
}
})

# DIALGA

MultipleForms.register(:DIALGA,{
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                  # Forma Modificada
   next [[getID(PBAbilities,:PRESSURE),0],
         [getID(PBAbilities,:TELEPATHY),2]] # Forma Origen
},
"height"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Modificada
   next 70                 # Forma Origen
},
"weight"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Modificada
   next 8500               # Forma Origen
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0       # Forma Modificada
   next [100,100,120,90,150,120] # Forma Origen
},
"getForm"=>proc{|pokemon|
   if isConst?(pokemon.item,PBItems,:LUSTROUSORB)
     next 1
   end
   next 0
}
})

# PALKIA
MultipleForms.register(:PALKIA,{
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                  # Forma Modificada
   next [[getID(PBAbilities,:PRESSURE),0],
         [getID(PBAbilities,:TELEPATHY),2]] # Forma Origen
},
"height"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Modificada
   next 63                 # Forma Origen
},
"weight"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Modificada
   next 6600               # Forma Origen
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0       # Forma Modificada
   next [90,100,100,120,150,120] # Forma Origen
},
"getForm"=>proc{|pokemon|
   if isConst?(pokemon.item,PBItems,:LUSTROUSORB)
     next 1
   end
   next 0
}
})

# GIRATINA
MultipleForms.register(:GIRATINA,{
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                  # Forma Modificada
   next [[getID(PBAbilities,:LEVITATE),0],
         [getID(PBAbilities,:TELEPATHY),2]] # Forma Origen
},
"height"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Modificada
   next 69                 # Forma Origen
},
"weight"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Modificada
   next 6500               # Forma Origen
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0       # Forma Modificada
   next [150,120,100,90,120,100] # Forma Origen
},
"getForm"=>proc{|pokemon|
   maps=[49,50,51,72,73]   # IDs de los mapas para la Forma Origen
   if isConst?(pokemon.item,PBItems,:GRISEOUSORB) ||
      ($game_map && maps.include?($game_map.map_id))
     next 1
   end
   next 0
}
})

# SHAYMIN

MultipleForms.register(:SHAYMIN,{
"type2"=>proc{|pokemon|
   next if pokemon.form==0     # Forma Tierra
   next getID(PBTypes,:FLYING) # Forma Cielo
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    # Forma Tierra
   next [[getID(PBAbilities,:SERENEGRACE),0]] # Forma Cielo
},
"height"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Tierra
   next 69                 # Forma Cielo
},
"weight"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Tierra
   next 4                  # Forma Cielo
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0      # Forma Tierra
   next [100,103,75,127,120,75] # Forma Cielo
},
"evYield"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Tierra
   next [0,0,0,3,0,0]      # Forma Cielo
},
"getForm"=>proc{|pokemon|
   next 0 if pokemon.hp<=0 || pokemon.status==PBStatuses::FROZEN ||
             PBDayNight.isNight?
   next nil
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:GROWTH],[10,:MAGICALLEAF],[19,:LEECHSEED],
                     [28,:QUICKATTACK],[37,:SWEETSCENT],[46,:NATURALGIFT],
                     [55,:WORRYSEED],[64,:AIRSLASH],[73,:ENERGYBALL],
                     [82,:SWEETKISS],[91,:LEAFSTORM],[100,:SEEDFLARE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# ARCEUS

MultipleForms.register(:ARCEUS,{
"type1"=>proc{|pokemon|
   types=[:NORMAL,:FIGHTING,:FLYING,:POISON,:GROUND,
          :ROCK,:BUG,:GHOST,:STEEL,:QMARKS,
          :FIRE,:WATER,:GRASS,:ELECTRIC,:PSYCHIC,
          :ICE,:DRAGON,:DARK,:FAIRY]
   next getID(PBTypes,types[pokemon.form])
},
"type2"=>proc{|pokemon|
   types=[:NORMAL,:FIGHTING,:FLYING,:POISON,:GROUND,
          :ROCK,:BUG,:GHOST,:STEEL,:QMARKS,
          :FIRE,:WATER,:GRASS,:ELECTRIC,:PSYCHIC,
          :ICE,:DRAGON,:DARK,:FAIRY]
   next getID(PBTypes,types[pokemon.form])
},
"getForm"=>proc{|pokemon|
   next 1  if isConst?(pokemon.item,PBItems,:FISTPLATE)
   next 2  if isConst?(pokemon.item,PBItems,:SKYPLATE)
   next 3  if isConst?(pokemon.item,PBItems,:TOXICPLATE)
   next 4  if isConst?(pokemon.item,PBItems,:EARTHPLATE)
   next 5  if isConst?(pokemon.item,PBItems,:STONEPLATE)
   next 6  if isConst?(pokemon.item,PBItems,:INSECTPLATE)
   next 7  if isConst?(pokemon.item,PBItems,:SPOOKYPLATE)
   next 8  if isConst?(pokemon.item,PBItems,:IRONPLATE)
   next 10 if isConst?(pokemon.item,PBItems,:FLAMEPLATE)
   next 11 if isConst?(pokemon.item,PBItems,:SPLASHPLATE)
   next 12 if isConst?(pokemon.item,PBItems,:MEADOWPLATE)
   next 13 if isConst?(pokemon.item,PBItems,:ZAPPLATE)
   next 14 if isConst?(pokemon.item,PBItems,:MINDPLATE)
   next 15 if isConst?(pokemon.item,PBItems,:ICICLEPLATE)
   next 16 if isConst?(pokemon.item,PBItems,:DRACOPLATE)
   next 17 if isConst?(pokemon.item,PBItems,:DREADPLATE)
   next 18 if isConst?(pokemon.item,PBItems,:PIXIEPLATE)
   next 0
}
})

# BASCULIN

MultipleForms.register(:BASCULIN,{
"getFormOnCreation"=>proc{|pokemon|
   maps1=[32]   # Map IDs para Raya Azul
   maps2=[33]   # Map IDs para Raya Blanca
   if $game_map && maps1.include?($game_map.map_id)
     next 1
   elsif $game_map && maps2.include?($game_map.map_id)
     next 2
   else
     next 0
   end
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:ROCKHEAD),0],[getID(PBAbilities,:ADAPTABILITY),1],[getID(PBAbilities,:MOLDBREAKER),2]] # Raya Azul
   when 2; next [[getID(PBAbilities,:RATTLED),0],[getID(PBAbilities,:ADAPTABILITY),1],[getID(PBAbilities,:MOLDBREAKER),2]] # Raya Blanca
   else;   next
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   next if pokemon.form==1
   movelist=[]
   case pokemon.form
   when 2; movelist=[[1,:WATERGUN],[1,:TAILWHIP],[4,:TACKLE],[8,:FLAIL],
                     [12,:AQUAJET],[16,:BITE],[20,:SCARYFACE],[24,:HEADBUTT],
                     [28,:SOAK],[32,:CRUNCH],[36,:TAKEDOWN],[40,:UPROAR],
                     [44,:WAVECRASH],[48,:THRASH],[52,:DOUBLEEDGE],[56,:HEADSMASH]
                    ]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :AGILITY,:BLIZZARD,:CHILLINGWATER,:CRUNCH,:DOUBLEEDGE,
                     :ENDEAVOR,:ENDURE,:FACADE,:FLIPTURN,:HYDROPUMP,:ICEBEAM,
                     :ICEFANG,:ICYWIND,:LIQUIDATION,:MUDDYWATER,:MUDSHOT,
                     :PROTECT,:PSYCHICFANGS,:RAINDANCE,:REST,:SCALESHOT,
                     :SCARYFACE,:SLEEPTALK,:SNOWSCAPE,:SUBSTITUTE,:SURF,:SWIFT,
                     :TAKEDOWN,:UPROAR,:WATERFALL,:WATERPULSE,:WHIRLPOOL,
                     :ZENHEADBUTT
                    ]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# DEERLING

MultipleForms.register(:DEERLING,{
"getForm"=>proc{|pokemon|
   next pbGetSeason
}
})

# SAWSBUCK

MultipleForms.copy(:DEERLING,:SAWSBUCK)

# TORNADUS

MultipleForms.register(:TORNADUS,{
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0     # Forma Avatar
   next [79,100,80,121,110,90] # Forma Tótem
},
"height"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Avatar
   next 14                 # Forma Tótem
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    # Forma Avatar
   next [[getID(PBAbilities,:REGENERATOR),0],
         [getID(PBAbilities,:REGENERATOR),2]]     # Forma Tótem
},
"evYield"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Avatar
   next [0,0,0,3,0,0]      # Forma Tótem
}
})

# THUNDURUS

MultipleForms.register(:THUNDURUS,{
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0     # Forma Avatar
   next [79,105,70,101,145,80] # Forma Tótem
},
"height"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Avatar
   next 30                 # Forma Tótem
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                   # Forma Avatar
   next [[getID(PBAbilities,:VOLTABSORB),0],
         [getID(PBAbilities,:VOLTABSORB),2]]    # Forma Tótem
},
"evYield"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Avatar
   next [0,0,0,0,3,0]      # Forma Tótem
}
})

# LANDORUS

MultipleForms.register(:LANDORUS,{
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0    # Forma Avatar
   next [89,145,90,71,105,80] # Forma Tótem
},
"height"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Avatar
   next 13                 # Forma Tótem
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                   # Forma Avatar
   next [[getID(PBAbilities,:INTIMIDATE),0],
         [getID(PBAbilities,:INTIMIDATE),2]] # Forma Tótem
},
"evYield"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Avatar
   next [0,3,0,0,0,0]      # Forma Tótem
}
})

# ENAMORUS

MultipleForms.register(:ENAMORUS,{
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0      # Forma Avatar
   next [74,115,110,46,135,100] # Forma Tótem
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                   # Forma Avatar
   next [[getID(PBAbilities,:OVERCOAT),0],
         [getID(PBAbilities,:OVERCOAT),2]] # Forma Tótem
}
})

# KYUREM
MultipleForms.register(:KYUREM,{
"getBaseStats"=>proc{|pokemon|
   case pokemon.form
   when 1; next [125,120, 90,95,170,100] # Kyurem Blanco
   when 2; next [125,170,100,95,120, 90] # Kyurem Negro
   else;   next                          # Kyurem
   end
},
"height"=>proc{|pokemon|
   case pokemon.form
   when 1; next 36 # White Kyurem
   when 2; next 33 # Black Kyurem
   else;   next    # Kyurem
   end
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:TURBOBLAZE),0]] # Kyurem Blanco
   when 2; next [[getID(PBAbilities,:TERAVOLT),0]]   # Kyurem Negro
   else;   next                                      # Kyurem
   end
},
"evYield"=>proc{|pokemon|
   case pokemon.form
   when 1; next [0,0,0,0,3,0] # Kyurem Blanco
   when 2; next [0,3,0,0,0,0] # Kyurem Negro
   else;   next               # Kyurem
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:ICYWIND],[1,:DRAGONRAGE],[8,:IMPRISON],
                     [15,:ANCIENTPOWER],[22,:ICEBEAM],[29,:DRAGONBREATH],
                     [36,:SLASH],[43,:FUSIONFLARE],[50,:ICEBURN],
                     [57,:DRAGONPULSE],[64,:IMPRISON],[71,:ENDEAVOR],
                     [78,:BLIZZARD],[85,:OUTRAGE],[92,:HYPERVOICE]]
   when 2; movelist=[[1,:ICYWIND],[1,:DRAGONRAGE],[8,:IMPRISON],
                     [15,:ANCIENTPOWER],[22,:ICEBEAM],[29,:DRAGONBREATH],
                     [36,:SLASH],[43,:FUSIONBOLT],[50,:FREEZESHOCK],
                     [57,:DRAGONPULSE],[64,:IMPRISON],[71,:ENDEAVOR],
                     [78,:BLIZZARD],[85,:OUTRAGE],[92,:HYPERVOICE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# KELDEO
MultipleForms.register(:KELDEO,{
"getForm"=>proc{|pokemon|
   next 1 if pokemon.hasMove?(:SECRETSWORD) # Forma Brío
   next 0                                   # Forma Normal
}
})

# MELOETTA
MultipleForms.register(:MELOETTA,{
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0     # Forma Lírica
   next [100,128,90,128,77,77] # Forma Danza
},
"type2"=>proc{|pokemon|
   next if pokemon.form==0       # Forma Lírica
   next getID(PBTypes,:FIGHTING) # Forma Danza
},
"evYield"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Lírica
   next [0,1,1,1,0,0]      # Forma Danza
}
})

# GENESECT
MultipleForms.register(:GENESECT,{
"getForm"=>proc{|pokemon|
   next 1 if isConst?(pokemon.item,PBItems,:SHOCKDRIVE)
   next 2 if isConst?(pokemon.item,PBItems,:BURNDRIVE)
   next 3 if isConst?(pokemon.item,PBItems,:CHILLDRIVE)
   next 4 if isConst?(pokemon.item,PBItems,:DOUSEDRIVE)
   next 0
}
})

# GRENINJA
MultipleForms.register(:GRENINJA,{
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0
   next [72,145,67,132,153,71]
}
})

# VIVILLON
MultipleForms.register(:SCATTERBUG,{
"getFormOnCreation"=>proc{|pokemon|
   next $Trainer.secretID%18
},
})

MultipleForms.copy(:SCATTERBUG,:SPEWPA,:VIVILLON)

# FLABEBE, FLOETTE, FLORGES
MultipleForms.register(:FLABEBE,{
"getFormOnCreation"=>proc{|pokemon|
   next rand(5)
},
})

MultipleForms.copy(:FLABEBE,:FLOETTE,:FLORGES)

# FURFROU
MultipleForms.register(:FURFROU,{
"getForm"=>proc{|pokemon|
   if !pokemon.formTime || pbGetTimeNow.to_i>pokemon.formTime.to_i+60*60*24*5 # 5 días
     next 0
   end
   next
},
"onSetForm"=>proc{|pokemon,form|
   pokemon.formTime=(form>0) ? pbGetTimeNow.to_i : nil
}
})

# MEOWSTIC
MultipleForms.register(:ESPURR,{
"getFormOnCreation"=>proc{|pokemon|
   if pokemon.isFemale?
     pokemon.form=1
   else
     pokemon.form=0
   end
}
})

MultipleForms.register(:MEOWSTIC,{
"getFormOnCreation"=>proc{|pokemon|
   if pokemon.isFemale?
     pokemon.form=1
   else
     pokemon.form=0
   end
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:KEENEYE),0],[getID(PBAbilities,:INFILTRATOR),1],[getID(PBAbilities,:COMPETITIVE),2]]
   else;   next
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:STOREDPOWER],[1,:MEFIRST],[1,:MAGICALLEAF],[1,:SCRATCH],
                        [1,:LEER],[5,:COVET],[9,:CONFUSION],[13,:LIGHTSCREEN],
                        [17,:PSYBEAM],[19,:FAKEOUT],[22,:DISARMINGVOICE],[25,:PSYSHOCK],[28,:CHARGEBEAM],
                        [31,:SHADOWBALL],[35,:EXTRASENSORY],[40,:PSYCHIC],
                        [43,:ROLEPLAY],[45,:SIGNALBEAM],[48,:SUCKERPUNCH],
                        [50,:FUTURESIGHT],[53,:STOREDPOWER]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# AEGISLASH
MultipleForms.register(:AEGISLASH,{
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0
   next [60,140,50,60,140,50]
}
})

# PUMPKABOO
MultipleForms.register(:PUMPKABOO,{
"getFormOnCreation"=>proc{|pokemon|
   next [rand(4),rand(4)].min
},
"height"=>proc{|pokemon|
   next if pokemon.form==0
   next 4 if pokemon.form==1
   next 5 if pokemon.form==2
   next 8 if pokemon.form==3
},
"weight"=>proc{|pokemon|
   next if pokemon.form==0
   next 50 if pokemon.form==1
   next 75 if pokemon.form==2
   next 150 if pokemon.form==3
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0
   next [49,66,70,51,44,55] if pokemon.form==1
   next [54,66,70,46,44,55] if pokemon.form==2
   next [59,66,70,41,44,55] if pokemon.form==3
},
"wildHoldItems"=>proc{|pokemon|
   next [getID(PBItems,:MIRACLESEED),
         getID(PBItems,:MIRACLESEED),
         getID(PBItems,:MIRACLESEED)] if pokemon.form==3
   next
}
})

# GOURGEIST
MultipleForms.register(:GOURGEIST,{
"getFormOnCreation"=>proc{|pokemon|
   next [rand(4),rand(4)].min
},
"height"=>proc{|pokemon|
   next if pokemon.form==0
   next 9 if pokemon.form==1
   next 11 if pokemon.form==2
   next 17 if pokemon.form==3
},
"weight"=>proc{|pokemon|
   next if pokemon.form==0
   next 125 if pokemon.form==1
   next 140 if pokemon.form==2
   next 390 if pokemon.form==3
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0
   next [65,90,122,84,58,75] if pokemon.form==1
   next [75,95,122,69,58,75] if pokemon.form==2
   next [85,100,122,54,58,75] if pokemon.form==3
}
})

# XERNEAS
MultipleForms.register(:XERNEAS,{
"getFormOnEnteringBattle"=>proc{|pokemon|
   next 1
}
})

# ZYGARDE
MultipleForms.register(:ZYGARDE,{
"getBaseStats"=>proc{|pokemon|
   case pokemon.form
   when 1; next [54,100,71,115,61,85]    # Zygarde-10%
   when 2; next [216,100,121,85,91,95]   # Zygarde Completo
   else;   next                          # Zygarde-50%
   end
}
})

# HOOPA
MultipleForms.register(:HOOPA,{
"getForm"=>proc{|pokemon|
   if !pokemon.formTime || pbGetTimeNow.to_i>pokemon.formTime.to_i+60*60*24*3 # 3 días
     next 0
   end
   next
},
"type2"=>proc{|pokemon|
   next if pokemon.form==0
   next getID(PBTypes,:DARK)
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0
   next [80,160,60,80,170,130]
},
"height"=>proc{|pokemon|
   next if pokemon.form==0
   next 65
},
"weight"=>proc{|pokemon|
   next if pokemon.form==0
   next 4900
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[[1,:HYPERSPACEFURY],[1,:TRICK],[1,:DESTINYBOND],[1,:ALLYSWITCH],
             [1,:CONFUSION],[6,:ASTONISH],[10,:MAGICCOAT],[15,:LIGHTSCREEN],
             [19,:PSYBEAM],[25,:SKILLSWAP],[29,:POWERSPLIT],[29,:GUARDSPLIT],
             [46,:KNOCKOFF],[50,:WONDERROOM],[50,:TRICKROOM],[55,:DARKPULSE],
             [75,:PSYCHIC],[85,:HYPERSPACEFURY]]
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"kind"=>proc{|pokemon|
   next if pokemon.form==0
   next _INTL("Djinn")
},
"onSetForm"=>proc{|pokemon,form|
   pokemon.formTime=(form>0) ? pbGetTimeNow.to_i : nil
}
})

# ORICORIO
MultipleForms.register(:ORICORIO,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[121]
   if $game_map && maps.include?($game_map.map_id)
     next 1
   maps=[122]
   elsif $game_map && maps.include?($game_map.map_id)
     next 2
   maps=[120]
   elsif $game_map && maps.include?($game_map.map_id)
     next 3
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
   next if pokemon.form==0
   case pokemon.form
   when 1; next getID(PBTypes,:ELECTRIC)
   when 2; next getID(PBTypes,:PSYCHIC)
   when 3; next getID(PBTypes,:GHOST)
   end
},
"type2"=>proc{|pokemon|
   next if pokemon.form==0
   case pokemon.form
   when 1; next getID(PBTypes,:FLYING)
   when 2; next getID(PBTypes,:FLYING)
   when 3; next getID(PBTypes,:FLYING)
   end
},
"dexEntry"=>proc{|pokemon|
   next if pokemon.form==1
   next _INTL("Forma que toma Oricorio al libar néctar amarillo. Electrifica el corazón de sus adversarios con su alegre y cálida danza.")
   next if pokemon.form==2
   next _INTL("Forma que toma Oricorio al libar néctar rosa. Con su suave contoneo de caderas, derrite el corazón de sus rivales.")
   next if pokemon.form==3
   next _INTL("Forma que toma Oricorio al libar néctar violeta. Con su refinada y elegante danza, puede enviar al otro mundo a sus enemigos en cuerpo y alma.")
}
})

MultipleForms.register(:ROCKRUFF,{
"getForm"=>proc{|pokemon|
   if PBDayNight.isEvening?
     next 2
   elsif PBDayNight.isNight?
     next 1
   else
     next 0
   end
}
})

# LYCANROC
MultipleForms.register(:LYCANROC,{
"getFormOnCreation"=>proc{|pokemon|
   if PBDayNight.isEvening?
     next 2
   elsif PBDayNight.isNight?
     next 1
   else
     next 0
   end
},
"getBaseStats"=>proc{|pokemon|
  next [85,115,75,82,55,75] if pokemon.form==1 # Forma Nocturna
  next [75,117,65,110,55,65] if pokemon.form==2 # Forma Crepuscular
  next
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:KEENEYE),0],[getID(PBAbilities,:VITALSPIRIT),1],[getID(PBAbilities,:NOGUARD),2]]
   when 2; next [[getID(PBAbilities,:TOUGHCLAWS),0]]
   else;   next
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:COUNTER],[1,:REVERSAL],[1,:TAUNT],[1,:TACKLE],[1,:LEER],
                     [4,:SANDATTACK],[7,:BITE],[12,:HOWL],[15,:ROCKTHROW],
                     [18,:ODORSLEUTH],[23,:ROCKTOMB],[26,:ROAR],[29,:STEALTHROCK],
                     [34,:ROCKSLIDE],[37,:SCARYFACE],[40,:CRUNCH],[45,:ROCKCLIMB],
                     [48,:STONEEDGE]]
   when 2; movelist=[[1,:THRASH],[1,:COUNTER],[1,:ACCELEROCK],[1,:TACKLE],[1,:LEER],
                     [4,:SANDATTACK],[7,:BITE],[12,:HOWL],[15,:ROCKTHROW],
                     [18,:ODORSLEUTH],[23,:ROCKTOMB],[26,:ROAR],[29,:STEALTHROCK],
                     [34,:ROCKSLIDE],[37,:SCARYFACE],[40,:CRUNCH],[45,:ROCKCLIMB],
                     [48,:STONEEDGE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[ # MTs Forma Nocturna
                     :ROAR,:TOXIC,:BULKUP,:HIDDENPOWER,:TAUNT,:PROTECT,:FRUSTRATION,
                     :RETURN,:BRICKBREAK,:DOUBLETEAM,:ROCKTOMB,:FACADE,:REST,:ATTRACT,
                     :ROUND,:ECHOEDVOICE,:ROCKPOLISH,:STONEEDGE,:SWORDSDANCE,:ROCKSLIDE,
                     :SWAGGER,:SLEEPTALK,:SUBSTITUTE,:SNARL,:CONFIDE,:LOWSWEEP,
                     # Movimientos Tutor Forma Nocturna
                     :COVET,:DUALCHOP,:ENDEAVOR,:FIREPUNCH,:FOCUSPUNCH,:FOULPLAY,
                     :HYPERVOICE,:IRONDEFENSE,:IRONHEAD,:IRONTAIL,:LASERFOCUS,
                     :LASTRESORT,:OUTRAGE,:SNORE,:STEALTHROCK,:STOMPINGTANTRUM,
                     :THROATCHOP,:THUNDERPUNCH,:UPROAR,:ZENHEADBUTT]
   when 2; movelist=[# MTs Forma Crepuscular
                     :ROAR,:TOXIC,:BULKUP,:HIDDENPOWER,:TAUNT,:PROTECT,:FRUSTRATION,
                     :RETURN,:BRICKBREAK,:DOUBLETEAM,:ROCKTOMB,:FACADE,:REST,:ATTRACT,
                     :ROUND,:ECHOEDVOICE,:ROCKPOLISH,:STONEEDGE,:SWORDSDANCE,:ROCKSLIDE,
                     :SWAGGER,:SLEEPTALK,:SUBSTITUTE,:SNARL,:CONFIDE,
                     # Movimientos Tutor Forma Crepuscular
                     :COVET,:DRILLRUN,:EARTHPOWER,:ENDEAVOR,:HYPERVOICE,
                     :IRONDEFENSE,:IRONHEAD,:IRONTAIL,:LASTRESORT,:OUTRAGE,
                     :SNORE,:STEALTHROCK,:STOMPINGTANTRUM,:ZENHEADBUTT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
},
"dexEntry"=>proc{|pokemon|
   next if pokemon.form==1
   next _INTL("Si no está de acuerdo con una orden, no duda en ignorarla. No le importa salir herido con tal de derrotar al oponente.")
   next if pokemon.form==2
   next _INTL("Lycanroc evoluciona a esta forma especial cuando se expone al sol del atardecer. Parece pacifico, pero posee un gran espiritu combativo.")
}
})


# WISHIWASHI
MultipleForms.register(:WISHIWASHI,{
"height"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Solo
   next 82                 # Forma Banco
},
"weight"=>proc{|pokemon|
   next if pokemon.form==0 # Forma Solo
   next 786                # Forma Banco
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0       # Forma Solo
   next [45,140,130,30,140,135]  # Forma Banco
}
})

# SILVALLY
MultipleForms.register(:SILVALLY,{
"type1"=>proc{|pokemon|
    types=[:NORMAL,:FIGHTING,:FLYING,:POISON,:GROUND,
           :ROCK,:BUG,:GHOST,:STEEL,:QMARKS,
           :FIRE,:WATER,:GRASS,:ELECTRIC,:PSYCHIC,
           :ICE,:DRAGON,:DARK,:FAIRY]
        next getID(PBTypes,types[pokemon.form])
},
"type2"=>proc{|pokemon|
    types=[:NORMAL,:FIGHTING,:FLYING,:POISON,:GROUND,
           :ROCK,:BUG,:GHOST,:STEEL,:QMARKS,
           :FIRE,:WATER,:GRASS,:ELECTRIC,:PSYCHIC,
           :ICE,:DRAGON,:DARK,:FAIRY]
        next getID(PBTypes,types[pokemon.form])
},
"getForm"=>proc{|pokemon|
   next 1 if isConst?(pokemon.item,PBItems,:FIGHTINGMEMORY)
   next 2 if isConst?(pokemon.item,PBItems,:FLYINGMEMORY)
   next 3 if isConst?(pokemon.item,PBItems,:POISONMEMORY)
   next 4 if isConst?(pokemon.item,PBItems,:GROUNDMEMORY)
   next 5 if isConst?(pokemon.item,PBItems,:ROCKMEMORY)
   next 6 if isConst?(pokemon.item,PBItems,:BUGMEMORY)
   next 7 if isConst?(pokemon.item,PBItems,:GHOSTMEMORY)
   next 8 if isConst?(pokemon.item,PBItems,:STEELMEMORY)
   next 10 if isConst?(pokemon.item,PBItems,:FIREMEMORY)
   next 11 if isConst?(pokemon.item,PBItems,:WATERMEMORY)
   next 12 if isConst?(pokemon.item,PBItems,:GRASSMEMORY)
   next 13 if isConst?(pokemon.item,PBItems,:ELECTRICMEMORY)
   next 14 if isConst?(pokemon.item,PBItems,:PSYCHICMEMORY)
   next 15 if isConst?(pokemon.item,PBItems,:ICEMEMORY)
   next 16 if isConst?(pokemon.item,PBItems,:DRAGONMEMORY)
   next 17 if isConst?(pokemon.item,PBItems,:DARKMEMORY)
   next 18 if isConst?(pokemon.item,PBItems,:FAIRYMEMORY)
   next 0
},
"onSetForm"=>proc{|pokemon,form|
   pbSeenForm(pokemon)
}
})

# MINIOR
MultipleForms.register(:MINIOR,{
"getFormOnCreation"=>proc{|pokemon|
   next 1+rand(7)
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0               # Forma Normal
   case pokemon.form
   when 1; next [60,100,60,120,100,60] # Formas Ofensivas
   when 2; next [60,100,60,120,100,60] # Formas Ofensivas
   when 3; next [60,100,60,120,100,60] # Formas Ofensivas
   when 4; next [60,100,60,120,100,60] # Formas Ofensivas
   when 5; next [60,100,60,120,100,60] # Formas Ofensivas
   when 6; next [60,100,60,120,100,60] # Formas Ofensivas
   when 7; next [60,100,60,120,100,60] # Formas Ofensivas
   end
}
})

# NECROZMA
MultipleForms.register(:NECROZMA,{
"type2"=>proc{|pokemon|
   next if pokemon.form==0             # Forma Normal
   case pokemon.form
   when 1; next getID(PBTypes,:STEEL)  # Forma Dusk
   when 2; next getID(PBTypes,:GHOST)  # Forma Dawn
   when 3: next getID(PBTypes,:DRAGON) # Forma Ultra
   end
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                           # Forma Normal
   case pokemon.form
   when 1; next [[getID(PBAbilities,:PRISMARMOR),0]] # Forma Dusk
   when 2; next [[getID(PBAbilities,:PRISMARMOR),0]] # Forma Dawn
   when 3; next [[getID(PBAbilities,:NEUROFORCE),0]] # Forma Ultra
  end
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0              # Forma Normal
   case pokemon.form
   when 1; next [97,157,127,77,113,109] # Forma Dusk
   when 2; next [97,113,109,77,157,127] # Forma Dawn
   when 3; next [97,167,97,129,167,97]  # Forma Ultra
  end
},
"getUltraForm"=>proc{|pokemon|
   next 3 if isConst?(pokemon.item,PBItems,:ULTRANECROZIUMZ) && (pokemon.form==1 || pokemon.form==2)
   next
},
"getUltraName"=>proc{|pokemon|
   next _INTL("Ultra Necrozma") if pokemon.form==3
   next
},
"onSetForm"=>proc{|pokemon,form|
   pbSeenForm(pokemon)
      moves=[
      :CONFUSION,       # Forma Normal
      :SUNSTEELSTRIKE,  # Forma Dusk
      :MOONGEISTBEAM,   # Forma Dawn
   ]
   if form!=3
     moves.each{|move|
        pbDeleteMoveByID(pokemon,getID(PBMoves,move))
     }
     pokemon.pbLearnMove(moves[form])
   end
}
})

# TOXTRICITY
MultipleForms.register(:TOXTRICITY,{
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0
   next [[getID(PBAbilities,:PUNKROCK),0],
         [getID(PBAbilities,:MINUS),1],
         [getID(PBAbilities,:TECHNICIAN),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SPARK],[1,:EERIEIMPULSE],[1,:BELCH],[1,:TEARFULLOOK],
                     [1,:NUZZLE],[1,:GROWL],[1,:FLAIL],[1,:ACID],[1,:THUNDERSHOCK],
                     [1,:ACIDSPRAY],[1,:LEER],[1,:NOBLEROAR],[4,:CHARGE],[8,:SHOCKWAVE],
                     [12,:SCARYFACE],[16,:TAUNT],[20,:VENOMDRENCH],[24,:SCREECH],
                     [28,:SWAGGER],[32,:TOXIC],[36,:DISCHARGE],[40,:POISONJAB],
                     [44,:OVERDRIVE],[48,:BOOMBURST],[52,:MAGNETICFLUX]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :FIREPUNCH,:THUNDERPUNCH,:HYPERBEAM,:GIGAIMPACT,:THUNDERWAVE,:REST,
                     :SNORE,:ATTRACT,:PROTECT,:FACADE,:PAYBACK,:FLING,:DRAINPUNCH,
                     :ROUND,:VOLTSWITCH,:SNARL,:THUNDERBOLT,:THUNDER,:SUBSTITUTE,
                     :SLUDGEBOMB,:SLEEPTALK,:UPROAR,:TAUNT,:HYPERVOICE,:POISONJAB,
                     :GUNKSHOT,:SLUDGEWAVE,:ELECTROBALL,:STOREDPOWER,:WILDCHARGE,:THROATCHOP,
                     :RISINGVOLTAGE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# EISCUE
MultipleForms.register(:EISCUE,{
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0
   next [75,80,70,130,65,50]
}
})

# INDEEDEE
MultipleForms.register(:INDEEDEE,{
"getFormOnCreation"=>proc{|pokemon|
   if pokemon.isFemale?
     pokemon.form=1
   else
     pokemon.form=0
   end
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:OWNTEMPO),0],[getID(PBAbilities,:SYNCHRONIZE),1],[getID(PBAbilities,:PSYCHICSURGE),2]]
   else;   next
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:STOREDPOWER],[1,:PLAYNICE],[5,:BATONPASS],[10,:DISARMINGVOICE],
               [15,:PSYBEAM],[20,:HELPINGHAND],[25,:FOLLOWME],[30,:AROMATHERAPY],
               [35,:PSYCHIC],[40,:CALMMIND],[45,:GUARDSPLIT],[50,:PSYCHICTERRAIN],
               [55,:HEALINGWISH]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[:LIGHTSCREEN,:REFLECT,:SAFEGUARD,:SNORE,:REST,:PROTECT,:ATTRACT,:FACADE,
                     :HELPINGHAND,:DRAINPUNCH,:ROUND,:PSYCHIC,:SUBSTITUTE,:PSYSHOCK,
                     :SLEEPTALK,:SHADOWBALL,:TRICK,:HYPERVOICE,:CALMMIND,:ENERGYBALL,
                     :ZENHEADBUTT,:ALLYSWITCH,:DAZZLINGGLEAM,:TERRAINPULSE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# ZACIAN
MultipleForms.register(:ZACIAN,{
"getForm"=>proc{|pokemon|
   next 1 if isConst?(pokemon.item,PBItems,:RUSTEDSWORD) && $startBattle
   next 0
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [92,150,115,148,80,115] if pokemon.form==1
  next
},
"onSetForm"=>proc{|pokemon,form|
   moves=[
      :IRONHEAD,     # Forma Normal
      :BEHEMOTHBLADE # Forma Espada
   ]
   hasoldmove=-1
   for i in 0...4
     for j in 0...moves.length
       if isConst?(pokemon.moves[i].id,PBMoves,moves[j])
         hasoldmove=i; break
       end
     end
     break if hasoldmove>=0
   end
   newmove = moves[form]
   if newmove!=nil && hasConst?(PBMoves,newmove)
     if hasoldmove>=0
       oldmovepp=pokemon.moves[hasoldmove].pp
       pokemon.moves[hasoldmove]=PBMove.new(getID(PBMoves,newmove))
       pokemon.moves[hasoldmove].pp=[oldmovepp,pokemon.moves[hasoldmove].totalpp].min
     end
   end
}
})

# ZAMAZENTA
MultipleForms.register(:ZAMAZENTA,{
"getForm"=>proc{|pokemon|
   next 1 if isConst?(pokemon.item,PBItems,:RUSTEDSHIELD) && $startBattle
   next 0
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [92,120,140,128,80,140] if pokemon.form==1
  next
},
"onSetForm"=>proc{|pokemon,form|
   moves=[
      :IRONHEAD,    # Forma Normal
      :BEHEMOTHBASH # Forma Escudo
   ]
   hasoldmove=-1
   for i in 0...4
     for j in 0...moves.length
       if isConst?(pokemon.moves[i].id,PBMoves,moves[j])
         hasoldmove=i; break
       end
     end
     break if hasoldmove>=0
   end
   newmove = moves[form]
   if newmove!=nil && hasConst?(PBMoves,newmove)
     if hasoldmove>=0
       oldmovepp=pokemon.moves[hasoldmove].pp
       pokemon.moves[hasoldmove]=PBMove.new(getID(PBMoves,newmove))
       pokemon.moves[hasoldmove].pp=[oldmovepp,pokemon.moves[hasoldmove].totalpp].min
     end
   end
}
})

# URSHIFU
MultipleForms.register(:URSHIFU,{
"type2"=>proc{|pokemon|
  next getID(PBTypes,:WATER) if pokemon.form==1
  next
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SURGINGSTRIKES],[1,:AQUAJET],[1,:ROCKSMASH],[1,:LEER],
                     [1,:ENDURE],[1,:FOCUSENERGY],[12,:AERIALACE],[16,:SCARYFACE],
                     [20,:HEADBUTT],[24,:BRICKBREAK],[28,:DETECT],[32,:BULKUP],
                     [36,:IRONHEAD],[40,:DYNAMICPUNCH],[44,:COUNTER],[48,:CLOSECOMBAT],
                     [52,:FOCUSPUNCH]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :FIREPUNCH,:ICEPUNCH,:THUNDERPUNCH,:DIG,:GIGAIMPACT,:REST,:ROCKSLIDE,
                     :PROTECT,:ATTRACT,:RAINDANCE,:FACADE,:BRICKBREAK,:ROCKTOMB,:BRINE,:DIVE,
                     :DRAINPUNCH,:UTURN,:ROUND,:ACROBATICS,:RETALIATE,:FALSESWIPE,:LOWKICK,
                     :WATERFALL,:SUBSTITUTE,:SLEEPTALK,:TAUNT,:SUPERPOWER,:IRONDEFENSE,:BULKUP,
                     :AURASPHERE,:POISONJAB,:AURASPHERE,:FOCUSBLAST,:ZENHEADBUTT,:IRONHEAD,:SCALD,
                     :STONEEDGE,:WORKUP,:LIQUIDATION,:BODYPRESS]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
},
"dexEntry"=>proc{|pokemon|
   next if pokemon.form==1
   next _INTL("Su estilo de combate se inspira en el flujo del agua y consiste en castigar al oponente de forma constante e ininterrumpida.")
}
})

# CALYREX
MultipleForms.register(:CALYREX,{
"type2"=>proc{|pokemon|
   next if pokemon.form==0
   case pokemon.form
   when 1; next getID(PBTypes,:ICE)    # Calyrex Glacial
   when 2; next getID(PBTypes,:GHOST)  # Calyrex Espectral
   end
},
"getBaseStats"=>proc{|pokemon|
   case pokemon.form
   when 1; next [100,165,150,50,85,130] # Calyrex Glacial
   when 2; next [100,85,80,150,165,100] # Calyrex Espectral
   else;   next
   end
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:ASONE1),0]]   # Calyrex Glacial
   when 2; next [[getID(PBAbilities,:ASONE2),0]]   # Calyrex Espectral
   else;   next
   end
},
"onSetForm"=>proc{|pokemon,form|
   moves=[
       :GLACIALLANCE, # Jinete Glaciar (con Glastrier)
       :ASTRALBARRAGE,# Jinete Espectral (con Spectrier)
       # Both forms
       :TACKLE,:TAILWHIP,:DOUBLEKICK,:STOMP,:TAKEDOWN,:THRASH,:DOUBLEEDGE,
       :AVALANCHE,:TORMENT,:MIST,:ICICLECRASH,:IRONDEFENSE,:TAUNT,:SWORDSDANCE,
       :HEX,:CONFUSERAY,:HAZE,:SHADOWBALL,:AGILITY,:DISABLE,:NASTYPLOT
    ]
   hasoldmove=-1
   for i in 0...4
     for j in 0...moves.length
       if isConst?(pokemon.moves[i].id,PBMoves,moves[j])
         hasoldmove=i; break
       end
     end
     break if hasoldmove>=0
   end
   if form>0
     newmove=moves[form-1]
     if newmove!=nil && hasConst?(PBMoves,newmove)
       if hasoldmove>=0
         # Remplaza automáticamente el movimiento especial de la forma vieja con el nuevo
         oldmovename=PBMoves.getName(pokemon.moves[hasoldmove].id)
         newmovename=PBMoves.getName(getID(PBMoves,newmove))
         pokemon.moves[hasoldmove]=PBMove.new(getID(PBMoves,newmove))
         Kernel.pbMessage(_INTL("\\se[]1,\\wt[4] 2,\\wt[4] y...\\wt[8] ...\\wt[8] ...\\wt[8] ¡Puf!\\se[balldrop]\1"))
         Kernel.pbMessage(_INTL("{1} ha olvidado cómo\r\nusar {2}.\1",pokemon.name,oldmovename))
         Kernel.pbMessage(_INTL("Y...\1"))
         Kernel.pbMessage(_INTL("\\se[]¡{1} ha aprendido {2}!\\se[MoveLearnt]",pokemon.name,newmovename))
       else
         # Intenta aprender el nuevo movimiento especial de esta forma
         pbLearnMove(pokemon,getID(PBMoves,newmove),true)
       end
     end
   else
     if hasoldmove>=0
       # Olvida el movimiento especial de la forma vieja
       oldmovename=PBMoves.getName(pokemon.moves[hasoldmove].id)
       pokemon.pbDeleteMoveAtIndex(hasoldmove)
       Kernel.pbMessage(_INTL("{1} ha olvidado {2}...",pokemon.name,oldmovename))
       if pokemon.moves.find_all{|i| i.id!=0}.length==0
         pbLearnMove(pokemon,getID(PBMoves,:CONFUSION))
       end
     end
   end
}
})

# OINKOLOGNE
MultipleForms.register(:OINKOLOGNE,{
"getFormOnCreation"=>proc{|pokemon|
   if pokemon.isFemale?
     pokemon.form=1
   else
     pokemon.form=0
   end
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:AROMAVEIL),0],[getID(PBAbilities,:GLUTTONY),1],[getID(PBAbilities,:THICKFAT),2]]
   else;   next
   end
}
})

# SQUAWKABILLY
MultipleForms.register(:SQUAWKABILLY,{
"getFormOnCreation"=>proc{|pokemon|
   maps1=[138]   # ID del mapa para el Plumaje Blanco
   maps2=[140]   # ID del mapa para el Plumaje Amarillo
   maps3=[142]   # ID del mapa para el Plumaje Azul
   if $game_map && maps1.include?($game_map.map_id)
     next 1
   elsif $game_map && maps2.include?($game_map.map_id)
     next 2
   elsif $game_map && maps3.include?($game_map.map_id)
     next 3
   else
     next 0
   end
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:INTIMIDATE),0],[getID(PBAbilities,:HUSTLE),1],[getID(PBAbilities,:SHEERFORCE),2]] # Plumaje Blanco
   when 2; next [[getID(PBAbilities,:INTIMIDATE),0],[getID(PBAbilities,:HUSTLE),1],[getID(PBAbilities,:SHEERFORCE),2]] # Plumaje Amarillo
   when 3; next [[getID(PBAbilities,:INTIMIDATE),0],[getID(PBAbilities,:HUSTLE),1],[getID(PBAbilities,:GUTS),2]] # Plumaje Azul
   else;   next
   end
}
})

# PALAFIN
MultipleForms.register(:PALAFIN,{
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0
   next [100,160,97,100,106,87]
}
})


MultipleForms.register(:OGERPON,{
"getForm"=>proc{|pokemon|
   f = 1 if isConst?(pokemon.item,PBItems,:WELLSPRINGMASK)
   f = 2 if isConst?(pokemon.item,PBItems,:HEARTHFLAMEMASK)
   f = 3 if isConst?(pokemon.item,PBItems,:CORRNERSTONEMASK)
   f += 5 if pokemon.isTera?
   next f
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:WATERABSORB),0],[getID(PBAbilities,:EMBODYASPECT3),1]]
   when 2; next [[getID(PBAbilities,:MOLDBREAKER),0],[getID(PBAbilities,:EMBODYASPECT2),1]]
   when 3; next [[getID(PBAbilities,:ENDURE),0],[getID(PBAbilities,:EMBODYASPECT4),1]]
   when 6; next [[getID(PBAbilities,:WATERABSORB),0],[getID(PBAbilities,:EMBODYASPECT3),1]]
   when 7; next [[getID(PBAbilities,:MOLDBREAKER),0],[getID(PBAbilities,:EMBODYASPECT2),1]]
   when 8; next [[getID(PBAbilities,:ENDURE),0],[getID(PBAbilities,:EMBODYASPECT4),1]]
   else;   next
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:WATER) if pokemon.form==1
  next getID(PBTypes,:FIRE) if pokemon.form==2
  next getID(PBTypes,:ROCK) if pokemon.form==3
  next
},
})

MultipleForms.register(:TERAPAGOS,{
"getBaseStats"=>proc{|pokemon|
  next [95,95,110,85,105,110] if pokemon.form==1
  next [160,105,110,85,130,110] if pokemon.form==2
  next
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:TERASHELL),0]]
   when 2; next [[getID(PBAbilities,:TERAFORMZERO),0]]
   else;   next
   end
},
"getForm"=>proc{|pokemon|
   next 2 if pokemon.isTera?
}

})
