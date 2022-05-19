module PBEvolution
  Unknown           = 0 # Do not use
  Happiness         = 1
  HappinessDay      = 2
  HappinessNight    = 3
  Level             = 4
  Trade             = 5
  TradeItem         = 6
  Item              = 7
  AttackGreater     = 8  # Tyrogue
  AtkDefEqual       = 9  # Tyrogue
  DefenseGreater    = 10 # Tyrogue
  Silcoon           = 11 # Wurmple
  Cascoon           = 12 # Wurmple
  Ninjask           = 13 # Nincada
  Shedinja          = 14 # Nincada
  Beauty            = 15 # Feebas
  ItemMale          = 16
  ItemFemale        = 17
  DayHoldItem       = 18
  NightHoldItem     = 19
  HasMove           = 20
  HasInParty        = 21
  LevelMale         = 22
  LevelFemale       = 23
  Location          = 24
  TradeSpecies      = 25
  LevelDay          = 26
  LevelNight        = 27
  LevelDarkInParty  = 28
  LevelRain         = 29
  HappinessMoveType = 30
  LevelForm0        = 31
  LevelForm1        = 32
  LevelForm2        = 33
  ItemForm0         = 34
  ItemForm1         = 35
  ItemForm2         = 36
  HappinessForm0    = 37
  HappinessForm1    = 38
  HappinessForm2    = 39
  LevelDayForm0     = 40
  LevelDayForm1     = 41
  LevelDayForm2     = 42
  LevelNightForm0   = 43
  LevelNightForm1   = 44
  LevelNightForm2   = 45
  HoldItemForm0     = 46
  HoldItemForm1     = 47
  HoldItemForm2     = 48
  LevelDayTime      = 49 # Rockruff
  Crits             = 50 # Farfetch'd de Galar
  HasMoveForm0      = 51
  HasMoveForm1      = 52
  HasMoveForm2      = 53

  EVONAMES=["Unknown",
     "Happiness","HappinessDay","HappinessNight","Level","Trade",
     "TradeItem","Item","AttackGreater","AtkDefEqual","DefenseGreater",
     "Silcoon","Cascoon","Ninjask","Shedinja","Beauty",
     "ItemMale","ItemFemale","DayHoldItem","NightHoldItem","HasMove",
     "HasInParty","LevelMale","LevelFemale","Location","TradeSpecies",
     "LevelDay","LevelNight","LevelDarkInParty","LevelRain","HappinessMoveType",
     "LevelForm0","LevelForm1","LevelForm2","ItemForm0","ItemForm1","ItemForm2",
     "HappinessForm0","HappinessForm1","HappinessForm2","LevelDayForm0",
     "LevelDayForm1","LevelDayForm2","LevelNightForm0","LevelNightForm1",
     "LevelNightForm2","HoldItemForm0","HoldItemForm1","HoldItemForm2",
     "LevelDayTime","Crits","HasMoveForm0","HasMoveForm1","HasMoveForm2"
  ]

  # 0 = no parameter
  # 1 = Positive integer
  # 2 = Item internal name
  # 3 = Move internal name
  # 4 = Species internal name
  # 5 = Type internal name
  EVOPARAM=[0,    # Desconocido (no usar)
     0,0,0,1,0,   # Happiness, HappinessDay, HappinessNight, Level, Trade
     2,2,1,1,1,   # TradeItem, Item, AttackGreater, AtkDefEqual, DefenseGreater
     1,1,1,1,1,   # Silcoon, Cascoon, Ninjask, Shedinja, Beauty
     2,2,2,2,3,   # ItemMale, ItemFemale, DayHoldItem, NightHoldItem, HasMove
     4,1,1,1,4,   # HasInParty, LevelMale, LevelFemale, Location, TradeSpecies
     1,1,1,1,5,   # LevelDay, LevelNight, LevelDarkInParty, LevelRain, HappinessMoveType
     1,1,1,2,2,   # LevelForm0, LevelForm1, LevelForm2, ItemForm0, ItemForm1
     2,0,0,0,1,   # ItemForm2, HappinessForm0, HappinessForm1, HappinessForm2, LevelDayForm0
     1,1,1,1,1,   # LevelDayForm1, LevelDayForm2, LevelNightForm0, LevelNightForm1, LevelNightForm2
     2,2,2,1,0,   # HoldItemForm0, HoldItemForm1, HoldItemForm2, LevelDayTime, Crits
     3,3,3        # HasMoveForm0, HasMoveForm1, HasMoveForm2
]
end



#===============================================================================
# Funciones de ayuda a la evolución
#===============================================================================
def pbGetEvolvedFormData(species)
  ret=[]
  _EVOTYPEMASK=0x3F
  _EVODATAMASK=0xC0
  _EVONEXTFORM=0x00
  pbRgssOpen("Data/evolutions.dat","rb"){|f|
     f.pos=(species-1)*8
     offset=f.fgetdw
     length=f.fgetdw
     if length>0
       f.pos=offset
       i=0; loop do break unless i<length
         evo=f.fgetb
         evonib=evo&_EVOTYPEMASK
         level=f.fgetw
         poke=f.fgetw
         if (evo&_EVODATAMASK)==_EVONEXTFORM
           ret.push([evonib,level,poke])
         end
         i+=5
       end
     end
  }
  return ret
end

