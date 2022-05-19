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
    v=MultipleForms.call("type1",self)
    return v if v!=nil
    return self.__mf_type1
  end

  def type2
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
   when 1; movelist=[[1,:QUIVERDANCE],[1,:SUCKERPUNCH],[1,:PROTECT],[1,:BUGBITE],[1,:TACKLE],[10,:PROTECT],[15,:BUGBITE],[20,:HIDDENPOWER],
                     [23,:CONFUSION],[26,:ROCKBLAST],[29,:HARDEN],[32,:PSYBEAM],
                     [35,:CAPTIVATE],[38,:FLAIL],[41,:ATTRACT],[44,:PSYCHIC],
                     [47,:FISSURE],[50,:BUGBUZZ]]
   when 2; movelist=[[1,:QUIVERDANCE],[1,:METALBURST],[1,:SUCKERPUNCH],[1,:PROTECT],[1,:BUGBITE],[1,:TACKLE],[10,:PROTECT],[15,:BUGBITE],[20,:HIDDENPOWER],
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
   maps=[49,50,51,72,73]   # IDs de los mapas para la Forma Origen
   if isConst?(pokemon.item,PBItems,:ADAMANTORB) ||
      ($game_map && maps.include?($game_map.map_id))
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
   maps=[49,50,51,72,73]   # IDs de los mapas para la Forma Origen
   if isConst?(pokemon.item,PBItems,:LUSTROUSORB) ||
      ($game_map && maps.include?($game_map.map_id))
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
   when 2; movelist=[[1,:TACKLE],[6,:AQUAJET],[11,:BITE],[18,:ZENHEADBUTT],
                     [25,:CRUNCH],[34,:WAVECRASH],[43,:DOUBLEEDGE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
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

# LYCANROC

MultipleForms.register(:LYCANROC,{
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
   next 3 if isConst?(pokemon.item,PBItems,:ULTRANECROZIUMZ) && pokemon.form!=0
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
  next [92,170,115,148,80,115] if pokemon.form==1
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
  next [92,130,145,128,80,145] if pokemon.form==1
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

########################################################################
######################### Formas Alola #################################
########################################################################

# RATTATA

MultipleForms.register(:RATTATA,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:GLUTTONY),0],
         [getID(PBAbilities,:HUSTLE),1],
         [getID(PBAbilities,:THICKFAT),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:TAILWHIP],[4,:QUICKATTACK],[7,:FOCUSENERGY],
                     [10,:BITE],[13,:PURSUIT],[16,:HYPERFANG],[19,:ASSURANCE],
                     [22,:CRUNCH],[25,:SUCKERPUNCH],[28,:SUPERFANG],[31,:DOUBLEEDGE],
                     [34,:ENDEAVOR]]
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
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:TAUNT,:ICEBEAM,:BLIZZARD,
                     :PROTECT,:RAINDANCE,:FRUSTRATION,:RETURN,:SHADOWBALL,
                     :DOUBLETEAM,:SLUDGEBOMB,:TORMENT,:FACADE,:REST,:ATTRACT,
                     :THIEF,:ROUND,:QUASH,:EMBARGO,:SHADOWCLAW,:GRASSKNOT,
                     :SWAGGER,:SLEEPTALK,:UTURN,:SUBSTITUTE,:SNARL,:DARKPULSE,
                     :CONFIDE,:ICYWIND,:ENDEAVOR,:ZENHEADBUTT,
                     :COVET,:LASTRESORT,:SHOCKWAVE,:SNATCH,:SNORE,:SUPERFANG,:UPROAR,
                     :CRUNCH,:IRONTAIL]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# RATICATE

MultipleForms.register(:RATICATE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [75,71,70,77,40,80] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:GLUTTONY),0],
         [getID(PBAbilities,:HUSTLE),1],
         [getID(PBAbilities,:THICKFAT),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SCARYFACE],[1,:TACKLE],[1,:SWORDSDANCE],[1,:TAILWHIP],[4,:QUICKATTACK],[7,:FOCUSENERGY],
                     [10,:BITE],[13,:PURSUIT],[16,:HYPERFANG],[19,:ASSURANCE],
                     [24,:CRUNCH],[29,:SUCKERPUNCH],[34,:SUPERFANG],[39,:DOUBLEEDGE],
                     [44,:ENDEAVOR]]
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
                     :ROAR,:TOXIC,:BULKUP,:VENOSHOCK,:HIDDENPOWER,:SUNNYDAY,:TAUNT,:ICEBEAM,:BLIZZARD,
                     :HYPERBEAM,:PROTECT,:RAINDANCE,:FRUSTRATION,:RETURN,:SHADOWBALL,
                     :DOUBLETEAM,:SLUDGEWAVE,:SLUDGEBOMB,:TORMENT,:FACADE,:REST,:ATTRACT,
                     :THIEF,:ROUND,:QUASH,:EMBARGO,:SHADOWCLAW,:GIGAIMPACT,:SWORDSDANCE,:GRASSKNOT,
                     :SWAGGER,:SLEEPTALK,:UTURN,:SUBSTITUTE,:SNARL,:DARKPULSE,
                     :CONFIDE,:ICYWIND,:ENDEAVOR,:ZENHEADBUTT,:STOMPINGTANTRUM,
                     :COVET,:LASTRESORT,:SHOCKWAVE,:SNATCH,:SNORE,:SUPERFANG,:UPROAR,
                     :CRUNCH,:IRONTAIL]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# RAICHU

MultipleForms.register(:RAICHU,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [60,85,50,110,95,85] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SURGESURFER),0]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:PSYCHIC],[1,:SPEEDSWAP],[1,:THUNDERSHOCK],[1,:QUICKATTACK],[1,:TAILWHIP],[1,:THUNDERBOLT]]
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
                     :PSYSHOCK,:CALMMIND,:TOXIC,:HIDDENPOWER,:HYPERBEAM,:LIGHTSCREEN,
                     :PROTECT,:RAINDANCE,:SAFEGUARD,:FRUSTRATION,:THUNDERBOLT,:THUNDER,:RETURN,:DIG,:PSYCHIC,
                     :BRICKBREAK,:DOUBLETEAM,:REFLECT,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,:ECHOEDVOICE,
                     :FOCUSBLAST,:FLING,:CHARGEBEAM,:GIGAIMPACT,:FLASH,:VOLTSWITCH,:THUNDERWAVE,:GRASSKNOT,
                     :SWAGGER,:SLEEPTALK,:SUBSTITUTE,:WILDCHARGE,:SECRETPOWER,:CONFIDE,:KNOCKOFF,:FOCUSPUNCH,:RECYCLE,
                     :ALLYSWITCH,:COVET,:ELECTROWEB,:HELPINGHAND,:LASERFOCUS,:LASTRESORT,:MAGICCOAT,:MAGICROOM,:MAGNETRISE,
                     :SIGNALBEAM,:SHOCKWAVE,:SNATCH,:SNORE,:SUPERFANG,:TELEKINESIS,:THUNDERPUNCH,:UPROAR,
                     :ELECTROBALL,:NASTYPLOT,:IRONTAIL,:RISINGVOLTAGE,:EXPANDINGFORCE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SANDSHREW

MultipleForms.register(:SANDSHREW,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [50,75,90,40,10,35] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SNOWCLOAK),0],
         [getID(PBAbilities,:SLUSHRUSH),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SCRATCH],[1,:DEFENSECURL],[3,:BIDE],[5,:POWDERSNOW],[7,:ICEBALL],[9,:RAPIDSPIN],
                     [11,:FURYCUTTER],[14,:METALCLAW],[17,:SWIFT],[20,:FURYSWIPES],[23,:IRONDEFENSE],
                     [26,:SLASH],[30,:IRONHEAD],[34,:GYROBALL],[38,:SWORDSDANCE],[42,:HAIL],
                     [46,:BLIZZARD]]
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
                     :HONECLAWS,:TOXIC,:HAIL,:HIDDENPOWER,:SUNNYDAY,:BLIZZARD,
                     :PROTECT,:SAFEGUARD,:FRUSTRATION,:EARTHQUAKE,:RETURN,
                     :BRICKBREAK,:DOUBLETEAM,:AERIALACE,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :FLING,:SHADOWCLAW,:GYROBALL,:SWORDSDANCE,:BULLDOZE,:FROSTBREATH,:ROCKSLIDE,:XSCISSOR,
                     :POISONJAB,:SWAGGER,:SLEEPTALK,:SUBSTITUTE,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:ICYWIND,:KNOCKOFF,:FOCUSPUNCH,:IRONHEAD,
                     :AQUATAIL,:AURORAVEIL,:COVET,:ICEPUNCH,:SNORE,:SUPERFANG,:WORKUP,
                     :ICICLESPEAR,:LEECHLIFE,:IRONTAIL,:STEELBEAM,:TRIPLEAXEL,:STEELROLLER]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SANDSLASH

