class PokeBattle_Battler
  alias absM_initialize initialize
  def initialize(btl,index)
    absM_initialize(btl,index)
    pbInitAbilMessage
  end
end

#=============================================================================
# Ability messages based on EBS
# Credits for code go to Luka S.J.
#=============================================================================
class PokeBattle_Battler
  def showAbilityMessage(battler,hide=true)
    return if battler.pokemon.nil?
    effect=PBAbilities.getName(battler.ability)    
    bitmap=Bitmap.new("Graphics/Pictures/Battle/abilityMessage")
    rect=(battler.index%2==0) ? Rect.new(0,56,280,56) : Rect.new(0,0,280,56)
    baseColor=Color.new(255,255,255)
    shadowColor=Color.new(32,32,32)
    @sprites["abilityMessage"].bitmap.clear
    @sprites["abilityMessage"].bitmap.blt(0,0,bitmap,rect)
    
    bitmap=@sprites["abilityMessage"].bitmap    
    pbDrawTextPositions(bitmap, [
      ["#{effect}", 32, 0, 0,baseColor,shadowColor, true],
      [_INTL("de {1}",battler.pokemon.name), 32, 32, 0,baseColor,shadowColor, true]
    ])
    
    @sprites["abilityMessage"].x=(battler.index%2==0) ? -280 : Graphics.width
    o = 32
    @sprites["abilityMessage"].y=(battler.index%2==0) ? 256 - o : 160 + o

    pbSEPlay("BW_ability")
    
    10.times do
      @sprites["abilityMessage"].x+=(battler.index%2==0) ? 28 : -28
      @sprites["abilityMessage"].zoom_y+=0.1
      Graphics.update
    end
    
    t=255
    @sprites["abilityMessage"].tone=Tone.new(t,t,t)
    50.times do
    t-=25.5 if t > 0
    @sprites["abilityMessage"].tone=Tone.new(t,t,t)
    Input.update
    Graphics.update
    end
    pbWait(20)
    hideAbilityMessage(battler) if hide
    
  end
    
  def hideAbilityMessage(battler)
    10.times do
      @sprites["abilityMessage"].x+=(battler.index%2==0) ? -28 : 28
      @sprites["abilityMessage"].zoom_y-=0.1
      Graphics.update
    end
  end

  def pbInitAbilMessage
    @viewport= Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=999999
    @sprites={}
    @sprites["abilityMessage"]=Sprite.new(@viewport)
    @sprites["abilityMessage"].bitmap=Bitmap.new(280,68)
    pbSetSystemFont(@sprites["abilityMessage"].bitmap)
    @sprites["abilityMessage"].oy=@sprites["abilityMessage"].bitmap.height/2+6
    @sprites["abilityMessage"].zoom_y=0
    @sprites["abilityMessage"].z=99999
  end

end