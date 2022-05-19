################################################################################
# Evolution Moves                                                              #
#                                                                              #
# By Crystal Noel with edits by Zerokid                                        #
#                                                                              #
# Current Version: 1.00                                                        #
################################################################################
# The 7th generation of Pokémon introduced the feature of evolution moves, a  #
# feature where a Pokémon would learn a move upon evolving reguardless of what #
# level it evolved at. The game defines these as being learned at level 0,    #
# which is not possible with the compiler, so they are defined here and upon  #
# evolving a species will check the list and learn the move. Do note that      #
# moves are not automatically added to the learn list, thus can't be relearned #
# through the move relearner, unless the move is also part of the Pokémon's    #
# learnset.                                                                    #
################################################################################
# To use                                                                      #
# 1.) Place in a new script section below "PSystem_Utilities" but above "Main" #                                                    #
# 2.) Define which species get evolution moves                                #
################################################################################

################################################################################
# Define Evolution Moves Here                                                  #
################################################################################
EVOLUTIONMOVES = {
  # Gen I
  [:VENUSAUR, 0]   => [:PETALDANCE],
  [:CHARIZARD, 0]  => [:WINGATTACK],
  [:METAPOD, 0]    => [:HARDEN],
  [:BUTTERFREE, 0] => [:GUST],
  [:KAKUNA, 0]     => [:HARDEN],
  [:BEEDRILL, 0]   => [:TWINEEDLE],
  [:RATICATE, 0]   => [:SCARYFACE],
  [:RATICATE, 1]   => [:SCARYFACE],
  [:ARBOK, 0]      => [:CRUNCH],
  [:RAICHU, 1]     => [:PSYCHIC],
  [:SANDSLASH, 0]  => [:CRUSHCLAW],
  [:SANDSLASH, 1]  => [:ICICLESPEAR],
  [:NINETALES, 1]  => [:DAZZLINGGLEAM],
  [:VENOMOTH, 0]   => [:GUST],
  [:DUGTRIO, 0]    => [:SANDTOMB],
  [:DUGTRIO, 1]    => [:SANDTOMB],
  [:PERSIAN, 0]    => [:SWIFT],
  [:PERSIAN, 1]    => [:SWIFT],
  [:PRIMEAPE, 0]   => [:RAGE],
  [:POLIWRATH, 0]  => [:SUBMISSION],
  [:KADABRA, 0]    => [:KINESIS],
  [:ALAKAZAM, 0]   => [:KINESIS],
  [:MACHAMP, 0]    => [:STRENGTH],
  [:VICTREEBEL, 0] => [:LEAFTORNADO],
  [:RAPIDASH, 0]   => [:FURYATTACK],
  [:RAPIDASH, 1]   => [:PSYCHOCUT],
  [:SLOWBRO, 0]    => [:WITHDRAW],
  [:SLOWBRO, 1]    => [:SHELLSIDEARM],
  [:MAGNETON, 0]   => [:TRIATTACK],
  [:DODRIO, 0]     => [:TRIATTACK],
  [:DEWGONG, 0]    => [:SHEERCOLD],
  [:MUK, 0]        => [:VENOMDRENCH],
  [:MUK, 1]        => [:VENOMDRENCH],
  [:HAUNTER, 0]    => [:SHADOWPUNCH],
  [:GENGAR, 0]     => [:SHADOWPUNCH],
  [:EXEGGUTOR, 0]  => [:STOMP],
  [:EXEGGUTOR, 1]  => [:DRAGONHAMMER],
  [:MAROWAK,1]     => [:SHADOWBONE],
  [:HITMONLEE, 0]  => [:DOUBLEKICK],
  [:HITMONCHAN, 0] => [:COMETPUNCH],
  [:WEEZING, 0]    => [:DOUBLEHIT],
  [:WEEZING, 1]    => [:DOUBLEHIT],
  [:RHYDON, 0]     => [:HAMMERARM],
  [:GYARADOS, 0]   => [:BITE],
  [:VAPOREON, 0]   => [:WATERGUN],
  [:JOLTEON, 0]    => [:THUNDERSHOCK],
  [:FLAREON, 0]    => [:EMBER],
  [:OMASTAR, 0]    => [:SPIKECANNON],
  [:KABUTOPS, 0]   => [:SLASH],
  [:DRAGONITE, 0]  => [:WINGATTACK],

  # Gen II
  [:MEGANIUM, 0]   => [:PETALDANCE],
  [:FURRET, 0]     => [:AGILITY],
  [:ARIADOS, 0]    => [:SWORDSDANCE],
  [:CROBAT, 0]     => [:CROSSPOISON],
  [:LANTURN, 0]    => [:STOCKPILE, :SWALLOW, :SPITUP],
  [:XATU, 0]       => [:AIRSLASH],
  [:AMPHAROS, 0]   => [:THUNDERPUNCH],
  [:BELLOSSOM, 0]  => [:MAGICALLEAF],
  [:SUDOWOODO, 0]  => [:SLAM],
  [:ESPEON, 0]     => [:CONFUSION],
  [:UMBREON, 0]    => [:PURSUIT],
  [:SLOWKING,1]    => [:EERIESPELL],
  [:FORRETRESS, 0] => [:MIRRORSHOT, :AUTOTOMIZE],
  [:MAGCARGO, 0]   => [:SHELLSMASH],
  [:PILOSWINE, 0]  => [:FURYATTACK],
  [:OCTILLERY, 0]  => [:OCTOZOOKA],
  [:DONPHAN, 0]    => [:FURYATTACK],
  [:HITMONTOP, 0]  => [:ROLLINGKICK],

  # Gen III
  [:GROVYLE, 0]   => [:FURYCUTTER],
  [:SCEPTILE, 0]  => [:DUALCHOP],
  [:COMBUSKEN, 0] => [:DOUBLEKICK],
  [:BLAZIKEN, 0]  => [:BLAZEKICK],
  [:MARSHTOMP, 0] => [:MUDSHOT],
  [:MIGHTYENA, 0] => [:SNARL],
  [:LINOONE, 1]   => [:NIGHTSLASH],
  [:SILCOON, 0]   => [:HARDEN],
  [:BEAUTIFLY, 0] => [:GUST],
  [:CASCOON, 0]   => [:HARDEN],
  [:DUSTOX, 0]    => [:GUST],
  [:NUZLEAF, 0]   => [:RAZORLEAF],
  [:PELIPPER, 0]  => [:PROTECT],
  [:BRELOOM, 0]   => [:MACHPUNCH],
  [:SLAKING, 0]   => [:SWAGGER],
  [:NINJASK, 0]   => [:DOUBLETEAM, :SCREECH, :FURYCUTTER],
  [:LOUDRED, 0]   => [:BITE],
  [:EXPLOUD, 0]   => [:CRUNCH],
  [:SWALOT, 0]    => [:BODYSLAM],
  [:SHARPEDO, 0]  => [:SLASH],
  [:CAMERUPT, 0]  => [:ROCKSLIDE],
  [:GRUMPIG, 0]   => [:TEETERDANCE],
  [:VIBRAVA, 0]   => [:DRAGONBREATH],
  [:FLYGON, 0]    => [:DRAGONCLAW],
  [:CACTURNE, 0]  => [:SPIKYSHIELD],
  [:ALTARIA, 0]   => [:DRAGONBREATH],
  [:WHISCASH, 0]  => [:THRASH],
  [:CRAWDAUNT, 0] => [:SWIFT],
  [:CLAYDOL, 0]   => [:HYPERBEAM],
  [:MILOTIC, 0]   => [:WATERPULSE],
  [:DUSCLOPS, 0]  => [:SHADOWPUNCH],
  [:GLALIE, 0]    => [:FREEZEDRY],
  [:SEALEO, 0]    => [:SWAGGER],
  [:WALREIN, 0]   => [:ICEFANG],
  [:SHELGON, 0]   => [:PROTECT],
  [:SALAMENCE, 0] => [:FLY],
  [:METANG, 0]    => [:CONFUSION, :METALCLAW],
  [:METAGROSS, 0] => [:HAMMERARM],

  # Gen IV
  [:TORTERRA, 0]   => [:EARTHQUAKE],
  [:MONFERNO, 0]   => [:MACHPUNCH],
  [:INFERNAPE, 0]  => [:CLOSECOMBAT],
  [:PRINPLUP, 0]   => [:METALCLAW],
  [:EMPOLEON, 0]   => [:AQUAJET],
  [:STARAPTOR, 0]  => [:CLOSECOMBAT],
  [:BIBAREL, 0]    => [:WATERGUN],
  [:KRICKETUNE, 0] => [:FURYCUTTER],
  [:RAMPARDOS, 0]  => [:ENDEAVOR],
  [:BASTIODON, 0]  => [:BLOCK],
  [:WORMADAM, 0]   => [:QUIVERDANCE],
  [:WORMADAM, 1]   => [:QUIVERDANCE],
  [:WORMADAM, 2]   => [:QUIVERDANCE],
  [:MOTHIM, 0]     => [:QUIVERDANCE],
  [:VESPIQUEN, 0]  => [:SLASH],
  [:CHERRIM, 0]    => [:PETALDANCE],
  [:LOPUNNY, 0]    => [:RETURN],
  [:PURUGLY, 0]    => [:SWAGGER],
  [:SKUNTANK, 0]   => [:FLAMETHROWER],
  [:BRONZONG, 0]   => [:BLOCK],
  [:GABITE, 0]     => [:DUALCHOP],
  [:GARCHOMP, 0]   => [:CRUNCH],
  [:LUCARIO, 0]    => [:AURASPHERE],
  [:MAGNEZONE, 0]  => [:TRIATTACK],
  [:LEAFEON, 0]    => [:RAZORLEAF],
  [:GLACEON, 0]    => [:ICYWIND],
  [:GALLADE, 0]    => [:SLASH],
  [:PROBOPASS, 0]  => [:TRIATTACK],
  [:FROSLASS, 0]   => [:OMINOUSWIND],

  # Gen V
  [:PIGNITE, 0]    => [:ARMTHRUST],
  [:SAMUROTT, 0]   => [:SLASH],
  [:WATCHOG, 0]    => [:CONFUSERAY],
  [:BOLDORE, 0]    => [:POWERGEM],
  [:EXCADRILL, 0]  => [:HORNDRILL],
  [:SEISMITOAD, 0] => [:ACID],
  [:SWADLOON, 0]   => [:PROTECT],
  [:LEAVANNY, 0]   => [:SLASH],
  [:WHIRLIPEDE, 0] => [:IRONDEFENSE],
  [:SCOLIPEDE, 0]  => [:BATONPASS],
  [:DARMANITAN, 0] => [:HAMMERARM],
  [:DARMANITAN, 1] => [:ICICLECRASH],
  [:COHAGRIGUS, 0] => [:SCARYFACE],
  [:ZOROARK, 0]    => [:NIGHTSLASH],
  [:REUNICLUS, 0]  => [:DIZZYPUNCH],
  [:SAWSBUCK, 0]   => [:HORNLEECH],
  [:SAWSBUCK, 1]   => [:HORNLEECH],
  [:SAWSBUCK, 2]   => [:HORNLEECH],
  [:SAWSBUCK, 3]   => [:HORNLEECH],
  [:GALVANTULA, 0] => [:STICKYWEB],
  [:FERROTHORN, 0] => [:POWERWHIP],
  [:KLINKLANG, 0]  => [:MAGNETICFLUX],
  [:EELEKTRIK, 0]  => [:CRUNCH],
  [:BEARTIC, 0]    => [:ICICLECRASH],
  [:GOLURK, 0]     => [:HEAVYSLAM],
  [:BRAVIARY, 0]   => [:SUPERPOWER],
  [:MANDIBUZZ, 0]  => [:BONERUSH],
  [:VOLCARONA, 0]  => [:QUIVERDANCE],

  # Gen VI
  [:QUILLADIN, 0]   => [:NEEDLEARM],
  [:CHESNAUGHT, 0]  => [:SPIKYSHIELD],
  [:DELPHOX, 0]     => [:MYSTICALFIRE],
  [:GRENINJA, 0]    => [:WATERSHURIKEN],
  [:FLETCHINDER, 0] => [:EMBER],
  [:SPEWPA, 0]      => [:PROTECT],
  [:SPEWPA, 1]      => [:PROTECT],
  [:SPEWPA, 2]      => [:PROTECT],
  [:SPEWPA, 3]      => [:PROTECT],
  [:SPEWPA, 4]      => [:PROTECT],
  [:SPEWPA, 5]      => [:PROTECT],
  [:SPEWPA, 6]      => [:PROTECT],
  [:SPEWPA, 7]      => [:PROTECT],
  [:SPEWPA, 8]      => [:PROTECT],
  [:SPEWPA, 9]      => [:PROTECT],
  [:SPEWPA, 10]     => [:PROTECT],
  [:SPEWPA, 11]     => [:PROTECT],
  [:SPEWPA, 12]     => [:PROTECT],
  [:SPEWPA, 13]     => [:PROTECT],
  [:SPEWPA, 14]     => [:PROTECT],
  [:SPEWPA, 15]     => [:PROTECT],
  [:SPEWPA, 16]     => [:PROTECT],
  [:SPEWPA, 17]     => [:PROTECT],
  [:SPEWPA, 18]     => [:PROTECT],
  [:SPEWPA, 19]     => [:PROTECT],
  [:VIVILLON, 0]    => [:GUST],
  [:VIVILLON, 1]    => [:GUST],
  [:VIVILLON, 2]    => [:GUST],
  [:VIVILLON, 3]    => [:GUST],
  [:VIVILLON, 4]    => [:GUST],
  [:VIVILLON, 5]    => [:GUST],
  [:VIVILLON, 6]    => [:GUST],
  [:VIVILLON, 7]    => [:GUST],
  [:VIVILLON, 8]    => [:GUST],
  [:VIVILLON, 9]    => [:GUST],
  [:VIVILLON, 10]   => [:GUST],
  [:VIVILLON, 11]   => [:GUST],
  [:VIVILLON, 12]   => [:GUST],
  [:VIVILLON, 13]   => [:GUST],
  [:VIVILLON, 14]   => [:GUST],
  [:VIVILLON, 15]   => [:GUST],
  [:VIVILLON, 16]   => [:GUST],
  [:VIVILLON, 17]   => [:GUST],
  [:VIVILLON, 18]   => [:GUST],
  [:VIVILLON, 19]   => [:GUST],
  [:GOGOAT, 0]      => [:AERIALACE],
  [:PANGORO, 0]     => [:BULLETPUNCH],
  [:DRAGALGE, 0]    => [:TWISTER],
  [:CLAWITZER, 0]   => [:AURASPHERE],
  [:TYRANTRUM, 0]   => [:ROCKSLIDE],
  [:AURORUS, 0]     => [:FREEZEDRY],
  [:SYLVEON, 0]     => [:FAIRYWIND],
  [:GOODRA, 0]      => [:AQUATAIL],
  [:TREVENANT, 0]   => [:SHADOWCLAW],
  [:AVALUGG, 0]     => [:BODYSLAM],

  # Gen VII
  [:DECIDUEYE, 0]    => [:SPIRITSHACKLE],
  [:INCINEROAR, 0]   => [:DARKESTLARIAT],
  [:PRIMARINA, 0]    => [:SPARKLINGARIA],
  [:TOUCANNON, 0]    => [:BEAKBLAST],
  [:CHARJABUG, 0]    => [:CHARGE],
  [:VIKAVOLT, 0]     => [:THUNDERBOLT],
  [:CRABOMINABLE, 0] => [:ICEPUNCH],
  [:RIBOMBEE, 0]     => [:POLLENPUFF],
  [:LYCANROC, 0]     => [:ACCELEROCK],
  [:LYCANROC, 1]     => [:COUNTER],
  [:LYCANROC, 2]     => [:THRASH],
  [:TOXAPEX, 0]      => [:BANEFULBUNKER],
  [:LURANTIS, 0]     => [:PETALBLIZZARD],
  [:SALAZZLE, 0]     => [:CAPTIVATE],
  [:BEWEAR, 0]       => [:BIND],
  [:STEENEE, 0]      => [:DOUBLESLAP],
  [:TSAREENA, 0]     => [:TROPKICK],
  [:GOLISOPOD, 0]    => [:FIRSTIMPRESSION],
  [:SILVALLY, 0]     => [:MULTIATTACK],
  [:HAKAMOO, 0]      => [:SKYUPPERCUT],
  [:KOMMOO, 0]       => [:CLANGINGSCALES],
  [:COSMOEM, 0]      => [:COSMICPOWER],
  [:SOLGALEO, 0]     => [:SUNSTEELSTRIKE],
  [:LUNALA, 0]       => [:MOONGEISTBEAM],
  [:MELMETAL, 0]     => [:THUNDERPUNCH],
  
  # Gen VIII
  [:THWACKEY, 0]     => [:DOUBLEHIT],
  [:RILLABOOM, 0]    => [:DRUMBEATING],
  [:CINDERACE, 0]    => [:PYROBALL],
  [:INTELEON, 0]     => [:SNIPESHOT],
  [:GREEDENT, 0]     => [:COVET],
  [:CORVIKNIGHT, 0]  => [:STEELWING],
  [:DOTTLER, 0]      => [:CONFUSION,:LIGHTSCREEN,:REFLECT],
  [:THIEVUL, 0]      => [:THIEF],
  [:DREDNAW, 0]      => [:ROCKTOMB],
  [:CARKOL, 0]       => [:FLAMECHARGE],
  [:COALOSSAL, 0]    => [:TARSHOT],
  [:FLAPPLE, 0]      => [:WINGATTACK],
  [:APPLETUN, 0]     => [:HEADBUTT],
  [:TOXTRICITY, 0]   => [:SPARK],
  [:TOXTRICITY, 1]   => [:SPARK],
  [:GRAPPLOCT, 0]    => [:OCTOLOCK],
  [:POLTEAGEIST, 0]  => [:TEATIME],
  [:HATTREM, 0]      => [:BRUTALSWING],
  [:HATTERENE, 0]    => [:PSYCHOCUT],
  [:MORGREM, 0]      => [:FALSESURRENDER],
  [:GRIMMSNARL, 0]   => [:SPIRITBREAK],
  [:OBSTAGOON, 1]    => [:OBSTRUCT],
  [:PERRSERKER, 2]   => [:IRONHEAD],
  [:SIRFETCHD, 1]    => [:IRONDEFENSE],
  [:RUNERIGUS, 1]    => [:SHADOWCLAW],
  [:ALCREMIE, 0]     => [:DECORATE],
  [:FROSMOTH, 0]     => [:ICYWIND],
  [:COPPERAJAH, 0]   => [:HEAVYSLAM],
  [:DRAKLOAK, 0]     => [:DRAGONPULSE],
  [:DRAGAPULT, 0]    => [:DRAGONDARTS],
  [:URSHIFU,0]       => [:WICKEDBLOW],
  [:URSHIFU,1]       => [:SURGINGSTRIKES]  
}