def pbEvoDebug()
  _EVOTYPEMASK=0x3F
  _EVODATAMASK=0xC0
  pbRgssOpen("Data/evolutions.dat","rb"){|f|
     for species in 1..PBSpecies.maxValue
       f.pos=(species-1)*8
       offset=f.fgetdw
       length=f.fgetdw
       puts PBSpecies.getName(species)
       if length>0
         f.pos=offset
         i=0; loop do break unless i<length
           evo=f.fgetb
           evonib=evo&_EVOTYPEMASK
           level=f.fgetw
           poke=f.fgetw
           puts sprintf("type=%02X, data=%02X, name=%s, level=%d",
              evonib,evo&_EVODATAMASK,PBSpecies.getName(poke),level)
           if poke==0
             p f.eof?
             break
           end
           i+=5
         end
       end
     end
  }
end

def pbGetPreviousForm(species)
  _EVOTYPEMASK=0x3F
  _EVODATAMASK=0xC0
  _EVOPREVFORM=0x40
  pbRgssOpen("Data/evolutions.dat","rb"){|f|
     f.pos=(species-1)*8
     offset=f.fgetdw
     length=f.fgetdw
     if length>0
       f.pos=offset
       i=0; loop do break unless i<length
         evo=f.fgetb
         evonib=evo&_EVOTYPEMASK
         level=f.fgetw
         poke=f.fgetw
         if (evo&_EVODATAMASK)==_EVOPREVFORM
           return poke
         end
         i+=5
       end
     end
  }
  return species
end

def pbGetMinimumLevel(species)
  ret=-1
  _EVOTYPEMASK=0x3F
  _EVODATAMASK=0xC0
  _EVOPREVFORM=0x40
  pbRgssOpen("Data/evolutions.dat","rb"){|f|
    f.pos=(species-1)*8
    offset=f.fgetdw
    length=f.fgetdw
    if length>0
      f.pos=offset
      i=0; loop do break unless i<length
        evo=f.fgetb
        evonib=evo&_EVOTYPEMASK
        level=f.fgetw
        poke=f.fgetw
        if poke<=PBSpecies.maxValue && 
           (evo&_EVODATAMASK)==_EVOPREVFORM &&    # la pre evolución
           [PBEvolution::Level,PBEvolution::LevelMale,
           PBEvolution::LevelFemale,PBEvolution::AttackGreater,
           PBEvolution::AtkDefEqual,PBEvolution::DefenseGreater,
           PBEvolution::Silcoon,PBEvolution::Cascoon,
           PBEvolution::Ninjask,PBEvolution::Shedinja,
           PBEvolution::LevelDay,PBEvolution::LevelNight,
           PBEvolution::LevelDarkInParty,PBEvolution::LevelRain,
           PBEvolution::LevelForm0,PBEvolution::LevelForm1,
           PBEvolution::LevelForm2,PBEvolution::LevelDayForm0,
           PBEvolution::LevelDayForm1,PBEvolution::LevelDayForm2,
           PBEvolution::LevelNightForm0,PBEvolution::LevelNightForm1,
           PBEvolution::LevelNightForm2,PBEvolution::LevelDayTime].include?(evonib)
          ret=(ret==-1) ? level : [ret,level].min
          break
        end
        i+=5
      end
    end
  }
  return (ret==-1) ? 1 : ret
end

def pbGetBabySpecies(species,item1=-1,item2=-1)
  ret=species
  _EVOTYPEMASK=0x3F
  _EVODATAMASK=0xC0
  _EVOPREVFORM=0x40
  pbRgssOpen("Data/evolutions.dat","rb"){|f|
     f.pos=(species-1)*8
     offset=f.fgetdw
     length=f.fgetdw
     if length>0
       f.pos=offset
       i=0; loop do break unless i<length
         evo=f.fgetb
         evonib=evo&_EVOTYPEMASK
         level=f.fgetw
         poke=f.fgetw
         if poke<=PBSpecies.maxValue && (evo&_EVODATAMASK)==_EVOPREVFORM # evolved from
           if item1>=0 && item2>=0
             dexdata=pbOpenDexData
             pbDexDataOffset(dexdata,poke,54)
             incense=dexdata.fgetw
             dexdata.close
             ret=poke if item1==incense || item2==incense
           else
             ret=poke
           end
           break
         end
         i+=5
       end
     end
  }
  if ret!=species
    ret=pbGetBabySpecies(ret)
  end
  return ret
end



