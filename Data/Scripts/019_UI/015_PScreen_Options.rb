#===============================================================================
#
#===============================================================================
class PokemonSystem
  attr_accessor :textspeed
  attr_accessor :battlescene
  attr_accessor :battlestyle
  attr_accessor :sendtoboxes
  attr_accessor :givenicknames
  attr_accessor :frame
  attr_accessor :textskin
  attr_accessor :screensize
  attr_accessor :language
  attr_accessor :runstyle
  attr_accessor :bgmvolume
  attr_accessor :sevolume
  attr_accessor :textinput
  attr_accessor :border
  attr_accessor :font
  
  def initialize
    @textspeed     = 2     # Text speed (0=slow, 1=medium, 2=fast, 3=instant)
    @battlescene   = 0     # Battle effects (animations) (0=on, 1=off)
    @battlestyle   = 0     # Battle style (0=switch, 1=set)
    @sendtoboxes   = 0     # Send to Boxes (0=manual, 1=automatic)
    @givenicknames = 0     # Give nicknames (0=give, 1=don't give)
    @frame         = 0     # Default window frame (see also Settings::MENU_WINDOWSKINS)
    @textskin      = 0     # Speech frame
    @screensize    = @screensize  = (DEFAULTSCREENZOOM.floor).to_i   # 0=half size, 1=full size, 2=full-and-a-half size, 3=double size
    @language      = 0     # Language (see also Settings::LANGUAGES in script PokemonSystem)
    @runstyle      = 0     # Default movement speed (0=walk, 1=run)
    @bgmvolume     = 100   # Volume of background music and ME
    @sevolume      = 100   # Volume of sound effects
    @textinput     = 0     # Text input mode (0=cursor, 1=keyboard)
    @font        = 0   # Font (see also $VersionStyles)
    @border      = 0   # Screen border (0=off, 1=on)

  end
  
  def tilemap; return MAPVIEWMODE; end
  
end

$SpeechFrames=[
  MessageConfig::TextSkinName, # Default: speech hgss 1
  "speech hgss 2",
  "speech hgss 3",
  "speech hgss 4",
  "speech hgss 5",
  "speech hgss 6",
  "speech hgss 7",
  "speech hgss 8",
  "speech hgss 9",
  "speech hgss 10",
  "speech hgss 11",
  "speech hgss 12",
  "speech hgss 13",
  "speech hgss 14",
  "speech hgss 15",
  "speech hgss 16",
  "speech hgss 17",
  "speech hgss 18",
  "speech hgss 19",
  "speech hgss 20",
  "speech pl 18"
]

$TextFrames=[
  "Graphics/Windowskins/"+MessageConfig::ChoiceSkinName, # Default: choice 1
  "Graphics/Windowskins/choice 2",
  "Graphics/Windowskins/choice 3",
  "Graphics/Windowskins/choice 4",
  "Graphics/Windowskins/choice 5",
  "Graphics/Windowskins/choice 6",
  "Graphics/Windowskins/choice 7",
  "Graphics/Windowskins/choice 8",
  "Graphics/Windowskins/choice 9",
  "Graphics/Windowskins/choice 10",
  "Graphics/Windowskins/choice 11",
  "Graphics/Windowskins/choice 12",
  "Graphics/Windowskins/choice 13",
  "Graphics/Windowskins/choice 14",
  "Graphics/Windowskins/choice 15",
  "Graphics/Windowskins/choice 16",
  "Graphics/Windowskins/choice 17",
  "Graphics/Windowskins/choice 18",
  "Graphics/Windowskins/choice 19",
  "Graphics/Windowskins/choice 20",
  "Graphics/Windowskins/choice 21",
  "Graphics/Windowskins/choice 22",
  "Graphics/Windowskins/choice 23",
  "Graphics/Windowskins/choice 24",
  "Graphics/Windowskins/choice 25",
  "Graphics/Windowskins/choice 26",
  "Graphics/Windowskins/choice 27",
  "Graphics/Windowskins/choice 28"
]

