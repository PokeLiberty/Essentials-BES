#===============================================================================
# Register contacts
#===============================================================================
def pbPhoneRegisterNPC(ident,name,mapid,showmessage=true)
  $PokemonGlobal.phoneNumbers = [] if !$PokemonGlobal.phoneNumbers
  exists = pbFindPhoneTrainer(ident,name)
  if exists
    return if exists[0]   # Already visible
    exists[0] = true   # Make visible
  else
    phonenum = [true,ident,name,mapid]
    $PokemonGlobal.phoneNumbers.push(phonenum)
  end
  Kernel.pbMessage(_INTL("Se registró a {1} en el Pokégear.",name)) if showmessage
end

def pbPhoneRegister(event,trainertype,trainername)
  $PokemonGlobal.phoneNumbers = [] if !$PokemonGlobal.phoneNumbers
  return if pbFindPhoneTrainer(trainertype,trainername)
  phonenum = []
  phonenum.push(true)
  phonenum.push(trainertype)
  phonenum.push(trainername)
  phonenum.push(0)   # time to next battle
  phonenum.push(0)   # can battle
  phonenum.push(0)   # battle count
  if event
    phonenum.push(event.map.map_id)
    phonenum.push(event.id)
  end
  $PokemonGlobal.phoneNumbers.push(phonenum)
end

def pbPhoneDeleteContact(index)
  $PokemonGlobal.phoneNumbers[index][0] = false       # Remove from contact list
  if $PokemonGlobal.phoneNumbers[index].length==8
    $PokemonGlobal.phoneNumbers[index][3] = 0                  # Reset countdown
    $PokemonGlobal.phoneNumbers[index][4] = 0                  # Reset countdown
  end
end

def pbPhoneRegisterBattle(message,event,trainertype,trainername,maxbattles)
  return if !$Trainer.pokegear               # Can't register without a Pokégear
  if trainertype.is_a?(String) || trainertype.is_a?(Symbol)
    return false if !hasConst?(PBTrainers,trainertype)
    trainertype = PBTrainers.const_get(trainertype)
  end
  contact = pbFindPhoneTrainer(trainertype,trainername)
  return if contact && contact[0]              # Existing contact and is visible
  message=_INTL("Déjame registrarte.") if !message
  return unless Kernel.pbConfirmMessage(message)
  displayname = _INTL("{1} {2}",PBTrainers.getName(trainertype),
     pbGetMessageFromHash(MessageTypes::TrainerNames,trainername))
  if contact                          # Previously registered, just make visible
    contact[0] = true
  else                                                         # Add new contact
    pbPhoneRegister(event,trainertype,trainername)
    pbPhoneIncrement(trainertype,trainername,maxbattles)
  end
  Kernel.pbMessage(_INTL("Se registró a {1} en el Pokégear.",displayname))
end

#===============================================================================
# Contact information
#===============================================================================
def pbRandomPhoneTrainer
  $PokemonGlobal.phoneNumbers = [] if !$PokemonGlobal.phoneNumbers
  temparray = []
  currentRegion = pbGetMetadata($game_map.map_id,MetadataMapPosition)
  for num in $PokemonGlobal.phoneNumbers
    next if !num[0] || num.length!=8   # if not visible or not a trainer
    next if $game_map.map_id==num[6]   # Can't call if on same map
    callerRegion  = pbGetMetadata(num[6],MetadataMapPosition)
    # Can't call if in different region
    next if callerRegion && currentRegion && callerRegion[0]!=currentRegion[0]
    temparray.push(num)
  end
  return nil if temparray.length==0
  return temparray[rand(temparray.length)]
end

def pbFindPhoneTrainer(trtype,trname)           # Ignores whether visible or not
  return nil if !$PokemonGlobal.phoneNumbers
  trtype = getID(PBTrainers,trtype)
  return nil if !trtype || trtype<=0
  for num in $PokemonGlobal.phoneNumbers
    return num if num[1]==trtype && num[2]==trname   # If a match
  end
  return nil
end

def pbHasPhoneTrainer?(trtype,trname)
  return pbFindPhoneTrainer(trtype,trname)!=nil
end

def pbPhoneBattleCount(trtype,trname)
  trainer = pbFindPhoneTrainer(trtype,trname)
  return trainer[5] if trainer
  return 0
end

def pbPhoneReadyToBattle?(trtype,trname)
  trainer = pbFindPhoneTrainer(trtype,trname)
  return (trainer && trainer[4]>=2)
end

