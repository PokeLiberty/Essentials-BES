class PokemonGlobalMetadata
  attr_accessor :pokeradarBattery
end



class PokemonTemp
  attr_accessor :pokeradar   # [species, level, chain count, grasses (x,y,ring,rarity)]
end



################################################################################
# Uso del Poké Radar
################################################################################
def pbCanUsePokeRadar?
  # No se puede usar el Radar si no se encuentra en hierba alta
  if !PBTerrain.isJustGrass?($game_map.terrain_tag($game_player.x,$game_player.y))
    Kernel.pbMessage(_INTL("No se puede usar aquí."))
    return false
  end
  # No se puede usar si el mapa no tiene encuentros en hierbas (ignorando el Concurso Cazabichos)
  if !$PokemonEncounters.isRegularGrass?
    Kernel.pbMessage(_INTL("No se puede usar aquí."))
    return false
  end
  # No se puede usar el Radar en la bicicleta
  if $PokemonGlobal.bicycle
    Kernel.pbMessage(_INTL("No se puede usar en la bicicleta."))
    return false
  end
  # Depurador
  return true if $DEBUG && Input.press?(Input::CTRL)
  # No se puede usar el Radar si no está completamente cargado
  if $PokemonGlobal.pokeradarBattery && $PokemonGlobal.pokeradarBattery>0
    Kernel.pbMessage(_INTL("¡Se ha agotado la batería!<br>Para recargarlo, necesitas caminar otros {1} pasos.",
       $PokemonGlobal.pokeradarBattery))
    return false
  end
  return true
end

def pbUsePokeRadar
  if pbCanUsePokeRadar?
    $PokemonTemp.pokeradar=[0,0,0,[]] if !$PokemonTemp.pokeradar
    $PokemonGlobal.pokeradarBattery=50
    pbPokeRadarHighlightGrass
    return true
  end
  return false
end

def pbPokeRadarHighlightGrass(showmessage=true)
  grasses=[]   # x, y, ring (0-3 inner to outer), rarity
  # Choose 1 random tile from each ring around the player
  for i in 0...4
    r=rand((i+1)*8)
    # Get coordinates of randomly chosen tile
    x=$game_player.x
    y=$game_player.y
    if r<=(i+1)*2
      x=$game_player.x-i-1+r
      y=$game_player.y-i-1
    elsif r<=(i+1)*6-2
      x=[$game_player.x+i+1,$game_player.x-i-1][r%2]
      y=$game_player.y-i+((r-1-(i+1)*2)/2).floor
    else
      x=$game_player.x-i+r-(i+1)*6
      y=$game_player.y+i+1
    end
    # Add tile to grasses array if it's a valid grass tile
    if x>=0 && x<$game_map.width &&
       y>=0 && y<$game_map.height
      if PBTerrain.isJustGrass?($game_map.terrain_tag(x,y))
        # Choose a rarity for the grass (0=normal, 1=rare, 2=shiny)
        s=(rand(4)==0) ? 1 : 0
        if $PokemonTemp.pokeradar && $PokemonTemp.pokeradar[2]>0
          v=[(65536/SHINYPOKEMONCHANCE)-$PokemonTemp.pokeradar[2]*200,200].max
          v=0xFFFF / v
          v=rand(65536) / v
          s=2 if v==0
        end
        grasses.push([x,y,i,s])
      end
    end
  end
  if grasses.length==0
    # No se encontró hierba que se sacuda, se rompe la cadena
    Kernel.pbMessage(_INTL("Las hojas de la hierba están quietas...")) if showmessage        # The grassy patch remained quiet...
    pbPokeRadarCancel
  else
    # Mostrar animación de crujido de la hierba
    for grass in grasses
      case grass[3]
      when 0   # Crujido Normal
        $scene.spriteset.addUserAnimation(RUSTLE_NORMAL_ANIMATION_ID,grass[0],grass[1],true)
      when 1   # Crujido Enérgico
        $scene.spriteset.addUserAnimation(RUSTLE_VIGOROUS_ANIMATION_ID,grass[0],grass[1],true)
      when 2   # Crujido Shiny
        $scene.spriteset.addUserAnimation(RUSTLE_SHINY_ANIMATION_ID,grass[0],grass[1],true)
      end
    end
    $PokemonTemp.pokeradar[3]=grasses if $PokemonTemp.pokeradar
    pbWait(20)
  end
end

def pbPokeRadarCancel
  $PokemonTemp.pokeradar=nil
end

def pbPokeRadarGetShakingGrass
  if $PokemonTemp.pokeradar
    grasses=$PokemonTemp.pokeradar[3]
    return -1 if grasses.length==0
    for i in grasses
      return i[2] if $game_player.x==i[0] && $game_player.y==i[1]
    end
  end
  return -1
end