$VersionStyles=[
  [MessageConfig::FontName], # Default font style - Power Green/"Pokemon Emerald"
  ["Power Red and Blue"],
  ["Power Red and Green"],
  ["Power Clear"]
]

def pbSettingToTextSpeed(speed)
  return 2 if speed==0
  return 1 if speed==1
  return -2 if speed==2
  return MessageConfig::TextSpeed if MessageConfig::TextSpeed
  return ((Graphics.frame_rate>40) ? -2 : 1)
end

module MessageConfig
  def self.pbDefaultSystemFrame
    if !$PokemonSystem
      return pbResolveBitmap("Graphics/Windowskins/"+MessageConfig::ChoiceSkinName)||""
    else
      return pbResolveBitmap($TextFrames[$PokemonSystem.frame])||""
    end
  end

  def self.pbDefaultSpeechFrame
    if !$PokemonSystem
      return pbResolveBitmap("Graphics/Windowskins/"+MessageConfig::TextSkinName)||""
    else
      return pbResolveBitmap("Graphics/Windowskins/"+$SpeechFrames[$PokemonSystem.textskin])||""
    end
  end

  def self.pbDefaultSystemFontName
    if !$PokemonSystem
      return MessageConfig.pbTryFonts(MessageConfig::FontName,"Arial Narrow","Arial")
    else
      return MessageConfig.pbTryFonts($VersionStyles[$PokemonSystem.font][0],"Arial Narrow","Arial")
    end
  end

  def self.pbDefaultTextSpeed
    return pbSettingToTextSpeed($PokemonSystem ? $PokemonSystem.textspeed : nil)
  end

  def pbGetSystemTextSpeed
    return $PokemonSystem ? $PokemonSystem.textspeed : ((Graphics.frame_rate>Graphics.frame_rate) ? 2 :  3)
  end
end

#===============================================================================
#
#===============================================================================
module PropertyMixin
  attr_reader :name

  def get
    return @get_proc.call if @get_proc
  end

  def set(*args)
    @set_proc.call(*args) if @get_proc
  end
end

#===============================================================================
#
#===============================================================================
class EnumOption
  include PropertyMixin
  attr_reader :values

  def initialize(name, values, get_proc, set_proc)
    @name     = name
    @values   = values.map { |val| _INTL(val) }
    @get_proc = get_proc
    @set_proc = set_proc
  end

  def next(current)
    index = current + 1
    index = @values.length - 1 if index > @values.length - 1
    return index
  end

  def prev(current)
    index = current - 1
    index = 0 if index < 0
    return index
  end
end

#===============================================================================
#
#===============================================================================
class NumberOption
  include PropertyMixin
  attr_reader :lowest_value
  attr_reader :highest_value

  def initialize(name, range, get_proc, set_proc)
    @name = name
    case range
    when Range
      @lowest_value  = range.begin
      @highest_value = range.end
    when Array
      @lowest_value  = range[0]
      @highest_value = range[1]
    end
    @get_proc = get_proc
    @set_proc = set_proc
  end

  def next(current)
    index = current + @lowest_value
    index += 1
    index = @lowest_value if index > @highest_value
    return index - @lowest_value
  end

  def prev(current)
    index = current + @lowest_value
    index -= 1
    index = @highest_value if index < @lowest_value
    return index - @lowest_value
  end
end

#===============================================================================
#
#===============================================================================
class SliderOption
  include PropertyMixin
  attr_reader :lowest_value
  attr_reader :highest_value

  def initialize(name, range, get_proc, set_proc)
    @name          = name
    @lowest_value  = range[0]
    @highest_value = range[1]
    @interval      = range[2]
    @get_proc      = get_proc
    @set_proc      = set_proc
  end

  def next(current)
    index = current + @lowest_value
    index += @interval
    index = @highest_value if index > @highest_value
    return index - @lowest_value
  end

  def prev(current)
    index = current + @lowest_value
    index -= @interval
    index = @lowest_value if index < @lowest_value
    return index - @lowest_value
  end