MultipleForms.register(:SANDSLASH,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [75,100,120,65,25,65] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SNOWCLOAK),0],
         [getID(PBAbilities,:SLUSHRUSH),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:ICICLESPEAR],[1,:ICICLECRASH],[1,:METALBURST],[1,:METALCLAW],[1,:ICEBALL],[1,:SLASH],[1,:DEFENSECURL]]
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
                     :HONECLAWS,:TOXIC,:HAIL,:HIDDENPOWER,:SUNNYDAY,:BLIZZARD,:HYPERBEAM,
                     :PROTECT,:SAFEGUARD,:FRUSTRATION,:EARTHQUAKE,:RETURN,
                     :BRICKBREAK,:DOUBLETEAM,:AERIALACE,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,:FOCUSBLAST,
                     :FLING,:SHADOWCLAW,:GIGAIMPACT,:GYROBALL,:SWORDSDANCE,:BULLDOZE,:FROSTBREATH,:ROCKSLIDE,:XSCISSOR,
                     :POISONJAB,:SWAGGER,:SLEEPTALK,:SUBSTITUTE,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:ICYWIND,:KNOCKOFF,:FOCUSPUNCH,:IRONHEAD,
                     :AQUATAIL,:AURORAVEIL,:COVET,:DRILLRUN,:ICEPUNCH,:SNORE,:SUPERFANG,:WORKUP,
                     :ICICLESPEAR,:LEECHLIFE,:IRONTAIL,:STEELBEAM,:TRIPLEAXEL,:STEELROLLER]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# VULPIX

MultipleForms.register(:VULPIX,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SNOWCLOAK),0],
         [getID(PBAbilities,:SNOWWARNING),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:POWDERSNOW],[4,:TAILWHIP],[7,:ROAR],[9,:BABYDOLLEYES],[10,:ICESHARD],[12,:CONFUSERAY],
                     [15,:ICYWIND],[18,:PAYBACK],[20,:MIST],[23,:FEINTATTACK],[26,:HEX],
                     [28,:AURORABEAM],[31,:EXTRASENSORY],[34,:SAFEGUARD],[36,:ICEBEAM],[39,:IMPRISON],
                     [42,:BLIZZARD],[44,:GRUDGE],[47,:CAPTIVATE],[50,:SHEERCOLD]]
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
                     :ROAR,:TOXIC,:HAIL,:HIDDENPOWER,:ICEBEAM,:BLIZZARD,:PROTECT,:RAINDANCE,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,:DOUBLETEAM,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :PAYBACK,:PSYCHUP,:FROSTBREATH,:SWAGGER,:SLEEPTALK,:SUBSTITUTE,:SECRETPOWER,:DARKPULSE,
                     :CONFIDE,:ICYWIND,:FOULPLAY,:PAINSPLIT,:ZENHEADBUTT,
                     :AQUATAIL,:AURORAVEIL,:COVET,:HEALBELL,:ROLEPLAY,:SNORE,
                     :SPITE,:IRONTAIL]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# NINETALES

MultipleForms.register(:NINETALES,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FAIRY) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [73,67,75,109,81,100] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SNOWCLOAK),0],
         [getID(PBAbilities,:SNOWWARNING),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:DAZZLINGGLEAM],[1,:MOONBLAST],[1,:NASTYPLOT],[1,:IMPRISON],[1,:ICESHARD],[1,:ICEBEAM],[1,:CONFUSERAY],[1,:SAFEGUARD]]
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
                     :PSYSHOCK,:CALMIND,:ROAR,:TOXIC,:HAIL,:HIDDENPOWER,:ICEBEAM,:BLIZZARD,:HYPERBEAM,:PROTECT,:RAINDANCE,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,:DOUBLETEAM,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :PAYBACK,:GIGAIMPACT,:PSYCHUP,:FROSTBREATH,:DREAMEATER,:SWAGGER,:SLEEPTALK,:SUBSTITUTE,:SECRETPOWER,:DARKPULSE,
                     :DAZZLINGGLEAM,:CONFIDE,:ICYWIND,:FOULPLAY,:PAINSPLIT,:ZENHEADBUTT,
                     :AQUATAIL,:AURORAVEIL,:COVET,:HEALBELL,:LASERFOCUS,:ROLEPLAY,:SNORE,:SPITE,:WONDERROOM,
                     :NASTPLOT,:SPITE,:IRONTAIL,:TRIPLEAXEL]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# DIGLETT

MultipleForms.register(:DIGLETT,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [10,55,30,90,35,45] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SANDVEIL),0],
         [getID(PBAbilities,:TANGLINGHAIR),1],
         [getID(PBAbilities,:SANDFORCE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:METALCLAW],[1,:SANDATTACK],[4,:GROWL],[7,:ASTONISH],[10,:MUDSLAP],[14,:MAGNITUDE],
                     [18,:BULLDOZE],[22,:SUCKERPUNCH],[25,:MUDBOMB],[28,:EARTHPOWER],[31,:DIG],
                     [35,:IRONHEAD],[39,:EARTHQUAKE],[43,:FISSURE]]
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
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:PROTECT,:FRUSTRATION,:EARTHQUAKE,:DIG,:RETURN,:DOUBLETEAM,
                     :SLUDGEBOMB,:SANDSTORM,:ROCKTOMB,:AERIALACE,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :ECHOEDVOICE,:SHADOWCLAW,:BULLDOZE,:ROCKSLIDE,:SWAGGER,:SLEEPTALK,:SUBSTITUTE,:WORKUP,
                     :FLASHCANNON,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:IRONHEAD,:STOMPINGTANTRUM,:SNORE,
                     :EARTHPOWER,:STEELBEAM,:SCORCHINGSANDS]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# DUGTRIO

MultipleForms.register(:DUGTRIO,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [35,100,60,110,50,70] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SANDVEIL),0],
         [getID(PBAbilities,:TANGLINGHAIR),1],
         [getID(PBAbilities,:SANDFORCE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SANDTOMB],[1,:METALCLAW],[1,:SANDATTACK],[1,:ROTOTILLER],[1,:TRIATTACK],[1,:NIGHTSLASH],
                     [4,:GROWL],[7,:ASTONISH],[10,:MUDSLAP],[14,:MAGNITUDE],
                     [18,:BULLDOZE],[22,:SUCKERPUNCH],[25,:MUDBOMB],[30,:EARTHPOWER],[35,:DIG],
                     [41,:IRONHEAD],[47,:EARTHQUAKE],[53,:FISSURE]]
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
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:HYPERBEAM,:PROTECT,:FRUSTRATION,:EARTHQUAKE,:DIG,:RETURN,:DOUBLETEAM,
                     :SLUDGEWAVE,:SLUDGEBOMB,:SANDSTORM,:ROCKTOMB,:AERIALACE,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :ECHOEDVOICE,:SHADOWCLAW,:GIGAIMPACT,:STONEEDGE,:BULLDOZE,:ROCKSLIDE,:SWAGGER,:SLEEPTALK,:SUBSTITUTE,
                     :FLASHCANNON,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:IRONHEAD,:STOMPINGTANTRUM,:WORKUP,:SNORE,
                     :EARTHPOWER,:TRIATTACK,:STEELBEAM,:SCORCHINGSANDS]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# MEOWTH

