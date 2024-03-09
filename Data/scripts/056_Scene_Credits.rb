# Fondos usados en los créditos. Se encuentran en la carpeta Graphics/Titles/
CreditsBackgroundList = ["credits1","credits2","credits3","credits4","credits5"]
CreditsMusic          = "begin"
CreditsScrollSpeed    = 1             # Al menos 1; mantenlo menor a 5 para que se pueda leer.
CreditsFrequency      = 8             # Cantidad de segundos por cambio de créditos.
CREDITS_OUTLINE       = Color.new(0,0,128, 255)
CREDITS_SHADOW        = Color.new(0,0,0, 100)
CREDITS_FILL          = Color.new(255,255,255, 255)

#==============================================================================
# * Scene_Credits
#------------------------------------------------------------------------------
# Desplazamiento de los créditos que se definan abajo. Autor original desconocido.
#
## Editado por MiDas Mike de forma que no se reproduce sobre el Title, sino que
# se ejecuta llamándolo de la siguiente forma:
#    $scene = Scene_Credits.new
#
## Edición nueva 3/6/2007 11:14 PM por AvatarMonkeyKirby.
# Bueno, lo que hice es cambiar la parte del script que se suponía que terminaba
# automáticamente los crétidos de forma que ahora realmente termina. Si, ahora
# terminarán cuando los créditos hayan pasado. Así que, con esto, las personas a
# las que debes agradecer ahora son: Unknown, MiDas Mike, and AvatarMonkeyKirby.
#                                             -sinceramente tuyo,
#                                               Tu Amado
# Oh si, además agregué una línea al final que desvanece la música de fondo de
# forma más rápida y suave.
#
## Edición nueva 24/1/2012 por Maruno.
# Agregué la posibilidad de partir una línea en dos partes iguales con <s>, con
# cada mital alineadas hacia el centro. Por favor, ponerme en los créditos si
# lo usas.
#
## Edición nueva 22/2/2012 por Maruno.
# Los creditos ahora se desplazan apropiadamente cuando se está usando un
# zoom de 0.5. Ahora se puede definir la música. Los créditos no se pueden
# omitir la primera vez que pasan.
#==============================================================================

class Scene_Credits

# La siguiente sección de código son los créditos.
# ¡Comienza a editar!
CREDIT=<<_END_

Tus créditos van aquí.

Tus créditos van aquí.

Tus créditos van aquí.

Tus créditos van aquí.

Tus créditos van aquí.



"Pokémon Essentials" fue creado por:
Flameguru
Poccil (Peter O.)
Maruno

Con contribuciones de:
AvatarMonkeyKirby<s>Luka S.J.
Boushy<s>MiDas Mike
Brother1440<s>Near Fantastica
FL.<s>PinkMan
Genzai Kawakami<s>Popper
Harshboy<s>Rataime
help-14<s>SoundSpawn
IceGod64<s>the__end
Jacob O. Wobbrock<s>Venom12
KitsuneKouta<s>Wachunga
Lisa Anthony<s>xLeD
y a todos los que dieron su ayuda



"RPG Maker XP" de:
Enterbrain

Pokémon es propiedad de:
The Pokémon Company
Nintendo
Socios de Game Freak

Éste es un juego hecho por fans sin fines de lucro.
No se pretende incumplir derechos de autor.
¡Por favor, apoya a los juegos oficiales!

_END_
# ¡Dejar de editar aquí!

  def main
#---------------------------------
# Configuración del fondo animado
#---------------------------------
    @sprite = IconSprite.new(0,0)
    @backgroundList = CreditsBackgroundList
    @backgroundGameFrameCount = 0
    # Number of game frames per background frame.
    @backgroundG_BFrameCount = CreditsFrequency * Graphics.frame_rate
    @sprite.setBitmap("Graphics/Titles/"+@backgroundList[0])
