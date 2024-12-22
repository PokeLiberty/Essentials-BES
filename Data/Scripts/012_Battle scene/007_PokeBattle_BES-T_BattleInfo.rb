################################################################################
#             ***************************************************              #
#             *** MENU DE INFO EN COMBATE CREADO POR SKYFLYER ***              #
#             ***************************************************              #
#           Adaptado para PE V16.3. Basado en el script de bo4p5687
#                         Editado por clara para BES
################################################################################

#########################################
#           CONFIGURACIÓN               #
#########################################
module PokeBattle_SceneConstants
  # CAMBIAR A "true" en vez de "false" SI QUERÉIS ESTAS OPCIONES:
  MOSTRAR_PS_RIVAL = true
  MOSTRAR_HABILIDAD_RIVAL = true
  MOSTRAR_OBJETO_RIVAL = true

  INFOBUTTON_X        = 6
  INFOBUTTON_Y        = 288 - 48

  INFOBASECOLOR        = Color.new(80,80,88)
  INFOSHADOWCOLOR      = Color.new(160,160,168)
  INFO2BASECOLOR       = Color.new(252,252,252)
  INFO2SHADOWCOLOR     = Color.new(88,88,88)
end

class PokeBattle_Scene
  def pbShowBattleInfo(scene)
    player = scene.array_change_stats_in_battle
    opponent = scene.array_change_stats_in_battle(1)
    quantity = []
    if @battle.doublebattle
      numBattlers = 2
    else
      numBattlers = 1
    end        
    2.times { |i| quantity << numBattlers}
    activef = scene.active_field
    actives = scene.active_side
    activep = scene.active_position
    team = [player, opponent]
    activestore = [activef, actives, activep]
    CheckStatsInBattle.show(team, quantity, activestore,scene)
  end
end

# Clase inicial que muestra la pantalla.
module CheckStatsInBattle
  
  def self.show(team, quantity, activestore, battle)
		s = Show.new(team, quantity, activestore, battle)
		s.show
		s.endScene
	end
  
	class Show
    # Función principal que llama al resto.
    def show
			create_scene
			draw_information
			loop do
				break if @exit
				# Update
				update_ingame
				update_bg
				update_choose_bar
				draw_information
				# Input
				set_input
			end
		end
    
    # Inicialización de todos los valores necesarios.
		def initialize(team, quantity, activestore, battle)
			player, opponent = team
      @playerTeam = player
      @playerRival = opponent
			activef, actives, activep = activestore
      @battleStats = battle
      # Start
			@sprites = {}
			# Viewport
			@viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
			@viewport.z = 99999
			# Array
			@name = []
			@pkmn = []
			player[:name].each_with_index { |name, i| @name[2*i] = name }
			player[:pkmn].each_with_index { |pkmn, i| @pkmn[2*i] = pkmn }
			opponent[:name].each_with_index { |name, i| @name[2*i+1] = name } if opponent[:name].size != 0
			opponent[:pkmn].each_with_index { |pkmn, i| @pkmn[2*i+1] = pkmn }
			opponent[:name].size != 0 ? @rivalTrainer=true : @rivalTrainer=false
      @quant = {}
			@quant[:player]   = quantity[0]
			@quant[:opponent] = quantity[1]
			# Valores
			@bg = 1
			@chose = false
			@position = 0
			@exit = false
			# Frame
			@frames = 0
			@iconw  = 0
			# Field, side, postion
			@active  = 0
      
      # CAMPOS Y DEMÁS
			@activef = activef
			@activep = activep
			@actives = actives
			@framesactive = 0
			@originactive = 0
		end

		def set_active_size
			# Reset
			@showactive = []
			# Set
			@showactive << @activef if @activef.size > 0
			@showactive << @actives if @actives[@position%2].size > 0
			@showactive << @activep if @activep[@position]!= nil && @activep[@position].size > 0
		end


#==============================================================================#
#==============================================================================#
#==============================================================================#
#==============================================================================#


		#------------#
		# Set bitmap #
		#------------#
		# Image
		def create_sprite(spritename, filename, vp, dir="Battle")
			@sprites["#{spritename}"] = Sprite.new(vp)
			file = dir ? "Graphics/Pictures/#{dir}/#{filename}" : "Graphics/Pictures/#{filename}"
			@sprites["#{spritename}"].bitmap = Bitmap.new(file)
		end
		def set_sprite(spritename, filename, dir="Battle")
			file = dir ? "Graphics/Pictures/#{dir}/#{filename}" : "Graphics/Pictures/#{filename}"
			@sprites["#{spritename}"].bitmap = Bitmap.new(file)
		end
		# Set ox, oy
		def set_oxoy_sprite(spritename,ox,oy)
			@sprites["#{spritename}"].ox = ox
			@sprites["#{spritename}"].oy = oy
		end
		# Set x, y
		def set_xy_sprite(spritename,x,y)
			@sprites["#{spritename}"].x = x
			@sprites["#{spritename}"].y = y
		end
		# Set zoom
		def set_zoom_sprite(spritename,zoom_x,zoom_y)
			@sprites["#{spritename}"].zoom_x = zoom_x
			@sprites["#{spritename}"].zoom_y = zoom_y
		end
		# Set visible
		def set_visible_sprite(spritename,vsb=false)
			@sprites["#{spritename}"].visible = vsb
		end
		# Set angle
		def set_angle_sprite(spritename,angle)
			@sprites["#{spritename}"].angle = angle
		end
		# Set src
		# width, height
		def set_src_wh_sprite(spritename,w,h)
			@sprites["#{spritename}"].src_rect.width = w
			@sprites["#{spritename}"].src_rect.height = h
		end
		# x, y
		def set_src_xy_sprite(spritename,x,y)
			@sprites["#{spritename}"].src_rect.x = x
			@sprites["#{spritename}"].src_rect.y = y
		end
    
		#------#
		# Text #
		#------#
		# Draw
		def create_sprite_2(spritename,vp)
			@sprites["#{spritename}"] = Sprite.new(vp)
			@sprites["#{spritename}"].bitmap = Bitmap.new(Graphics.width,Graphics.height)
		end
		# Write
		def drawTxt(bitmap,textpos,font=nil,fontsize=nil,width=0,pw=false,height=0,ph=false,clearbm=true)
			# Sprite
			bitmap = @sprites["#{bitmap}"].bitmap
			bitmap.clear if clearbm
			# Set font, size
			(font!=nil)? (bitmap.font.name=font) : pbSetNarrowFont(bitmap)
			bitmap.font.size = fontsize if !fontsize.nil?
			textpos.each { |i|
				if pw
					i[1] += width==0 ? 0 : width==1 ? bitmap.text_size(i[0]).width/2 : bitmap.text_size(i[0]).width
				else
					i[1] -= width==0 ? 0 : width==1 ? bitmap.text_size(i[0]).width/2 : bitmap.text_size(i[0]).width
				end
				if ph
					i[2] += height==0 ? 0 : height==1 ? bitmap.text_size(i[0]).height/2 : bitmap.text_size(i[0]).height
				else
					i[2] -= height==0 ? 0 : height==1 ? bitmap.text_size(i[0]).height/2 : bitmap.text_size(i[0]).height
				end
			}
			pbDrawTextPositions(bitmap,textpos)
		end
		# Clear
		def clearTxt(bitmap)
			@sprites["#{bitmap}"].bitmap.clear
		end
    
		#------------------------------------------------------------------------------#
		# Set SE for input
		#------------------------------------------------------------------------------#
		def checkInput(name,exact=false)
			if exact
				if Input.triggerex?(name)
					(name==:X)? pbPlayDecisionSE : pbPlayDecisionSE
					return true
				end
			else
				if Input.trigger?(name)
					(name==Input::B)? pbPlayDecisionSE : pbPlayDecisionSE
					return true
				end
			end
			return false
		end
		#------------------------------------------------------------------------------#
    # Dispose
    def dispose(id=nil)
      (id.nil?)? pbDisposeSpriteHash(@sprites) : pbDisposeSprite(@sprites,id)
    end
    # Update (just script)
    def update
      pbUpdateSpriteHash(@sprites)
    end
    # Update
    def update_ingame
      Graphics.update
      Input.update
      pbUpdateSpriteHash(@sprites)
    end
    # End
    def endScene
      # Dipose sprites
      self.dispose
      # Dispose viewport
      @viewport.dispose
    end

    