#===============================================================================
# Animación de la evolución
#===============================================================================
class SpriteMetafile
  VIEWPORT      = 0
  TONE          = 1
  SRC_RECT      = 2
  VISIBLE       = 3
  X             = 4
  Y             = 5
  Z             = 6
  OX            = 7
  OY            = 8
  ZOOM_X        = 9
  ZOOM_Y        = 10
  ANGLE         = 11
  MIRROR        = 12
  BUSH_DEPTH    = 13
  OPACITY       = 14
  BLEND_TYPE    = 15
  COLOR         = 16
  FLASHCOLOR    = 17
  FLASHDURATION = 18
  BITMAP        = 19

  def length
    return @metafile.length
  end

  def [](i)
    return @metafile[i]
  end

  def initialize(viewport=nil)
    @metafile=[]
    @values=[
       viewport,
       Tone.new(0,0,0,0),Rect.new(0,0,0,0),
       true,
       0,0,0,0,0,100,100,
       0,false,0,255,0,
       Color.new(0,0,0,0),Color.new(0,0,0,0),
       0
    ]
  end

  def disposed?
    return false
  end

  def dispose
  end

  def flash(color,duration)
    if duration>0
      @values[FLASHCOLOR]=color.clone
      @values[FLASHDURATION]=duration
      @metafile.push([FLASHCOLOR,color])
      @metafile.push([FLASHDURATION,duration])
    end
  end

  def x
    return @values[X]
  end

  def x=(value)
    @values[X]=value
    @metafile.push([X,value])
  end

  def y
    return @values[Y]
  end

  def y=(value)
    @values[Y]=value
    @metafile.push([Y,value])
  end

  def bitmap
    return nil
  end

  def bitmap=(value)
    if value && !value.disposed?
      @values[SRC_RECT].set(0,0,value.width,value.height)
      @metafile.push([SRC_RECT,@values[SRC_RECT].clone])
    end
  end

  def src_rect
    return @values[SRC_RECT]
  end

  def src_rect=(value)
    @values[SRC_RECT]=value
   @metafile.push([SRC_RECT,value])
 end

  def visible
    return @values[VISIBLE]
  end

  def visible=(value)
    @values[VISIBLE]=value
    @metafile.push([VISIBLE,value])
  end

  def z
    return @values[Z]
  end

  def z=(value)
    @values[Z]=value
    @metafile.push([Z,value])
  end

  def ox
    return @values[OX]
  end

  def ox=(value)
    @values[OX]=value
    @metafile.push([OX,value])
  end

  def oy
    return @values[OY]
  end

  def oy=(value)
    @values[OY]=value
    @metafile.push([OY,value])
  end

  def zoom_x
    return @values[ZOOM_X]
  end

  def zoom_x=(value)
    @values[ZOOM_X]=value
    @metafile.push([ZOOM_X,value])
  end

  def zoom_y
    return @values[ZOOM_Y]
  end

  def zoom_y=(value)
    @values[ZOOM_Y]=value
    @metafile.push([ZOOM_Y,value])
  end

  def zoom=(value)
    @values[ZOOM_X]=value
    @metafile.push([ZOOM_X,value])
    @values[ZOOM_Y]=value
    @metafile.push([ZOOM_Y,value])
  end

  def angle
    return @values[ANGLE]
  end

  def angle=(value)
    @values[ANGLE]=value
    @metafile.push([ANGLE,value])
  end

  def mirror
    return @values[MIRROR]
  end

  def mirror=(value)
    @values[MIRROR]=value
    @metafile.push([MIRROR,value])
  end

  def bush_depth
    return @values[BUSH_DEPTH]
  end

  def bush_depth=(value)
    @values[BUSH_DEPTH]=value
    @metafile.push([BUSH_DEPTH,value])
  end

  def opacity
    return @values[OPACITY]
  end

  def opacity=(value)
    @values[OPACITY]=value
    @metafile.push([OPACITY,value])
  end

  def blend_type
    return @values[BLEND_TYPE]
  end

  def blend_type=(value)
    @values[BLEND_TYPE]=value
    @metafile.push([BLEND_TYPE,value])
  end

  def color
    return @values[COLOR]
  end

  def color=(value)
    @values[COLOR]=value.clone
    @metafile.push([COLOR,@values[COLOR]])
  end

  def tone
    return @values[TONE]
  end

  def tone=(value)
    @values[TONE]=value.clone
    @metafile.push([TONE,@values[TONE]])
  end

  def update
    @metafile.push([-1,nil])
  end
end



class SpriteMetafilePlayer
  def initialize(metafile,sprite=nil)
    @metafile=metafile
    @sprites=[]
    @playing=false
    @index=0
    @sprites.push(sprite) if sprite
  end

  def add(sprite)
    @sprites.push(sprite)
  end

  def playing?
    return @playing
  end

  def play
    @playing=true
    @index=0
  end

  def update
    if @playing
      for j in @index...@metafile.length
        @index=j+1
        break if @metafile[j][0]<0
        code=@metafile[j][0]
        value=@metafile[j][1]
        for sprite in @sprites
          case code
          when SpriteMetafile::X
            sprite.x=value
          when SpriteMetafile::Y
            sprite.y=value
          when SpriteMetafile::OX
            sprite.ox=value
          when SpriteMetafile::OY
            sprite.oy=value
          when SpriteMetafile::ZOOM_X
            sprite.zoom_x=value
          when SpriteMetafile::ZOOM_Y
            sprite.zoom_y=value
          when SpriteMetafile::SRC_RECT
            sprite.src_rect=value
          when SpriteMetafile::VISIBLE
            sprite.visible=value
          when SpriteMetafile::Z
            sprite.z=value
          # prevent crashes
          when SpriteMetafile::ANGLE
            sprite.angle=(value==180) ? 179.9 : value
          when SpriteMetafile::MIRROR
            sprite.mirror=value
          when SpriteMetafile::BUSH_DEPTH
            sprite.bush_depth=value
          when SpriteMetafile::OPACITY
            sprite.opacity=value
          when SpriteMetafile::BLEND_TYPE
            sprite.blend_type=value
          when SpriteMetafile::COLOR
            sprite.color=value
          when SpriteMetafile::TONE
            sprite.tone=value
          end
        end
      end
      @playing=false if @index==@metafile.length
    end
  end
end



def pbSaveSpriteState(sprite)
  state=[]
  return state if !sprite || sprite.disposed?
  state[SpriteMetafile::BITMAP]     = sprite.x
  state[SpriteMetafile::X]          = sprite.x
  state[SpriteMetafile::Y]          = sprite.y
  state[SpriteMetafile::SRC_RECT]   = sprite.src_rect.clone
  state[SpriteMetafile::VISIBLE]    = sprite.visible
  state[SpriteMetafile::Z]          = sprite.z
  state[SpriteMetafile::OX]         = sprite.ox
  state[SpriteMetafile::OY]         = sprite.oy
  state[SpriteMetafile::ZOOM_X]     = sprite.zoom_x
  state[SpriteMetafile::ZOOM_Y]     = sprite.zoom_y
  state[SpriteMetafile::ANGLE]      = sprite.angle
  state[SpriteMetafile::MIRROR]     = sprite.mirror
  state[SpriteMetafile::BUSH_DEPTH] = sprite.bush_depth
  state[SpriteMetafile::OPACITY]    = sprite.opacity
  state[SpriteMetafile::BLEND_TYPE] = sprite.blend_type
  state[SpriteMetafile::COLOR]      = sprite.color.clone
  state[SpriteMetafile::TONE]       = sprite.tone.clone
  return state