#===============================================================================
# Contact rematch data modifications
#===============================================================================
def pbPhoneIncrement(trtype,trname,maxbattles)
  trainer = pbFindPhoneTrainer(trtype,trname)
  return if !trainer
  trainer[5] += 1 if trainer[5]<maxbattles   # Increment battle count
  trainer[3] = 0   # reset time to can-battle
  trainer[4] = 0   # reset can-battle flag
end

def pbPhoneReset(trtype,trname)
  trainer = pbFindPhoneTrainer(trtype,trname)
  return false if !trainer
  trainer[3] = 0   # reset time to can-battle
  trainer[4] = 0   # reset can-battle flag
  return true
end

def pbSetReadyToBattle(num)
  return if !num[6] || !num[7]
  $game_self_switches[[num[6],num[7],"A"]] = false
  $game_self_switches[[num[6],num[7],"B"]] = true
  $game_map.need_refresh = true
end

#===============================================================================
# Phone-related counters
#===============================================================================
Events.onMapUpdate += proc { |_sender,_e|
  next if !$Trainer || !$Trainer.pokegear
  # Reset time to next phone call if necessary
  if !$PokemonGlobal.phoneTime || $PokemonGlobal.phoneTime<=0
    $PokemonGlobal.phoneTime = 20*60*Graphics.frame_rate
    $PokemonGlobal.phoneTime += rand(20*60*Graphics.frame_rate)
  end
  # Don't count down various phone times if other things are happening
  $PokemonGlobal.phoneNumbers = [] if !$PokemonGlobal.phoneNumbers
  next if $game_temp.in_menu || $game_temp.in_battle || $game_temp.message_window_showing
  next if $game_player.move_route_forcing || pbMapInterpreterRunning?
  # Count down time to next phone call
  $PokemonGlobal.phoneTime -= 1
  # Count down time to next can-battle for each trainer contact
  if $PokemonGlobal.phoneTime%Graphics.frame_rate==0   # Every second
    for num in $PokemonGlobal.phoneNumbers
      next if !num[0] || num.length!=8   # if not visible or not a trainer
      # Reset time to next can-battle if necessary
      if num[4]==0
        num[3] = 20*60+rand(20*60)   # 20-40 minutes
        num[4] = 1
      end
      # Count down time to next can-battle
      num[3] -= 1
      # Ready to battle
      if num[3]<=0 && num[4]==1
        num[4] = 2   # set ready-to-battle flag
        pbSetReadyToBattle(num)
      end
    end
  end
  # Time for a random phone call; generate one
  if $PokemonGlobal.phoneTime<=0
    # find all trainer phone numbers
    phonenum = pbRandomPhoneTrainer
    if phonenum
      call = pbPhoneGenerateCall(phonenum)
      pbPhoneCall(call,phonenum)
    end
  end
}

#===============================================================================
# Player calls a contact
#===============================================================================
def pbCallTrainer(trtype,trname)
  trainer = pbFindPhoneTrainer(trtype,trname)
  return if !trainer
  # Special NPC contacts
  if trainer.length!=8
    if !pbCommonEvent(trtype)
      Kernel.pbMessage(_INTL("No se definieron mensajes de {1}.<br>No se puedo llamar al evento común {2}.",trainer[2],trtype))
    end
    return
  end
  # Trainer contacts
  if $game_map.map_id==trainer[6]
    Kernel.pbMessage(_INTL("El entrenador está cerca.<br>¡Háblale en persona!"))
    return
  end
  callerregion  = pbGetMetadata(trainer[6],MetadataMapPosition)
  currentregion = pbGetMetadata($game_map.map_id,MetadataMapPosition)
  if callerregion && currentregion && callerregion[0]!=currentregion[0]
    Kernel.pbMessage(_INTL("El entrenador está fuera de rango."))
    return   # Can't call if in different region
  end
  call = pbPhoneGenerateCall(trainer)
  pbPhoneCall(call,trainer)
end

#===============================================================================
# Generate phone message
#===============================================================================
def pbPhoneGenerateCall(phonenum)
  call=""
  phoneData = pbLoadPhoneData
  # Choose random greeting depending on time of day
  call = pbRandomPhoneItem(phoneData.greetings)
  time = pbGetTimeNow
  if PBDayNight.isMorning?(time)
    modcall = pbRandomPhoneItem(phoneData.greetingsMorning)
    call = modcall if modcall && modcall!=""
  elsif PBDayNight.isEvening?(time)
    modcall = pbRandomPhoneItem(phoneData.greetingsEvening)
    call = modcall if modcall && modcall!=""
  end
  call += "\\m"
  if phonenum[4]==2 || (rand(2)==0 && phonenum[4]==3)
    # If "can battle" is set, make ready to battle
    call += pbRandomPhoneItem(phoneData.battleRequests)
    pbSetReadyToBattle(phonenum)
    phonenum[4] = 3
  elsif rand(4)<3
    # Choose random body
    call += pbRandomPhoneItem(phoneData.bodies1)
    call += "\\m"
    call += pbRandomPhoneItem(phoneData.bodies2)
  else
    # Choose random generic
    call += pbRandomPhoneItem(phoneData.generics)
  end
  return call
