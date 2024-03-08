#===============================================================================
# Este script implementa los objetos incluidos por defecto en Pokemon Essentials.
#===============================================================================

#===============================================================================
# UseFromBag handlers
# Valores de retorno: 0 = no usado
#                     1 = usado, objeto no consumido
#                     2 = cierra la mochila para usarlo, objeto no consumido
#                     3 = usado, objeto consumido
#                     4 = cierra la mochila para usarlo, objeto consumido
#===============================================================================

def pbRepel(item,steps)
  if $PokemonGlobal.repel>0
    Kernel.pbMessage(_INTL("Pero todavía tiene efecto el último Repente utilizado."))
    return 0
  else
    Kernel.pbMessage(_INTL("{1} ha usado {2}.",$Trainer.name,PBItems.getName(item)))
    $PokemonGlobal.repel=steps
    return 3
  end
end

ItemHandlers::UseFromBag.add(:REPEL,proc{|item| pbRepel(item,100) })

ItemHandlers::UseFromBag.add(:SUPERREPEL,proc{|item| pbRepel(item,200) })

ItemHandlers::UseFromBag.add(:MAXREPEL,proc{|item| pbRepel(item,250) })

ItemHandlers::UseFromBag.add(:PICKAXE,proc{|item| next canUseRockSmash? ? 2:0 })

ItemHandlers::UseInField.add(:PICKAXE,proc{|item| useRockSmash if canUseRockSmash?})

ItemHandlers::UseFromBag.add(:SHEARS,proc{|item| next canUseCut? ? 2:0 })

ItemHandlers::UseInField.add(:SHEARS,proc{|item| useCut if canUseCut?})

ItemHandlers::UseFromBag.add(:GLOVES,proc{|item| next canUseStrength? ? 2:0 })

ItemHandlers::UseInField.add(:GLOVES,proc{|item| useStrength if canUseStrength?})

ItemHandlers::UseFromBag.add(:SURFBOARD,proc{|item| next canUseSurf? ? 2:0 })

ItemHandlers::UseInField.add(:SURFBOARD,proc{|item| useSurf if canUseSurf?})

Events.onStepTaken+=proc {
   if !PBTerrain.isIce?($game_player.terrain_tag)   # No debería contar cuando se desplaza sobre el hielo
     if $PokemonGlobal.repel>0
       $PokemonGlobal.repel-=1
       if $PokemonGlobal.repel<=0
         Kernel.pbMessage(_INTL("El Repelente dejó de tener efecto..."))
         ret=pbChooseItemFromList(_INTL("¿Quieres utilizar otro Repelente?"),1,
            :REPEL,:SUPERREPEL,:MAXREPEL)
         pbUseItem($PokemonBag,ret) if ret>0
       end
     end
   end
}

ItemHandlers::UseFromBag.add(:BLACKFLUTE,proc{|item|
   Kernel.pbMessage(_INTL("¡{1} ha usado una {2}!",$Trainer.name,PBItems.getName(item)))
   Kernel.pbMessage(_INTL("¡{1} se encontrará con más Pokémon de nivel alto!",$Trainer.name))
   $PokemonMap.blackFluteUsed=true
   $PokemonMap.whiteFluteUsed=false
   next 1
})

ItemHandlers::UseFromBag.add(:WHITEFLUTE,proc{|item|
   Kernel.pbMessage(_INTL("¡{1} ha usado una {2}!",$Trainer.name,PBItems.getName(item)))
   Kernel.pbMessage(_INTL("¡{1} se encontrará con más Pokémon de nivel bajo!",$Trainer.name))
   $PokemonMap.blackFluteUsed=false
   $PokemonMap.whiteFluteUsed=true
   next 1
})

ItemHandlers::UseFromBag.add(:HONEY,proc{|item| next 4 })

ItemHandlers::UseFromBag.add(:ESCAPEROPE,proc{|item|
   if $game_player.pbHasDependentEvents?
     Kernel.pbMessage(_INTL("No se puede utilizar cuando vas con alguien."))
     next 0
   end
   if ($PokemonGlobal.escapePoint rescue false) && $PokemonGlobal.escapePoint.length>0
     next 4 # End screen and consume item
   else
     Kernel.pbMessage(_INTL("Eso no se puede usar aquí."))
     next 0
   end
})

ItemHandlers::UseFromBag.add(:SACREDASH,proc{|item|
   revived=0
   if $Trainer.pokemonCount==0
     Kernel.pbMessage(_INTL("No hay Pokémon."))
     next 0
   end
   pbFadeOutIn(99999){
      scene=PokemonScreen_Scene.new
      screen=PokemonScreen.new(scene,$Trainer.party)
      screen.pbStartScene(_INTL("Usando el objeto..."),false)
      for i in $Trainer.party
       if i.hp<=0 && !i.isEgg?
         revived+=1
         i.heal
         screen.pbDisplay(_INTL("{1} ha recuperado los PS.",i.name))
       end
     end
     if revived==0
       screen.pbDisplay(_INTL("No tendrá ningún efecto."))
     end
     screen.pbEndScene
   }
   next (revived==0) ? 0 : 3
})

ItemHandlers::UseFromBag.add(:BICYCLE,proc{|item|
   next pbBikeCheck ? 2 : 0
})

ItemHandlers::UseFromBag.copy(:BICYCLE,:MACHBIKE,:ACROBIKE)

ItemHandlers::UseFromBag.add(:OLDROD,proc{|item|
   terrain=Kernel.pbFacingTerrainTag
   notCliff=$game_map.passable?($game_player.x,$game_player.y,$game_player.direction)
   if (PBTerrain.isWater?(terrain) && !$PokemonGlobal.surfing && notCliff) ||
      (PBTerrain.isWater?(terrain) && $PokemonGlobal.surfing)
     next 2
   else
     Kernel.pbMessage(_INTL("Eso no se puede usar aquí."))
     next 0
   end
})

ItemHandlers::UseFromBag.copy(:OLDROD,:GOODROD,:SUPERROD)

ItemHandlers::UseFromBag.add(:ITEMFINDER,proc{|item| next 2 })

ItemHandlers::UseFromBag.copy(:ITEMFINDER,:DOWSINGMCHN,:DOWSINGMACHINE)

ItemHandlers::UseFromBag.add(:TOWNMAP,proc{|item|
   pbShowMap(-1,false)
   next 1 # Continue
})

ItemHandlers::UseFromBag.add(:COINCASE,proc{|item|
   Kernel.pbMessage(_INTL("Fichas: {1}",$PokemonGlobal.coins))
   next 1 # Continue
})

ItemHandlers::UseFromBag.add(:EXPALL,proc{|item|
   $PokemonBag.pbChangeItem(:EXPALL,:EXPALLOFF)
   Kernel.pbMessage(_INTL("Has desactivado el Repartir Exp."))
   next 1 # Continue
})

ItemHandlers::UseFromBag.add(:EXPALLOFF,proc{|item|
   $PokemonBag.pbChangeItem(:EXPALLOFF,:EXPALL)
   Kernel.pbMessage(_INTL("Has activado el Repartir Exp."))
   next 1 # Continue
})

#===============================================================================
# UseInField handlers
#===============================================================================

ItemHandlers::UseInField.add(:HONEY,proc{|item|  
   Kernel.pbMessage(_INTL("{1} ha usado {2}.",$Trainer.name,PBItems.getName(item)))
   pbSweetScent
})

