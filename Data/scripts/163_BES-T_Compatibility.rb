################################################################################
#Classes que cambiaron de v16 a v17
################################################################################
class PokemonParty_Scene < PokemonScreen_Scene; end
class PokemonPartyScreen < PokemonScreen; end
class PokemonSave_Scene < PokemonSaveScene; end
class PokemonSaveScreen < PokemonSave; end
class PokemonLoad_Scene < PokemonLoadScene; end
class PokemonLoadScreen < PokemonLoad; end
class PokemonSummary_Scene < PokemonSummaryScene; end
class PokemonSummaryScreen < PokemonSummary; end
class PokemonTrade_Scene < PokemonTradeScene; end
class PokemonEggHatch_Scene < PokemonEggHatchScene; end
class PokemonOption_Scene < PokemonOptionScene; end
class PokemonOptionScreen < PokemonOption; end
class PokemonTrainerCard_Scene < PokemonTrainerCardScene; end
class PokemonTrainerCardScreen < PokemonTrainerCard; end
class PokemonPokegear_Scene < Scene_Pokegear; end
class PokemonRegionMap_Scene < PokemonRegionMapScene; end
class PokemonRegionMapScreen < PokemonRegionMap; end
class PokemonJukebox_Scene < Scene_Jukebox; end
class MoveRelearner_Scene < MoveRelearnerScene; end
class PokemonMart_Scene < PokemonMartScene; end
class HallOfFame_Scene < HallOfFameScene; end
################################################################################

def pbGetFSpeciesFromForm(species,form=0)
  return species
end

def pbGetSpeciesFromFSpecies(species)
  return [species,0]
end

class PokeBattle_Pokemon
  def fSpecies
    return pbGetFSpeciesFromForm(@species,self.form)
  end
end

def pbPlayCrySpecies(pokemon,form=0,volume=90,pitch=nil)
  return if !pokemon
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon = getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Numeric)
    pkmnwav = pbCryFile(pokemon,form)
    if pkmnwav
      pbSEPlay(RPG::AudioFile.new(pkmnwav,volume,(pitch) ? pitch : 100)) rescue nil
    end
  end
end

def pbCryFile(pokemon,form=0)
  return nil if !pokemon
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon = getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Numeric)
    filename = sprintf("Cries/%sCry_%d",getConstantName(PBSpecies,pokemon),form) rescue nil
    if !pbResolveAudioSE(filename)
      filename = sprintf("Cries/%03dCry_%d",pokemon,form)
      if !pbResolveAudioSE(filename)
        filename = sprintf("Cries/%sCry",getConstantName(PBSpecies,pokemon)) rescue nil
        if !pbResolveAudioSE(filename)
          filename = sprintf("Cries/%03dCry",pokemon)
        end
      end
    end
    return filename if pbResolveAudioSE(filename)
  elsif !pokemon.egg?
    form = (pokemon.form rescue 0)
    filename = sprintf("Cries/%sCry_%d",getConstantName(PBSpecies,pokemon.species),form) rescue nil
    if !pbResolveAudioSE(filename)
      filename = sprintf("Cries/%03dCry_%d",pokemon.species,form)
      if !pbResolveAudioSE(filename)
        filename = sprintf("Cries/%sCry",getConstantName(PBSpecies,pokemon.species)) rescue nil
        if !pbResolveAudioSE(filename)
          filename = sprintf("Cries/%03dCry",pokemon.species)
        end
      end
    end
    return filename if pbResolveAudioSE(filename)
  end
  return nil
end

def pbAfterBattle(decision,canlose)
  for i in $Trainer.party
    (i.makeUnmega rescue nil); (i.makeUnprimal rescue nil)
  end
  if $PokemonGlobal.partner
    pbHealAll
    for i in $PokemonGlobal.partner[3]
      i.heal
      (i.makeUnmega rescue nil); (i.makeUnprimal rescue nil)
    end
  end
  if decision==2 || decision==5 # if loss or draw
    if canlose
      for i in $Trainer.party; i.heal; end
      for i in 0...10
        Graphics.update
      end
    end
  end
  Events.onEndBattle.trigger(nil,decision,canlose)