end

def pbRandomPhoneItem(array)
  ret = array[rand(array.length)]
  ret = "" if !ret
  return pbGetMessageFromHash(MessageTypes::PhoneMessages,ret)
end

def pbRandomEncounterSpecies(enctype)
  return 0 if !enctype
  len = [enctype.length,4].min
  return enctype[rand(len)][0]
end

def pbEncounterSpecies(phonenum)
  return "" if !phonenum[6] || phonenum[6]==0
  begin
    data=load_data("Data/encounters.dat")
    return "" if !data
    enctypes=data[phonenum[6]][1]
  rescue
    return ""
  end
  species=pbRandomEncounterSpecies(enctypes[0]) # Land
  species=pbRandomEncounterSpecies(enctypes[1]) if species==0 # Cave
  species=pbRandomEncounterSpecies(enctypes[9]) if species==0 # LandMorning
  species=pbRandomEncounterSpecies(enctypes[10]) if species==0 # LandDay
  species=pbRandomEncounterSpecies(enctypes[11]) if species==0 # LandNight
  species=pbRandomEncounterSpecies(enctypes[2]) if species==0 # Water
  return "" if species==0
  return PBSpecies.getName(species)
end

def pbTrainerMapName(phonenum)
  return "" if !phonenum[6] || phonenum[6]==0
  return pbGetMessage(MessageTypes::MapNames,phonenum[6])
end

def pbLoadTrainerData(trainerid,trainername,partyid=0)
  ret = nil
  trainers = load_data("Data/trainers.dat")
  for trainer in trainers
    name = trainer[1]
    thistrainerid = trainer[0]
    thispartyid   = trainer[4]
    if trainerid==thistrainerid && name==trainername && partyid==thispartyid
      ret = trainer
      break
    end
  end
  return ret
end

def pbTrainerSpecies(phonenum)
  return "" if !phonenum[0]
  partyid = [0,(phonenum[5]-1)].max
  trainer = pbLoadTrainerData(phonenum[1],phonenum[2],partyid)
  return "" if !trainer || trainer[3].length==0
  rndpoke = trainer[3][rand(trainer[3].length)]
  return PBSpecies.getName(rndpoke[0])
end

#===============================================================================
# Phone screen
#===============================================================================
class Window_PhoneList < Window_CommandPokemon
  def drawCursor(index,rect)
    selarrow = AnimatedBitmap.new("Graphics/Pictures/phoneSel")
    if self.index==index
      pbCopyBitmap(self.contents,selarrow.bitmap,rect.x,rect.y)
    end
    return Rect.new(rect.x+28,rect.y+8,rect.width-16,rect.height)
  end

  def drawItem(index,count,rect)
    return if index>=self.top_row+self.page_item_max
    super
    drawCursor(index-1,itemRect(index-1))
  end
end