MultipleForms.register(:MEOWTH,{
"getFormOnCreation"=>proc{|pokemon|
   maps1=[22]   # Map IDs for Alola Form
   maps2=[32]   # Map IDs for Galar Form
   if $game_map && maps1.include?($game_map.map_id)
     next 1
   elsif $game_map && maps2.include?($game_map.map_id)
     next 2
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
   next if pokemon.form==0             # Forma Normal
   case pokemon.form
   when 1; next getID(PBTypes,:DARK)   # Forma Alola
   when 2; next getID(PBTypes,:STEEL)  # Forma Galar
   end
},
"type2"=>proc{|pokemon|
   next if pokemon.form==0             # Forma Normal
   case pokemon.form
   when 1; next getID(PBTypes,:DARK)   # Forma Alola
   when 2; next getID(PBTypes,:STEEL)  # Forma Galar
   end
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0              # Forma Normal
   case pokemon.form
   when 1; next [40,35,35,90,50,40]     # Forma Alola
   when 2; next [50,65,55,40,40,40]     # Forma Galar
  end
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:PICKUP),0],[getID(PBAbilities,:TECHNICIAN),1],[getID(PBAbilities,:RATTLED),2]] # Forma Alola
   when 2; next [[getID(PBAbilities,:PICKUP),0],[getID(PBAbilities,:TOUGHCLAWS),1],[getID(PBAbilities,:UNNERVE),2]] # Forma Galar
   else;   next                                       
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SCRATCH],[1,:GROWL],[6,:BITE],[9,:FAKEOUT],[14,:FURYSWIPES],[17,:SCREECH],
                     [22,:FEINTATTACK],[25,:TAUNT],[30,:PAYDAY],[33,:SLASH],[38,:NASTYPLOT],
                     [41,:ASSURANCE],[46,:CAPTIVATE],[49,:NIGHTSLASH],[50,:FEINT],[55,:DARKPULSE]]
   when 2; movelist=[[1,:FAKEOUT],[1,:GROWL],[4,:HONECLAWS],[8,:SCRATCH],[12,:PAYDAY],[16,:METALCLAW],
                     [20,:TAUNT],[24,:SWAGGER],[29,:FURYSWIPES],[32,:SCREECH],[36,:SLASH],
                     [40,:METALSOUND],[44,:THRASH]]
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
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:TAUNT,:PROTECT,:RAINDANCE,:FRUSTRATION,:THUNDERBOLT,:THUNDER,:RETURN,
                     :SHADOWBALL,:DOUBLETEAM,:AERIALACE,:TORMENT,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :ECHOEDVOICE,:QUASH,:EMBARGO,:SHADOWCLAW,:PAYBACK,:PSYCHUP,:DREAMEATER,:SWAGGER,:SLEEPTALK,:UTURN,:SUBSTITUTE,
                     :DARKPULSE,:CONFIDE,:FOULPLAY,:ICYWIND,:SEEDBOMB,:KNOCKOFF,
                     :COVET,:LASTRESORT,:SHOCKWAVE,:SNATCH,:SNORE,:UPROAR,:WATERPULSE,:WORKUP,
                     :GUNKSHOT,:NASTYPLOT,:SPITE,:HYPERVOICE,:IRONTAIL,:LASHOUT]
   when 2; movelist=[# MTs y tutores
                     :DIG,:REST,:THIEF,:SNORE,:PROTECT,:ATTRACT,:FACADE,:RAINDANCE,:SUNNYDAY,
                     :UTURN,:PAYBACK,:SHADOWCLAW,:ROUND,:RETALIATE,:SWORDSDANCE,:THUNDERBOLT,
                     :THUNDER,:SUBSTITUTE,:SLEEPTALK,:IRONTAIL,:CRUNCH,:SHADOWBALL,:UPROAR,
                     :TAUNT,:HYPERVOICE,:IRONDEFENSE,:DARKPULSE,:GYROBALL,:SEEDBOMB,:GUNKSHOT,
                     :NASTYPLOT,:IRONHEAD,:FOULPLAY,:WORKUP,:PLAYROUGH,:THROATCHOP,:SWAGGER,
                     :COVET,:LASHOUT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# PERSIAN

MultipleForms.register(:PERSIAN,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [65,60,60,115,75,65] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:FURCOAT),0],
         [getID(PBAbilities,:TECHNICIAN),1],
         [getID(PBAbilities,:RATTLED),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SWIFT],[1,:SCRATCH],[1,:GROWL],[1,:PLAYROUGH],[1,:SWITCHEROO],[1,:QUASH],
                     [6,:BITE],[9,:FAKEOUT],[14,:FURYSWIPES],[17,:SCREECH],
                     [22,:FEINTATTACK],[25,:TAUNT],[32,:POWERGEM],[37,:SLASH],[44,:NASTYPLOT],
                     [49,:ASSURANCE],[56,:CAPTIVATE],[61,:NIGHTSLASH],[65,:FEINT],[69,:DARKPULSE]]
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
                     :ROAR,:TOXIC,:HIDDENPOWER,:SUNNYDAY,:TAUNT,:HYPERBEAM,:PROTECT,:RAINDANCE,:FRUSTRATION,:THUNDERBOLT,:THUNDER,:RETURN,
                     :SHADOWBALL,:DOUBLETEAM,:AERIALACE,:TORMENT,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :ECHOEDVOICE,:QUASH,:EMBARGO,:SHADOWCLAW,:PAYBACK,:GIGAIMPACT,:PSYCHUP,:DREAMEATER,:SWAGGER,:SLEEPTALK,:UTURN,:SUBSTITUTE,
                     :SNARL,:DARKPULSE,:CONFIDE,:FOULPLAY,:ICYWIND,:SEEDBOMB,:KNOCKOFF,
                     :COVET,:LASTRESORT,:SHOCKWAVE,:SNATCH,:SNORE,:UPROAR,:WATERPULSE,:WORKUP,
                     :POWERGEM,:GUNKSHOT,:NASTYPLOT,:SPITE,:HYPERVOICE,:IRONTAIL,:PLAYROUGH,
                     :BURNINGJEALOUSY,:LASHOUT,:SKITTERSMACK]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# GEODUDE

MultipleForms.register(:GEODUDE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ELECTRIC) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:MAGNETPULL),0],
         [getID(PBAbilities,:STURDY),1],
         [getID(PBAbilities,:GALVANIZE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:DEFENSECURL],[4,:CHARGE],[6,:ROCKPOLISH],[10,:ROLLOUT],[12,:SPARK],
                     [16,:ROCKTHROW],[18,:SMACKDOWN],[22,:THUNDERPUNCH],[24,:SELFDESTRUCT],
                     [28,:STEALTHROCK],[30,:ROCKBLAST],[34,:DISCHARGE],[36,:EXPLOSION],[40,:DOUBLEEDGE],
                     [42,:STONEEDGE]]
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
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:PROTECT,:FRUSTRATION,:SMACKDOWN,:THUNDERBOLT,:THUNDER,:EARTHQUAKE,:RETURN,
                     :BRICKBREAK,:DOUBLETEAM,:FLAMETHROWER,:SANDSTORM,:FIREBLAST,:ROCKTOMB,:FACADE,:REST,:ATTRACT,:ROUND,
                     :FLING,:CHARGEBEAM,:EXPLOSION,:ROCKPOLISH,:STONEEDGE,:VOLTSWITCH,:GYROBALL,:BULLDOZE,:ROCKSLIDE,
                     :SWAGGER,:SLEEPTALK,:SUBSTITUTE,:NATUREPOWER,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:BLOCK,:FOCUSPUNCH,:SUPERPOWER,:BRUTALSWING,
                     :ELECTROWEB,:FIREPUNCH,:MAGNETRISE,:SNORE,:THUNDERPUNCH,
                     :EARTHPOWER,:ROCKBLAST]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# GRAVELER

MultipleForms.register(:GRAVELER,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ELECTRIC) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:MAGNETPULL),0],
         [getID(PBAbilities,:STURDY),1],
         [getID(PBAbilities,:GALVANIZE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:DEFENSECURL],[4,:CHARGE],[6,:ROCKPOLISH],[10,:ROLLOUT],[12,:SPARK],
                     [16,:ROCKTHROW],[18,:SMACKDOWN],[22,:THUNDERPUNCH],[24,:SELFDESTRUCT],
                     [30,:STEALTHROCK],[34,:ROCKBLAST],[40,:DISCHARGE],[44,:EXPLOSION],[50,:DOUBLEEDGE],
                     [54,:STONEEDGE]]
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
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:PROTECT,:FRUSTRATION,:SMACKDOWN,:THUNDERBOLT,:THUNDER,:EARTHQUAKE,:RETURN,
                     :BRICKBREAK,:DOUBLETEAM,:FLAMETHROWER,:SANDSTORM,:FIREBLAST,:ROCKTOMB,:FACADE,:REST,:ATTRACT,:ROUND,
                     :FLING,:CHARGEBEAM,:EXPLOSION,:ROCKPOLISH,:STONEEDGE,:VOLTSWITCH,:GYROBALL,:BULLDOZE,:ROCKSLIDE,
                     :SWAGGER,:SLEEPTALK,:SUBSTITUTE,:NATUREPOWER,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:BLOCK,:FOCUSPUNCH,:SUPERPOWER,:BRUTALSWING,:STOMPINGTANTRUM,
                     :ALLYSWITCH,:ELECTROWEB,:FIREPUNCH,:MAGNETRISE,:SNORE,:THUNDERPUNCH,
                     :EARTHPOWER,:ROCKBLAST]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# GOLEM

MultipleForms.register(:GOLEM,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ELECTRIC) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:MAGNETPULL),0],
         [getID(PBAbilities,:STURDY),1],
         [getID(PBAbilities,:GALVANIZE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:DEFENSECURL],[4,:CHARGE],[6,:ROCKPOLISH],[10,:STEAMROLLER],[12,:SPARK],
                     [16,:ROCKTHROW],[18,:SMACKDOWN],[22,:THUNDERPUNCH],[24,:SELFDESTRUCT],
                     [30,:STEALTHROCK],[34,:ROCKBLAST],[40,:DISCHARGE],[44,:EXPLOSION],[50,:DOUBLEEDGE],
                     [54,:STONEEDGE],[60,:HEAVYSLAM]]
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
                     :ROAR,:TOXIC,:HIDDENPOWER,:SUNNYDAY,:HYPERBEAM,:PROTECT,:FRUSTRATION,:SMACKDOWN,:THUNDERBOLT,:THUNDER,:EARTHQUAKE,:RETURN,
                     :BRICKBREAK,:DOUBLETEAM,:FLAMETHROWER,:SANDSTORM,:FIREBLAST,:ROCKTOMB,:FACADE,:REST,:ATTRACT,:ROUND,:ECHOEDVOICE,:FOCUSBLAST,
                     :FLING,:CHARGEBEAM,:EXPLOSION,:GIGAIMPACT,:ROCKPOLISH,:STONEEDGE,:VOLTSWITCH,:GYROBALL,:BULLDOZE,:ROCKSLIDE,
                     :SWAGGER,:SLEEPTALK,:SUBSTITUTE,:WILDCHARGE,:NATUREPOWER,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:BLOCK,:FOCUSPUNCH,:SUPERPOWER,:IRONHEAD,:BRUTALSWING,:STOMPINGTANTRUM,
                     :ALLYSWITCH,:ELECTROWEB,:FIREPUNCH,:MAGNETRISE,:SHOCKWAVE,:SNORE,:THUNDERPUNCH,
                     :EARTHPOWER,:ROCKBLAST]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# GRIMER