end

#===============================================================================
# Main options list
#===============================================================================
class Window_PokemonOption < Window_DrawableCommand
  attr_reader :value_changed

  SEL_NAME_BASE_COLOR    = Color.new(192, 120, 0)
  SEL_NAME_SHADOW_COLOR  = Color.new(248, 176, 80)
  SEL_VALUE_BASE_COLOR   = Color.new(248, 48, 24)
  SEL_VALUE_SHADOW_COLOR = Color.new(248, 136, 128)

  def initialize(options, x, y, width, height)
    @options = options
    @values = []
    @options.length.times { |i| @values[i] = 0 }
    @value_changed = false
    super(x, y, width, height)
  end

  def [](i)
    return @values[i]
  end

  def []=(i, value)
    @values[i] = value
    refresh
  end

  def setValueNoRefresh(i, value)
    @values[i] = value
  end

  def itemCount
    return @options.length + 1
  end

  def drawItem(index, _count, rect)
    rect = drawCursor(index, rect)
    sel_index = self.index
    # Draw option's name
    optionname = (index == @options.length) ? _INTL("Salir") : @options[index].name
    optionwidth = rect.width * 9 / 20
    pbDrawShadowText(self.contents, rect.x, rect.y, optionwidth, rect.height, optionname,
                     (index == sel_index) ? SEL_NAME_BASE_COLOR : self.baseColor,
                     (index == sel_index) ? SEL_NAME_SHADOW_COLOR : self.shadowColor)
    return if index == @options.length
    # Draw option's values
    case @options[index]
    when EnumOption
      if @options[index].values.length > 1
        totalwidth = 0
        @options[index].values.each do |value|
          totalwidth += self.contents.text_size(value).width
        end
        spacing = (rect.width - rect.x - optionwidth - totalwidth) / (@options[index].values.length - 1)
        spacing = 0 if spacing < 0
        xpos = optionwidth + rect.x
        ivalue = 0
        @options[index].values.each do |value|
          pbDrawShadowText(self.contents, xpos, rect.y, optionwidth, rect.height, value,
                           (ivalue == self[index]) ? SEL_VALUE_BASE_COLOR : self.baseColor,
                           (ivalue == self[index]) ? SEL_VALUE_SHADOW_COLOR : self.shadowColor)
          xpos += self.contents.text_size(value).width
          xpos += spacing
          ivalue += 1
        end
      else
        pbDrawShadowText(self.contents, rect.x + optionwidth, rect.y, optionwidth, rect.height,
                         optionname, self.baseColor, self.shadowColor)
      end
    when NumberOption
      value = _INTL("Tipo {1}/{2}", @options[index].lowest_value + self[index],
                    @options[index].highest_value - @options[index].lowest_value + 1)
      xpos = optionwidth + (rect.x * 2)
      pbDrawShadowText(self.contents, xpos, rect.y, optionwidth, rect.height, value,
                       SEL_VALUE_BASE_COLOR, SEL_VALUE_SHADOW_COLOR, 1)
    when SliderOption
      value = sprintf(" %d", @options[index].highest_value)
      sliderlength = rect.width - rect.x - optionwidth - self.contents.text_size(value).width
      xpos = optionwidth + rect.x
      self.contents.fill_rect(xpos, rect.y - 2 + (rect.height / 2), sliderlength, 4, self.baseColor)
      self.contents.fill_rect(
        xpos + ((sliderlength - 8) * (@options[index].lowest_value + self[index]) / @options[index].highest_value),
        rect.y - 8 + (rect.height / 2),
        8, 16, SEL_VALUE_BASE_COLOR
      )
      value = (@options[index].lowest_value + self[index]).to_s
      xpos += (rect.width - rect.x - optionwidth) - self.contents.text_size(value).width
      pbDrawShadowText(self.contents, xpos, rect.y, optionwidth, rect.height, value,
                       SEL_VALUE_BASE_COLOR, SEL_VALUE_SHADOW_COLOR)
    else
      value = @options[index].values[self[index]]
      xpos = optionwidth + rect.x
      pbDrawShadowText(self.contents, xpos, rect.y, optionwidth, rect.height, value,
                       SEL_VALUE_BASE_COLOR, SEL_VALUE_SHADOW_COLOR)
    end
  end

  def update
    oldindex = self.index
    @value_changed = false
    super
    dorefresh = (self.index != oldindex)
    if self.active && self.index < @options.length
      if Input.repeat?(Input::LEFT)
        self[self.index] = @options[self.index].prev(self[self.index])
        dorefresh = true
        @value_changed = true
      elsif Input.repeat?(Input::RIGHT)
        self[self.index] = @options[self.index].next(self[self.index])
        dorefresh = true
        @value_changed = true
      end
    end
    refresh if dorefresh
  end
