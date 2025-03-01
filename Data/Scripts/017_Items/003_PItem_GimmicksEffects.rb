##################################################################################
# Z Crystals                                                                     #
##################################################################################

ItemHandlers::UseOnPokemon.add(:NORMALIUMZ,proc{|item,pokemon,scene|
  type=0  if isConst?(item,PBItems,:NORMALIUMZ)
  type=1  if isConst?(item,PBItems,:FIGHTINIUMZ)
  type=2  if isConst?(item,PBItems,:FLYINIUMZ)
  type=3  if isConst?(item,PBItems,:POISONIUMZ)
  type=4  if isConst?(item,PBItems,:GROUNDIUMZ)
  type=5  if isConst?(item,PBItems,:ROCKIUMZ)
  type=6  if isConst?(item,PBItems,:BUGINIUMZ)
  type=7  if isConst?(item,PBItems,:GHOSTIUMZ)
  type=8  if isConst?(item,PBItems,:STEELIUMZ)
  type=10 if isConst?(item,PBItems,:FIRIUMZ)
  type=11 if isConst?(item,PBItems,:WATERIUMZ)
  type=12 if isConst?(item,PBItems,:GRASSIUMZ)
  type=13 if isConst?(item,PBItems,:ELECTRIUMZ)
  type=14 if isConst?(item,PBItems,:PSYCHICCORE)
  type=15 if isConst?(item,PBItems,:ICIUMZ)
  type=16 if isConst?(item,PBItems,:DRAGONIUMZ)
  type=17 if isConst?(item,PBItems,:DARKINIUMZ)
  type=18 if isConst?(item,PBItems,:FAIRIUMZ)

   canuse=false  
   for move in pokemon.moves
     if move.type==type
       canuse=true
     end
   end
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(item)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(item)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})

ItemHandlers::UseOnPokemon.copy(:NORMALIUMZ,:FIGHTINIUMZ,:FLYINIUMZ,:POISONIUMZ,
:GROUNDIUMZ,:ROCKIUMZ,:BUGINIUMZ,:GHOSTIUMZ,:STEELIUMZ,:FIRIUMZ,:WATERIUMZ,
:GRASSIUMZ,:ELECTRIUMZ,:PSYCHICCORE,:ICIUMZ,:DRAGONIUMZ,:DARKINIUMZ,:FAIRIUMZ)

ItemHandlers::UseOnPokemon.add(:ALORAICHIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:THUNDERBOLT)
       canuse=true
     end
   end
   if pokemon.species!=26 || pokemon.form!=1
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:ALORAICHIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:ALORAICHIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})
ItemHandlers::UseOnPokemon.add(:DECIDIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:SPIRITSHACKLE)
       canuse=true
     end
   end
   if pokemon.species!=724
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:DECIDIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:DECIDIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})
ItemHandlers::UseOnPokemon.add(:INCINIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:DARKESTLARIAT)
       canuse=true
     end
   end
   if pokemon.species!=727
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:INCINIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:INCINIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})
ItemHandlers::UseOnPokemon.add(:PRIMARIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:SPARKLINGARIA)
       canuse=true
     end
   end
   if pokemon.species!=730
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:PRIMARIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:PRIMARIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})
ItemHandlers::UseOnPokemon.add(:EEVIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:LASTRESORT)
       canuse=true
     end
   end
   if pokemon.species!=133
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:EEVIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:EEVIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})
ItemHandlers::UseOnPokemon.add(:PIKANIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:VOLTTACKLE)
       canuse=true
     end
   end
   if pokemon.species!=25
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:PIKANIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:PIKANIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})
ItemHandlers::UseOnPokemon.add(:SNORLIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:GIGAIMPACT)
       canuse=true
     end
   end
   if pokemon.species!=143
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:SNORLIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:SNORLIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})
ItemHandlers::UseOnPokemon.add(:MEWNIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:PSYCHIC)
       canuse=true
     end
   end
   if pokemon.species!=151
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:MEWNIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:MEWNIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})
ItemHandlers::UseOnPokemon.add(:TAPUNIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:NATURESMADNESS)
       canuse=true
     end
   end
   if !(pokemon.species==785 || pokemon.species==786 || pokemon.species==787 || pokemon.species==788)
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:TAPUNIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:TAPUNIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})

ItemHandlers::UseOnPokemon.add(:MARSHADIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:SPECTRALTHIEF)
       canuse=true
     end
   end
   if pokemon.species!=802
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:MARSHADIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:MARSHADIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})

ItemHandlers::UseOnPokemon.add(:PIKASHUNIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:THUNDERBOLT)
       canuse=true
     end
   end
   if pokemon.species!=25 || pokemon.form==0
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:PIKASHUNIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:PIKASHUNIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})

ItemHandlers::UseOnPokemon.add(:ULTRANECROZIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:PHOTONGEYSER)
       canuse=true
     end
   end
   if pokemon.species!=800 || pokemon.form==3
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:ULTRANECROZIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:ULTRANECROZIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})



ItemHandlers::UseOnPokemon.add(:LYCANIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:STONEEDGE)
       canuse=true
     end
   end
   if pokemon.species!=747
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:LYCANIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:LYCANIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})

ItemHandlers::UseOnPokemon.add(:MIMIKIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:PLAYROUGH)
       canuse=true
     end
   end
   if pokemon.species!=778
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:MIMIKIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:MIMIKIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})

ItemHandlers::UseOnPokemon.add(:KOMMONIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:CLANGINGSCALES)
       canuse=true
     end
   end
   if pokemon.species!=784
     canuse=false
   end  
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:KOMMONIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:KOMMONIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})

