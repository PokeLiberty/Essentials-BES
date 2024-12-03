# Resultados de una batalla:
#    0 - No decidido o cancelada
#    1 - Gana el jugador
#    2 - Pierde el jugador
#    3 - El jugador o Pokémon salvaje huye de la batalla, o el jugador pierde la partida
#    4 - El Pokémon salvaje fue atrapado
#    5 - Empate

################################################################################
# Catching and storing Pokémon.
################################################################################
module PokeBattle_BattleCommon
  def pbStorePokemon(pokemon)
    if !(pokemon.isShadow? rescue false)
      if pbDisplayConfirm(_INTL("¿Quieres ponerle un mote a {1}?",pokemon.name))
        species=PBSpecies.getName(pokemon.species)
        nickname=@scene.pbNameEntry(_INTL("Mote de {1}",species),pokemon)
        pokemon.name=nickname if nickname!=""
      end
    end
    if self.pbPlayer.party.length<6
      self.pbPlayer.party[self.pbPlayer.party.length]=pokemon
      return
    else
      pokemon2 = -1
      if pbDisplayConfirm(_INTL("¿Te gustaría añadir a {1} a tu equipo?",pokemon.name))
        pbDisplayPaused(_INTL("Selecciona un Pokémon para intercambiar."))
        pbChoosePokemon(1,2)
        poke = pbGet(1)
        if poke != -1
          pokemon2 = pokemon
          pokemon = self.pbPlayer.party[poke]
          pbRemovePokemonAt(poke)
          self.pbPlayer.party[self.pbPlayer.party.length]=pokemon2
        end
      end
      oldcurbox=@peer.pbCurrentBox()
      storedbox=@peer.pbStorePokemon(self.pbPlayer,pokemon)
      creator=@peer.pbGetStorageCreator()
      return if storedbox<0
      curboxname=@peer.pbBoxName(oldcurbox)
      boxname=@peer.pbBoxName(storedbox)
      if storedbox!=oldcurbox
        if creator
          pbDisplayPaused(_INTL("La caja \"{1}\" del PC de {2} está llena.",curboxname,creator))
        else
          pbDisplayPaused(_INTL("La caja \"{1}\" del PC de Alguien está llena.",curboxname))
        end
        pbDisplayPaused(_INTL("{1} fue transferido a la caja \"{2}\".",pokemon.name,boxname))
      else
        if creator
        pbDisplayPaused(_INTL("{1} fue transferido al PC de {2}.",pokemon.name,creator))
        else
        pbDisplayPaused(_INTL("{1} fue transferido al PC de Alguien.",pokemon.name))
        end
        pbDisplayPaused(_INTL("Fue guardado en la caja \"{1}\".",boxname))
      end
      if pokemon2 != -1
        pbSEPlay("PokemonGet")
        pbDisplayPaused(_INTL("¡{2} se une al equipo {1}!\1",$Trainer.name,pokemon2.name))
      end
    end
  end

  # Ball Fetch
  def tryFetchingBall(ball,safari,firstfailedthrowatsafari)
    ret=0
    if safari
      if !firstfailedthrowatsafari
        for i in 0...$Trainer.party.length
          if isConst?($Trainer.party[i].ability,PBAbilities,:BALLFETCH) &&
            $Trainer.party[i].item <= 0
            pbDisplay(_INTL("¡{1} ha encontrado una {2}!",$Trainer.party[i].name,PBItems.getName(ball)))
            PBDebug.log("[Ability triggered] #{$Trainer.party[i].name} fetched the #{PBItems.getName(ball)}")
            ret=-1
            break
          end
        end
      end
    else
      if !@firstfailedthrow
        for i in 0...$Trainer.party.length
          if isConst?($Trainer.party[i].ability,PBAbilities,:BALLFETCH) &&
            $Trainer.party[i].item <= 0
            $Trainer.party[i].item=ball
            $Trainer.party[i].itemInitial=ball
            pbDisplay(_INTL("¡{1} ha encontrado una {2}!",$Trainer.party[i].name,PBItems.getName(ball)))
            PBDebug.log("[Ability triggered] #{$Trainer.party[i].name} fetched the #{PBItems.getName(ball)}")
            ret=-1
            break
          end
        end
        @firstfailedthrow=true
      end
    end
    return ret
  end

# Retuns: 1 - success at capturing,
#         0 - fail at capturing and at fetching ball,
#        -1 - fail at capturing and success at fetching ball

def pbThrowPokeBall(idxPokemon,ball,rareness=nil,showplayer=false,safari=false,firstfailedthrowatsafari=false)
  ret=0
  itemname=PBItems.getName(ball)
  battler=nil
  if pbIsOpposing?(idxPokemon)
    battler=self.battlers[idxPokemon]
  else
    battler=self.battlers[idxPokemon].pbOppositeOpposing
  end
  if battler.isFainted?
    battler=battler.pbPartner
  end
  pbDisplayBrief(_INTL("{1} usó una {2}.",self.pbPlayer.name,itemname))
  if battler.isFainted?
    pbDisplay(_INTL("Pero no hay objetivo..."))
    return tryFetchingBall(ball,safari,firstfailedthrowatsafari)
  end
  if @opponent && (!pbIsSnagBall?(ball) || !battler.isShadow?)
    @scene.pbThrowAndDeflect(ball,1)
    pbDisplay(_INTL("¡El entrenador ha bloqueado la Poké Ball!<br>¡No seas un ladrón!"))
    ret=tryFetchingBall(ball,safari,firstfailedthrowatsafari)
  elsif $game_switches[NO_CAPTURE_SWITCH] || @rules["disablePokeBalls"]
   @scene.pbThrowAndDeflect(ball,1)
   pbDisplay(_INTL("No puedes capturar a este Pokémon."))
  else
    pokemon=battler.pokemon
    species=pokemon.species
    if $DEBUG && Input.press?(Input::CTRL) || @rules["alwaysCapture"]
      shakes=4
    elsif @rules["neverCapture"]
      shakes=0
    else
      if !rareness
        dexdata=pbOpenDexData
        pbDexDataOffset(dexdata,species,16)
        rareness=dexdata.fgetb # Get rareness from dexdata file
        dexdata.close
      end
      a=battler.totalhp
      b=battler.hp
      rareness=BallHandlers.modifyCatchRate(ball,rareness,self,battler)
      x=(((a*3-b*2)*rareness)/(a*3)).floor
      if battler.status==PBStatuses::SLEEP || battler.status==PBStatuses::FROZEN
        x=(x*2.5).floor
      elsif battler.status!=0
        x=(x*1.5).floor
      end
      c=0
      if $Trainer
        if $Trainer.pokedexOwned>600
          c=(x*2.5/6).floor
        elsif $Trainer.pokedexOwned>450
          c=(x*2/6).floor
        elsif $Trainer.pokedexOwned>300
          c=(x*1.5/6).floor
        elsif $Trainer.pokedexOwned>150
          c=(x*1/6).floor
        elsif $Trainer.pokedexOwned>30
          c=(x*0.5/6).floor
        end
      end
      shakes=0; critical=false
      if x>255 || BallHandlers.isUnconditional?(ball,self,battler)
        shakes=4
      else
        x=1 if x<1
        y = ( 65536/((255.0/x)**0.1875) ).floor
        if USECRITICALCAPTURE && pbRandom(256)<c
          critical=true
          shakes=4 if pbRandom(65536)<y
        else
          shakes+=1 if pbRandom(65536)<y
          shakes+=1 if pbRandom(65536)<y && shakes==1
          shakes+=1 if pbRandom(65536)<y && shakes==2
          shakes+=1 if pbRandom(65536)<y && shakes==3
        end
      end
    end
    PBDebug.log("[Poké Ball lanzada] #{itemname}, #{shakes} sacudidas (4=captura)")
    @scene.pbThrow(ball,shakes,critical,battler.index,showplayer)
    case shakes
    when 0
      pbDisplay(_INTL("¡Oh no! ¡El Pokémon se ha escapado!"))
      BallHandlers.onFailCatch(ball,self,battler)
      ret=tryFetchingBall(ball,safari,firstfailedthrowatsafari)
    when 1
      pbDisplay(_INTL("¡Vaya! ¡Parecía que ya estaba capturado!"))
      BallHandlers.onFailCatch(ball,self,battler)
      ret=tryFetchingBall(ball,safari,firstfailedthrowatsafari)
    when 2
      pbDisplay(_INTL("¡Aargh! ¡Casi lo tenías!"))
      BallHandlers.onFailCatch(ball,self,battler)
      ret=tryFetchingBall(ball,safari,firstfailedthrowatsafari)
    when 3
      pbDisplay(_INTL("¡Uy! ¡Estuvo demasiado cerca!"))
      BallHandlers.onFailCatch(ball,self,battler)
      ret=tryFetchingBall(ball,safari,firstfailedthrowatsafari)
    when 4
      pbDisplayBrief(_INTL("¡Sí! ¡{1} ha sido capturado!",pokemon.name))
      @scene.pbThrowSuccess
      if pbIsSnagBall?(ball) && @opponent
        pbRemoveFromParty(battler.index,battler.pokemonIndex)
        battler.pbReset
        battler.participants=[]
      else
        @decision=4
      end
      if pbIsSnagBall?(ball)
        pokemon.ot=self.pbPlayer.name
        pokemon.trainerID=self.pbPlayer.id
      end
      BallHandlers.onCatch(ball,self,pokemon)
      pokemon.ballused=pbGetBallType(ball)
      pokemon.makeUnmega rescue nil
      pokemon.makeUnprimal rescue nil
      pokemon.makeUnultra rescue nil
      pokemon.revertOtherForms rescue nil
      pokemon.pbRecordFirstMoves
      if GAINEXPFORCAPTURE
        battler.captured=true
        pbGainEXP
        battler.captured=false
      end
      if !self.pbPlayer.hasOwned?(species)
        self.pbPlayer.setOwned(species)
        if $Trainer.pokedex
          pbDisplayPaused(_INTL("Se agregaron los datos de {1} en la Pokédex.",pokemon.name))
          @scene.pbShowPokedex(species)
        end
      end
      @scene.pbHideCaptureBall
      if pbIsSnagBall?(ball) && @opponent
        pokemon.pbUpdateShadowMoves rescue nil
        @snaggedpokemon.push(pokemon)
      else
        pbStorePokemon(pokemon)
      end
      ret=1
    end
  end
  return ret
end
end

################################################################################
# Main battle class.
################################################################################
class PokeBattle_Battle
  attr_reader(:scene)             # Scene object for this battle
  attr_accessor(:decision)        # Decision: 0=undecided; 1=win; 2=loss; 3=escaped; 4=caught
  attr_accessor(:internalbattle)  # Internal battle flag
  attr_accessor(:doublebattle)    # Double battle flag
  attr_accessor(:cantescape)      # True if player can't escape
  attr_accessor(:shiftStyle)      # Shift/Set "battle style" option
  attr_accessor(:battlescene)     # "Battle scene" option
  attr_accessor(:debug)           # Debug flag
  attr_reader(:player)            # Player trainer
  attr_reader(:opponent)          # Opponent trainer
  attr_reader(:party1)            # Player's Pokémon party
  attr_reader(:party2)            # Foe's Pokémon party
  attr_reader(:party1order)       # Order of Pokémon in the player's party
  attr_reader(:party2order)       # Order of Pokémon in the opponent's party
  attr_accessor(:fullparty1)      # True if player's party's max size is 6 instead of 3
  attr_accessor(:fullparty2)      # True if opponent's party's max size is 6 instead of 3
  attr_reader(:battlers)          # Currently active Pokémon
  attr_accessor(:items)           # Items held by opponents
  attr_reader(:sides)             # Effects common to each side of a battle
  attr_reader(:field)             # Effects common to the whole of a battle
  attr_accessor(:environment)     # Battle surroundings
  attr_accessor(:weather)         # Current weather, custom methods should use pbWeather instead
  attr_accessor(:weatherduration) # Duration of current weather, or -1 if indefinite
  attr_reader(:switching)         # True if during the switching phase of the round
  attr_reader(:futuresight)       # True if Future Sight is hitting
  attr_reader(:struggle)          # The Struggle move
  attr_accessor(:choices)         # Choices made by each Pokémon this round
  attr_reader(:successStates)     # Success states
  attr_accessor(:lastMoveUsed)    # Last move used
  attr_accessor(:lastMoveUser)    # Last move user
  attr_accessor(:megaEvolution)   # Battle index of each trainer's Pokémon to Mega Evolve
  attr_accessor :teraCristal      # Battle index of each trainer's Pokémon to Tera Cristal
  attr_accessor(:ultraBurst)      # Battle index of each trainer's Pokémon to Ultra Burst
  attr_accessor(:necrozmaVar)     # Store the form Necrozma was in initially if it bursts
  attr_accessor(:amuletcoin)      # Whether Amulet Coin's effect applies
  attr_accessor(:extramoney)      # Money gained in battle by using Pay Day
  attr_accessor(:doublemoney)     # Whether Happy Hour's effect applies
  attr_accessor(:endspeech)       # Speech by opponent when player wins
  attr_accessor(:endspeech2)      # Speech by opponent when player wins
  attr_accessor(:endspeechwin)    # Speech by opponent when opponent wins
  attr_accessor(:endspeechwin2)   # Speech by opponent when opponent wins
  attr_accessor(:rules)
  attr_reader(:turncount)
  attr_accessor :controlPlayer

  include PokeBattle_BattleCommon

  MAXPARTYSIZE = 6
  #MEGARINGS=[:MEGARING,:MEGABRACELET,:MEGACUFF,:MEGACHARM]
  #TERAORBS=MEGARINGS
  #ZRINGS=MEGARINGS
  # MOVIDO A BES-T Settings

  class BattleAbortedException < Exception; end

  def pbAbort
    raise BattleAbortedException.new("Battle aborted")
  end

  def pbDebugUpdate
  end

  def pbRandom(x)
    return rand(x)
  end

  def pbAIRandom(x)
    return rand(x)
  end

################################################################################
# Initialise battle class. / Inicializa la clase batalla
################################################################################
  def initialize(scene,p1,p2,player,opponent)
    $criticosFarf=0
    if p1.length==0
      raise ArgumentError.new(_INTL("El equipo 1 no tiene Pokémon."))
      return
    end
    if p2.length==0
      raise ArgumentError.new(_INTL("El equipo 2 no tiene Pokémon."))
      return
    end
    if p2.length>2 && !opponent
      raise ArgumentError.new(_INTL("Las batallas con más de dos Pokémon salvajes no están permitidas."))
      return
    end
    @scene           = scene
    @decision        = 0
    @internalbattle  = true
    @doublebattle    = false
    @cantescape      = false
    @shiftStyle      = true
    @battlescene     = true
    @debug           = false
    @debugupdate     = 0
    if opponent && player.is_a?(Array) && player.length==0
      player = player[0]
    end
    if opponent && opponent.is_a?(Array) && opponent.length==0
      opponent = opponent[0]
    end
    @player          = player                # PokeBattle_Trainer object
    @opponent        = opponent              # PokeBattle_Trainer object
    @party1          = p1
    @party2          = p2
    @party1order     = []
    for i in 0...12; @party1order.push(i); end
    @party2order     = []
    for i in 0...12; @party2order.push(i); end
    @fullparty1      = false
    @fullparty2      = false
    @battlers        = []
    @items           = nil
    @sides           = [PokeBattle_ActiveSide.new,   # Player's side
                        PokeBattle_ActiveSide.new]   # Foe's side
    @field           = PokeBattle_ActiveField.new    # Whole field (gravity/rooms)
    @environment     = PBEnvironment::None
    @rules           = $PokemonTemp.battle_rules || {}
    @weather         = 0
    @weatherduration = 0
    case @rules["terrain"]
    when :Electric
      @field.effects[PBEffects::ElectricTerrain]=999
    when :Grassy
      @field.effects[PBEffects::GrassyTerrain]=999
    when :Misty
      @field.effects[PBEffects::MistyTerrain]=999
    when :Psychic
      @field.effects[PBEffects::PsychicTerrain]=999
    end
    @switching       = false
    @futuresight     = false
    @choices         = [ [0,0,nil,-1],[0,0,nil,-1],[0,0,nil,-1],[0,0,nil,-1] ]
    @successStates   = []
    for i in 0...4
      @successStates.push(PokeBattle_SuccessState.new)
    end
    @lastMoveUsed    = -1
    @lastMoveUser    = -1
    @nextPickupUse   = 0
    @megaEvolution   = []
    @ultraBurst      = []
    @teraCristal     = []
    @necrozmaVar     = [-1,-1]
    @zMove           = []
    if @player.is_a?(Array)
      @megaEvolution[0]=[-1]*@player.length
      @ultraBurst[0]   =[-1]*@player.length
      @teraCristal[0]   =[-1]*@player.length
      @zMove[0]=[-1]*@player.length
    else
      @megaEvolution[0]=[-1]
      @ultraBurst[0]=[-1]
      @teraCristal[0]=[-1]
      @zMove[0]=[-1]
    end
    if @opponent.is_a?(Array)
      @megaEvolution[1]=[-1]*@opponent.length
      @ultraBurst[1]   =[-1]*@opponent.length
      @teraCristal[1]   =[-1]*@opponent.length
      @zMove[1]=[-1]*@opponent.length
    else
      @megaEvolution[1]=[-1]
      @ultraBurst[1]=[-1]
      @teraCristal[1]=[-1]
      @zMove[1]=[-1]
    end
    @amuletcoin       = false
    @extramoney       = 0
    @doublemoney      = false
    @endspeech        = ""
    @endspeech2       = ""
    @endspeechwin     = ""
    @endspeechwin2    = ""
    @turncount        = 0
    @peer             = PokeBattle_BattlePeer.create()
    @priority         = []
    @usepriority      = false
    @firstfailedthrow = false # First failed catch attempt with a pokeball
    @snaggedpokemon   = []
    @runCommand       = 0
    if hasConst?(PBMoves,:STRUGGLE)
      @struggle = PokeBattle_Move.pbFromPBMove(self,PBMove.new(getConst(PBMoves,:STRUGGLE)))
    else
      @struggle = PokeBattle_Struggle.new(self,nil)
    end
    @struggle.pp     = -1
    for i in 0...4
      battlers[i] = PokeBattle_Battler.new(self,i)
    end
    for i in @party1
      next if !i
      i.itemRecycle = 0
      i.itemInitial = i.item
      i.belch       = false
    end
    for i in @party2
      next if !i
      i.itemRecycle = 0
      i.itemInitial = i.item
      i.belch       = false
    end
  end

################################################################################
# Info about battle. / Información sobre la batalla
################################################################################
  def pbDoubleBattleAllowed?
    if !@fullparty1 && @party1.length>MAXPARTYSIZE
      return false
    end
    if !@fullparty2 && @party2.length>MAXPARTYSIZE
      return false
    end
    _opponent=@opponent
    _player=@player
    # Wild battle
    if !_opponent
      if @party2.length==1
        return false
      elsif @party2.length==2
        return true
      else
        return false
      end
    # Trainer battle
    else
      if _opponent.is_a?(Array)
        if _opponent.length==1
          _opponent=_opponent[0]
        elsif _opponent.length!=2
          return false
        end
      end
      _player=_player
      if _player.is_a?(Array)
        if _player.length==1
          _player=_player[0]
        elsif _player.length!=2
          return false
        end
      end
      if _opponent.is_a?(Array)
        sendout1=pbFindNextUnfainted(@party2,0,pbSecondPartyBegin(1))
        sendout2=pbFindNextUnfainted(@party2,pbSecondPartyBegin(1))
        return false if sendout1<0 || sendout2<0
      else
        sendout1=pbFindNextUnfainted(@party2,0)
        sendout2=pbFindNextUnfainted(@party2,sendout1+1)
        return false if sendout1<0 || sendout2<0
      end
    end
    if _player.is_a?(Array)
      sendout1=pbFindNextUnfainted(@party1,0,pbSecondPartyBegin(0))
      sendout2=pbFindNextUnfainted(@party1,pbSecondPartyBegin(0))
      return false if sendout1<0 || sendout2<0
    else
      sendout1=pbFindNextUnfainted(@party1,0)
      sendout2=pbFindNextUnfainted(@party1,sendout1+1)
      return false if sendout1<0 || sendout2<0
    end
    return true
  end

  def pbWeather
    for i in 0...4
      if @battlers[i].hasWorkingAbility(:CLOUDNINE) ||
         @battlers[i].hasWorkingAbility(:AIRLOCK)
        return 0
      end
    end
    return @weather
  end

################################################################################
# Get battler info. / Obtiene información de la batalla
################################################################################
  def pbIsOpposing?(index)
    return (index%2)==1
  end

  def pbOwnedByPlayer?(index)
    return false if pbIsOpposing?(index)
    return false if @player.is_a?(Array) && index==2
    return true
  end

  def pbIsDoubleBattler?(index)
    return (index>=2)
  end

  # Only used for Wish      / Solo usado para Deseo
  def pbThisEx(battlerindex,pokemonindex)
    party=pbParty(battlerindex)
    if pbIsOpposing?(battlerindex)
      if @opponent
        return _INTL("El {1} rival",party[pokemonindex].name)
      else
        return _INTL("El {1} salvaje",party[pokemonindex].name)
      end
    else
      return _INTL("{1}",party[pokemonindex].name)
    end
  end

# Checks whether an item can be removed from a Pokémon.
  def pbIsUnlosableItem(pkmn,item)
    return true if pbIsMail?(item)
    return true if pbIsZCrystal?(item)
    return false if pkmn.effects[PBEffects::Transform]
    if isConst?(pkmn.ability,PBAbilities,:MULTITYPE)
      plates=[:FISTPLATE,:SKYPLATE,:TOXICPLATE,:EARTHPLATE,:STONEPLATE,
              :INSECTPLATE,:SPOOKYPLATE,:IRONPLATE,:FLAMEPLATE,:SPLASHPLATE,
              :MEADOWPLATE,:ZAPPLATE,:MINDPLATE,:ICICLEPLATE,:DRACOPLATE,
              :DREADPLATE,:PIXIEPLATE]
      for i in plates
        return true if isConst?(item,PBItems,i)
      end
    end
    if isConst?(pkmn.ability,PBAbilities,:RKSSYSTEM)
      memories=[:FIGHTINGMEMORY,:FLYINGMEMORY,:POISONMEMORY,:GROUNDMEMORY,
                :ROCKMEMORY,:BUGMEMORY,:GHOSTMEMORY,:STEELMEMORY,:FIREMEMORY,
                :WATERMEMORY,:GRASSMEMORY,:ELECTRICMEMORY,:PSYCHICMEMORY,
                :ICEMEMORY,:DRAGONMEMORY,:DARKMEMORY,:FAIRYMEMORY]
      for i in memories
        return true if isConst?(item,PBItems,i)
      end
    end
    combos=[[:DIALGA,:ADAMANTORB],
            [:PALKIA,:LUSTROUSORB],
            [:GIRATINA,:GRISEOUSORB],
            [:GENESECT,:BURNDRIVE],
            [:GENESECT,:CHILLDRIVE],
            [:GENESECT,:DOUSEDRIVE],
            [:GENESECT,:SHOCKDRIVE],
            [:NECROZMA,:ULTRANECROZIUMZ],
            [:ZACIAN,:RUSTEDSWORD],
            [:ZAMAZENTA,:RUSTEDSHIELD],
            # Mega Stones
            [:ABOMASNOW,:ABOMASITE],
            [:ABSOL,:ABSOLITE],
            [:AERODACTYL,:AERODACTYLITE],
            [:AGGRON,:AGGRONITE],
            [:ALAKAZAM,:ALAKAZITE],
            [:ALTARIA,:ALTARIANITE],
            [:AMPHAROS,:AMPHAROSITE],
            [:AUDINO,:AUDINITE],
            [:BANETTE,:BANETTITE],
            [:BEEDRILL,:BEEDRILLITE],
            [:BLASTOISE,:BLASTOISINITE],
            [:BLAZIKEN,:BLAZIKENITE],
            [:CAMERUPT,:CAMERUPTITE],
            [:CHARIZARD,:CHARIZARDITEX],
            [:CHARIZARD,:CHARIZARDITEY],
            [:DIANCIE,:DIANCITE],
            [:GALLADE,:GALLADITE],
            [:GARCHOMP,:GARCHOMPITE],
            [:GARDEVOIR,:GARDEVOIRITE],
            [:GENGAR,:GENGARITE],
            [:GLALIE,:GLALITITE],
            [:GYARADOS,:GYARADOSITE],
            [:HERACROSS,:HERACRONITE],
            [:HOUNDOOM,:HOUNDOOMINITE],
            [:KANGASKHAN,:KANGASKHANITE],
            [:LATIAS,:LATIASITE],
            [:LATIOS,:LATIOSITE],
            [:LOPUNNY,:LOPUNNITE],
            [:LUCARIO,:LUCARIONITE],
            [:MANECTRIC,:MANECTITE],
            [:MAWILE,:MAWILITE],
            [:MEDICHAM,:MEDICHAMITE],
            [:METAGROSS,:METAGROSSITE],
            [:MEWTWO,:MEWTWONITEX],
            [:MEWTWO,:MEWTWONITEY],
            [:PIDGEOT,:PIDGEOTITE],
            [:PINSIR,:PINSIRITE],
            [:SABLEYE,:SABLENITE],
            [:SALAMENCE,:SALAMENCITE],
            [:SCEPTILE,:SCEPTILITE],
            [:SCIZOR,:SCIZORITE],
            [:SHARPEDO,:SHARPEDONITE],
            [:SLOWBRO,:SLOWBRONITE],
            [:STEELIX,:STEELIXITE],
            [:SWAMPERT,:SWAMPERTITE],
            [:TYRANITAR,:TYRANITARITE],
            [:VENUSAUR,:VENUSAURITE],
            # Primal Reversion stones
            [:KYOGRE,:BLUEORB],
            [:GROUDON,:REDORB]
           ]
    for i in combos
      if isConst?(pkmn.species,PBSpecies,i[0]) && isConst?(item,PBItems,i[1])
        return true
      end
    end
    return false
  end

  def pbCheckGlobalAbility(a)
    for i in 0...4 # in order from own first, opposing first, own second, opposing second
      if @battlers[i].hasWorkingAbility(a)
        return @battlers[i]
      end
    end
    return nil
  end

  def nextPickupUse
    @nextPickupUse+=1
    return @nextPickupUse
  end