MultipleForms.register(:GRIMER,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:POISONTOUCH),0],
         [getID(PBAbilities,:GLUTTONY),1],
         [getID(PBAbilities,:POWEROFALCHEMY),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:POUND],[1,:POISONGAS],[4,:HARDEN],[7,:BITE],[12,:DISABLE],[15,:ACIDSPRAY],
                     [18,:POISONFANG],[21,:MINIMIZE],[26,:FLING],[29,:KNOCKOFF],
                     [32,:CRUNCH],[37,:SCREECH],[40,:GUNKSHOT],[43,:ACIDARMOR],[46,:BELCH],
                     [48,:MEMENTO]]
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
                     :TOXIC,:VENOSHOCK,:HIDDENPOWER,:SUNNYDAY,:TAUNT,:PROTECT,:RAINDANCE,:FRUSTRATION,:RETURN,
                     :SHADOWBALL,:DOUBLETEAM,:SLUDGEWAVE,:FLAMETHROWER,:SLUDGEBOMB,:FIREBLAST,:ROCKTOMB,:TORMENT,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :FLING,:QUASH,:EMBARGO,:EXPLOSION,:PAYBACK,:ROCKPOLISH,:STONEEDGE,:ROCKSLIDE,:INFESTATION,:POISONJAB,:SWAGGER,
                     :SLEEPTALK,:SUBSTITUTE,:SNARL,:POWERUPPUNCH,:CONFIDE,:GIGADRAIN,:KNOCKOFF,:PAINSPLIT,:BRUTALSWING,
                     :FIREPUNCH,:GASTROACID,:ICEPUNCH,:SHOCKWAVE,:SNORE,:THUNDERPUNCH,
                     :GUNKSHOT,:CRUNCH,:SPITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# MUK

MultipleForms.register(:MUK,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:POISONTOUCH),0],
         [getID(PBAbilities,:GLUTTONY),1],
         [getID(PBAbilities,:POWEROFALCHEMY),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:VENOMDRENCH],[1,:POUND],[1,:POISONGAS],[4,:HARDEN],[7,:BITE],[12,:DISABLE],[15,:ACIDSPRAY],
                     [18,:POISONFANG],[21,:MINIMIZE],[26,:FLING],[29,:KNOCKOFF],
                     [32,:CRUNCH],[37,:SCREECH],[40,:GUNKSHOT],[46,:ACIDARMOR],[52,:BELCH],
                     [57,:MEMENTO]]
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
                     :TOXIC,:VENOSHOCK,:HIDDENPOWER,:SUNNYDAY,:TAUNT,:HYPERBEAM,:PROTECT,:RAINDANCE,:FRUSTRATION,:THUNDERBOLT,:RETURN,
                     :SHADOWBALL,:BRICKBREAK,:DOUBLETEAM,:SLUDGEWAVE,:FLAMETHROWER,:SLUDGEBOMB,:FIREBLAST,:ROCKTOMB,:TORMENT,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :FOCUSBLAST,:FLING,:QUASH,:EMBARGO,:EXPLOSION,:PAYBACK,:GIGAIMPACT,:ROCKPOLISH,:STONEEDGE,:ROCKSLIDE,:INFESTATION,:POISONJAB,:SWAGGER,
                     :SLEEPTALK,:SUBSTITUTE,:SNARL,:DARKPULSE,:POWERUPPUNCH,:CONFIDE,:GIGADRAIN,:KNOCKOFF,:PAINSPLIT,:BLOCK,:FOCUSPUNCH,:RECYCLE,:BRUTALSWING,
                     :FIREPUNCH,:GASTROACID,:ICEPUNCH,:SHOCKWAVE,:SNORE,:THUNDERPUNCH,
                     :GUNKSHOT,:CRUNCH,:SPITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# EXEGGUTOR

MultipleForms.register(:EXEGGUTOR,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DRAGON) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [95,105,85,45,125,75] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:FRISK),0],
         [getID(PBAbilities,:HARVEST),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:DRAGONHAMMER],[1,:SEEDBOMB],[1,:CLAMP],[1,:HYPNOSIS],[1,:CONFUSION],[17,:PSYSHOCK],
                     [27,:EGGBOMB],[37,:WOODHAMMER],[47,:LEAFSTORM]]
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
                     :PSYSHOCK,:TOXIC,:HIDDENPOWER,:SUNNYDAY,:HYPERBEAM,:LIGHTSCREEN,:PROTECT,:FRUSTRATION,:SOLARBEAM,:EARTHQUAKE,:RETURN,
                     :PSYCHIC,:BRICKBREAK,:DOUBLETEAM,:REFLECT,:FLAMETHROWER,:SLUDGEBOMB,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,:ENERGYBALL,
                     :EXPLOSION,:GIGAIMPACT,:FLASH,:SWORDSDANCE,:PSYCHUP,:BULLDOZE,:DRAGONTAIL,:INFESTATION,:DREAMEATER,:SWAGGER,
                     :SLEEPTALK,:SUBSTITUTE,:TRICKROOM,:SECRETPOWER,:NATUREPOWER,:CONFIDE,:GIGADRAIN,:SEEDBOMB,:KNOCKOFF,:BLOCK,:SKILLSWAP,:SUPERPOWER,:DRAGONPULSE,:IRONHEAD,:ZENHEADBUTT,:BRUTALSWING,:STOMPINGTANTRUM,
                     :GRAVITY,:LOWKICK,:SNORE,:SYNTHESIS,:TELEKINESIS,:WORRYSEED,
                     :LEAFSTORM,:OUTRAGE,:DRACOMETEOR,:IRONTAIL,:TERRAINPULSE,:GRASSYGLIDE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# MAROWAK

MultipleForms.register(:MAROWAK,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIRE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [95,105,85,45,125,75] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:CURSEDBODY),0],
         [getID(PBAbilities,:LIGHTNINGROD),1],
         [getID(PBAbilities,:ROCKHEAD),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SHADOWBONE],[1,:GROWL],[3,:TAILWHIP],[7,:BONECLUB],[11,:FLAMEWHEEL],[13,:LEER],
                     [17,:HEX],[21,:BONEMERANG],[23,:WILLOWISP],[33,:THRASH],[37,:FLING],[43,:STOMPINGTANTRUM],[49,:ENDEAVOR],
                     [53,:FLAREBLITZ],[59,:RETALIATE],[65,:BONERUSH]]
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
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:ICEBEAM,:BLIZZARD,:HYPERBEAM,:PROTECT,:RAINDANCE,:FRUSTRATION,:SMACKDOWN,:THUNDERBOLT,:THUNDER,:EARTHQUAKE,:RETURN,:DIG,
                     :SHADOWBALL,:BRICKBREAK,:DOUBLETEAM,:FLAMETHROWER,:SANDSTORM,:FIREBLAST,:ROCKTOMB,:AERIALACE,:FLAMECHARGE,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,:ECHOEDVOICE,
                     :FOCUSBLAST,:FALSESWIPE,:FLING,:INCINERATE,:WILLOWISP,:RETALIATE,:GIGAIMPACT,:STONEEDGE,:SWORDSDANCE,:BULLDOZE,:ROCKSLIDE,:DREAMEATER,:SWAGGER,
                     :SLEEPTALK,:SUBSTITUTE,:SECRETPOWER,:DARKPULSE,:POWERUPPUNCH,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:ICYWIND,:ENDEAVOR,:KNOCKOFF,:PAINSPLIT,:FOCUSPUNCH,:IRONHEAD,:BRUTALSWING,:STOMPINGTANTRUM,
                     :ALLYSWITCH,:FIREPUNCH,:HEATWAVE,:LASERFOCUS,:LOWKICK,:SNORE,:THUNDERPUNCH,:UPROAR,
                     :FLAREBLITZ,:SPITE,:EARTHPOWER,:OUTRAGE,:IRONTAIL,:BURNINGJEALOUSY,:POLTERGEIST,
                     :SCORCHINGSANDS]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

########################################################################
######################### Formas Galar #################################
########################################################################

# PONYTA

MultipleForms.register(:PONYTA,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [50,85,55,90,65,65] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:RUNAWAY),0],
         [getID(PBAbilities,:PASTELVEIL),1],
         [getID(PBAbilities,:ANTICIPATION),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:GROWL],[5,:TAILWHIP],[10,:CONFUSION],[15,:FAIRYWIND],
                     [20,:AGILITY],[25,:PSYBEAM],[30,:STOMP],[35,:HEALPULSE],[41,:TAKEDOWN],
                     [45,:DAZZLINGGLEAM],[50,:PSYCHIC],[55,:HEALINGWISH]]
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
                     :REST,:SNORE,:PROTECT,:ATTRACT,:FACADE,:BOUNCE,:LOWKICK,
                     :ROUND,:SUBSTITUTE,:SLEEPTALK,:PSYCHIC,:IRONTAIL,:CALMMIND,
                     :ZENHEADBUTT,:STOREDPOWER,:ALLYSWITCH,:WILDCHARGE,:PLAYROUGH,
                     :DAZZLINGGLEAM,:HIGHHORSEPOWER,:EXPANDINGFORCE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# RAPIDASH

