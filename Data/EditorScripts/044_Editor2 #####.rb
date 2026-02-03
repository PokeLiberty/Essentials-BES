################################################################################
# Item editor
################################################################################
def pbItemEditorNew(defaultname)
  itemdata=readItemList("Data/items.dat")
  # Get the first blank ID for the new item to use.
  maxid=PBItems.maxValue+1
  for i in 1..PBItems.maxValue
    name=itemdata[i][1]
    if !name || name=="" || itemdata[i][ITEMPOCKET]==0
      maxid=i
      break
    end
  end
  index=maxid
  itemname=Kernel.pbMessageFreeText(_INTL("Please enter the item's name."),
     defaultname ? defaultname.gsub(/_+/," ") : "",false,12)
  if itemname=="" && !defaultname
    return -1
  else
    # Create a default name if there is none.
    if !defaultname
      defaultname=itemname.gsub(/[^A-Za-z0-9_]/,"")
      defaultname=defaultname.sub(/^([a-z])/){ $1.upcase }
      if defaultname.length==0
        defaultname=sprintf("Item%03d",index)
      elsif !defaultname[0,1][/[A-Z]/]
        defaultname="Item"+defaultname
      end
    end
    itemname=defaultname if itemname==""
    # Create an internal name based on the item name.
    cname=itemname.gsub(/é/,"e")
    cname=cname.gsub(/[^A-Za-z0-9_]/,"")
    cname=cname.upcase
    if hasConst?(PBItems,cname)
      suffix=1
      100.times do
        tname=sprintf("%s_%d",cname,suffix)
        if !hasConst?(PBItems,tname)
          cname=tname
          break
        end
        suffix+=1
      end
    end
    if hasConst?(PBItems,cname)
      Kernel.pbMessage(_INTL("Failed to create the item.  Choose a different name."))
      return -1
    end
    pocket=PocketProperty.set("",0)
    return -1 if pocket==0
    price=LimitProperty.new(999999).set(_INTL("Purchase price"),-1)
    return -1 if price==-1
    desc=StringProperty.set(_INTL("Description"),"")
    # Item list will create record automatically
    itemdata[index][ITEMID]        = index
    itemdata[index][ITEMNAME]      = itemname
    itemdata[index][ITEMPOCKET]    = pocket
    itemdata[index][ITEMPRICE]     = price
    itemdata[index][ITEMDESC]      = desc
    itemdata[index][ITEMUSE]       = 0
    itemdata[index][ITEMBATTLEUSE] = 0
    itemdata[index][ITEMTYPE]      = 0
    itemdata[index][ITEMMACHINE]   = 0
    PBItems.const_set(cname,index)
    writeSerialRecords("Data/items.dat",itemdata)
    pbSaveItems()
    Kernel.pbMessage(_INTL("The item was created (ID: {1}).",index))
    Kernel.pbMessage(
       _ISPRINTF("Put the item's graphic (item{1:03d}.png or item{2:s}.png) in Graphics/Icons, or it will be blank.",
       index,getConstantName(PBItems,index)))
    return index
  end
end



class ItemNameProperty
  def set(settingname,oldsetting)
    message=Kernel.pbMessageFreeText(_INTL("Set the value for {1}.",settingname),
       oldsetting ? oldsetting : "",false,12)
  end

  def defaultValue
    return "???"
  end

  def format(value)
    return value
  end
end



module PocketProperty
  def self.pocketnames
    return [_INTL("Items"),_INTL("Medicine"),_INTL("Poké Balls"),
       _INTL("TMs & HMs"),_INTL("Berries"),_INTL("Mail"),
       _INTL("Battle Items"),_INTL("Key Items")]
  end
   
  def self.set(settingname,oldsetting)
    cmd=Kernel.pbMessage(_INTL("Choose a pocket for this item."),pocketnames(),-1)
    if cmd<0
      return oldsetting
    else
      return cmd+1
    end
  end

  def self.defaultValue
    return 1
  end

  def self.format(value)
    return _INTL("No Pocket") if value==0
    return value ? pocketnames()[value-1] : value.inspect
  end 
end



def pbItemEditor
  selection=0
  items=[
     [_INTL("Internal Name"),ReadOnlyProperty,
         _INTL("Internal name that appears in constructs like PBItems::XXX.")],
     [_INTL("Item Name"),ItemNameProperty.new(),
         _INTL("Name of the item as displayed by the game.")],
     [_INTL("Item Name Plural"),ItemNameProperty.new(),
         _INTL("Plural name of the item as displayed by the game.")],
     [_INTL("Pocket"),PocketProperty,
         _INTL("Pocket in the bag where the item is stored.")],
     [_INTL("Purchase price"),LimitProperty.new(9999),
         _INTL("Purchase price of the item.")],
     [_INTL("Description"),StringProperty,
         _INTL("Description of the item")],
     [_INTL("Use Out of Battle"),EnumProperty.new([
         _INTL("Can't Use"),_INTL("On a Pokemon"),_INTL("Use directly"),
         _INTL("TM"),_INTL("HM"),_INTL("On Pokémon reusable")]),
         _INTL("Specifies how this item can be used outside of battle.")],
     [_INTL("Use In Battle"),EnumProperty.new([
         _INTL("Can't Use"),_INTL("On a Pokemon"),_INTL("Use directly"),
         _INTL("On Pokemon reusable"),_INTL("Use directly reusable")]),
         _INTL("Specifies how this item can be used within a battle.")],
     [_INTL("Special Items"),EnumProperty.new([
         _INTL("None of Below"),_INTL("Mail"),_INTL("Mail with Pictures"),
         _INTL("Snag Ball"),_INTL("Poké Ball"),_INTL("Plantable Berry"),
         _INTL("Key Item")]),
         _INTL("For special kinds of items.")],
     [_INTL("Machine"),MoveProperty,
         _INTL("Move taught by this TM or HM.")]
  ]
  pbListScreenBlock(_INTL("Items"),ItemLister.new(selection,true)){|button,trtype|
     if trtype
       if button==Input::A
         if trtype>=0
           if Kernel.pbConfirmMessageSerious("Delete this item?")
             data=readSerialRecords("Data/items.dat")
             removeConstantValue(PBItems,trtype)
             data.delete_if{|item| item[0]==trtype }
             for x in data
               p x if data[0]==0
             end
             writeSerialRecords("Data/items.dat",data)
             pbSaveItems()
             Kernel.pbMessage(_INTL("The item was deleted."))
           end
         end
       elsif button==Input::C
         selection=trtype
         if selection<0
           newid=pbItemEditorNew(nil)
           if newid>=0
             selection=newid
           end
         else
           data=[getConstantName(PBItems,selection)]
           itemdata=readItemList("Data/items.dat")
           data.push(itemdata[selection][ITEMNAME])
           data.push(itemdata[selection][ITEMPLURAL])
           data.push(itemdata[selection][ITEMPOCKET])
           data.push(itemdata[selection][ITEMPRICE])
           data.push(itemdata[selection][ITEMDESC])
           data.push(itemdata[selection][ITEMUSE])
           data.push(itemdata[selection][ITEMBATTLEUSE])
           data.push(itemdata[selection][ITEMTYPE])
           data.push(itemdata[selection][ITEMMACHINE])
           save=pbPropertyList(data[ITEMNAME],data,items,true)
           if save
             itemdata[selection][ITEMNAME]      = data[ITEMNAME]
             itemdata[selection][ITEMPLURAL]    = data[ITEMPLURAL]
             itemdata[selection][ITEMPOCKET]    = data[ITEMPOCKET]
             itemdata[selection][ITEMPRICE]     = data[ITEMPRICE]
             itemdata[selection][ITEMDESC]      = data[ITEMDESC]
             itemdata[selection][ITEMUSE]       = data[ITEMUSE]
             itemdata[selection][ITEMBATTLEUSE] = data[ITEMBATTLEUSE]
             itemdata[selection][ITEMTYPE]      = data[ITEMTYPE]
             itemdata[selection][ITEMMACHINE]   = data[ITEMMACHINE]
             writeSerialRecords("Data/items.dat",itemdata)
             pbSaveItems()
           end
         end
       end
     end
  }
