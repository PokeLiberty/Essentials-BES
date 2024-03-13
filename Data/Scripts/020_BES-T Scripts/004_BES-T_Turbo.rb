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
      bitmap_path = Graphics.frame_rate <= 60 ? "Graphics/Pictures/FastForward" : "Graphics/Pictures/FastForward1"
      @button.bitmap = Bitmap.new(bitmap_path)
    end
    
  end
end

#reescribe el turbo
def pbTurbo()
  if $DEBUG || TURBO_DEBUG
    $buttonframes = 0
		if Graphics.frame_rate<=60
			Graphics.frame_rate=GOALFPS #Velocidad de frames a la que es aumentada [predeterminada 130]
		else
      Graphics.frame_rate = 40 
      Graphics.frame_rate = 60 if FPS60 && $MKXP
		end	
  end
end