class PokemonPhoneScene
  def start
    commands = []
    @trainers = []
    if $PokemonGlobal.phoneNumbers
      for num in $PokemonGlobal.phoneNumbers
        if num[0]   # if visible
          if num.length==8   # if trainer
            @trainers.push([num[1],num[2],num[6],(num[4]>=2)])
          else               # if NPC
            @trainers.push([num[1],num[2],num[3]])
          end
        end
      end
    end
    if @trainers.length==0
      Kernel.pbMessage(_INTL("No hay ningún número de teléfono guardado."))
      return
    end
    @sprites = {}
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites["list"] = Window_PhoneList.newEmpty(152,32,Graphics.width-142,Graphics.height-80,@viewport)
    @sprites["header"] = Window_UnformattedTextPokemon.newWithSize(_INTL("Teléfono"),
       2,-18,128,64,@viewport)
    @sprites["header"].baseColor   = Color.new(248,248,248)
    @sprites["header"].shadowColor = Color.new(0,0,0)
    mapname = (@trainers[0][2]) ? pbGetMessage(MessageTypes::MapNames,@trainers[0][2]) : ""
    @sprites["bottom"] = Window_AdvancedTextPokemon.newWithSize("",
       162,Graphics.height-64,Graphics.width-158,64,@viewport)
    @sprites["bottom"].text = "<ac>"+mapname
    @sprites["info"] = Window_AdvancedTextPokemon.newWithSize("",-8,224,180,160,@viewport)
    addBackgroundPlane(@sprites,"bg","phonebg",@viewport)
    @sprites["icon"] = IconSprite.new(70,102,@viewport)
    if @trainers[0].length==4
      filename = pbTrainerCharFile(@trainers[0][0])
    else
      filename = sprintf("Graphics/Characters/phone%03d",@trainers[0][0])
    end
    @sprites["icon"].setBitmap(filename)
    charwidth  = @sprites["icon"].bitmap.width
    charheight = @sprites["icon"].bitmap.height
    @sprites["icon"].x = 86-charwidth/8
    @sprites["icon"].y = 134-charheight/8
    @sprites["icon"].src_rect = Rect.new(0,0,charwidth/4,charheight/4)
    for trainer in @trainers
      if trainer.length==4
        displayname = _INTL("{1} {2}",PBTrainers.getName(trainer[0]),
           pbGetMessageFromHash(MessageTypes::TrainerNames,trainer[1])
        )
        commands.push(displayname) # trainer's display name
      else
        commands.push(trainer[1]) # NPC's display name
      end
    end
    @sprites["list"].commands = commands
    for i in 0...@sprites["list"].page_item_max
      @sprites["rematch[#{i}]"] = IconSprite.new(468,62+i*32,@viewport)
      j = i+@sprites["list"].top_item
      next if j>=commands.length
      trainer = @trainers[j]
      if trainer.length==4
        if trainer[3]
          @sprites["rematch[#{i}]"].setBitmap("Graphics/Pictures/phoneRematch")
        end
      end
    end
    rematchcount = 0
    for trainer in @trainers
      if trainer.length==4
        rematchcount += 1 if trainer[3]
      end
    end
    infotext=_INTL("Registrados<br>")
    infotext += _INTL(" <r>{1}<br>",@sprites["list"].commands.length)
    infotext+=_INTL("Esperando revancha<r>{1}",rematchcount)
    @sprites["info"].text = infotext
    pbFadeInAndShow(@sprites)
    pbActivateWindow(@sprites,"list") {
      oldindex = -1
      loop do
        Graphics.update
        Input.update
        pbUpdateSpriteHash(@sprites)
        if @sprites["list"].index!=oldindex
          trainer = @trainers[@sprites["list"].index]
          if trainer.length==4
            filename = pbTrainerCharFile(trainer[0])
          else
            filename = sprintf("Graphics/Characters/phone%03d",trainer[0])
          end
          @sprites["icon"].setBitmap(filename)
          charwidth  = @sprites["icon"].bitmap.width
          charheight = @sprites["icon"].bitmap.height
          @sprites["icon"].x        = 86-charwidth/8
          @sprites["icon"].y        = 134-charheight/8
          @sprites["icon"].src_rect = Rect.new(0,0,charwidth/4,charheight/4)
          mapname=(trainer[2]) ? pbGetMessage(MessageTypes::MapNames,trainer[2]) : ""
          @sprites["bottom"].text = "<ac>"+mapname
          for i in 0...@sprites["list"].page_item_max
            @sprites["rematch[#{i}]"].clearBitmaps
            j = i+@sprites["list"].top_item
            next if j>=commands.length
            trainer = @trainers[j]
            if trainer.length==4
              if trainer[3]
                @sprites["rematch[#{i}]"].setBitmap("Graphics/Pictures/phoneRematch")
              end
            end
          end
        end
        if Input.trigger?(Input::B)
          pbPlayCloseMenuSE
          break
        elsif Input.trigger?(Input::C)
          index = @sprites["list"].index
          if index>=0
            pbCallTrainer(@trainers[index][0],@trainers[index][1])
          end
        end
      end
    }
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
# The phone call itself
#===============================================================================
def pbPhoneCall(call,phonenum)
  Kernel.pbMessage(_INTL("......\\wt[5] ......\\1"))
  encspecies     = pbEncounterSpecies(phonenum)
  trainerspecies = pbTrainerSpecies(phonenum)
  trainermap     = pbTrainerMapName(phonenum)
  messages = call.split("\\m")
  for i in 0...messages.length
    messages[i].gsub!(/\\TN/,phonenum[2])
    messages[i].gsub!(/\\TP/,trainerspecies)
    messages[i].gsub!(/\\TE/,encspecies)
    messages[i].gsub!(/\\TM/,trainermap)
    messages[i] += "\\1" if i<messages.length-1
    Kernel.pbMessage(messages[i])
  end
  Kernel.pbMessage(_INTL("¡Clic!\\wt[10]<br>......\\wt[5] ......\\1"))
end