end



################################################################################
# Pokémon species editor
################################################################################
def pbSpeciesEditorNew(defaultname)
end



module BaseStatsProperty
  def self.set(settingname,oldsetting)
    if !oldsetting
      return oldsetting
    end
    properties=[
       [_INTL("Base HP"),NonzeroLimitProperty.new(255),
           _INTL("Base HP stat of the Pokémon.")],
       [_INTL("Base Attack"),NonzeroLimitProperty.new(255),
           _INTL("Base Attack stat of the Pokémon.")],
       [_INTL("Base Defense"),NonzeroLimitProperty.new(255),
           _INTL("Base Defense stat of the Pokémon.")],
       [_INTL("Base Speed"),NonzeroLimitProperty.new(255),
           _INTL("Base Speed stat of the Pokémon.")],
       [_INTL("Base Special Attack"),NonzeroLimitProperty.new(255),
           _INTL("Base Special Attack stat of the Pokémon.")],
       [_INTL("Base Special Defense"),NonzeroLimitProperty.new(255),
           _INTL("Base Special Defense stat of the Pokémon.")]
    ]
    if !pbPropertyList(settingname,oldsetting,properties,true)
      oldsetting=nil
    else
      oldsetting=nil if !oldsetting[0] || oldsetting[0]==0
    end
    return oldsetting
  end

  def self.defaultValue
    return 10
  end

  def self.format(value)
    return value.inspect
  end
end



module EVProperty
  def self.set(settingname,oldsetting)
    if !oldsetting
      return oldsetting
    end
    properties=[
       [_INTL("HP EVs"),LimitProperty.new(255),
           _INTL("Number of HP Effort Value points gained from the Pokémon.")],
       [_INTL("Attack EVs"),LimitProperty.new(255),
           _INTL("Number of Attack Effort Value points gained from the Pokémon.")],
       [_INTL("Defense EVs"),LimitProperty.new(255),
           _INTL("Number of Defense Effort Value points gained from the Pokémon.")],
       [_INTL("Speed EVs"),LimitProperty.new(255),
           _INTL("Number of Speed Effort Value points gained from the Pokémon.")],
       [_INTL("Special Attack EVs"),LimitProperty.new(255),
           _INTL("Number of Special Attack Effort Value points gained from the Pokémon.")],
       [_INTL("Special Defense EVs"),LimitProperty.new(255),
           _INTL("Number of Special Defense Effort Value points gained from the Pokémon.")]
    ]
    if !pbPropertyList(settingname,oldsetting,properties,true)
      oldsetting=nil
    else
      oldsetting=nil if !oldsetting[0] || oldsetting[0]==0
    end
    return oldsetting
  end

  def self.defaultValue
    return 0
  end

  def self.format(value)
    return value.inspect
  end
end



module AbilityProperty
  def self.set(settingname,oldsetting)
    ret=pbChooseAbilityList(oldsetting ? oldsetting : 1)
    return (ret<=0) ? (oldsetting ? oldsetting : 0) : ret
  end

  def self.format(value)
    return value ? PBAbilities.getName(value) : "-"
  end

  def self.defaultValue
    return 0
  end
end



module MovePoolProperty
  def self.set(settingname,oldsetting)
    ret=oldsetting
    cmdwin=pbListWindow([],200)
    commands=[]
    realcmds=[]
    realcmds.push([0,0,-1])
    for i in 0...oldsetting.length
      realcmds.push([oldsetting[i][0],oldsetting[i][1],i])
    end
    refreshlist=true; oldsel=-1
    cmd=[0,0]
    loop do
      if refreshlist
        realcmds.sort!{|a,b| a[0]==b[0] ? a[2]<=>b[2] : a[0]<=>b[0]}
        commands=[]
        for i in 0...realcmds.length
          if realcmds[i][0]==0
            commands.push(_ISPRINTF("[ADD MOVE]"))
          else
            commands.push(_ISPRINTF("{1:d}: {2:s}",realcmds[i][0],PBMoves.getName(realcmds[i][1])))
          end
          cmd[1]=i if oldsel>=0 && realcmds[i][2]==oldsel
        end
      end
      refreshlist=false; oldsel=-1
      cmd=pbCommands3(cmdwin,commands,-1,cmd[1],true)
      if cmd[0]==1   # Swap move up
        if cmd[1]<realcmds.length-1 && realcmds[cmd[1]][0]==realcmds[cmd[1]+1][0]
          realcmds[cmd[1]+1][2],realcmds[cmd[1]][2]=realcmds[cmd[1]][2],realcmds[cmd[1]+1][2]
          refreshlist=true
        end
      elsif cmd[0]==2   # Swap move down
        if cmd[1]>0 && realcmds[cmd[1]][0]==realcmds[cmd[1]-1][0]
          realcmds[cmd[1]-1][2],realcmds[cmd[1]][2]=realcmds[cmd[1]][2],realcmds[cmd[1]-1][2]
          refreshlist=true
        end
      elsif cmd[0]==0
        if cmd[1]>=0
          entry=realcmds[cmd[1]]
          if entry[0]==0   # Add new move
            params=ChooseNumberParams.new
            params.setRange(1,MAXIMUMLEVEL)
            params.setDefaultValue(1)
            newlevel=Kernel.pbMessageChooseNumber(
               _INTL("Choose a level."),params)
            if newlevel>0
              newmove=pbChooseMoveList()
              if newmove>0
                havemove=-1
                for i in 0...realcmds.length
                  havemove=realcmds[i][2] if realcmds[i][0]==newlevel && realcmds[i][1]==newmove
                end
                if havemove>=0
                  oldsel=havemove
                else
                  maxid=-1
                  for i in realcmds; maxid=[maxid,i[2]].max; end
                  realcmds.push([newlevel,newmove,maxid+1])
                end
                refreshlist=true
              end
            end
          else   # Edit move
            cmd2=Kernel.pbMessage(_INTL("\\ts[]Do what with this move?"),
               [_INTL("Change level"),_INTL("Change move"),_INTL("Delete"),_INTL("Cancel")],4)
            if cmd2==0
              params=ChooseNumberParams.new
              params.setRange(1,MAXIMUMLEVEL)
              params.setDefaultValue(entry[0])
              newlevel=Kernel.pbMessageChooseNumber(_INTL("Choose a new level."),params)
              if newlevel>0
                havemove=-1
                for i in 0...realcmds.length
                  havemove=realcmds[i][2] if realcmds[i][0]==newlevel && realcmds[i][1]==entry[1]
                end
                if havemove>=0
                  realcmds[cmd[1]]=nil
                  realcmds.compact!
                  oldsel=havemove
                else
                  entry[0]=newlevel
                  oldsel=entry[2]
                end
                refreshlist=true
              end
            elsif cmd2==1
              newmove=pbChooseMoveList(entry[1])
              if newmove>0
                havemove=-1
                for i in 0...realcmds.length
                  havemove=realcmds[i][2] if realcmds[i][0]==entry[0] && realcmds[i][1]==newmove
                end
                if havemove>=0
                  realcmds[cmd[1]]=nil
                  realcmds.compact!
                  oldsel=havemove
                else
                  entry[1]=newmove
                  oldsel=entry[2]
                end
                refreshlist=true
              end
            elsif cmd2==2
              realcmds[cmd[1]]=nil
              realcmds.compact!
              cmd[1]=[cmd[1],realcmds.length-1].min
              refreshlist=true
            end
          end
        else
          cmd2=Kernel.pbMessage(_INTL("Save changes?"),
             [_INTL("Yes"),_INTL("No"),_INTL("Cancel")],3)
          if cmd2==0 || cmd2==1
            if cmd2==0
              for i in 0...realcmds.length
                realcmds[i].pop
                realcmds[i]=nil if realcmds[i][0]==0
              end
              realcmds.compact!
              ret=realcmds
            end
            break
          end
        end
      end
    end
    cmdwin.dispose
    return ret
  end

  def self.format(value)
    ret=""
    for i in 0...value.length
      ret << "," if i>0
      ret << sprintf("#{value[i][0]},#{PBMoves.getName(value[i][1])}")
    end
    return ret
  end

  def self.defaultValue
    return []
  end
