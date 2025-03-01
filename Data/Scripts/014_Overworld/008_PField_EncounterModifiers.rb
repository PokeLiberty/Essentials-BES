################################################################################
# This section was created solely for you to put various bits of code that
# modify various wild Pokémon and trainers immediately prior to battling them.
# Be sure that any code you use here ONLY applies to the Pokémon/trainers you
# want it to apply to!
################################################################################

# Make all wild Pokémon shiny while a certain Switch is ON (see Settings).
Events.onWildPokemonCreate+=proc {|sender,e|
   pokemon=e[0]
   if $game_switches[SHINY_WILD_POKEMON_SWITCH] || $PokemonTemp.battle_rules["wildShiny"]
     pokemon.makeShiny
   end
   pokemon.makeShadow if $PokemonTemp.battle_rules["wildShadow"]
   pokemon.form = $PokemonTemp.battle_rules["wildForm"] if $PokemonTemp.battle_rules["wildForm"]
   pokemon.pbLearnMove($PokemonTemp.battle_rules["wildMove"]) if $PokemonTemp.battle_rules["wildMove"]
   if $PokemonTemp.battle_rules["wildTera"]
    pokemon.tera_ace=true
    pokemon.teratype=getConst(PBTypes,$PokemonTemp.battle_rules["wildTera"])
   end
}

# Used in the random dungeon map.  Makes the levels of all wild Pokémon in that
# map depend on the levels of Pokémon in the player's party.
# This is a simple method, and can/should be modified to account for evolutions
# and other such details.  Of course, you don't HAVE to use this code.
Events.onWildPokemonCreate+=proc {|sender,e|
   pokemon=e[0]
   if $game_map.map_id==51
     newlevel=pbBalancedLevel($Trainer.party) - 4 + rand(5)   # For variety
     newlevel=1 if newlevel<1
     newlevel=PBExperience::MAXLEVEL if newlevel>PBExperience::MAXLEVEL
     pokemon.level=newlevel
     pokemon.calcStats
     pokemon.resetMoves
   end
}

# This is the basis of a trainer modifier.  It works both for trainers loaded
# when you battle them, and for partner trainers when they are registered.
# Note that you can only modify a partner trainer's Pokémon, and not the trainer
# themselves nor their items this way, as those are generated from scratch
# before each battle.
#Events.onTrainerPartyLoad+=proc {|sender,e|
#   if e[0] # Trainer data should exist to be loaded, but may not exist somehow
#     trainer=e[0][0] # A PokeBattle_Trainer object of the loaded trainer
#     items=e[0][1]   # An array of the trainer's items they can use
#     party=e[0][2]   # An array of the trainer's Pokémon
#     YOUR CODE HERE
#   end
#}


# EJEMPLO PARA MEWTWO CON MEGAPIEDRA
Events.onWildPokemonCreate+=proc {
|sender,e|
   pokemon=e[0]
   # Comprueba un interruptor, en este caso el que hay para evitar capturas
   # Y luego comprueba la especie.
   # Esta es la forma más eficiente de crear bosses, tan solo edita el codigo y añade nuevas cosas o condiciones.
   if $game_switches[NO_CAPTURE_SWITCH] && pokemon.species == PBSpecies::MEWTWO
     pokemon.setItem(:MEWTWONITEX)
     pokemon.makeShiny
   end
}
