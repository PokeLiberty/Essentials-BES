def pbSafeCopyFile(x,y,z=nil)
  if safeExists?(x)
    safetocopy=true
    filedata=nil
    if safeExists?(y)
      different=false
      if FileTest.size(x)!=FileTest.size(y)
        different=true
      else
        filedata2=""
        File.open(x,"rb"){|f| filedata=f.read }
        File.open(y,"rb"){|f| filedata2=f.read }
        if filedata!=filedata2
          different=true
        end
      end
      if different
        safetocopy=Kernel.pbConfirmMessage(
           _INTL("A different file named '{1}' already exists. Overwrite it?",y))
      else
        # No need to copy
        return
      end
    end
    if safetocopy
      if !filedata
        File.open(x,"rb"){|f| filedata=f.read }
      end
      File.open(z ? z : y,"wb"){|f| f.write(filedata) }
    end
  end
end

def pbAllocateAnimation(animations,name)
  for i in 1...animations.length
    anim=animations[i]
    if !anim
      return i
    end
#    if name && name!="" && anim.name==name
#      # use animation with same name
#      return i
#    end
    if anim.length==1 && anim[0].length==2 && anim.name==""
      # assume empty
      return i
    end
  end
  oldlength=animations.length
  animations.resize(10)
  return oldlength
end