end



module EggMovesProperty
  def self.set(settingname,oldsetting)
    ret=oldsetting
    cmdwin=pbListWindow([],200)
    commands=[]
    realcmds=[]
    realcmds.push([0,_ISPRINTF("[ADD MOVE]"),-1])
    for i in 0...oldsetting.length
      realcmds.push([oldsetting[i],PBMoves.getName(oldsetting[i]),0])
    end
    refreshlist=true; oldsel=-1
    cmd=0
    loop do
      if refreshlist
        realcmds.sort!{|a,b| a[2]==b[2] ? a[1]<=>b[1] : a[2]<=>b[2]}
        commands=[]
        for i in 0...realcmds.length
          commands.push(realcmds[i][1])
          cmd=i if oldsel>=0 && realcmds[i][0]==oldsel
        end
      end
      refreshlist=false; oldsel=-1
      cmd=pbCommands2(cmdwin,commands,-1,cmd,true)
      if cmd>=0
        entry=realcmds[cmd]
        if entry[0]==0   # Add new move
          newmove=pbChooseMoveList()
          if newmove>0
            havemove=false
            for i in 0...realcmds.length
              havemove=true if realcmds[i][0]==newmove
            end
            if havemove
              oldsel=newmove
            else
              realcmds.push([newmove,PBMoves.getName(newmove),0])
            end
            refreshlist=true
          end
        else   # Edit move
          cmd2=Kernel.pbMessage(_INTL("\\ts[]Do what with this move?"),
             [_INTL("Change move"),_INTL("Delete"),_INTL("Cancel")],3)
          if cmd2==0
            newmove=pbChooseMoveList(entry[0])
            if newmove>0
              havemove=false
              for i in 0...realcmds.length
                havemove=true if realcmds[i][0]==newmove
              end
              if havemove
                realcmds[cmd]=nil
                realcmds.compact!
                cmd=[cmd,realcmds.length-1].min
              else
                realcmds[cmd]=[newmove,PBMoves.getName(newmove),0]
              end
              oldsel=newmove
              refreshlist=true
            end
          elsif cmd2==1
            realcmds[cmd]=nil
            realcmds.compact!
            cmd=[cmd,realcmds.length-1].min
            refreshlist=true
          end
        end
      else
        cmd2=Kernel.pbMessage(_INTL("Save changes?"),
           [_INTL("Yes"),_INTL("No"),_INTL("Cancel")],3)
        if cmd2==0 || cmd2==1
          if cmd2==0
            for i in 0...realcmds.length
              realcmds[i]=realcmds[i][0]
              realcmds[i]=nil if realcmds[i]==0
            end
            realcmds.compact!
            ret=realcmds
          end
          break
        end
      end
    end
    cmdwin.dispose
    return ret
  end

  def self.format(value)
    ret=""
    for i in 0...value.length
      ret << "," if i>0
      ret << sprintf("#{PBMoves.getName(value[i])}")
    end
    return ret
  end

  def self.defaultValue
    return []
  end
end



module FormNamesProperty
  def self.set(settingname,oldsetting)
    ret=oldsetting
    cmdwin=pbListWindow([],200)
    commands=[]
    realcmds=[]
    realcmds.push([_ISPRINTF("[ADD FORM]"),-1])
    for i in 0...oldsetting.length
      realcmds.push([oldsetting[i],i])
    end
    refreshlist=true; oldsel=-1
    cmd=[0,0]
    loop do
      if refreshlist
        realcmds.sort!{|a,b| a[1]<=>b[1]}
        commands=[]
        for i in 0...realcmds.length
          text=(realcmds[i][1]>=0) ? sprintf("#{realcmds[i][1].to_s} - #{realcmds[i][0]}") : realcmds[i][0]
          commands.push(text)
          cmd[1]=i if oldsel>=0 && realcmds[i][1]==oldsel
        end
      end
      refreshlist=false; oldsel=-1
      cmd=pbCommands3(cmdwin,commands,-1,cmd[1],true)
      if cmd[0]==1   # Swap name up
        if cmd[1]<realcmds.length-1 && realcmds[cmd[1]][1]>=0 && realcmds[cmd[1]+1][1]>=0
          realcmds[cmd[1]+1][1],realcmds[cmd[1]][1]=realcmds[cmd[1]][1],realcmds[cmd[1]+1][1]
          refreshlist=true
        end
      elsif cmd[0]==2   # Swap name down
        if cmd[1]>0 && realcmds[cmd[1]][1]>=0 && realcmds[cmd[1]-1][1]>=0
          realcmds[cmd[1]-1][1],realcmds[cmd[1]][1]=realcmds[cmd[1]][1],realcmds[cmd[1]-1][1]
          refreshlist=true
        end
      elsif cmd[0]==0
        if cmd[1]>=0
          entry=realcmds[cmd[1]]
          if entry[1]<0   # Add new form
            newname=Kernel.pbMessageFreeText(_INTL("Choose a form name (no commas)."),
               "",false,255)
            if newname!=""
              realcmds.push([newname,realcmds.length-1])
              refreshlist=true
            end
          else   # Edit form name
            cmd2=Kernel.pbMessage(_INTL("\\ts[]Do what with this form name?"),
               [_INTL("Rename"),_INTL("Delete"),_INTL("Cancel")],3)
            if cmd2==0
              newname=Kernel.pbMessageFreeText(_INTL("Choose a form name (no commas)."),
                 entry[0],false,255)
              if newname!=""
                realcmds[cmd[1]][0]=newname
                refreshlist=true
              end
            elsif cmd2==1
              realcmds[cmd[1]]=nil
              realcmds.compact!
              cmd[1]=[cmd[1],realcmds.length-1].min
              refreshlist=true
            end
          end
        else
          cmd2=Kernel.pbMessage(_INTL("Save changes?"),
             [_INTL("Yes"),_INTL("No"),_INTL("Cancel")],3)
          if cmd2==0 || cmd2==1
            if cmd2==0
              for i in 0...realcmds.length
                if realcmds[i][1]<0
                  realcmds[i]=nil
                else
                  realcmds[i]=realcmds[i][0]
                end
              end
              realcmds.compact!
              ret=realcmds
            end
            break
          end
        end
      end
    end
    cmdwin.dispose
    return ret
  end

  def self.format(value)
    ret=""
    for i in 0...value.length
      ret << "," if i>0
      ret << sprintf("#{value[i]}")
    end
    return ret
  end

  def self.defaultValue
    return []
  end
end