end

def pbRestoreSpriteState(sprite,state)
  return if !state || !sprite || sprite.disposed?
  sprite.x          = state[SpriteMetafile::X]
  sprite.y          = state[SpriteMetafile::Y]
  sprite.src_rect   = state[SpriteMetafile::SRC_RECT]
  sprite.visible    = state[SpriteMetafile::VISIBLE]
  sprite.z          = state[SpriteMetafile::Z]
  sprite.ox         = state[SpriteMetafile::OX]
  sprite.oy         = state[SpriteMetafile::OY]
  sprite.zoom_x     = state[SpriteMetafile::ZOOM_X]
  sprite.zoom_y     = state[SpriteMetafile::ZOOM_Y]
  sprite.angle      = state[SpriteMetafile::ANGLE]
  sprite.mirror     = state[SpriteMetafile::MIRROR]
  sprite.bush_depth = state[SpriteMetafile::BUSH_DEPTH]
  sprite.opacity    = state[SpriteMetafile::OPACITY]
  sprite.blend_type = state[SpriteMetafile::BLEND_TYPE]
  sprite.color      = state[SpriteMetafile::COLOR]
  sprite.tone       = state[SpriteMetafile::TONE]
end

def pbSaveSpriteStateAndBitmap(sprite)
  return [] if !sprite || sprite.disposed?
  state=pbSaveSpriteState(sprite)
  state[SpriteMetafile::BITMAP]=sprite.bitmap
  return state
end

def pbRestoreSpriteStateAndBitmap(sprite,state)
  return if !state || !sprite || sprite.disposed?
  sprite.bitmap=state[SpriteMetafile::BITMAP]
  pbRestoreSpriteState(sprite,state)
  return state
end



class PokemonEvolutionScene
  private

  def pbGenerateMetafiles(s1x,s1y,s2x,s2y)
    sprite=SpriteMetafile.new
    sprite2=SpriteMetafile.new
    sprite.opacity=255
    sprite2.opacity=255
    sprite2.zoom=0.0
    sprite.ox=s1x
    sprite.oy=s1y
    sprite2.ox=s2x
    sprite2.oy=s2y
    alpha=0
    for j in 0...26
      if sprite.pbHasType?(:GRASS) || sprite.pbHasType?(:BUG)
        sprite.color.red=92
        sprite.color.green=255
        sprite.color.blue=45
        sprite.color.alpha=255
        sprite.color=sprite.color
        alpha+=5
      elsif sprite.pbHasType?(:DARK) || sprite.pbHasType?(:POISON) || sprite.pbHasType?(:GHOST)
        sprite.color.red=29
        sprite.color.green=10
        sprite.color.blue=47
        sprite.color.alpha=255
        sprite.color=sprite.color
        alpha+=5
      elsif sprite.pbHasType?(:ICE) || sprite.pbHasType?(:FLYING)
        sprite.color.red=0
        sprite.color.green=220
        sprite.color.blue=230
        sprite.color.alpha=255
        sprite.color=sprite.color
        alpha+=5
      elsif sprite.pbHasType?(:ELECTRIC)
        sprite.color.red=255
        sprite.color.green=255
        sprite.color.blue=0
        sprite.color.alpha=255
        sprite.color=sprite.color
        alpha+=5
      elsif sprite.pbHasType?(:FIRE) || sprite.pbHasType?(:FIGHTING)
        sprite.color.red=200
        sprite.color.green=0
        sprite.color.blue=0
        sprite.color.alpha=255
        sprite.color=sprite.color
        alpha+=5
      elsif sprite.pbHasType?(:ROCK) || sprite.pbHasType?(:GROUND)
        sprite.color.red=148
        sprite.color.green=124
        sprite.color.blue=75
        sprite.color.alpha=255
        sprite.color=sprite.color
        alpha+=5
      elsif sprite.pbHasType?(:STEEL) || sprite.pbHasType?(:NORMAL)
        sprite.color.red=250
        sprite.color.green=250
        sprite.color.blue=250
        sprite.color.alpha=255
        sprite.color=sprite.color
        alpha+=5
      elsif sprite.pbHasType?(:PSYCHIC) || sprite.pbHasType?(:FAIRY)
        sprite.color.red=255
        sprite.color.green=0
        sprite.color.blue=250
        sprite.color.alpha=255
        sprite.color=sprite.color
        alpha+=5
      elsif sprite.pbHasType?(:WATER)
        sprite.color.red=0
        sprite.color.green=51
        sprite.color.blue=255
        sprite.color.alpha=255
        sprite.color=sprite.color
        alpha+=5
      else#
        sprite.color.red=255
        sprite.color.green=255 
        sprite.color.blue=255
        sprite.color.alpha=alpha
        sprite.color=sprite.color
        sprite2.color=sprite.color
        sprite2.color.alpha=255
        sprite.update
        sprite2.update
        alpha+=5
      end#
    end
    totaltempo=0
    currenttempo=25
    maxtempo=7*Graphics.frame_rate
    while totaltempo<maxtempo
      for j in 0...currenttempo
        if alpha<255
          if sprite2.pbHasType?(:GRASS) || sprite2.pbHasType?(:BUG)
            sprite2.color.red=92
            sprite2.color.green=255
            sprite2.color.blue=45
            sprite2.color.alpha=255
            sprite2.color=sprite2.color
            alpha+=5
          elsif sprite2.pbHasType?(:DARK) || sprite2.pbHasType?(:POISON) || sprite2.pbHasType?(:GHOST)
            sprite2.color.red=29
            sprite2.color.green=10
            sprite2.color.blue=47
            sprite2.color.alpha=255
            sprite2.color=sprite2.color
            alpha+=5
          elsif sprite2.pbHasType?(:ICE) || sprite2.pbHasType?(:FLYING)
            sprite2.color.red=0
            sprite2.color.green=220
            sprite2.color.blue=230
            sprite2.color.alpha=255
            sprite2.color=sprite2.color
            alpha+=5
          elsif sprite2.pbHasType?(:ELECTRIC)
            sprite2.color.red=255
            sprite2.color.green=255
            sprite2.color.blue=0
            sprite2.color.alpha=255
            sprite2.color=sprite2.color
            alpha+=5
          elsif sprite2.pbHasType?(:FIRE) || sprite2.pbHasType?(:FIGHTING)
            sprite2.color.red=200
            sprite2.color.green=0
            sprite2.color.blue=0
            sprite2.color.alpha=255
            sprite2.color=sprite2.color
            alpha+=5
          elsif sprite2.pbHasType?(:ROCK) || sprite2.pbHasType?(:GROUND)
            sprite2.color.red=148
            sprite2.color.green=124
            sprite2.color.blue=75
            sprite2.color.alpha=255
            sprite2.color=sprite2.color
            alpha+=5
          elsif sprite2.pbHasType?(:STEEL) || sprite2.pbHasType?(:NORMAL)
            sprite2.color.red=250
            sprite2.color.green=250
            sprite2.color.blue=250
            sprite2.color.alpha=255
            sprite2.color=sprite2.color
            alpha+=5
          elsif sprite2.pbHasType?(:PSYCHIC) || sprite2.pbHasType?(:FAIRY)
            sprite2.color.red=255
            sprite2.color.green=0
            sprite2.color.blue=250
            sprite2.color.alpha=255
            sprite2.color=sprite2.color
            alpha+=5
          elsif sprite2.pbHasType?(:WATER)
            sprite2.color.red=0
            sprite2.color.green=51
            sprite2.color.blue=255
            sprite2.color.alpha=255
            sprite2.color=sprite2.color
            alpha+=5
          else#
            sprite2.color.red=255
            sprite2.color.green=255 
            sprite2.color.blue=255
            sprite2.color.alpha=alpha
            sprite2.color=sprite2.color
            sprite2.color=sprite2.color
            sprite2.color.alpha=255
            sprite2.update
            sprite2.update
            alpha+=5
          end#
        end
        sprite.zoom=[1.1*(currenttempo-j-1)/currenttempo,1.0].min
        sprite2.zoom=[1.1*(j+1)/currenttempo,1.0].min
        sprite.update
        sprite2.update
      end
      totaltempo+=currenttempo
      if totaltempo+currenttempo<maxtempo
        for j in 0...currenttempo
          sprite.zoom=[1.1*(j+1)/currenttempo,1.0].min
          sprite2.zoom=[1.1*(currenttempo-j-1)/currenttempo,1.0].min
          sprite.update
          sprite2.update
        end
      end
      totaltempo+=currenttempo
      currenttempo=[(currenttempo/1.5).floor,5].max
    end
    @metafile1=sprite
    @metafile2=sprite2
  end