MultipleForms.register(:RAPIDASH,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FAIRY) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [65,100,70,105,80,80] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:RUNAWAY),0],
         [getID(PBAbilities,:PASTELVEIL),1],
         [getID(PBAbilities,:ANTICIPATION),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:PSYCHOCUT],[1,:MEGAHORN],[1,:QUICKATTACK],[1,:TAILWHIP], 
                     [1,:TACKLE],[1,:GROWL],[1,:CONFUSION],[15,:FAIRYWIND],
                     [20,:AGILITY],[25,:PSYBEAM],[30,:STOMP],[35,:HEALPULSE],[43,:TAKEDOWN],
                     [49,:DAZZLINGGLEAM],[56,:PSYCHIC],[63,:HEALINGWISH]]
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
                     :HYPERBEAM,:GIGAIMPACT,:REST,:SNORE,:PROTECT,:ATTRACT,:FACADE,:BOUNCE,
                     :TRICKROOM,:MAGICROOM,:WONDERROOM,:SMARTSTRIKE,:SWORDSDANCE,:DRILLRUN,
                     :LOWKICK,:ROUND,:SUBSTITUTE,:SLEEPTALK,:PSYCHIC,:IRONTAIL,:CALMMIND,
                     :ZENHEADBUTT,:STOREDPOWER,:ALLYSWITCH,:WILDCHARGE,:PLAYROUGH,
                     :DAZZLINGGLEAM,:HIGHHORSEPOWER,:THROATCHOP,:EXPANDINGFORCE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SLOWPOKE

MultipleForms.register(:SLOWPOKE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [90,65,65,15,40,40] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:GLUTTONY),0],
         [getID(PBAbilities,:OWNTEMPO),1],
         [getID(PBAbilities,:REGENERATOR),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:CURSE],[1,:TACKLE],[3,:GROWL],[6,:ACID],[9,:YAWN],
                     [12,:CONFUSION],[15,:DISABLE],[18,:WATERPULSE],[21,:HEADBUTT],
                     [24,:ZENHEADBUTT],[27,:AMNESIA],[30,:SURF],[33,:SLACKOFF],
                     [36,:PSYCHIC],[39,:PSYCHUP],[42,:RAINDANCE],[45,:HEALPULSE]]
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
                     :THUNDERWAVE,:DIG,:LIGHTSCREEN,:SAFEGUARD,:REST,:SNORE,:PROTECT,:ICYWIND,
                     :ATTRACT,:RAINDANCE,:SUNNYDAY,:HAIL,:FACADE,:DIVE,:TRICKROOM,:WONDERROOM,
                     :ROUND,:BULLDOZE,:FLAMETHROWER,:SURF,:HYDROPUMP,:ICEBEAM,:BLIZZARD,:EARTHQUAKE,
                     :PSYCHIC,:FIREBLAST,:SUBSTITUTE,:SLEEPTALK,:PSYSHOCK,:IRONTAIL,:SHADOWBALL,
                     :TRICK,:SKILLSWAP,:CALMMIND,:ZENHEADBUTT,:GRASSKNOT,:STOREDPOWER,:TRIATTACK,
                     :SCALD,:LIQUIDATION,:BRINE,:PSYCHICTERRAIN,:WEATHERBALL,:AMNESIA,:EXPANDINGFORCE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SLOWBRO

MultipleForms.register(:SLOWBRO,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"getMegaForm"=>proc{|pokemon|
   next 2 if isConst?(pokemon.item,PBItems,:SLOWBRONITE)
   next
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next getID(PBTypes,:WATER) if pokemon.form==2
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:POISON) if pokemon.form==1
  next getID(PBTypes,:PSYCHIC) if pokemon.form==2
  next
},
"getBaseStats"=>proc{|pokemon|
  next [95,100,95,30,100,70] if pokemon.form==1
  next [95,75,180,30,130,80] if pokemon.form==2
  next
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:QUICKDRAW),0],[getID(PBAbilities,:OWNTEMPO),1],[getID(PBAbilities,:REGENERATOR),2]]
   when 2; next [[getID(PBAbilities,:SHELLARMOR),0]]
   else;   next                                       
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SHELLSIDEARM],[1,:TACKLE],[1,:GROWL],[1,:ACID],[1,:CURSE],
                     [9,:YAWN],[12,:CONFUSION],[15,:DISABLE],[18,:WATERPULSE],
                     [21,:HEADBUTT],[24,:ZENHEADBUTT],[27,:AMNESIA],[30,:SURF],
                     [33,:SLACKOFF],[36,:PSYCHIC],[39,:PSYCHUP],[42,:RAINDANCE],
                     [45,:HEALPULSE]]
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
                     :THUNDERWAVE,:DIG,:LIGHTSCREEN,:SAFEGUARD,:REST,:SNORE,:PROTECT,:ICYWIND,
                     :ATTRACT,:RAINDANCE,:SUNNYDAY,:HAIL,:FACADE,:DIVE,:TRICKROOM,:WONDERROOM,
                     :ROUND,:BULLDOZE,:FLAMETHROWER,:SURF,:HYDROPUMP,:ICEBEAM,:BLIZZARD,:EARTHQUAKE,
                     :PSYCHIC,:FIREBLAST,:SUBSTITUTE,:SLEEPTALK,:PSYSHOCK,:IRONTAIL,:SHADOWBALL,
                     :TRICK,:SKILLSWAP,:CALMMIND,:ZENHEADBUTT,:GRASSKNOT,:STOREDPOWER,:TRIATTACK,
                     :SCALD,:LIQUIDATION,:BRINE,:PSYCHICTERRAIN,:WEATHERBALL,:AMNESIA,:AVALANCHE,
                     :EXPANDINGFORCE,:BRICKBREAK,:DRAINPUNCH,:FOCUSBLAST,:GIGAIMPACT,:HYPERBEAM,
                     :ICEPUNCH,:IRONDEFENSE,:MUDDYWATER,:NASTYPLOT,:POISONJAB,:RAZORSHELL,:SLUDGEBOMB,
                     :SLUDGEWAVE,:VENOSHOCK,:EXPANDINGFORCE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# FARFETCH'D

MultipleForms.register(:FARFETCHD,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [52,95,55,55,58,62] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:STEADFAST),0],
         [getID(PBAbilities,:SCRAPPY),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:PECK],[1,:SANDATTACK],[5,:LEER],[10,:FURYCUTTER],[15,:ROCKSMASH],
                     [20,:BRUTALSWING],[25,:DETECT],[30,:KNOCKOFF],[35,:DEFOG],
                     [40,:BRICKBREAK],[45,:SWORDSDANCE],[50,:SLAM],[55,:LEAFBLADE],
                     [60,:FINALGAMBIT],[65,:BRAVEBIRD]]
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
                     :REST,:SNORE,:PROTECT,:STEELWING,:ATTRACT,:SUNNYDAY,:FACADE,
                     :HELPINGHAND,:BRICKBREAK,:ROUND,:RETALIATE,:BRUTALSWING,
                     :SWORDSDANCE,:SUBSTITUTE,:SLEEPTALK,:SUPERPOWER,:POISONJAB,
                     :WORKUP,:THROATCHOP,:KNOCKOFF,:COVET,:DEFOG,:SKYATTACK,:DUALWINGBEAT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# WEEZING

MultipleForms.register(:WEEZING,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FAIRY) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:LEVITATE),0],
         [getID(PBAbilities,:NEUTRALIZINGGAS),1],
         [getID(PBAbilities,:MISTYSURGE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:DOUBLEHIT],[1,:STRANGESTEAM],[1,:DEFOG],[1,:HEATWAVE],[1,:SMOG],
                     [1,:SMOKESCREEN],[1,:HAZE],[1,:POISONGAS],[1,:TACKLE],[9,:FAIRYWIND],
                     [1,:AROMATICMIST],[12,:CLEARSMOG],[16,:ASSURANCE],[20,:SLUDGE],
                     [24,:AROMATHERAPY],[28,:SELFDESTRUCT],[32,:SLUDGEBOMB],[38,:TOXIC],
                     [44,:BELCH],[50,:EXPLOSION],[56,:MEMENTO],[62,:DESTINYBOND],[68,:MISTYTERRAIN]]
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
                     :TOXIC,:HYPERBEAM,:GIGAIMPACT,:REST,:THIEF,:SNORE,:PROTECT,:ATTRACT,
                     :RAINDANCE,:SUNNYDAY,:WILLOWISP,:FACADE,:PAYBACK,:WONDERROOM,:VENOSHOCK,
                     :ROUND,:BRUTALSWING,:FLAMETHROWER,:THUNDERBOLT,:THUNDER,:FIREBLAST,
                     :SUBSTITUTE,:SLUDGEBOMB,:SLEEPTALK,:SHADOWBALL,:UPROAR,:HEATWAVE,
                     :TAUNT,:OVERHEAT,:GYROBALL,:DARKPULSE,:SLUDGEWAVE,:DAZZLINGGLEAM,
                     :PAINSPLIT,:EXPLOSION,:DEFOG,:CORROSIVEGAS,:MISTYEXPLOSION,:CONFIDE,
                     :RETURN,:FRUSTRATION,:HIDDENPOWER]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# MR. MIME