################################################################################
# Player-related info.
################################################################################
  def pbPlayer
    if @player.is_a?(Array)
      return @player[0]
    else
      return @player
    end
  end

  def pbGetOwnerItems(battlerIndex)
    return [] if !@items
    if pbIsOpposing?(battlerIndex)
      if @opponent.is_a?(Array)
        return (battlerIndex==1) ? @items[0] : @items[1]
      else
        return @items
      end
    else
      return []
    end
  end

  def pbSetSeen(pokemon)
    if pokemon && @internalbattle
      self.pbPlayer.seen[pokemon.species]=true
      pbSeenForm(pokemon)
    end
  end

  def pbGetMegaRingName(battlerIndex)
    if pbBelongsToPlayer?(battlerIndex)
      for i in MEGARINGS
        next if !hasConst?(PBItems,i)
        return PBItems.getName(getConst(PBItems,i)) if $PokemonBag.pbQuantity(i)>0
      end
    end
    # Add your own Mega objects for particular trainer types here
#    if isConst?(pbGetOwner(battlerIndex).trainertype,PBTrainers,:BUGCATCHER)
#      return _INTL("Mega Net")
#    end
    return _INTL("Mega Aro")
  end

  def pbHasMegaRing(battlerIndex)
    return true if !pbBelongsToPlayer?(battlerIndex)
    for i in MEGARINGS
      next if !hasConst?(PBItems,i)
      return true if $PokemonBag.pbQuantity(i)>0
    end
    return false
  end

  def pbHasZRing(battlerIndex)
    return true if !pbBelongsToPlayer?(battlerIndex)
    for i in ZRINGS
      next if !hasConst?(PBItems,i)
      return true if $PokemonBag.pbQuantity(i)>0
    end
    return false
  end

  def pbHasTeraOrb(battlerIndex)
    return true if !pbBelongsToPlayer?(battlerIndex)
    for i in TERAORBS
      next if !hasConst?(PBItems,i)
      return true if $PokemonBag.pbQuantity(i)>0
    end
    return false
  end
################################################################################
# Get party info, manipulate parties. / Obtiene información del equipo,
################################################################################
  def pbPokemonCount(party)
    count=0
    for i in party
      next if !i
      count+=1 if i.hp>0 && !i.isEgg?
    end
    return count
  end

  def pbAllFainted?(party)
    pbPokemonCount(party)==0
  end

  def pbMaxLevel(party)
    lv=0
    for i in party
      next if !i
      lv=i.level if lv<i.level
    end
    return lv
  end

  def pbMaxLevelFromIndex(index)
    party=pbParty(index)
    owner=(pbIsOpposing?(index)) ? @opponent : @player
    maxlevel=0
    if owner.is_a?(Array)
      start=0
      limit=pbSecondPartyBegin(index)
      start=limit if pbIsDoubleBattler?(index)
      for i in start...start+limit
        next if !party[i]
        maxlevel=party[i].level if maxlevel<party[i].level
      end
    else
      for i in party
        next if !i
        maxlevel=i.level if maxlevel<i.level
      end
    end
    return maxlevel
  end

  def pbParty(index)
    return pbIsOpposing?(index) ? party2 : party1
  end

  def pbOpposingParty(index)
    return pbIsOpposing?(index) ? party1 : party2
  end

  def pbSecondPartyBegin(battlerIndex)
    if pbIsOpposing?(battlerIndex)
      return @fullparty2 ? 6 : 3
    else
      return @fullparty1 ? 6 : 3
    end
  end

  def pbPartyLength(battlerIndex)
    if pbIsOpposing?(battlerIndex)
      return (@opponent.is_a?(Array)) ? pbSecondPartyBegin(battlerIndex) : MAXPARTYSIZE
    else
      return @player.is_a?(Array) ? pbSecondPartyBegin(battlerIndex) : MAXPARTYSIZE
    end
  end

  def pbFindNextUnfainted(party,start,finish=-1)
    finish=party.length if finish<0
    for i in start...finish
      next if !party[i]
      return i if party[i].hp>0 && !party[i].isEgg?
    end
    return -1
  end

  def pbGetLastPokeInTeam(index)
    party=pbParty(index)
    partyorder=(!pbIsOpposing?(index)) ? @party1order : @party2order
    plength=pbPartyLength(index)
    pstart=pbGetOwnerIndex(index)*plength
    lastpoke=-1
    for i in pstart...pstart+plength
      p=party[partyorder[i]]
      next if !p || p.isEgg? || p.hp<=0
      lastpoke=partyorder[i]
    end
    return lastpoke
  end

  def pbFindPlayerBattler(pkmnIndex)
    battler=nil
    for k in 0...4
      if !pbIsOpposing?(k) && @battlers[k].pokemonIndex==pkmnIndex
        battler=@battlers[k]
        break
      end
    end
    return battler
  end

  def pbIsOwner?(battlerIndex,partyIndex)
    secondParty=pbSecondPartyBegin(battlerIndex)
    if !pbIsOpposing?(battlerIndex)
      return true if !@player || !@player.is_a?(Array)
      return (battlerIndex==0) ? partyIndex<secondParty : partyIndex>=secondParty
    else
      return true if !@opponent || !@opponent.is_a?(Array)
      return (battlerIndex==1) ? partyIndex<secondParty : partyIndex>=secondParty
    end
  end

  def pbGetOwner(battlerIndex)
    if pbIsOpposing?(battlerIndex)
      if @opponent.is_a?(Array)
        return (battlerIndex==1) ? @opponent[0] : @opponent[1]
      else
        return @opponent
      end
    else
      if @player.is_a?(Array)
        return (battlerIndex==0) ? @player[0] : @player[1]
      else
        return @player
      end
    end
  end

  def pbGetOwnerPartner(battlerIndex)
    if pbIsOpposing?(battlerIndex)
      if @opponent.is_a?(Array)
        return (battlerIndex==1) ? @opponent[1] : @opponent[0]
      else
        return @opponent
      end
    else
      if @player.is_a?(Array)
        return (battlerIndex==0) ? @player[1] : @player[0]
      else
        return @player
      end
    end
  end

  def pbGetOwnerIndex(battlerIndex)
    if pbIsOpposing?(battlerIndex)
      return (@opponent.is_a?(Array)) ? ((battlerIndex==1) ? 0 : 1) : 0
    else
      return (@player.is_a?(Array)) ? ((battlerIndex==0) ? 0 : 1) : 0
    end
  end

  def pbBelongsToPlayer?(battlerIndex)
    if @player.is_a?(Array) && @player.length>1
      return battlerIndex==0
    else
      return (battlerIndex%2)==0
    end
    return false
  end

  def pbPartyGetOwner(battlerIndex,partyIndex)
    secondParty=pbSecondPartyBegin(battlerIndex)
    if !pbIsOpposing?(battlerIndex)
      return @player if !@player || !@player.is_a?(Array)
      return (partyIndex<secondParty) ? @player[0] : @player[1]
    else
      return @opponent if !@opponent || !@opponent.is_a?(Array)
      return (partyIndex<secondParty) ? @opponent[0] : @opponent[1]
    end
  end

  def pbAddToPlayerParty(pokemon)
    party=pbParty(0)
    for i in 0...party.length
      party[i]=pokemon if pbIsOwner?(0,i) && !party[i]
    end
  end

  def pbRemoveFromParty(battlerIndex,partyIndex)
    party=pbParty(battlerIndex)
    side=(pbIsOpposing?(battlerIndex)) ? @opponent : @player
    order=(pbIsOpposing?(battlerIndex)) ? @party2order : @party1order
    secondpartybegin=pbSecondPartyBegin(battlerIndex)
    party[partyIndex]=nil
    if !side || !side.is_a?(Array) # Oponente individual o salvaje
      party.compact!
      for i in partyIndex...party.length+1
        for j in 0...4
          next if !@battlers[j]
          if pbGetOwner(j)==side && @battlers[j].pokemonIndex==i
            @battlers[j].pokemonIndex-=1
            break
          end
        end
      end
      for i in 0...order.length
        order[i]=(i==partyIndex) ? order.length-1 : order[i]-1
      end
    else
      if partyIndex<secondpartybegin-1
        for i in partyIndex...secondpartybegin
          if i>=secondpartybegin-1
            party[i]=nil
          else
            party[i]=party[i+1]
          end
        end
        for i in 0...order.length
          next if order[i]>=secondpartybegin
          order[i]=(i==partyIndex) ? secondpartybegin-1 : order[i]-1
        end
      else
        for i in partyIndex...secondpartybegin+pbPartyLength(battlerIndex)
          if i>=party.length-1
            party[i]=nil
          else
            party[i]=party[i+1]
          end
        end
        for i in 0...order.length
          next if order[i]<secondpartybegin
          order[i]=(i==partyIndex) ? secondpartybegin+pbPartyLength(battlerIndex)-1 : order[i]-1
        end
      end
    end
  end

################################################################################
# Check whether actions can be taken. / Verifica cuando se pueden tomar acciones
################################################################################
  def pbCanShowCommands?(idxPokemon)
    thispkmn=@battlers[idxPokemon]
    return false if thispkmn.isFainted?
    return false if thispkmn.effects[PBEffects::TwoTurnAttack]>0
    return false if thispkmn.effects[PBEffects::HyperBeam]>0
    return false if thispkmn.effects[PBEffects::Rollout]>0
    return false if thispkmn.effects[PBEffects::Outrage]>0
    return false if thispkmn.effects[PBEffects::Uproar]>0
    return false if thispkmn.effects[PBEffects::Bide]>0
    return false if thispkmn.effects[PBEffects::Commander]>0
    return true
  end

  def zMove
    return @zMove
  end

################################################################################
# Attacking. / Atacando
################################################################################
  def pbCanShowFightMenu?(idxPokemon)
    thispkmn=@battlers[idxPokemon]
    if !pbCanShowCommands?(idxPokemon)
      return false
    end
    # No hay movimientos que se puedan elegir
    if !pbCanChooseMove?(idxPokemon,0,false) &&
       !pbCanChooseMove?(idxPokemon,1,false) &&
       !pbCanChooseMove?(idxPokemon,2,false) &&
       !pbCanChooseMove?(idxPokemon,3,false)
      return false
    end
    # Encore / Repetición
    return false if thispkmn.effects[PBEffects::Encore]>0
    return true
  end

  def pbCanChooseMove?(idxPokemon,idxMove,showMessages,sleeptalk=false)
    thispkmn=@battlers[idxPokemon]
    thismove=thispkmn.moves[idxMove]
    opp1=thispkmn.pbOpposing1
    opp2=thispkmn.pbOpposing2
    if !thismove||thismove.id==0
      return false
    end
    if thismove.pp<=0 && thismove.totalpp>0 && !sleeptalk
      if showMessages
        pbDisplayPaused(_INTL("¡No quedan PP para este movimiento!"))
      end
      return false
    end
    if thispkmn.hasWorkingItem(:ASSAULTVEST) && thismove.pbIsStatus?
      if showMessages
        pbDisplayPaused(_INTL("¡El {1} impide el uso de movimientos de estado!",
           PBItems.getName(thispkmn.item)))
      end
      return false
    end
    if thispkmn.effects[PBEffects::ChoiceBand]>=0 &&
       (thispkmn.hasWorkingItem(:CHOICEBAND) ||
       thispkmn.hasWorkingItem(:CHOICESPECS) ||
       thispkmn.hasWorkingItem(:CHOICESCARF))
      hasmove=false
      for i in 0...4
        if thispkmn.moves[i].id==thispkmn.effects[PBEffects::ChoiceBand]
          hasmove=true; break
        end
      end
      if hasmove && thismove.id!=thispkmn.effects[PBEffects::ChoiceBand]
        if showMessages
          pbDisplayPaused(_INTL("¡La {1} solo permite el uso de {2}!",
             PBItems.getName(thispkmn.item),
             PBMoves.getName(thispkmn.effects[PBEffects::ChoiceBand])))
        end
        return false
      end
    end
    if opp1.effects[PBEffects::Imprison]
      if thismove.id==opp1.moves[0].id ||
         thismove.id==opp1.moves[1].id ||
         thismove.id==opp1.moves[2].id ||
         thismove.id==opp1.moves[3].id
        if showMessages
          pbDisplayPaused(_INTL("¡{1} no puede usar {2} por estar sellado!",thispkmn.pbThis,thismove.name))
        end
        #PBDebug.log("[CanChoose][#{opp1.pbThis} has: #{opp1.moves[0].name}, #{opp1.moves[1].name},#{opp1.moves[2].name},#{opp1.moves[3].name}]")
        return false
      end
    end
    if opp2.effects[PBEffects::Imprison]    # Cerca
      if thismove.id==opp2.moves[0].id ||
         thismove.id==opp2.moves[1].id ||
         thismove.id==opp2.moves[2].id ||
         thismove.id==opp2.moves[3].id
        if showMessages
          pbDisplayPaused(_INTL("¡{1} no puede usar {2} por estar sellado!",thispkmn.pbThis,thismove.name))
        end
        #PBDebug.log("[CanChoose][#{opp2.pbThis} has: #{opp2.moves[0].name}, #{opp2.moves[1].name},#{opp2.moves[2].name},#{opp2.moves[3].name}]")
        return false
      end
    end
    if thispkmn.effects[PBEffects::ThroatChop]>0 && thismove.isSoundBased?
      if showMessages
        pbDisplayPaused(_INTL("¡{1} no pudo usar {2} debido a Golpe Mordaza!",thispkmn.pbThis,thismove.name))
      end
      return false
    end
    if thispkmn.effects[PBEffects::Taunt]>0 && thismove.basedamage==0   # Mofa
      if showMessages
        pbDisplayPaused(_INTL("¡{1} no puede usar {2} por la mofa!",thispkmn.pbThis,thismove.name))
      end
      return false
    end
    if thispkmn.effects[PBEffects::Torment]     # Tormento
      if thismove.id==thispkmn.lastMoveUsed
        if showMessages
          pbDisplayPaused(_INTL("¡{1} no puede utilizar el mismo movimiento dos veces seguidas debido al tormento!",thispkmn.pbThis))
        end
        return false
      end
    end
    if thispkmn.effects[PBEffects::GigatonHammer]==2     # Martillo Colosal
      if thismove.function==0x245
        if showMessages
          pbDisplayPaused(_INTL("¡{1} no puede usar este movimiento dos veces seguidas!",thispkmn.pbThis))
        end
        return false
      end
    end
    if thismove.id==thispkmn.effects[PBEffects::DisableMove] && !sleeptalk      # Movimiento deshabilitado
      if showMessages
        pbDisplayPaused(_INTL("¡{1} tiene deshabilitado {2}!",thispkmn.pbThis,thismove.name))
      end
      return false
    end
    if thismove.function==0x158 && # Belch
       (!thispkmn.pokemon || !thispkmn.pokemon.belch)
      if showMessages
        pbDisplayPaused(_INTL("¡{1} no ha comido ninguna baya, por lo que no se puede reciclar!",thispkmn.pbThis))
      end
      return false
    end
    if thismove.function==0x188 && # Stuff Cheeks
       !pbIsBerry?(thispkmn.item)
      if showMessages
        pbDisplayPaused(_INTL("¡El Pokémon no puede usar el movimiento al no tener ninguna baya equipada!",thispkmn.pbThis))
      end
      return false
    end
    if thispkmn.effects[PBEffects::Encore]>0 && idxMove!=thispkmn.effects[PBEffects::EncoreIndex]
      return false
    end
    if thispkmn.effects[PBEffects::GorillaTactics]>=0 && thispkmn.hasWorkingAbility(:GORILLATACTICS)
      hasmove=false
      for i in 0...4
        if thispkmn.moves[i].id==thispkmn.effects[PBEffects::GorillaTactics]
          hasmove=true; break
        end
      end
      if hasmove && thismove.id!=thispkmn.effects[PBEffects::GorillaTactics]
        if showMessages
          pbDisplayPaused(_INTL("¡{1} solo puede usar {2}!",
             thispkmn.pbThis,
             PBMoves.getName(thispkmn.effects[PBEffects::GorillaTactics])))
        end
        return false
      end
    end
    return true
  end

  def pbAutoChooseMove(idxPokemon,showMessages=true)
    thispkmn=@battlers[idxPokemon]
    if thispkmn.isFainted?
      @choices[idxPokemon][0]=0
      @choices[idxPokemon][1]=0
      @choices[idxPokemon][2]=nil
      return
    end
    if thispkmn.effects[PBEffects::Encore]>0 &&
       pbCanChooseMove?(idxPokemon,thispkmn.effects[PBEffects::EncoreIndex],false)
      PBDebug.log("[Auto choosing Encore move] #{thispkmn.moves[thispkmn.effects[PBEffects::EncoreIndex]].name}")
      @choices[idxPokemon][0]=1    # "Use move"
      @choices[idxPokemon][1]=thispkmn.effects[PBEffects::EncoreIndex] # Index of move
      @choices[idxPokemon][2]=thispkmn.moves[thispkmn.effects[PBEffects::EncoreIndex]]
      @choices[idxPokemon][3]=-1   # No target chosen yet
      if @doublebattle
        thismove=thispkmn.moves[thispkmn.effects[PBEffects::EncoreIndex]]
        target=thispkmn.pbTarget(thismove)
        if target==PBTargets::SingleNonUser
          target=@scene.pbChooseTarget(idxPokemon,target)
          pbRegisterTarget(idxPokemon,target) if target>=0
        elsif target==PBTargets::UserOrPartner
          target=@scene.pbChooseTarget(idxPokemon,target)
          pbRegisterTarget(idxPokemon,target) if target>=0 && (target&1)==(idxPokemon&1)
        end
      end
    else
      if !pbIsOpposing?(idxPokemon)
        pbDisplayPaused(_INTL("¡A {1} no le quedan movimientos!",thispkmn.name)) if showMessages
      end
      @choices[idxPokemon][0]=1           # "Usa movimiento"
      @choices[idxPokemon][1]=-1          # Índice del movimiento usado
      @choices[idxPokemon][2]=@struggle   # Usa Combate
      @choices[idxPokemon][3]=-1          # Falta elegir objetivo
    end
  end

  def pbRegisterMove(idxPokemon,idxMove,showMessages=true)
    thispkmn=@battlers[idxPokemon]
    thismove=thispkmn.moves[idxMove]
    return false if !pbCanChooseMove?(idxPokemon,idxMove,showMessages)
    @choices[idxPokemon][0]=1         # "Usa movimiento"
    @choices[idxPokemon][1]=idxMove   # Índice del movimiento usado
    @choices[idxPokemon][2]=thismove  # PokeBattle_Move object of the move
    @choices[idxPokemon][3]=-1        # Falta elegir objetivo
    return true
  end

  def pbChoseMove?(i,move)
    return false if @battlers[i].isFainted?
    if @choices[i][0]==1 && @choices[i][1]>=0
      choice=@choices[i][1]
      return isConst?(@battlers[i].moves[choice].id,PBMoves,move)
    end
    return false
  end

  def pbChoseMoveFunctionCode?(i,code)
    return false if @battlers[i].isFainted?
    if @choices[i][0]==1 && @choices[i][1]>=0
      choice=@choices[i][1]
      return @battlers[i].moves[choice].function==code
    end
    return false
  end

  def pbRegisterTarget(idxPokemon,idxTarget)
    @choices[idxPokemon][3]=idxTarget   # Set target of move
    return true
  end

  def pbPriority(ignorequickclaw=false,log=false)
    return @priority if @usepriority # use stored priority if round isn't over yet
    @priority.clear
    speeds=[]
    priorities=[]
    quickclaw=[]; lagging=[]
    quickdraw=[]
    minpri=0; maxpri=0
    temp=[]
    # Calcula la velocidad de cada Pokémon
    for i in 0...4
      speeds[i]=@battlers[i].pbSpeed
      quickclaw[i]=false
      lagging[i]=false
      quickdraw[i]=false
      if !ignorequickclaw && @choices[i][0]==1 # Chose to use a move
        if !quickclaw[i] && !quickdraw[i] && @battlers[i].hasWorkingItem(:CUSTAPBERRY) &&
           !@battlers[i].pbOpposing1.hasWorkingAbility(:UNNERVE) &&
           !@battlers[i].pbOpposing2.hasWorkingAbility(:UNNERVE) &&
           !@battlers[i].pbOpposing1.hasWorkingAbility(:ASONE1) &&
           !@battlers[i].pbOpposing2.hasWorkingAbility(:ASONE1) &&
           !@battlers[i].pbOpposing1.hasWorkingAbility(:ASONE2) &&
           !@battlers[i].pbOpposing2.hasWorkingAbility(:ASONE2)
          if (@battlers[i].hasWorkingAbility(:GLUTTONY) && @battlers[i].hp<=(@battlers[i].totalhp/2).floor) ||
             @battlers[i].hp<=(@battlers[i].totalhp/4).floor
            pbCommonAnimation("UseItem",@battlers[i],nil)
            quickclaw[i]=true
            pbDisplayBrief(_INTL("¡{1} se mueve primero gracias a la {2}!",
               @battlers[i].pbThis,PBItems.getName(@battlers[i].item)))
            @battlers[i].pbConsumeItem
          end
        end
        if !quickclaw[i] && @battlers[i].hasWorkingItem(:QUICKCLAW)
          if pbRandom(10)<2
            pbCommonAnimation("UseItem",@battlers[i],nil)
            quickclaw[i]=true
            pbDisplayBrief(_INTL("¡{1} se mueve primero gracias a la {2}!",
               @battlers[i].pbThis,PBItems.getName(@battlers[i].item)))
          end
        end
        if !quickclaw[i] && !quickdraw[i] && @battlers[i].hasWorkingAbility(:QUICKDRAW)
          if pbRandom(10)<2

            quickdraw[i]=true
            pbDisplayBrief(_INTL("¡{1} se mueve primero gracias a Mano Rápida!",
               @battlers[i].pbThis))
          end
        end
        if !quickclaw[i] && !quickdraw[i] &&
           (@battlers[i].hasWorkingAbility(:STALL) ||
           @battlers[i].hasWorkingItem(:LAGGINGTAIL) ||
           @battlers[i].hasWorkingItem(:FULLINCENSE))
          lagging[i]=true
        end
      end
    end
    # Calculate each Pokémon's priority bracket, and get the min/max priorities
    for i in 0...4
      # Assume that doing something other than using a move is priority 0
      pri=0
      if @choices[i][0]==1 # Chose to use a move
        pri=@choices[i][2].priority
        pri+=1 if @field.effects[PBEffects::GrassyTerrain]>0 &&
                  @choices[i][2].function == 0x211
        pri+=1 if @battlers[i].hasWorkingAbility(:PRANKSTER) &&
                  @choices[i][2].pbIsStatus?
        pri+=1 if @battlers[i].hasWorkingAbility(:GALEWINGS) &&
                  isConst?(@choices[i][2].type,PBTypes,:FLYING)
        pri+=3 if @battlers[i].hasWorkingAbility(:TRIAGE) &&
                  @choices[i][2].isHealingMove? &&
                  !isConst?(@choices[i][2].id,PBMoves,:AQUARING) &&
                  !isConst?(@choices[i][2].id,PBMoves,:GRASSYTERRAIN) &&
                  !isConst?(@choices[i][2].id,PBMoves,:INGRAIN) &&
                  !isConst?(@choices[i][2].id,PBMoves,:LEECHSEED) &&
                  !isConst?(@choices[i][2].id,PBMoves,:PAINSPLIT) &&
                  !isConst?(@choices[i][2].id,PBMoves,:PRESENT) &&
                  !isConst?(@choices[i][2].id,PBMoves,:POLLENPUFF)

        lagging[i]=true if (@battlers[i].hasWorkingAbility(:MYCELIUMMIGHT) && @choices[i][2].pbIsStatus?)
        if @choices[i][2].zmove && (@choices[i][2].pbIsPhysical?(@choices[i][2].type) || @choices[i][2].pbIsSpecial?(@choices[i][2].type))
          pri=0
        end
      end

      priorities[i]=pri
      if i==0
        minpri=pri
        maxpri=pri
      else
        minpri=pri if minpri>pri
        maxpri=pri if maxpri<pri
      end
    end
    # Find and order all moves with the same priority
    curpri=maxpri
    loop do
      temp.clear
      for j in 0...4
        temp.push(j) if priorities[j]==curpri
      end
      # Sort by speed
      if temp.length==1
        @priority[@priority.length]=@battlers[temp[0]]
      elsif temp.length>1
        n=temp.length
        for m in 0...temp.length-1
          for i in 1...temp.length
            # For each pair of battlers, rank the second compared to the first
            # -1 means rank higher, 0 means rank equal, 1 means rank lower
            cmp=0
            if quickclaw[temp[i]] || quickdraw[temp[i]]
              cmp=-1
              if quickclaw[temp[i-1]] || quickdraw[temp[i-1]]
                if speeds[temp[i]]==speeds[temp[i-1]]
                  cmp=0
                else
                  cmp=(speeds[temp[i]]>speeds[temp[i-1]]) ? -1 : 1
                end
              end
            elsif quickclaw[temp[i-1]] || quickdraw[temp[i-1]]
              cmp=1
            elsif lagging[temp[i]]
              cmp=1
              if lagging[temp[i-1]]
                if speeds[temp[i]]==speeds[temp[i-1]]
                  cmp=0
                else
                  cmp=(speeds[temp[i]]>speeds[temp[i-1]]) ? 1 : -1
                end
              end
            elsif lagging[temp[i-1]]
              cmp=-1
            elsif speeds[temp[i]]!=speeds[temp[i-1]]
              if @field.effects[PBEffects::TrickRoom]>0
                cmp=(speeds[temp[i]]>speeds[temp[i-1]]) ? 1 : -1
              else
                cmp=(speeds[temp[i]]>speeds[temp[i-1]]) ? -1 : 1
              end
            end
            if cmp<0 || # Swap the pair according to the second battler's rank
               (cmp==0 && pbRandom(2)==0)
              swaptmp=temp[i]
              temp[i]=temp[i-1]
              temp[i-1]=swaptmp
            end
          end
        end
        # Battlers in this bracket are properly sorted, so add them to @priority
        for i in temp
          @priority[@priority.length]=@battlers[i]
        end
      end
      curpri-=1
      break if curpri<minpri
    end
    # Write the priority order to the debug log
    if log
      d="[Priority] "; comma=false
      for i in 0...4
        if @priority[i] && !@priority[i].isFainted?
          d+=", " if comma
          d+="#{@priority[i].pbThis(comma)} (#{@priority[i].index})"; comma=true
        end
      end
      PBDebug.log(d)
    end
    @usepriority=true
    return @priority
  end