# Inicia la pantalla de evolución con el Pokémon dado y la especie nueva.
  public

  def pbUpdate(animating=false)
    if animating      # El Pokémon no debería ser animado durante la animación de la evolución
      @sprites["background"].update
    else
      pbUpdateSpriteHash(@sprites)
    end
  end

  def pbUpdateNarrowScreen
    if @bgviewport.rect.y<20*4
      @bgviewport.rect.height-=2*4
      if @bgviewport.rect.height<Graphics.height-64
        @bgviewport.rect.y+=4
        @sprites["background"].oy=@bgviewport.rect.y
      end
    end
  end

  def pbUpdateExpandScreen
    if @bgviewport.rect.y>0
      @bgviewport.rect.y-=4
      @sprites["background"].oy=@bgviewport.rect.y
    end
    if @bgviewport.rect.height<Graphics.height
      @bgviewport.rect.height+=2*4
    end
  end

  def pbFlashInOut(canceled,oldstate,oldstate2)
    tone=0
    loop do
      Graphics.update
      pbUpdate(true)
      pbUpdateExpandScreen
      tone+=10
      @viewport.tone.set(tone,tone,tone,0)
      break if tone>=255
    end
    @bgviewport.rect.y=0
    @bgviewport.rect.height=Graphics.height
    @sprites["background"].oy=0
    if canceled
      pbRestoreSpriteState(@sprites["rsprite1"],oldstate)
      pbRestoreSpriteState(@sprites["rsprite2"],oldstate2)
      @sprites["rsprite1"].visible=true
      @sprites["rsprite1"].zoom_x=1.0
      @sprites["rsprite1"].zoom_y=1.0
      @sprites["rsprite1"].color.alpha=0
      @sprites["rsprite2"].visible=false
    else
      @sprites["rsprite1"].visible=false
      @sprites["rsprite2"].visible=true
      @sprites["rsprite2"].zoom_x=1.0
      @sprites["rsprite2"].zoom_y=1.0
      @sprites["rsprite2"].color.alpha=0
    end
    10.times do
      Graphics.update
      pbUpdate(true)
    end
    tone=255
    loop do
      Graphics.update
      pbUpdate
      tone=[tone-20,0].max
      @viewport.tone.set(tone,tone,tone,0)
      break if tone<=0
    end
  end
  
  def pbStartScreen(pokemon,newspecies)
    @sprites={}
    @bgviewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @bgviewport.z=99999
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @msgviewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @msgviewport.z=99999
    @pokemon=pokemon
    @newspecies=newspecies
    addBackgroundOrColoredPlane(@sprites,"background","evolutionbg",
       Color.new(248,248,248),@bgviewport)
    rsprite1=PokemonSprite.new(@viewport)
    rsprite2=PokemonSprite.new(@viewport)
    rsprite1.setPokemonBitmap(@pokemon,false)
    rsprite2.setPokemonBitmapSpecies(@pokemon,@newspecies,false)
    rsprite1.ox=rsprite1.bitmap.width/2
    rsprite1.oy=rsprite1.bitmap.height/2
    rsprite2.ox=rsprite2.bitmap.width/2
    rsprite2.oy=rsprite2.bitmap.height/2
    rsprite1.x=Graphics.width/2
    rsprite1.y=(Graphics.height-64)/2
    rsprite2.x=rsprite1.x
    rsprite2.y=rsprite1.y
    rsprite2.opacity=0
    @sprites["rsprite1"]=rsprite1
    @sprites["rsprite2"]=rsprite2
    pbGenerateMetafiles(rsprite1.ox,rsprite1.oy,rsprite2.ox,rsprite2.oy)
    @sprites["msgwindow"]=Kernel.pbCreateMessageWindow(@msgviewport)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