#==============================================================================#
#==============================================================================#
#==============================================================================#
#==============================================================================#
    

    ###################
    # CREAR LA ESCENA #
    ###################
    
		def create_scene
      
			# Fondo
			create_sprite("bg", "Scene_#{@bg}", @viewport)
      
			# Botones Pokémon a elegir
			@pkmn.each_with_index { |pkmn, i|
				next if pkmn.nil?
				file  = "Choose"
				create_sprite("choose #{i}", file, @viewport)   # Crea nuevo gráfico
				w = @sprites["choose #{i}"].bitmap.width        # Dimensiones del gráfico
				h = (@sprites["choose #{i}"].bitmap.height / 2)
				set_src_wh_sprite("choose #{i}", w, h)
				y = i == @position ? h : 0
				set_src_xy_sprite("choose #{i}", 0, y)
        
				qw = i%2==0 ? @quant[:player] : @quant[:opponent]
				qw = 3 if qw > 3
				disx = (Graphics.width - qw * w) / (qw + 1)
				if disx <= 0
					disx = 0
					echoln "You need to redraw bitmap 'Choose' if you want distance between these bitmaps that is greater than 0"
				end
        
				qh = i%2==0 ? @quant[:player] : @quant[:opponent]
				qh = qh/3 == 0 ? 1 : qh/3 > 2 ? 2 : qh/3
				disy = (Graphics.height / 2 - qh * h) / (qh + 1)
				if disy <= 0
					disy = 0
					echoln "You need to redraw bitmap 'Choose' if you want distance between these bitmaps that is greater than 0"
				end
        
				x = disx + (disx + w) * ((i%2==0 ? i/2 : (i-1)/2) % 3) + 20 # Posición botón
				multiple = 0
				real = i%2==0 ? i/2 : (i-1)/2
				multiple = real / 3 if real > 3
				y = (i%2==0 ? (Graphics.height/2)-90 : 0) + disy + (disy + h) * multiple + 2
				set_xy_sprite("choose #{i}", x, y) # Añadir botón al bloque de botones
			}
      
      # ARREGLO 1: Invertir posiciones de los rivales en dobles (salen al revés)
      if @sprites["choose 1"] && @sprites["choose 3"] && (@battleStats.opponent.is_a?(Array) || @battleStats.doublebattle) #if @pkmn.size>2
        x1 = @sprites["choose 1"].x
        x3 = @sprites["choose 3"].x
        y = @sprites["choose 1"].y
        set_xy_sprite("choose 1", x3, y)
        set_xy_sprite("choose 3", x1, y)
      end
      # ARREGLO 2: Desplazar a la derecha el botón si no hay Pokémon a la izquierda.
      if @sprites["choose 1"] && !@sprites["choose 3"] && (@battleStats.opponent.is_a?(Array) || @battleStats.doublebattle)
        x = 162#286
        y = @sprites["choose 1"].y
        set_xy_sprite("choose 1", x, y)
      end
      # ARREGLO 3: Colocar al rival centrado si es un Boss.
      if @sprites["choose 1"] && !@sprites["choose 3"] && 
         (@battleStats.opponent.is_a?(Array) || @battleStats.doublebattle) && 
         defined?(BOSS_SWITCH) && $game_switches[BOSS_SWITCH]
        x = 162
        y = @sprites["choose 1"].y
        set_xy_sprite("choose 1", x, y)
      end
      
			# Textos
			create_sprite_2("text", @viewport)
			@sprites["text"].z = 1
      
			# Iconos
			@pkmn.each_with_index { |pkmn, i|
				next if pkmn.nil?
        next if (defined?(BOSS_SWITCH) && $game_switches[BOSS_SWITCH] && i==3)
				pkmn = pkmn.effects[PBEffects::Illusion] if pkmn.effects[PBEffects::Illusion]
        file = pbCheckPokemonIconFiles([pkmn.species, pkmn.gender==1, pkmn.isShiny?, (pkmn.form rescue 0)], false)
        if (!(defined?(BOSS_SWITCH) && $game_switches[BOSS_SWITCH]) || i!=3)
          @sprites["pkmn #{i}"] = Bitmap.new(file)
        end
			}
			["point", "increase", "decrease"].each { |i| @sprites[i] = Bitmap.new("Graphics/Pictures/Battle/#{i.capitalize}") }
			["statuses", "types"].each { |i| @sprites[i] = Bitmap.new("Graphics/Pictures/#{i}") }
      
      # FLECHAS CAMBIO DE POKÉMON
        @sprites["leftarrow"]=AnimatedSprite.new("Graphics/Pictures/leftarrow",8,40,28,6,@viewport)
        @sprites["leftarrow"].x = 4
        @sprites["leftarrow"].y = 16
        @sprites["leftarrow"].visible = false
        @sprites["leftarrow"].play
        @sprites["rightarrow"]=AnimatedSprite.new("Graphics/Pictures/rightarrow",8,40,28,6,@viewport)
        @sprites["rightarrow"].x = Graphics.width-44
        @sprites["rightarrow"].y = 16
        @sprites["rightarrow"].visible = false
        @sprites["rightarrow"].play
		end

    
		#---------------------------------------------------#
		# TEXTOS DE LA PANTALLA DE ESTADÍSTICAS DEL POKÉMON #
		#---------------------------------------------------#
		def draw_information
			clearTxt("text")
      
      for i in 0..23
        @sprites["partyball #{i}"].dispose if @sprites["partyball #{i}"]
      end
      
			text = []
			bitmap = @sprites["text"].bitmap
			stat = ["ATTACK", "DEFENSE", "SPECIAL_ATTACK", "SPECIAL_DEFENSE", "SPEED", "ACCURACY", "EVASION", "CRITICS"]
      
      #################################
      # PANTALLA DE DATOS DEL POKÉMON #
      #################################
			if @chose
				xystat = []
        # PS
				stringhp = _INTL("PS: {1}/{2}",@pkmn[@position].hp,@pkmn[@position].totalhp)
				x = 64 + 8 + 20
				y = 34
        text << [stringhp, x, y, 0, PokeBattle_SceneConstants::INFO2BASECOLOR,PokeBattle_SceneConstants::INFO2SHADOWCOLOR] if (PokeBattle_SceneConstants::MOSTRAR_PS_RIVAL || (@position%2==0))
        # Nombre Pokémon
        string = "#{@pkmn[@position].name}"
				x = 64 + 8 + 20
				y = 4
				text << [_INTL("{1}",string), x, y, 0, PokeBattle_SceneConstants::INFO2BASECOLOR,PokeBattle_SceneConstants::INFO2SHADOWCOLOR]
        # Nivel del Pokémon
        x = 216
        string = _INTL("Nv. {1}",@pkmn[@position].level)
				y = 4
				text << [_INTL("{1}",string), x, y, 0, PokeBattle_SceneConstants::INFO2BASECOLOR,PokeBattle_SceneConstants::INFO2SHADOWCOLOR]
        # Turno del combate
        string =  _INTL("Turno: {1}",@battleStats.turncount + 1)
				x = 298
				#y = 18
				text << [_INTL("{1}",string), x, y, 0, PokeBattle_SceneConstants::INFO2BASECOLOR,PokeBattle_SceneConstants::INFO2SHADOWCOLOR]
        # Stats
        stat.each_with_index { |stat, i|
          string = 
            case stat
            when "ATTACK"          then PBStats.getName(1,true)
            when "DEFENSE"         then PBStats.getName(2,true)
            when "SPECIAL_ATTACK"  then PBStats.getName(4,true)
            when "SPECIAL_DEFENSE" then PBStats.getName(5,true)
            when "SPEED"           then PBStats.getName(3,true)
            when "ACCURACY"        then PBStats.getName(6,true)
            when "EVASION"         then PBStats.getName(7,true)
            when "CRITICS"         then _INTL("Crítico")
            else stat
            end
            
          x = (i%2==0 ? 24 : (280))
          y = 64 + 30 * (i / 2)+14
          text << [_INTL("{1}",string), x, y, 0, PokeBattle_SceneConstants::INFO2BASECOLOR,PokeBattle_SceneConstants::INFO2SHADOWCOLOR]
          xystat << [x, y]
        }
        # Habilidad
        yabi = 208
        if (PokeBattle_SceneConstants::MOSTRAR_HABILIDAD_RIVAL || (@position%2==0))
          string = _INTL("Habilidad:")
          x = xystat[stat.size-1][0]
          text << [_INTL("{1}",string), x, yabi-2, 0, PokeBattle_SceneConstants::INFO2BASECOLOR,PokeBattle_SceneConstants::INFO2SHADOWCOLOR]
          
          string = _INTL("{1}",PBAbilities.getName(@pkmn[@position].ability))
          x = 266
          text << [_INTL("{1}",string), x, yabi-2, 1, PokeBattle_SceneConstants::INFOBASECOLOR,PokeBattle_SceneConstants::INFOSHADOWCOLOR]

        end
        # Objeto equipado
        if (PokeBattle_SceneConstants::MOSTRAR_OBJETO_RIVAL || (@position%2==0))
          itname = @pkmn[@position].item==0 ? "---" : PBItems.getName(@pkmn[@position].item)

          string = _INTL("Objeto:")
          x = xystat[stat.size-1][0]
          y = yabi + 30
          text << [_INTL("{1}",string), x, y-2, 0, PokeBattle_SceneConstants::INFO2BASECOLOR,PokeBattle_SceneConstants::INFO2SHADOWCOLOR]

          string = _INTL("{1}",itname)
          x = 266
          text << [_INTL("{1}",string), x, y-2, 1, PokeBattle_SceneConstants::INFOBASECOLOR,PokeBattle_SceneConstants::INFOSHADOWCOLOR]
        end
        # Último mov. usado
        string = _INTL("Último movimiento: ")
        x = xystat[stat.size-1][0]
        y = 304
        text << [_INTL("{1}",string), x, y, 0, PokeBattle_SceneConstants::INFO2BASECOLOR,PokeBattle_SceneConstants::INFO2SHADOWCOLOR]
        string = "#{PBMoves.getName(@pkmn[@position].lastMoveUsed)}"
        string = "---" if @pkmn[@position].lastMoveUsed == -1
        y += 36
        text << [_INTL("{1}",string), x, y, 0, PokeBattle_SceneConstants::INFOBASECOLOR,PokeBattle_SceneConstants::INFOSHADOWCOLOR]
        # Efectos de combate
        string = _INTL("Efectos de combate:")
        x = 280
        y = yabi
        text << [_INTL("{1}",string), x, y, 0, PokeBattle_SceneConstants::INFO2BASECOLOR,PokeBattle_SceneConstants::INFO2SHADOWCOLOR]
        
        if @showactive && @showactive[0]!=nil
          active = store_active
          active.each_with_index { |atv, i|
            string = atv
            x = 280
            y = yabi + 26 * i + 28
            text << [_INTL("{1}",string), x, y, 0, PokeBattle_SceneConstants::INFOBASECOLOR,PokeBattle_SceneConstants::INFOSHADOWCOLOR]
          }
        end
        
      ####################################
      # PANTALLA DE SELECCIÓN DE POKÉMON #
      ####################################
			else
        # Escribir los textos de los Pokémon
				@pkmn.each_with_index { |pkmn, i|
					next if !@sprites["choose #{i}"] || pkmn.nil?
					string = "#{pkmn.name}"
					x = @sprites["choose #{i}"].x + 69
					y = @sprites["choose #{i}"].y + 26
					text << [_INTL("{1}",string), x, y, 0, PokeBattle_SceneConstants::INFO2BASECOLOR,PokeBattle_SceneConstants::INFO2SHADOWCOLOR,true]
				}
        
        ###############################################
        # POKEBALLS EN SELECCION CON TOTAL DE POKÉMON #
        ###############################################
        
        #---------------------------------------------------#
        # Mostrar balls del equipo del jugador
        #---------------------------------------------------#
        for i in 0..5
          create_sprite("partyball #{i}", "battler_ball", @viewport)
          w = (@sprites["partyball #{i}"].bitmap.width / 4)
          h = @sprites["partyball #{i}"].bitmap.height
          set_src_wh_sprite("partyball #{i}", w, h)
          set_zoom_sprite("partyball #{i}",2.0,2.0)
          set_src_xy_sprite("partyball #{i}", 45, 0)     # Ball vacía
          x = 176 + 30 * i
          x -= 130 if @battleStats.player.is_a?(Array)
          y = 246
          set_xy_sprite("partyball #{i}", x, y)
        end
        
        # Contamos cantidad de Pokémon de cada uno.
        tamTeamJugador = 0
        tamTeamPartner = 0
        if @battleStats.player.is_a?(Array) # Combate múltiple
          @battleStats.pbParty(0).each_with_index { |name, i|
            if @battleStats.pbSecondPartyBegin(0) == 3 # Team 2 empieza en pos 3
                tamTeamJugador+=1 if i<3 && name!=nil
                tamTeamPartner+=1 if i>=3 && name!=nil
            else                                       # Team 2 empieza en pos 6
                tamTeamJugador+=1 if i<6 && name!=nil
                tamTeamPartner+=1 if i>=6 && name!=nil              
            end
          }
        else                                # Combate no múltiple
          @battleStats.pbParty(0).each_with_index { |name, i|
              tamTeamJugador+=1 if name!=nil
            }
        end
          
        # Modificamos las balls del jugador en base a su estado
        @battleStats.pbParty(0).each_with_index { |name, i|
          if name!=nil && !name.isEgg? && i<tamTeamJugador
            if name.hp==0
              set_src_xy_sprite("partyball #{i}", 30, 0) # Debilitado 
            elsif name.status>0
              set_src_xy_sprite("partyball #{i}", 15, 0) # Status
            else
              set_src_xy_sprite("partyball #{i}", 0, 0)  # Sano
            end
          end
        }
        #---------------------------------------------------#
        # Compañero del jugador en batallas múltiples
        #---------------------------------------------------#
        if @battleStats.player.is_a?(Array)
          for i in 12..17
            create_sprite("partyball #{i}", "battler_ball", @viewport)
            w = (@sprites["partyball #{i}"].bitmap.width / 4)
            h = @sprites["partyball #{i}"].bitmap.height
            set_src_wh_sprite("partyball #{i}", w, h)
            set_zoom_sprite("partyball #{i}",2.0,2.0)
            set_src_xy_sprite("partyball #{i}", 45, 0)           # Ball vacía
            x = 176 + 30 * (i-12) +120
            y = 246
            set_xy_sprite("partyball #{i}", x, y)
          end
          # Modificamos las balls del compañero en base a su estado
          @battleStats.pbParty(0).each_with_index { |name, i|
            if @battleStats.pbSecondPartyBegin(0) == 3 # Team 2 empieza en pos 3
              if i>=3
                if name!=nil && !name.isEgg?
                  if name.hp==0
                    set_src_xy_sprite("partyball #{i+9}", 30, 0) # Debilitado 
                  elsif name.status>0
                    set_src_xy_sprite("partyball #{i+9}", 15, 0) # Status
                  else
                    set_src_xy_sprite("partyball #{i+9}", 0, 0)  # Sano
                  end
                end
              end
            else                                       # Team 2 empieza en pos 6
              if i>=6
                if name!=nil && !name.isEgg?
                  if name.hp==0
                    set_src_xy_sprite("partyball #{i+6}", 30, 0) # Debilitado 
                  elsif name.status>0
                    set_src_xy_sprite("partyball #{i+6}", 15, 0) # Status
                  else
                    set_src_xy_sprite("partyball #{i+6}", 0, 0)  # Sano
                  end
                end
              end
            end
          }
        end
        #---------------------------------------------------#
        # Mostrar balls del rival
        #---------------------------------------------------#
        if @rivalTrainer
          for i in 6..11
            create_sprite("partyball #{i}", "battler_ball", @viewport)
            w = (@sprites["partyball #{i}"].bitmap.width / 4)
            h = @sprites["partyball #{i}"].bitmap.height
            set_src_wh_sprite("partyball #{i}", w, h)
            set_zoom_sprite("partyball #{i}",2.0,2.0)
            set_src_xy_sprite("partyball #{i}", 45, 0)           # Ball vacía
            x = 176 + 30 * (i-6)
            x += 120 if @battleStats.opponent.is_a?(Array)
            y = 23
            set_xy_sprite("partyball #{i}", x, y)
          end
          
          # Contamos cantidad de Pokémon de cada uno.
          tamTeamRival1 = 0
          tamTeamRival2 = 0
          if @battleStats.opponent.is_a?(Array) # Combate múltiple
            @battleStats.pbParty(1).each_with_index { |name, i|
              if @battleStats.pbSecondPartyBegin(1) == 3 # Team 2 empieza en pos 3
                  tamTeamRival1+=1 if i<3 && name!=nil
                  tamTeamRival2+=1 if i>=3 && name!=nil
              else                                       # Team 2 empieza en pos 6
                  tamTeamRival1+=1 if i<6 && name!=nil
                  tamTeamRival2+=1 if i>=6 && name!=nil              
              end
            }
          else                                # Combate no múltiple
            @battleStats.pbParty(1).each_with_index { |name, i|
                tamTeamRival1+=1 if name!=nil
              }
          end
          
          # Modificamos las balls del rival 1 en base a su estado
          @battleStats.pbParty(1).each_with_index { |name, i|
            if name!=nil && !name.isEgg? && i<tamTeamRival1
              if name.hp==0
                set_src_xy_sprite("partyball #{i+6}", 30, 0) # Debilitado 
              elsif name.status>0
                set_src_xy_sprite("partyball #{i+6}", 15, 0) # Status
              else
                set_src_xy_sprite("partyball #{i+6}", 0, 0)  # Sano
              end
            end
          }
          
          #---------------------------------------------------#
          # Segundo rival en batalla doble
          #---------------------------------------------------#
          if @battleStats.opponent.is_a?(Array)
            for i in 18..23
              create_sprite("partyball #{i}", "battler_ball", @viewport)
              w = (@sprites["partyball #{i}"].bitmap.width / 4)
              h = @sprites["partyball #{i}"].bitmap.height
              set_src_wh_sprite("partyball #{i}", w, h)
              set_zoom_sprite("partyball #{i}",2.0,2.0)
              set_src_xy_sprite("partyball #{i}", 45, 0)           # Ball vacía
              x = 176 + 30 * (i-18) -120
              y = 23
              set_xy_sprite("partyball #{i}", x, y)
            end
            # Modificamos las balls del compañero en base a su estado
            @battleStats.pbParty(1).each_with_index { |name, i|
              if @battleStats.pbSecondPartyBegin(1) == 3 # Team 2 empieza en pos 3
                if i>=3
                  if name!=nil && !name.isEgg?
                    if name.hp==0
                      set_src_xy_sprite("partyball #{i+15}", 30, 0) # Debilitado 
                    elsif name.status>0
                      set_src_xy_sprite("partyball #{i+15}", 15, 0) # Status
                    else
                      set_src_xy_sprite("partyball #{i+15}", 0, 0)  # Sano
                    end
                  end
                end
              else                                       # Team 2 empieza en pos 6
                if i>=6
                  if name!=nil && !name.isEgg?
                    if name.hp==0
                      set_src_xy_sprite("partyball #{i+12}", 30, 0) # Debilitado 
                    elsif name.status>0
                      set_src_xy_sprite("partyball #{i+12}", 15, 0) # Status
                    else
                      set_src_xy_sprite("partyball #{i+12}", 0, 0)  # Sano
                    end
                  end
                end
              end
            }
          end
        end
			end
  ##########################################################################
      
			drawTxt("text", text)
			# Bitmap
			if @frames > 4
				@iconw += 64
				@iconw  = 0 if @iconw > 64
				@frames = 0
			end
			rect = Rect.new(@iconw, 0, 64, 64)
			
      if @chose
				bitmap.blt(32, 0, @sprites["pkmn #{@position}"], rect)
				if @active == 0
					# Stats
					stat = [PBStats::ATTACK, PBStats::DEFENSE, PBStats::SPATK, PBStats::SPDEF, PBStats::SPEED, PBStats::ACCURACY, PBStats::EVASION]
					stat.each_with_index { |stat, i|
						stage = @pkmn[@position].stages[stat]
						rectnew = Rect.new(0, 0, 30, 30)
						if stage > 0
							file = @sprites["increase"]
							(stage.abs).times { |j|
								x = xystat[i][0] + 86 + 20 * j
								y = xystat[i][1]
								bitmap.blt(x, y, file, rectnew)
							}
						elsif stage < 0
							file = @sprites["decrease"]
							(stage.abs).times { |j|
								x = xystat[i][0] + 86 + 20 * j
								y = xystat[i][1]
								bitmap.blt(x, y, file, rectnew)
							}
						end
						minus = 6 - (stage.abs)
						next if minus <= 0
						file = @sprites["point"]
						minus.times { |j|
							x = xystat[i][0] + 86 + 20 * (6 - minus + j)
							y = xystat[i][1]
							bitmap.blt(x, y, file, rectnew)
						}
					}
          # Criticos
          stage = checkLevelCritical(@pkmn[@position])
          rectnew = Rect.new(0, 0, 30, 30)
          i=7
          if stage > 0
            file = @sprites["increase"]
            (stage.abs).times { |j|
              x = xystat[i][0] + 86 + 20 * j
              y = xystat[i][1]
              bitmap.blt(x, y, file, rectnew)
            }
          end
          minus = 4 - (stage.abs)
          next if minus <= 0
          file = @sprites["point"]
          minus.times { |j|
            x = xystat[i][0] + 86 + 20 * (6 - minus + j)
            y = xystat[i][1]
            bitmap.blt(x, y, file, rectnew)
          }
				end
        
				# TIPOS DEL POKÉMON
				file = @sprites["types"]
        
        # MODIFICAMOS LOS TIPOS MOSTRADOS SI ESTÁ BAJO EL EFECTO DE ILUSIÓN.
        if @pkmn[@position].effects[PBEffects::Illusion]
          # Si tiene dos tipos
          if @pkmn[@position].effects[PBEffects::Illusion].type2 && @pkmn[@position].effects[PBEffects::Illusion].type2 != @pkmn[@position].effects[PBEffects::Illusion].type1
            srcy = getID(PBTypes, @pkmn[@position].effects[PBEffects::Illusion].type1)
            x = Graphics.width - @sprites["types"].width - 34
            y = 2+4
            bitmap.blt(x, y, file, Rect.new(0, srcy * 28, 64, 28))
            if @pkmn[@position].effects[PBEffects::Illusion].type2 && @pkmn[@position].effects[PBEffects::Illusion].type2 != @pkmn[@position].effects[PBEffects::Illusion].type1
              x = Graphics.width - @sprites["types"].width - 34
              file = @sprites["types"]
              srcy = getID(PBTypes, @pkmn[@position].effects[PBEffects::Illusion].type2)
              bitmap.blt(x, y+30+4, file, Rect.new(0, srcy * 28, 64, 28))
            end
          else
            srcy = getID(PBTypes, @pkmn[@position].effects[PBEffects::Illusion].type1)
            x = Graphics.width - @sprites["types"].width - 34
            y = 15+4
            bitmap.blt(x, y, file, Rect.new(0, srcy * 28, 64, 28))
          end
        else # SIN ILUSION
          # Si tiene dos tipos
          if @pkmn[@position].type2 && @pkmn[@position].type2 != @pkmn[@position].type1
            srcy = getID(PBTypes, @pkmn[@position].type1)
            x = Graphics.width - @sprites["types"].width - 34
            y = 6
            bitmap.blt(x, y, file, Rect.new(0, srcy * 28, 64, 28))
            if @pkmn[@position].type2 && @pkmn[@position].type2 != @pkmn[@position].type1
              x = Graphics.width - @sprites["types"].width - 34
              file = @sprites["types"]
              srcy = getID(PBTypes, @pkmn[@position].type2)
              bitmap.blt(x, y+26, file, Rect.new(0, srcy * 28, 64, 28))
            end
          else
            srcy = getID(PBTypes, @pkmn[@position].type1)
            x = Graphics.width - @sprites["types"].width - 34
            y = 16
            bitmap.blt(x, y, file, Rect.new(0, srcy * 28, 64, 28))
          end
        end
        
        # FLECHAS CAMBIO DE POKÉMON
        @sprites["leftarrow"].visible = true
        @sprites["rightarrow"].visible = true
        
        
				# ESTADO
				x = 64 + 5 + bitmap.text_size(stringhp).width + 30
				y = 40
				file = @sprites["statuses"]
				srcy = getID(PBStatuses, @pkmn[@position].status) - 1
				bitmap.blt(x, y, file, Rect.new(0, srcy * 16, 44, 16)) if @pkmn[@position].status!=0

			else
        # SPRITES POKÉMON PARA SELECCIONAR
				@pkmn.each_with_index { |pkmn, i|
					next if pkmn.nil?
          next if defined?(BOSS_SWITCH) && $game_switches[BOSS_SWITCH] && i==3
					x = @sprites["choose #{i}"].x
					y = @sprites["choose #{i}"].y
          bitmap.blt(x, y, @sprites["pkmn #{i}"], rect)
				}
			end
			@frames += 1
		end

    # Función para separar en líneas la descripción de la habilidad.
		def split_text(text1, width)
			i = 0
			str = ""
			text2 = []
			length = text1.length
			real = length * 12
			# Use to define 'Space'
			space = 0
			first = true
			strfake = ""
			loop do
				break if i == text1.length
				if first
					if text1[i] == " "
						i += 1
						next
					end
					first = false
				end
				space += 1 if text1[i] == " "
				str << text1[i] if space < 1
				if space > 0
					strfake << text1[i]
					if space == 2 && i+1 != text1.length
						if (str.length + strfake.length) * 12 > width
							text2 << str
							str = strfake
						elsif (str.length + strfake.length) * 12 <= width
							str << strfake
						end
						strfake = ""
						space = 1
					elsif i+1 == text1.length
						text2 << (str + strfake)
					end
				else
					text2 << str if i+1 == text1.length
				end
				i += 1
			end
			return text2
		end


		#---------------------------#
		# CONTROLES DENTRO DEL MENÚ #
		#---------------------------#
		def set_input
			@exit = true if checkInput(Input::B)
			if checkInput(Input::C)
				@chose = true
        # Set active
				change_active
      end
      
      #-------------------------------------------------#
      # Pantalla de datos del Pokémon
      #-------------------------------------------------#
      if @chose
        if checkInput(Input::LEFT)
          loop do
            if @position == 0
              @position = 1
            elsif @position == 2
              @position = 0
            elsif @position == 1
              @position = 3
            elsif @position == 3
              @position = 2
            end
            break if !@pkmn[@position].nil?
          end
          # Set active
          change_active
        elsif checkInput(Input::RIGHT)
          loop do
            if @position == 0
              @position = 2
            elsif @position == 2
              @position = 3
            elsif @position == 3
              @position = 1
            elsif @position == 1
              @position = 0
            end
            break if !@pkmn[@position].nil?
          end
          # Set active
          change_active
        end
      #-------------------------------------------------#
      # Pantalla de elección del Pokémon
      #-------------------------------------------------#
      else
        # IZDA
        if checkInput(Input::LEFT)
          if @position==0
            @position = 2
          elsif @position==1
            @position = 3
          elsif @position==2
            @position = 0
          elsif @position==3
            @position = 1
          end
          if @position==3 && @position>=@pkmn.size # Si no hay pos.3, hay pos.1 (indis)
            @position = 1
          elsif @position == 2 && !@sprites["choose 2"]
            @position = 0
          end
          change_active # Set active
        # DCHA
        elsif checkInput(Input::RIGHT)
          
          if @position==0
            @position = 2
          elsif @position==1
            @position = 3
          elsif @position==2
            @position = 0
          elsif @position==3
            @position = 1
          end
          if @position==3 && @position>=@pkmn.size # Si no hay pos.3, hay pos.1 (indis)
            @position = 1
          elsif @position == 2 && !@sprites["choose 2"]
            @position = 0
          end
          change_active # Set active
        # ARRIBA
        elsif checkInput(Input::UP)
          if @position==0
            @position = 3
          elsif @position==1
            @position = 2
          elsif @position==2
            @position = 1
          elsif @position==3
            @position = 0
          end
          if @position==3 && @position>=@pkmn.size # Si no hay pos.3, hay pos.1 (indis)
            @position = 1
          elsif @position == 2 && (!@sprites["choose 2"] || (defined?(BOSS_SWITCH) && $game_switches[BOSS_SWITCH]))
            @position = 0
          end
          change_active # Set active
        # ABAJO
        elsif checkInput(Input::DOWN)
          if @position==0
            @position = 3
          elsif @position==1
            @position = 2
          elsif @position==2
            @position = 1
          elsif @position==3
            @position = 0
          end
          if @position==3 && @position>=@pkmn.size # Si no hay pos.3, hay pos.1 (indis)
            @position = 1
          elsif @position == 2 && (!@sprites["choose 2"] || (defined?(BOSS_SWITCH) && $game_switches[BOSS_SWITCH]))
            @position = 0
          end
          change_active # Set active
        end
      end
		end

		#--------#
		# Update #
		#--------#
		def update_bg
			return if !@chose || (@chose && @bg == 2)
			@bg = 2
			set_sprite("bg", "Scene_#{@bg}")
		end

		def update_choose_bar
			if @chose
				@pkmn.each_with_index { |pkmn, i|
					next if pkmn.nil?
					set_visible_sprite("choose #{i}")
				}
				return
			end
			@pkmn.each_with_index { |pkmn, i|
				next if pkmn.nil?
				h = i == @position ? @sprites["choose #{i}"].src_rect.height : 0
				set_src_xy_sprite("choose #{i}", 0, h)
			}
		end

		
		#--------------#
		# Check active #
		#--------------#
		def store_active
			active = []
      show = []
      case @showactive[0]
      when @activef then 
        for i in @showactive[0]
          show << i
        end
      when @actives then
        for i in @showactive[0][@position%2]
          show << i
        end
      when @activep then
        for i in @showactive[0][@position]
          show << i
        end
      end
      if @showactive[1]!=nil
        case @showactive[1]
        when @actives then
          for i in @showactive[1][@position%2]
            show << i
          end
        when @activep then
          for i in @showactive[1][@position]
            show << i
          end
        end
      end
      if @showactive[2]!=nil
        for i in @showactive[2][@position]
          show << i
        end
      end
        
			show.each { |k, v| active << "#{v}" }
			width = 512
			active.each_with_index{ |line, i|
				length = line.length
				real   = length * 12
				rate   = real / width
				next if rate <= 0
				arrfake = split_text(line, width)
				arrfake.each_with_index { |fake, j| j == 0 ? (active[i] = fake) : (active.insert(i+1, fake)) }
			}
			if active.size > max_show_active
				@framesactive += 1
				if @framesactive > 2 ** 5
					@framesactive = 0
					@originactive += 1
					@originactive  = 0 if @originactive >= active.size
				end
				rest = @originactive + max_show_active - active.size if @originactive + max_show_active > active.size
				activefake = active[@originactive...(@originactive + max_show_active)]
				rest.times { |i| activefake << active[i] } if rest
				active = activefake
			end
			return active
		end

		def max_show_active
			return 9
		end

		def change_active(rs=true)
			return unless @chose
			# Set
			set_active_size
			# Reset
			@active = 0 if rs
			@originactive = 0
			@framesactive = 0
		end
  
    def checkLevelCritical(attacker)
      c=0
      if attacker.effects[PBEffects::LaserFocus]>0
        return c=4
      end
      c+=attacker.effects[PBEffects::FocusEnergy]
      if (attacker.inHyperMode? rescue false) && isConst?(self.type,PBTypes,:SHADOW)
        c+=1
      end
      c+=1 if attacker.hasWorkingAbility(:SUPERLUCK)
      if attacker.hasWorkingItem(:STICK) &&
         (isConst?(attacker.species,PBSpecies,:FARFETCHD) ||
          isConst?(attacker.species,PBSpecies,:SIRFETCHD))
        c+=2
      end
      if attacker.hasWorkingItem(:LUCKYPUNCH) &&
         isConst?(attacker.species,PBSpecies,:CHANSEY)
        c+=2
      end
      c+=1 if attacker.hasWorkingItem(:RAZORCLAW)
      c+=1 if attacker.hasWorkingItem(:SCOPELENS)
      c=4 if c>4
      return c
    end
    
	end
  