################################################################################
# Switching Pokémon.
################################################################################
  def pbCanSwitchLax?(idxPokemon,pkmnidxTo,showMessages)
    if pkmnidxTo>=0
      party=pbParty(idxPokemon)
      if pkmnidxTo>=party.length
        return false
      end
      if !party[pkmnidxTo]
        return false
      end
      if party[pkmnidxTo].isEgg?
        pbDisplayPaused(_INTL("¡Un Huevo no puede pelear!")) if showMessages
        return false
      end
      if !pbIsOwner?(idxPokemon,pkmnidxTo)
        owner=pbPartyGetOwner(idxPokemon,pkmnidxTo)
        pbDisplayPaused(_INTL("¡No puedes cambiar un Pokémon de {1} por uno de los tuyos!",owner.name)) if showMessages
        return false
      end
      if party[pkmnidxTo].hp<=0
        pbDisplayPaused(_INTL("¡{1} no tiene más energías para pelear!",party[pkmnidxTo].name)) if showMessages
        return false
      end
      if @battlers[idxPokemon].pokemonIndex==pkmnidxTo ||
         @battlers[idxPokemon].pbPartner.pokemonIndex==pkmnidxTo
        pbDisplayPaused(_INTL("¡{1} ya está en el campo de batalla!",party[pkmnidxTo].name)) if showMessages
        return false
      end
    end
    return true
  end

  def pbCanSwitch?(idxPokemon,pkmnidxTo,showMessages,ignoremeanlook=false)
    thispkmn=@battlers[idxPokemon]
    # Multi-Turn Attacks/Mean Look   --   Ataques multiturnos / Mal de Ojo
    if !pbCanSwitchLax?(idxPokemon,pkmnidxTo,showMessages)
      return false
    end
    isOpposing=pbIsOpposing?(idxPokemon)
    party=pbParty(idxPokemon)
    for i in 0...4
      next if isOpposing!=pbIsOpposing?(i)
      if choices[i][0]==2 && choices[i][1]==pkmnidxTo
        pbDisplayPaused(_INTL("{1} ya está seleccionado.",party[pkmnidxTo].name)) if showMessages
        return false
      end
    end
    if thispkmn.hasWorkingItem(:SHEDSHELL)
      return true
    end
    if USENEWBATTLEMECHANICS && thispkmn.pbHasType?(:GHOST)
      return true
    end
    if thispkmn.effects[PBEffects::MultiTurn]>0 ||
       (!ignoremeanlook && thispkmn.effects[PBEffects::MeanLook]>=0)
      pbDisplayPaused(_INTL("¡{1} no puede ser cambiado!",thispkmn.pbThis)) if showMessages
      return false
    end
    if @field.effects[PBEffects::FairyLock]>0
      pbDisplayPaused(_INTL("¡{1} no puede ser cambiado!",thispkmn.pbThis)) if showMessages
      return false
    end
    if thispkmn.effects[PBEffects::Ingrain]
      pbDisplayPaused(_INTL("¡{1} no puede ser cambiado!",thispkmn.pbThis)) if showMessages
      return false
    end
    if thispkmn.effects[PBEffects::NoRetreat]
      pbDisplayPaused(_INTL("¡{1} no puede ser cambiado!",thispkmn.pbThis)) if showMessages
      return false
    end
    # Commander
    if thispkmn.effects[PBEffects::Commander] > 0 || thispkmn.pbPartner.effects[PBEffects::Commander] > 0
      pbDisplayPaused(_INTL("¡{1} no puede ser cambiado!",thispkmn.pbThis)) if showMessages
      return false
    end
    if thispkmn.effects[PBEffects::Octolock]
      for i in battlers
        if i.pokemonIndex==thispkmn.effects[PBEffects::OctolockUser] && !i.isFainted?
          pbDisplayPaused(_INTL("¡{1} no puede ser cambiado!",thispkmn.pbThis,movename)) if showMessages
          return false
        end
      end
    end
    if thispkmn.effects[PBEffects::JawLock]
      for i in battlers
        if i.pokemonIndex==thispkmn.effects[PBEffects::JawLockUser] && !i.isFainted?
          pbDisplayPaused(_INTL("¡{1} no puede ser cambiado!",thispkmn.pbThis)) if showMessages
          return false
        end
      end
    end
    opp1=thispkmn.pbOpposing1
    opp2=thispkmn.pbOpposing2
    opp=nil
    if thispkmn.pbHasType?(:STEEL)
      opp=opp1 if opp1.hasWorkingAbility(:MAGNETPULL)
      opp=opp2 if opp2.hasWorkingAbility(:MAGNETPULL)
    end
    if !thispkmn.isAirborne?
      opp=opp1 if opp1.hasWorkingAbility(:ARENATRAP)
      opp=opp2 if opp2.hasWorkingAbility(:ARENATRAP)
    end
    if !thispkmn.hasWorkingAbility(:SHADOWTAG)
      opp=opp1 if opp1.hasWorkingAbility(:SHADOWTAG)
      opp=opp2 if opp2.hasWorkingAbility(:SHADOWTAG)
    end
    if opp
      abilityname=PBAbilities.getName(opp.ability)
      pbDisplayPaused(_INTL("¡La habilidad {2} de {1} impide el cambio!",opp.pbThis,abilityname)) if showMessages
      return false
    end
    return true
  end

  def pbRegisterSwitch(idxPokemon,idxOther)
    return false if !pbCanSwitch?(idxPokemon,idxOther,false)
    @choices[idxPokemon][0]=2          # "Cambiar Pokémon"
    @choices[idxPokemon][1]=idxOther   # Índice del Pokémon con el que se hará el cambio
    @choices[idxPokemon][2]=nil
    side=(pbIsOpposing?(idxPokemon)) ? 1 : 0
    owner=pbGetOwnerIndex(idxPokemon)
    if @megaEvolution[side][owner]==idxPokemon
      @megaEvolution[side][owner]=-1
    end
    if @ultraBurst[side][owner]==idxPokemon
      @ultraBurst[side][owner]=-1
    end
    if @zMove[side][owner]==idxPokemon
      @zMove[side][owner]=-1
    end
    if @teraCristal[side][owner]==idxPokemon
      @teraCristal[side][owner]=-1
    end
    return true
  end

  def pbCanChooseNonActive?(index)
    party=pbParty(index)
    for i in 0...party.length
      return true if pbCanSwitchLax?(index,i,false)
    end
    return false
  end

  def pbSwitch(favorDraws=false)
    if !favorDraws
      return if @decision>0
    else
      return if @decision==5
    end
    pbJudge()
    return if @decision>0
    firstbattlerhp=@battlers[0].hp
    switched=[]
    for index in 0...4
      next if !@doublebattle && pbIsDoubleBattler?(index)
      next if @battlers[index] && !@battlers[index].isFainted?
      next if !pbCanChooseNonActive?(index)
      if !pbOwnedByPlayer?(index)
        if !pbIsOpposing?(index) || (@opponent && pbIsOpposing?(index))
          newenemy=pbSwitchInBetween(index,false,false)
          newenemyname=newenemy
          if newenemy>=0 && isConst?(pbParty(index)[newenemy].ability,PBAbilities,:ILLUSION)
            newenemyname=pbGetLastPokeInTeam(index)
          end
          @scene.partyAnimationRestart(index==1 && @doublebattle) if index != 2
          opponent=pbGetOwner(index)
          if !@doublebattle && firstbattlerhp>0 && @shiftStyle && @opponent &&
              @internalbattle && pbCanChooseNonActive?(0) && pbIsOpposing?(index) &&
              @battlers[0].effects[PBEffects::Outrage]==0
            pbDisplayPaused(_INTL("{1} está por enviar a {2}.",opponent.fullname,pbParty(index)[newenemyname].name))
            if pbDisplayConfirm(_INTL("{1}, ¿quieres cambiar de Pokémon?",self.pbPlayer.name))
              newpoke=pbSwitchPlayer(0,true,true)
              if newpoke>=0
                newpokename=newpoke
                if isConst?(@party1[newpoke].ability,PBAbilities,:ILLUSION)
                  newpokename=pbGetLastPokeInTeam(0)
                end
                pbDisplayBrief(_INTL("¡{1}, es suficiente! ¡Regresa!",@battlers[0].name))
                pbRecallAndReplace(0,newpoke,newpokename)
                switched.push(0)
              end
            end
          else
            # You can change the time delay for double/Set Option here
            timedelay=64 # Set Option
            timedelay=96 if @doublebattle
            for i in 0...timedelay
              @scene.pbGraphicsUpdate
            end
          end
          @scene.partyAnimationFade if index!=2
          pbRecallAndReplace(index,newenemy,newenemyname,false,false)
          switched.push(index)
        end
      elsif @opponent
        newpoke=pbSwitchInBetween(index,true,false)
        newpokename=newpoke
        if isConst?(@party1[newpoke].ability,PBAbilities,:ILLUSION)
          newpokename=pbGetLastPokeInTeam(index)
        end
        pbRecallAndReplace(index,newpoke,newpokename)
        switched.push(index)
      else
        switch=false
        if !pbDisplayConfirm(_INTL("¿Quieres cambiar de Pokémon?"))
          switch=(pbRun(index,true)<=0)
        else
          switch=true
        end
        if switch
          newpoke=pbSwitchInBetween(index,true,false)
          newpokename=newpoke
          if isConst?(@party1[newpoke].ability,PBAbilities,:ILLUSION)
            newpokename=pbGetLastPokeInTeam(index)
          end
          pbRecallAndReplace(index,newpoke,newpokename)
          switched.push(index)
        end
      end
    end
    if switched.length>0
      priority=pbPriority
      for i in priority
        i.pbAbilitiesOnSwitchIn(true) if switched.include?(i.index)
      end
    end
  end

  def pbSendOut(index,pokemon)
    pbSetSeen(pokemon)
    @peer.pbOnEnteringBattle(self,pokemon)
    if pbIsOpposing?(index)
      @scene.pbTrainerSendOut(index,pokemon)
    else
      @scene.pbSendOut(index,pokemon)
    end
    @scene.pbResetMoveIndex(index)
  end

  def pbReplace(index,newpoke,batonpass=false)
    party=pbParty(index)
    oldpoke=@battlers[index].pokemonIndex
    # Initialise the new Pokémon
    @battlers[index].pbInitialize(party[newpoke],newpoke,batonpass)
    # Reorder the party for this battle
    partyorder=(!pbIsOpposing?(index)) ? @party1order : @party2order
    bpo=-1; bpn=-1
    for i in 0...partyorder.length
      bpo=i if partyorder[i]==oldpoke
      bpn=i if partyorder[i]==newpoke
    end
    p=partyorder[bpo]; partyorder[bpo]=partyorder[bpn]; partyorder[bpn]=p
    # Send out the new Pokémon
    pbSendOut(index,party[newpoke])
    pbSetSeen(party[newpoke])
  end

  def pbRecallAndReplace(index,newpoke,newpokename=-1,batonpass=false,moldbreaker=false)
    @battlers[index].pbResetForm
    if !@battlers[index].isFainted?
      @scene.pbRecall(index)
    end
    pbMessagesOnReplace(index,newpoke,newpokename)
    pbReplace(index,newpoke,batonpass)
    return pbOnActiveOne(@battlers[index],false,moldbreaker)
  end

  def pbMessagesOnReplace(index,newpoke,newpokename=-1)
    newpokename=newpoke if newpokename<0
    party=pbParty(index)
    if pbOwnedByPlayer?(index)
#     if !party[newpoke]
#       p [index,newpoke,party[newpoke],pbAllFainted?(party)]
#       PBDebug.log([index,newpoke,party[newpoke],"pbMOR"].inspect)
#       for i in 0...party.length
#         PBDebug.log([i,party[i].hp].inspect)
#       end
#       raise BattleAbortedException.new
#     end
      opposing=@battlers[index].pbOppositeOpposing
      if opposing.isFainted? || opposing.hp==opposing.totalhp
        pbDisplayBrief(_INTL("¡Adelante! ¡{1}!",party[newpokename].name))
      elsif opposing.hp>=(opposing.totalhp/2)
        pbDisplayBrief(_INTL("¡Tú puedes! ¡{1}!",party[newpokename].name))
      elsif opposing.hp>=(opposing.totalhp/4)
        pbDisplayBrief(_INTL("¡Ya lo tienes, {1}!",party[newpokename].name))
      else
        pbDisplayBrief(_INTL("¡Tu rival está débil!<br>¡Termínalo, {1}!",party[newpokename].name))
      end
      PBDebug.log("[Sacar Pokémon] El jugador envió a #{party[newpokename].name} en posición #{index}")
    else
#     if !party[newpoke]
#       p [index,newpoke,party[newpoke],pbAllFainted?(party)]
#       PBDebug.log([index,newpoke,party[newpoke],"pbMOR"].inspect)
#       for i in 0...party.length
#         PBDebug.log([i,party[i].hp].inspect)
#       end
#       raise BattleAbortedException.new
#     end
      owner=pbGetOwner(index)
      pbDisplayBrief(_INTL("¡{1} envió<br>a {2}!",owner.fullname,party[newpokename].name))
      PBDebug.log("[Sacar Pokémon] Rival envió a #{party[newpokename].name} en posición #{index}")
    end
  end

  def pbSwitchInBetween(index,lax,cancancel)
    if !pbOwnedByPlayer?(index)
      return @scene.pbChooseNewEnemy(index,pbParty(index))
    else
      return pbSwitchPlayer(index,lax,cancancel)
    end
  end

  def pbSwitchPlayer(index,lax,cancancel)
    if @debug
      return @scene.pbChooseNewEnemy(index,pbParty(index))
    else
      return @scene.pbSwitch(index,lax,cancancel)
    end
  end

################################################################################
# Revival Blessing / Plegaria Vital
################################################################################
  def pbCanReviveLax?(idxPokemon,pkmnidxTo,showMessages)
    if pkmnidxTo>=0
      party=pbParty(idxPokemon)
      if pkmnidxTo>=party.length
        return false
      end
      if !party[pkmnidxTo]
        return false
      end
      if !pbIsOwner?(idxPokemon,pkmnidxTo)
        owner=pbPartyGetOwner(idxPokemon,pkmnidxTo)
        pbDisplayPaused(_INTL("¡No puedes revivir a un Pokémon de {1}!",owner.name)) if showMessages
        return false
      end
      if party[pkmnidxTo].hp>0 || party[pkmnidxTo].isEgg?
        pbDisplayPaused(_INTL("No tendrá ningún efecto.",party[pkmnidxTo].name)) if showMessages
        return false
      end
      if @battlers[idxPokemon].pokemonIndex==pkmnidxTo ||
         @battlers[idxPokemon].pbPartner.pokemonIndex==pkmnidxTo
        pbDisplayPaused(_INTL("¡{1} ya está combatiendo!",party[pkmnidxTo].name)) if showMessages
        return false
      end
    end
    return true
  end

  def pbCanRevive?(idxPokemon,pkmnidxTo,showMessages,ignoremeanlook=false)
    return true
  end

  def pbRevival(index,newpoke)
    party=pbParty(index)
    party[newpoke].hp=(party[newpoke].totalhp/2).floor
    party[newpoke].healStatus
  end

  def pbMessagesOnRevival(index,newpoke,newpokename=-1)
    newpokename=newpoke# if newpokename<0
    party=pbParty(index)
    pbDisplayBrief(_INTL("¡{1} se ha repuesto y está listo para combatir!",party[newpokename].name))
    PBDebug.log("[Sacar Pokémon] El jugador revivió a #{party[newpokename].name} en posición #{index}")
  end

  def pbRevivalBlessing(index,lax,cancancel)
    return @scene.pbRevivalScene(index,lax,cancancel)
  end

################################################################################
# Using an item. / Usando un objeto
################################################################################
# Uses an item on a Pokémon in the player's party.
  def pbUseItemOnPokemon(item,pkmnIndex,userPkmn,scene)
    pokemon=@party1[pkmnIndex]
    battler=nil
    name=pbGetOwner(userPkmn.index).fullname
    name=pbGetOwner(userPkmn.index).name if pbBelongsToPlayer?(userPkmn.index)
    pbDisplayBrief(_INTL("{1} ha usado<br>{2}.",name,PBItems.getName(item)))
    PBDebug.log("[Objeto usado] El jugador ha usado #{PBItems.getName(item)} en #{pokemon.name}")
    ret=false
    if pokemon.isEgg?
      pbDisplay(_INTL("¡Pero no tuvo efecto!"))
    else
      for i in 0...4
        if !pbIsOpposing?(i) && @battlers[i].pokemonIndex==pkmnIndex
          battler=@battlers[i]
          pbCommonAnimation("UseItem",@battlers[i],nil) rescue nil
        end
      end
      ret=ItemHandlers.triggerBattleUseOnPokemon(item,pokemon,battler,scene)
    end
    if !ret && pbBelongsToPlayer?(userPkmn.index)
      if $PokemonBag.pbCanStore?(item)
        $PokemonBag.pbStoreItem(item)
      else
        p _INTL("De alguna forma no se pudo devolver el objeto sin usar a la mochila.")
      end
    end
    return ret
  end

# Uses an item on an active Pokémon.
  def pbUseItemOnBattler(item,index,userPkmn,scene)
    PBDebug.log("[Objeto usado] El jugador ha usado #{PBItems.getName(item)} en #{@battlers[index].pbThis(true)}")
    pbCommonAnimation("UseItem",@battlers[index],nil) rescue nil
    ret=ItemHandlers.triggerBattleUseOnBattler(item,@battlers[index],scene)
    if !ret && pbBelongsToPlayer?(userPkmn.index)
      if $PokemonBag.pbCanStore?(item)
        $PokemonBag.pbStoreItem(item)
      else
        p _INTL("De alguna forma no se pudo devolver el objeto sin usar a la mochila.")
      end
    end
    return ret
  end

  def pbRegisterItem(idxPokemon,idxItem,idxTarget=nil)
    if idxTarget!=nil && idxTarget>=0
      for i in 0...4
        if !@battlers[i].pbIsOpposing?(idxPokemon) &&
           @battlers[i].pokemonIndex==idxTarget &&
           @battlers[i].effects[PBEffects::Embargo]>0
          pbDisplay(_INTL("¡El efecto de Embargo impide usar el objeto en {1}!",@battlers[i].pbThis(true)))
          if pbBelongsToPlayer?(@battlers[i].index)
            if $PokemonBag.pbCanStore?(idxItem)
              $PokemonBag.pbStoreItem(idxItem)
            else
              p _INTL("Por alguna razón, no se pudo devolver el objeto a la mochila.")
            end
          end
          return false
        end
      end
    end
    if ItemHandlers.hasUseInBattle(idxItem)
      if idxPokemon==0              # Primer Pokémon del Jugador
        if ItemHandlers.triggerBattleUseOnBattler(idxItem,@battlers[idxPokemon],self)
          # Using Poké Balls or Poké Doll only
          ItemHandlers.triggerUseInBattle(idxItem,@battlers[idxPokemon],self)
          @battlers[idxPokemon+2].effects[PBEffects::SkipTurn]=true if @doublebattle
        else
          if $PokemonBag.pbCanStore?(idxItem)
            $PokemonBag.pbStoreItem(idxItem)
          else
            p _INTL("De alguna forma no se pudo devolver el objeto sin usar a la mochila.")
          end
          return false
        end
      else
        pbDisplay(_INTL("¡Es imposible apuntar sin concentrarse!")) if ItemHandlers.triggerBattleUseOnBattler(idxItem,@battlers[idxPokemon],self)
        return false
      end
    end
    @choices[idxPokemon][0]=3         # "Usar un objeto"
    @choices[idxPokemon][1]=idxItem   # ID del objeto que se usará
    @choices[idxPokemon][2]=idxTarget # Índice del Pokémon sobre el que se usará
    side=(pbIsOpposing?(idxPokemon)) ? 1 : 0
    owner=pbGetOwnerIndex(idxPokemon)
    @megaEvolution[side][owner]=-1 if @megaEvolution[side][owner]==idxPokemon
    @ultraBurst[side][owner]=-1 if @ultraBurst[side][owner]==idxPokemon
    @zMove[side][owner]=-1 if @zMove[side][owner]==idxPokemon
    @teraCristal[side][owner]=-1 if @teraCristal[side][owner]==idxPokemon
    return true
  end
  # BES-T Editado para mejor manejo y poder añadir nuevos objetos rápidamente.
  def pbEnemyUseItem(item, battler)
    return 0 if !@internalbattle
    items = pbGetOwnerItems(battler.index)
    return if !items
    opponent = pbGetOwner(battler.index)
  
    # Elimina el ítem usado del inventario
    if items.include?(item)
      items.delete_at(items.index(item))
    end
  
    itemname = PBItems.getName(item)
    pbDisplayBrief(_INTL("¡{1} ha usado<br>{2}!", opponent.fullname, itemname))
    PBDebug.log("[Objeto usado] El rival ha usado #{itemname} en #{battler.pbThis(true)}")
  
    heal_map = {
      :POTION       => 20,
      :SUPERPOTION  => (USENEWBATTLEMECHANICS ? 60 : 50),
      :HYPERPOTION  => (USENEWBATTLEMECHANICS ? 120 : 200),
      :MAXPOTION    => (pokemon.totalhp - pokemon.hp),
      :FRESHWATER   => (USENEWBATTLEMECHANICS ? 30 : 50),
      :SODAPOP      => (USENEWBATTLEMECHANICS ? 50 : 60),
      :LEMONADE     => (USENEWBATTLEMECHANICS ? 70 : 80),
      :MOOMOOMILK   => 100,
      :ORANBERRY    => 10,
      :SITRUSBERRY  => (pokemon.totalhp / 4).floor,

      :ENERGYPOWDER  => (USENEWBATTLEMECHANICS) ? 60 : 50,
      :ENERGYROOT    => (USENEWBATTLEMECHANICS) ? 120 : 200
    }

    pbCommonAnimation("UseItem",battler,nil) rescue nil
    if healing_items.keys.any? { |key| isConst?(item, PBItems, key) }
      heal_amount = healing_items.detect { |key, _| isConst?(item, PBItems, key) }[1]
      battler.pbRecoverHP(heal_amount, true)
      pbDisplay(_INTL("Los PS de {1} fueron restaurados.", battler.pbThis))
    elsif isConst?(item, PBItems, :FULLRESTORE)
      fullhp = (battler.hp == battler.totalhp)
      battler.pbRecoverHP(battler.totalhp - battler.hp, true)
      battler.status = 0
      battler.statusCount = 0
      battler.effects[PBEffects::Confusion] = 0
      if fullhp
        pbDisplay(_INTL("{1} ha recuperado su salud.", battler.pbThis))
      else
        pbDisplay(_INTL("Los PS de {1} fueron restaurados.", battler.pbThis))
      end
    elsif isConst?(item, PBItems, :FULLHEAL) || isConst?(item, PBItems, :HEALPOWDER)
      battler.status = 0
      battler.statusCount = 0
      battler.effects[PBEffects::Confusion] = 0
      pbDisplay(_INTL("{1} ha recuperado su salud.", battler.pbThis))
    else
      # Items que aumentan stats
      stat_items = {
        :XATTACK    => PBStats::ATTACK,
        :XDEFEND    => PBStats::DEFENSE,
        :XSPEED     => PBStats::SPEED,
        :XSPECIAL   => PBStats::SPATK,
        :XSPDEF     => PBStats::SPDEF,
        :XACCURACY  => PBStats::ACCURACY
      }
      stat_item = stat_items.detect { |key, _| isConst?(item, PBItems, key) }
      if stat_item && battler.pbCanIncreaseStatStage?(stat_item[1], battler)
        battler.pbIncreaseStat(stat_item[1], (USENEWBATTLEMECHANICS) ? 2 : 1, battler, true)
      end
    end
  end
  