class EvolutionsProperty
  def initialize(methods)
    @methods=methods
    @evoparams=PBEvolution::EVOPARAM
  end

  def set(settingname,oldsetting)
    ret=oldsetting
    cmdwin=pbListWindow([],256)
    commands=[]
    realcmds=[]
    realcmds.push([-1,0,0,-1])
    for i in 0...oldsetting.length
      realcmds.push([oldsetting[i][0],oldsetting[i][1],oldsetting[i][2],i])
    end
    refreshlist=true; oldsel=-1
    cmd=[0,0]
    loop do
      if refreshlist
        realcmds.sort!{|a,b| a[3]<=>b[3]}
        commands=[]
        for i in 0...realcmds.length
          if realcmds[i][0]<0
            commands.push(_ISPRINTF("[ADD EVOLUTION]"))
          else
            level=realcmds[i][1]
            case @evoparams[realcmds[i][0]]
              when 0
                level=""
              when 2
                level=sprintf("#{PBItems.getName(level)}")
              when 3
                level=sprintf("#{PBMoves.getName(level)}")
              when 4
                level=sprintf("#{PBSpecies.getName(level)}")
              when 5
                level=sprintf("#{PBTypes.getName(level)}")
            end
            commands.push(_ISPRINTF("{1:s}: {2:s}, {3:s}",
               PBSpecies.getName(realcmds[i][2]),@methods[realcmds[i][0]],level.to_s))
          end
          cmd[1]=i if oldsel>=0 && realcmds[i][3]==oldsel
        end
      end
      refreshlist=false; oldsel=-1
      cmd=pbCommands3(cmdwin,commands,-1,cmd[1],true)
      if cmd[0]==1   # Swap evolution up
        if cmd[1]>0 && cmd[1]<realcmds.length-1
          realcmds[cmd[1]+1][3],realcmds[cmd[1]][3]=realcmds[cmd[1]][3],realcmds[cmd[1]+1][3]
          refreshlist=true
        end
      elsif cmd[0]==2   # Swap evolution down
        if cmd[1]>1
          realcmds[cmd[1]-1][3],realcmds[cmd[1]][3]=realcmds[cmd[1]][3],realcmds[cmd[1]-1][3]
          refreshlist=true
        end
      elsif cmd[0]==0
        if cmd[1]>=0
          entry=realcmds[cmd[1]]
          if entry[0]==-1   # Add new evolution path
            Kernel.pbMessage(_INTL("Choose an evolved form, method and parameter."))
            newspecies=pbChooseSpeciesList()
            if newspecies>0
              newmethod=Kernel.pbMessage(_INTL("Choose an evolution method."),@methods,-1)
              if newmethod>0
                newparam=0
                if @evoparams[newmethod]==2   # Items
                  newparam=pbChooseItemList()
                elsif @evoparams[newmethod]==3   # Moves
                  newparam=pbChooseMoveList()
                elsif @evoparams[newmethod]==4   # Species
                  newparam=pbChooseSpeciesList()
                elsif @evoparams[newmethod]==5   # Types
                  newparam=pbChooseTypeList()
                elsif @evoparams[newmethod]!=0
                  params=ChooseNumberParams.new
                  params.setRange(0,65535)
                  params.setDefaultValue(-1)
                  newparam=Kernel.pbMessageChooseNumber(_INTL("Choose a parameter."),params)
                end
                if @evoparams[newmethod]==0 ||
                   (@evoparams[newmethod]==1 && newparam && newparam>=0) ||
                   (@evoparams[newmethod]==2 && newparam && newparam>0) ||
                   (@evoparams[newmethod]==3 && newparam && newparam>0) ||
                   (@evoparams[newmethod]==4 && newparam && newparam>0) ||
                   (@evoparams[newmethod]==5 && newparam && newparam>=0)
                  havemove=-1
                  for i in 0...realcmds.length
                    havemove=realcmds[i][3] if realcmds[i][0]==newmethod &&
                                               realcmds[i][1]==newparam &&
                                               realcmds[i][2]==newspecies
                  end
                  if havemove>=0
                    oldsel=havemove
                  else
                    maxid=-1
                    for i in realcmds; maxid=[maxid,i[3]].max; end
                    realcmds.push([newmethod,newparam,newspecies,maxid+1])
                    oldsel=maxid+1
                  end
                  refreshlist=true
                end
              end
            end
          else   # Edit evolution
            cmd2=Kernel.pbMessage(_INTL("\\ts[]Do what with this move?"),
               [_INTL("Change species"),_INTL("Change method"),
                _INTL("Change parameter"),_INTL("Delete"),_INTL("Cancel")],5)
            if cmd2==0   # Change species
              newspecies=pbChooseSpeciesList(entry[2])
              if newspecies>0
                havemove=-1
                for i in 0...realcmds.length
                  havemove=realcmds[i][3] if realcmds[i][0]==entry[0] &&
                                             realcmds[i][1]==entry[1] &&
                                             realcmds[i][2]==newspecies
                end
                if havemove>=0
                  realcmds[cmd[1]]=nil
                  realcmds.compact!
                  oldsel=havemove
                else
                  entry[2]=newspecies
                  oldsel=entry[3]
                end
                refreshlist=true
              end
            elsif cmd2==1   # Change method
              newmethod=Kernel.pbMessage(_INTL("Choose an evolution method."),
                 @methods,-1,nil,entry[0])
              if newmethod>0
                havemove=-1
                for i in 0...realcmds.length
                  havemove=realcmds[i][3] if realcmds[i][0]==newmethod &&
                                             realcmds[i][1]==entry[1] &&
                                             realcmds[i][2]==entry[2]
                end
                if havemove>=0
                  realcmds[cmd[1]]=nil
                  realcmds.compact!
                  oldsel=havemove
                else
                  entry[0]=newmethod
                  entry[1]=0 if @evoparams[entry[0]]==0
                  oldsel=entry[3]
                end
                refreshlist=true
              end
            elsif cmd2==2   # Change parameter
              if @evoparams[entry[0]]==0
                Kernel.pbMessage(_INTL("This evolution method doesn't use a parameter."))
              else
                newparam=-1
                if @evoparams[entry[0]]==2   # Items
                  newparam=pbChooseItemList(entry[1])
                elsif @evoparams[entry[0]]==3   # Moves
                  newparam=pbChooseMoveList(entry[1])
                elsif @evoparams[entry[0]]==4   # Species
                  newparam=pbChooseSpeciesList(entry[1])
                elsif @evoparams[entry[0]]==5   # Types
                  newparam=pbChooseTypesList(entry[1])
                else
                  params=ChooseNumberParams.new
                  params.setRange(0,65535)
                  params.setDefaultValue(entry[1])
                  params.setCancelValue(-1)
                  newparam=Kernel.pbMessageChooseNumber(_INTL("Choose a parameter."),params)
                end
                if (@evoparams[entry[0]]==1 && newparam && newparam>=0) ||
                   (@evoparams[entry[0]]==2 && newparam && newparam>0) ||
                   (@evoparams[entry[0]]==3 && newparam && newparam>0) ||
                   (@evoparams[entry[0]]==4 && newparam && newparam>0) ||
                   (@evoparams[entry[0]]==5 && newparam && newparam>=0)
                  havemove=-1
                  for i in 0...realcmds.length
                    havemove=realcmds[i][3] if realcmds[i][0]==entry[0] &&
                                               realcmds[i][1]==newparam &&
                                               realcmds[i][2]==entry[2]
                  end
                  if havemove>=0
                    realcmds[cmd[1]]=nil
                    realcmds.compact!
                    oldsel=havemove
                  else
                    entry[1]=newparam
                    oldsel=entry[3]
                  end
                  refreshlist=true
                end
              end
            elsif cmd2==3   # Delete
              realcmds[cmd[1]]=nil
              realcmds.compact!
              cmd[1]=[cmd[1],realcmds.length-1].min
              refreshlist=true
            end
          end
        else
          cmd2=Kernel.pbMessage(_INTL("Save changes?"),
             [_INTL("Yes"),_INTL("No"),_INTL("Cancel")],3)
          if cmd2==0 || cmd2==1
            if cmd2==0
              for i in 0...realcmds.length
                realcmds[i].pop
                realcmds[i]=nil if realcmds[i][0]==-1
              end
              realcmds.compact!
              ret=realcmds
            end
            break
          end
        end
      end
    end
    cmdwin.dispose
    return ret
  end

  def format(value)
    ret=""
    for i in 0...value.length
      ret << "," if i>0
      param=value[i][1]
      case @evoparams[value[i][0]]
        when 0
          param=""
        when 2
          param=sprintf("#{PBItems.getName(param)}")
        when 3
          param=sprintf("#{PBMoves.getName(param)}")
        when 4
          param=sprintf("#{PBSpecies.getName(param)}")
        when 5
          param=sprintf("#{PBTypes.getName(param)}")
      end
      ret << sprintf("#{PBSpecies.getName(value[i][2])},#{@methods[value[i][0]]},#{param}")
    end
    return ret
  end

  def defaultValue
    return []
  end
end



