#===============================================================================
#
#===============================================================================
class PokegearButton < Sprite
  attr_reader :index
  attr_reader :name
  attr_reader :selected

  TEXT_BASE_COLOR = Color.new(248, 248, 248)
  TEXT_SHADOW_COLOR = Color.new(40, 40, 40)

  def initialize(command, x, y, viewport = nil)
    super(viewport)
    @image = command[0]
    @name  = command[1]
    @selected = false
    if $Trainer.isFemale? && pbResolveBitmap("Graphics/#{POKEGEAR_ROUTE}/pokegearButtonf")
      @button = AnimatedBitmap.new("Graphics/#{POKEGEAR_ROUTE}/pokegearButtonf")
    else
      @button = AnimatedBitmap.new("Graphics/#{POKEGEAR_ROUTE}/pokegearButton")
    end
    @contents = Bitmap.new(@button.width, @button.height)
    self.bitmap = @contents
    self.x = x - (@button.width / 2)
    self.y = y
    pbSetSystemFont(self.bitmap)
    refresh
  end

  def dispose
    @button.dispose
    @contents.dispose
    super
  end

  def selected=(val)
    oldsel = @selected
    @selected = val
    refresh if oldsel != val
  end

  def refresh
    self.bitmap.clear
    rect = Rect.new(0, 0, @button.width, @button.height / 2)
    rect.y = @button.height / 2 if @selected
    self.bitmap.blt(0, 0, @button.bitmap, rect)
    textpos = [
      [@name, rect.width / 2, (rect.height / 2) - 10, 2, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR]
    ]
    pbDrawTextPositions(self.bitmap, textpos)
    icon=sprintf("Graphics/#{POKEGEAR_ROUTE}/pokegear"+@image)
    imagepos=[         # Icon is put on both unselected and selected buttons
       [icon,18,10,0,0,-1,-1],
       #[icon,18,62,0,0,-1,-1]
    ]
    pbDrawImagePositions(self.bitmap,imagepos)
  end
end

#===============================================================================
#
#===============================================================================
class Scene_Pokegear
  def pbUpdate
    @commands.length.times do |i|
      @sprites["button#{i}"].selected = (i == @index)
    end
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(commands)
    @commands = commands
    @index = 0
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    if $Trainer.isFemale? && pbResolveBitmap("Graphics/#{POKEGEAR_ROUTE}/pokegearbgf")
      @sprites["background"].setBitmap("Graphics/#{POKEGEAR_ROUTE}/pokegearbgf")
    else
      @sprites["background"].setBitmap("Graphics/#{POKEGEAR_ROUTE}/pokegearbg")
    end
    @commands.length.times do |i|
      @sprites["button#{i}"] = PokegearButton.new(@commands[i], Graphics.width / 2, 0, @viewport)
      button_height = @sprites["button#{i}"].bitmap.height / 2
      @sprites["button#{i}"].y = ((Graphics.height - (@commands.length * button_height)) / 2) + (i * button_height)
    end
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbScene
    ret = -1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        ret = @index
        break
      elsif Input.trigger?(Input::UP)
        pbPlayCursorSE if @commands.length > 1
        @index -= 1
        @index = @commands.length - 1 if @index < 0
      elsif Input.trigger?(Input::DOWN)
        pbPlayCursorSE if @commands.length > 1
        @index += 1
        @index = 0 if @index >= @commands.length
      end
    end
    return ret
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    dispose
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPokegearScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    # Get all commands
    command_list = []
    commands = []
    MenuHandlers.each_available(:pokegear_menu) do |option, hash, name|
      command_list.push([hash["icon_name"] || "", name])
      commands.push(hash)
    end
    @scene.pbStartScene(command_list)
    # Main loop
    end_scene = false
    loop do
      choice = @scene.pbScene
      if choice < 0
        end_scene = true
        break
      end
      break if commands[choice]["effect"].call(@scene)
    end
    @scene.pbEndScene if end_scene
  end
end

#===============================================================================
#
#===============================================================================
MenuHandlers.add(:pokegear_menu, :map, {
  "name"      => _INTL("Mapa"),
  "icon_name" => "map",
  "order"     => 10,
  "effect"    => proc { |menu|
    pbShowMap(-1,false)
  }
})

MenuHandlers.add(:pokegear_menu, :phone, {
  "name"      => _INTL("Teléfono"),
  "icon_name" => "phone",
  "order"     => 20,
  "condition" => proc { next if $PokemonGlobal.phoneNumbers.length>0 },
  "effect"    => proc { |menu|
    pbFadeOutIn do
       PokemonPhoneScene.new.start
    end
    next false
  }
})

MenuHandlers.add(:pokegear_menu, :jukebox, {
  "name"      => _INTL("Jukebox"),
  "icon_name" => "jukebox",
  "order"     => 30,
  "effect"    => proc { |menu|
    pbFadeOutIn do
      scene = Scene_Jukebox.new
      screen = PokemonJukeboxScreen.new(scene)
      screen.pbStartScreen
    end
    next false
  }
})