################################################################################
# Fleeing from battle. / Huyendo de la batalla
################################################################################
  def pbCanRun?(idxPokemon)
    return false if @opponent
    return false if @cantescape && !pbIsOpposing?(idxPokemon)
    thispkmn=@battlers[idxPokemon]
    return true if thispkmn.pbHasType?(:GHOST) && USENEWBATTLEMECHANICS
    return true if thispkmn.hasWorkingItem(:SMOKEBALL)
    return true if thispkmn.hasWorkingAbility(:RUNAWAY)
    return false if thispkmn.effects[PBEffects::NoRetreat]
    return false if thispkmn.effects[PBEffects::Octolock] && thispkmn.effects[PBEffects::OctolockUser]>=0
    if thispkmn.effects[PBEffects::JawLock]
      for i in battlers
        if i.pokemonIndex==thispkmn.effects[PBEffects::JawLockUser] && !i.isFainted?
          return false
        end
      end
    end
    return pbCanSwitch?(idxPokemon,-1,false)
  end

  def pbRun(idxPokemon,duringBattle=false)
    thispkmn=@battlers[idxPokemon]
    if pbIsOpposing?(idxPokemon)
      return 0 if @opponent
      @choices[i][0]=5 # run
      @choices[i][1]=0
      @choices[i][2]=nil
      return -1
    end
    if @opponent
      if $DEBUG && Input.press?(Input::CTRL)
        if pbDisplayConfirm(_INTL("¿Tratar esta batalla como una victoria?"))
          @decision=1
          return 1
        elsif pbDisplayConfirm(_INTL("¿Tratar esta batalla como una derrota?"))
          @decision=2
          return 1
        end
      elsif @internalbattle
        pbDisplayPaused(_INTL("¡No se puede escapar de una batalla contra un entrenador!"))
      elsif pbDisplayConfirm(_INTL("¿Quieres perder el duelo y salir ahora?"))
        pbDisplay(_INTL("¡{1} perdió el duelo!",self.pbPlayer.name))
        @decision=3
        return 1
      end
      return 0
    end
    if $DEBUG && Input.press?(Input::CTRL)
      pbSEPlay("Battle flee")
      pbDisplayPaused(_INTL("¡Escapaste sin problemas!"))
      @decision=3
      return 1
    end
    if @cantescape
      pbDisplayPaused(_INTL("¡No conseguiste escapar!"))
      return 0
    end
    if thispkmn.effects[PBEffects::NoRetreat]
      pbDisplayPaused(_INTL("¡No conseguiste escapar!"))
      return 0
    end
    if thispkmn.pbHasType?(:GHOST) && USENEWBATTLEMECHANICS
      pbSEPlay("Battle flee")
      pbDisplayPaused(_INTL("¡Escapaste sin problemas!"))
      @decision=3
      return 1
    end
    if thispkmn.hasWorkingAbility(:RUNAWAY)
      pbSEPlay("Battle flee")
      if duringBattle
        pbDisplayPaused(_INTL("¡Escapaste sin problemas!"))
      else
        pbDisplayPaused(_INTL("¡{1} ha escapado usando Fuga!",thispkmn.pbThis))
      end
      @decision=3
      return 1
    end
    if thispkmn.hasWorkingItem(:SMOKEBALL)
      pbSEPlay("Battle flee")
      if duringBattle
        pbDisplayPaused(_INTL("¡Escapaste sin problemas!"))
      else
        pbDisplayPaused(_INTL("¡{1} ha escapado usando la {2}!",thispkmn.pbThis,PBItems.getName(thispkmn.item)))
      end
      @decision=3
      return 1
    end
    if thispkmn.hasWorkingAbility(:WIMPOUT) && thispkmn.hp<=(thispkmn.totalhp/2).floor && (thispkmn.hp+thispkmn.lastHPLost)>(thispkmn.totalhp/2) && !thispkmn.damagestate.substitute
      pbSEPlay("Battle flee")
      if duringBattle
        pbDisplayPaused(_INTL("{Se activó Huída de {1}!",thispkmn.pbThis))
        pbDisplayPaused(_INTL("¡Escapaste sin problemas!"))
      else
        pbDisplayPaused(_INTL("¡{1} escapó gracias a Huída!",thispkmn.pbThis))
      end
      @decision=3
      return 1
    end
    if thispkmn.hasWorkingAbility(:EMERGENCYEXIT) && thispkmn.hp<=(thispkmn.totalhp/2).floor && (thispkmn.hp+thispkmn.lastHPLost)>(thispkmn.totalhp/2) && !thispkmn.damagestate.substitute
      pbSEPlay("Battle flee")
      if duringBattle
        pbDisplayPaused(_INTL("{Se activó Retirada de {1}!",thispkmn.pbThis))
        pbDisplayPaused(_INTL("¡Escapaste sin problemas!"))
      else
        pbDisplayPaused(_INTL("¡{1} escapó gracias a Retirada!",thispkmn.pbThis))
      end
      @decision=3
      return 1
    end
    if !duringBattle && !pbCanSwitch?(idxPokemon,-1,false)
      pbDisplayPaused(_INTL("¡No conseguiste escapar!"))
      return 0
    end
    # Note: not pbSpeed, because using unmodified Speed
    speedPlayer=@battlers[idxPokemon].speed
    opposing=@battlers[idxPokemon].pbOppositeOpposing
    opposing=opposing.pbPartner if opposing.isFainted?
    if !opposing.isFainted?
      speedEnemy=opposing.speed
      if speedPlayer>speedEnemy
        rate=256
      else
        speedEnemy=1 if speedEnemy<=0
        rate=speedPlayer*128/speedEnemy
        rate+=@runCommand*30
        rate&=0xFF
      end
    else
      rate=256
    end
    ret=1
    if pbAIRandom(256)<rate
      pbSEPlay("Battle flee")
      pbDisplayPaused(_INTL("¡Escapaste sin problemas!"))
      @decision=3
    else
      pbDisplayPaused(_INTL("¡No conseguiste escapar!"))
      ret=-1
    end
    @runCommand+=1 if !duringBattle
    return ret
  end