end



#==============================================================================#
#==============================================================================#
#==============================================================================#
#==============================================================================#

begin
	module PBEffects
		STORE_SPECIES = 500
	end
rescue Exception
  if $!.is_a?(SystemExit) || "#{$!.class}"=="Reset"
    raise $!
  end
end


class PokeBattle_Battler
	alias check_stat_init_effect pbInitEffects

	def pbInitEffects(batonPass)
		check_stat_init_effect(batonPass)
		@effects[PBEffects::STORE_SPECIES] = 0
	end

	def pbTransform(target)
    return
		@effects[PBEffects::STORE_SPECIES] = target
		check_stat_transform(target)
	end
end


class PokeBattle_Battle

	def array_change_stats_in_battle(side=0)
		ret = {}
		[:player, :opponent].each_with_index { |name, i|
			ret[name] = {
				:name => [],
				:pkmn => []
			}
			@battlers.each_with_index { |pkmn, j|
        next unless pkmn && !pkmn.isFainted? && !pkmn.pbIsOpposing?(i)
				ret[name][:pkmn] << pkmn
			}
		}
		# Name of player
		@battlers.each_with_index { |pkmn, i|
			next unless pkmn && !pkmn.isFainted?
			if i%2==0
				ret[:player][:name] << ""
			else
				next if !@opponent
				ret[:opponent][:name] << ""
			end
		}
		# Player
		return ret[:player] if side == 0
		# Opponent
		return ret[:opponent]
	end

	#------------#
	# Get active #
	#------------#
	def active_field
		ret = {}

    # CLIMAS
    if pbWeather != 0
      if weatherduration > 0
        if pbWeather==PBWeather::SUNNYDAY
          ret["Clima"] = _INTL("Clima soleado ({1})",weatherduration.to_s)
        elsif pbWeather==PBWeather::RAINDANCE
          ret["Clima"] = _INTL("Clima lluvioso ({1})",weatherduration.to_s)
        elsif pbWeather==PBWeather::SANDSTORM
          ret["Clima"] = _INTL("Clima torm. arena ({1})",weatherduration.to_s)
        elsif pbWeather==PBWeather::HAIL
          ret["Clima"] = _INTL("Clima granizo ({1})",weatherduration.to_s)
        elsif pbWeather==PBWeather::HARSHSUN
          ret["Clima"] = _INTL("Clima sol abrasador ({1})",weatherduration.to_s)
        elsif pbWeather==PBWeather::HEAVYRAIN
          ret["Clima"] = _INTL("Clima diluvio ({1})",weatherduration.to_s)
        elsif pbWeather==PBWeather::STRONGWINDS
          ret["Clima"] = _INTL("Clima turbulencias ({1})",weatherduration.to_s)
        end
      elsif weatherduration < 0
        if pbWeather==PBWeather::SUNNYDAY
          ret["Clima"] = _INTL("Clima soleado")
        elsif pbWeather==PBWeather::RAINDANCE
          ret["Clima"] = _INTL("Clima lluvioso")
        elsif pbWeather==PBWeather::SANDSTORM
          ret["Clima"] = _INTL("Clima torm. arena")
        elsif pbWeather==PBWeather::HAIL
          ret["Clima"] = _INTL("Clima granizo")
        elsif pbWeather==PBWeather::HARSHSUN
          ret["Clima"] = _INTL("Clima sol abrasador")
        elsif pbWeather==PBWeather::HEAVYRAIN
          ret["Clima"] = _INTL("Clima diluvio")
        elsif pbWeather==PBWeather::STRONGWINDS
          ret["Clima"] = _INTL("Clima turbulencias")
        end
      end
    end
    
    # TERRENOS
    if field.effects[PBEffects::ElectricTerrain ]>0
      ret["Campo"] = PBMoves.getName(PBMoves::ELECTRICTERRAIN) + "(" + field.effects[PBEffects::ElectricTerrain].to_s + ")"
    end
    if field.effects[PBEffects::GrassyTerrain ]>0
      ret["Campo"] = PBMoves.getName(PBMoves::GRASSYTERRAIN) + "(" + field.effects[PBEffects::GrassyTerrain].to_s + ")"
    end
    if field.effects[PBEffects::MistyTerrain ]>0
      ret["Campo"] = PBMoves.getName(PBMoves::MISTYTERRAIN) + "(" + field.effects[PBEffects::MistyTerrain].to_s + ")"
    end
    if field.effects[PBEffects::PsychicTerrain ]>0
      ret["Campo"] = PBMoves.getName(PBMoves::PSYCHICTERRAIN) + "(" + field.effects[PBEffects::PsychicTerrain].to_s + ")"
    end
    
    # EFECETOS DE CAMPO
		@field.effects.each_with_index { |effect, i|
			next if effect.nil?
			next if !effect || effect == 0
			case i
			when PBEffects::FairyLock       then ret["Cerrojo Feérico"] = PBMoves.getName(PBMoves::FAIRYLOCK)
			when PBEffects::Gravity         then ret["Gravedad"]        = (PBMoves.getName(PBMoves::GRAVITY) + " (" + effect.to_s + ")") if effect != 0
			when PBEffects::MagicRoom       then ret["Zona Mágica"]     = (PBMoves.getName(PBMoves::MAGICROOM) + " (" + effect.to_s + ")") if effect != 0
			when PBEffects::MudSportField   then ret["Chapoteo lodo"]   = (PBMoves.getName(PBMoves::MUDSPORT) + " (" + effect.to_s + ")") if effect != 0
			when PBEffects::TrickRoom       then ret["Espacio Raro"]    = (PBMoves.getName(PBMoves::TRICKROOM) + " (" + effect.to_s + ")") if effect != 0
			when PBEffects::WaterSportField then ret["Hidrochorro"]     = (PBMoves.getName(PBMoves::WATERSPORT) + " (" + effect.to_s + ")") if effect != 0
			when PBEffects::WonderRoom      then ret["Zona Extraña"]    = (PBMoves.getName(PBMoves::WONDERROOM) + " (" + effect.to_s + ")") if effect != 0
			when PBEffects::CorrosiveGas    then ret["Gas Corrosivo"]   = PBMoves.getName(PBMoves::CORROSIVEGAS)
			end
		}

		return ret
	end

	def active_side
		ret = [{}, {}]
		ret.each_with_index { |_, i|
			@sides[i].effects.each_with_index { |effect, j|
				next if effect.nil?
				next if !effect
				case j
				when PBEffects::AuroraVeil         then ret[i]["Velo Aurora"]      = (PBMoves.getName(PBMoves::AURORAVEIL) + " (" + effect.to_s + ")") if effect != 0
				when PBEffects::EchoedVoiceCounter then ret[i]["Contador Eco Voz"] = _INTL("Contador Eco Voz ({1})",effect.to_s) if effect != 0
				when PBEffects::LightScreen        then ret[i]["Pantalla Luz"]     = (PBMoves.getName(PBMoves::LIGHTSCREEN) + " (" + effect.to_s + ")") if effect != 0
				when PBEffects::LuckyChant         then ret[i]["Conjuro"]          = (PBMoves.getName(PBMoves::LUCKYCHANT) + " (" + effect.to_s + ")") if effect != 0
				when PBEffects::Reflect            then ret[i]["Reflejo"]          = (PBMoves.getName(PBMoves::REFLECT) + " (" + effect.to_s + ")") if effect != 0
				when PBEffects::Safeguard          then ret[i]["Velo Sagrado"]     = (PBMoves.getName(PBMoves::SAFEGUARD) + " (" + effect.to_s + ")") if effect != 0
				when PBEffects::Spikes             then ret[i]["Púas"]             = (PBMoves.getName(PBMoves::SPIKES) + " (" + effect.to_s + ")") if effect != 0
				when PBEffects::StealthRock        then ret[i]["Trampa Rocas"]     = PBMoves.getName(PBMoves::STEALTHROCK)
				when PBEffects::StickyWeb          then ret[i]["Red viscosa"]      = PBMoves.getName(PBMoves::STICKYWEB)
				when PBEffects::Swamp              then ret[i]["Ciénaga"]          = _INTL("Pantano({1})",effect.to_s) if effect != 0
				when PBEffects::SeaOfFire          then ret[i]["Mar de fuego"]     = _INTL("Mar de Llamas({1})",effect.to_s) if effect != 0
				when PBEffects::Rainbow            then ret[i]["Arcoíris"]         = _INTL("Arcoíris ({1})",effect.to_s) if effect != 0
				when PBEffects::Tailwind           then ret[i]["Viento afín"]      = (PBMoves.getName(PBMoves::TAILWIND) + " (" + effect.to_s + ")") if effect != 0
				when PBEffects::ToxicSpikes        then ret[i]["Púas Tóxicas"]     = (PBMoves.getName(PBMoves::TOXICSPIKES) + " (" + effect.to_s + ")") if effect != 0
				when PBEffects::FaintedAlly        then ret[i]["FaintedAlly"]      = _INTL("Aliado Derrotado ({1})",effect.to_s) if effect != 0
        end
			}
		}
		return ret
	end
  
  
  def active_position
		ret = []
    
    player = array_change_stats_in_battle
		opponent = array_change_stats_in_battle(1)
    @pkmn = []
    player[:pkmn].each_with_index { |pkmn, i| @pkmn[2*i] = pkmn }
    opponent[:pkmn].each_with_index { |pkmn, i| @pkmn[2*i+1] = pkmn }
    count = 0
		@pkmn.each_with_index { |pos, i|
      begin #Añadido por Clara, deberia evitar crashes si no encuentra un efecto.
			pkmn = @battlers[i]
			ret << {}
			next unless pkmn && !pkmn.isFainted? && pos
			pos.effects.each_with_index { |effect, j|
      
      count += 1
      
      # Protección
      numProts = effect
      protsTotales = 0
      if j==PBEffects::ProtectRate
        while numProts>1
          numProts/=2
          protsTotales+=1
        end
      end
        
      # Deseo
      wishReady = false
      pos.effects.each_with_index { |effectDX, k|
        case k
        when PBEffects::Wish then wishReady=true if effectDX>0
        end
      }
        
      # Desenrollar
      desenrollar = 0
      case j
      when PBEffects::Rollout then desenrollar=5-effect if effect>0
      end
        
      # Venganza
      venganza = 0
      case j
      when PBEffects::Bide then venganza=3-effect if effect>0
      end
      
      if effect
        case j
          when PBEffects::FutureSight    then ret[i][count.to_s] = _INTL("{1} ({2})",PBMoves.getName(PBMoves::FUTURESIGHT),effect.to_s) if effect != 0
          when PBEffects::WishAmount     then ret[i][count.to_s] = _INTL("{1} ({2} PS)",PBMoves.getName(PBMoves:WISH),effect.to_s) if (effect != 0 && wishReady)
          when PBEffects::Bide           then ret[i][count.to_s] = _INTL("{1} ({2})",PBMoves.getName(PBMoves::BIDE),effect.to_s) if effect != 0
          when PBEffects::Charge         then ret[i][count.to_s] = PBMoves.getName(PBMoves::CHARGE) if effect != 0
          when PBEffects::Confusion      then ret[i][count.to_s] = _INTL("Confuso") if effect != 0
          when PBEffects::Curse          then ret[i][count.to_s] = _INTL("Maldito")
          when PBEffects::DefenseCurl    then ret[i][count.to_s] = PBMoves.getName(PBMoves::DEFENSECURL)
          when PBEffects::DestinyBond    then ret[i][count.to_s] = PBMoves.getName(PBMoves::DESTINYBOND)
          when PBEffects::Embargo        then ret[i][count.to_s] = PBMoves.getName(PBMoves::EMBARGO) if effect != 0
          when PBEffects::Foresight      then ret[i][count.to_s] = PBMoves.getName(PBMoves::FORESIGHT)
          when PBEffects::FuryCutter     then ret[i][count.to_s] = _INTL("{1} ({2})",PBMoves.getName(PBMoves::FURYCUTTER),effect.to_s) if effect != 0
          when PBEffects::ProtectRate    then ret[i][count.to_s] = _INTL("Protegido({1})",protsTotales.to_s) if effect != 1
          when PBEffects::HealBlock      then ret[i][count.to_s] = PBMoves.getName(PBMoves::HEALBLOCK) if effect != 0
          when PBEffects::HyperBeam      then ret[i][count.to_s] = _INTL("Necesita descansar") if effect != 0
          when PBEffects::Imprison       then ret[i][count.to_s] = PBMoves.getName(PBMoves::IMPRISON)
          when PBEffects::Ingrain        then ret[i][count.to_s] = PBMoves.getName(PBMoves::INGRAIN)
          when PBEffects::LeechSeed      then ret[i][count.to_s] = PBMoves.getName(PBMoves::LEECHSEED) if effect != -1
          when PBEffects::LockOn         then ret[i][count.to_s] = PBMoves.getName(PBMoves::LOCKON) if effect != 0
          when PBEffects::MagnetRise     then ret[i][count.to_s] = PBMoves.getName(PBMoves::MAGNETRISE) if effect != 0
          when PBEffects::MeanLook, PBEffects::Octolock, PBEffects::NoRetreat, PBEffects::JawLock
            ret[i][count.to_s] = _INTL("Apresado") if effect != -1
          when PBEffects::Minimize       then ret[i][count.to_s] = PBMoves.getName(PBMoves::MINIMIZE)
          when PBEffects::MiracleEye     then ret[i][count.to_s] = PBMoves.getName(PBMoves::MIRACLEYE)
          when PBEffects::Nightmare      then ret[i][count.to_s] = PBMoves.getName(PBMoves::NIGHTMARE)
          when PBEffects::PerishSong, PBEffects::PerishBody 
            ret[i][count.to_s] = _INTL("{1} ({2})",PBMoves.getName(PBMoves::PERISHSONG),effect.to_s) if effect != 0
          when PBEffects::PowerTrick     then ret[i][count.to_s] = PBMoves.getName(PBMoves::POWERTRICK)
          when PBEffects::Rage           then ret[i][count.to_s] = PBMoves.getName(PBMoves::RAGE)
          when PBEffects::Rollout        then ret[i][count.to_s] = _INTL("{1} ({2})",PBMoves.getName(PBMoves::ROLLOUT),effect.to_s) if effect != 0 
          when PBEffects::SmackDown      then ret[i][count.to_s] = PBMoves.getName(PBMoves::SMACKDOWN)
          when PBEffects::Stockpile      then ret[i][count.to_s] = _INTL("{1} ({2})",PBMoves.getName(PBMoves::STOCKPILE),effect.to_s) if effect != 0
          when PBEffects::Taunt          then ret[i][count.to_s] = PBMoves.getName(PBMoves::TAUNT) if effect != 0
          when PBEffects::Telekinesis    then ret[i][count.to_s] = PBMoves.getName(PBMoves::TELEKINESIS) if effect != 0
          when PBEffects::Transform      then ret[i][count.to_s] = PBMoves.getName(PBMoves::TRANSFORM)
          when PBEffects::Unburden       then ret[i][count.to_s] = PBMoves.getName(PBMoves::UNBURDEN)
          when PBEffects::Uproar         then ret[i][count.to_s] = PBMoves.getName(PBMoves::UPROAR) if effect != 0
          when PBEffects::WeightChange   then ret[i][count.to_s] = _INTL("Peso reducido") if effect != 0
          when PBEffects::Yawn           then ret[i][count.to_s] = _INTL("Somnoliento") if effect != 0
          when PBEffects::LaserFocus     then ret[i][count.to_s] = PBMoves.getName(PBMoves::LASERFOCUS) if effect != 0
          when PBEffects::ThroatChop     then ret[i][count.to_s] = _INTL("Silenciado") if effect != 0
          when PBEffects::TarShot        then ret[i][count.to_s] = PBMoves.getName(PBMoves::TARSHOT)
          when PBEffects::Metronome      then ret[i][count.to_s] = _INTL("{1} ({2})",PBItems.getName(getID(PBItems,:METRONOME)),effect.to_s) if effect != 0
          when PBEffects::RageFist       then ret[i][count.to_s] = _INTL("{1} ({2})",PBMoves.getName(PBMoves::RAGEFIST),effect.to_s) if effect != 0
          when PBEffects::Commander      then ret[i][count.to_s] = PBAbilities.getName(PBAbilities::COMMANDER) if effect != 0
          when PBEffects::GlaiveRush     then ret[i][count.to_s] = _INTL("Vulnerable")
          when PBEffects::SaltCure       then ret[i][count.to_s] = PBMoves.getName(PBMoves::SALTCURE)
          when PBEffects::SyrupBomb      then ret[i][count.to_s] = _INTL("Caramelizado ({1})",effect.to_s) if effect != 0
          when PBEffects::Protosynthesis then ret[i][count.to_s] = _INTL("Potenciado") if effect != 0
        end
      end
			}
    rescue;end
		}
		return ret
	end

end