class SpeciesLister
  def initialize(selection,includeNew=false)
    @selection=selection
    @commands=[]
    @ids=[]
    @includeNew=includeNew
    @trainers=nil
    @index=0
  end

  def setViewport(viewport); end

  def startIndex
    return @index
  end

  def commands   # Sorted alphabetically
    @commands.clear
    @ids.clear
    cmds=[]
    for i in 1..PBSpecies.maxValue
      cname=getConstantName(PBSpecies,i) rescue next
      name=PBSpecies.getName(i)
      cmds.push([i,name]) if name && name!=""
    end
    cmds.sort! {|a,b| a[1]<=>b[1]}
    if @includeNew
      @commands.push(_ISPRINTF("[NEW SPECIES]"))
      @ids.push(-1)
    end
    for i in cmds
      @commands.push(_ISPRINTF("{1:03d}: {2:s}",i[0],i[1]))
      @ids.push(i[0])
    end
    @index=@selection
    @index=@commands.length-1 if @index>=@commands.length
    @index=0 if @index<0
    return @commands
  end

  def value(index)
    return nil if (index<0)
    return -1 if index==0 && @includeNew
    realIndex=index
    return @ids[realIndex]
  end

  def dispose; end
  def refresh(index); end
end



def pbPokemonEditor
  selection=0
  species=[
     [_INTL("Name"),LimitStringProperty.new(10),
         _INTL("Name of the Pokémon.")],
     [_INTL("InternalName"),ReadOnlyProperty,
         _INTL("Internal name of the Pokémon.")],
     [_INTL("Type1"),TypeProperty,
         _INTL("Pokémon's type.  If same as Type2, this Pokémon has a single type.")],
     [_INTL("Type2"),TypeProperty,
         _INTL("Pokémon's type.  If same as Type1, this Pokémon has a single type.")],
     [_INTL("BaseStats"),BaseStatsProperty,
         _INTL("Base stats of the Pokémon.")],
     [_INTL("GenderRate"),EnumProperty.new([_INTL("AlwaysMale"),_INTL("FemaleOneEighth"),
         _INTL("Female25Percent"),_INTL("Female50Percent"),_INTL("Female75Percent"),
         _INTL("FemaleSevenEighths"),_INTL("AlwaysFemale"),_INTL("Genderless")]),
         _INTL("Proportion of males to females for this species.")],
     [_INTL("GrowthRate"),EnumProperty.new([_INTL("Medium"),_INTL("Erratic"),
         _INTL("Fluctuating"),_INTL("Parabolic"),_INTL("Fast"),_INTL("Slow")]),
         _INTL("Pokémon's growth rate.")],
     [_INTL("BaseEXP"),LimitProperty.new(65535),
         _INTL("Base experience earned when this species is defeated.")],
     [_INTL("EffortPoints"),EVProperty,
         _INTL("Effort Value points earned when this species is defeated.")],
     [_INTL("Rareness"),LimitProperty.new(255),
         _INTL("Catch rate of this species (max=255).")],
     [_INTL("Happiness"),LimitProperty.new(255),
         _INTL("Base happiness of this species (max=255).")],
     [_INTL("Ability1"),AbilityProperty,
         _INTL("One ability which the Pokémon can have.")],
     [_INTL("Ability2"),AbilityProperty,
         _INTL("Another ability which the Pokémon can have.")],
     [_INTL("HiddenAbility 1"),AbilityProperty,
         _INTL("A secret ability which the Pokémon can have.")],
     [_INTL("HiddenAbility 2"),AbilityProperty,
         _INTL("A secret ability which the Pokémon can have.")],
     [_INTL("HiddenAbility 3"),AbilityProperty,
         _INTL("A secret ability which the Pokémon can have.")],
     [_INTL("HiddenAbility 4"),AbilityProperty,
         _INTL("A secret ability which the Pokémon can have.")],
     [_INTL("Moves"),MovePoolProperty,
         _INTL("Moves which the Pokémon learns while levelling up.")],
     [_INTL("EggMoves"),EggMovesProperty,
         _INTL("Moves which the Pokémon can learn via breeding.")],
     [_INTL("Compat1"),EnumProperty.new([
         "-","Monster","Water 1","Bug","Flying",
         "Field","Fairy","Grass","Human-like","Water 3",
         "Mineral","Amorphous","Water 2","Ditto","Dragon","Undiscovered"]),
         _INTL("Compatibility group (egg group) for breeding purposes.")],
     [_INTL("Compat2"),EnumProperty.new([
         "-","Monster","Water 1","Bug","Flying",
         "Field","Fairy","Grass","Human-like","Water 3",
         "Mineral","Amorphous","Water 2","Ditto","Dragon","Undiscovered"]),
         _INTL("Compatibility group (egg group) for breeding purposes.")],
     [_INTL("StepsToHatch"),LimitProperty.new(65535),
         _INTL("Number of steps until an egg of this species hatches.")],
     [_INTL("Height"),NonzeroLimitProperty.new(999),
         _INTL("Height of the Pokémon in 0.1 metres (e.g. 42 = 4.2m).")],
     [_INTL("Weight"),NonzeroLimitProperty.new(9999),
         _INTL("Weight of the Pokémon in 0.1 kilograms (e.g. 42 = 4.2kg).")],
     [_INTL("Color"),EnumProperty.new([_INTL("Red"),_INTL("Blue"),
         _INTL("Yellow"),_INTL("Green"),_INTL("Black"),_INTL("Brown"),
         _INTL("Purple"),_INTL("Gray"),_INTL("White"),_INTL("Pink")]),
         _INTL("Pokémon's body color.")],
     [_INTL("Habitat"),EnumProperty.new([_INTL("None"),_INTL("Grassland"),_INTL("Forest"),
         _INTL("WatersEdge"),_INTL("Sea"),_INTL("Cave"),_INTL("Mountain"),
         _INTL("RoughTerrain"),_INTL("Urban"),_INTL("Rare")]),
         _INTL("The habitat of this species.")],
     [_INTL("RegionalNumbers"),ReadOnlyProperty,
         _INTL("Regional Dex numbers for the Pokémon. These are edited elsewhere.")],
     [_INTL("Kind"),LimitStringProperty.new(13),
         _INTL("Kind of Pokémon species.")],
     [_INTL("Pokédex"),StringProperty,
         _INTL("Description of the Pokémon as displayed in the Pokédex.")],
     [_INTL("FormNames"),FormNamesProperty,
         _INTL("Names of each form of the Pokémon. Defines how many forms it has.")],
     [_INTL("WildItemCommon"),ItemProperty,
         _INTL("Item commonly held by wild Pokémon of this species.")],
     [_INTL("WildItemUncommon"),ItemProperty,
         _INTL("Item uncommonly held by wild Pokémon of this species.")],
     [_INTL("WildItemRare"),ItemProperty,
         _INTL("Item rarely held by wild Pokémon of this species.")],
     [_INTL("BattlerPlayerY"),ReadOnlyProperty,
         _INTL("Affects positioning of the Pokémon in battle. These are edited elsewhere.")],
     [_INTL("BattlerEnemyY"),ReadOnlyProperty,
         _INTL("Affects positioning of the Pokémon in battle. These are edited elsewhere.")],
     [_INTL("BattlerAltitude"),ReadOnlyProperty,
         _INTL("Affects positioning of the Pokémon in battle. These are edited elsewhere.")],
     [_INTL("Evolutions"),EvolutionsProperty.new(PBEvolution::EVONAMES),
         _INTL("Evolution paths of this species.")],
     [_INTL("Incense"),ItemProperty,
         _INTL("Item needed to be held by a parent to produce an egg of this species.")],
  ]
  pbListScreenBlock(_INTL("Pokémon species"),SpeciesLister.new(selection,false)){|button,index|
     if index
       if button==Input::A
         if index>=0
           if Kernel.pbConfirmMessageSerious("Delete this species?")
             # A species existing depends on its constant existing, so just need
             # to delete that - recompiling pokemon.txt will do the rest.
             removeConstantValue(PBSpecies,index)
             pbSavePokemonData
             Kernel.pbMessage(_INTL("The species was deleted. You should fully recompile before doing anything else."))
           end
         end
       elsif button==Input::C
         selection=index
         if selection<0
           Kernel.pbMessage(_INTL("Can't add a new species."))
#           newid=pbSpeciesEditorNew(nil)
#           selection=newid if newid>=0
         else
           dexdata=File.open("Data/dexdata.dat","rb") rescue nil
           messages=Messages.new("Data/messages.dat") rescue nil
           if !dexdata || !messages
             raise _INTL("Couldn't find dexdata.dat or messages.dat to get Pokémon data from.")
           end
           
           speciesname=messages.get(MessageTypes::Species,selection)
           kind=messages.get(MessageTypes::Kinds,selection)
           entry=messages.get(MessageTypes::Entries,selection)
           cname=getConstantName(PBSpecies,selection) rescue sprintf("POKE%03d",selection)
           formnames=messages.get(MessageTypes::FormNames,selection)
           if !formnames || formnames==""
             formnames=[]
           else
             formnames=strsplit(formnames,/,/)
           end
           
           pbDexDataOffset(dexdata,selection,2)
           ability1=dexdata.fgetw
           ability2=dexdata.fgetw
           color=dexdata.fgetb
           habitat=dexdata.fgetb
           type1=dexdata.fgetb
           type2=dexdata.fgetb
           basestats=[]
           for j in 0...6
             basestats.push(dexdata.fgetb)
           end
           rareness=dexdata.fgetb
           pbDexDataOffset(dexdata,selection,18)
           gender=dexdata.fgetb
           genderrate=0 if gender==0
           genderrate=1 if gender==31
           genderrate=2 if gender==63
           genderrate=3 if gender==127
           genderrate=4 if gender==191
           genderrate=5 if gender==223
           genderrate=6 if gender==254
           genderrate=7 if gender==255
           happiness=dexdata.fgetb
           growthrate=dexdata.fgetb
           stepstohatch=dexdata.fgetw
           effort=[]
           for j in 0...6
             effort.push(dexdata.fgetb)
           end
           pbDexDataOffset(dexdata,selection,31)
           compat1=dexdata.fgetb
           compat2=dexdata.fgetb
           height=dexdata.fgetw
           weight=dexdata.fgetw
           pbDexDataOffset(dexdata,selection,38)
           baseexp=dexdata.fgetw
           hiddenability1=dexdata.fgetw
           hiddenability2=dexdata.fgetw
           hiddenability3=dexdata.fgetw
           hiddenability4=dexdata.fgetw
           item1=dexdata.fgetw
           item2=dexdata.fgetw
           item3=dexdata.fgetw
           incense=dexdata.fgetw
           dexdata.close
           movelist=[]
           File.open("Data/attacksRS.dat","rb"){|f|
              offset=f.getOffset(selection-1)
              length=f.getLength(selection-1)>>1
              f.pos=offset
              for j in 0...length
                alevel=f.fgetw
                move=f.fgetw
                movelist.push([alevel,move,j])
              end
           }
           movelist.sort!{|a,b| a[0]==b[0] ? a[2]<=>b[2] : a[0]<=>b[0] }
           eggmovelist=[]
           File.open("Data/eggEmerald.dat","rb"){|f|
              f.pos=(selection-1)*8
              offset=f.fgetdw
              length=f.fgetdw
              f.pos=offset
              for j in 0...length
                move=f.fgetw
                eggmovelist.push(move) if move!=0
              end
           }
           regionallist=[]
           File.open("Data/regionals.dat","rb"){|f|
              numRegions=f.fgetw
              numDexDatas=f.fgetw
              for region in 0...numRegions
                f.pos=4+region*numDexDatas*2+(selection*2)
                regionallist.push(f.fgetw)
              end
           }
           numb=regionallist.size-1
           while numb>=0   # Remove every 0 at end of array 
             (regionallist[numb]==0) ? regionallist.pop : break
             numb-=1
           end
           evolutions=pbGetEvolvedFormData(selection)
           metrics=load_data("Data/metrics.dat") rescue nil
           data=[]
           data.push(speciesname)             # 0
           data.push(cname)                   # 1
           data.push(type1)                   # 2
           data.push(type2)                   # 3
           data.push(basestats)               # 4
           data.push(genderrate)              # 5
           data.push(growthrate)              # 6
           data.push(baseexp)                 # 7
           data.push(effort)                  # 8
           data.push(rareness)                # 9
           data.push(happiness)               # 10
           data.push(ability1)                # 11
           data.push(ability2)                # 12
           data.push(hiddenability1)          # 13
           data.push(hiddenability2)          # 14
           data.push(hiddenability3)          # 15
           data.push(hiddenability4)          # 16
           data.push(movelist)                # 17
           data.push(eggmovelist)             # 18
           data.push(compat1)                 # 19
           data.push(compat2)                 # 20
           data.push(stepstohatch)            # 21
           data.push(height)                  # 22
           data.push(weight)                  # 23
           data.push(color)                   # 24
           data.push(habitat)                 # 25
           data.push(regionallist)            # 26
           data.push(kind)                    # 27
           data.push(entry)                   # 28
           data.push(formnames)               # 29
           data.push(item1)                   # 30
           data.push(item2)                   # 31
           data.push(item3)                   # 32
           data.push(metrics[0][selection])   # 33
           data.push(metrics[1][selection])   # 34
           data.push(metrics[2][selection])   # 35
           data.push(evolutions)              # 36
           data.push(incense)                 # 37
           save=pbPropertyList(data[0],data,species,true)
           if save
             # Make sure both Type1 and Type2 are recorded correctly
             data[2]=(data[3] ? data[3] : 0) if !data[2]
             data[3]=data[2] if !data[3]
             # Make sure both Compatibilities are recorded correctly
             data[19]=(data[20] && data[20]!=0) ? data[20] : 15 if !data[19] || data[19]==0
             data[20]=data[19] if !data[20] || data[20]==0
             # Make sure both Abilities are recorded correctly
             data[11]=data[12] if !data[11] || (data[11]==0 && data[12]!=0)
             data[11]=0 if !data[11]
             data[12]=0 if data[11]==data[12]
             # Turn GenderRate back into the correct value
             data[5]=0 if data[5]==0
             data[5]=31 if data[5]==1
             data[5]=63 if data[5]==2
             data[5]=127 if data[5]==3
             data[5]=191 if data[5]==4
             data[5]=223 if data[5]==5
             data[5]=254 if data[5]==6
             data[5]=255 if data[5]==7
             savedata=[]
             for i in 0...76
               savedata[i]=0
             end
             savedata[2]=data[11]&0xFF   # Ability 1 - lower byte
             savedata[3]=(data[11]>>8)&0xFF   # Ability 1 - upper byte
             savedata[4]=data[12]&0xFF   # Ability 2 - lower byte
             savedata[5]=(data[12]>>8)&0xFF   # Ability 2 - upper byte
             savedata[6]=data[24]   # Color
             savedata[7]=data[25]   # Habitat
             savedata[8]=data[2]   # Type1
             savedata[9]=data[3]   # Type2
             savedata[10]=data[4][0]   # Base HP
             savedata[11]=data[4][1]   # Base Attack
             savedata[12]=data[4][2]   # Base Defense
             savedata[13]=data[4][3]   # Base Speed
             savedata[14]=data[4][4]   # Base Special Attack
             savedata[15]=data[4][5]   # Base Special Defense
             savedata[16]=data[9]   # Rareness
             savedata[18]=data[5]   # Gender rate
             savedata[19]=data[10]   # Happiness
             savedata[20]=data[6]   # Growth rate
             savedata[21]=data[21]&0xFF   # Steps to hatch - lower byte
             savedata[22]=(data[21]>>8)&0xFF   # Steps to hatch - upper byte
             savedata[23]=data[8][0]   # HP EV
             savedata[24]=data[8][1]   # Attack EV
             savedata[25]=data[8][2]   # Defense EV
             savedata[26]=data[8][3]   # Speed EV
             savedata[27]=data[8][4]   # Special Attack EV
             savedata[28]=data[8][5]   # Special Defense EV
             savedata[31]=data[19]   # Compatibility 1
             savedata[32]=data[20]   # Compatibility 2
             savedata[33]=data[22]&0xFF   # Height - lower byte
             savedata[34]=(data[22]>>8)&0xFF   # Height - upper byte
             savedata[35]=data[23]&0xFF   # Weight - lower byte
             savedata[36]=(data[23]>>8)&0xFF   # Weight - upper byte
             savedata[38]=data[7]&0xFF   # Base EXP - lower byte
             savedata[39]=(data[7]>>8)&0xFF   # Base EXP - upper byte
             savedata[40]=data[13]&0xFF   # Hidden Ability 1 - lower byte
             savedata[41]=(data[13]>>8)&0xFF   # Hidden Ability 1 - upper byte
             savedata[42]=data[14]&0xFF   # Hidden Ability 2 - lower byte
             savedata[43]=(data[14]>>8)&0xFF   # Hidden Ability 2 - upper byte
             savedata[44]=data[15]&0xFF   # Hidden Ability 3 - lower byte
             savedata[45]=(data[15]>>8)&0xFF   # Hidden Ability 3 - upper byte
             savedata[46]=data[16]&0xFF   # Hidden Ability 4 - lower byte
             savedata[47]=(data[16]>>8)&0xFF   # Hidden Ability 4 - upper byte
             savedata[48]=data[30]&0xFF   # Common item - lower byte
             savedata[49]=(data[30]>>8)&0xFF   # Common item - upper byte
             savedata[50]=data[31]&0xFF   # Uncommon item - lower byte
             savedata[51]=(data[31]>>8)&0xFF   # Uncommon item - upper byte
             savedata[52]=data[32]&0xFF   # Rare item - lower byte
             savedata[53]=(data[32]>>8)&0xFF   # Rare item - upper byte
             savedata[54]=data[37]&0xFF   # Incense - lower byte
             savedata[55]=(data[37]>>8)&0xFF   # Incense - upper byte
             File.open("Data/dexdata.dat","rb+"){|f|
                f.pos=76*(selection-1)
                savedata.each {|item| f.fputb(item)}
             }
             namearray=[]
             kindarray=[]
             entryarray=[]
             formarray=[]
             for i in 1..(PBSpecies.maxValue rescue PBSpecies.getCount-1 rescue messages.getCount(MessageTypes::Species)-1)
               namearray[i]=messages.get(MessageTypes::Species,i)
               kindarray[i]=messages.get(MessageTypes::Kinds,i)
               entryarray[i]=messages.get(MessageTypes::Entries,i)
               formarray[i]=messages.get(MessageTypes::FormNames,i)
             end
             namearray[selection]=data[0]
             kindarray[selection]=data[27]
             entryarray[selection]=data[28]
             formarray[selection]=data[29].join(",")
             MessageTypes.setMessages(MessageTypes::Species,namearray)
             MessageTypes.setMessages(MessageTypes::Kinds,kindarray)
             MessageTypes.setMessages(MessageTypes::Entries,entryarray)
             MessageTypes.setMessages(MessageTypes::FormNames,formarray)
             MessageTypes.saveMessages
             # Save moves data
             newmovelist=[]
             File.open("Data/attacksRS.dat","rb"){|f|
                for sp in 1..PBSpecies.maxValue
                  newmovelist[sp]=[]
                  if sp==selection
                    for j in 0...data[17].length
                      newmovelist[sp].push(data[17][j])
                    end
                  else
                    offset=f.getOffset(sp-1)
                    length=f.getLength(sp-1)>>1
                    f.pos=offset
                    for j in 0...length
                      alevel=f.fgetw
                      move=f.fgetw
                      newmovelist[sp].push([alevel,move])
                    end
                  end
                end
             }
             File.open("Data/attacksRS.dat","wb"){|f|
                mx=newmovelist.length-1
                offset=mx*8
                for i in 1..mx
                  f.fputdw(offset)
                  f.fputdw(newmovelist[i] ? newmovelist[i].length*2 : 0)
                  offset+=newmovelist[i] ? newmovelist[i].length*4 : 0
                end
                for i in 1..mx
                  next if !newmovelist[i]
                  for j in newmovelist[i]
                    f.fputw(j[0])
                    f.fputw(j[1])
                  end
                end
             }
             # Save egg moves data
             neweggmovelist=[]
             File.open("Data/eggEmerald.dat","rb"){|f|
                for sp in 1..PBSpecies.maxValue
                  neweggmovelist[sp]=[]
                  if sp==selection
                    for j in 0...data[18].length
                      neweggmovelist[sp].push(data[18][j])
                    end
                  else
                    f.pos=(sp-1)*8
                    offset=f.fgetdw
                    length=f.fgetdw
                    f.pos=offset
                    j=0; loop do break unless j<length
                      move=f.fgetw
                      break if move==0
                      neweggmovelist[sp].push(move) if move>0
                      j+=1
                    end
                  end
                end
             }
             File.open("Data/eggEmerald.dat","wb"){|f|
                mx=newmovelist.length-1
                offset=mx*8
                for i in 1..mx
                  f.fputdw(offset)
                  f.fputdw(neweggmovelist[i] ? neweggmovelist[i].length : 0)
                  offset+=neweggmovelist[i] ? neweggmovelist[i].length*2 : 0
                end
                for i in 1..mx
                  next if !neweggmovelist[i]
                  for j in neweggmovelist[i]
                    f.fputw(j)
                  end
                end
             }
             # Save evolutions data
             evos=[]
             for sp in 1..PBSpecies.maxValue
               evos[sp]=[]
               if sp==selection
                 for i in 0...data[36].length
                   evos[sp].push([data[36][i][2],data[36][i][0],data[36][i][1],0])
                 end
               else
                 t=pbGetEvolvedFormData(sp)
                 for i in 0...t.length
                   evos[sp].push([t[i][2],t[i][0],t[i][1],0])
                 end
               end
             end
             _EVODATAMASK=0xC0
             _EVONEXTFORM=0x00
             _EVOPREVFORM=0x40
             for e in 0...evos.length
               evolist=evos[e]
               next if !evos
               parent=nil
               child=-1
               for f in 0...evos.length
                 evolist=evos[f]
                 next if !evolist || e==f
                 for g in evolist
                   if g[0]==e && (g[3]&_EVODATAMASK)==_EVONEXTFORM
                     parent=g
                     child=f
                     break
                   end
                 end
                 break if parent
               end
               if parent
                 evos[e]=[[child,parent[1],parent[2],_EVOPREVFORM]].concat(evos[e])
               end
             end
             File.open("Data/evolutions.dat","wb"){|f|
                mx=evos.length-1
                offset=mx*8
                for i in 1..mx
                  f.fputdw(offset)
                  f.fputdw(evos[i] ? evos[i].length*5 : 0)
                  offset+=evos[i] ? evos[i].length*5 : 0
                end
                for i in 1..mx
                  next if !evos[i]
                  for j in evos[i]
                    f.fputb(j[3]|j[1])
                    f.fputw(j[2])
                    f.fputw(j[0])
                  end
                end
             }
             # Don't need to save metrics or regional numbers
             # because they can't be edited here
             pbSavePokemonData
             Kernel.pbMessage(_INTL("Data saved."))
           end
         end
       end
     end
  }