################################################################################
# Mega Evolve battler. / Mega Evolución
################################################################################
  def pbCanMegaEvolve?(index)

    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)

    return false if @battlers[index].isTera?
    return false if pbIsZCrystal?(@battlers[index].item) || pbCanZMove?(index)
    return false if $game_switches[NO_MEGA_EVOLUTION]
    return false if @rules["noMega"]
    return false if !@battlers[index].hasMega?
    #return false if pbIsOpposing?(index) && !@opponent
    return true if $DEBUG && Input.press?(Input::CTRL)
    return false if !pbHasMegaRing(index)
    return false if @megaEvolution[side][owner]!=-1
    return false if @battlers[index].effects[PBEffects::SkyDrop]
    return true
  end

  def pbRegisterMegaEvolution(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @megaEvolution[side][owner]=index
  end

  def pbMegaEvolve(index)
    return if !@battlers[index] || !@battlers[index].pokemon
    return if !(@battlers[index].hasMega? rescue false)
    return if (@battlers[index].isMega? rescue true)
    if pbGetOwner(index)==nil
      case (@battlers[index].pokemon.megaMessage rescue 0)
      when 1 # Rayquaza
        pbDisplay(_INTL("¡El ruego vehemente alcanza a {1}!",@battlers[index].pbThis))
      else
        pbDisplay(_INTL("¡La {2} de {1} está reaccionando su poder interior!",
           @battlers[index].pbThis,PBItems.getName(@battlers[index].item)))
      end
    else
      ownername=pbGetOwner(index).fullname
      ownername=pbGetOwner(index).name if pbBelongsToPlayer?(index)
      case (@battlers[index].pokemon.megaMessage rescue 0)
      when 1                                                           # Rayquaza
        pbDisplay(_INTL("¡El ruego vehemente de {1} alcanza a {2}!",ownername,@battlers[index].pbThis))
      else
        pbDisplay(_INTL("¡La {2} de {1} está reaccionando al {4} de {3}!",
           @battlers[index].pbThis,PBItems.getName(@battlers[index].item),
           ownername,pbGetMegaRingName(index)))
      end
    end
    pbCommonAnimation("MegaEvolution",@battlers[index],nil)
    @battlers[index].pokemon.makeMega
    @battlers[index].form=@battlers[index].pokemon.form
    @battlers[index].pbUpdate(true)
    @scene.pbChangePokemon(@battlers[index],@battlers[index].pokemon)
    pbCommonAnimation("MegaEvolution2",@battlers[index],nil)
    meganame=(@battlers[index].pokemon.megaName rescue nil)
    if !meganame || meganame==""
      meganame=_INTL("Mega {1}",PBSpecies.getName(@battlers[index].pokemon.species))
    end
    pbDisplay(_INTL("¡{1} ha Mega Evolucionado en {2}!",@battlers[index].pbThis,meganame))
    PBDebug.log("[Mega Evolución] #{@battlers[index].pbThis} ha Mega Evolucionado")
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @megaEvolution[side][owner]=-2
  end

################################################################################
# Teracristalización
################################################################################
  def pbCanTeraCristal?(index)
    return false if @battlers[index].hasMega? || @battlers[index].isMega?
    return false if @battlers[index].isPrimal?
    return false if @battlers[index].hasUltra? || @battlers[index].isUltra?
    return false if pbIsZCrystal?(@battlers[index].item) || pbCanZMove?(index)
    return false if $game_switches[NO_TERA_CRISTAL]
    return false if @rules["noTera"]
    return false if pbIsOpposing?(index) && !@opponent
    return true if $DEBUG && Input.press?(Input::CTRL)
    return false if !pbHasTeraOrb(index)
    return false if !@battlers[index].pokemon.teratype

    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    return false if @teraCristal[side][owner]!=-1
    return false if @battlers[index].effects[PBEffects::SkyDrop]
    return true
  end

  def pbRegisterTeraCristal(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @teraCristal[side][owner]=index
  end

  def pbTeraCristal(index)
    teratype=@battlers[index].pokemon.teratype
    return if !@battlers[index] || !@battlers[index].pokemon
    return if (@battlers[index].isTera? rescue true)
    fpShowText("tera") if pbIsOpposing?(index) && defined?(MBD_Data)
    pbDisplay(_INTL("¡{1} se está rodeando de cristal!",@battlers[index].pbThis))
    pbCommonAnimation("MegaEvolution",@battlers[index],nil)
    @battlers[index].pokemon.original_types=[@battlers[index].type1,@battlers[index].type2]
    @battlers[index].pokemon.makeTera
    @battlers[index].pbUpdate(true)
    @scene.pbChangePokemon(@battlers[index],@battlers[index].pokemon)
    pbCommonAnimation("MegaEvolution2",@battlers[index],nil)
    typename=PBTypes.getName(teratype)
    pbDisplay(_INTL("¡{1} ha Teracristalizado al tipo {2}!",@battlers[index].pbThis,typename))
    fpShowText("tera(player)") if pbBelongsToPlayer?(index) && defined?(MBD_Data)
    PBDebug.log("[Teracristalización] #{@battlers[index].pbThis} ha Teracristalizado (#{typename})")
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @teraCristal[side][owner]=-2
    $PokemonGlobal.teraorb[0]-=1 if $PokemonGlobal.teraorb
  end

################################################################################
# Primal Revert battler.
################################################################################
  def pbPrimalReversion(index)
    return if !@battlers[index] || !@battlers[index].pokemon
    return if !(@battlers[index].hasPrimal? rescue false)
    return if (@battlers[index].isPrimal? rescue true)
    pbCommonAnimation("Primal#{PBSpecies.getName(@battlers[index].species)}",@battlers[index],nil)
    @battlers[index].pokemon.makePrimal
    @battlers[index].form=@battlers[index].pokemon.form
    @battlers[index].pbUpdate(true)
    @scene.pbChangePokemon(@battlers[index],@battlers[index].pokemon)
    pbCommonAnimation("Primal#{PBSpecies.getName(@battlers[index].species)}2",@battlers[index],nil)
    pbDisplay(_INTL("¡{1} ha esperimentado una Regresión Primigenia y ha recobrado su apariencia primitiva!",@battlers[index].pbThis))
    PBDebug.log("[Regresión Primigenia] #{@battlers[index].pbThis} ha recobrado su apariencia primitiva")
  end

################################################################################
# Ultra Burst battler.
################################################################################
  def pbCanUltraBurst?(index)
    return false if @battlers[index].isTera?
    return false if $game_switches[NO_ULTRA_BURST]
    return false if @rules["noUltra"]
    return false if !@battlers[index].hasUltra?
    return false if pbIsOpposing?(index) && !@opponent
    return true if $DEBUG && Input.press?(Input::CTRL)
#    return false if !pbHasZRing?(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    return false if @ultraBurst[side][owner]!=-1
    return false if @battlers[index].effects[PBEffects::SkyDrop]
    return true
  end

  def pbRegisterUltraBurst(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @ultraBurst[side][owner]=index
  end

  def pbUltraBurst(index)
    return if !@battlers[index] || !@battlers[index].pokemon
    return if !(@battlers[index].hasUltra? rescue false)
    return if (@battlers[index].isUltra? rescue true)
    @necrozmaVar = [@battlers[index].pokemonIndex,@battlers[index].form] if pbBelongsToPlayer?(index)
    ownername=pbGetOwner(index).fullname
    ownername=pbGetOwner(index).name if pbBelongsToPlayer?(index)
    pbDisplay(_INTL("¡{1} emite una luz cegadora!",@battlers[index].pbThis))
    pbCommonAnimation("UltraBurst",@battlers[index],nil)
    @battlers[index].pokemon.makeUltra
    @battlers[index].form=@battlers[index].pokemon.form
    @battlers[index].pbUpdate(true)
    @scene.pbChangePokemon(@battlers[index],@battlers[index].pokemon)
    pbCommonAnimation("UltraBurst2",@battlers[index],nil)
    ultraname=(@battlers[index].pokemon.ultraName rescue nil)
    if !ultraname || ultraname==""
      ultraname=_INTL("Ultra {1}",PBSpecies.getName(@battlers[index].pokemon.species))
    end
    pbDisplay(_INTL("¡{1} ha adoptado una nueva forma gracias a la Ultraexplosión!",@battlers[index].pbThis))
    PBDebug.log("[Ultra Burst] #{@battlers[index].pbThis} became #{ultraname}")
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @ultraBurst[side][owner]=-2
  end

################################################################################
# Use Z-Move.
################################################################################
  def pbCanZMove?(index)
    return false if @battlers[index].isTera?
    return false if $game_switches[NO_Z_MOVE]
    return false if @rules["noZ"]
    return false if !@battlers[index].hasZMove?
    return false if !pbHasZRing(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    return false if @zMove[side][owner]!=-1
    return true
  end

  def pbRegisterZMove(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @zMove[side][owner]=index
  end

  def pbUseZMove(index,move,crystal)
    return if !@battlers[index] || !@battlers[index].pokemon
    return if !(@battlers[index].hasZMove? rescue false)
    ownername=pbGetOwner(index).fullname
    ownername=pbGetOwner(index).name if pbBelongsToPlayer?(index)
    pbDisplay(_INTL("¡{1} se envuelve en un halo de Poder Z!",@battlers[index].pbThis))
    pbCommonAnimation("ZPower",@battlers[index],nil)
    PokeBattle_ZMoves.new(self,@battlers[index],move,crystal)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @zMove[side][owner]=-2
  end

################################################################################
# Call battler.
################################################################################
  def pbCall(index)
    owner=pbGetOwner(index)
    pbDisplay(_INTL("¡{1} ha llamado a {2}!",owner.name,@battlers[index].name))
    pbDisplay(_INTL("¡{1}!",@battlers[index].name))
    PBDebug.log("[Llamado Pokémon] #{owner.name} ha llamado a #{@battlers[index].pbThis(true)}")
    if @battlers[index].isShadow?
      if @battlers[index].inHyperMode?
        @battlers[index].pokemon.hypermode=false
        @battlers[index].pokemon.adjustHeart(-300)
        pbDisplay(_INTL("¡{1} recobró el sentido tras la llamada de su Entrenador!",@battlers[index].pbThis))
      else
        pbDisplay(_INTL("¡Pero no pasó nada!"))
      end
    elsif @battlers[index].status!=PBStatuses::SLEEP &&
          @battlers[index].pbCanIncreaseStatStage?(PBStats::ACCURACY,@battlers[index])
      @battlers[index].pbIncreaseStat(PBStats::ACCURACY,1,@battlers[index],true)
    else
      pbDisplay(_INTL("¡Pero no pasó nada!"))
    end
  end

################################################################################
# Gaining Experience. / Ganando experiencia
################################################################################
  def pbGainEXP
    return if !@internalbattle
    return if @rules["noExp"]
    successbegin=true
    for i in 0...4 # Not ordered by priority
      if !@doublebattle && pbIsDoubleBattler?(i)
        @battlers[i].participants=[]
        next
      end
      if pbIsOpposing?(i) && @battlers[i].participants.length>0 &&
         (@battlers[i].isFainted? || @battlers[i].captured)
        haveexpall=(hasConst?(PBItems,:EXPALL) && $PokemonBag.pbQuantity(:EXPALL)>0) || EXPALLWITHOUTITEM
        # First count the number of participants
        partic=0
        expshare=0
        for j in @battlers[i].participants
          next if !@party1[j] || !pbIsOwner?(0,j)
          partic+=1 if @party1[j].hp>0 && !@party1[j].isEgg?
        end
        if !haveexpall
          for j in 0...@party1.length
            next if !@party1[j] || !pbIsOwner?(0,j)
            expshare+=1 if @party1[j].hp>0 && !@party1[j].isEgg? &&
                           (isConst?(@party1[j].item,PBItems,:EXPSHARE) ||
                           isConst?(@party1[j].itemInitial,PBItems,:EXPSHARE))
          end
        end
        # Now calculate EXP for the participants
        if partic>0 || expshare>0 || haveexpall
          if !@opponent && successbegin && pbAllFainted?(@party2)
            @scene.pbWildBattleSuccess
            successbegin=false
          end
          for j in 0...@party1.length
            next if !@party1[j] || !pbIsOwner?(0,j)
            next if @party1[j].hp<=0 || @party1[j].isEgg?
            haveexpshare=(isConst?(@party1[j].item,PBItems,:EXPSHARE) ||
                          isConst?(@party1[j].itemInitial,PBItems,:EXPSHARE))
            next if !haveexpshare && !@battlers[i].participants.include?(j)
            pbGainExpOne(j,@battlers[i],partic,expshare,haveexpall)
          end
          if haveexpall
            showmessage=true
            for j in 0...@party1.length
              next if !@party1[j] || !pbIsOwner?(0,j)
              next if @party1[j].hp<=0 || @party1[j].isEgg?
              next if isConst?(@party1[j].item,PBItems,:EXPSHARE) ||
                      isConst?(@party1[j].itemInitial,PBItems,:EXPSHARE)
              next if @battlers[i].participants.include?(j)
              pbDisplayPaused(_INTL("¡El resto del equipo también ha ganado Puntos de Experiencia gracias al {1}!",
                 PBItems.getName(getConst(PBItems,:EXPALL)))) if showmessage && !EXPALLWITHOUTITEM
              showmessage=false
              pbGainExpOne(j,@battlers[i],partic,expshare,haveexpall,false)
            end
          end
        end
        # Now clear the participants array
        @battlers[i].participants=[]
      end
    end
  end

  def pbGainExpOne(index,defeated,partic,expshare,haveexpall,showmessages=true)
    thispoke=@party1[index]
    # Original species, not current species
    level=defeated.level
    baseexp=defeated.pokemon.baseExp
    evyield=defeated.pokemon.evYield
    # Gain effort value points, using RS effort values
    totalev=0
    for k in 0...6
      totalev+=thispoke.ev[k]
    end
    for k in 0...6
      evgain=evyield[k]
      evgain*=2 if isConst?(thispoke.item,PBItems,:MACHOBRACE) ||
                   isConst?(thispoke.itemInitial,PBItems,:MACHOBRACE)
      case k
      when PBStats::HP
        evgain+=4 if isConst?(thispoke.item,PBItems,:POWERWEIGHT) ||
                     isConst?(thispoke.itemInitial,PBItems,:POWERWEIGHT)
      when PBStats::ATTACK
        evgain+=4 if isConst?(thispoke.item,PBItems,:POWERBRACER) ||
                     isConst?(thispoke.itemInitial,PBItems,:POWERBRACER)
      when PBStats::DEFENSE
        evgain+=4 if isConst?(thispoke.item,PBItems,:POWERBELT) ||
                     isConst?(thispoke.itemInitial,PBItems,:POWERBELT)
      when PBStats::SPATK
        evgain+=4 if isConst?(thispoke.item,PBItems,:POWERLENS) ||
                     isConst?(thispoke.itemInitial,PBItems,:POWERLENS)
      when PBStats::SPDEF
        evgain+=4 if isConst?(thispoke.item,PBItems,:POWERBAND) ||
                     isConst?(thispoke.itemInitial,PBItems,:POWERBAND)
      when PBStats::SPEED
        evgain+=4 if isConst?(thispoke.item,PBItems,:POWERANKLET) ||
                     isConst?(thispoke.itemInitial,PBItems,:POWERANKLET)
      end
      evgain*=2 if thispoke.pokerusStage>=1 # Infected or cured
      if evgain>0
        # Can't exceed overall limit
        evgain-=totalev+evgain-PokeBattle_Pokemon::EVLIMIT if totalev+evgain>PokeBattle_Pokemon::EVLIMIT
        # Can't exceed stat limit
        evgain-=thispoke.ev[k]+evgain-PokeBattle_Pokemon::EVSTATLIMIT if thispoke.ev[k]+evgain>PokeBattle_Pokemon::EVSTATLIMIT
        # Add EV gain
        thispoke.ev[k]+=evgain
        if thispoke.ev[k]>PokeBattle_Pokemon::EVSTATLIMIT
          print "Single-stat EV limit #{PokeBattle_Pokemon::EVSTATLIMIT} exceeded.\r\nStat: #{k}  EV gain: #{evgain}  EVs: #{thispoke.ev.inspect}"
          thispoke.ev[k]=PokeBattle_Pokemon::EVSTATLIMIT
        end
        totalev+=evgain
        if totalev>PokeBattle_Pokemon::EVLIMIT
          print "EV limit #{PokeBattle_Pokemon::EVLIMIT} exceeded.\r\nTotal EVs: #{totalev} EV gain: #{evgain}  EVs: #{thispoke.ev.inspect}"
        end
      end
    end
    # Gain experience
    ispartic=0
    ispartic=1 if defeated.participants.include?(index)
    haveexpshare=(isConst?(thispoke.item,PBItems,:EXPSHARE) ||
                  isConst?(thispoke.itemInitial,PBItems,:EXPSHARE)) ? 1 : 0
    exp=0
    if expshare>0
      if partic==0 # No participants, all Exp goes to Exp Share holders
        exp=(level*baseexp).floor
        exp=(exp/(NOSPLITEXP ? 1 : expshare)).floor*haveexpshare
      else
        if NOSPLITEXP
          exp=(level*baseexp).floor*ispartic
          exp=(level*baseexp/2).floor*haveexpshare if ispartic==0
        else
          exp=(level*baseexp/2).floor
          exp=(exp/partic).floor*ispartic + (exp/expshare).floor*haveexpshare
        end
      end
    elsif ispartic==1
      exp=(level*baseexp/(NOSPLITEXP ? 1 : partic)).floor
    elsif haveexpall
      exp=(level*baseexp/2).floor
    end
    return if exp<=0
    exp=(exp*3/2).floor if @opponent
    if USESCALEDEXPFORMULA
      exp=(exp/5).floor
      leveladjust=(2*level+10.0)/(level+thispoke.level+10.0)
      leveladjust=leveladjust**5
      leveladjust=Math.sqrt(leveladjust)
      exp=(exp*leveladjust).floor
      exp+=1 if ispartic>0 || haveexpshare>0
    else
      exp=(exp/7).floor
    end
    isOutsider=(thispoke.trainerID!=self.pbPlayer.id ||
               (thispoke.language!=0 && thispoke.language!=self.pbPlayer.language))
    if isOutsider
      if thispoke.language!=0 && thispoke.language!=self.pbPlayer.language
        exp=(exp*1.7).floor
      else
        exp=(exp*3/2).floor
      end
    end
    exp=(exp*3/2).floor if isConst?(thispoke.item,PBItems,:LUCKYEGG) ||
                           isConst?(thispoke.itemInitial,PBItems,:LUCKYEGG)
    growthrate=thispoke.growthrate
    newexp=PBExperience.pbAddExperience(thispoke.exp,exp,growthrate)
    exp=newexp-thispoke.exp
    if exp>0
      if showmessages
        if isOutsider
          pbDisplayPaused(_INTL("¡{1} ha ganado un total de {2} Puntos de Experiencia!",thispoke.name,exp))
        else
          pbDisplayPaused(_INTL("¡{1} ha ganado {2} Puntos de Experiencia!",thispoke.name,exp))
        end
      end
      newlevel=PBExperience.pbGetLevelFromExperience(newexp,growthrate)
      tempexp=0
      curlevel=thispoke.level
      if newlevel<curlevel
        debuginfo="#{thispoke.name}: #{thispoke.level}/#{newlevel} | #{thispoke.exp}/#{newexp} | gain: #{exp}"
        raise RuntimeError.new(_INTL("El nivel nuevo ({1}) es menor que el nivel actual\r\ndel Pokémon ({2}), lo que no debería pasar.\r\n[Depurar: {3}]",
                               newlevel,curlevel,debuginfo))
        return
      end
      if thispoke.respond_to?("isShadow?") && thispoke.isShadow?
        thispoke.exp+=exp
      else
        tempexp1=thispoke.exp
        tempexp2=0
        # Find battler
        battler=pbFindPlayerBattler(index)
        loop do
          # EXP Bar animation
          startexp=PBExperience.pbGetStartExperience(curlevel,growthrate)
          endexp=PBExperience.pbGetStartExperience(curlevel+1,growthrate)
          tempexp2=(endexp<newexp) ? endexp : newexp
          thispoke.exp=tempexp2
          @scene.pbEXPBar(thispoke,battler,startexp,endexp,tempexp1,tempexp2)
          tempexp1=tempexp2
          curlevel+=1
          if curlevel>newlevel
            thispoke.calcStats
            battler.pbUpdate(false) if battler
            @scene.pbRefresh
            break
          end
          oldtotalhp=thispoke.totalhp
          oldattack=thispoke.attack
          olddefense=thispoke.defense
          oldspeed=thispoke.speed
          oldspatk=thispoke.spatk
          oldspdef=thispoke.spdef
          if battler && battler.pokemon && @internalbattle
            battler.pokemon.changeHappiness("level up")
          end
          thispoke.calcStats
          battler.pbUpdate(false) if battler
          @scene.pbRefresh
          pbDisplayPaused(_INTL("¡{1} subió al nivel {2}!",thispoke.name,curlevel))
          @scene.pbLevelUp(thispoke,battler,oldtotalhp,oldattack,
                           olddefense,oldspeed,oldspatk,oldspdef)
          # Determina todos los movimientos aprendidos a este nivel
          movelist=thispoke.getMoveList
          for k in movelist
            if k[0]==thispoke.level   # Aprendió un movimiento nuevo
              pbLearnMove(index,k[1])
            end
          end
        end
      end
    end
  end

################################################################################
# Learning a move. / Aprendiendo un movimiento
################################################################################
  def pbLearnMove(pkmnIndex,move)
    pokemon=@party1[pkmnIndex]
    return if !pokemon
    pkmnname=pokemon.name
    battler=pbFindPlayerBattler(pkmnIndex)
    movename=PBMoves.getName(move)
    for i in 0...4
      return if pokemon.moves[i].id==move
      if pokemon.moves[i].id==0
        pokemon.moves[i]=PBMove.new(move)
        battler.moves[i]=PokeBattle_Move.pbFromPBMove(self,pokemon.moves[i]) if battler
        pbDisplayPaused(_INTL("¡{1} ha aprendido {2}!",pkmnname,movename))
        PBDebug.log("[Movimiento aprendido] #{pkmnname} ha aprendido #{movename}")
        return
      end
    end
    loop do
      pbDisplayPaused(_INTL("{1} quiere aprender el movimiento {2}.",pkmnname,movename))
      pbDisplayPaused(_INTL("Pero {1} ya conoce cuatro movimientos.",pkmnname))
      if pbDisplayConfirm(_INTL("¿Quieres sustituir uno de esos movimientos por {1}?",movename))
        pbDisplayPaused(_INTL("¿Qué movimiento quieres que olvide?"))
        forgetmove=@scene.pbForgetMove(pokemon,move)
        if forgetmove>=0
          oldmovename=PBMoves.getName(pokemon.moves[forgetmove].id)
          pokemon.moves[forgetmove]=PBMove.new(move)                # Remplaza PP actuales/totales
          battler.moves[forgetmove]=PokeBattle_Move.pbFromPBMove(self,pokemon.moves[forgetmove]) if battler
          pbDisplayPaused(_INTL("1, 2 y..."))
          pbDisplayPaused(_INTL("¡Puf!"))
          pbDisplayPaused(_INTL("¡{1} ha olvidado cómo utilizar {2}!",pkmnname,oldmovename))
          pbDisplayPaused(_INTL("Y..."))
          pbDisplayPaused(_INTL("¡{1} ha aprendido {2}!",pkmnname,movename))
          PBDebug.log("[Movimiento aprendido] #{pkmnname} ha olvidado #{oldmovename} y ha aprendido #{movename}")
          return
        elsif pbDisplayConfirm(_INTL("¿Prefieres que {1} no aprenda {2}?",pkmnname,movename))
          pbDisplayPaused(_INTL("{1} no ha aprendido {2}.",pkmnname,movename))
          return
        end
      elsif pbDisplayConfirm(_INTL("¿Prefieres que {1} no aprenda {2}?",pkmnname,movename))
        pbDisplayPaused(_INTL("{1} no ha aprendido {2}.",pkmnname,movename))
        return
      end
    end
  end

################################################################################
# Abilities. / Habilidades
################################################################################
  def pbOnActiveAll
    for i in 0...4 # Currently unfainted participants will earn EXP even if they faint afterwards
      @battlers[i].pbUpdateParticipants if pbIsOpposing?(i)
      @amuletcoin=true if !pbIsOpposing?(i) &&
                          (isConst?(@battlers[i].item,PBItems,:AMULETCOIN) ||
                           isConst?(@battlers[i].item,PBItems,:LUCKINCENSE))
    end
    for i in 0...4
      if !@battlers[i].isFainted?
        if @battlers[i].isShadow? && pbIsOpposing?(i)
          pbCommonAnimation("Shadow",@battlers[i],nil)
          pbDisplay(_INTL("¡Alto!<br>¡Un Pokémon Oscuro!"))
        end
      end
    end
    # Weather-inducing abilities, Trace, Imposter, etc.
    @usepriority=false
    priority=pbPriority
    for i in priority
      i.pbAbilitiesOnSwitchIn(true)
    end
    # Check forms are correct
    for i in 0...4
      next if @battlers[i].isFainted?
      @battlers[i].pbCheckForm
    end
  end

  def pbOnActiveOne(pkmn,onlyabilities=false,moldbreaker=false)
    return false if pkmn.isFainted?
    if !onlyabilities
      for i in 0...4    # Los participantes actualmente no debilitados ganarán EXP incluso si estuvieron debilitados en el medio
        @battlers[i].pbUpdateParticipants if pbIsOpposing?(i)
        @amuletcoin=true if !pbIsOpposing?(i) &&
                            (isConst?(@battlers[i].item,PBItems,:AMULETCOIN) ||
                             isConst?(@battlers[i].item,PBItems,:LUCKINCENSE))
      end
      if pkmn.isShadow? && pbIsOpposing?(pkmn.index)
        pbCommonAnimation("Shadow",pkmn,nil)
        pbDisplay(_INTL("¡Alto!<br>¡Un Pokémon Oscuro!"))
      end
      # Deseo Cura
      if pkmn.effects[PBEffects::HealingWish]
        PBDebug.log("[Efecto prolongado disparado] Deseo Cura de #{pkmn.pbThis}")
        pbCommonAnimation("HealingWish",pkmn,nil)
        pbDisplayPaused(_INTL("¡El deseo de {1} se hizo realidad!",pkmn.pbThis(true)))
        pkmn.pbRecoverHP(pkmn.totalhp,true)
        pkmn.pbCureStatus(false)
        pkmn.effects[PBEffects::HealingWish]=false
      end
      # Danza Lunar
      if pkmn.effects[PBEffects::LunarDance]
        PBDebug.log("[Efecto prolongado disparado] Danza Lunar de #{pkmn.pbThis}")
        pbCommonAnimation("LunarDance",pkmn,nil)
        pbDisplayPaused(_INTL("¡{1} se rodeó de una luz lunar misteriosa!",pkmn.pbThis))
        pkmn.pbRecoverHP(pkmn.totalhp,true)
        pkmn.pbCureStatus(false)
        for i in 0...4
          pkmn.moves[i].pp=pkmn.moves[i].totalpp
        end
        pkmn.effects[PBEffects::LunarDance]=false
      end
      # Z-Memento/Parting Shot
      if pkmn.effects[PBEffects::ZHeal]
        pkmn.pbRecoverHP(pkmn.totalhp,false)
        pbDisplayPaused(_INTL("The Z-Power healed {1}!",pkmn.pbThis(true)))
        pkmn.effects[PBEffects::ZHeal]=false
      end
      # Púas
      if pkmn.pbOwnSide.effects[PBEffects::Spikes]>0 && !pkmn.isAirborne?(moldbreaker)
        if !(pkmn.hasWorkingAbility(:MAGICGUARD) || pkmn.hasWorkingItem(:HEAVYDUTYBOOTS))
          PBDebug.log("[Peligro de entrada] #{pkmn.pbThis} activó las Púas")
          spikesdiv=[8,6,4][pkmn.pbOwnSide.effects[PBEffects::Spikes]-1]
          @scene.pbDamageAnimation(pkmn,0)
          pkmn.pbReduceHP((pkmn.totalhp/spikesdiv).floor)
          pbDisplayPaused(_INTL("¡{1} ha sido herido por las púas!",pkmn.pbThis))
        end
      end
      pkmn.pbFaint if pkmn.isFainted?
      # Trampa Rocas
      if pkmn.pbOwnSide.effects[PBEffects::StealthRock] && !pkmn.isFainted?
        if !(pkmn.hasWorkingAbility(:MAGICGUARD) || pkmn.hasWorkingItem(:HEAVYDUTYBOOTS))
          atype=getConst(PBTypes,:ROCK) || 0
          eff=PBTypes.getCombinedEffectiveness(atype,pkmn.type1,pkmn.type2,pkmn.effects[PBEffects::Type3])
          if eff>0
            PBDebug.log("[Peligro de entrada] #{pkmn.pbThis} activó la Trampa Rocas")
            @scene.pbDamageAnimation(pkmn,0)
            pkmn.pbReduceHP(((pkmn.totalhp*eff)/64).floor)
            pbDisplayPaused(_INTL("¡{1} fue herido por las piedras puntiagudas!",pkmn.pbThis))
          end
        end
      end
      pkmn.pbFaint if pkmn.isFainted?
      # Púas Tóxicas
      if pkmn.pbOwnSide.effects[PBEffects::ToxicSpikes]>0 && !pkmn.isFainted?
        if !(pkmn.isAirborne?(moldbreaker) || pkmn.hasWorkingItem(:HEAVYDUTYBOOTS))
          if pkmn.pbHasType?(:POISON)
            PBDebug.log("[Peligro de entrada] #{pkmn.pbThis} absorbió las Púas Tóxicas")
            pkmn.pbOwnSide.effects[PBEffects::ToxicSpikes]=0
            pbDisplayPaused(_INTL("¡Las Púas Tóxicas lanzadas alrededor de {1} desaparecieron!",pkmn.pbThis))
          elsif pkmn.pbCanPoisonSpikes?(moldbreaker)
            PBDebug.log("[Peligro de entrada] #{pkmn.pbThis} activó las Púas Tóxicas")
            if pkmn.pbOwnSide.effects[PBEffects::ToxicSpikes]==2
              pkmn.pbPoison(nil,_INTL("¡{1} ha sido gravemente envenenado por las Púas Tóxicas!",pkmn.pbThis,true))
            else
              pkmn.pbPoison(nil,_INTL("¡{1} ha sido envenenado por las Púas Tóxicas!",pkmn.pbThis))
            end
          end
        end
      end
      # Red Viscosa
      if pkmn.pbOwnSide.effects[PBEffects::StickyWeb] && !pkmn.isFainted? &&
         !(pkmn.isAirborne?(moldbreaker) || pkmn.hasWorkingItem(:HEAVYDUTYBOOTS))
        if pkmn.pbCanReduceStatStage?(PBStats::SPEED,nil,false,nil,moldbreaker)
          PBDebug.log("[Peligro de entrada] #{pkmn.pbThis} activó la Red Viscosa")
          pbDisplayPaused(_INTL("¡{1} ha sido atrapado en la Red Viscosa!",pkmn.pbThis))
          pkmn.pbReduceStat(PBStats::SPEED,1,nil,false,nil,true,moldbreaker)
        end
      end
    end
    pkmn.pbAbilityCureCheck
    if pkmn.isFainted?
      pbGainEXP
      pbJudge #      pbSwitch
      return false
    end
#    pkmn.pbAbilitiesOnSwitchIn(true)
    if !onlyabilities
      pkmn.pbCheckForm
      pkmn.pbBerryCureCheck
    end
    return true
  end

  def pbPrimordialWeather
    # End Primordial Sea, Desolate Land, Delta Stream
    hasabil=false
    case @weather
    when PBWeather::HEAVYRAIN
      for i in 0...4
        if isConst?(@battlers[i].ability,PBAbilities,:PRIMORDIALSEA) &&
           !@battlers[i].isFainted?
          hasabil=true; break
        end
      end
    when PBWeather::HARSHSUN
      for i in 0...4
        if isConst?(@battlers[i].ability,PBAbilities,:DESOLATELAND) &&
           !@battlers[i].isFainted?
          hasabil=true; break
        end
      end
    when PBWeather::STRONGWINDS
      for i in 0...4
        if isConst?(@battlers[i].ability,PBAbilities,:DELTASTREAM) &&
           !@battlers[i].isFainted?
          hasabil=true; break
        end
      end
    end
  end

################################################################################
# Judging.
################################################################################
  def pbJudgeCheckpoint(attacker,move=0)
  end

  def pbDecisionOnTime
    count1=0
    count2=0
    hptotal1=0
    hptotal2=0
    for i in @party1
      next if !i
      if i.hp>0 && !i.isEgg?
        count1+=1
        hptotal1+=i.hp
      end
    end
    for i in @party2
      next if !i
      if i.hp>0 && !i.isEgg?
        count2+=1
        hptotal2+=i.hp
      end
    end
    return 1 if count1>count2     # win
    return 2 if count1<count2     # loss
    return 1 if hptotal1>hptotal2 # win
    return 2 if hptotal1<hptotal2 # loss
    return 5                      # draw
  end

  def pbDecisionOnTime2
    count1=0
    count2=0
    hptotal1=0
    hptotal2=0
    for i in @party1
      next if !i
      if i.hp>0 && !i.isEgg?
        count1+=1
        hptotal1+=(i.hp*100/i.totalhp)
      end
    end
    hptotal1/=count1 if count1>0
    for i in @party2
      next if !i
      if i.hp>0 && !i.isEgg?
        count2+=1
        hptotal2+=(i.hp*100/i.totalhp)
      end
    end
    hptotal2/=count2 if count2>0
    return 1 if count1>count2     # win
    return 2 if count1<count2     # loss
    return 1 if hptotal1>hptotal2 # win
    return 2 if hptotal1<hptotal2 # loss
    return 5                      # draw
  end

  def pbDecisionOnDraw
    return 5 # draw
  end

  def pbJudge
#   PBDebug.log("[Counts: #{pbPokemonCount(@party1)}/#{pbPokemonCount(@party2)}]")
    if pbAllFainted?(@party1) && pbAllFainted?(@party2)
      @decision=pbDecisionOnDraw() # Draw
      return
    end
    if pbAllFainted?(@party1)
      @decision=2 # Loss
      return
    end
    if pbAllFainted?(@party2)
      @decision=1 # Win
      return
    end
  end

################################################################################
# Messages and animations.
################################################################################
  def pbDisplay(msg)
    @scene.pbDisplayMessage(msg)
  end

  def pbDisplayPaused(msg)
    @scene.pbDisplayPausedMessage(msg)
  end

  def pbDisplayBrief(msg)
    @scene.pbDisplayMessage(msg,true)
  end

  def pbDisplayConfirm(msg)
    @scene.pbDisplayConfirmMessage(msg)
  end

  def pbShowCommands(msg,commands,cancancel=true)
    @scene.pbShowCommands(msg,commands,cancancel)
  end

  def pbAnimation(move,attacker,opponent,hitnum=0)
    if @battlescene
      @scene.pbAnimation(move,attacker,opponent,hitnum)
    end
  end

  def pbCommonAnimation(name,attacker,opponent,hitnum=0)
    if @battlescene
      @scene.pbCommonAnimation(name,attacker,opponent,hitnum)
    end
  end

################################################################################
# Núcleo del combate.
################################################################################
  def pbStartBattle(canlose=false)
    Graphics.frame_rate = 80 if FASTER_BATTLE
    PBDebug.log("")
    PBDebug.log("******************************************")
    begin
      pbStartBattleCore(canlose)
    rescue BattleAbortedException
      @decision=0
      @scene.pbEndBattle(@decision)
    end
    if FASTER_BATTLE
      Graphics.frame_rate = 40
      Graphics.frame_rate = 60 if FPS60 && $MKXP
    end
    return @decision
  end

  def pbStartBattleCore(canlose)
    if !@fullparty1 && @party1.length>MAXPARTYSIZE
      raise ArgumentError.new(_INTL("Equipo 1 tiene más de {1} Pokémon.",MAXPARTYSIZE))
    end
    if !@fullparty2 && @party2.length>MAXPARTYSIZE
      raise ArgumentError.new(_INTL("Equipo 2 tiene más de {1} Pokémon.",MAXPARTYSIZE))
    end
#==================================================================
# Initialize wild Pokémon / Inicializa Pokémon salvaje
#==================================================================
    if !@opponent
      if @party2.length==1
        #if @doublebattle
        #  raise _INTL("Sólo se permiten dos Pokémon salvajes en una batalla doble")
        #end
        wildpoke=@party2[0]
        @battlers[1].pbInitialize(wildpoke,0,false)
        @peer.pbOnEnteringBattle(self,wildpoke)
        pbSetSeen(wildpoke)
        @scene.pbStartBattle(self)
        pbDisplayPaused(_INTL("¡Un {1} salvaje te corta el paso!",wildpoke.name))
      elsif @party2.length==2
        if !@doublebattle
          raise _INTL("Sólo se permite un Pokémon salvaje en batallas individuales")
        end
        @battlers[1].pbInitialize(@party2[0],0,false)
        @battlers[3].pbInitialize(@party2[1],0,false)
        @peer.pbOnEnteringBattle(self,@party2[0])
        @peer.pbOnEnteringBattle(self,@party2[1])
        pbSetSeen(@party2[0])
        pbSetSeen(@party2[1])
        @scene.pbStartBattle(self)
        pbDisplayPaused(_INTL("¡Un {1} y<br>{2} salvajes te cortan el paso!",
           @party2[0].name,@party2[1].name))
      else
        raise _INTL("Sólo se permite uno o dos Pokémon salvajes en batallas dobles")
      end
      #if rand(65536)<TERAWILD || $game_switches[ALWAISTERAWILD]
      #  fpTeracristal(1)
      #end
#=====================================================================================
# Initialize opponents in double battles / Inicializa oponentes en batallas dobles
#=====================================================================================
    elsif @doublebattle
      if @opponent.is_a?(Array)
        if @opponent.length==1
          @opponent=@opponent[0]
        elsif @opponent.length!=2
          raise _INTL("Rivales con cero o más de dos personas no están permitidos")
        end
      end
      if @player.is_a?(Array)
        if @player.length==1
          @player=@player[0]
        elsif @player.length!=2
          raise _INTL("Entrenadores jugadores con cero o más de dos personas no están permitidos")
        end
      end
      @scene.pbStartBattle(self)
      if @opponent.is_a?(Array)
        pbDisplayPaused(_INTL("¡{1} y {2}<br>te desafían!",@opponent[0].fullname,@opponent[1].fullname))
        sendout1=pbFindNextUnfainted(@party2,0,pbSecondPartyBegin(1))
        raise _INTL("El oponente 1 no tiene ningún Pokémon saludable") if sendout1<0
        sendout2=pbFindNextUnfainted(@party2,pbSecondPartyBegin(1))
        raise _INTL("El oponente 2 no tiene ningún Pokémon saludable") if sendout2<0
        @battlers[1].pbInitialize(@party2[sendout1],sendout1,false)
        pbDisplayBrief(_INTL("¡{1} envió<br>a {2}!",@opponent[0].fullname,@battlers[1].name))
        pbSendOut(1,@party2[sendout1])
        @battlers[3].pbInitialize(@party2[sendout2],sendout2,false)
        pbDisplayBrief(_INTL("¡{1} envió<br>a {2}!",@opponent[1].fullname,@battlers[3].name))
        pbSendOut(3,@party2[sendout2])
      else
        pbDisplayPaused(_INTL("¡{1}<br>te desafía!",@opponent.fullname))
        sendout1=pbFindNextUnfainted(@party2,0)
        sendout2=pbFindNextUnfainted(@party2,sendout1+1)
        if sendout1<0 || sendout2<0
          raise _INTL("El oponente no tiene dos Pokémon saludables")
        end
        @battlers[1].pbInitialize(@party2[sendout1],sendout1,false)
        @battlers[3].pbInitialize(@party2[sendout2],sendout2,false)
        pbDisplayBrief(_INTL("¡{1} envió<br>a {2} y {3}!",
           @opponent.fullname,@battlers[1].name,@battlers[3].name))
        pbSendOut(1,@party2[sendout1])
        pbSendOut(3,@party2[sendout2])
      end
#================================================================================
# Initialize opponent in single battles / Inicializa oponente en batallas simples
#================================================================================
    else
      sendout=pbFindNextUnfainted(@party2,0)
      raise _INTL("El Entrenador no tiene ningún Pokémon saludable") if sendout<0
      if @opponent.is_a?(Array)
        p _INTL("El oponente debe tener un sólo participante en batallas individuales") if @opponent.length!=1 && $DEBUG
        @opponent=@opponent[0]
      end
      if @player.is_a?(Array)
        p _INTL("El jugador debe tener un sólo participante en batallas individuales") if @player.length!=1 && $DEBUG
        @player=@player[0]
      end
      trainerpoke=@party2[sendout]
      @scene.pbStartBattle(self)
      pbDisplayPaused(_INTL("¡{1}<br>te desafía!",@opponent.fullname))
      @battlers[1].pbInitialize(trainerpoke,sendout,false)
      pbDisplayBrief(_INTL("¡{1} envió<br>a {2}!",@opponent.fullname,@battlers[1].name))
      pbSendOut(1,trainerpoke)
    end
#===================================================================================
# Initialize players in double battles / Inicializa jugadores en batallas dobles
#===================================================================================
    if @doublebattle
      if @player.is_a?(Array)
        sendout1=pbFindNextUnfainted(@party1,0,pbSecondPartyBegin(0))
        raise _INTL("El jugador 1 no tiene ningún Pokémon saludable") if sendout1<0
        sendout2=pbFindNextUnfainted(@party1,pbSecondPartyBegin(0))
        p _INTL("El jugador 2 no tiene ningún Pokémon saludable") if sendout2<0 && $DEBUG
        @battlers[0].pbInitialize(@party1[sendout1],sendout1,false)
        @battlers[2].pbInitialize(@party1[sendout2],sendout2,false)
        pbDisplayBrief(_INTL("¡{1} envió<br>a {2}! ¡Adelante, {3}!",
           @player[1].fullname,@battlers[2].name,@battlers[0].name))
        pbSetSeen(@party1[sendout1])
        pbSetSeen(@party1[sendout2])
      else
        sendout1=pbFindNextUnfainted(@party1,0)
        sendout2=pbFindNextUnfainted(@party1,sendout1+1)
        if sendout1<0 #|| sendout2<0
          p _INTL("El jugador no tiene dos Pokémon saludables")
        end
        @battlers[0].pbInitialize(@party1[sendout1],sendout1,false)
        unless sendout2<0
          @battlers[2].pbInitialize(@party1[sendout2],sendout2,false)
          pbDisplayBrief(_INTL("¡Adelante, {1} y {2}!",@battlers[0].name,@battlers[2].name))
        else
          pbDisplayBrief(_INTL("¡Adelante, {1}!",@battlers[0].name))
        end
      end
      pbSendOut(0,@party1[sendout1])
      pbSendOut(2,@party1[sendout2]) unless sendout2<0
#====================================
# Initialize player in single battles
#====================================
    else
      sendout=pbFindNextUnfainted(@party1,0)
      if sendout<0
        raise _INTL("El jugador no tiene ningún Pokémon saludable")
      end
      @battlers[0].pbInitialize(@party1[sendout],sendout,false)
      pbDisplayBrief(_INTL("¡Adelante, {1}!",@battlers[0].name))
      pbSendOut(0,@party1[sendout])
    end
#==================
# Initialize battle
#==================
    if @weather==PBWeather::SUNNYDAY
      pbCommonAnimation("Sunny",nil,nil)
      pbDisplay(_INTL("Hace mucho sol..."))
    elsif @weather==PBWeather::RAINDANCE
      pbCommonAnimation("Rain",nil,nil)
      pbDisplay(_INTL("Sigue lloviendo..."))
    elsif @weather==PBWeather::SANDSTORM
      pbCommonAnimation("Sandstorm",nil,nil)
      pbDisplay(_INTL("La tormenta de arena arrecia..."))
    elsif @weather==PBWeather::HAIL
      pbCommonAnimation("Hail",nil,nil)
      if SNOW_REPLACES_HAIL
        pbDisplay(_INTL("Sigue nevando..."))
      else
        pbDisplay(_INTL("Sigue granizando..."))
      end
    elsif @weather==PBWeather::HEAVYRAIN
      pbCommonAnimation("HeavyRain",nil,nil)
      pbDisplay(_INTL("Sigue diluviando..."))
    elsif @weather==PBWeather::HARSHSUN
      pbCommonAnimation("Sunny",nil,nil)
      pbDisplay(_INTL("El sol sigue realmente abrasador..."))
    elsif @weather==PBWeather::STRONGWINDS
      pbCommonAnimation("StrongWinds",nil,nil)
      pbDisplay(_INTL("Las misteriosas turbulencias continúan con fuerza..."))
    end
    if @field.effects[PBEffects::ElectricTerrain]>0
      #pbCommonAnimation("",nil,nil)
      pbDisplay(_INTL("¡Se ha formado un campo de corriente eléctrica en el campo de batalla!"))
    elsif @field.effects[PBEffects::GrassyTerrain]>0
      #pbCommonAnimation("",nil,nil)
      pbDisplay(_INTL("¡El terreno de combate se ha cubierto de hierba!"))
    elsif @field.effects[PBEffects::MistyTerrain]>0
      #pbCommonAnimation("",nil,nil)
      pbDisplay(_INTL("¡La niebla ha envuelto el terreno de combate!"))
    elsif @field.effects[PBEffects::PsychicTerrain]>0
      #pbCommonAnimation("",nil,nil)
      pbDisplay(_INTL("¡El campo de batalla se volvió extraño!"))
    end
    pbOnActiveAll   # Habilidades
    @turncount=0
    loop do   # Now begin the battle loop
      PBDebug.log("")
      PBDebug.log("***Round #{@turncount+1}***")
      if @debug && @turncount>=100
        @decision=pbDecisionOnTime()
        PBDebug.log("")
        PBDebug.log("***Undecided after 100 rounds, aborting***")
        pbAbort
        break
      end
      PBDebug.logonerr{
         pbCommandPhase
      }
      break if @decision>0
      PBDebug.logonerr{
         pbAttackPhase
      }
      break if @decision>0
      PBDebug.logonerr{
         pbEndOfRoundPhase
      }
      break if @decision>0
      @turncount+=1
    end
    return pbEndOfBattle(canlose)
  end

################################################################################
# Command phase.
################################################################################
  def pbCommandMenu(i)
    return @scene.pbCommandMenu(i)
  end

  def pbItemMenu(i)
    return @scene.pbItemMenu(i)
  end

  def pbAutoFightMenu(i)
    return false
  end

  def pbCommandPhase
    @scene.pbBeginCommandPhase
    @scene.pbResetCommandIndices
    for i in 0...4   # Reset choices if commands can be shown
      @battlers[i].effects[PBEffects::SkipTurn]=false
      if pbCanShowCommands?(i) || @battlers[i].isFainted?
        @choices[i][0]=0
        @choices[i][1]=0
        @choices[i][2]=nil
        @choices[i][3]=-1
      else
        unless !@doublebattle && pbIsDoubleBattler?(i)
          PBDebug.log("[Reutilización de comandos] #{@battlers[i].pbThis(true)}")
        end
      end
    end
    # Reset choices to perform Mega Evolution if it wasn't done somehow
    for i in 0...2
      for j in 0...@megaEvolution[i].length
        @megaEvolution[i][j]=-1 if @megaEvolution[i][j]>=0
      end
    end
    for i in 0...2
      for j in 0...@teraCristal[i].length
        @teraCristal[i][j]=-1 if @teraCristal[i][j]>=0
      end
    end
    for i in 0...2
      for j in 0...@ultraBurst[i].length
        @ultraBurst[i][j]=-1 if @ultraBurst[i][j]>=0
      end
    end
    for i in 0...@zMove[0].length
      @zMove[0][i]=-1 if @zMove[0][i]>=0
    end
    for i in 0...@zMove[1].length
      @zMove[1][i]=-1 if @zMove[1][i]>=0
    end
    for i in 0...4
      break if @decision!=0
      next if @choices[i][0]!=0
      if !pbOwnedByPlayer?(i) || @controlPlayer
        if !@battlers[i].isFainted? && pbCanShowCommands?(i)
          @scene.pbChooseEnemyCommand(i)
        end
      else
        commandDone=false
        commandEnd=false
        if pbCanShowCommands?(i)
          loop do
            cmd=pbCommandMenu(i)
            if cmd==0 # Fight
              if pbCanShowFightMenu?(i)
                commandDone=true if pbAutoFightMenu(i)
                until commandDone
                  index=@scene.pbFightMenu(i)
                  if index<0
                    side=(pbIsOpposing?(i)) ? 1 : 0
                    owner=pbGetOwnerIndex(i)
                    if @megaEvolution[side][owner]==i
                      @megaEvolution[side][owner]=-1
                    end
                    if @ultraBurst[side][owner]==i
                      @ultraBurst[side][owner]=-1
                    end
                    if @zMove[side][owner]==i
                      @zMove[side][owner]=-1
                    end
                    if @teraCristal[side][owner]==i
                      @teraCristal[side][owner]=-1
                    end
                    break
                  end
                  next if !pbRegisterMove(i,index)
                  if @doublebattle
                    thismove=@battlers[i].moves[index]
                    target=@battlers[i].pbTarget(thismove)
                    if target==PBTargets::SingleNonUser # single non-user
                      target=@scene.pbChooseTarget(i,target)
                      next if target<0
                      pbRegisterTarget(i,target)
                    elsif target==PBTargets::UserOrPartner # Acupressure
                      target=@scene.pbChooseTarget(i,target)
                      next if target<0 || (target&1)==1
                      pbRegisterTarget(i,target)
                    end
                  end
                  commandDone=true
                end
              else
                pbAutoChooseMove(i)
                commandDone=true
              end
            elsif cmd!=0 && @battlers[i].effects[PBEffects::SkyDrop]           # Caída Libre
              pbDisplay(_INTL("¡{1} no se puede liberar de la Caída Libre!",@battlers[i].pbThis(true)))
            elsif cmd==1 # Bag
              if !@internalbattle
                if pbOwnedByPlayer?(i)
                  pbDisplay(_INTL("Los objetos no se pueden utilizar aquí."))
                end
              else
                item=pbItemMenu(i)
                if item[0]>0
                  if pbRegisterItem(i,item[0],item[1])
                    commandDone=true
                  end
                end
              end
            elsif cmd==2 # Pokémon
              pkmn=pbSwitchPlayer(i,false,true)
              if pkmn>=0
                commandDone=true if pbRegisterSwitch(i,pkmn)
              end
            elsif cmd==3   # Run
              run=pbRun(i)
              if run>0
                commandDone=true
                return
              elsif run<0
                commandDone=true
                side=(pbIsOpposing?(i)) ? 1 : 0
                owner=pbGetOwnerIndex(i)
                if @megaEvolution[side][owner]==i
                  @megaEvolution[side][owner]=-1
                end
                if @ultraBurst[side][owner]==i
                  @ultraBurst[side][owner]=-1
                end
                if @zMove[side][owner]==i
                  @zMove[side][owner]=-1
                end
                if @teraCristal[side][owner]==i
                  @teraCristal[side][owner]=-1
                end
              end
            elsif cmd==4   # Call
              thispkmn=@battlers[i]
              @choices[i][0]=4   # "Call Pokémon"
              @choices[i][1]=0
              @choices[i][2]=nil
              side=(pbIsOpposing?(i)) ? 1 : 0
              owner=pbGetOwnerIndex(i)
              if @megaEvolution[side][owner]==i
                @megaEvolution[side][owner]=-1
              end
              if @ultraBurst[side][owner]==i
                @ultraBurst[side][owner]=-1
              end
              if @zMove[side][owner]==i
                @zMove[side][owner]=-1
              end
              if @teraCristal[side][owner]==i
                @teraCristal[side][owner]=-1
              end
              commandDone=true
            elsif cmd==-1   # Go back to first battler's choice
              @megaEvolution[0][0]=-1 if @megaEvolution[0][0]>=0
              @megaEvolution[1][0]=-1 if @megaEvolution[1][0]>=0
              @ultraBurst[0][0]=-1 if @ultraBurst[0][0]>=0
              @ultraBurst[1][0]=-1 if @ultraBurst[1][0]>=0
              @zMove[0][0]=-1 if @zMove[0][0]>=0
              @zMove[1][0]=-1 if @zMove[1][0]>=0
              @teraCristal[0][0]=-1 if @teraCristal[0][0]>=0
              @teraCristal[1][0]=-1 if @teraCristal[1][0]>=0
              # Restore the item the player's first Pokémon was due to use
              if @choices[0][0]==3 && $PokemonBag && $PokemonBag.pbCanStore?(@choices[0][1])
                $PokemonBag.pbStoreItem(@choices[0][1])
              end
              pbCommandPhase
              return
            end
            break if commandDone
          end
        end
      end
    end
  end

################################################################################
# Attack phase.
################################################################################
  def pbAttackPhase
    @scene.pbBeginAttackPhase
    for i in 0...4
      @successStates[i].clear
      if @choices[i][0]!=1 && @choices[i][0]!=2
        @battlers[i].effects[PBEffects::DestinyBond]=false
        @battlers[i].effects[PBEffects::Grudge]=false
      end
      @battlers[i].turncount+=1 if !@battlers[i].isFainted?
      @battlers[i].effects[PBEffects::Rage]=false if !pbChoseMove?(i,:RAGE)
    end
    # Prepare for Z Moves
    for i in 0..3
      next if @choices[i][0]!=1
      side=(pbIsOpposing?(i)) ? 1 : 0
      owner=pbGetOwnerIndex(i)
      if @zMove[side][owner]==i
        @choices[i][2].zmove=true
      end
    end
    # Calculate priority at this time
    @usepriority=false
    priority=pbPriority(false,true)
    # Mega Evolution
    megaevolved=[]
    for i in priority
      if @choices[i.index][0]==1 && !i.effects[PBEffects::SkipTurn]
        side=(pbIsOpposing?(i.index)) ? 1 : 0
        owner=pbGetOwnerIndex(i.index)
        if @megaEvolution[side][owner]==i.index
          pbMegaEvolve(i.index)
          megaevolved.push(i.index)
        end
      end
    end
    if megaevolved.length>0
      for i in priority
        i.pbAbilitiesOnSwitchIn(true) if megaevolved.include?(i.index)
      end
    end
    # Ultra Burst
    ultrabursted=[]
    for i in priority
      if @choices[i.index][0]==1 && !i.effects[PBEffects::SkipTurn]
        side=(pbIsOpposing?(i.index)) ? 1 : 0
        owner=pbGetOwnerIndex(i.index)
        if @ultraBurst[side][owner]==i.index
          pbUltraBurst(i.index)
          ultrabursted.push(i.index)
        end
      end
    end
    if ultrabursted.length>0
      for i in priority
        i.pbAbilitiesOnSwitchIn(true) if ultrabursted.include?(i.index)
      end
    end
    # TeraCristal
    for i in priority
      if @choices[i.index][0]==1 && !i.effects[PBEffects::SkipTurn]
        side=(pbIsOpposing?(i.index)) ? 1 : 0
        owner=pbGetOwnerIndex(i.index)
        if @teraCristal[side][owner]==i.index
          pbTeraCristal(i.index)
        end
      end
    end
    # Call at Pokémon
    for i in priority
      if @choices[i.index][0]==4 && !i.effects[PBEffects::SkipTurn]
        pbCall(i.index)
      end
    end
    # Switch out Pokémon
    @switching=true
    switched=[]
    for i in priority
      if @choices[i.index][0]==2 && !i.effects[PBEffects::SkipTurn]
        index=@choices[i.index][1] # party position of Pokémon to switch to
        newpokename=index
        if isConst?(pbParty(i.index)[index].ability,PBAbilities,:ILLUSION)
          newpokename=pbGetLastPokeInTeam(i.index)
        end
        self.lastMoveUser=i.index
        if !pbOwnedByPlayer?(i.index)
          owner=pbGetOwner(i.index)
          pbDisplayBrief(_INTL("¡{1} saca a {2}!",owner.fullname,i.name))
          PBDebug.log("[Sacar Pokémon] Oponente sacó #{i.pbThis(true)}")
        else
          pbDisplayBrief(_INTL("¡{1}, cambio!<br>¡Vuelve aquí!",i.name))
          PBDebug.log("[Sacar Pokémon] Jugador sacó #{i.pbThis(true)}")
        end
        i.effects[PBEffects::PerishBody]=0 # Reset Perish Body if has one
        for j in priority
          next if !i.pbIsOpposing?(j.index)
          # if Pursuit and this target ("i") was chosen
          if pbChoseMoveFunctionCode?(j.index,0x88) && # Pursuit
             !j.hasMovedThisRound?
            if j.status!=PBStatuses::SLEEP && j.status!=PBStatuses::FROZEN &&
               !j.effects[PBEffects::SkyDrop] &&
               (!j.hasWorkingAbility(:TRUANT) || !j.effects[PBEffects::Truant])
              @choices[j.index][3]=i.index # Make sure to target the switching Pokémon
              j.pbUseMove(@choices[j.index]) # This calls pbGainEXP as appropriate
              j.effects[PBEffects::Pursuit]=true
              @switching=false
              return if @decision>0
            end
          end
          break if i.isFainted?
        end
        if !pbRecallAndReplace(i.index,index,newpokename)
          # If a forced switch somehow occurs here in single battles
          # the attack phase now ends
          if !@doublebattle
            @switching=false
            return
          end
        else
          switched.push(i.index)
          i.effects[PBEffects::Stakeout]=true
        end
      end
    end
    if switched.length>0
      for i in priority
        i.pbAbilitiesOnSwitchIn(true) if switched.include?(i.index)
      end
    end
    @switching=false
    # Uso de objetos
    for i in priority
      if @choices[i.index][0]==3 && !i.effects[PBEffects::SkipTurn]
        if pbIsOpposing?(i.index)
          # Opponent use item
          pbEnemyUseItem(@choices[i.index][1],i)
        else
          # Player use item
          item=@choices[i.index][1]
          if item>0
            usetype=$ItemData[item][ITEMBATTLEUSE]
            if usetype==1 || usetype==3
              if @choices[i.index][2]>=0
                pbUseItemOnPokemon(item,@choices[i.index][2],i,@scene)
              end
            elsif usetype==2 || usetype==4
              if !ItemHandlers.hasUseInBattle(item) # Poké Ball/Poké Doll used already
                pbUseItemOnBattler(item,@choices[i.index][2],i,@scene)
              end
            end
          end
        end
      end
    end
    # Uso de ataques
    for i in priority
      next if i.effects[PBEffects::SkipTurn]
      if pbChoseMoveFunctionCode?(i.index,0x115) # Focus Punch  /  Puño Certero
        pbCommonAnimation("FocusPunch",i,nil)
        pbDisplay(_INTL("¡{1} está reforzando su concentración!",i.pbThis))
      elsif pbChoseMoveFunctionCode?(i.index,0x1BC) # Beak Blast
        pbCommonAnimation("Burn",i,nil)
        pbDisplay(_INTL("¡{1} empezó a calentar su pico!",i.pbThis))
      end
    end
    10.times do
      # Forced to go next
      advance=false
      for i in priority
        next if !i.effects[PBEffects::MoveNext]
        next if i.hasMovedThisRound? || i.effects[PBEffects::SkipTurn]
        advance=i.pbProcessTurn(@choices[i.index])
        break if advance
      end
      return if @decision>0
      next if advance
      # Regular priority order
      for i in priority
        next if i.effects[PBEffects::Quash]
        next if i.hasMovedThisRound? || i.effects[PBEffects::SkipTurn]
        advance=i.pbProcessTurn(@choices[i.index])
        break if advance
      end
      return if @decision>0
      next if advance
      # Quashed
      for i in priority
        next if !i.effects[PBEffects::Quash]
        next if i.hasMovedThisRound? || i.effects[PBEffects::SkipTurn]
        advance=i.pbProcessTurn(@choices[i.index])
        break if advance
      end
      return if @decision>0
      next if advance
      # Check for all done
      for i in priority
        advance=true if @choices[i.index][0]==1 && !i.hasMovedThisRound? &&
                        !i.effects[PBEffects::SkipTurn]
        break if advance
      end
      next if advance
      break
    end
    pbWait(20)
  end

################################################################################
# Final de la ronda.
################################################################################
  def pbEndOfRoundPhase
    PBDebug.log("[Final de la ronda]")
    for i in 0...4
      @battlers[i].effects[PBEffects::BanefulBunker]=false
      @battlers[i].effects[PBEffects::Electrify]=false
      @battlers[i].effects[PBEffects::Endure]=false
      @battlers[i].effects[PBEffects::FirstPledge]=0
      @battlers[i].effects[PBEffects::HyperBeam]-=1 if @battlers[i].effects[PBEffects::HyperBeam]>0
      @battlers[i].effects[PBEffects::KingsShield]=false
      @battlers[i].effects[PBEffects::LifeOrb]=false
      @battlers[i].effects[PBEffects::MoveNext]=false
      @battlers[i].effects[PBEffects::Powder]=false
      @battlers[i].effects[PBEffects::Protect]=false
      @battlers[i].effects[PBEffects::ProtectNegation]=false
      @battlers[i].effects[PBEffects::Quash]=false
      @battlers[i].effects[PBEffects::Roost]=false
      @battlers[i].effects[PBEffects::SpikyShield]=false
      @battlers[i].effects[PBEffects::Stakeout]=false
      @battlers[i].effects[PBEffects::Obstruct]=false
      @battlers[i].effects[PBEffects::Silktrap]=false
    end
    @usepriority=false  # recalculate priority
    priority=pbPriority(true) # Ignoring Quick Claw here
    #for i in @battlers
    #  if pbIsOpposing?(i.index) && i.totalhp/2 > i.hp && i.isTera? && !@opponent
    #    i.makeUntera
    #  end
    #end
    # Weather
    case @weather
    when PBWeather::SUNNYDAY
      @weatherduration=@weatherduration-1 if @weatherduration>0
      if @weatherduration==0
        pbDisplay(_INTL("Se ha ido el sol."))
        @weather=0
        PBDebug.log("[Fin de efecto] El clima Día Soleado se terminó")
      else
        pbCommonAnimation("Sunny",nil,nil)
        pbDisplay(_INTL("Hace mucho sol..."))
        if pbWeather==PBWeather::SUNNYDAY
          for i in priority
            if i.hasWorkingAbility(:SOLARPOWER) && !i.hasWorkingItem(:UTILITYUMBRELLA) # Poder solar
              PBDebug.log("[Habilidad disparada] Poder Solar de #{i.pbThis}")
              @scene.pbDamageAnimation(i,0)
              i.pbReduceHP((i.totalhp/8).floor)
              pbDisplay(_INTL("¡{1} perdió algunos PS debido al Poder Solar!",i.pbThis))
              if i.isFainted?
                return if !i.pbFaint
              end
            end
          end
        end
      end
    when PBWeather::RAINDANCE
      @weatherduration=@weatherduration-1 if @weatherduration>0
      if @weatherduration==0
        pbDisplay(_INTL("Ha dejado de llover."))
        @weather=0
        PBDebug.log("[Fin de efecto] El clima Lluvia se terminó")
      else
        pbCommonAnimation("Rain",nil,nil)
        pbDisplay(_INTL("Sigue lloviendo..."))
      end
    when PBWeather::SANDSTORM
      @weatherduration=@weatherduration-1 if @weatherduration>0
      if @weatherduration==0
        pbDisplay(_INTL("La tormenta de arena amainó."))
        @weather=0
        PBDebug.log("[Fin de efecto] El clima Tormenta de Arena terminó")
      else
        pbCommonAnimation("Sandstorm",nil,nil)
        pbDisplay(_INTL("La tormenta de arena arrecia..."))
        if pbWeather==PBWeather::SANDSTORM
          PBDebug.log("[Efecto prolongado disparado] El clima Tormenta de Arena inflinge daño")
          for i in priority
            next if i.isFainted?
            if !i.pbHasType?(:GROUND) && !i.pbHasType?(:ROCK) && !i.pbHasType?(:STEEL) &&
               !i.hasWorkingAbility(:SANDVEIL) &&
               !i.hasWorkingAbility(:SANDRUSH) &&
               !i.hasWorkingAbility(:SANDFORCE) &&
               !i.hasWorkingAbility(:MAGICGUARD) &&
               !i.hasWorkingAbility(:OVERCOAT) &&
               !i.hasWorkingItem(:SAFETYGOGGLES) &&
               ![0xCA,0xCB].include?(PBMoveData.new(i.effects[PBEffects::TwoTurnAttack]).function) # Dig, Dive
              @scene.pbDamageAnimation(i,0)
              i.pbReduceHP((i.totalhp/16).floor)
              pbDisplay(_INTL("¡La tormenta de arena zarandea a {1}!",i.pbThis))
              if i.isFainted?
                return if !i.pbFaint
              end
            end
          end
        end
      end
    when PBWeather::HAIL
      @weatherduration=@weatherduration-1 if @weatherduration>0
      if @weatherduration==0
        if SNOW_REPLACES_HAIL
          pbDisplay(_INTL("Ha dejado de nevar."))
        else
          pbDisplay(_INTL("Ha dejado de granizar."))
        end
        @weather=0
        PBDebug.log("[Fin de efecto] El clima Granizo terminó")
      else
        pbCommonAnimation("Hail",nil,nil)
        if SNOW_REPLACES_HAIL
          pbDisplay(_INTL("Sigue nevando..."))
        else
          pbDisplay(_INTL("Sigue granizando..."))
        end
        if pbWeather==PBWeather::HAIL && !SNOW_REPLACES_HAIL
          PBDebug.log("[Efecto prolongado disparado] El clima Granizo inflinge daño")
          for i in priority
            next if i.isFainted?
            if !i.pbHasType?(:ICE) &&
               !i.hasWorkingAbility(:ICEBODY) &&
               !i.hasWorkingAbility(:SNOWCLOAK) &&
               !i.hasWorkingAbility(:MAGICGUARD) &&
               !i.hasWorkingAbility(:OVERCOAT) &&
               !i.hasWorkingItem(:SAFETYGOGGLES) &&
               ![0xCA,0xCB].include?(PBMoveData.new(i.effects[PBEffects::TwoTurnAttack]).function) # Dig, Dive
              @scene.pbDamageAnimation(i,0)
              i.pbReduceHP((i.totalhp/16).floor)
              pbDisplay(_INTL("¡El granizo zarandea a {1}!",i.pbThis))
              if i.isFainted?
                return if !i.pbFaint
              end
            end
          end
        end
      end
    when PBWeather::HEAVYRAIN                              # Mar del Albor
      hasabil=false
      for i in 0...4
        if isConst?(@battlers[i].ability,PBAbilities,:PRIMORDIALSEA) && !@battlers[i].isFainted?
          hasabil=true; break
        end
      end
      @weatherduration=0 if !hasabil
      if @weatherduration==0
        pbDisplay(_INTL("¡El diluvio ha terminado!"))
        @weather=0
        PBDebug.log("[Fin de efecto] El clima del Mar del Albor ha terminado")
      else
        pbCommonAnimation("HeavyRain",nil,nil)
        pbDisplay(_INTL("Sigue diluviando con fuerza..."))
      end
    when PBWeather::HARSHSUN                               # Tierra del Ocaso
      hasabil=false
      for i in 0...4
        if isConst?(@battlers[i].ability,PBAbilities,:DESOLATELAND) && !@battlers[i].isFainted?
          hasabil=true; break
        end
      end
      @weatherduration=0 if !hasabil
      if @weatherduration==0
        pbDisplay(_INTL("¡El sol vuelve a brillar como siempre!"))
        @weather=0
        PBDebug.log("[Fin de efecto] El clima de la Tierra del Ocaso ha terminado")
      else
        pbCommonAnimation("Sunny",nil,nil)
        pbDisplay(_INTL("El sol sigue siendo abrasador..."))
        if pbWeather==PBWeather::HARSHSUN
          for i in priority
            if i.hasWorkingAbility(:SOLARPOWER) && !i.hasWorkingItem(:UTILITYUMBRELLA) # Poder Solar
              PBDebug.log("[Habilidad disparada] Poder Solar de #{i.pbThis}")
              @scene.pbDamageAnimation(i,0)
              i.pbReduceHP((i.totalhp/8).floor)
              pbDisplay(_INTL("¡{1} ha sido dañado por la luz solar!",i.pbThis))
              if i.isFainted?
                return if !i.pbFaint
              end
            end
          end
        end
      end
    when PBWeather::STRONGWINDS                            # Ráfaga Delta
      hasabil=false
      for i in 0...4
        if isConst?(@battlers[i].ability,PBAbilities,:DELTASTREAM) && !@battlers[i].isFainted?
          hasabil=true; break
        end
      end
      @weatherduration=0 if !hasabil
      if @weatherduration==0
        pbDisplay(_INTL("¡Las misteriosas turbulencias han amainado!"))
        @weather=0
        PBDebug.log("[Fin de efecto] El clima de Ráfaga Delta ha terminado")
      else
        pbCommonAnimation("StrongWinds",nil,nil)
      end
    end
    # Shadow Sky weather  /  Clima Cielo Oscuro (de Pkm XD)
    if isConst?(@weather,PBWeather,:SHADOWSKY)
      @weatherduration=@weatherduration-1 if @weatherduration>0
      if @weatherduration==0
        pbDisplay(_INTL("El cielo oscuro se ha aclarado."))
        @weather=0
        PBDebug.log("[Fin de efecto] El clima Cielo Oscuro ha terminado")
      else
        pbCommonAnimation("ShadowSky",nil,nil)
#        pbDisplay(_INTL("El cielo sigue oscuro..."));
        if isConst?(pbWeather,PBWeather,:SHADOWSKY)
          PBDebug.log("[Efecto prolongado disparado] El clima Cielo Oscuro inflinge daño")
          for i in priority
            next if i.isFainted?
            if !i.isShadow?
              @scene.pbDamageAnimation(i,0)
              i.pbReduceHP((i.totalhp/16).floor)
              pbDisplay(_INTL("¡{1} ha sido dañado por el cielo oscuro!",i.pbThis))
              if i.isFainted?
                return if !i.pbFaint
              end
            end
          end
        end
      end
    end
    # Future Sight/Doom Desire     -   Premonición/Deseo Oculto
    for i in battlers   # not priority
      next if i.isFainted?
      if i.effects[PBEffects::FutureSight]>0
        i.effects[PBEffects::FutureSight]-=1
        if i.effects[PBEffects::FutureSight]==0
          move=i.effects[PBEffects::FutureSightMove]
          PBDebug.log("[Efecto prolongado disparado] #{PBMoves.getName(move)} ha golpeado a #{i.pbThis(true)}")
          pbDisplay(_INTL("¡{1} ha sufrido el ataque {2}!",i.pbThis,PBMoves.getName(move)))
          moveuser=nil
          for j in battlers
            next if j.pbIsOpposing?(i.effects[PBEffects::FutureSightUserPos])
            if j.pokemonIndex==i.effects[PBEffects::FutureSightUser] && !j.isFainted?
              moveuser=j; break
            end
          end
          if !moveuser
            party=pbParty(i.effects[PBEffects::FutureSightUserPos])
            if party[i.effects[PBEffects::FutureSightUser]].hp>0
              moveuser=PokeBattle_Battler.new(self,i.effects[PBEffects::FutureSightUserPos])
              moveuser.pbInitDummyPokemon(party[i.effects[PBEffects::FutureSightUser]],
                                          i.effects[PBEffects::FutureSightUser])
            end
          end
          if !moveuser
            pbDisplay(_INTL("¡Pero falló!"))
          else
            @futuresight=true
            moveuser.pbUseMoveSimple(move,-1,i.index)
            @futuresight=false
          end
          i.effects[PBEffects::FutureSight]=0
          i.effects[PBEffects::FutureSightMove]=0
          i.effects[PBEffects::FutureSightUser]=-1
          i.effects[PBEffects::FutureSightUserPos]=-1
          if i.isFainted?
            return if !i.pbFaint
            next
          end
        end
      end
    end
    for i in priority
      next if i.isFainted?
      # Rain Dish   /   Cura Lluvia
      if i.hasWorkingAbility(:RAINDISH) && i.effects[PBEffects::HealBlock]==0 &&
         (pbWeather==PBWeather::RAINDANCE ||
         pbWeather==PBWeather::HEAVYRAIN)  && !i.hasWorkingItem(:UTILITYUMBRELLA)
        PBDebug.log("[Habilidad disparada] Cura Lluvia de #{i.pbThis}")
        hpgain=i.pbRecoverHP((i.totalhp/16).floor,true)
        pbDisplay(_INTL("¡{1} ha restaurado algunos PS gracias a {2}!",i.pbThis,PBAbilities.getName(i.ability))) if hpgain>0
      end
      # Dry Skin  /  Piel Seca
      if i.hasWorkingAbility(:DRYSKIN)
        if pbWeather==PBWeather::RAINDANCE ||
           pbWeather==PBWeather::HEAVYRAIN && !i.hasWorkingItem(:UTILITYUMBRELLA) &&
           i.effects[PBEffects::HealBlock]==0
          PBDebug.log("[Habilidad disparada] Piel Seca de #{i.pbThis} (bajo lluvia)")
          hpgain=i.pbRecoverHP((i.totalhp/8).floor,true)
          pbDisplay(_INTL("¡{1} ha restaurado algunos PS por su {2}!",i.pbThis,PBAbilities.getName(i.ability))) if hpgain>0
        elsif (pbWeather==PBWeather::SUNNYDAY ||
              pbWeather==PBWeather::HARSHSUN) && !i.hasWorkingItem(:UTILITYUMBRELLA)
          PBDebug.log("[Habilidad disparada] Piel Seca de #{i.pbThis} (al sol)")
          @scene.pbDamageAnimation(i,0)
          hploss=i.pbReduceHP((i.totalhp/8).floor)
          pbDisplay(_INTL("¡{1} ha sido dañado por la fuerte luz del sol sobre su {2}!",i.pbThis,PBAbilities.getName(i.ability))) if hploss>0
        end
      end
      # Ice Body  /  Gélido
      if i.hasWorkingAbility(:ICEBODY) && pbWeather==PBWeather::HAIL
        PBDebug.log("[Habilidad disparada] Gélido de #{i.pbThis}")
        hpgain=i.pbRecoverHP((i.totalhp/16).floor,true)
        pbDisplay(_INTL("{1} ha restaurado algunos PS con {2}!",i.pbThis,PBAbilities.getName(i.ability))) if hpgain>0
      end
      if i.isFainted?
        return if !i.pbFaint
      end
    end
    # Wish  /  Deseo
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::Wish]>0
        i.effects[PBEffects::Wish]-=1
        if i.effects[PBEffects::Wish]==0
          PBDebug.log("[Efecto prolongado disparado] Deseo de #{i.pbThis}")
          hpgain=i.pbRecoverHP(i.effects[PBEffects::WishAmount],true)
          if hpgain>0
            wishmaker=pbThisEx(i.index,i.effects[PBEffects::WishMaker])
            pbDisplay(_INTL("¡El deseo de {1} se hizo realidad!",wishmaker))
          end
        end
      end
    end
    # Fire Pledge + Grass Pledge combination damage
    for i in 0...2
      if sides[i].effects[PBEffects::SeaOfFire]>0 &&
         pbWeather!=PBWeather::RAINDANCE &&
         pbWeather!=PBWeather::HEAVYRAIN
        @battle.pbCommonAnimation("SeaOfFire",nil,nil) if i==0
        @battle.pbCommonAnimation("SeaOfFireOpp",nil,nil) if i==1
        for j in priority
          next if (j.index&1)!=i
          next if j.pbHasType?(:FIRE) || j.hasWorkingAbility(:MAGICGUARD)
          @scene.pbDamageAnimation(j,0)
          hploss=j.pbReduceHP((j.totalhp/8).floor)
          pbDisplay(_INTL("¡{1} ha sido dañado por el mar de llamas!",j.pbThis)) if hploss>0
          if j.isFainted?
            return if !j.pbFaint
          end
        end
      end
    end
    for i in priority
      next if i.isFainted?
      # Shed Skin, Hydration
      if (i.hasWorkingAbility(:SHEDSKIN) && pbRandom(10)<3) ||
         (i.hasWorkingAbility(:HYDRATION) && (pbWeather==PBWeather::RAINDANCE ||
                                              pbWeather==PBWeather::HEAVYRAIN) && !i.hasWorkingItem(:UTILITYUMBRELLA))
        if i.status>0
          PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(i.ability)} de #{i.pbThis}")
          s=i.status
          i.pbCureStatus(false)
          case s
          when PBStatuses::SLEEP
            pbDisplay(_INTL("¡{2} de {1} lo despertó!",i.pbThis,PBAbilities.getName(i.ability)))
          when PBStatuses::POISON
            pbDisplay(_INTL("¡{2} de {1} le curó el veneno!",i.pbThis,PBAbilities.getName(i.ability)))
          when PBStatuses::BURN
            pbDisplay(_INTL("¡{2} de {1} le curó la quemadura!",i.pbThis,PBAbilities.getName(i.ability)))
          when PBStatuses::PARALYSIS
            pbDisplay(_INTL("¡{2} de {1} le curó la parálisis!",i.pbThis,PBAbilities.getName(i.ability)))
          when PBStatuses::FROZEN
            pbDisplay(_INTL("¡{2} de {1} le permitió descongelarse!",i.pbThis,PBAbilities.getName(i.ability)))
          end
        end
      end
      # Healer
      if i.hasWorkingAbility(:HEALER) && pbRandom(10)<3
        partner=i.pbPartner
        if partner && partner.status>0
          PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(i.ability)} de #{i.pbThis}")
          s=partner.status
          partner.pbCureStatus(false)
          case s
          when PBStatuses::SLEEP
            pbDisplay(_INTL("¡{2} de {1} le quitó el sueño a su compañero!",i.pbThis,PBAbilities.getName(i.ability)))
          when PBStatuses::POISON
            pbDisplay(_INTL("¡{2} de {1} le curó el venenó a su compañero!",i.pbThis,PBAbilities.getName(i.ability)))
          when PBStatuses::BURN
            pbDisplay(_INTL("¡{2} de {1} le curó la quemadura a su compañero!",i.pbThis,PBAbilities.getName(i.ability)))
          when PBStatuses::PARALYSIS
            pbDisplay(_INTL("¡{2} de {1} liberó de la parálisis a su compañero!",i.pbThis,PBAbilities.getName(i.ability)))
          when PBStatuses::FROZEN
            pbDisplay(_INTL("¡{2} de {1} descongeló a su compañero!",i.pbThis,PBAbilities.getName(i.ability)))
          end
        end
      end
    end
    for i in priority
      next if i.isFainted?
      # Grassy Terrain (healing)
      if @field.effects[PBEffects::GrassyTerrain]>0 && !i.isAirborne?
        if i.effects[PBEffects::HealBlock]==0
          hpgain=i.pbRecoverHP((i.totalhp/16).floor,true)
          pbDisplay(_INTL("Los PS de {1} han sido recuperados.",i.pbThis)) if hpgain>0
        end
      end
      # Held berries/Leftovers/Black Sludge
      i.pbBerryCureCheck(true)
      if i.isFainted?
        return if !i.pbFaint
      end
    end
    # Acua Aro / Aqua Ring
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::AquaRing]
        PBDebug.log("[Efecto prolongado disparado] Acua Aro de #{i.pbThis}")
        hpgain=(i.totalhp/16).floor
        hpgain=(hpgain*1.3).floor if i.hasWorkingItem(:BIGROOT)
        hpgain=i.pbRecoverHP(hpgain,true)
        pbDisplay(_INTL("¡Acua Aro ha recuperado salud de {1}!",i.pbThis)) if hpgain>0
      end
    end
    # Arraigo / Ingrain
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::Ingrain]
        PBDebug.log("[Efecto prolongado disparado] Arraigo de #{i.pbThis}")
        hpgain=(i.totalhp/16).floor
        hpgain=(hpgain*1.3).floor if i.hasWorkingItem(:BIGROOT)         # Raíz Grande
        hpgain=i.pbRecoverHP(hpgain,true)
        pbDisplay(_INTL("¡{1} ha absorbido nutrientes con las raíces!",i.pbThis)) if hpgain>0
      end
    end
    # Drenadoras / Leech Seed
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::LeechSeed]>=0 && !i.hasWorkingAbility(:MAGICGUARD)
        recipient=@battlers[i.effects[PBEffects::LeechSeed]]
        if recipient && !recipient.isFainted?            # si existe beneficiario
          PBDebug.log("[Efecto prolongado disparado] Drenadoras de #{i.pbThis}")
          pbCommonAnimation("LeechSeed",recipient,i)
          hploss=i.pbReduceHP((i.totalhp/8).floor,true)
          if i.hasWorkingAbility(:LIQUIDOOZE)
            recipient.pbReduceHP(hploss,true)
            pbDisplay(_INTL("¡{1} ha absorbido el Lodo Líquido!",recipient.pbThis))
          else
            if recipient.effects[PBEffects::HealBlock]==0
              hploss=(hploss*1.3).floor if recipient.hasWorkingItem(:BIGROOT)
              recipient.pbRecoverHP(hploss,true)
            end
            pbDisplay(_INTL("¡Las drenadoras restaron salud a {1}!",i.pbThis))
          end
          if i.isFainted?
            return if !i.pbFaint
          end
          if recipient.isFainted?
            return if !recipient.pbFaint
          end
        end
      end
    end
    for i in priority
      next if i.isFainted?
      # Envenenado/Gravemente envenenado         Poison/Bad poison
      if i.status==PBStatuses::POISON
        if i.statusCount>0
          i.effects[PBEffects::Toxic]+=1
          i.effects[PBEffects::Toxic]=[15,i.effects[PBEffects::Toxic]].min
        end
        if i.hasWorkingAbility(:POISONHEAL)                # Antídoto
          pbCommonAnimation("Poison",i,nil)
          if i.effects[PBEffects::HealBlock]==0 && i.hp<i.totalhp
            PBDebug.log("[Habilidad disparada] Antídoto de #{i.pbThis}")
            i.pbRecoverHP((i.totalhp/8).floor,true)
            pbDisplay(_INTL("¡{1} ha recuperado salud gracias al Antídoto!",i.pbThis))
          end
        else
          if !i.hasWorkingAbility(:MAGICGUARD)             # Muro Mágico
            PBDebug.log("[Daño por estado] #{i.pbThis} recibió daño por el veneno/tóxico")
            if i.statusCount==0
              i.pbReduceHP((i.totalhp/8).floor)
            else
              i.pbReduceHP(((i.totalhp*i.effects[PBEffects::Toxic])/16).floor)
            end
            i.pbContinueStatus
          end
        end
      end
      # Quemadura  /  Burn
      if i.status==PBStatuses::BURN
        if !i.hasWorkingAbility(:MAGICGUARD)               # Muro Mágico
          PBDebug.log("[Daño por estado] #{i.pbThis} recibió daño por la quemadura")
          if i.hasWorkingAbility(:HEATPROOF)               # Ignífugo
            PBDebug.log("[Habilidad disparada] Ignífugo de #{i.pbThis}")
            i.pbReduceHP((i.totalhp/(USENEWBATTLEMECHANICS ? 32 : 16)).floor)
          else
            i.pbReduceHP((i.totalhp/(USENEWBATTLEMECHANICS ? 16 : 8)).floor)
          end
        end
        i.pbContinueStatus
      end
      # Helado / Frostbite
      if FROSTBITE_REPLACES_FREEZE
        if i.status==PBStatuses::FROZEN
          if !i.hasWorkingAbility(:MAGICGUARD)               # Muro Mágico
            PBDebug.log("[Daño por estado] #{i.pbThis} recibió daño por el hielo")
            i.pbReduceHP((i.totalhp/16).floor)
          end
          i.pbContinueStatus
        end
      end
      # Pesadilla  /  Nightmare
      if i.effects[PBEffects::Nightmare]
        if i.status==PBStatuses::SLEEP || (i.hasWorkingAbility(:COMATOSE) &&
          isConst?(i.species,PBSpecies,:KOMALA))
          if !i.hasWorkingAbility(:MAGICGUARD)
            PBDebug.log("[Efecto prolongado disparado] Pesadilla de #{i.pbThis}")
            i.pbReduceHP((i.totalhp/4).floor,true)
            pbDisplay(_INTL("¡{1} está inmerso en una Pesadilla!",i.pbThis))
          end
        else
          i.effects[PBEffects::Nightmare]=false
        end
      end
      if i.isFainted?
        return if !i.pbFaint
        next
      end
    end
    # Maldición  /  Curse
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::Curse] && !i.hasWorkingAbility(:MAGICGUARD)
        PBDebug.log("[Efecto prolongado disparado] Maldición de #{i.pbThis}")
        i.pbReduceHP((i.totalhp/4).floor,true)
        pbDisplay(_INTL("¡{1} es víctima de una Maldición!",i.pbThis))
      end
      if i.isFainted?
        return if !i.pbFaint
        next
      end
    end
    # Salazón  /  Salt Cure
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::SaltCure] && !i.hasWorkingAbility(:MAGICGUARD)
        PBDebug.log("[Efecto prolongado disparado] Salazón de #{i.pbThis}")
        @scene.pbDamageAnimation(i,0)
        if i.pbHasType?(:WATER) || i.pbHasType?(:STEEL)
          i.pbReduceHP((i.totalhp/4).floor,true)
          pbDisplay(_INTL("¡Salazón ha herido a {1}!",i.pbThis))
        else
          i.pbReduceHP((i.totalhp/8).floor,true)
          pbDisplay(_INTL("¡Salazón ha herido a {1}!",i.pbThis))
        end
      end
      if i.isFainted?
        return if !i.pbFaint
        next
      end
    end
    # Ataques Multi-turnos (Bind/Clamp/Fire Spin/Magma Storm/Sand Tomb/Whirlpool/Wrap)
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::MultiTurn]>0
        i.effects[PBEffects::MultiTurn]-=1
        movename=PBMoves.getName(i.effects[PBEffects::MultiTurnAttack])
        if i.effects[PBEffects::MultiTurn]==0
          PBDebug.log("[Fin de efecto] El movimiento de trampa #{movename} que afectaba a #{i.pbThis} terminó")
          pbDisplay(_INTL("¡{1} se liberó de {2}!",i.pbThis,movename))
        else
          if isConst?(i.effects[PBEffects::MultiTurnAttack],PBMoves,:BIND)
            pbCommonAnimation("Bind",i,nil)
          elsif isConst?(i.effects[PBEffects::MultiTurnAttack],PBMoves,:CLAMP)
            pbCommonAnimation("Clamp",i,nil)
          elsif isConst?(i.effects[PBEffects::MultiTurnAttack],PBMoves,:FIRESPIN)
            pbCommonAnimation("FireSpin",i,nil)
          elsif isConst?(i.effects[PBEffects::MultiTurnAttack],PBMoves,:MAGMASTORM)
            pbCommonAnimation("MagmaStorm",i,nil)
          elsif isConst?(i.effects[PBEffects::MultiTurnAttack],PBMoves,:SANDTOMB)
            pbCommonAnimation("SandTomb",i,nil)
          elsif isConst?(i.effects[PBEffects::MultiTurnAttack],PBMoves,:WRAP)
            pbCommonAnimation("Wrap",i,nil)
          elsif isConst?(i.effects[PBEffects::MultiTurnAttack],PBMoves,:INFESTATION)
            pbCommonAnimation("Infestation",i,nil)
          elsif isConst?(i.effects[PBEffects::MultiTurnAttack],PBMoves,:THUNDERCAGE)
            pbCommonAnimation("ThunderCage",i,nil)
          elsif isConst?(i.effects[PBEffects::MultiTurnAttack],PBMoves,:CEASELESSEDGE)
            pbCommonAnimation("CeaselessEdge",i,nil)
          else
            pbCommonAnimation("Wrap",i,nil)
          end
          if !i.hasWorkingAbility(:MAGICGUARD)
            PBDebug.log("[Efecto prolongado disparado] #{i.pbThis} ha sido dañado por el movimiento de trampa #{movename}")
            @scene.pbDamageAnimation(i,0)
            amt=(USENEWBATTLEMECHANICS) ? (i.totalhp/8).floor : (i.totalhp/16).floor
            if @battlers[i.effects[PBEffects::MultiTurnUser]].hasWorkingItem(:BINDINGBAND)
              amt=(USENEWBATTLEMECHANICS) ? (i.totalhp/6).floor : (i.totalhp/8).floor
            end
            i.pbReduceHP(amt)
            pbDisplay(_INTL("¡{1} ha sido dañado por {2}!",i.pbThis,movename))
          end
        end
      end
      if i.isFainted?
        return if !i.pbFaint
      end
    end
    # Throat Chop
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::ThroatChop]>0
        i.effects[PBEffects::ThroatChop]-=1
        if i.effects[PBEffects::ThroatChop]==0
          pbDisplay(_INTL("¡{1} puede volver a utilizar movimientos sonoros!",i.pbThis))
          PBDebug.log("[End of effect] #{i.pbThis} is no longer Throat chopped")
        end
      end
    end
    # Octolock
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::Octolock]
        octolock=@battlers[i.effects[PBEffects::OctolockUser]]
        if octolock && !octolock.isFainted?
          downanim=true
          if i.pbCanReduceStatStage?(PBStats::DEFENSE,i,false,self)
            i.pbReduceStat(PBStats::DEFENSE,1,i,false,self,downanim)
            downanim=false
          end
          if i.pbCanReduceStatStage?(PBStats::SPDEF,i,false,self)
            i.pbReduceStat(PBStats::SPDEF,1,i,false,self,downanim)
            downanim=false
          end
        end
      end
    end
    # Mofa  /  Taunt
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::Taunt]>0
        i.effects[PBEffects::Taunt]-=1
        if i.effects[PBEffects::Taunt]==0
          pbDisplay(_INTL("¡El efecto de Mofa de {1} ha pasado!",i.pbThis))
          PBDebug.log("[Fin de efecto] #{i.pbThis} ya no está afectado por Mofa")
        end
      end
    end
    # Otra Vez  /  Encore
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::Encore]>0
        if i.moves[i.effects[PBEffects::EncoreIndex]].id!=i.effects[PBEffects::EncoreMove]
          i.effects[PBEffects::Encore]=0
          i.effects[PBEffects::EncoreIndex]=0
          i.effects[PBEffects::EncoreMove]=0
          PBDebug.log("[Fin de efecto] #{i.pbThis} is no longer encored (encored move was lost)")
        else
          i.effects[PBEffects::Encore]-=1
          if i.effects[PBEffects::Encore]==0 || i.moves[i.effects[PBEffects::EncoreIndex]].pp==0
            i.effects[PBEffects::Encore]=0
            pbDisplay(_INTL("¡Otra Vez ya no hace efecto en {1}!",i.pbThis))
            PBDebug.log("[Fin de efecto] #{i.pbThis} ya no es afectado por Otra Vez")
          end
        end
      end
    end
    # Anulación/Cuerpo Maldito  -  Disable/Cursed Body
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::Disable]>0
        i.effects[PBEffects::Disable]-=1
        if i.effects[PBEffects::Disable]==0
          i.effects[PBEffects::DisableMove]=0
          pbDisplay(_INTL("¡{1} ya no está desactivado!",i.pbThis))
          PBDebug.log("[Fin de efecto] #{i.pbThis} ya no está desactivado")
        end
      end
    end
    # Levitón  /  Magnet Rise
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::MagnetRise]>0
        i.effects[PBEffects::MagnetRise]-=1
        if i.effects[PBEffects::MagnetRise]==0
          pbDisplay(_INTL("¡El electromagnetismo de {1} desapareció!",i.pbThis))
          PBDebug.log("[Fin de efecto] #{i.pbThis} dejó de levitar con Levitón")
        end
      end
    end
    # Telequinesis / Telekinesis (Gen5)
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::Telekinesis]>0
        i.effects[PBEffects::Telekinesis]-=1
        if i.effects[PBEffects::Telekinesis]==0
          pbDisplay(_INTL("¡{1} se liberó de la Telequinesis!",i.pbThis))
          PBDebug.log("[Fin de efecto] #{i.pbThis} ya no está levitando por Telequinesis")
        end
      end
    end
    # Anticura  /  Heal Block
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::HealBlock]>0
        i.effects[PBEffects::HealBlock]-=1
        if i.effects[PBEffects::HealBlock]==0
          pbDisplay(_INTL("¡Anticura ya no hace efecto en {1}!",i.pbThis))
          PBDebug.log("[Fin de efecto] #{i.pbThis} ya no tiene Anticura")
        end
      end
    end
    # Embargo
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::Embargo]>0
        i.effects[PBEffects::Embargo]-=1
        if i.effects[PBEffects::Embargo]==0
          pbDisplay(_INTL("¡{1} puede volver a usar objetos!",i.pbThis(true)))
          PBDebug.log("[Fin de efecto] #{i.pbThis} ya no está afectado por Embargo")
        end
      end
    end
    # Bostezo  /  Yawn
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::Yawn]>0
        i.effects[PBEffects::Yawn]-=1
        if i.effects[PBEffects::Yawn]==0 && i.pbCanSleepYawn?
          PBDebug.log("[Efecto prolongado disparado] Bostezo de #{i.pbThis}")
          i.pbSleep
        end
      end
    end
    # Canto Mortal / Perish Song
    perishSongUsers=[]
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::PerishSong]>0
        i.effects[PBEffects::PerishSong]-=1
        pbDisplay(_INTL("¡El contador de salud de {1} bajó a {2}!",i.pbThis,i.effects[PBEffects::PerishSong]))
        PBDebug.log("[Efecto prolongado disparado] El contador de Canto Mortal de #{i.pbThis} bajó a #{i.effects[PBEffects::PerishSong]}")
        if i.effects[PBEffects::PerishSong]==0
          perishSongUsers.push(i.effects[PBEffects::PerishSongUser])
          i.pbReduceHP(i.hp,true)
        end
      end
      if i.isFainted?
        return if !i.pbFaint
      end
    end
    if perishSongUsers.length>0
      # If all remaining Pokemon fainted by a Perish Song triggered by a single side
      if (perishSongUsers.find_all{|item| pbIsOpposing?(item) }.length==perishSongUsers.length) ||
         (perishSongUsers.find_all{|item| !pbIsOpposing?(item) }.length==perishSongUsers.length)
        pbJudgeCheckpoint(@battlers[perishSongUsers[0]])
      end
    end
    if @decision>0
      pbGainEXP
      return
    end
    # Reflejo  /  Reflect
    for i in 0...2
      if sides[i].effects[PBEffects::Reflect]>0
        sides[i].effects[PBEffects::Reflect]-=1
        if sides[i].effects[PBEffects::Reflect]==0
          pbDisplay(_INTL("¡Los efectos de Reflejo de tu equipo se disiparon!")) if i==0
          pbDisplay(_INTL("¡Los efectos de Reflejo del equipo enemigo se disiparon!")) if i==1
          PBDebug.log("[Fin de efecto] Reflejo del lado del jugador terminó.") if i==0
          PBDebug.log("[Fin de efecto] Reflejo del lado del oponente terminó.") if i==1
        end
      end
    end
    # Pantalla Luz  /  Light Screen
    for i in 0...2
      if sides[i].effects[PBEffects::LightScreen]>0
        sides[i].effects[PBEffects::LightScreen]-=1
        if sides[i].effects[PBEffects::LightScreen]==0
          pbDisplay(_INTL("¡Los efectos de Pantalla de Luz de tu equipo se disiparon!")) if i==0
          pbDisplay(_INTL("¡Los efectos de Pantalla de Luz del equipo enemigo se disiparon!")) if i==1
          PBDebug.log("[Fin de efecto] Pantalla de Luz del lado del jugador se terminó.") if i==0
          PBDebug.log("[Fin de efecto] Pantalla de Luz del lado del oponente se terminó.") if i==1
        end
      end
    end
    # Velo Aurora / Aurora Veil
    for i in 0...2
      if sides[i].effects[PBEffects::AuroraVeil]>0
        sides[i].effects[PBEffects::AuroraVeil]-=1
        if sides[i].effects[PBEffects::AuroraVeil]==0
          pbDisplay(_INTL("¡Los efectos de Velo Aurora de tu equipo se disiparon!")) if i==0
          pbDisplay(_INTL("¡Los efectos de Velo Aurora del equipo enemigo se disiparon!")) if i==1
          PBDebug.log("[Fin de efecto] Velo Aurora del lado del jugador se terminó.") if i==0
          PBDebug.log("[Fin de efecto] Velo Aurora del lado del oponente se terminó.") if i==1
        end
      end
    end
    # Velo Sagrado / Safeguard
    for i in 0...2
      if sides[i].effects[PBEffects::Safeguard]>0
        sides[i].effects[PBEffects::Safeguard]-=1
        if sides[i].effects[PBEffects::Safeguard]==0
          pbDisplay(_INTL("¡Velo Sagrado de tu equipo dejó de hacer efecto!")) if i==0
          pbDisplay(_INTL("¡Velo Sagrado del equipo enemigo dejó de hacer efecto!")) if i==1
          PBDebug.log("[Fin de efecto] Velo Sagrado del lado del jugador terminó.") if i==0
          PBDebug.log("[Fin de efecto] Velo Sagrado del lado del oponente terminó.") if i==1
        end
      end
    end
    # Neblina  /  Mist
    for i in 0...2
      if sides[i].effects[PBEffects::Mist]>0
        sides[i].effects[PBEffects::Mist]-=1
        if sides[i].effects[PBEffects::Mist]==0
          pbDisplay(_INTL("¡Neblina de tu equipo dejó de hacer efecto!")) if i==0
          pbDisplay(_INTL("¡Neblina del equipo enemigo dejó de hacer efecto!")) if i==1
          PBDebug.log("[Fin de efecto] Neblina del lado del jugador terminó.") if i==0
          PBDebug.log("[Fin de efecto] Neblina del lado del oponente terminó.") if i==1
        end
      end
    end
    # Viento Afín / Tailwind
    for i in 0...2
      if sides[i].effects[PBEffects::Tailwind]>0
        sides[i].effects[PBEffects::Tailwind]-=1
        if sides[i].effects[PBEffects::Tailwind]==0
          pbDisplay(_INTL("¡Viento Afín de tu equipo dejó de hacer efecto!")) if i==0
          pbDisplay(_INTL("¡Viento Afín del equipo enemigo dejó de hacer efecto!")) if i==1
          PBDebug.log("[Fin de efecto] Viento Afín del lado del jugador terminó.") if i==0
          PBDebug.log("[Fin de efecto] Viento Afín del lado del oponente terminó.") if i==1
        end
      end
    end
    # Conjuro  /  Lucky Chant
    for i in 0...2
      if sides[i].effects[PBEffects::LuckyChant]>0
        sides[i].effects[PBEffects::LuckyChant]-=1
        if sides[i].effects[PBEffects::LuckyChant]==0
          pbDisplay(_INTL("¡Conjuro de tu equipo dejó de hacer efecto!")) if i==0
          pbDisplay(_INTL("¡Conjuro del equipo enemigo dejó de hacer efecto!")) if i==1
          PBDebug.log("[Fin de efecto] Conjuro del lado del jugador terminó.") if i==0
          PBDebug.log("[Fin de efecto] Conjuro del lado del oponente terminó.") if i==1
        end
      end
    end
    # Final de los movimientos combiandos Voto
    for i in 0...2
      if sides[i].effects[PBEffects::Swamp]>0
        sides[i].effects[PBEffects::Swamp]-=1
        if sides[i].effects[PBEffects::Swamp]==0
          pbDisplay(_INTL("¡El pantano que rodeaba a tu equipo desapareció!")) if i==0
          pbDisplay(_INTL("¡El pantano que rodeaba al equipo enemigo desapareció!")) if i==1
          PBDebug.log("[Fin de efecto] Grass Pledge's swamp ended on the player's side") if i==0
          PBDebug.log("[Fin de efecto] Grass Pledge's swamp ended on the opponent's side") if i==1
        end
      end
      if sides[i].effects[PBEffects::SeaOfFire]>0
        sides[i].effects[PBEffects::SeaOfFire]-=1
        if sides[i].effects[PBEffects::SeaOfFire]==0
          pbDisplay(_INTL("¡El mar de lava que rodeaba a tu equipo desapareció!")) if i==0
          pbDisplay(_INTL("¡El mar de lava que rodeaba al equipo enemigo desapareció!")) if i==1
          PBDebug.log("[Fin de efecto] Fire Pledge's sea of fire ended on the player's side") if i==0
          PBDebug.log("[Fin de efecto] Fire Pledge's sea of fire ended on the opponent's side") if i==1
        end
      end
      if sides[i].effects[PBEffects::Rainbow]>0
        sides[i].effects[PBEffects::Rainbow]-=1
        if sides[i].effects[PBEffects::Rainbow]==0
          pbDisplay(_INTL("¡El arco iris que rodeaba a tu equipo desapareció!")) if i==0
          pbDisplay(_INTL("¡El arco iris que rodeaba al equipo enemigo desapareció!")) if i==1
          PBDebug.log("[Fin de efecto] Water Pledge's rainbow ended on the player's side") if i==0
          PBDebug.log("[Fin de efecto] Water Pledge's rainbow ended on the opponent's side") if i==1
        end
      end
    end
    # Gravedad  /  Gravity
    if @field.effects[PBEffects::Gravity]>0
      @field.effects[PBEffects::Gravity]-=1
      if @field.effects[PBEffects::Gravity]==0
        pbDisplay(_INTL("¡La Gravedad volvió a la normalidad!"))
        PBDebug.log("[Fin de efecto] Se terminó la gravedad intensa")
      end
    end
    # Espacio Raro  /  Trick Room
    if @field.effects[PBEffects::TrickRoom]>0
      for i in priority
        next if i.isFainted?
        if i.hasWorkingItem(:ROOMSERVICE)
          if i.pbCanReduceStatStage?(PBStats::SPEED,i,false,self)
            pbCommonAnimation("UseItem",i,nil)
            i.pbReduceStat(PBStats::SPEED,1,i,false,self,true)
            i.pbConsumeItem
          end
        end
      end
      @field.effects[PBEffects::TrickRoom]-=1
      if @field.effects[PBEffects::TrickRoom]==0
        pbDisplay(_INTL("¡Las dimensiones alteradas volvieron a la normalidad!"))
        PBDebug.log("[Fin de efecto] Espacio Raro ha terminado.")
      end
    end
    # Zona Extraña  /  Wonder Room
    if @field.effects[PBEffects::WonderRoom]>0
      @field.effects[PBEffects::WonderRoom]-=1
      if @field.effects[PBEffects::WonderRoom]==0
        pbDisplay(_INTL("¡Se terminaron los efectos de Zona Extraña!"))
        PBDebug.log("[Fin de efecto] Zona Extraña ha terminado.")
      end
    end
    # Zona Mágica  / Magic Room
    if @field.effects[PBEffects::MagicRoom]>0
      @field.effects[PBEffects::MagicRoom]-=1
      if @field.effects[PBEffects::MagicRoom]==0
        pbDisplay(_INTL("¡Se terminaron los efectos de Zona Mágica!"))
        PBDebug.log("[Fin de efecto] Zona Mágica ha terminado.")
      end
    end
    # Mud Sport
    if @field.effects[PBEffects::MudSportField]>0
      @field.effects[PBEffects::MudSportField]-=1
      if @field.effects[PBEffects::MudSportField]==0
        pbDisplay(_INTL("¡Los efectos de Chapoteolodo se acabaron!"))
        PBDebug.log("[Fin de efecto] Chapoteolodo ha terminado.")
      end
    end
    # Water Sport
    if @field.effects[PBEffects::WaterSportField]>0
      @field.effects[PBEffects::WaterSportField]-=1
      if @field.effects[PBEffects::WaterSportField]==0
        pbDisplay(_INTL("¡Los efectos de Hidrochorro se acabaron!"))
        PBDebug.log("[Fin de efecto] Water Sport ended")
      end
    end
    # Electric Terrain
    if @field.effects[PBEffects::ElectricTerrain]>0
      @field.effects[PBEffects::ElectricTerrain]-=1
      if @field.effects[PBEffects::ElectricTerrain]==0
        pbDisplay(_INTL("¡La corriente eléctrica desapareció del campo!"))
        PBDebug.log("[End of effect] Electric Terrain ended")
      else
        pbDisplay(_INTL("¡La corriente eléctrica permanece en el campo!"))
      end
    end
    # Grassy Terrain
    if @field.effects[PBEffects::GrassyTerrain]>0
      @field.effects[PBEffects::GrassyTerrain]-=1
      if @field.effects[PBEffects::GrassyTerrain]==0
        pbDisplay(_INTL("¡La hierba desapareció del campo!"))
        PBDebug.log("[End of effect] Grassy Terrain ended")
      else
        pbDisplay(_INTL("¡La hierba permanece en el campo!"))
      end
    end
    # Misty Terrain
    if @field.effects[PBEffects::MistyTerrain]>0
      @field.effects[PBEffects::MistyTerrain]-=1
      if @field.effects[PBEffects::MistyTerrain]==0
        pbDisplay(_INTL("¡La niebla desapareció del campo!"))
        PBDebug.log("[End of effect] Misty Terrain ended")
      else
        pbDisplay(_INTL("¡La niebla permanece en el campo!"))
      end
    end
    # Psychic Terrain
    if @field.effects[PBEffects::PsychicTerrain]>0
      @field.effects[PBEffects::PsychicTerrain]-=1
      if @field.effects[PBEffects::PsychicTerrain]==0
        pbDisplay(_INTL("¡La sensación extraña desapareció del campo!"))
        PBDebug.log("[End of effect] Psychic Terrain ended")
      else
        pbDisplay(_INTL("¡La sensación extraña permanece en el campo!"))
      end
    end
    # Cuerpo Maldito / Perish Body
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::PerishBody]>0
        i.effects[PBEffects::PerishBody]-=1
        pbDisplay(_INTL("¡El contador de salud de {1} bajó a {2}!",i.pbThis,i.effects[PBEffects::PerishBody]))
        PBDebug.log("[Lingering effect triggered] #{i.pbThis}'s Perish Body count dropped to #{i.effects[PBEffects::PerishBody]}")
        if i.effects[PBEffects::PerishBody]==0
          i.pbReduceHP(i.hp,true)
        end
      end
      if i.isFainted?
        return if !i.pbFaint
      end
    end
    if @decision>0
      pbGainEXP
      return
    end
    # Alboroto  /  Uproar
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::Uproar]>0
        for j in priority
          if !j.isFainted? && j.status==PBStatuses::SLEEP && !j.hasWorkingAbility(:SOUNDPROOF)
            PBDebug.log("[Efecto prolongado disparado] Alboroto ha despertado a #{j.pbThis(true)}")
            j.pbCureStatus(false)
            pbDisplay(_INTL("¡{1} se despertó por el Alboroto!",j.pbThis))
          end
        end
        i.effects[PBEffects::Uproar]-=1
        if i.effects[PBEffects::Uproar]==0
          pbDisplay(_INTL("{1} se tranquilizó.",i.pbThis))
          PBDebug.log("[Fin de efecto] #{i.pbThis} ya no está haciendo alboroto")
        else
          pbDisplay(_INTL("¡{1} está montando un Alboroto!",i.pbThis))
        end
      end
    end
    # Martillo Colosal  /  Gigaton Hammer
    for i in priority
      next if i.isFainted?
      if i.effects[PBEffects::GigatonHammer]==2
        i.effects[PBEffects::GigatonHammer]=0
      elsif i.effects[PBEffects::GigatonHammer]==1
        i.effects[PBEffects::GigatonHammer]=2
      end
    end
    for i in priority
      next if i.isFainted?
      # Impulso  /  Speed Boost
      # A Pokémon's turncount is 0 if it became active after the beginning of a round
      if i.turncount>0 && i.hasWorkingAbility(:SPEEDBOOST)
        if i.pbIncreaseStatWithCause(PBStats::SPEED,1,i,PBAbilities.getName(i.ability))
          PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(i.ability)} de #{i.pbThis}")
        end
      end
     # Syrup Bomb
        if i.turncount>0 && i.effects[PBEffects::SyrupBomb]>0
          if i.pbCanReduceStatStage?(PBStats::SPEED,i,false,self)
          i.pbReduceStat(PBStats::SPEED,1,i,false,self,true)
          i.effects[PBEffects::SyrupBomb]-=1
        end
      end
      # Oportunista
      if i.hasWorkingAbility(:OPPORTUNIST)
        for j in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
          PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
          i.stages[j]=i.pbOpposing1.stages[j]
        end
        pbDisplay(_INTL("¡{1} copió las nuevas características de {2}!",i.pbThis,i.pbOpposing1.pbThis(true)))
      end
      if i.hasWorkingItem(:MIRRORHERB)
        for j in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
          PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
          i.stages[j]=i.pbOpposing1.stages[j]
        end
        pbDisplay(_INTL("¡{1} copió las nuevas características de {2}!",i.pbThis,i.pbOpposing1.pbThis(true)))
        i.pbConsumeItem
      end
      # Bad Dreams
      if (i.status==PBStatuses::SLEEP && !i.hasWorkingAbility(:MAGICGUARD)) ||
        (i.hasWorkingAbility(:COMATOSE) && isConst?(i.species,PBSpecies,:KOMALA))
        if i.pbOpposing1.hasWorkingAbility(:BADDREAMS) ||
           i.pbOpposing2.hasWorkingAbility(:BADDREAMS)
          PBDebug.log("[Ability triggered] #{i.pbThis}'s opponent's Bad Dreams")
          hploss=i.pbReduceHP((i.totalhp/8).floor,true)
          pbDisplay(_INTL("¡{1} sufre por el mal sueño!",i.pbThis)) if hploss>0
        end
      end
      if i.isFainted?
        return if !i.pbFaint
        next
      end
      # Recogida  /  Pickup
      if i.hasWorkingAbility(:PICKUP) && i.item<=0
        item=0; index=-1; use=0
        for j in 0...4
          next if j==i.index
          if @battlers[j].effects[PBEffects::PickupUse]>use
            item=@battlers[j].effects[PBEffects::PickupItem]
            index=j
            use=@battlers[j].effects[PBEffects::PickupUse]
          end
        end
        if item>0
          i.item=item
          @battlers[index].effects[PBEffects::PickupItem]=0
          @battlers[index].effects[PBEffects::PickupUse]=0
          @battlers[index].pokemon.itemRecycle=0 if @battlers[index].pokemon.itemRecycle==item
          if !@opponent && # In a wild battle
             i.pokemon.itemInitial==0 &&
             @battlers[index].pokemon.itemInitial==item
            i.pokemon.itemInitial=item
            @battlers[index].pokemon.itemInitial=0
          end
          pbDisplay(_INTL("¡{1} ha encontrado una {2}!",i.pbThis,PBItems.getName(item)))
          i.pbBerryCureCheck(true)
        end
      end
      # Cosecha  /  Harvest
      if i.hasWorkingAbility(:HARVEST) && i.item<=0 && i.pokemon.itemRecycle>0
        if pbIsBerry?(i.pokemon.itemRecycle) &&
           (pbWeather==PBWeather::SUNNYDAY ||
           pbWeather==PBWeather::HARSHSUN || pbRandom(10)<5)
          i.item=i.pokemon.itemRecycle
          i.pokemon.itemRecycle=0
          i.pokemon.itemInitial=i.item if i.pokemon.itemInitial==0
          pbDisplay(_INTL("¡{1} ha cosechado una {2}!",i.pbThis,PBItems.getName(i.item)))
          i.pbBerryCureCheck(true)
        end
      end
      # Rumia / Cud Chew
      if i.hasWorkingAbility(:CUDCHEW)
        if i.effects[PBEffects::CudChew]==2
          i.item=i.pokemon.itemRecycle
          i.pokemon.itemRecycle=0
          i.pokemon.itemInitial=i.item if i.pokemon.itemInitial==0
          pbDisplay(_INTL("¡{1} regurgitó la baya y volvió a comérsela!",i.pbThis))
          i.pbActivateBerryEffect
          i.effects[PBEffects::CudChew]=0
        elsif i.effects[PBEffects::CudChew]==1
          i.effects[PBEffects::CudChew]=2
        end
      end
      # Veleta  /  Moody
      if i.hasWorkingAbility(:MOODY)
        randomup=[]; randomdown=[]
        for j in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,PBStats::SPATK,
                  PBStats::SPDEF]
          randomup.push(j) if i.pbCanIncreaseStatStage?(j,i)
          randomdown.push(j) if i.pbCanReduceStatStage?(j,i)
        end
        if randomup.length>0
          PBDebug.log("[Habilidad disparada] Veleta de #{i.pbThis} (suba caractarística)")
          r=pbRandom(randomup.length)
          i.pbIncreaseStatWithCause(randomup[r],2,i,PBAbilities.getName(i.ability))
          for j in 0...randomdown.length
            if randomdown[j]==randomup[r]
              randomdown[j]=nil; randomdown.compact!
              break
            end
          end
        end
        if randomdown.length>0
          PBDebug.log("[Habilidad disparada] Veleta de #{i.pbThis} (baja caractarística)")
          r=pbRandom(randomdown.length)
          i.pbReduceStatWithCause(randomdown[r],1,i,PBAbilities.getName(i.ability))
        end
      end
    end
    for i in priority
      next if i.isFainted?
      # Toxisfera  /  Toxic Orb
      if i.hasWorkingItem(:TOXICORB) && i.status==0 && i.pbCanPoison?(nil,false)
        PBDebug.log("[Objeto disparado] Toxisfera de #{i.pbThis}")
        i.pbPoison(nil,_INTL("¡{1} ha sido gravemente envenenado por la {2}!",i.pbThis,
           PBItems.getName(i.item)),true)
      end
      # Llamasfera  /  Flame Orb
      if i.hasWorkingItem(:FLAMEORB) && i.status==0 && i.pbCanBurn?(nil,false)
        PBDebug.log("[Objeto disparado] Llamasfera de #{i.pbThis}")
        i.pbBurn(nil,_INTL("¡{1} ha sido quemado por la {2}!",i.pbThis,PBItems.getName(i.item)))
      end
      # Toxiestrella  /  Sticky Barb
      if i.hasWorkingItem(:STICKYBARB) && !i.hasWorkingAbility(:MAGICGUARD)
        PBDebug.log("[Objeto disparado] Toxiestrella de #{i.pbThis}")
        @scene.pbDamageAnimation(i,0)
        i.pbReduceHP((i.totalhp/8).floor)
        pbDisplay(_INTL("¡{1} ha sido dañado por la {2}!",i.pbThis,PBItems.getName(i.item)))
      end
      if i.isFainted?
        return if !i.pbFaint
      end
    end
    # Slow Start's end message
    if i.hasWorkingAbility(:SLOWSTART) && i.turncount==6
      pbDisplay(_INTL("¡{1} vuelve a ir a por todas!",i.pbThis))
    end
    for i in priority
      next if i.isFainted?
      # Hunger Switch
      if i.hasWorkingAbility(:HUNGERSWITCH) && isConst?(i.species,PBSpecies,:MORPEKO)
        i.form=(i.form==0) ? 1 : 0
        i.pbUpdate(true)
        scene.pbChangePokemon(i,i.pokemon)
        pbDisplay(_INTL("¡{1} se transformó!",i.pbThis))
        PBDebug.log("[Form changed] #{i.pbThis} changed to form #{i.form}")
      end
    end
    # Revisión de formas
    for i in 0...4
      next if @battlers[i].isFainted?
      @battlers[i].pbCheckForm
    end
    pbGainEXP
    pbSwitch
    return if @decision>0
    for i in priority
      next if i.isFainted?
      i.pbAbilitiesOnSwitchIn(false)
    end
    # Healing Wish/Lunar Dance - should go here
    # Spikes/Toxic Spikes/Stealth Rock - should go here (in order of their 1st use)
    for i in 0...4
      if @battlers[i].turncount>0 && @battlers[i].hasWorkingAbility(:TRUANT)
        @battlers[i].effects[PBEffects::Truant]=!@battlers[i].effects[PBEffects::Truant]
      end
      if @battlers[i].effects[PBEffects::LockOn]>0   # Also Mind Reader
        @battlers[i].effects[PBEffects::LockOn]-=1
        @battlers[i].effects[PBEffects::LockOnPos]=-1 if @battlers[i].effects[PBEffects::LockOn]==0
      end
      @battlers[i].effects[PBEffects::ShellTrap]=false
      @battlers[i].effects[PBEffects::Flinch]=false
      @battlers[i].effects[PBEffects::BurningJealousy] = false
      @battlers[i].effects[PBEffects::LashOut] = false
      # Commander && Follow Me
      if(pbIsDoubleBattler?(i) && @battlers[i].pbPartner.effects[PBEffects::Commander] == 0)
        @battlers[i].effects[PBEffects::FollowMe]=0
      elsif (!pbIsDoubleBattler?(i))
        @battlers[i].effects[PBEffects::FollowMe]=0
      end
      @battlers[i].effects[PBEffects::HelpingHand]=false
      @battlers[i].effects[PBEffects::MagicCoat]=false
      @battlers[i].effects[PBEffects::Snatch]=false
      @battlers[i].effects[PBEffects::Charge]-=1 if @battlers[i].effects[PBEffects::Charge]>0  && !USENEWBATTLEMECHANICS
      @battlers[i].lastHPLost=0
      @battlers[i].tookDamage=false
      @battlers[i].lastAttacker.clear
      @battlers[i].lastTarget=0
      @battlers[i].effects[PBEffects::Counter]=-1
      @battlers[i].effects[PBEffects::CounterTarget]=-1
      @battlers[i].effects[PBEffects::MirrorCoat]=-1
      @battlers[i].effects[PBEffects::MirrorCoatTarget]=-1
    end
    for i in 0...2
      if !@sides[i].effects[PBEffects::EchoedVoiceUsed]
        @sides[i].effects[PBEffects::EchoedVoiceCounter]=0
      end
      @sides[i].effects[PBEffects::EchoedVoiceUsed]=false
      @sides[i].effects[PBEffects::MatBlock]= false
      @sides[i].effects[PBEffects::QuickGuard]=false
      @sides[i].effects[PBEffects::WideGuard]=false
      @sides[i].effects[PBEffects::CraftyShield]=false
      @sides[i].effects[PBEffects::Round]=0
    end
    @field.effects[PBEffects::FusionBolt]=false
    @field.effects[PBEffects::FusionFlare]=false
    @field.effects[PBEffects::IonDeluge]=false
    @field.effects[PBEffects::PlasmaFists]=false
    @field.effects[PBEffects::FairyLock]-=1 if @field.effects[PBEffects::FairyLock]>0
    # invalidate stored priority
    @usepriority=false
  end