MultipleForms.register(:MRMIME,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [50,65,65,100,90,90] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:VITALSPIRIT),0],
         [getID(PBAbilities,:SCREENCLEANER),1],
         [getID(PBAbilities,:ICEBODY),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:COPYCAT],[1,:ENCORE],[1,:ROLEPLAY],[1,:PROTECT],[1,:RECYCLE],
                     [1,:MIMIC],[1,:LIGHTSCREEN],[1,:REFLECT],[1,:SAFEGUARD],[1,:DAZZLINGGLEAM],
                     [1,:MISTYTERRAIN],[1,:POUND],[1,:RAPIDSPIN],[1,:BATONPASS],[1,:ICESHARD],
                     [12,:CONFUSION],[16,:ALLYSWITCH],[20,:ICYWIND],[24,:DOUBLEKICK],[28,:PSYBEAM],
                     [32,:HYPNOSIS],[36,:MIRRORCOAT],[40,:SUCKERPUNCH],[44,:FREEZEDRY],
                     [48,:PSYCHIC],[52,:TEETERDANCE]]
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
                     :ICEPUNCH,:HYPERBEAM,:GIGAIMPACT,:SOLARBEAM,:THUNDERWAVE,:TRICKROOM,
                     :LIGHTSCREEN,:REFLECT,:SAFEGUARD,:ICYWIND,:THIEF,:HELPINGHAND,:FLING,
                     :REST,:SNORE,:PROTECT,:ATTRACT,:SUNNYDAY,:FACADE,:RAINDANCE,:HAIL,:CONFIDE,
                     :BRICKBREAK,:ICICLESPEAR,:ROUND,:PAYBACK,:WONDERROOM,:MAGICROOM,:DRAINPUNCH,
                     :STOMPINGTANTRUM,:ICEBEAM,:SUBSTITUTE,:SLEEPTALK,:BLIZZARD,:PSYCHIC,:PSYSHOCK,
                     :THUNDER,:THUNDERBOLT,:SHADOWBALL,:UPROAR,:TAUNT,:TRICK,:SKILLSWAP,:IRONDEFENSE,
                     :CALMMIND,:FOCUSBLAST,:ENERGYBALL,:NASTYPLOT,:ZENHEADBUTT,:GRASSKNOT,:FOULPLAY,
                     :STOREDPOWER,:ALLYSWITCH,:DAZZLINGGLEAM,:RECYCLE,:ROLEPLAY,:TRIPLEAXEL,:EXPANDINGFORCE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# ARTICUNO

MultipleForms.register(:ARTICUNO,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[139]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FLYING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [90,85,85,95,125,95] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:COMPETITIVE),0]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:GUST],[1,:PSYCHOSHIFT],[5,:CONFUSION],[10,:REFLECT],
                     [15,:HYPNOSIS],[20,:AGILITY],[25,:ANCIENTPOWER],[30,:TAILWIND],
                     [35,:PSYCHOCUT],[40,:RECOVER],[45,:FREEZINGGLARE],
                     [50,:DREAMEATER],[55,:HURRICANE],[60,:MINDREADER],[65,:FUTURESIGHT],
                     [70,:TRICKROOM]]
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
                     :FLY,:HYPERBEAM,:GIGAIMPACT,:REFLECT,:LIGHTSCREEN,:REST,:PROTECT,
                     :STEELWING,:FACADE,:UTURN,:PSYCHOCUT,:TRICKROOM,:ROUND,:AIRSLASH,
                     :PSYCHIC,:AGILITY,:SUBSTITUTE,:SLEEPTALK,:PSYSHOCK,:SHADOWBALL,
                     :SKILLSWAP,:HYPERVOICE,:CALMMIND,:BRAVEBIRD,:HURRICANE,:STOREDPOWER,
                     :EXPANDINGFORCE,:DUALWINGBEAT,:SNORE,:ALLYSWITCH]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# ZAPDOS

MultipleForms.register(:ZAPDOS,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FLYING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [90,125,90,100,85,90] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:DEFIANT),0]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:PECK],[1,:FOCUSENERGY],[5,:ROCKSMASH],[10,:LIGHTSCREEN],
                     [15,:PLUCK],[20,:AGILITY],[25,:ANCIENTPOWER],[30,:BRICKBREAK],
                     [35,:DRILLPECK],[40,:QUICKGUARD],[45,:THUNDEROUSKICK],
                     [50,:BULKUP],[55,:COUNTER],[60,:DETECT],[65,:CLOSECOMBAT],
                     [70,:REVERSAL]]
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
                     :FLY,:HYPERBEAM,:GIGAIMPACT,:LIGHTSCREEN,:REST,:PROTECT,
                     :STEELWING,:FACADE,:BRICKBREAK,:UTURN,:PAYBACK,:ROUND,
                     :ACROBATICS,:RETALIATE,:STOMPINGTANTRUM,:LOWKICK,:AGILITY,
                     :SUBSTITUTE,:SLEEPTALK,:TAUNT,:SUPERPOWER,:BULKUP,:CLOSECOMBAT,
                     :BRAVEBIRD,:HURRICANE,:THROATCHOP,:COACHING,:DUALWINGBEAT,
                     :SNORE,:BOUNCE,:LOWSWEEP]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# MOLTRES

MultipleForms.register(:MOLTRES,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[139]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FLYING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [90,85,90,90,100,125] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:BERSERK),0]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:GUST],[1,:LEER],[5,:PAYBACK],[10,:SAFEGUARD],
                     [15,:WINGATTACK],[20,:AGILITY],[25,:ANCIENTPOWER],[30,:SUCKERPUNCH],
                     [35,:AIRSLASH],[40,:AFTERYOU],[45,:FIERYWRATH],
                     [50,:NASTYPLOT],[55,:HURRICANE],[60,:ENDURE],[65,:MEMENTO],
                     [70,:SKYATTACK]]
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
                     :FLY,:HYPERBEAM,:GIGAIMPACT,:SAFEGUARD,:REST,:PROTECT,
                     :STEELWING,:FACADE,:UTURN,:PAYBACK,:ROUND,:HEX,:SNARL,:AIRSLASH,
                     :AGILITY,:SUBSTITUTE,:SLEEPTALK,:SHADOWBALL,:TAUNT,:HYPERVOICE,
                     :DARKPULSE,:BRAVEBIRD,:NASTYPLOT,:FOULPLAY,:HURRICANE,:LASHOUT,
                     :DUALWINGBEAT,:SNORE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SLOWKING

MultipleForms.register(:SLOWKING,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[139]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:POISON) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [95,65,80,30,110,110] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:CURIOUSMEDICINE),0],[getID(PBAbilities,:OWNTEMPO),1],[getID(PBAbilities,:REGENERATOR),2]]
   else;   next                                       
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:EERIESPELL],[1,:NASTYPLOT],[1,:POWERGEM],[1,:SWAGGER],
                     [1,:TACKLE],[1,:GROWL],[1,:ACID],[1,:CURSE],[9,:YAWN],
                     [12,:CONFUSION],[15,:DISABLE],[18,:WATERPULSE],
                     [21,:HEADBUTT],[24,:ZENHEADBUTT],[27,:AMNESIA],[30,:SURF],
                     [33,:SLACKOFF],[36,:PSYCHIC],[39,:PSYCHUP],[42,:RAINDANCE],
                     [45,:HEALPULSE]]
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
                     :THUNDERWAVE,:DIG,:LIGHTSCREEN,:SAFEGUARD,:REST,:SNORE,:PROTECT,:ICYWIND,
                     :ATTRACT,:RAINDANCE,:SUNNYDAY,:HAIL,:FACADE,:DIVE,:TRICKROOM,:WONDERROOM,
                     :ROUND,:BULLDOZE,:FLAMETHROWER,:SURF,:HYDROPUMP,:ICEBEAM,:BLIZZARD,:EARTHQUAKE,
                     :PSYCHIC,:FIREBLAST,:SUBSTITUTE,:SLEEPTALK,:PSYSHOCK,:IRONTAIL,:SHADOWBALL,
                     :TRICK,:SKILLSWAP,:CALMMIND,:ZENHEADBUTT,:GRASSKNOT,:STOREDPOWER,:TRIATTACK,
                     :SCALD,:LIQUIDATION,:BRINE,:PSYCHICTERRAIN,:WEATHERBALL,:AMNESIA,:AVALANCHE,
                     :EXPANDINGFORCE,:BRICKBREAK,:DRAINPUNCH,:FOCUSBLAST,:GIGAIMPACT,:HYPERBEAM,
                     :ICEPUNCH,:IRONDEFENSE,:MUDDYWATER,:NASTYPLOT,:POISONJAB,:RAZORSHELL,:SLUDGEBOMB,
                     :SLUDGEWAVE,:VENOSHOCK,:EXPANDINGFORCE,:SNORE,:FLING]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# CORSOLA

MultipleForms.register(:CORSOLA,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [60,55,100,30,65,100] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:WEAKARMOR),0],
         [getID(PBAbilities,:CURSEDBODY),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:HARDEN],[5,:ASTONISH],[10,:DISABLE],[15,:SPITE],
                     [20,:ANCIENTPOWER],[25,:HEX],[30,:CURSE],[35,:STRENGTHSAP],
                     [40,:POWERGEM],[45,:NIGHTSHADE],[50,:GRUDGE],[55,:MIRRORCOAT]]
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
                     :DIG,:LIGHTSCREEN,:REFLECT,:SAFEGUARD,:ROCKSLIDE,:ICYWIND,:SANDSTORM,
                     :REST,:SNORE,:PROTECT,:ATTRACT,:SUNNYDAY,:FACADE,:RAINDANCE,:HAIL,
                     :ROCKTOMB,:ICICLESPEAR,:ROUND,:ROCKBLAST,:BULLDOZE,:STOMPINGTANTRUM,
                     :HYDROPUMP,:SURF,:ICEBEAM,:SUBSTITUTE,:SLEEPTALK,:BLIZZARD,:EARTHQUAKE,
                     :PSYCHIC,:SHADOWBALL,:IRONDEFENSE,:CALMMIND,:POWERGEM,:EARTHPOWER,
                     :STONEEDGE,:STEALTHROCK,:SCALD,:THROATCHOP,:LIQUIDATION,:NATUREPOWER,
                     :WATERPULSE,:METEORBEAM]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# ZIGZAGOON