#-----------------------------------------
# Configuración del texto de los créditos
#-----------------------------------------
    credit_lines = CREDIT.split(/\n/)
    credit_bitmap = Bitmap.new(Graphics.width,32 * credit_lines.size)
    credit_lines.each_index do |i|
      line = credit_lines[i]
      line = line.split("<s>")
      # LÍNEA NUEVA: Si utilizas el kit en tu juego propio, deberías quitar esta línea
      pbSetSystemFont(credit_bitmap) # <--- Esta línea ha sido agregada
      x = 0
      xpos = 0
      align = 1     # Alineación al centro
      linewidth = Graphics.width
      for j in 0...line.length
        if line.length>1
          xpos = (j==0) ? 0 : 20 + Graphics.width/2
          align = (j==0) ? 2 : 0    # Alineación derecha : izquierda
          linewidth = Graphics.width/2 - 20
        end
        credit_bitmap.font.color = CREDITS_SHADOW
        credit_bitmap.draw_text(xpos,i * 32 + 8,linewidth,32,line[j],align)
        credit_bitmap.font.color = CREDITS_OUTLINE
        credit_bitmap.draw_text(xpos + 2,i * 32 - 2,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos,i * 32 - 2,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos - 2,i * 32 - 2,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos + 2,i * 32,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos - 2,i * 32,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos + 2,i * 32 + 2,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos,i * 32 + 2,linewidth,32,line[j],align)
        credit_bitmap.draw_text(xpos - 2,i * 32 + 2,linewidth,32,line[j],align)
        credit_bitmap.font.color = CREDITS_FILL
        credit_bitmap.draw_text(xpos,i * 32,linewidth,32,line[j],align)
      end
    end
    @trim=Graphics.height/10
    @credit_sprite = Sprite.new(Viewport.new(0,@trim,Graphics.width,Graphics.height-(@trim*2)))
    @credit_sprite.bitmap = credit_bitmap
    @credit_sprite.z = 9998
    @credit_sprite.oy = -(Graphics.height-@trim) #-430
    @frame_index = 0
    @bg_index = 0
    @pixels_banked = 0
    @zoom_adjustment = 1/$ResizeFactor
    @last_flag = false
#---------------
# Configuración
#---------------
    #Detiene todas las pistas menos la música de fondo.
    previousBGM = $game_system.getPlayingBGM
    pbMEStop()
    pbBGSStop()
    pbSEStop()
    pbBGMFade(2.0)
    pbBGMPlay(CreditsMusic)
    Graphics.transition
    loop do
      Graphics.update
      Input.update
      update
      if $scene != self
        break
      end
    end
    Graphics.freeze
    @sprite.dispose
    @credit_sprite.dispose
    $PokemonGlobal.creditsPlayed=true
    pbBGMPlay(previousBGM)
  end

# Revisa si el mapa de bit de los créditos ha alcanzado su punto final
  def last?
    if @frame_index > (@credit_sprite.bitmap.height + Graphics.height + (@trim/2))
      $scene = ($game_map) ? Scene_Map.new : nil
      pbBGMFade(2.0)
      return true
    end
    return false
  end

# Revisa si los créditos deberían ser cancelados
  def cancel?
    if Input.trigger?(Input::C) && $PokemonGlobal.creditsPlayed
      $scene = Scene_Map.new
      pbBGMFade(1.0)
      return true
    end
    return false
  end

  def update
    @backgroundGameFrameCount += 1
    if @backgroundGameFrameCount >= @backgroundG_BFrameCount        # Diapositiva siguiente
      @backgroundGameFrameCount = 0
      @bg_index += 1
      @bg_index = 0 if @bg_index >= @backgroundList.length
      @sprite.setBitmap("Graphics/Titles/"+@backgroundList[@bg_index])
    end
    return if cancel?
    return if last?
    @pixels_banked += CreditsScrollSpeed
    if @pixels_banked>=@zoom_adjustment
      @credit_sprite.oy += (@pixels_banked - @pixels_banked%@zoom_adjustment)
      @pixels_banked = @pixels_banked%@zoom_adjustment
    end
    @frame_index += CreditsScrollSpeed    # Esto debería corregir el problema de finalización automática
  end
end