################################################################################
# End of battle. / Final de la batalla
################################################################################
  def pbEndOfBattle(canlose=false)
    case @decision
    ##### VICTORIA #####
    when 1
      PBDebug.log("")
      PBDebug.log("***Jugador ganó***")
      if @opponent
        @scene.pbTrainerBattleSuccess
        if @opponent.is_a?(Array)
          pbDisplayPaused(_INTL("¡{1} ha derrotado a {2} y {3}!",self.pbPlayer.name,@opponent[0].fullname,@opponent[1].fullname))
        else
          pbDisplayPaused(_INTL("¡{1} ha derrotado a<br>{2}!",self.pbPlayer.name,@opponent.fullname))
        end
        @scene.pbShowOpponent(0)
        pbDisplayPaused(@endspeech.gsub(/\\[Pp][Nn]/,self.pbPlayer.name))
        if @opponent.is_a?(Array)
          @scene.pbHideOpponent
          @scene.pbShowOpponent(1)
          pbDisplayPaused(@endspeech2.gsub(/\\[Pp][Nn]/,self.pbPlayer.name))
        end
        # Se calcula el dinero ganado por la victoria
        if @internalbattle && !@rules["noMoney"]
          tmoney=0
          if @opponent.is_a?(Array)             # Batallas dobles
            maxlevel1=0; maxlevel2=0; limit=pbSecondPartyBegin(1)
            for i in 0...limit
              if @party2[i]
                maxlevel1=@party2[i].level if maxlevel1<@party2[i].level
              end
              if @party2[i+limit]
                maxlevel2=@party2[i+limit].level if maxlevel1<@party2[i+limit].level
              end
            end
            tmoney+=maxlevel1*@opponent[0].moneyEarned
            tmoney+=maxlevel2*@opponent[1].moneyEarned
          else
            maxlevel=0
            for i in @party2
              next if !i
              maxlevel=i.level if maxlevel<i.level
            end
            tmoney+=maxlevel*@opponent.moneyEarned
          end
          # If Amulet Coin/Luck Incense's effect applies, double money earned
          tmoney*=2 if @amuletcoin
          # If Happy Hour's effect applies, double money earned
          tmoney*=2 if @doublemoney
          oldmoney=self.pbPlayer.money
          self.pbPlayer.money+=tmoney
          moneygained=self.pbPlayer.money-oldmoney
          if moneygained>0
            pbDisplayPaused(_INTL("¡{1} ha obtenido ${2}<br>por la victoria!",self.pbPlayer.name,tmoney))
          end
        end
      end
      if @internalbattle && @extramoney>0
        @extramoney*=2 if @amuletcoin
        @extramoney*=2 if @doublemoney
        oldmoney=self.pbPlayer.money
        self.pbPlayer.money+=@extramoney
        moneygained=self.pbPlayer.money-oldmoney
        if moneygained>0
          pbDisplayPaused(_INTL("¡{1} ha recogido ${2}!",self.pbPlayer.name,@extramoney))
        end
      end
      for pkmn in @snaggedpokemon
        pbStorePokemon(pkmn)
        self.pbPlayer.shadowcaught=[] if !self.pbPlayer.shadowcaught
        self.pbPlayer.shadowcaught[pkmn.species]=true
      end
      @snaggedpokemon.clear
    ##### DERROTA, EMPATE #####
    when 2, 5
      PBDebug.log("")
      PBDebug.log("***Jugador perdió***") if @decision==2
      PBDebug.log("***Jugador empató con oponente***") if @decision==5
      if @internalbattle
        pbDisplayPaused(_INTL("¡{1} no tiene más Pokémon que puedan pelear!",self.pbPlayer.name))
        moneylost=pbMaxLevelFromIndex(0)   # Player's Pokémon only, not partner's
        multiplier=[8,16,24,36,48,60,80,100,120]
        moneylost*=multiplier[[multiplier.length-1,self.pbPlayer.numbadges].min]
        moneylost=self.pbPlayer.money if moneylost>self.pbPlayer.money
        moneylost=0 if $game_switches[NO_MONEY_LOSS] || @rules["noMoney"]
        oldmoney=self.pbPlayer.money
        self.pbPlayer.money-=moneylost
        lostmoney=oldmoney-self.pbPlayer.money
        if @opponent
          if @opponent.is_a?(Array)
            pbDisplayPaused(_INTL("¡{1} ha perdido contra {2} y {3}!",self.pbPlayer.name,@opponent[0].fullname,@opponent[1].fullname))
          else
            pbDisplayPaused(_INTL("¡{1} ha perdido contra<br>{2}!",self.pbPlayer.name,@opponent.fullname))
          end
          if moneylost>0
            pbDisplayPaused(_INTL("{1} ha entregado ${2} al ganador...",self.pbPlayer.name,lostmoney))
            pbDisplayPaused(_INTL("...")) if !canlose
          end
        else
          if moneylost>0
            pbDisplayPaused(_INTL("{1} entró en pánico y dejó caer<br>${2}...",self.pbPlayer.name,lostmoney))
            pbDisplayPaused(_INTL("...")) if !canlose
          end
        end
        pbDisplayPaused(_INTL("¡{1} se desmayó!",self.pbPlayer.name)) if !canlose
      elsif @decision==2
        @scene.pbShowOpponent(0)
        pbDisplayPaused(@endspeechwin.gsub(/\\[Pp][Nn]/,self.pbPlayer.name))
        if @opponent.is_a?(Array)
          @scene.pbHideOpponent
          @scene.pbShowOpponent(1)
          pbDisplayPaused(@endspeechwin2.gsub(/\\[Pp][Nn]/,self.pbPlayer.name))
        end
      end
    end
    # Pass on Pokérus within the party
    infected=[]
    for i in 0...$Trainer.party.length
      if $Trainer.party[i].pokerusStage==1
        infected.push(i)
      end
    end
    if infected.length>=1
      for i in infected
        strain=$Trainer.party[i].pokerus/16
        if i>0 && $Trainer.party[i-1].pokerusStage==0
          $Trainer.party[i-1].givePokerus(strain) if rand(3)==0
        end
        if i<$Trainer.party.length-1 && $Trainer.party[i+1].pokerusStage==0
          $Trainer.party[i+1].givePokerus(strain) if rand(3)==0
        end
      end
    end
    @scene.pbEndBattle(@decision)
    for i in @battlers
      i.pbResetForm
      if i.hasWorkingAbility(:NATURALCURE)
        i.status=0
      end
    end
    if @necrozmaVar[1]!=-1
      $Trainer.party[@necrozmaVar[0]].form = @necrozmaVar[1]
    end
    for i in $Trainer.party
      i.setItem(i.itemInitial)
      i.itemInitial=i.itemRecycle=0
      i.belch=false
    end
    if USENEWBATTLEMECHANICS # BES-T Recuperar objetos usados excepto Bayas
      for i in $Trainer.party 
        itemToReplenish = $consumedItems[i]
        i.item = itemToReplenish if itemToReplenish && i.item<=0
      end
      $consumedItems.clear
    end
    $PokemonTemp.battle_rules={}
    return @decision
  end
end