end



################################################################################
# Regional Dexes editor
################################################################################
def pbRegionalDexEditor(dex)
  viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z=99999
  info=Window_AdvancedTextPokemon.new(_INTL("Z+Up/Down: Rearrange entries\nZ+Right: Insert new entry\nZ+Left: Delete entry\nA: Clear entry"))
  info.x=256
  info.y=64
  info.width=Graphics.width-256
  info.height=Graphics.height-64
  info.viewport=viewport
  info.z=2
  ret=dex
  tdex=dex.clone
  tdex.compact!
  cmdwin=pbListWindow([],256)
  refreshlist=true
  commands=[]
  cmd=[0,0]
  loop do
    if refreshlist
      if tdex.length>0
        i=tdex.length-1
        loop do break unless tdex[i]==0
          tdex[i]=nil
          i-=1
          break if i<0
        end
        tdex.compact!
      end
      tdex.push(0) if tdex.length==0 || tdex[tdex.length-1]!=0
      commands=[]
      for i in 0...tdex.length
        text="----------"
        if tdex[i]>0 && (getConstantName(PBSpecies,tdex[i]) rescue false)
          text=PBSpecies.getName(tdex[i])
        end
        commands.push(sprintf("%03d: %s",i+1,text))
      end
    end
    refreshlist=false
    cmd=pbCommands3(cmdwin,commands,-1,cmd[1],true)
    if cmd[0]==1   # Swap move up
      if cmd[1]<tdex.length-1
        tdex[cmd[1]+1],tdex[cmd[1]]=tdex[cmd[1]],tdex[cmd[1]+1]
        refreshlist=true
      end
    elsif cmd[0]==2   # Swap move down
      if cmd[1]>0
        tdex[cmd[1]-1],tdex[cmd[1]]=tdex[cmd[1]],tdex[cmd[1]-1]
        refreshlist=true
      end
    elsif cmd[0]==3   # Delete spot
      tdex[cmd[1]]=nil
      tdex.compact!
      cmd[1]=[cmd[1],tdex.length-1].min
      refreshlist=true
    elsif cmd[0]==4   # Insert spot
      i=tdex.length
      loop do break unless i>=cmd[1]
        tdex[i+1]=tdex[i]
        i-=1
      end
      tdex[cmd[1]]=0
      refreshlist=true
    elsif cmd[0]==5   # Clear spot
      tdex[cmd[1]]=0
      refreshlist=true
    elsif cmd[0]==0
      if cmd[1]>=0   # Edit entry
        cmd2=Kernel.pbMessage(_INTL("\\ts[]Do what with this entry?"),
            [_INTL("Change species"),_INTL("Clear"),_INTL("Insert entry"),_INTL("Delete entry"),_INTL("Cancel")],5)
        if cmd2==0
          newspecies=pbChooseSpeciesList(tdex[cmd[1]])
          if newspecies>0
            tdex[cmd[1]]=newspecies
            for i in 0...tdex.length
              next if i==cmd[1]
              tdex[i]=0 if tdex[i]==newspecies
            end
            refreshlist=true
          end
        elsif cmd2==1
          tdex[cmd[1]]=0
          refreshlist=true
        elsif cmd2==2
          i=tdex.length
          loop do break unless i>=cmd[1]
            tdex[i+1]=tdex[i]
            i-=1
          end
          tdex[cmd[1]]=0
          refreshlist=true
        elsif cmd2==3 && cmd[1]<tdex.length-1
          tdex[cmd[1]]=nil
          tdex.compact!
          cmd[1]=[cmd[1],tdex.length-1].min
          refreshlist=true
        end
      else   # Cancel
        cmd2=Kernel.pbMessage(_INTL("Save changes?"),
           [_INTL("Yes"),_INTL("No"),_INTL("Cancel")],3)
        if cmd2==0 || cmd2==1
          if cmd2==0
            if tdex.length>0
              i=tdex.length-1
              loop do break unless tdex[i]==0
                tdex[i]=nil
                i-=1
                break if i<0
              end
              tdex.compact!
            end
            tdex=[nil].concat(tdex)
            ret=tdex
          end
          break
        end
      end
    end
  end
  info.dispose
  cmdwin.dispose
  viewport.dispose
  return ret
