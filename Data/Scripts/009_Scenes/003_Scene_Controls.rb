#==============================================================================
# * Scene_Controls
#------------------------------------------------------------------------------
# Muestra una pantalla de ayuda comentando los controles del teclado.
# Muestra con: 
#      pbEventScreen(ButtonEventScene)
#==============================================================================
class ButtonEventScene < EventScene
  def initialize(viewport=nil)
    super
    Graphics.freeze
    addImage(0,0,"Graphics/Pictures/helpbg")
    @labels=[
       addLabel(52*2,13*2,Graphics.width*3/4,_INTL("Para mover el personaje principal. También usado para desplazarse en los listados.")),
       addLabel(52*2,53*2,Graphics.width*3/4,_INTL("Usado para confirmar una selección, activar cosas y hablar con la gente.")),
       addLabel(52*2,93*2,Graphics.width*3/4,_INTL("Usado para salir, cancelar una selección o modo y abrir el menú del juego.")),
       addLabel(52*2,133*2,Graphics.width*3/4,_INTL("Mantener presionado mientras camina para correr.")),
       addLabel(52*2,157*2,Graphics.width*3/4,_INTL("Presionar para usar un Objeto Clave registrado."))
    ]
    @keys=[
       addImage(26*2,18*2,"Graphics/Pictures/helpArrowKeys"),
       addImage(26*2,59*2,"Graphics/Pictures/helpCkey"),
       addImage(26*2,99*2,"Graphics/Pictures/helpXkey"),
       addImage(26*2,130*2,"Graphics/Pictures/helpZkey"),
       addImage(26*2,154*2,"Graphics/Pictures/helpF5key")
    ]
    for key in @keys
      key.origin=PictureOrigin::Top
    end
    for i in 0...5      # Hace que se muestre todo (casi) inmediatamente
      @labels[i].moveOpacity(1,0,255)
      @keys[i].moveOpacity(1,0,255)
    end
    pictureWait         # Actualiza la pantalla con todos los cambios
    Graphics.transition(20)
    # Go to next screen when user presses C
    onCTrigger.set(method(:pbOnScreen1))
  end

  def pbOnScreen1(scene,args)
    # Final de la escena
    Graphics.freeze
    scene.dispose
    Graphics.transition(20)
  end
end