ItemHandlers::UseInField.add(:ESCAPEROPE,proc{|item|
   escape=($PokemonGlobal.escapePoint rescue nil)
   if !escape || escape==[]
     Kernel.pbMessage(_INTL("Eso no se puede usar aquí."))
     next
   end
   if $game_player.pbHasDependentEvents?
     Kernel.pbMessage(_INTL("No se puede utilizar cuando vas con alguien."))
     next
   end
   Kernel.pbMessage(_INTL("{1} ha usado {2}.",$Trainer.name,PBItems.getName(item)))
   pbFadeOutIn(99999){
      Kernel.pbCancelVehicles
      $game_temp.player_new_map_id=escape[0]
      $game_temp.player_new_x=escape[1]
      $game_temp.player_new_y=escape[2]
      $game_temp.player_new_direction=escape[3]
      $scene.transfer_player
      $game_map.autoplay
      $game_map.refresh
   }
   pbEraseEscapePoint
})

ItemHandlers::UseInField.add(:BICYCLE,proc{|item|
   if pbBikeCheck
     if $PokemonGlobal.bicycle
       Kernel.pbDismountBike
     else
       Kernel.pbMountBike 
     end
   end
})

ItemHandlers::UseInField.copy(:BICYCLE,:MACHBIKE,:ACROBIKE)

ItemHandlers::UseInField.add(:OLDROD,proc{|item|
   terrain=Kernel.pbFacingTerrainTag
   notCliff=$game_map.passable?($game_player.x,$game_player.y,$game_player.direction)
   if !PBTerrain.isWater?(terrain) || (!notCliff && !$PokemonGlobal.surfing)
     Kernel.pbMessage(_INTL("Eso no se puede usar aquí."))
     next
   end
   encounter=$PokemonEncounters.hasEncounter?(EncounterTypes::OldRod)
   if pbFishing(encounter,1)
     pbEncounter(EncounterTypes::OldRod)
   end
})

ItemHandlers::UseInField.add(:GOODROD,proc{|item|
   terrain=Kernel.pbFacingTerrainTag
   notCliff=$game_map.passable?($game_player.x,$game_player.y,$game_player.direction)
   if !PBTerrain.isWater?(terrain) || (!notCliff && !$PokemonGlobal.surfing)
     Kernel.pbMessage(_INTL("Eso no se puede usar aquí."))
     next
   end
   encounter=$PokemonEncounters.hasEncounter?(EncounterTypes::GoodRod)
   if pbFishing(encounter,2)
     pbEncounter(EncounterTypes::GoodRod)
   end
})

ItemHandlers::UseInField.add(:SUPERROD,proc{|item|
   terrain=Kernel.pbFacingTerrainTag
   notCliff=$game_map.passable?($game_player.x,$game_player.y,$game_player.direction)
   if !PBTerrain.isWater?(terrain) || (!notCliff && !$PokemonGlobal.surfing)
     Kernel.pbMessage(_INTL("Eso no se puede usar aquí."))
     next
   end
   encounter=$PokemonEncounters.hasEncounter?(EncounterTypes::SuperRod)
   if pbFishing(encounter,3)
     pbEncounter(EncounterTypes::SuperRod)
   end
})

ItemHandlers::UseInField.add(:ITEMFINDER,proc{|item|
   event=pbClosestHiddenItem
   if !event
     Kernel.pbMessage(_INTL("... ... ... ...¡Nada!\r\nNo responde."))
   else
     offsetX=event.x-$game_player.x
     offsetY=event.y-$game_player.y
     if offsetX==0 && offsetY==0
       for i in 0...32
         Graphics.update
         Input.update
         $game_player.turn_right_90 if (i&7)==0
         pbUpdateSceneMap
       end
       Kernel.pbMessage(_INTL("¡El {1} indica algo justo bajo los pies!\1",PBItems.getName(item)))
     else
       direction=$game_player.direction
       if offsetX.abs>offsetY.abs
         direction=(offsetX<0) ? 4 : 6         
       else
         direction=(offsetY<0) ? 8 : 2
       end
       for i in 0...8
         Graphics.update
         Input.update
         if i==0
           $game_player.turn_down if direction==2
           $game_player.turn_left if direction==4
           $game_player.turn_right if direction==6
           $game_player.turn_up if direction==8
         end
         pbUpdateSceneMap
       end
       Kernel.pbMessage(_INTL("¡Alto!\n¡El {1} está respondiendo!\1",PBItems.getName(item)))
       Kernel.pbMessage(_INTL("¡Hay algo enterrado muy cerca!"))
     end
   end
})

ItemHandlers::UseInField.copy(:ITEMFINDER,:DOWSINGMCHN,:DOWSINGMACHINE)

ItemHandlers::UseInField.add(:TOWNMAP,proc{|item|
   pbShowMap(-1,false)
})

ItemHandlers::UseInField.add(:COINCASE,proc{|item|
   Kernel.pbMessage(_INTL("Fichas: {1}",$PokemonGlobal.coins))
   next 1                 # Continue
})

#===============================================================================
# UseOnPokemon handlers
#===============================================================================

ItemHandlers::UseOnPokemon.add(:FIRESTONE,proc{|item,pokemon,scene|
   if (pokemon.isShadow? rescue false)
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   end
   newspecies=pbCheckEvolution(pokemon,item)
   if newspecies<=0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pbFadeOutInWithMusic(99999){
        evo=PokemonEvolutionScene.new
        evo.pbStartScreen(pokemon,newspecies)
        evo.pbEvolution(false)
        evo.pbEndScreen
        if scene.is_a?(PokemonBag_Scene)
          scene.pbRefreshAnnotations(proc{|p| pbCheckEvolution(p,item)>0 })
          scene.pbRefresh
        end
     }
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:FIRESTONE,
   :THUNDERSTONE,:WATERSTONE,:LEAFSTONE,:MOONSTONE,
   :SUNSTONE,:DUSKSTONE,:DAWNSTONE,:SHINYSTONE,:ICESTONE,
   :TARTAPPLE,:SWEETAPPLE,:CRACKEDPOT,:DEEPSEASCALE,:DEEPSEATOOTH,
   :ELECTIRIZER,:MAGMARIZER,:PROTECTOR,:REAPERCLOTH,:UPGRADE,
   :DUBIOUSDISC,:PRISMSCALE,:DRAGONSCALE,:SACHET,:WHIPPEDDREAM,
   :METALCOAT,:KINGSROCK,:GALARICAWREATH,:GALARICACUFF,:SCROLLOFDARKNESS,
   :BLACKAUGURITE,:PEATBLOCK,:MALICIOUSARMOR,:AUSPICIOUSARMOR,:LEADERSCREST,:METALALLOY)

ItemHandlers::UseOnPokemon.add(:SCROLLOFWATERS,proc{|item,pokemon,scene|
   if (pokemon.isShadow? rescue false)
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   end
   newspecies=pbCheckEvolution(pokemon,item)
   if newspecies<=0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.form = 1
     pbFadeOutInWithMusic(99999){
        evo=PokemonEvolutionScene.new
        evo.pbStartScreen(pokemon,newspecies)
        evo.pbEvolution(false)
        evo.pbEndScreen
        if scene.is_a?(PokemonBag_Scene)
          scene.pbRefreshAnnotations(proc{|p| pbCheckEvolution(p,item)>0 })
          scene.pbRefresh
        end
     }
     next true
   end
})  
   
ItemHandlers::UseOnPokemon.add(:POTION,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,20,scene)
})

ItemHandlers::UseOnPokemon.add(:SUPERPOTION,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,50,scene)
})

ItemHandlers::UseOnPokemon.add(:HYPERPOTION,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,200,scene)
})

ItemHandlers::UseOnPokemon.add(:MAXPOTION,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,pokemon.totalhp-pokemon.hp,scene)
})