end

class PokemonTemp
  attr_accessor :pokemonFormsData
  attr_accessor :surfJump
  attr_accessor :endSurf
  attr_accessor :forceSingleBattle
  
  alias initialize_new initialize
  def initialize
    initialize_new
    @pokemonFormsData       = nil
    @surfJump               = nil
    @endSurf                = nil
    @forceSingleBattle      = false
  end
  
end

################################################################################
#De v16 a v18
################################################################################
class PokemonBagScreen
  def pbChooseItemScreen(proc=nil)
    oldlastpocket = @bag.lastpocket
    oldchoices = @bag.getAllChoices
    @scene.pbStartScene(@bag,true,proc)
    item = @scene.pbChooseItem
    @scene.pbEndScene
    @bag.lastpocket = oldlastpocket
    @bag.setAllChoices(oldchoices)
    return item
  end
end

class PokemonBag
  def getAllChoices
    ret = @choices.clone
    for i in 0...@choices.length; @choices[i] = 0; end
    return ret
  end

  def setAllChoices(choices)
    @choices = choices
  end
end

def pbMessage(message,commands=nil,cmdIfCancel=0,skin=nil,defaultCmd=0,&block)
  Kernel.pbMessage(message,commands=nil,cmdIfCancel=0,skin=nil,defaultCmd=0,&block)
end

def pbShowCommandsWithHelp(msgwindow, commands, help, cmdIfCancel = 0, defaultCmd = 0)
  Kernel.pbShowCommandsWithHelp(msgwindow,commands,help,cmdIfCancel=0,defaultCmd=0)
end

def pbShowCommands(msgwindow, commands = nil, cmdIfCancel = 0, defaultCmd = 0)
  Kernel.pbShowCommands(msgwindow,commands=nil,cmdIfCancel=0,defaultCmd=0)
end

def pbMessageChooseNumber(message, params, &block)
  Kernel.pbMessageChooseNumber(message,params,&block)
end

def pbConfirmMessage(message, &block)
  Kernel.pbConfirmMessage(message,&block)
end

def pbConfirmMessageSerious(message, &block)
  Kernel.pbConfirmMessageSerious(message,&block)
end

def pbCreateStatusWindow(viewport = nil)
  Kernel.pbCreateStatusWindow(viewport=nil)
end

def pbCreateMessageWindow(viewport = nil, skin = nil)
  Kernel.pbCreateMessageWindow(viewport=nil,skin=nil)
end

def pbDisposeMessageWindow(msgwindow)
  Kernel.pbDisposeMessageWindow(msgwindow)
end

def pbMessageDisplay(msgwindow, message, letterbyletter = true, commandProc = nil)
  Kernel.pbMessageDisplay(msgwindow,message,letterbyletter=true,commandProc=nil)
end

def pbFreeText(msgwindow, currenttext, passwordbox, maxlength, width = 240)
  Kernel.pbFreeText(msgwindow,currenttext,passwordbox,maxlength,width=240)
end

def pbMessageFreeText(message, currenttext, passwordbox, maxlength, width = 240, &block)
  Kernel.pbMessageFreeText(message,currenttext,passwordbox,maxlength,width=240,&block)
end


