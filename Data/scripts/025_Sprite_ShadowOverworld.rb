# In order for the shadow to be invisible, the name of the event must 
# contain a string that is defined in No_Shadow_If_Event_Name_Has, or having 
# a comment containing the exact string NoShadow (case sensitive for the comment).

# Extending so we can access some private instance variables.
class Game_Character
  attr_reader :jump_count
  attr_reader :name 
end

class Sprite_ShadowOverworld
  attr_reader :visible
  attr_accessor :event
    
  def initialize(sprite,event,viewport=nil)
    @rsprite  = sprite
    @sprite   = nil
    @event    = event
    @viewport = viewport
    @disposed = false
    @shadowoverworldbitmap = AnimatedBitmap.new("Graphics/Characters/shadow")
    @cws = @shadowoverworldbitmap.height*2
    @chs = @shadowoverworldbitmap.height*2
    update
  end

  def dispose; if !@disposed; @sprite.dispose if @sprite; @sprite = nil; @disposed = true; end; end

  def disposed?; @disposed; end
      
  def ShouldGetShadow?
    return false if event.character_name =="" || event.character_name == "nil" ||
                   (PBTerrain.isGrass?(pbGetTerrainTag(event)) || 
                    PBTerrain.hasReflections?(pbGetTerrainTag(event)) || 
                    PBTerrain.isSurfable?(pbGetTerrainTag(event)) || 
                    PBTerrain.isIce?(pbGetTerrainTag(event))) ||
                    (event!=$game_player && pbEventCommentInput(event,0,"NoShadow")) ||
                    (event!=$game_player && pbEventCommentInput(event,0,"noShadow")) ||
                    event.transparent
                      
    if event.name != nil
      name=event.name.dup
      name.downcase!
      No_Shadow_If_Event_Name_Has.each do |e|
        e.downcase!
        return false if name.include?(e)
      end
    end
    return true
  end
    
  def jump_sprite
    return unless @sprite
    x = (@event.real_x - @event.map.display_x + 3) / 4 + (Game_Map::TILEWIDTH / 2)
    y = (@event.real_y - @event.map.display_y + 3) / 4 + (Game_Map::TILEHEIGHT)
    @totaljump = @event.jump_count if !@totaljump
    case @event.jump_count
    when 1..(@totaljump / 3); @sprite.zoom_x += 0.1; @sprite.zoom_y += 0.1
    when (@totaljump / 3 + 1)..(@totaljump / 3 + 2); @sprite.zoom_x += 0.05; @sprite.zoom_y += 0.05
    when (@totaljump / 3 * 2 - 1)..(@totaljump / 3 * 2); @sprite.zoom_x -= 0.05; @sprite.zoom_y -= 0.05
    when (@totaljump / 3 * 2 + 1)..(@totaljump); @sprite.zoom_x -= 0.1; @sprite.zoom_y -= 0.1
    end
    if @event.jump_count == 1; @sprite.zoom_x = 1.0; @sprite.zoom_y = 1.0; @totaljump = nil; end
    @sprite.x = x; @sprite.y = y; @sprite.z = @rsprite.z - 1
  end

  def visible=(value); @visible = value; @sprite.visible = value if @sprite && !@sprite.disposed?; end

  def update
    return if disposed? || !$scene || !$scene.is_a?(Scene_Map)
    return jump_sprite if event.jumping?
    if !ShouldGetShadow?
      # Just-in-time disposal of sprite 
      if @sprite; @sprite.dispose; @sprite = nil; end; return; end
    # Just-in-time creation of sprite
    @sprite = Sprite.new(@viewport) if !@sprite
    if @sprite
      @sprite.bitmap = @shadowoverworldbitmap.bitmap; cw = @cws; ch = @chs
      @sprite.x       = @rsprite.x-1
      @sprite.y       = @rsprite.y
      @sprite.ox      = cw/2 -1
      @sprite.oy      = ch -18
      @sprite.z       = @rsprite.z-1
      @sprite.zoom_x  = @rsprite.zoom_x
      @sprite.zoom_y  = @rsprite.zoom_y
      @sprite.tone    = @rsprite.tone
      @sprite.color   = @rsprite.color
      @sprite.opacity = @rsprite.opacity
    end
  end
end