# Closes the evolution screen.
  def pbEndScreen
    Kernel.pbDisposeMessageWindow(@sprites["msgwindow"])
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
    @bgviewport.dispose
    @msgviewport.dispose
  end

# Muestra la pantalla de la evolución
  def pbEvolution(cancancel=true)
    metaplayer1=SpriteMetafilePlayer.new(@metafile1,@sprites["rsprite1"])
    metaplayer2=SpriteMetafilePlayer.new(@metafile2,@sprites["rsprite2"])
    metaplayer1.play
    metaplayer2.play
    pbBGMStop()
    pbPlayCry(@pokemon)
    Kernel.pbMessageDisplay(@sprites["msgwindow"],
       _INTL("\\se[]¿Y esto?\r\n¡{1} está evolucionando!\\^",@pokemon.name)) { pbUpdate }
    Kernel.pbMessageWaitForInput(@sprites["msgwindow"],100,true) { pbUpdate }
    pbPlayDecisionSE()
    oldstate=pbSaveSpriteState(@sprites["rsprite1"])
    oldstate2=pbSaveSpriteState(@sprites["rsprite2"])
    pbBGMPlay("evolv")
    canceled=false
    begin
      pbUpdateNarrowScreen
      metaplayer1.update
      metaplayer2.update
      Graphics.update
      Input.update
      pbUpdate(true)
      if Input.trigger?(Input::B) && cancancel
        pbBGMStop()
        pbPlayCancelSE()
        canceled=true
        break
      end
    end while metaplayer1.playing? && metaplayer2.playing?
    pbFlashInOut(canceled,oldstate,oldstate2)
    if canceled
      Kernel.pbMessageDisplay(@sprites["msgwindow"],
         _INTL("¿Qué?\r\n¡Se detuvo la evolución de {1}!",@pokemon.name)) { pbUpdate }
    else
      frames=pbCryFrameLength(@newspecies)
      pbBGMStop()
      pbPlayCry(@newspecies)
      frames.times do
        Graphics.update
        pbUpdate
      end
      pbMEPlay("EvolutionSuccess")
      newspeciesname=PBSpecies.getName(@newspecies)
      oldspeciesname=PBSpecies.getName(@pokemon.species)
      Kernel.pbMessageDisplay(@sprites["msgwindow"],
         _INTL("\\se[]¡Felicitaciones! ¡Tu {1} ha evolucionado en {2}!\\wt[80]",
         @pokemon.name,newspeciesname)) { pbUpdate }
      @sprites["msgwindow"].text=""
      removeItem=false
      createSpecies=pbCheckEvolutionEx(@pokemon){|pokemon,evonib,level,poke|
         if evonib==PBEvolution::Shedinja
           next poke if $PokemonBag.pbQuantity(getConst(PBItems,:POKEBALL))>0
         elsif evonib==PBEvolution::TradeItem ||
               evonib==PBEvolution::DayHoldItem ||
               evonib==PBEvolution::NightHoldItem ||
               evonib==PBEvolution::HoldItem
           removeItem=true if poke==@newspecies   # El objeto ahora es consumido
         end
         next -1
      }
      @pokemon.setItem(0) if removeItem
      @pokemon.species=@newspecies
      $Trainer.seen[@newspecies]=true
      $Trainer.owned[@newspecies]=true
      pbSeenForm(@pokemon)
      @pokemon.name=newspeciesname if @pokemon.name==oldspeciesname
      @pokemon.calcStats
      # Revisa los movimientos de la especie nueva
      movelist=@pokemon.getMoveList
      for i in movelist
        if i[0]==@pokemon.level          # Aprendió un movimiento nuevo
          pbLearnMove(@pokemon,i[1],true) { pbUpdate }
        end
      end
      if createSpecies>0 && $Trainer.party.length<6
        newpokemon=@pokemon.clone
        newpokemon.iv=@pokemon.iv.clone
        newpokemon.ev=@pokemon.ev.clone
        newpokemon.species=createSpecies
        newpokemon.name=PBSpecies.getName(createSpecies)
        newpokemon.setItem(0)
        newpokemon.clearAllRibbons
        newpokemon.markings=0
        newpokemon.ballused=0
        newpokemon.calcStats
        newpokemon.heal
        $Trainer.party.push(newpokemon)
        $Trainer.seen[createSpecies]=true
        $Trainer.owned[createSpecies]=true
        pbSeenForm(newpokemon)
        $PokemonBag.pbDeleteItem(getConst(PBItems,:POKEBALL))
      end
    end
  end
