#elena hizo esta cosa, ponedla encima de main y aseguraos de tener las imagenes en pictures

GOALFPS   =120 #los fps a los que el juego llega con el turbo
STAYFRAMES= 148 #el tiempo que el iconito esta en pantalla

$buttonframes = STAYFRAMES

module Graphics
  class << self
    alias _update_turbo_anim update
    
    def update
      _update_turbo_anim
      if $buttonframes < STAYFRAMES
        if !@button || @button.disposed?
          @button = Sprite.new
          @button.z = 999999
        end
        set_button_bitmap
        $buttonframes += 1
        @button.dispose if $buttonframes == STAYFRAMES
      end
    end

    def set_button_bitmap
      if $GameSpeed == 0
        bitmap_path = "Graphics/Pictures/FastForward"
      elsif $GameSpeed == 1
        bitmap_path = "Graphics/Pictures/FastForward1" 
      else
        bitmap_path = "Graphics/Pictures/FastForward2"
      end
      @button.bitmap = Bitmap.new(bitmap_path)
    end
    
  end
end

#==============================================================================#
#                         Better Fast-forward Mode                             #
#                                   v1.0                                       #
#                                                                              #
#                                 by Marin                                     #
#==============================================================================#
#                                   Usage                                      #
#                                                                              #
# SPEEDUP_STAGES are the speed stages the game will pick from. If you click F, #
# it'll choose the next number in that array. It goes back to the first number #
#                                 afterward.                                   #
#                                                                              #
#             $GameSpeed is the current index in the speed up array.           #
#   Should you want to change that manually, you can do, say, $GameSpeed = 0   #
#                                                                              #
# If you don't want the user to be able to speed up at certain points, you can #
#                use "pbDisallowSpeedup" and "pbAllowSpeedup".                 #
#==============================================================================#

# When the user clicks F, it'll pick the next number in this array.
SPEEDUP_STAGES = [1,2,3]

def pbAllowSpeedup
  $CanToggle = true
end

def pbDisallowSpeedup
  $CanToggle = false
  $GameSpeed = 0
end

# Default game speed.
$GameSpeed = 0

$frame = 0

$CanToggle = false
$CanToggle = true if ($DEBUG || TURBO_DEBUG)

module Graphics
  class << Graphics
    alias fast_forward_update update
  end
  
  def self.update 
    if $CanToggle && Input.trigger?(Input::ALT) 
      $buttonframes = 0
      $GameSpeed += 1
      $GameSpeed = 0 if $GameSpeed >= SPEEDUP_STAGES.size
    end
    $frame += 1
    return unless $frame % SPEEDUP_STAGES[$GameSpeed] == 0
    fast_forward_update
    $frame = 0
  end
end