ItemHandlers::UseOnPokemon.add(:BERRYJUICE,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,20,scene)
})

ItemHandlers::UseOnPokemon.add(:RAGECANDYBAR,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,20,scene)
})

ItemHandlers::UseOnPokemon.add(:SWEETHEART,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,20,scene)
})

ItemHandlers::UseOnPokemon.add(:FRESHWATER,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,50,scene)
})

ItemHandlers::UseOnPokemon.add(:SODAPOP,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,60,scene)
})

ItemHandlers::UseOnPokemon.add(:LEMONADE,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,80,scene)
})

ItemHandlers::UseOnPokemon.add(:MOOMOOMILK,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,100,scene)
})

ItemHandlers::UseOnPokemon.add(:ORANBERRY,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,10,scene)
})

ItemHandlers::UseOnPokemon.add(:SITRUSBERRY,proc{|item,pokemon,scene|
   next pbHPItem(pokemon,(pokemon.totalhp/4).floor,scene)
})

ItemHandlers::UseOnPokemon.add(:AWAKENING,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::SLEEP
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} se ha despertado.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:AWAKENING,:CHESTOBERRY,:BLUEFLUTE,:POKEFLUTE)

ItemHandlers::UseOnPokemon.add(:ANTIDOTE,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::POISON
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} se curó del envenenamiento.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:ANTIDOTE,:PECHABERRY)