def pbPokeRadarOnShakingGrass
  return pbPokeRadarGetShakingGrass>=0
end

def pbPokeRadarGetEncounter(rarity=0)
  # Poké Radar-exclusive encounters can only be found in vigorously-shaking grass
  if rarity>0
    # Get all Poké Radar-exclusive encounters for this map
    map=$game_map.map_id rescue 0
    array=[]
    for enc in POKERADAREXCLUSIVES
      array.push(enc) if enc.length>=4 && enc[0]==map && getID(PBSpecies,enc[2])>0
    end
    # If there are any exclusives, first have a chance of encountering those
    if array.length>0
      rnd=rand(100)
      chance=0
      for enc in array
        chance+=enc[1]
        if rnd<chance
          upper=(enc[4]!=nil) ? enc[4] : enc[3]
          level=enc[3]+rand(1+upper-enc[3])
          return [getID(PBSpecies,enc[2]),level]
        end
      end
    end
  end
  # Didn't choose a Poké Radar-exclusive species, choose a regular encounter instead
  return $PokemonEncounters.pbEncounteredPokemon($PokemonEncounters.pbEncounterType,rarity+1)
end

################################################################################
# Event handlers
################################################################################
EncounterModifier.register(proc {|encounter|
   if !$PokemonEncounters.isRegularGrass? || 
     !$PokemonEncounters.isEncounterPossibleHere? ||
     $PokemonGlobal.partner
     pbPokeRadarCancel
     return encounter
   end
   grass=pbPokeRadarGetShakingGrass
   if grass>=0
     # Get rarity of shaking grass
     s=0
     for g in $PokemonTemp.pokeradar[3]
       s=g[3] if g[2]==grass
     end
     if $PokemonTemp.pokeradar[2]>0
      if s==2 || rand(100)<86+grass*4+($PokemonTemp.pokeradar[2]/4).floor
         # Continue the chain
         encounter=[$PokemonTemp.pokeradar[0],$PokemonTemp.pokeradar[1]]
       else
         # Break the chain, force an encounter with a different species
         100.times do
           break if encounter && encounter[0]!=$PokemonTemp.pokeradar[0]
           encounter=$PokemonEncounters.pbEncounteredPokemon($PokemonEncounters.pbEncounterType)
         end
         pbPokeRadarCancel
       end
     else
       # Force random wild encounter, vigorous shaking means rarer species
       encounter=pbPokeRadarGetEncounter(s)
     end
   else
     pbPokeRadarCancel if encounter   # El objetivo no se encuentra en la hierba que sacudida
   end
   return encounter
})

Events.onWildPokemonCreate+=proc {|sender,e|
   pokemon=e[0]
   if $PokemonTemp.pokeradar
     grasses=$PokemonTemp.pokeradar[3]
     return if !grasses
     for grass in grasses
       if $game_player.x==grass[0] && $game_player.y==grass[1]
         pokemon.makeShiny if grass[3]==2
         return
       end
     end
   end
}

Events.onWildBattleEnd+=proc {|sender,e|
   species=e[0]
   level=e[1]
   decision=e[2]
  if !$PokemonEncounters.isRegularGrass? || ($PokemonGlobal && $PokemonGlobal.bicycle)
     pbPokeRadarCancel
     return
   end
   if $PokemonTemp.pokeradar && (decision==1 || decision==4) # Defeated/caught
     $PokemonTemp.pokeradar[0]=species
     $PokemonTemp.pokeradar[1]=level
     $PokemonTemp.pokeradar[2]+=1
     $PokemonTemp.pokeradar[2]=40 if $PokemonTemp.pokeradar[2]>40
     pbPokeRadarHighlightGrass(false)
   else
     pbPokeRadarCancel
   end
}

Events.onStepTaken+=proc {|sender,e|
   if $PokemonGlobal.pokeradarBattery && $PokemonGlobal.pokeradarBattery>0 &&
      !$PokemonTemp.pokeradar
     $PokemonGlobal.pokeradarBattery-=1
   end
   if !$PokemonEncounters.isRegularGrass? ||
      !PBTerrain.isJustGrass?($game_map.terrain_tag($game_player.x,$game_player.y))
     pbPokeRadarCancel
   end
}

Events.onMapUpdate+=proc {|sender,e|
   if $PokemonGlobal && $PokemonTemp && $PokemonGlobal.bicycle
     pbPokeRadarCancel
   end
}

Events.onMapChange+=proc {|sender,e|
   pbPokeRadarCancel
}

################################################################################
# Item handlers
################################################################################
ItemHandlers.addUseInField(:POKERADAR, proc {
  next 0 if !pbCanUsePokeRadar?
   next pbUsePokeRadar
})

ItemHandlers.addUseFromBag(:POKERADAR, proc {
  next (pbCanUsePokeRadar?) ? 2 : 0
})