# This class stores data on each Pokemon.  Refer to $Trainer.party for an array
# of each Pokemon in the Trainer's current party.
class PokeBattle_Pokemon

  attr_accessor(:evolving)      # Is evolving

  alias initializeEvolutionMoves initialize
  def initialize(species,level,player=nil,withMoves=true)
    initializeEvolutionMoves(species,level,player,withMoves)
    @evolving=false
  end

################################################################################
# Moves                                                                        #
################################################################################

# Returns if the Pokémon is evolving.
  def evolving
    return @evolving
  end

# Returns a list of moves learned upon evolving, with the current level as the
# learn level
  def getEvolutionMoves
    name=getConstantName(PBSpecies,@species).to_sym
    key=[name, form]
    if EVOLUTIONMOVES[key] && @evolving
      movelist = []
      EVOLUTIONMOVES[key].each do |move|
        movelist.push([level,getID(PBMoves,move)])
      end
      return movelist
    else
      return []
    end
  end

# Returns the list of moves this Pokémon can learn by levelling up.
  alias getMoveListEvolutionMoves getMoveList
  def getMoveList
    return getEvolutionMoves + getMoveListEvolutionMoves
  end

end

class PokemonEvolutionScene

# Opens the evolution screen
  alias pbEvolutionEvolutionMoves pbEvolution
  def pbEvolution(cancancel=true)
    @pokemon.evolving = true
    pbEvolutionEvolutionMoves(cancancel)
    @pokemon.evolving = false
  end

end