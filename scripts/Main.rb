class Scene_DebugIntro
  def initialize
    if !$pkmn_animations
      $pkmn_animations = load_data("Data/PkmnAnimations.rxdata")
    end
  end
  
  def main
    Graphics.transition(0)
    sscene=PokemonLoadScene.new
    sscreen=PokemonLoad.new(sscene)
    sscreen.pbStartLoadScreen
    Graphics.freeze
  end
end



def pbCallTitle #:nodoc:
  if $DEBUG
    return Scene_DebugIntro.new
  else
    # El primer parámetro es un arreglo de imágenes de la carpeta Titles
    # sin la extensión del archivo, que se mostrarán antes de la pantalla
    # de títulos real. El segundo parámetro es el nombre del archivo de
    # la pantalla de títulos real, también en Titles sin extensión.
    return Scene_Intro.new(['intro1'], 'splash') 
  end
end

def mainFunction #:nodoc:
  if $DEBUG
    pbCriticalCode { mainFunctionDebug }
  else
    mainFunctionDebug
  end
  return 1
end

def mainFunctionDebug #:nodoc:
  begin
    getCurrentProcess=Win32API.new("kernel32.dll","GetCurrentProcess","","l")
    setPriorityClass=Win32API.new("kernel32.dll","SetPriorityClass",%w(l i),"")
    setPriorityClass.call(getCurrentProcess.call(),32768) # "Above normal" priority class
    $data_animations    = pbLoadRxData("Data/Animations")
    $data_tilesets      = pbLoadRxData("Data/Tilesets")
    $data_common_events = pbLoadRxData("Data/CommonEvents")
    $data_system        = pbLoadRxData("Data/System")
    $game_system        = Game_System.new
    setScreenBorderName("border") # Estable el archivo de imágen para los bordes
    Graphics.update
    Graphics.freeze
    $scene = pbCallTitle
    while $scene != nil
      $scene.main
    end
    Graphics.transition(20)
  rescue Hangup
    pbEmergencySave
    raise
  end
end

loop do
  retval=mainFunction
  if retval==0 # falla
    loop do
      Graphics.update
    end
  elsif retval==1 # termina exitosamente
    break
  end
end