end

#===============================================================================
# Options main screen
#===============================================================================
class PokemonOptionScene
  attr_reader :sprites
  attr_reader :in_load_screen

  def pbStartScene(in_load_screen = false)
    @in_load_screen = in_load_screen
    # Get all options
    @options = []
    @hashes = []
    MenuHandlers.each_available(:options_menu) do |option, hash, name|
      @options.push(
        hash["type"].new(name, hash["parameters"], hash["get_proc"], hash["set_proc"])
      )
      @hashes.push(hash)
    end
    # Create sprites
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    addBackgroundOrColoredPlane(@sprites, "bg", "optionsbg", Color.new(192, 200, 208), @viewport)
    @sprites["title"]=Window_UnformattedTextPokemon.newWithSize(
       _INTL("Opciones"),0,0,Graphics.width,64,@viewport)
    @sprites["textbox"] = Kernel.pbCreateMessageWindow
    @sprites["textbox"].width=@sprites["textbox"].width  # Necessary evil
    pbSetSystemFont(@sprites["textbox"].contents)

    @sprites["option"] = Window_PokemonOption.new(
      @options, 0, @sprites["title"].y + @sprites["title"].height, Graphics.width,
      Graphics.height - (@sprites["title"].y + @sprites["title"].height) - @sprites["textbox"].height
    )
    @sprites["option"].viewport = @viewport
    @sprites["option"].visible  = true
    # Get the values of each option
    @options.length.times { |i| @sprites["option"].setValueNoRefresh(i, @options[i].get || 0) }
    @sprites["option"].refresh
    pbChangeSelection
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbChangeSelection
    hash = @hashes[@sprites["option"].index]
    # Call selected option's "on_select" proc (if defined)
    @sprites["textbox"].setSkin(MessageConfig.pbGetSpeechFrame())
    @sprites["textbox"].letterbyletter = false
    hash["on_select"].call(self) if hash && hash["on_select"]
    # Set descriptive text
    description = ""
    if hash
      if hash["description"].is_a?(Proc)
        description = hash["description"].call
      elsif !hash["description"].nil?
        description = _INTL(hash["description"])
      end
    else
      description = _INTL("Close the screen.")
    end
    @sprites["textbox"].text = description
  end

  def pbOptions
    pbActivateWindow(@sprites, "option") do
      index = -1
      loop do
        Graphics.update
        Input.update
        pbUpdate
        if @sprites["option"].index != index
          pbChangeSelection
          index = @sprites["option"].index
        end
        @options[index].set(@sprites["option"][index], self) if @sprites["option"].value_changed
        @sprites["textbox"].width=@sprites["textbox"].width  # Necessary evil
        if Input.trigger?(Input::B)
          break
        elsif Input.trigger?(Input::C)
          break if @sprites["option"].index == @options.length
        end
      end
    end
  end

  def pbEndScene
    pbPlayCloseMenuSE
    pbFadeOutAndHide(@sprites) { pbUpdate }
    # Set the values of each option, to make sure they're all set
    @options.length.times do |i|
      @options[i].set(@sprites["option"][i], self)
    end
    Kernel.pbDisposeMessageWindow(@sprites["textbox"])
    pbDisposeSpriteHash(@sprites)
    pbUpdateSceneMap
    @viewport.dispose
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end
end