SCREEN_WIDTH                = DEFAULTSCREENWIDTH
SCREEN_HEIGHT               = DEFAULTSCREENHEIGHT
SCREEN_ZOOM                 = DEFAULTSCREENZOOM
BORDER_FULLY_SHOWS          = FULLSCREENBORDERCROP
BORDER_WIDTH                = BORDERWIDTH
BORDER_HEIGHT               = BORDERHEIGHT
MAP_VIEW_MODE               = MAPVIEWMODE
MAXIMUM_LEVEL               = MAXIMUMLEVEL
EGG_LEVEL                   = EGGINITIALLEVEL
SHINY_POKEMON_CHANCE        = SHINYPOKEMONCHANCE
POKERUS_CHANCE              = POKERUSCHANCE
TIME_SHADING                = ENABLESHADING
POISON_IN_FIELD             = POISONINFIELD
POISON_FAINT_IN_FIELD       = POISONFAINTINFIELD
FISHING_AUTO_HOOK           = FISHINGAUTOHOOK
DIVING_SURFACE_ANYWHERE     = DIVINGSURFACEANYWHERE
NEW_BERRY_PLANTS            = NEWBERRYPLANTS
INFINITE_TMS                = INFINITETMS
SAFARI_STEPS                = SAFARISTEPS
BUG_CONTEST_TIME            = BUGCONTESTTIME
NO_SIGNPOSTS                = NOSIGNPOSTS
INITIAL_MONEY               = INITIALMONEY
MAX_MONEY                   = MAXMONEY
MAX_COINS                   = MAXCOINS
MAX_PLAYER_NAME_SIZE        = 12
RIVAL_NAMES                 = RIVALNAMES
NUM_BADGES_BOOST_ATTACK     = BADGESBOOSTATTACK
NUM_BADGES_BOOST_DEFENSE    = BADGESBOOSTDEFENSE
NUM_BADGES_BOOST_SPATK      = BADGESBOOSTSPEED
NUM_BADGES_BOOST_SPDEF      = BADGESBOOSTSPATK
NUM_BADGES_BOOST_SPEED      = BADGESBOOSTSPDEF
FIELD_MOVES_COUNT_BADGES    = HIDDENMOVESCOUNTBADGES
BADGE_FOR_CUT               = BADGEFORCUT
BADGE_FOR_FLASH             = 2
BADGE_FOR_ROCKSMASH         = BADGEFORROCKSMASH
BADGE_FOR_SURF              = BADGEFORSURF
BADGE_FOR_FLY               = BADGEFORFLY
BADGE_FOR_STRENGTH          = BADGEFORSTRENGTH 
BADGE_FOR_DIVE              = BADGEFORDIVE
BADGE_FOR_WATERFALL         = BADGEFORWATERFALL
MOVE_CATEGORY_PER_MOVE      = USEMOVECATEGORY
NEWEST_BATTLE_MECHANICS     = USENEWBATTLEMECHANICS
SCALED_EXP_FORMULA          = USESCALEDEXPFORMULA
SPLIT_EXP_BETWEEN_GAINERS   = NOSPLITEXP
ENABLE_CRITICAL_CAPTURES    = USECRITICALCAPTURE
GAIN_EXP_FOR_CAPTURE        = GAINEXPFORCAPTURE
BAG_MAX_POCKET_SIZE         = MAXPOCKETSIZE
BAG_MAX_PER_SLOT            = BAGMAXPERSLOT
BAG_POCKET_AUTO_SORT        = POCKETAUTOSORT
REGION_MAP_EXTRAS           = REGIONMAPEXTRAS
NUM_STORAGE_BOXES           = STORAGEBOXES
USE_CURRENT_REGION_DEX      = DEXDEPENDSONLOCATION
DEX_SHOWS_ALL_FORMS         = ALWAYSSHOWALLFORMS
DEXES_WITH_OFFSETS          = DEXINDEXOFFSETS
POKE_RADAR_ENCOUNTERS       = POKERADAREXCLUSIVES
FISHING_BEGIN_COMMON_EVENT  = FISHINGBEGINCOMMONEVENT
FISHING_END_COMMON_EVENT    = FISHINGBEGINCOMMONEVENT

module Settings
  SCREEN_WIDTH                = DEFAULTSCREENWIDTH
  SCREEN_HEIGHT               = DEFAULTSCREENHEIGHT
  SCREEN_SCALE  =               DEFAULTSCREENZOOM
end