end



#===============================================================================
# Métodos de evolución
#===============================================================================
def pbMiniCheckEvolution(pokemon,evonib,level,poke)
  case evonib
  when PBEvolution::Happiness
    return poke if pokemon.happiness>=220
  when PBEvolution::HappinessForm0
    return poke if pokemon.happiness>=220 && pokemon.form==0
  when PBEvolution::HappinessForm1
    return poke if pokemon.happiness>=220 && pokemon.form==1
  when PBEvolution::HappinessForm2
    return poke if pokemon.happiness>=220 && pokemon.form==2
  when PBEvolution::HappinessDay
    return poke if pokemon.happiness>=220 && PBDayNight.isDay?
  when PBEvolution::HappinessNight
    if isConst?(pokemon.species,PBSpecies,:KUBFU)
      pokemon.form=1 if pokemon.happiness>=220 && PBDayNight.isNight?
    end
    return poke if pokemon.happiness>=220 && PBDayNight.isNight?
  when PBEvolution::HappinessMoveType
    if pokemon.happiness>=220
      for i in 0...4
        return poke if pokemon.moves[i].id>0 && pokemon.moves[i].type==level
      end
    end
  when PBEvolution::Level
    if isConst?(pokemon.species,PBSpecies,:CUBONE) && pokemon.obtainMap==22 && PBDayNight.isNight?
      pokemon.form=1 if level>=level
    elsif isConst?(pokemon.species,PBSpecies,:KOFFING) && pokemon.obtainMap==32
      pokemon.form=1 if level>=level
    elsif isConst?(pokemon.species,PBSpecies,:QUILAVA) && pokemon.obtainMap==33
      pokemon.form=1 if level>=level
    elsif isConst?(pokemon.species,PBSpecies,:DEWOTT) && pokemon.obtainMap==33
      pokemon.form=1 if level>=level
    elsif isConst?(pokemon.species,PBSpecies,:DARTRIX) && pokemon.obtainMap==33
      pokemon.form=1 if level>=level
    elsif isConst?(pokemon.species,PBSpecies,:RUFFLET) && pokemon.obtainMap==33
      pokemon.form=1 if level>=level
    elsif isConst?(pokemon.species,PBSpecies,:GOOMY) && pokemon.obtainMap==33
      pokemon.form=1 if level>=level
    elsif isConst?(pokemon.species,PBSpecies,:BERGMITE) && pokemon.obtainMap==33
      pokemon.form=1 if level>=level
    elsif isConst?(pokemon.species,PBSpecies,:TOXEL) && (pokemon.nature==PBNatures::LONELY ||
      pokemon.nature==PBNatures::BOLD || pokemon.nature==PBNatures::RELAXED || 
      pokemon.nature==PBNatures::TIMID || pokemon.nature==PBNatures::SERIOUS ||
      pokemon.nature==PBNatures::MODEST || pokemon.nature==PBNatures::MILD ||
      pokemon.nature==PBNatures::QUIET || pokemon.nature==PBNatures::BASHFUL ||
      pokemon.nature==PBNatures::CALM || pokemon.nature==PBNatures::GENTLE ||
      pokemon.nature==PBNatures::CAREFUL)
      pokemon.form=1 if level>=level
    end
    return poke if pokemon.level>=level
  when PBEvolution::LevelForm0
    return poke if pokemon.level>=level && pokemon.form==0
  when PBEvolution::LevelForm1
    return poke if pokemon.level>=level && pokemon.form==1
  when PBEvolution::LevelForm2
    return poke if pokemon.level>=level && pokemon.form==2
  when PBEvolution::LevelDay
    return poke if pokemon.level>=level && PBDayNight.isDay?
  when PBEvolution::LevelDayForm0
    return poke if pokemon.level>=level && pokemon.form==0 && PBDayNight.isDay?
  when PBEvolution::LevelDayForm1
    return poke if pokemon.level>=level && pokemon.form==1 && PBDayNight.isDay?
  when PBEvolution::LevelDayForm2
    return poke if pokemon.level>=level && pokemon.form==2 && PBDayNight.isDay?
  when PBEvolution::LevelNight
    return poke if pokemon.level>=level && PBDayNight.isNight?
  when PBEvolution::LevelNightForm0
    return poke if pokemon.level>=level && pokemon.form==0 && PBDayNight.isNight?
  when PBEvolution::LevelNightForm1
    return poke if pokemon.level>=level && pokemon.form==1 && PBDayNight.isNight?
  when PBEvolution::LevelNightForm2
    return poke if pokemon.level>=level && pokemon.form==2 && PBDayNight.isNight?
  when PBEvolution::LevelMale
    return poke if pokemon.level>=level && pokemon.isMale?
  when PBEvolution::LevelFemale
    return poke if pokemon.level>=level && pokemon.isFemale?
  when PBEvolution::AttackGreater           # Hitmonlee
    return poke if pokemon.level>=level && pokemon.attack>pokemon.defense
  when PBEvolution::AtkDefEqual             # Hitmontop
    return poke if pokemon.level>=level && pokemon.attack==pokemon.defense
  when PBEvolution::DefenseGreater          # Hitmonchan
    return poke if pokemon.level>=level && pokemon.attack<pokemon.defense
  when PBEvolution::Silcoon
    return poke if pokemon.level>=level && (((pokemon.personalID>>16)&0xFFFF)%10)<5
  when PBEvolution::Cascoon
    return poke if pokemon.level>=level && (((pokemon.personalID>>16)&0xFFFF)%10)>=5
  when PBEvolution::Ninjask
    return poke if pokemon.level>=level
  when PBEvolution::Shedinja
    return -1
  when PBEvolution::DayHoldItem
    return poke if pokemon.item==level && PBDayNight.isDay?
  when PBEvolution::NightHoldItem
    return poke if pokemon.item==level && PBDayNight.isNight?
  when PBEvolution::HoldItemForm0
    return poke if pokemon.item==level && pokemon.form==0
  when PBEvolution::HoldItemForm1
    return poke if pokemon.item==level && pokemon.form==1
  when PBEvolution::HoldItemForm2
    return poke if pokemon.item==level && pokemon.form==2
  when PBEvolution::HasMove
    for i in 0...4
      if isConst?(pokemon.species,PBSpecies,:MIMEJR) && pokemon.obtainMap==32
        pokemon.form=1 if pokemon.moves[i].id==level
      end
      return poke if pokemon.moves[i].id==level
    end
  when PBEvolution::HasMoveForm0
    for i in 0...4
      return poke if pokemon.moves[i].id==level && pokemon.form==0
    end
  when PBEvolution::HasMoveForm1
    for i in 0...4
      return poke if pokemon.moves[i].id==level && pokemon.form==1
    end
  when PBEvolution::HasMoveForm2
    for i in 0...4
      return poke if pokemon.moves[i].id==level && pokemon.form==2
    end
  when PBEvolution::HasInParty
    for i in $Trainer.party
      return poke if !i.isEgg? && i.species==level
    end
  when PBEvolution::LevelDarkInParty
    if pokemon.level>=level
      for i in $Trainer.party
        return poke if !i.isEgg? && i.hasType?(:DARK)
      end
    end
  when PBEvolution::Location
    return poke if $game_map.map_id==level
  when PBEvolution::LevelRain
    if pokemon.level>=level
      if $game_screen && ($game_screen.weather==PBFieldWeather::Rain ||
                          $game_screen.weather==PBFieldWeather::HeavyRain ||
                          $game_screen.weather==PBFieldWeather::Storm)
        return poke
      end
    end
  when PBEvolution::Beauty # Feebas
    return poke if pokemon.beauty>=level
  when PBEvolution::Trade, PBEvolution::TradeItem, PBEvolution::TradeSpecies
    return -1
  when PBEvolution::LevelDayTime # Lycanroc
    if PBDayNight.isDusk?
      pokemon.form=2
      if pokemon.level>=level
        return poke
      else
        if PBDayNight.isDay? 
          pokemon.form=0
          return poke if pokemon.level>=level
        else
          pokemon.form=1
          return poke if pokemon.level>=level
        end
      end
    end
    if PBDayNight.isNight?
      pokemon.form=1
      return poke if pokemon.level>=level && PBDayNight.isNight?
    end
    if PBDayNight.isDay?
      pokemon.form=0
      return poke if pokemon.level>=level && PBDayNight.isDay?
    end  
  when PBEvolution::Crits # Sirfetch'd
    return poke if $criticosFarf>=3 && pokemon.form==1
  end
  return -1