#===============================================================================
#
#===============================================================================
class PokemonOption
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(in_load_screen = false)
    @scene.pbStartScene(in_load_screen)
    @scene.pbOptions
    @scene.pbEndScene
  end
end

#===============================================================================
# Options Menu commands
#===============================================================================
MenuHandlers.add(:options_menu, :bgm_volume, {
  "name"        => _INTL("Volumen música"),
  "order"       => 10,
  "type"        => SliderOption,
  "parameters"  => [0, 100, 5],   # [minimum_value, maximum_value, interval]
  "description" => _INTL("Ajusta el volumen de la música del juego."),
  "get_proc"    => proc { next $PokemonSystem.bgmvolume },
  "set_proc"    => proc { |value, scene|
    next if $PokemonSystem.bgmvolume == value
    $PokemonSystem.bgmvolume = value
    next if scene.in_load_screen || $game_system.playing_bgm.nil?
    playingBGM = $game_system.getPlayingBGM
    $game_system.bgm_pause
    $game_system.bgm_resume(playingBGM)
  }
})

MenuHandlers.add(:options_menu, :se_volume, {
  "name"        => _INTL("Volumen efectos"),
  "order"       => 20,
  "type"        => SliderOption,
  "parameters"  => [0, 100, 5],   # [minimum_value, maximum_value, interval]
  "description" => _INTL("Ajusta el volumen de los efectos de sonido del juego."),
  "get_proc"    => proc { next $PokemonSystem.sevolume },
  "set_proc"    => proc { |value, _scene|
    next if $PokemonSystem.sevolume == value
    $PokemonSystem.sevolume = value
    if $game_system.playing_bgs
      $game_system.playing_bgs.volume = value
      playingBGS = $game_system.getPlayingBGS
      $game_system.bgs_pause
      $game_system.bgs_resume(playingBGS)
    end
    pbPlayCursorSE
  }
})

MenuHandlers.add(:options_menu, :text_speed, {
  "name"        => _INTL("Velocidad del texto	"),
  "order"       => 30,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Lenta"), _INTL("Media"), _INTL("Rápida")],
  "description" => _INTL("Elige entre los tres niveles de velocidad del texto."),
  "on_select"   => proc { |scene| scene.sprites["textbox"].letterbyletter = true },
  "get_proc"    => proc { next $PokemonSystem.textspeed },
  "set_proc"    => proc { |value, scene|
    next if value == $PokemonSystem.textspeed
    $PokemonSystem.textspeed = value
    MessageConfig.pbSetTextSpeed(MessageConfig.pbSettingToTextSpeed(value))
    # Display the message with the selected text speed to gauge it better.
    scene.sprites["textbox"].textspeed      = MessageConfig.pbGetTextSpeed
    scene.sprites["textbox"].letterbyletter = true
    scene.sprites["textbox"].text           = scene.sprites["textbox"].text
  }
})

MenuHandlers.add(:options_menu, :battle_animations, {
  "name"        => _INTL("Animaciones batalla"),
  "order"       => 40,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Ver"), _INTL("No ver")],
  "description" => _INTL("Activa o desactiva las animaciones durante los combates."),
  "get_proc"    => proc { next $PokemonSystem.battlescene },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.battlescene = value }
})

MenuHandlers.add(:options_menu, :battle_style, {
  "name"        => _INTL("Tipo de combate"),
  "order"       => 50,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Con cambios"), _INTL("Fijo")],
  "description" => _INTL("Elige si quieres que sea posible cambiar de Pokémon cuando un oponente se debilite."),
  "get_proc"    => proc { next $PokemonSystem.battlestyle },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.battlestyle = value }
})