end

def pbRegionalNumbersEditor
  numDexDatas=0
  regionallist=[]
  pbRgssOpen("Data/regionals.dat","rb"){|f|
     numRegions=f.fgetw
     numDexDatas=f.fgetw
     for i in 0...numRegions
       regionallist[i]=[]
       f.pos=4+i*numDexDatas*2
       for j in 0...numDexDatas
         regionalNum=f.fgetw
         regionallist[i][regionalNum]=j if regionalNum && regionalNum>0
       end
       for j in 1...regionallist[i].length
         regionallist[i][j]=0 if !regionallist[i][j]
       end
     end
  }
  viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z=99999
  cmdwin=pbListWindow([],256)
  cmdwin.viewport=viewport
  cmdwin.z=2
  title=Window_UnformattedTextPokemon.new(_INTL("Regional Dexes Editor"))
  title.x=256
  title.y=0
  title.width=Graphics.width-256
  title.height=64
  title.viewport=viewport
  title.z=2
  info=Window_AdvancedTextPokemon.new(_INTL("Z+Up/Down: Rearrange Dexes"))
  info.x=256
  info.y=64
  info.width=Graphics.width-256
  info.height=Graphics.height-64
  info.viewport=viewport
  info.z=2
  commands=[]
  refreshlist=true; oldsel=-1
  cmd=[0,0]
  loop do
    if refreshlist
      commands=[_INTL("[ADD DEX]")]
      for i in 0...regionallist.length
        commands.push(_INTL("Dex {1} (size {2})",i+1,regionallist[i].length-1))
      end
    end
    refreshlist=false; oldsel=-1
    cmd=pbCommands3(cmdwin,commands,-1,cmd[1],true)
    if cmd[0]==1   # Swap dex up
      if cmd[1]>0 && cmd[1]<commands.length-1
        regionallist[cmd[1]-1],regionallist[cmd[1]]=regionallist[cmd[1]],regionallist[cmd[1]-1]
        refreshlist=true
      end
    elsif cmd[0]==2   # Swap dex down
      if cmd[1]>1
        regionallist[cmd[1]-2],regionallist[cmd[1]-1]=regionallist[cmd[1]-1],regionallist[cmd[1]-2]
        refreshlist=true
      end
    elsif cmd[0]==0
      if cmd[1]==0   # Add new dex
        cmd2=Kernel.pbMessage(_INTL("Fill in this new Dex?"),
           [_INTL("Leave blank"),_INTL("Fill with National Dex"),_INTL("Cancel")],3)
        if cmd2==0 || cmd2==1
          newdex=[nil]
          if cmd2==1
            for i in 1...numDexDatas
              newdex[i]=i
            end
          end
          regionallist[regionallist.length]=newdex
          refreshlist=true
        end
      elsif cmd[1]>0   # Edit a dex
        cmd2=Kernel.pbMessage(_INTL("\\ts[]Do what with this Dex?"),
            [_INTL("Edit"),_INTL("Copy"),_INTL("Delete"),_INTL("Cancel")],4)
        if cmd2==0
          regionallist[cmd[1]-1]=pbRegionalDexEditor(regionallist[cmd[1]-1])
          refreshlist=true
        elsif cmd2==1
          regionallist[regionallist.length]=regionallist[cmd[1]-1].clone
          cmd[1]=regionallist.length
          refreshlist=true
        elsif cmd2==2
          regionallist[cmd[1]-1]=nil
          regionallist.compact!
          cmd[1]=[cmd[1],regionallist.length].min
          refreshlist=true
        end
      else   # Cancel
        cmd2=Kernel.pbMessage(_INTL("Save changes?"),
            [_INTL("Yes"),_INTL("No"),_INTL("Cancel")],3)
        if cmd2==0 || cmd2==1
          if cmd2==0
            # Save new dexes here
            tosave=[]
            for i in 0...regionallist.length
              tosave[i]=[]
              for j in 0...regionallist[i].length
                tosave[i][regionallist[i][j]]=j if regionallist[i][j]
              end
            end
            File.open("Data/regionals.dat","wb"){|f|
               f.fputw(tosave.length)
               f.fputw(numDexDatas)
               for i in 0...tosave.length
                 for j in 0...numDexDatas
                   num=tosave[i][j]
                   num=0 if !num
                   f.fputw(num)
                 end
               end
            }
            pbSavePokemonData
            Kernel.pbMessage(_INTL("Data saved."))
          end
          break
        end
      end
    end
  end
  title.dispose
  info.dispose
  cmdwin.dispose
  viewport.dispose
end