ItemHandlers::UseOnPokemon.add(:BURNHEAL,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::BURN
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     scene.pbRefresh
     scene.pbDisplay(_INTL("La quemadura de {1} ha sido curada.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:BURNHEAL,:RAWSTBERRY)

ItemHandlers::UseOnPokemon.add(:PARLYZHEAL,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::PARALYSIS
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha sido liberado de la parálisis.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:PARLYZHEAL,:PARALYZEHEAL,:CHERIBERRY)

ItemHandlers::UseOnPokemon.add(:ICEHEAL,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::FROZEN
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha sido descongelado.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:ICEHEAL,:ASPEARBERRY)

ItemHandlers::UseOnPokemon.add(:FULLHEAL,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha recuperado su salud.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:FULLHEAL,
   :LAVACOOKIE,:OLDGATEAU,:CASTELIACONE,:LUMIOSEGALETTE,:SHALOURSABLE,:LUMBERRY)

ItemHandlers::UseOnPokemon.add(:FULLRESTORE,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || (pokemon.hp==pokemon.totalhp && pokemon.status==0)
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     hpgain=pbItemRestoreHP(pokemon,pokemon.totalhp-pokemon.hp)
     pokemon.healStatus
     scene.pbRefresh
     if hpgain>0
       scene.pbDisplay(_INTL("{1} ha recuperado {2} PS.",pokemon.name,hpgain))
     else
       scene.pbDisplay(_INTL("{1} ha recuperado su salud.",pokemon.name))
     end
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:REVIVE,proc{|item,pokemon,scene|
   if pokemon.hp>0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.hp=(pokemon.totalhp/2).floor
     pokemon.healStatus
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha recuperado los PS.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:MAXREVIVE,proc{|item,pokemon,scene|
   if pokemon.hp>0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healHP
     pokemon.healStatus
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha recuperado los PS.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:ENERGYPOWDER,proc{|item,pokemon,scene|
   if pbHPItem(pokemon,50,scene)
     pokemon.changeHappiness("powder")
     next true
   end
   next false
})

ItemHandlers::UseOnPokemon.add(:ENERGYROOT,proc{|item,pokemon,scene|
   if pbHPItem(pokemon,200,scene)
     pokemon.changeHappiness("Energy Root")
     next true
   end
   next false
})

ItemHandlers::UseOnPokemon.add(:HEALPOWDER,proc{|item,pokemon,scene|
   if pokemon.hp<=0 || pokemon.status==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     pokemon.changeHappiness("powder")
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha recuperado su salud.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:REVIVALHERB,proc{|item,pokemon,scene|
   if pokemon.hp>0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healHP
     pokemon.healStatus
     pokemon.changeHappiness("Revival Herb")
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha recuperado los PS.",pokemon.name))
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:ETHER,proc{|item,pokemon,scene|
   move=scene.pbChooseMove(pokemon,_INTL("¿Qué movimiento recuperar?"))
   if move>=0
     if pbRestorePP(pokemon,move,10)==0
       scene.pbDisplay(_INTL("No tendrá ningún efecto."))
       next false
     else
      scene.pbDisplay(_INTL("Los PP han sido restaurados."))
      next true
    end
  end
  next false
})

ItemHandlers::UseOnPokemon.copy(:ETHER,:LEPPABERRY)

ItemHandlers::UseOnPokemon.add(:MAXETHER,proc{|item,pokemon,scene|
   move=scene.pbChooseMove(pokemon,_INTL("¿Qué movimiento recuperar?"))
   if move>=0
     if pbRestorePP(pokemon,move,pokemon.moves[move].totalpp-pokemon.moves[move].pp)==0
       scene.pbDisplay(_INTL("No tendrá ningún efecto."))
       next false
     else
       scene.pbDisplay(_INTL("Los PP han sido restaurados."))
       next true
     end
   end
   next false
})

ItemHandlers::UseOnPokemon.add(:ELIXIR,proc{|item,pokemon,scene|
   pprestored=0
   for i in 0...pokemon.moves.length
     pprestored+=pbRestorePP(pokemon,i,10)
   end
   if pprestored==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("Los PP han sido restaurados."))
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:MAXELIXIR,proc{|item,pokemon,scene|
   pprestored=0
   for i in 0...pokemon.moves.length
     pprestored+=pbRestorePP(pokemon,i,pokemon.moves[i].totalpp-pokemon.moves[i].pp)
   end
   if pprestored==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("Los PP han sido restaurados."))
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:PPUP,proc{|item,pokemon,scene|
   move=scene.pbChooseMove(pokemon,_INTL("¿A qué movimiento subir los PP?"))
   if move>=0
     if pokemon.moves[move].totalpp==0 || pokemon.moves[move].ppup>=3
       scene.pbDisplay(_INTL("No tendrá ningún efecto."))
       next false
     else
       pokemon.moves[move].ppup+=1
       movename=PBMoves.getName(pokemon.moves[move].id)
       scene.pbDisplay(_INTL("Se incrementaron los PP de {1}.",movename))
       next true
     end
   end
})

ItemHandlers::UseOnPokemon.add(:PPMAX,proc{|item,pokemon,scene|
   move=scene.pbChooseMove(pokemon,_INTL("¿A qué movimiento subir los PP?"))
   if move>=0
     if pokemon.moves[move].totalpp==0 || pokemon.moves[move].ppup>=3
       scene.pbDisplay(_INTL("No tendrá ningún efecto."))
       next false
     else
       pokemon.moves[move].ppup=3
       movename=PBMoves.getName(pokemon.moves[move].id)
       scene.pbDisplay(_INTL("Se incrementaron los PP de {1}.",movename))
       next true
     end
   end
})

ItemHandlers::UseOnPokemon.add(:HPUP,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,PBStats::HP)==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbRefresh
     scene.pbDisplay(_INTL("Se incrementaron los PS de {1}.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:PROTEIN,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,PBStats::ATTACK)==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("El Ataque de {1} se ha incrementado.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:IRON,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,PBStats::DEFENSE)==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("La Defensa de {1} se ha incrementado.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:CALCIUM,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,PBStats::SPATK)==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("El Ataque Especial de {1} se ha incrementado.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:ZINC,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,PBStats::SPDEF)==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("La Defensa Especial de {1} se ha incrementado.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:CARBOS,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,PBStats::SPEED)==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("La Velocidad de {1} se ha incrementado.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:HEALTHWING,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,PBStats::HP,1,false)==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbRefresh
     scene.pbDisplay(_INTL("Los PS de {1} se incrementaron.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:MUSCLEWING,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,PBStats::ATTACK,1,false)==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("El Ataque de {1} se ha incrementado.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:RESISTWING,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,PBStats::DEFENSE,1,false)==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("La Defensa de {1} se ha incrementado.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:GENIUSWING,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,PBStats::SPATK,1,false)==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("El Ataque Especial de {1} se ha incrementado.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:CLEVERWING,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,PBStats::SPDEF,1,false)==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("La Defensa Especial de {1} se ha incrementado.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:SWIFTWING,proc{|item,pokemon,scene|
   if pbRaiseEffortValues(pokemon,PBStats::SPEED,1,false)==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("La Velocidad de {1} se ha incrementado.",pokemon.name))
     pokemon.changeHappiness("vitamin")
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:RARECANDY,proc{|item,pokemon,scene|
   if pokemon.level>=PBExperience::MAXLEVEL || (pokemon.isShadow? rescue false)
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pbChangeLevel(pokemon,pokemon.level+1,scene)
     scene.pbHardRefresh
     next true
   end
})

ItemHandlers::UseOnPokemon.add(:POMEGBERRY,proc{|item,pokemon,scene|
   next pbRaiseHappinessAndLowerEV(pokemon,scene,PBStats::HP,[
      _INTL("¡{1} te adora! ¡Pero sus PS de base han disminuido!",pokemon.name),
      _INTL("{1} se ha vuelto más amable. ¡Sus PS de base ya no pueden bajar más!",pokemon.name),
      _INTL("{1} se ha vuelto más amable. ¡Pero tiene menos PS de base!",pokemon.name)
   ])
})

ItemHandlers::UseOnPokemon.add(:KELPSYBERRY,proc{|item,pokemon,scene|
   next pbRaiseHappinessAndLowerEV(pokemon,scene,PBStats::ATTACK,[
      _INTL("¡{1} te adora! ¡Pero su Ataque de base ha disminuido!",pokemon.name),
      _INTL("{1} se ha vuelto más amable. ¡Su Ataque de base ya no puede bajar más!",pokemon.name),
      _INTL("{1} se ha vuelto más amable. ¡Pero tiene menos Ataque de base!",pokemon.name)
   ])
})

ItemHandlers::UseOnPokemon.add(:QUALOTBERRY,proc{|item,pokemon,scene|
   next pbRaiseHappinessAndLowerEV(pokemon,scene,PBStats::DEFENSE,[
      _INTL("¡{1} te adora! ¡Pero su Defensa de base ha disminuido!",pokemon.name),
      _INTL("{1} se ha vuelto más amable. ¡Su Defensa de base ya no puede bajar más!",pokemon.name),
      _INTL("{1} se ha vuelto más amable. ¡Pero tiene menos Defensa de base!",pokemon.name)
   ])
})

ItemHandlers::UseOnPokemon.add(:HONDEWBERRY,proc{|item,pokemon,scene|
   next pbRaiseHappinessAndLowerEV(pokemon,scene,PBStats::SPATK,[
      _INTL("¡{1} te adora! ¡Pero su Ataque Especial de base ha disminuido!",pokemon.name),
      _INTL("{1} se ha vuelto más amable. ¡Su Ataque Especial de base ya no puede bajar más!",pokemon.name),
      _INTL("{1} se ha vuelto más amable. ¡Pero tiene menos Ataque Especial de base!",pokemon.name)
   ])
})

ItemHandlers::UseOnPokemon.add(:GREPABERRY,proc{|item,pokemon,scene|
   next pbRaiseHappinessAndLowerEV(pokemon,scene,PBStats::SPDEF,[
      _INTL("¡{1} te adora! ¡Pero su Defensa Especial de base ha disminuido!",pokemon.name),
      _INTL("{1} se ha vuelto más amable. ¡Su Defensa Especial de base ya no puede bajar más!",pokemon.name),
      _INTL("{1} se ha vuelto más amable. ¡Pero tiene menos Defensa Especial de base!",pokemon.name)
   ])
})

ItemHandlers::UseOnPokemon.add(:TAMATOBERRY,proc{|item,pokemon,scene|
   next pbRaiseHappinessAndLowerEV(pokemon,scene,PBStats::SPEED,[
      _INTL("¡{1} te adora! ¡Pero su Velocidad de base ha disminuido!",pokemon.name),
      _INTL("{1} se ha vuelto más amable. ¡Su Velocidad de base ya no puede bajar más!",pokemon.name),
      _INTL("{1} se ha vuelto más amable. ¡Pero tiene menos Velocidad de base!",pokemon.name)
   ])
})

ItemHandlers::UseOnPokemon.add(:GRACIDEA,proc{|item,pokemon,scene|
   if isConst?(pokemon.species,PBSpecies,:SHAYMIN) && pokemon.form==0 &&
      pokemon.status!=PBStatuses::FROZEN && !PBDayNight.isNight?
     if pokemon.hp>0
       pokemon.form=1
       scene.pbRefresh
       scene.pbDisplay(_INTL("¡{1} ha cambiado de forma!",pokemon.name))
       next true
     else
       scene.pbDisplay(_INTL("No se puede usar en un Pokémon debilitado."))
     end
   else
     scene.pbDisplay(_INTL("No tuvo efecto."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:REDNECTAR,proc{|item,pokemon,scene|
   if isConst?(pokemon.species,PBSpecies,:ORICORIO) && pokemon.form!=0
     if pokemon.hp>0
       pokemon.form=0
       scene.pbRefresh
       scene.pbDisplay(_INTL("¡{1} ha cambiado de forma!",pokemon.name))
       next true
     else
       scene.pbDisplay(_INTL("No se puede usar en un Pokémon debilitado."))
     end
   else
     scene.pbDisplay(_INTL("No tuvo efecto."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:YELLOWNECTAR,proc{|item,pokemon,scene|
   if isConst?(pokemon.species,PBSpecies,:ORICORIO) && pokemon.form!=1
     if pokemon.hp>0
       pokemon.form=1
       scene.pbRefresh
       scene.pbDisplay(_INTL("¡{1} ha cambiado de forma!",pokemon.name))
       next true
     else
       scene.pbDisplay(_INTL("No se puede usar en un Pokémon debilitado."))
     end
   else
     scene.pbDisplay(_INTL("No tuvo efecto."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:PINKNECTAR,proc{|item,pokemon,scene|
   if isConst?(pokemon.species,PBSpecies,:ORICORIO) && pokemon.form!=2
     if pokemon.hp>0
       pokemon.form=2
       scene.pbRefresh
       scene.pbDisplay(_INTL("¡{1} ha cambiado de forma!",pokemon.name))
       next true
     else
       scene.pbDisplay(_INTL("No se puede usar en un Pokémon debilitado."))
     end
   else
     scene.pbDisplay(_INTL("No tuvo efecto."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:PURPLENECTAR,proc{|item,pokemon,scene|
   if isConst?(pokemon.species,PBSpecies,:ORICORIO) && pokemon.form!=3
     if pokemon.hp>0
       pokemon.form=3
       scene.pbRefresh
       scene.pbDisplay(_INTL("¡{1} ha cambiado de forma!",pokemon.name))
       next true
     else
       scene.pbDisplay(_INTL("No se puede usar en un Pokémon debilitado."))
     end
   else
     scene.pbDisplay(_INTL("No tuvo efecto."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:REVEALGLASS,proc{|item,pokemon,scene|
   if (isConst?(pokemon.species,PBSpecies,:TORNADUS) ||
      isConst?(pokemon.species,PBSpecies,:THUNDURUS) ||
      isConst?(pokemon.species,PBSpecies,:LANDORUS) ||
      isConst?(pokemon.species,PBSpecies,:ENAMORUS))
     if pokemon.hp>0
       pokemon.form=(pokemon.form==0) ? 1 : 0
       scene.pbRefresh
       scene.pbDisplay(_INTL("¡{1} ha cambiado de forma!",pokemon.name))
       next true
     else
       scene.pbDisplay(_INTL("No se puede usar en un Pokémon debilitado."))
     end
   else
     scene.pbDisplay(_INTL("No tuvo efecto."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:DNASPLICERS,proc{|item,pokemon,scene|
   if isConst?(pokemon.species,PBSpecies,:KYUREM)
     if pokemon.hp>0
       if pokemon.fused!=nil
         if $Trainer.party.length>=6
           scene.pbDisplay(_INTL("No tienes espacio para separar a los Pokémon."))
           next false
         else
           $Trainer.party[$Trainer.party.length]=pokemon.fused
           pokemon.fused=nil
           pokemon.form=0
           scene.pbHardRefresh
           scene.pbDisplay(_INTL("¡{1} ha cambiado de forma!",pokemon.name))
           next true
         end
       else
         chosen=scene.pbChoosePokemon(_INTL("¿Fusionar con qué Pokémon?"))
         if chosen>=0
           poke2=$Trainer.party[chosen]
           if (isConst?(poke2.species,PBSpecies,:RESHIRAM) ||
              isConst?(poke2.species,PBSpecies,:ZEKROM)) && poke2.hp>0 && !poke2.isEgg?
             pokemon.form=1 if isConst?(poke2.species,PBSpecies,:RESHIRAM)
             pokemon.form=2 if isConst?(poke2.species,PBSpecies,:ZEKROM)
             pokemon.fused=poke2
             pbRemovePokemonAt(chosen)
             scene.pbHardRefresh
             scene.pbDisplay(_INTL("¡{1} ha cambiado de forma!",pokemon.name))
             next true
           elsif poke2.isEgg?
             scene.pbDisplay(_INTL("No se puede fusionar con un Huevo."))
           elsif poke2.hp<=0
             scene.pbDisplay(_INTL("No se puede fusionar con un Pokémon debilitado."))
           elsif pokemon==poke2
             scene.pbDisplay(_INTL("No se puede fusionar con sí mismo."))
           else
             scene.pbDisplay(_INTL("No se puede fusionar con ese Pokémon."))
           end
         else
           next false
         end
       end
     else
       scene.pbDisplay(_INTL("No se puede utilizar en un Pokémon debilitado."))
     end
   else
     scene.pbDisplay(_INTL("No tuvo efecto."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:REINSOFUNITY,proc{|item,pokemon,scene|
   if isConst?(pokemon.species,PBSpecies,:CALYREX)
     if pokemon.hp>0
       if pokemon.fused!=nil
         if $Trainer.party.length>=6
           scene.pbDisplay(_INTL("No tienes espacio para separar a los Pokémon."))
           next false
         else
           $Trainer.party[$Trainer.party.length]=pokemon.fused
           pokemon.fused=nil
           pokemon.form=0
           scene.pbHardRefresh
           scene.pbDisplay(_INTL("¡{1} ha cambiado de forma!",pokemon.name))
           next true
         end
       else
         chosen=scene.pbChoosePokemon(_INTL("¿Fusionar con qué Pokémon?"))
         if chosen>=0
           poke2=$Trainer.party[chosen]
           if (isConst?(poke2.species,PBSpecies,:GLASTRIER) ||
              isConst?(poke2.species,PBSpecies,:SPECTRIER)) && poke2.hp>0 && !poke2.isEgg?
             pokemon.form=1 if isConst?(poke2.species,PBSpecies,:GLASTRIER)
             pokemon.form=2 if isConst?(poke2.species,PBSpecies,:SPECTRIER)
             pokemon.fused=poke2
             pbRemovePokemonAt(chosen)
             scene.pbHardRefresh
             scene.pbDisplay(_INTL("¡{1} ha cambiado de forma!",pokemon.name))
             next true
           elsif poke2.isEgg?
             scene.pbDisplay(_INTL("No se puede fusionar con un Huevo."))
           elsif poke2.hp<=0
             scene.pbDisplay(_INTL("No se puede fusionar con un Pokémon debilitado."))
           elsif pokemon==poke2
             scene.pbDisplay(_INTL("No se puede fusionar con sí mismo."))
           else
             scene.pbDisplay(_INTL("No se puede fusionar con ese Pokémon."))
           end
         else
           next false
         end
       end
     else
       scene.pbDisplay(_INTL("No se puede utilizar en un Pokémon debilitado."))
     end
   else
     scene.pbDisplay(_INTL("No tuvo efecto."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:NSOLARIZER,proc{|item,pokemon,scene|
   if isConst?(pokemon.species,PBSpecies,:NECROZMA)
     if pokemon.hp>0
       if pokemon.fused!=nil
         if pokemon.form==1
           if pokemon.hasItem? && item>0
             $PokemonBag.pbStoreItem(pokemon.item) 
             pokemon.setItem(0)
           end
           if $Trainer.party.length>=6
             scene.pbDisplay(_INTL("No tienes espacio para separar a los Pokémon."))
             next false
           else
             $Trainer.party[$Trainer.party.length]=pokemon.fused
             pokemon.fused=nil
             pokemon.form=0
             scene.pbHardRefresh
             next true
           end
         else
           scene.pbDisplay(_INTL("No tuvo efecto."))
           next false
         end
       else
         chosen=scene.pbChoosePokemon(_INTL("¿Fusionar con qué Pokémon?"))
         if chosen>=0
           poke2=$Trainer.party[chosen]
             if poke2.hasItem? && item>0
               $PokemonBag.pbStoreItem(poke2.item) 
               poke2.setItem(0)
             end

           if isConst?(poke2.species,PBSpecies,:SOLGALEO) && poke2.hp>0 && !poke2.egg?
             pokemon.form=1
             pokemon.fused=poke2
             pbRemovePokemonAt(chosen)
             scene.pbHardRefresh
             next true
           elsif poke2.egg?
             scene.pbDisplay(_INTL("No se puede fusionar con un Huevo."))
           elsif poke2.hp<=0
             scene.pbDisplay(_INTL("No se puede fusionar con un Pokémon debilitado."))
           elsif pokemon==poke2
             scene.pbDisplay(_INTL("No se puede fusionar con sí mismo."))
           else
             scene.pbDisplay(_INTL("No se puede fusionar con ese Pokémon."))
           end
         else
           next false
         end
       end
     else
       scene.pbDisplay(_INTL("No se puede utilizar en un Pokémon debilitado."))
     end
   else
     scene.pbDisplay(_INTL("No tuvo efecto."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:NLUNARIZER,proc{|item,pokemon,scene|
   if isConst?(pokemon.species,PBSpecies,:NECROZMA)
     if pokemon.hp>0
       if pokemon.fused!=nil
         if pokemon.form==2
           if pokemon.hasItem? && item>0
             $PokemonBag.pbStoreItem(pokemon.item) 
             pokemon.setItem(0)
           end
           if $Trainer.party.length>=6
             scene.pbDisplay(_INTL("No tienes espacio para separar a los Pokémon."))
             next false
           else
             $Trainer.party[$Trainer.party.length]=pokemon.fused
             pokemon.fused=nil
             pokemon.form=0
             scene.pbHardRefresh
             next true
           end
         else
           scene.pbDisplay(_INTL("No tuvo efecto."))
           next false
         end
       else
         chosen=scene.pbChoosePokemon(_INTL("¿Fusionar con qué Pokémon?"))
         if chosen>=0
           poke2=$Trainer.party[chosen]
             if poke2.hasItem? && item>0
               $PokemonBag.pbStoreItem(poke2.item) 
               poke2.setItem(0)
             end
           if isConst?(poke2.species,PBSpecies,:LUNALA) && poke2.hp>0 && !poke2.egg?
             pokemon.form=2
             pokemon.fused=poke2
             pbRemovePokemonAt(chosen)
             scene.pbHardRefresh
             next true
           elsif poke2.egg?
             scene.pbDisplay(_INTL("No se puede fusionar con un Huevo."))
           elsif poke2.hp<=0
             scene.pbDisplay(_INTL("No se puede fusionar con un Pokémon debilitado."))
           elsif pokemon==poke2
             scene.pbDisplay(_INTL("No se puede fusionar con sí mismo."))
           else
             scene.pbDisplay(_INTL("No se puede fusionar con ese Pokémon."))
           end
         else
           next false
         end
       end
     else
       scene.pbDisplay(_INTL("No se puede utilizar en un Pokémon debilitado."))
     end
   else
     scene.pbDisplay(_INTL("No tuvo efecto."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:PRISONBOTTLE,proc{|item,pokemon,scene|
   if isConst?(pokemon.species,PBSpecies,:HOOPA)
     if pokemon.hp>0
       pokemon.form=(pokemon.form==0) ? 1 : 0
       scene.pbRefresh
       scene.pbDisplay(_INTL("¡{1} ha cambiando de forma!",pokemon.name))
       next true
     else
       scene.pbDisplay(_INTL("No se puede utilizar en un Pokémon debilitado."))
     end
   else
     scene.pbDisplay(_INTL("No tuvo efecto."))
     next false
   end
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYXS,proc{|item,pokemon,scene|
   if pokemon.level>=PBExperience::MAXLEVEL || (pokemon.isShadow? rescue false)
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     experience=100   if isConst?(item,PBItems,:EXPCANDYXS)
     experience=800   if isConst?(item,PBItems,:EXPCANDYS)
     experience=3000  if isConst?(item,PBItems,:EXPCANDYM)
     experience=10000 if isConst?(item,PBItems,:EXPCANDYL)
     experience=30000 if isConst?(item,PBItems,:EXPCANDYXL)
     newexp=PBExperience.pbAddExperience(pokemon.exp,experience,pokemon.growthrate)
     newlevel=PBExperience.pbGetLevelFromExperience(newexp,pokemon.growthrate)
     curlevel=pokemon.level
     scene.pbDisplay(_INTL("¡Tu Pokémon ganó Puntos de Experiencia!"))
     if newlevel==curlevel
       pokemon.exp=newexp
       pokemon.calcStats
       scene.pbRefresh
     else
       attackdiff=pokemon.attack
       defensediff=pokemon.defense
       speeddiff=pokemon.speed
       spatkdiff=pokemon.spatk
       spdefdiff=pokemon.spdef
       totalhpdiff=pokemon.totalhp
       oldlevel=pokemon.level
       pokemon.level=newlevel
#       pokemon.changeHappiness("levelup")
       pokemon.calcStats
       scene.pbRefresh
       Kernel.pbMessage(_INTL("\\se[Pkmn level up]¡{1} subió al nivel {2}!",pokemon.name,pokemon.level))
       attackdiff=pokemon.attack-attackdiff
       defensediff=pokemon.defense-defensediff
       speeddiff=pokemon.speed-speeddiff
       spatkdiff=pokemon.spatk-spatkdiff
       spdefdiff=pokemon.spdef-spdefdiff
       totalhpdiff=pokemon.totalhp-totalhpdiff
       pbTopRightWindow(_INTL("PS Máx.<r>+{1}\r\nAtaque<r>+{2}\r\nDefensa<r>+{3}\r\nAt. Esp.<r>+{4}\r\nDef. Esp.<r>+{5}\r\nVelocidad<r>+{6}",
          totalhpdiff,attackdiff,defensediff,spatkdiff,spdefdiff,speeddiff))
       pbTopRightWindow(_INTL("PS Máx.<r>{1}\r\nAtaque<r>{2}\r\nDefensa<r>{3}\r\nAt. Esp.<r>{4}\r\nDef. Esp.<r>{5}\r\nVelocidad<r>{6}",
          pokemon.totalhp,pokemon.attack,pokemon.defense,pokemon.spatk,pokemon.spdef,pokemon.speed))
       movelist=pokemon.getMoveList
       for i in movelist
         if i[0]>oldlevel && i[0]<=pokemon.level
           pbLearnMove(pokemon,i[1],true)
         end
       end
       newspecies=pbCheckEvolution(pokemon)
       if newspecies>0
         pbFadeOutInWithMusic(99999){
            evo=PokemonEvolutionScene.new
            evo.pbStartScreen(pokemon,newspecies)
            evo.pbEvolution
            evo.pbEndScreen
         }
       end
       pokemon.exp=newexp
       scene.pbRefresh
     end
     next true
   end
})

ItemHandlers::UseOnPokemon.copy(:EXPCANDYXS,:EXPCANDYS,:EXPCANDYM,:EXPCANDYL,:EXPCANDYXL)

ItemHandlers::UseOnPokemon.add(:ABILITYCAPSULE,proc{|item,pokemon,scene|
   abils=pokemon.getAbilityList
   abil1=0; abil2=0
   for i in abils
     abil1=i[0] if i[1]==0
     abil2=i[0] if i[1]==1
   end
   if abil1<=0 || abil2<=0 || pokemon.hasHiddenAbility?
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   end
   newabil=(pokemon.abilityIndex+1)%2
   newabilname=PBAbilities.getName((newabil==0) ? abil1 : abil2)
   if scene.pbConfirm(_INTL("¿Quieres cambiar la habilidad de {1} a {2}?",
      pokemon.name,newabilname))
     pokemon.setAbility(newabil)
     scene.pbRefresh
     scene.pbDisplay(_INTL("¡La habilidad de {1} se ha cambiado a {2}!",pokemon.name,
        PBAbilities.getName(pokemon.ability)))
     next true
   end
   next false
})

ItemHandlers::UseOnPokemon.add(:ABILITYPATCH,proc{|item,pokemon,scene|
   if pokemon.hasHiddenAbility? || pokemon.getAbilityList.length < 2
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   end
   for i in pokemon.getAbilityList
     abil=i[0] if i[1]==2
   end
   if scene.pbConfirm(_INTL("¿Quieres cambiar la habilidad de {1} a {2}?",
      pokemon.name,PBAbilities.getName(abil)))
     pokemon.setAbility(2)
     scene.pbRefresh
     scene.pbDisplay(_INTL("¡La habilidad de {1} se ha cambiado a {2}!",pokemon.name,
        PBAbilities.getName(pokemon.ability)))
     next true
   end
   next false
})

#===============================================================================
# BattleUseOnPokemon handlers
#===============================================================================

ItemHandlers::BattleUseOnPokemon.add(:POTION,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,20,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:SUPERPOTION,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,50,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:HYPERPOTION,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,200,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:MAXPOTION,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,pokemon.totalhp-pokemon.hp,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:BERRYJUICE,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,20,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:RAGECANDYBAR,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,20,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:SWEETHEART,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,20,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:FRESHWATER,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,50,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:SODAPOP,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,60,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:LEMONADE,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,80,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:MOOMOOMILK,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,100,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:ORANBERRY,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,10,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:SITRUSBERRY,proc{|item,pokemon,battler,scene|
   next pbBattleHPItem(pokemon,battler,(pokemon.totalhp/4).floor,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:AWAKENING,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::SLEEP
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     battler.status=0 if battler
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} se ha despertado.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:AWAKENING,:CHESTOBERRY,:BLUEFLUTE,:POKEFLUTE)

ItemHandlers::BattleUseOnPokemon.add(:ANTIDOTE,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::POISON
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     battler.status=0 if battler
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} se curó del envenenamiento.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:ANTIDOTE,:PECHABERRY)

ItemHandlers::BattleUseOnPokemon.add(:BURNHEAL,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::BURN
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     battler.status=0 if battler
     scene.pbRefresh
     scene.pbDisplay(_INTL("La quemadura de {1} ha sido curada.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:BURNHEAL,:RAWSTBERRY)

ItemHandlers::BattleUseOnPokemon.add(:PARLYZHEAL,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::PARALYSIS
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     battler.status=0 if battler
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha sido liberado de la parálisis.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:PARLYZHEAL,:PARALYZEHEAL,:CHERIBERRY)

ItemHandlers::BattleUseOnPokemon.add(:ICEHEAL,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || pokemon.status!=PBStatuses::FROZEN
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     battler.status=0 if battler
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha sido descongelado.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:ICEHEAL,:ASPEARBERRY)

ItemHandlers::BattleUseOnPokemon.add(:FULLHEAL,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || (pokemon.status==0 && (!battler || battler.effects[PBEffects::Confusion]==0))
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     battler.status=0 if battler
     battler.effects[PBEffects::Confusion]=0 if battler
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha recuperado su salud.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:FULLHEAL,
   :LAVACOOKIE,:OLDGATEAU,:CASTELIACONE,:LUMIOSEGALETTE,:SHALOURSABLE,:LUMBERRY)

ItemHandlers::BattleUseOnPokemon.add(:FULLRESTORE,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || (pokemon.hp==pokemon.totalhp && pokemon.status==0 &&
      (!battler || battler.effects[PBEffects::Confusion]==0))
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     hpgain=pbItemRestoreHP(pokemon,pokemon.totalhp-pokemon.hp)
     battler.hp=pokemon.hp if battler
     pokemon.healStatus
     battler.status=0 if battler
     battler.effects[PBEffects::Confusion]=0 if battler
     scene.pbRefresh
     if hpgain>0
       scene.pbDisplay(_INTL("{1} ha recuperado {2} PS.",pokemon.name,hpgain))
     else
       scene.pbDisplay(_INTL("{1} ha recuperado su salud.",pokemon.name))
     end
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:REVIVE,proc{|item,pokemon,battler,scene|
   if pokemon.hp>0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.hp=(pokemon.totalhp/2).floor
     pokemon.healStatus
     for i in 0...$Trainer.party.length
       if $Trainer.party[i]==pokemon
         battler.pbInitialize(pokemon,i,false) if battler
         break
       end
     end
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha recuperado los PS.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:MAXREVIVE,proc{|item,pokemon,battler,scene|
   if pokemon.hp>0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healHP
     pokemon.healStatus
     for i in 0...$Trainer.party.length
       if $Trainer.party[i]==pokemon
         battler.pbInitialize(pokemon,i,false) if battler
         break
       end
     end
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha recuperado los PS.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:ENERGYPOWDER,proc{|item,pokemon,battler,scene|
   if pbBattleHPItem(pokemon,battler,50,scene)
     pokemon.changeHappiness("powder")
     next true
   end
   next false
})

ItemHandlers::BattleUseOnPokemon.add(:ENERGYROOT,proc{|item,pokemon,battler,scene|
   if pbBattleHPItem(pokemon,battler,200,scene)
     pokemon.changeHappiness("Energy Root")
     next true
   end
   next false
})

ItemHandlers::BattleUseOnPokemon.add(:HEALPOWDER,proc{|item,pokemon,battler,scene|
   if pokemon.hp<=0 || (pokemon.status==0 && (!battler || battler.effects[PBEffects::Confusion]==0))
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     battler.status=0 if battler
     battler.effects[PBEffects::Confusion]=0 if battler
     pokemon.changeHappiness("powder")
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha recuperado su salud.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:REVIVALHERB,proc{|item,pokemon,battler,scene|
   if pokemon.hp>0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     pokemon.healStatus
     pokemon.hp=pokemon.totalhp
     for i in 0...$Trainer.party.length
       if $Trainer.party[i]==pokemon
         battler.pbInitialize(pokemon,i,false) if battler
         break
       end
     end
     pokemon.changeHappiness("Revival Herb")
     scene.pbRefresh
     scene.pbDisplay(_INTL("{1} ha recuperado los PS.",pokemon.name))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:ETHER,proc{|item,pokemon,battler,scene|
   move=scene.pbChooseMove(pokemon,_INTL("¿Qué movimiento recuperar?"))
   if move>=0
     if pbBattleRestorePP(pokemon,battler,move,10)==0
       scene.pbDisplay(_INTL("No tendrá ningún efecto."))
       next false
     else
       scene.pbDisplay(_INTL("Los PP han sido restaurados."))
       next true
     end
   end
   next false
})

ItemHandlers::BattleUseOnPokemon.copy(:ETHER,:LEPPABERRY)

ItemHandlers::BattleUseOnPokemon.add(:MAXETHER,proc{|item,pokemon,battler,scene|
   move=scene.pbChooseMove(pokemon,_INTL("¿Qué movimiento recuperar?"))
   if move>=0
     if pbBattleRestorePP(pokemon,battler,move,pokemon.moves[move].totalpp-pokemon.moves[move].pp)==0
       scene.pbDisplay(_INTL("No tendrá ningún efecto."))
       next false
     else
       scene.pbDisplay(_INTL("Los PP han sido restaurados."))
       next true
     end
   end
   next false
})

ItemHandlers::BattleUseOnPokemon.add(:ELIXIR,proc{|item,pokemon,battler,scene|
   pprestored=0
   for i in 0...pokemon.moves.length
     pprestored+=pbBattleRestorePP(pokemon,battler,i,10)
   end
   if pprestored==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("Los PP han sido restaurados."))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:MAXELIXIR,proc{|item,pokemon,battler,scene|
   pprestored=0
   for i in 0...pokemon.moves.length
     pprestored+=pbBattleRestorePP(pokemon,battler,i,pokemon.moves[i].totalpp-pokemon.moves[i].pp)
   end
   if pprestored==0
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   else
     scene.pbDisplay(_INTL("Los PP han sido restaurados."))
     next true
   end
})

ItemHandlers::BattleUseOnPokemon.add(:REDFLUTE,proc{|item,pokemon,battler,scene|
   if battler && battler.effects[PBEffects::Attract]>=0
     battler.effects[PBEffects::Attract]=-1
     scene.pbDisplay(_INTL("{1} got over its infatuation.",pokemon.name))
     next true # :consumed:
   else
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   end
})

ItemHandlers::BattleUseOnPokemon.add(:YELLOWFLUTE,proc{|item,pokemon,battler,scene|
   if battler && battler.effects[PBEffects::Confusion]>0
     battler.effects[PBEffects::Confusion]=0
     scene.pbDisplay(_INTL("{1} ya no está confuso.",pokemon.name))
     next true # :consumed:
   else
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   end
})

ItemHandlers::BattleUseOnPokemon.copy(:YELLOWFLUTE,:PERSIMBERRY)

#===============================================================================
# BattleUseOnBattler handlers
#===============================================================================

ItemHandlers::BattleUseOnBattler.add(:XATTACK,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::ATTACK,battler,false)
     battler.pbIncreaseStat(PBStats::ATTACK,1,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XATTACK2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::ATTACK,battler,false)
     battler.pbIncreaseStat(PBStats::ATTACK,2,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XATTACK3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::ATTACK,battler,false)
     battler.pbIncreaseStat(PBStats::ATTACK,3,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XATTACK6,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbIncreaseStatWithCause(PBStats::ATTACK,6,battler,PBItems.getName(item))
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XDEFEND,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::DEFENSE,battler,false)
     battler.pbIncreaseStat(PBStats::DEFENSE,1,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.copy(:XDEFEND,:XDEFENSE)

ItemHandlers::BattleUseOnBattler.add(:XDEFEND2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::DEFENSE,battler,false)
     battler.pbIncreaseStat(PBStats::DEFENSE,2,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.copy(:XDEFEND2,:XDEFENSE2)

ItemHandlers::BattleUseOnBattler.add(:XDEFEND3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::DEFENSE,battler,false)
     battler.pbIncreaseStat(PBStats::DEFENSE,3,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.copy(:XDEFEND3,:XDEFENSE3)

ItemHandlers::BattleUseOnBattler.add(:XDEFEND6,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbIncreaseStatWithCause(PBStats::DEFENSE,6,battler,PBItems.getName(item))
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.copy(:XDEFEND6,:XDEFENSE6)

ItemHandlers::BattleUseOnBattler.add(:XSPECIAL,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::SPATK,battler,false)
     battler.pbIncreaseStat(PBStats::SPATK,1,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.copy(:XSPECIAL,:XSPATK)

ItemHandlers::BattleUseOnBattler.add(:XSPECIAL2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::SPATK,battler,false)
     battler.pbIncreaseStat(PBStats::SPATK,2,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.copy(:XSPECIAL2,:XSPATK2)

ItemHandlers::BattleUseOnBattler.add(:XSPECIAL3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::SPATK,battler,false)
     battler.pbIncreaseStat(PBStats::SPATK,3,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.copy(:XSPECIAL3,:XSPATK3)

ItemHandlers::BattleUseOnBattler.add(:XSPECIAL6,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbIncreaseStatWithCause(PBStats::SPATK,6,battler,PBItems.getName(item))
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.copy(:XSPECIAL6,:XSPATK6)

ItemHandlers::BattleUseOnBattler.add(:XSPDEF,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::SPDEF,battler,false)
     battler.pbIncreaseStat(PBStats::SPDEF,1,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPDEF2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::SPDEF,battler,false)
     battler.pbIncreaseStat(PBStats::SPDEF,2,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPDEF3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::SPDEF,battler,false)
     battler.pbIncreaseStat(PBStats::SPDEF,3,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPDEF6,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbIncreaseStatWithCause(PBStats::SPDEF,6,battler,PBItems.getName(item))
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPEED,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::SPEED,battler,false)
     battler.pbIncreaseStat(PBStats::SPEED,1,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPEED2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::SPEED,battler,false)
     battler.pbIncreaseStat(PBStats::SPEED,2,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPEED3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::SPEED,battler,false)
     battler.pbIncreaseStat(PBStats::SPEED,3,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XSPEED6,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbIncreaseStatWithCause(PBStats::SPEED,6,battler,PBItems.getName(item))
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XACCURACY,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::ACCURACY,battler,false)
     battler.pbIncreaseStat(PBStats::ACCURACY,1,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XACCURACY2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::ACCURACY,battler,false)
     battler.pbIncreaseStat(PBStats::ACCURACY,2,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XACCURACY3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbCanIncreaseStatStage?(PBStats::ACCURACY,battler,false)
     battler.pbIncreaseStat(PBStats::ACCURACY,3,battler,true)
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:XACCURACY6,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbIncreaseStatWithCause(PBStats::ACCURACY,6,battler,PBItems.getName(item))
     return true
   else
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false  
   end
})

ItemHandlers::BattleUseOnBattler.add(:DIREHIT,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.effects[PBEffects::FocusEnergy]>=1
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false
   else
     battler.effects[PBEffects::FocusEnergy]=1
     scene.pbDisplay(_INTL("¡{1} se está preparando para luchar!",battler.pbThis))
     return true
   end
})

ItemHandlers::BattleUseOnBattler.add(:DIREHIT2,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.effects[PBEffects::FocusEnergy]>=2
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false
   else
     battler.effects[PBEffects::FocusEnergy]=2
     scene.pbDisplay(_INTL("¡{1} se está preparando para luchar!",battler.pbThis))
     return true
   end
})

ItemHandlers::BattleUseOnBattler.add(:DIREHIT3,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.effects[PBEffects::FocusEnergy]>=3
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false
   else
     battler.effects[PBEffects::FocusEnergy]=3
     scene.pbDisplay(_INTL("¡{1} se está preparando para luchar!",battler.pbThis))
     return true
   end
})

ItemHandlers::BattleUseOnBattler.add(:GUARDSPEC,proc{|item,battler,scene|
   playername=battler.battle.pbPlayer.name
   scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
   if battler.pbOwnSide.effects[PBEffects::Mist]>0
     scene.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
     return false
   else
     battler.pbOwnSide.effects[PBEffects::Mist]=5         # Neblina
     if !scene.pbIsOpposing?(attacker.index)
       scene.pbDisplay(_INTL("¡Tu equipo ha sido cubierto por una Neblina!"))
     else
       scene.pbDisplay(_INTL("¡El equipo enemigo ha sido cubierto por una Neblina!"))
     end
     return true
   end
})

ItemHandlers::BattleUseOnBattler.add(:POKEDOLL,proc{|item,battler,scene|
   battle=battler.battle
   if battle.opponent
     scene.pbDisplay(_INTL("Eso no se puede usar aquí."))
     return false
   else
     playername=battle.pbPlayer.name
     scene.pbDisplay(_INTL("{1} ha usado {2}.",playername,PBItems.getName(item)))
     return true
   end
})

ItemHandlers::BattleUseOnBattler.copy(:POKEDOLL,:FLUFFYTAIL,:POKETOY)

ItemHandlers::BattleUseOnBattler.addIf(proc{|item|
                pbIsPokeBall?(item)},proc{|item,battler,scene|  # Any Poké Ball
   battle=battler.battle
   if !battler.pbOpposing1.isFainted? && !battler.pbOpposing2.isFainted?
     if !pbIsSnagBall?(item)
       scene.pbDisplay(_INTL("¡Esto no es bueno! ¡No se puede apuntar cuando hay más de un Pokémon!"))
       return false
     end
   end
   if battle.pbPlayer.party.length>=6 && $PokemonStorage.full?
     scene.pbDisplay(_INTL("¡No hay espacio en la PC!"))
     return false
   end
   return true
})

#===============================================================================
# UseInBattle handlers
#===============================================================================

ItemHandlers::UseInBattle.add(:POKEDOLL,proc{|item,battler,battle|
   battle.decision=3
   battle.pbDisplayPaused(_INTL("¡Has huido sin problemas!"))
})

ItemHandlers::UseInBattle.copy(:POKEDOLL,:FLUFFYTAIL,:POKETOY)

ItemHandlers::UseInBattle.addIf(proc{|item| pbIsPokeBall?(item)},
   proc{|item,battler,battle|  # Any Poké Ball 
      battle.pbThrowPokeBall(battler.index,item)
})