MultipleForms.register(:ZIGZAGOON,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:PICKUP),0],
         [getID(PBAbilities,:GLUTTONY),1],
         [getID(PBAbilities,:QUICKFEET),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:LEER],[3,:SANDATTACK],[6,:LICK],
                     [9,:SNARL],[12,:HEADBUTT],[15,:BABYDOLLEYES],[18,:PINMISSILE],
                     [21,:REST],[24,:TAKEDOWN],[27,:SCARYFACE],[30,:COUNTER],
                     [33,:TAUNT],[36,:DOUBLEEDGE]]
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
                     :THUNDERWAVE,:DIG,:REST,:THIEF,:SNORE,:PROTECT,
                     :ICYWIND,:ATTRACT,:RAINDANCE,:SUNNYDAY,:FACADE,:HELPINGHAND,
                     :PAYBACK,:FLING,:ROUND,:RETALIATE,:SNARL,:SURF,:ICEBEAM,:BLIZZARD,
                     :THUNDERBOLT,:THUNDER,:SUBSTITUTE,:SLEEPTALK,:IRONTAIL,:SHADOWBALL,
                     :TAUNT,:TRICK,:HYPERVOICE,:SEEDBOMB,:GUNKSHOT,:GRASSKNOT,:WORKUP,
                     :KNOCKOFF,:LASHOUT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# LINOONE

MultipleForms.register(:LINOONE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:PICKUP),0],
         [getID(PBAbilities,:GLUTTONY),1],
         [getID(PBAbilities,:QUICKFEET),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:NIGHTSLASH],[1,:SWITCHEROO],[1,:PINMISSILE],[1,:BABYDOLLEYES],
                     [1,:TACKLE],[1,:LEER],[1,:SANDATTACK],[1,:LICK],[9,:SNARL],[12,:HEADBUTT],
                     [15,:HONECLAWS],[18,:FURYSWIPES],[23,:REST],[28,:TAKEDOWN],[33,:SCARYFACE],
                     [38,:COUNTER],[43,:TAUNT],[48,:DOUBLEEDGE]]
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
                     :HYPERBEAM,:GIGAIMPACT,:THUNDERWAVE,:DIG,:REST,:THIEF,:SNORE,:PROTECT,
                     :ICYWIND,:ATTRACT,:RAINDANCE,:SUNNYDAY,:FACADE,:HELPINGHAND,:PAYBACK,
                     :FLING,:SHADOWCLAW,:ROUND,:RETALIATE,:SNARL,:STOMPINGTANTRUM,:SURF,:ICEBEAM,
                     :BLIZZARD,:THUNDERBOLT,:THUNDER,:SUBSTITUTE,:SLEEPTALK,:IRONTAIL,:SHADOWBALL,
                     :TAUNT,:TRICK,:HYPERVOICE,:SEEDBOMB,:GUNKSHOT,:GRASSKNOT,:WORKUP,:THROATCHOP,
                     :HONECLAWS,:KNOCKOFF,:LASHOUT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# DARUMAKA

MultipleForms.register(:DARUMAKA,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [70,90,45,50,15,45] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:HUSTLE),0],
         [getID(PBAbilities,:INNERFOCUS),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:POWDERSNOW],[1,:TACKLE],[4,:TAUNT],[8,:BITE], 
                     [12,:AVALANCHE],[16,:WORKUP],[20,:ICEFANG],[24,:HEADBUTT],
                     [28,:ICEPUNCH],[32,:UPROAR],[36,:BELLYDRUM],[40,:BLIZZARD],
                     [44,:THRASH],[48,:SUPERPOWER]]
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
                     :FIREPUNCH,:ICEPUNCH,:SOLARBEAM,:DIG,:REST,:SNORE,:PROTECT,:ATTRACT,:FACADE,
                     :ROCKSLIDE,:THIEF,:SUNNYDAY,:WILLOWISP,:BRICKBREAK,:ROCKTOMB,:UTURN,:FLING,
                     :ICEFANG,:FIREFANG,:ROUND,:ICEBEAM,:BLIZZARD,:FLAMETHROWER,:FIREBLAST,:UPROAR,
                     :SUBSTITUTE,:SLEEPTALK,:HEATWAVE,:TAUNT,:SUPERPOWER,:OVERHEAT,:GYROBALL,
                     :FLAREBLITZ,:ZENHEADBUTT,:GRASSKNOT,:WORKUP,:INCINERATE,:POWERUPPUNCH,
                     :FOCUSPUNCH]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# DARMANITAN

MultipleForms.register(:DARMANITAN,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for Galar Form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
   next if pokemon.form==0             # Forma Normal
   case pokemon.form
   when 1; next getID(PBTypes,:ICE)    # Forma Galar
   when 2; next getID(PBTypes,:FIRE)   # Forma Daruma
   when 3; next getID(PBTypes,:ICE)    # Forma Galar Daruma
   end
},
"type2"=>proc{|pokemon|
   next if pokemon.form==0              # Forma Normal
   case pokemon.form
   when 1; next getID(PBTypes,:ICE)     # Forma Galar
   when 2; next getID(PBTypes,:PSYCHIC) # Forma Daruma
   when 3; next getID(PBTypes,:FIRE)    # Forma Galar Daruma
   end
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0                  # Forma Normal
   case pokemon.form
   when 1; next [105,140,55,95,30,55]       # Forma Galar
   when 2; next [105,30,105,55,140,105]     # Forma Daruma
   when 3; next [105,160,55,135,30,55]      # Forma Galar Daruma
  end
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:GORILLATACTICS),0],[getID(PBAbilities,:ZENMODE),2]] # Forma Galar
   when 2; next [[getID(PBAbilities,:ZENMODE),0]] # Forma Daruma
   when 3; next [[getID(PBAbilities,:ZENMODE),0]] # Forma Galar Daruma
   else;   next                                       
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:ICICLECRASH],[1,:POWDERSNOW],[1,:BITE],[1,:TACKLE],[1,:TAUNT],[12,:AVALANCHE],
                     [16,:WORKUP],[20,:ICEFANG],[24,:HEADBUTT],[28,:ICEPUNCH],[32,:UPROAR],
                     [38,:BELLYDRUM],[44,:BLIZZARD],[50,:THRASH],[56,:SUPERPOWER]]
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
                     :FIREPUNCH,:ICEPUNCH,:GIGAIMPACT,:HYPERBEAM,:SOLARBEAM,:DIG,:BODYPRESS,
                     :REST,:ROCKSLIDE,:THIEF,:SNORE,:PROTECT,:ATTRACT,:SUNNYDAY,:WORKUP,
                     :WILLOWISP,:FACADE,:BRICKBREAK,:ROCKTOMB,:UTURN,:PAYBACK,:FLING,
                     :ICEFANG,:FIREFANG,:ROUND,:BULLDOZE,:FLAMETHROWER,:ICEBEAM,:BLIZZARD,
                     :EARTHQUAKE,:PSYCHIC,:FIREBLAST,:SLEEPTALK,:SUBSTITUTE,:UPROAR,
                     :HEATWAVE,:TAUNT,:SUPERPOWER,:OVERHEAT,:IRONDEFENSE,:BULKUP,:GYROBALL,
                     :FLAREBLITZ,:FOCUSBLAST,:ZENHEADBUTT,:IRONHEAD,:STONEEDGE,:GRASSKNOT,
                     :INCINERATE,:POWERUPPUNCH,:FOCUSPUNCH,:BURNINGJEALOUSY,:LASHOUT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# YAMASK

MultipleForms.register(:YAMASK,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:GROUND) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [38,55,85,30,30,65] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:WANDERINGSPIRIT),0]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:ASTONISH],[1,:PROTECT],[4,:HAZE],[8,:NIGHTSHADE],[12,:DISABLE],
                     [16,:BRUTALSWING],[20,:CRAFTYSHIELD],[24,:HEX],[28,:MEANLOOK],[32,:SLAM],
                     [36,:CURSE],[40,:SHADOWBALL],[44,:EARTHQUAKE],[48,:POWERSPIT],
                     [48,:GUARDSPIT],[52,:DESTINYBOND]]
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
                     :SAFEGUARD,:ROCKSLIDE,:REST,:SNORE,:PROTECT,:ATTRACT,:FACADE,
                     :WILLOWISP,:RAINDANCE,:SANDSTORM,:ROCKTOMB,:PAYBACK,:TRICKROOM,
                     :WONDERROOM,:ROUND,:BRUTALSWING,:EARTHQUAKE,:SUBSTITUTE,:SLEEPTALK,
                     :PSYCHIC,:SHADOWBALL,:TRICK,:SKILLSWAP,:IRONDEFENSE,:CALMMIND,:EARTHPOWER,
                     :DARKPULSE,:ENERGYBALL,:NASTYPLOT,:ZENHEADBUTT,:ALLYSWITCH,:POLTERGEIST]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# STUNFISK