def pbEditorMenu
  viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z=99999
  sprites={}
  data_system=pbLoadRxData("Data/System")
  sprites["cmdwindow"]=Window_CommandPokemonEx.new([
     _INTL("Edit Items"),
     _INTL("Edit Pokémon"),
     _INTL("Reposition Sprites"),
     _INTL("Auto-Position All Sprites"),
     _INTL("Edit Regional Dexes"),
     _INTL("Edit Trainer Types"),
     _INTL("Edit Trainers"),
     _INTL("Set Encounters"),
     _INTL("Set Metadata"),
     _INTL("Map Connections"),
     _INTL("Set Terrain Tags"),
     _INTL("Animation Editor"),
     _INTL("Extract Text"),
     _INTL("Compile Text"),
     _INTL("Compile Data")
  ])
  cmdwindow=sprites["cmdwindow"]
  cmdwindow.viewport=viewport
  cmdwindow.resizeToFit(cmdwindow.commands)
  cmdwindow.height=Graphics.height if cmdwindow.height>Graphics.height
  cmdwindow.x=0
  cmdwindow.y=0
  cmdwindow.visible=true
  pbFadeInAndShow(sprites)
  ret=-1
  loop do
    loop do
      cmdwindow.update
      Graphics.update
      Input.update
      if safeExists?("extendtext.exe") && Graphics.frame_count%Graphics.frame_rate == 0
        Thread.new {Thread.stop;system("extendtext")}.run
      end
      if Input.trigger?(Input::B)
        ret=-1
        break
      end
      if Input.trigger?(Input::C)
        ret=cmdwindow.index
        break
      end
    end
    break if ret==-1
    if ret==0 # Edit Items
      pbFadeOutIn(99999) { pbItemEditor }
    elsif ret==1 # Edit Pokémon
      pbFadeOutIn(99999) { pbPokemonEditor }
    elsif ret==2 # Reposition Sprites
      pbFadeOutIn(99999) {
         sp=SpritePositioner.new
         sps=SpritePositionerScreen.new(sp)
         sps.pbStart
      }
    elsif ret==3 # Auto-Position All Sprites
      if Kernel.pbConfirmMessage(_INTL("Are you sure you want to reposition all sprites?"))
        msgwindow=Kernel.pbCreateMessageWindow
        Kernel.pbMessageDisplay(msgwindow,_INTL("Repositioning all sprites. Please wait."),false)
        Graphics.update
        pbAutoPositionAll()
        Kernel.pbDisposeMessageWindow(msgwindow)
      end
    elsif ret==4 # Edit Regional Dexes
      pbFadeOutIn(99999) { pbRegionalNumbersEditor }
    elsif ret==5 # Edit Trainer Types
      pbFadeOutIn(99999) { pbTrainerTypeEditor }
    elsif ret==6 # Edit Trainers
      pbFadeOutIn(99999) { pbTrainerBattleEditor }
    elsif ret==7 # Set Encounters
      encdata=load_data("Data/encounters.dat")
      map=data_system ? data_system.edit_map_id : 0
      loop do
        map=pbListScreen(_INTL("SET ENCOUNTERS"),MapLister.new(map))
        break if map<=0
        pbEncounterEditorMap(encdata,map)
      end
      save_data(encdata,"Data/encounters.dat")
      pbSaveEncounterData()
    elsif ret==8 # Set Metadata
      pbMetadataScreen(data_system ? data_system.edit_map_id : 0)
    elsif ret==9 # Map Connections
      pbFadeOutIn(99999) { pbEditorScreen }
    elsif ret==10 # Set Terrain Tags
      pbFadeOutIn(99999) { pbTilesetScreen }
    elsif ret==11 # Animations
      subcommand=Kernel.pbShowCommands(nil,[
         _INTL("Animation Editor"),
         _INTL("Export All Animations"),
         _INTL("Import All Animations")
      ],-1)
      if subcommand==0 # Animation Editor
        pbFadeOutIn(99999) { pbAnimationEditor }
      elsif subcommand==1 # Export All Animations
        begin
          Dir.mkdir("Animations") rescue nil
          animations=tryLoadData("Data/PkmnAnimations.rxdata")
          if animations
            msgwindow=Kernel.pbCreateMessageWindow
            for anim in animations
              next if !anim || anim.length==0 || anim.name==""
              Kernel.pbMessageDisplay(msgwindow,anim.name,false)
              Graphics.update
              safename=anim.name.gsub(/\W/,"_")
              Dir.mkdir("Animations/#{safename}") rescue nil
              File.open("Animations/#{safename}/#{safename}.anm","wb"){|f|
                 f.write(dumpBase64Anim(anim))
              }
              if anim.graphic && anim.graphic!=""
                graphicname=RTP.getImagePath("Graphics/Animations/"+anim.graphic)
                pbSafeCopyFile(graphicname,"Animations/#{safename}/"+File.basename(graphicname))
              end
              for timing in anim.timing
                if !timing.timingType || timing.timingType==0
                  if timing.name && timing.name!=""
                    audioName=RTP.getAudioPath("Audio/SE/"+timing.name)
                    pbSafeCopyFile(audioName,"Animations/#{safename}/"+File.basename(audioName))
                  end
                elsif timing.timingType==1 || timing.timingType==3
                  if timing.name && timing.name!=""
                    graphicname=RTP.getImagePath("Graphics/Animations/"+timing.name)
                    pbSafeCopyFile(graphicname,"Animations/#{safename}/"+File.basename(graphicname))
                  end
                end
              end
            end
            Kernel.pbDisposeMessageWindow(msgwindow)
            Kernel.pbMessage(_INTL("All animations were extracted and saved to the Animations folder."))
          else
            Kernel.pbMessage(_INTL("There are no animations to export."))
          end
        rescue
          p $!.message,$!.backtrace
          Kernel.pbMessage(_INTL("The export failed."))
        end
      elsif subcommand==2 # Import All Animations
        animationFolders=[]
        if safeIsDirectory?("Animations")
          Dir.foreach("Animations"){|fb|
             f="Animations/"+fb
             if safeIsDirectory?(f) && fb!="." && fb!=".."
               animationFolders.push(f)
             end
          }
        end
        if animationFolders.length==0
          Kernel.pbMessage(
             _INTL("There are no animations to import. Put each animation in a folder within the Animations folder."))
        else
          msgwindow=Kernel.pbCreateMessageWindow
          animations=tryLoadData("Data/PkmnAnimations.rxdata")
          animations=PBAnimations.new if !animations
          for folder in animationFolders
            Kernel.pbMessageDisplay(msgwindow,folder,false)
            Graphics.update
            audios=[]
            files=Dir.glob(folder+"/*.*")
            %w( wav ogg mid wma mp3 ).each{|ext|
               upext=ext.upcase
               audios.concat(files.find_all{|f| f[f.length-3,3]==ext})
               audios.concat(files.find_all{|f| f[f.length-3,3]==upext})
            }
            for audio in audios
              pbSafeCopyFile(audio,
                 RTP.getAudioPath("Audio/SE/"+File.basename(audio)),
                 "Audio/SE/"+File.basename(audio))
            end
            images=[]
            %w( png jpg bmp gif ).each{|ext|
               upext=ext.upcase
               images.concat(files.find_all{|f| f[f.length-3,3]==ext})
               images.concat(files.find_all{|f| f[f.length-3,3]==upext})
            }
            for image in images
              pbSafeCopyFile(image,
                 RTP.getImagePath("Graphics/Animations/"+File.basename(image)),
                 "Graphics/Animations/"+File.basename(image))
            end
            Dir.glob(folder+"/*.anm"){|f|
               textdata=loadBase64Anim(IO.read(f)) rescue nil
               if textdata && textdata.is_a?(PBAnimation)
                 index=pbAllocateAnimation(animations,textdata.name)
                 missingFiles=[]
                 if textdata.name==""
                   textdata.name=File.basename(folder)
                 end
                 textdata.id=-1 # this is not an RPG Maker XP animation
                 pbConvertAnimToNewFormat(textdata)
                 if textdata.graphic && textdata.graphic!=""
                   if !safeExists?(folder+"/"+textdata.graphic) &&
                      !FileTest.image_exist?("Graphics/Animations/"+textdata.graphic)
                     textdata.graphic=""; missingFiles.push(textdata.graphic)
                   end
                 end
                 for timing in textdata.timing
                   if timing.name && timing.name!=""
                     if !safeExists?(folder+"/"+timing.name) &&
                        !FileTest.audio_exist?("Audio/SE/"+timing.name)
                       timing.name=""; missingFiles.push(timing.name)
                     end
                   end
                 end
                 animations[index]=textdata
               end
            }
          end
          save_data(animations,"Data/PkmnAnimations.rxdata")
          Kernel.pbDisposeMessageWindow(msgwindow)
          Kernel.pbMessage(_INTL("All animations were imported."))
        end
      end
    elsif ret==12 # Extract Text
      pbExtractText
    elsif ret==13 # Compile Text
      pbCompileTextUI
    elsif ret==14 # Compile Data
      msgwindow=Kernel.pbCreateMessageWindow
      pbCompileAllData(true) {|msg| Kernel.pbMessageDisplay(msgwindow,msg,false) }
      Kernel.pbMessageDisplay(msgwindow,_INTL("All game data was compiled."))
      Kernel.pbDisposeMessageWindow(msgwindow)
    end
  end
  pbFadeOutAndHide(sprites)
  pbDisposeSpriteHash(sprites)
  viewport.dispose
end

pbCriticalCode { pbEditorMenu }