ItemHandlers::UseOnPokemon.add(:SOLGANIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:SUNSTEELSTRIKE)
       canuse=true
     end
   end
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:SOLGANIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:SOLGANIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})

ItemHandlers::UseOnPokemon.add(:LUNALIUMZ,proc{|item,pokemon,scene|
   canuse=false  
   for move in pokemon.moves
     if move.id==getID(PBMoves,:MOONGEISTBEAM)
       canuse=true
     end
   end
   if canuse
     scene.pbDisplay(_INTL("¡El {1} se le entregará a {2} para que pueda usar su Poder Z!",PBItems.getName(item),pokemon.name))
     if pokemon.item!=0
      itemname=PBItems.getName(pokemon.item)
      scene.pbDisplay(_INTL("{1} ya tiene un {2}.\1",pokemon.name,itemname))
      if scene.pbConfirm(_INTL("¿Quieres cambiar los objetos?"))  
        if !$PokemonBag.pbStoreItem(pokemon.item)
          scene.pbDisplay(_INTL("La Bolsa está llena. No se pudo quitar el objeto del Pokémon."))
        else
          pokemon.setItem(:LUNALIUMZ)
          scene.pbDisplay(_INTL("El {1} fue tomado y reemplazado por el {2}.",itemname,PBItems.getName(item)))
          next true
        end
      end
    else
      pokemon.setItem(:LUNALIUMZ)
      scene.pbDisplay(_INTL("¡El {1} se le entregará a {2}!",pokemon.name,PBItems.getName(item)))
      next true      
    end
  else      
    scene.pbDisplay(_INTL("No tendrá efecto."))
    next false
  end
})

ItemHandlers::UseOnPokemon.add(:NORMALCORE,proc{|item,pokemon,scene|
  type=0  if isConst?(item,PBItems,:NORMALCORE)
  type=1  if isConst?(item,PBItems,:FIGHTINGCORE)
  type=2  if isConst?(item,PBItems,:FLYINGCORE)
  type=3  if isConst?(item,PBItems,:POISONCORE)
  type=4  if isConst?(item,PBItems,:GROUNDCORE)
  type=5  if isConst?(item,PBItems,:ROCKCORE)
  type=6  if isConst?(item,PBItems,:BUGCORE)
  type=7  if isConst?(item,PBItems,:GHOSTCORE)
  type=8  if isConst?(item,PBItems,:STEELCORE)
  type=10 if isConst?(item,PBItems,:FIRECORE)
  type=11 if isConst?(item,PBItems,:WATERCORE)
  type=12 if isConst?(item,PBItems,:GRASSCORE)
  type=13 if isConst?(item,PBItems,:ELECTRICCORE)
  type=14 if isConst?(item,PBItems,:PSYCHICCORE)
  type=15 if isConst?(item,PBItems,:ICECORE)
  type=16 if isConst?(item,PBItems,:DRAGONCORE)
  type=17 if isConst?(item,PBItems,:DARKCORE)
  type=18 if isConst?(item,PBItems,:FAIRYCORE)
  type=getConst(PBTypes,:STELLAR) if isConst?(item,PBItems,:STELLARCORE)
  if pokemon.teratype==type || pokemon.species==getConst(PBSpecies,:OGERPON) || pokemon.species==getConst(PBSpecies,:TERAPAGOS)
    scene.pbDisplay(_INTL("¡No tendrá efecto!"))
    next false
  else
    pokemon.teratype=type
    scene.pbDisplay(_INTL("El teratipo de {1} cambió a {2}",pokemon.name,PBTypes.getName(type)))
    next true
  end
})

ItemHandlers::UseOnPokemon.copy(:NORMALCORE,:FIGHTINGCORE,:FLYINGCORE,:POISONCORE,:GROUNDCORE,:ROCKCORE,:BUGCORE,
:GHOSTCORE,:STEELCORE,:FIRECORE,:WATERCORE,:GRASSCORE,:ELECTRICCORE,:PSYCHICCORE,:ICECORE,:DRAGONCORE,
:DARKCORE,:FAIRYCORE,:STELLARCORE)

ItemHandlers::UseOnPokemon.add(:TERARANDOMITEM,proc{|item,pokemon,scene|
  loop do
    newtype = rand(PBTypes.maxValue)
    break unless [pokemon.teratype,9,getConst(PBTypes,:STELLAR)].include?(newtype)
  end
  typename=PBTypes.getName(newtype)
  scene.pbDisplay(_INTL("El teratipo de {1} ha cambiado a {2}.",pokemon.name,typename))
  pokemon.teratype=newtype
})

##################################################################################
# BES-T MO ITEMS    
# Traido desde la base de Pira, son objetos que no estan en el PBS, dejados por compatibilidad.
##################################################################################
ItemHandlers::UseFromBag.add(:PICKAXE,proc{|item| next canUseRockSmash? ? 2:0 })

ItemHandlers::UseInField.add(:PICKAXE,proc{|item| useRockSmash if canUseRockSmash?})

ItemHandlers::UseFromBag.add(:SHEARS,proc{|item| next canUseCut? ? 2:0 })

ItemHandlers::UseInField.add(:SHEARS,proc{|item| useCut if canUseCut?})

ItemHandlers::UseFromBag.add(:GLOVES,proc{|item| next canUseStrength? ? 2:0 })

ItemHandlers::UseInField.add(:GLOVES,proc{|item| useStrength if canUseStrength?})

ItemHandlers::UseFromBag.add(:SURFBOARD,proc{|item| next canUseSurf? ? 2:0 })

ItemHandlers::UseInField.add(:SURFBOARD,proc{|item| useSurf if canUseSurf?})