MultipleForms.register(:STUNFISK,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[32]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:GROUND) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [109,81,99,32,66,84] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:MIMICRY),0]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:MUDSLAP],[1,:TACKLE],[1,:WATERGUN],[1,:METALCLAW], 
                     [5,:ENDURE],[10,:MUDSHOT],[15,:REVENGE],[20,:METALSOUND],
                     [25,:SUCKERPUNCH],[30,:IRONDEFENSE],[35,:BOUNCE],[40,:MUDDYWATER],
                     [45,:SNAPTRAP],[50,:FLAIL],[55,:FISSURE]]
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
                     :THUNDERWAVE,:DIG,:ROCKSLIDE,:REST,:SNORE,:PROTECT,:ATTRACT,:FACADE,:BOUNCE,
                     :SANDSTORM,:RAINDANCE,:ROCKTOMB,:PAYBACK,:ICEFANG,:BULLDOZE,:EARTHQUAKE,
                     :STOMPINGTANTRUM,:ROUND,:SUBSTITUTE,:SLEEPTALK,:SURF,:SLUDGEBOMB,:CRUNCH,
                     :UPROAR,:MUDDYWATER,:IRONDEFENSE,:EARTHPOWER,:FLASHCANNON,:STONEEDGE,
                     :STEALTHROCK,:SLUDGEWAVE,:FOULPLAY,:SCALD,:STEELBEAM,:PAINSPLIT,:BIND,
                     :TERRAINPULSE,:LASHOUT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

########################################################################
######################### Formas Hisui #################################
########################################################################

# GROWLITHE

MultipleForms.register(:GROWLITHE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIRE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ROCK) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [60,75,45,50,65,50] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:INTIMIDATE),0],
         [getID(PBAbilities,:FLASHFIRE),1],
         [getID(PBAbilities,:JUSTIFIED),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[5,:EMBER],[9,:BITE],[15,:FIREFANG],
                     [21,:ROCKSLIDE],[29,:CRUNCH],[37,:DOUBLEEDGE],
                     [47,:FLAREBLITZ]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# ARCANINE

MultipleForms.register(:ARCANINE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIRE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ROCK) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [95,115,80,90,95,80] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:INTIMIDATE),0],
         [getID(PBAbilities,:FLASHFIRE),1],
         [getID(PBAbilities,:JUSTIFIED),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[5,:EMBER],[9,:BITE],[15,:FIREFANG],
                     [21,:ROCKSLIDE],[29,:CRUNCH],[29,:RAGINGFURY],
                     [37,:DOUBLEEDGE],[47,:FLAREBLITZ]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# VOLTORB

MultipleForms.register(:VOLTORB,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ELECTRIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GRASS) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [40,30,50,100,55,55] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SOUNDPROOF),0],
         [getID(PBAbilities,:STATIC),1],
         [getID(PBAbilities,:AFTERMATH),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:THUNDERSHOCK],[5,:TACKLE],[9,:THUNDERWAVE],[15,:SPARK],
                     [21,:ENERGYBALL],[29,:THUNDERBOLT],[37,:THUNDER],
                     [47,:SELFDESTRUCT]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# ELECTRODE

MultipleForms.register(:ELECTRODE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ELECTRIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GRASS) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [60,50,70,150,80,80] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SOUNDPROOF),0],
         [getID(PBAbilities,:STATIC),1],
         [getID(PBAbilities,:AFTERMATH),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:THUNDERSHOCK],[5,:TACKLE],[9,:THUNDERWAVE],[15,:SPARK],
                     [21,:ENERGYBALL],[29,:THUNDERBOLT],[37,:THUNDER],
                     [47,:SELFDESTRUCT],[47,:CHLOROBLAST]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# TYPHLOSION

MultipleForms.register(:TYPHLOSION,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIRE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [73,84,78,95,119,85] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:BLAZE),0],
         [getID(PBAbilities,:FLASHFIRE),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:QUICKATTACK],[6,:EMBER],[11,:ROLLOUT],[18,:FLAMEWHEEL],
                     [25,:SWIFT],[34,:FLAMETHROWER],[40,:INFERNALPARADE],
                     [43,:SHADOWBALL],[43,:OVERHEAT]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# QWILFISH

MultipleForms.register(:QWILFISH,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:POISON) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [65,95,85,85,55,55] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SWIFTSWIM),0],
         [getID(PBAbilities,:POISONPOINT),1],
         [getID(PBAbilities,:INTIMIDATE),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:POISONSTING],[5,:SPIKES],[9,:PINMISSILE],
                     [15,:BARBBARRAGE],[21,:WATERPULSE],[29,:POISONJAB],
                     [37,:AQUATAIL],[47,:DOUBLEEDGE],[57,:SELFDESTRUCT]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# SNEASEL

MultipleForms.register(:SNEASEL,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:POISON) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [55,95,55,115,35,75] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:INNERFOCUS),0],
         [getID(PBAbilities,:KEENEYE),1],
         [getID(PBAbilities,:POISONTOUCH),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:QUICKATTACK],[6,:ROCKSMASH],[11,:SWIFT],
                     [18,:SLASH],[25,:POISONJAB],[34,:SWORDSDANCE],
                     [43,:CLOSECOMBAT]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# SAMUROTT

MultipleForms.register(:SAMUROTT,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:WATER) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [90,108,80,85,100,65] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:TORRENT),0],
         [getID(PBAbilities,:SHELLARMOR),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[6,:AQUAJET],[11,:SWORDSDANCE],[18,:WATERPULSE],
                     [21,:CEASELESSEDGE],[25,:SLASH],[34,:AQUATAIL],
                     [40,:DARKPULSE],[43,:HYDROPUMP]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# LILLIGANT

MultipleForms.register(:LILLIGANT,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:GRASS) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [70,105,75,105,50,75] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:CHLOROPHYLL),0],
         [getID(PBAbilities,:HUSTLE),1],
         [getID(PBAbilities,:LEAFGUARD),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:ABSORB],[5,:LEAFAGE],[9,:STUNSPORE],[15,:POISONPOWDER],
                     [21,:ENERGYBALL],[29,:SLEEPPOWDER],[34,:DRAINPUNCH],
                     [37,:RECOVER],[37,:LEAFBLADE],[42,:VICTORYDANCE],
                     [47,:LEAFSTORM],[53,:PETALDANCE],[57,:CLOSECOMBAT]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# ZORUA

MultipleForms.register(:ZORUA,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:NORMAL) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [35,60,40,70,85,40] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:ILLUSION),0]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SHADOWSNEAK],[6,:SNARL],[11,:SWIFT],
                     [18,:BITTERMALICE],[25,:SLASH],[34,:SHADOWCLAW],
                     [43,:NASTYPLOT]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# ZOROARK

MultipleForms.register(:ZOROARK,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:NORMAL) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [55,100,60,110,125,60] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:ILLUSION),0]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SHADOWSNEAK],[6,:SNARL],[11,:SWIFT],
                     [18,:BITTERMALICE],[25,:SLASH],[34,:SHADOWCLAW],
                     [40,:SHADOWBALL],[43,:NASTYPLOT],[52,:EXTRASENSORY]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# BRAVIARY

MultipleForms.register(:BRAVIARY,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FLYING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [110,83,70,65,112,70] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:KEENEYE),0],
         [getID(PBAbilities,:SHEERFORCE),1],
         [getID(PBAbilities,:COMPETITIVE),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:QUICKATTACK],[6,:AERIALACE],[11,:TWISTER],
                     [18,:SLASH],[20,:AIRSLASH],[25,:ESPERWING],
                     [25,:ROOST],[34,:DOUBLEEDGE],[43,:BRAVEBIRD],
                     [52,:HURRICANE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# SLIGGOO

MultipleForms.register(:SLIGGOO,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DRAGON) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [58,75,83,40,83,113] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SAPSIPPER),0],
         [getID(PBAbilities,:OVERCOAT),1],
         [getID(PBAbilities,:GOOEY),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:BUBBLE],[6,:ACIDSPRAY],[11,:ACIDARMOR],
                     [18,:WATERPULSE],[25,:IRONHEAD],[25,:DRAGONPULSE],
                     [34,:SHELTER],[43,:HYDROPUMP]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# GOODRA

MultipleForms.register(:GOODRA,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DRAGON) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [80,100,100,60,110,150] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SAPSIPPER),0],
         [getID(PBAbilities,:OVERCOAT),1],
         [getID(PBAbilities,:GOOEY),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:BUBBLE],[6,:ACIDSPRAY],[11,:ACIDARMOR],
                     [18,:WATERPULSE],[25,:IRONHEAD],[25,:DRAGONPULSE],
                     [34,:SHELTER],[43,:HYDROPUMP]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# AVALUGG

MultipleForms.register(:AVALUGG,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ROCK) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [95,127,184,38,34,36] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:STRONGJAW),0],
         [getID(PBAbilities,:ICEBODY),1],
         [getID(PBAbilities,:STURDY),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[5,:POWDERSNOW],[9,:ICESHARD],[15,:BITE],
                     [21,:IRONDEFENSE],[29,:CRUNCH],[29,:EARTHPOWER],
                     [37,:MOUNTAINGALE],[37,:BLIZZARD],[47,:DOUBLEEDGE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# DECIDUEYE

MultipleForms.register(:DECIDUEYE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[33]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:GRASS) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [88,112,80,60,95,95] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:OVERGROW),0],
         [getID(PBAbilities,:LONGREACH),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:GUST],[6,:LEAFAGE],[11,:ROOST],[18,:AERIALACE],
                     [21,:MAGICALLEAF],[25,:AIRSLASH],[30,:AURASPHERE],
                     [34,:LEAFBLADE],[34,:TRIPLEARROWS],[40,:BRAVEBIRD],
                     [43,:LEAFSTORM]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})