MenuHandlers.add(:options_menu, :movement_style, {
  "name"        => _INTL("Movimiento Predt."),
  "order"       => 60,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Andar"), _INTL("Correr")],
  "description" => _INTL("Elige la velocidad de movimiento. Pulsa el botón al moverte para elegir la otra."),
  "get_proc"    => proc { next $PokemonSystem.runstyle },
  "set_proc"    => proc { |value, _sceme| 
    if $PokemonSystem.runstyle!=value
      $PokemonSystem.runstyle=value
      $PokemonGlobal.runtoggle=false if $PokemonGlobal
    end
  }
})

MenuHandlers.add(:options_menu, :send_to_boxes, {
  "name"        => _INTL("Equipo/Caja"),
  "order"       => 70,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Manual"), _INTL("Automático")],
  "description" => _INTL("Puedes indicar que los Pokémon que atrapes vayan a una caja si tu equipo está lleno."),
  "get_proc"    => proc { next $PokemonSystem.sendtoboxes },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.sendtoboxes = value }
})

MenuHandlers.add(:options_menu, :give_nicknames, {
  "name"        => _INTL("Poner motes"),
  "order"       => 80,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Sí"), _INTL("No")],
  "description" => _INTL("Activa esta opción para tener la posibilidad de poner motes a los Pokémon que atrapes."),
  "get_proc"    => proc { next $PokemonSystem.givenicknames },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.givenicknames = value }
})

MenuHandlers.add(:options_menu, :speech_frame, {
  "name"        => _INTL("Marco de Texto"),
  "order"       => 90,
  "type"        => NumberOption,
  "parameters"  => 1..$SpeechFrames.length,
  "description" => _INTL("Elige la apariencia de las cajas de diálogos."),
  "condition"   => proc { next NO_TETXBOX_OPTIONS },
  "get_proc"    => proc { next $PokemonSystem.textskin },
  "set_proc"    => proc { |value, scene|
    $PokemonSystem.textskin=value
    MessageConfig.pbSetSpeechFrame("Graphics/Windowskins/"+$SpeechFrames[value])
    scene.sprites["textbox"].setSkin(MessageConfig.pbGetSpeechFrame)
  }
})

MenuHandlers.add(:options_menu, :menu_frame, {
  "name"        => _INTL("Marco de Menú"),
  "order"       => 100,
  "type"        => NumberOption,
  "parameters"  => 1..$TextFrames.length,
  "description" => _INTL("Elige la apariencia de los mensajes de menús."),
  "get_proc"    => proc { next $PokemonSystem.frame },
  "condition"   => proc { next NO_TETXBOX_OPTIONS },
  "set_proc"    => proc { |value, scene|
    $PokemonSystem.frame=value
    MessageConfig.pbSetSystemFrame($TextFrames[value]) 
    scene.sprites["option"].setSkin(MessageConfig.pbGetSystemFrame)
  }
})

MenuHandlers.add(:options_menu, :text_input_style, {
  "name"        => _INTL("Entrada de Texto"),
  "order"       => 110,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Cursor"), _INTL("Teclado")],
  "description" => _INTL("Elige cómo quieres introducir el texto."),

  "get_proc"    => proc { next $PokemonSystem.textinput },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.textinput = value }
})

MenuHandlers.add(:options_menu, :screen_size, {
  "name"        => _INTL("Tamaño Pantalla"),
  "order"       => 120,
  "type"        => EnumOption,
  "parameters"  => [_INTL("S"), _INTL("M"), _INTL("L"), _INTL("XL"), _INTL("Full")],
  "description" => _INTL("Elige el tamaño de la ventana de juego."),
  "condition"   => proc { next $MKXP },
  "get_proc"    => proc { next [$PokemonSystem.screensize, 4].min },
  "set_proc"    => proc { |value, _scene|
    next if $PokemonSystem.screensize == value
    $PokemonSystem.screensize = value
    pbSetResizeFactor($PokemonSystem.screensize)
  }
})