end

def pbMiniCheckEvolutionItem(pokemon,evonib,level,poke,item)
  # Revisa si se ha usado un objeto en el Pokémon (por ejemplo, una piedra evolutiva)
  case evonib
  when PBEvolution::Item
    if isConst?(pokemon.species,PBSpecies,:PIKACHU) && pokemon.obtainMap==22
      pokemon.form=1 if level==item
    elsif isConst?(pokemon.species,PBSpecies,:EXEGGCUTE) && pokemon.obtainMap==22
      pokemon.form=1 if level==item
    elsif isConst?(pokemon.species,PBSpecies,:PETILIL) && pokemon.obtainMap==33
      pokemon.form=1 if level==item
    end
    return poke if level==item  
  when PBEvolution::ItemMale
    return poke if level==item && pokemon.isMale?
  when PBEvolution::ItemFemale
    return poke if level==item && pokemon.isFemale?
  when PBEvolution::ItemForm0
    return poke if level==item && pokemon.form==0
  when PBEvolution::ItemForm1
    return poke if level==item && pokemon.form==1
  when PBEvolution::ItemForm2
    return poke if level==item && pokemon.form==2
  end
  return -1
end

# Revisa si un Pokémon puede evolucionar ahora.
# Si se da un bloque, se lo llama con los siguientes parámetros:
# Pokemon a revisar; tipo de evolución; nivel u otro parámetro; ID de la especie Pokémon nueva
def pbCheckEvolutionEx(pokemon)
  return -1 if pokemon.species<=0 || pokemon.isEgg?
  return -1 if isConst?(pokemon.species,PBSpecies,:PICHU) && pokemon.form==1
  return -1 if isConst?(pokemon.item,PBItems,:EVERSTONE) &&
               !isConst?(pokemon.species,PBSpecies,:KADABRA)
  ret=-1
  for form in pbGetEvolvedFormData(pokemon.species)
    ret=yield pokemon,form[0],form[1],form[2]
    break if ret>0
  end
  return ret
end

# Revisa si un Pokémon puede evolucionar ahora. Si usa un objeto en el Pokémon, se revisa
# si el Pokémon puede evolucionar con ese objeto o no.
def pbCheckEvolution(pokemon,item=0)
  if item==0
    return pbCheckEvolutionEx(pokemon){|pokemon,evonib,level,poke|
       next pbMiniCheckEvolution(pokemon,evonib,level,poke)
    }
  else
    return pbCheckEvolutionEx(pokemon){|pokemon,evonib,level,poke|
       next pbMiniCheckEvolutionItem(pokemon,evonib,level,poke,item)
    }
  end
end