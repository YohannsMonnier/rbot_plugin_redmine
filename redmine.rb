# :title: Authentified Webservice Client for Redmine
#
# Author:: Yohann MONNIER - Internethic
#
# Version:: 0.0.2
#
# License:: MIT license

require 'xmlrpc/client'
require "net/https"
require 'openssl'
require 'pp'

class RedminePlugin < Plugin

  Redminelogger = Struct.new('Redminelogger', :task, :time, :for, :inprogress, :projectname, :taskname, :alreadydone)
  RedmineAuth = Struct.new('RedmineAuth', :nickname, :username, :password)
  
  # initialize configuration
  def initialize
  	super
  	
  	###############
  	##  SETTINGS ##
    ###############
    # These five variables are the only you need to set.
    @redmine_url_prefixe = "https://"
    @redmine_url_suffixe = "projets/"
    @redmine_webservice_user = "admin"
    @redmine_webservice_pass = "admin"

    # Other variables - should not be changed
    @redmine_webservice_path =  "redmine_webservice/api"
    @redmine_issue_show_path = "issues/show"
    @redmine_project_show_path = "projects/show"
    @redmine_rapid_url = @redmine_url_prefixe + @redmine_url_suffixe
    @redmine_counter_hour_limit = 12
    @redmine_debug_mode = 0


  end
  
  # Display the known redmine adress
  def redmine_address(m, params)
  	 begin	
  	 	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			m.reply @redmine_rapid_url
			callparameters  	= {
									:method => "Information.GetVersion",
									:args => ""
								}
			# call of the Info.check_credentials
			redmine_call(m, callparameters)
    	end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end	
  end
 
  # Check authentification in Redmine in order to authentify User in Redmine Bot system
  def redmine_connect(m, params)
  	begin
  		methodparameters	= {
  								:arg0 => params[:user],
 								:arg1 => params[:password]
  							}
 		callparameters  	= {
 							  	:method => "Information.CheckCredentials",
 							  	:args => methodparameters
							}
    	#---- call of the Info.check_credentials
    	result = redmine_call(m, callparameters)
    	# Si le couple user/password est ok
    	#m.reply result
    	#pp result
    	if result.to_s == "true"
    		#on teste si il est déjà authentifié ou non
    		if ! @registry["#{m.sourcenick}_auth"]
				authtostore = @registry["#{m.sourcenick}_auth"] || Array.new	
				authtostore.push RedmineAuth.new(m.sourcenick, params[:user], params[:password])
				@registry["#{m.sourcenick}_auth"] = authtostore
					
    			m.reply "Bienvenue #{params[:user]} !"
    		else
    			authstored = @registry["#{m.sourcenick}_auth"]
    			m.reply "Désolé #{m.sourcenick}, Vous êtes déjà authentifié en tant que #{authstored[0].username} !"
    		end
    	# Si le couple user/password ne fonctionne pas
    	else
    		m.reply "Redmine ne vous connais pas !"
    	end
    	
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end	
  end


  # Check the module authentification
  def redmine_disconnect(m, params)
  	begin
  		certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			m.reply "Aurevoir #{certificate[:username]}."
			@registry.delete "#{m.sourcenick}_auth"
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end	
  end
  
  # Check the module authentification
  def redmine_check_auth(m)
  	begin
		if ! @registry["#{m.sourcenick}_auth"]
			m.reply "Bonjour #{m.sourcenick}, veuillez vous authentifier pour accéder à cette fonctionnalité."
			return false
		else
			authstored = @registry["#{m.sourcenick}_auth"]
			certificate = {:username => authstored[0].username, :password => authstored[0].password}
			return certificate
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end	
  end
	
  # Display the known redmine users
  def redmine_users(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			if m.source.botuser.owner?
				m.reply "#{Underline}En ce moment, " + m.sourcenick + ", les utilisateurs connectés sont:#{Underline}"
				
				@registry.keys.each do |key_data|
					# utilisateurs connectés
					if key_data.include? "_auth"
						# recuperons les données de l'utilisateur
						authstored = @registry[key_data]
						nickname = key_data.gsub('_auth', '')
						# on affiche le nom de l'utilisateur
						m.reply "#{Bold}#{nickname} as #{authstored[0].username}#{Bold}"

						if @registry.has_key? authstored[0].username
							@registry[authstored[0].username].each do |task_logger|
								if (task_logger.inprogress == "pause")
									# preparation du paramètre durée de tache
									gap = task_logger.alreadydone.to_i
									hours = gap/3600.to_i
									mins = ( gap/60 % 60 ).to_i
									secs = ( gap % 60 )
									real_hours = ( task_logger.alreadydone )/3600
									pause_message = "[en pause]"
								else
									gap = ( Time.now - task_logger.time ).to_i + task_logger.alreadydone.to_i
									hours = gap/3600.to_i
									mins = ( gap/60 % 60 ).to_i
									secs = ( gap % 60 )
									real_hours = ( Time.now - task_logger.time )/3600
									pause_message = "[en cours]"
								end
								m.reply "Task ##{task_logger.task}#{pause_message} (#{hours}h #{mins}m #{secs}s) : [#{task_logger.projectname}] #{task_logger.taskname}(!!) => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{task_logger.task}"
							end
						else
							#@bot.say nickname , "#{Bold}#{nickname}#{Bold}, Tu n'as démarré aucune tâche en ce moment ? Lance le compteur ;) (aide ? => type 'help redmine start')"
							m.reply "Aucune tâche en cours"
						end
					end
				end
			else
				m.reply "Tu ne dispose pas des droits nécessaires"
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end
  
  # Alert the known redmine users if they have no tasks
  def alert_redmine_users(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			if m.source.botuser.owner?
				m.reply "#{Underline}En ce moment, " + m.sourcenick + ", les utilisateurs qui n'ont pas lancé de compteur sont:#{Underline}"

				@registry.keys.each do |key_data|
					# utilisateurs connectés
					if key_data.include? "_auth"
						# recuperons les données de l'utilisateur
						authstored = @registry[key_data]
						nickname = key_data.gsub('_auth', '')
					
						# Si l'utilisateur n'a pas de taches, on lui indique par message
						if ! @registry.has_key? authstored[0].username
							# on affiche le nom de l'utilisateur pour l'administrateur
							m.reply "#{Bold}#{nickname} as #{authstored[0].username}#{Bold} - Aucune tâche en cours"
							# on envoie le message à l'utilisateur
							@bot.say nickname , "#{Bold}#{nickname}#{Bold}, Tu n'as démarré aucune tâche en ce moment ? Lance le compteur ;) (aide ? => help redmine start)"
						end
					end
				end
			else
				m.reply "Tu ne dispose pas des droits nécessaires"
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end
  
  # Display the known redmine users
  def redmine_my_tasks(m, params)
  	begin
		certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			methodparameters	= {
								:arg0 => certificate[:username]
							}
			changedparameters = {
								  :method => "Ticket.FindIssueForUser",
								  :args => methodparameters
								}
			# call of the Issue.FindIssueForUser method
			redmine_call(m, changedparameters)
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end	
  end
  
  # Display the known redmine users by project
  def redmine_my_tasks_by_project(m, params)
  	begin
		certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			methodparameters	= {
								:arg0 => params[:id_project],
								:arg1 => certificate[:username]
							}
			changedparameters = {
								  :method => "Ticket.FindIssueForUserByProject",
								  :args => methodparameters
								}
			# call of the Issue.FindIssueForUserByProject method
			redmine_call(m, changedparameters)
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end	
  end
  
 
   # Display the known pending redmine tasks for this user
  def redmine_tasks(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			m.reply "En ce moment, la tâche en cours de #{certificate[:username]} est :"
			if @registry.has_key? certificate[:username]
				task_detected = false
				@registry[certificate[:username]].each do |task_logger|
					task_detected = true
						if (task_logger.inprogress == "pause")
							# preparation du paramètre durée de tache
							gap = task_logger.alreadydone.to_i
							hours = gap/3600.to_i
							mins = ( gap/60 % 60 ).to_i
							secs = ( gap % 60 )
							real_hours = ( task_logger.alreadydone )/3600
							pause_message = "[en pause]"
						else
							gap = ( Time.now - task_logger.time ).to_i + task_logger.alreadydone.to_i
							hours = gap/3600.to_i
							mins = ( gap/60 % 60 ).to_i
							secs = ( gap % 60 )
							real_hours = ( Time.now - task_logger.time )/3600
							pause_message = "[en cours]"
						end
					
					m.reply "Task ##{task_logger.task}#{pause_message} (#{hours}h #{mins}m #{secs}s) : [#{task_logger.projectname}] #{task_logger.taskname} => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{task_logger.task}"
				end
				if !task_detected
					if @redmine_debug_mode == 1
						m.reply "Aucune tâche en cours"
					end
				end
				
			else
				#if @redmine_debug_mode == 1
					m.reply "Aucune tâche en cours"
				#end
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end
  
   # Call a method in the redmine webservice
  def redmine_call(m, params)
  
  	#########################################
	## Initialisation of the XMLRPC client ##
	#########################################
	@redmineserver = XMLRPC::Client.new2( "#{@redmine_url_prefixe}#{@redmine_webservice_user}:#{@redmine_webservice_pass}@#{@redmine_url_suffixe}#{@redmine_webservice_path}" )
    @redmineserver.instance_variable_get(:@http).instance_variable_set(:@verify_mode, OpenSSL::SSL::VERIFY_NONE)
    
  	# recuperation des parametres
  	methods = params[:method]
			
	#Initialisation de tous les paramètres
	arg0 = ""
	arg1 = ""
	arg2 = ""
	arg3 = ""	
	arg4 = ""
	
     if ! params[:args].nil?
     	if ! params[:args][:arg0].nil?
     		arg0  = params[:args][:arg0]
     	end
     	if ! params[:args][:arg1].nil?
     		arg1  = params[:args][:arg1]
     	end
     	if ! params[:args][:arg2].nil?
     		arg2  = params[:args][:arg2]
     	end
     	if ! params[:args][:arg3].nil?
     		arg3  = params[:args][:arg3]
     	end
     	if ! params[:args][:arg4].nil?
     		arg4  = params[:args][:arg4]
     	end
     end
    
	if params[:debug] == "true"
		# liste des parametres
     	pp params[:args]
		m.reply "arg0 : [#{arg0}], arg1 : [#{arg1}], arg2 : [#{arg2}], arg3 : [#{arg3}], arg4 : [#{arg4}]." 
	end
		
	begin
		# appel à la méthode passée en paramètre
		result = @redmineserver.call( methods , arg0, arg1, arg2, arg3, arg4 )
	rescue Exception => e  
			m.reply e.message  
			m.reply "Nom methode: '" + methods + "'"
		if params[:debug] == "true"
			m.reply e.backtrace.inspect
		end 
	end

	# réponse selon méthodes
	if defined?result 
		case  methods
			when "Project.FindAll"
				for project in result
					# give project name
					m.reply "* " + project['name'] + ", " + project['identifier']
					m.reply "* * #{@redmine_rapid_url}#{@redmine_project_show_path}/" + project['identifier']
				end
				pp project
			when "Ticket.FindIssueForUser"
				for issue in result
					# display issue information
					m.reply "Task ##{issue['id']} : [#{issue['project_name']}] #{issue['subject']} (#{issue['priority']}) => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{issue['id']}"
					pp issue
				end
			when "Ticket.FindIssueForUserByProject"
				for issue in result
					# display issue information
					m.reply "Task ##{issue['id']} : [#{issue['project_name']}] #{issue['subject']} (#{issue['priority']} - #{issue['priority_id']}) => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{issue['id']}"
					pp issue
				end
			when "Information.CheckCredentials"
					return result
					# display auth result
					#m.reply "result is [#{result}]"
			when "Information.GetVersion"
					# display auth result
					m.reply "Versions => Redmine[#{result[0]}], Ruby[#{result[1]}], RedmineServices[#{result[2]}], Temps limite compteur[#{@redmine_counter_hour_limit}h]"
					true
			when "Ticket.FindTicketById"
					# display task result
					if @redmine_debug_mode == 1
						m.reply "La tâche #{result['id']} existe dans Redmine"
					end
					return result
			else
					#m.reply "No method to display this result"
					return result
		end
	else
		m.reply "No results..."
	end
	
	# Fin du message
	m.reply "---------------" 

  end


 # check if the task given in parameter exists
  def redmine_check_task(m, params)
    begin
		methodparameters	= {
							:arg0 => params[:task]
						}
		parameters = {
				  :method => "Ticket.FindTicketById",
				  :args => methodparameters
				}
    	# call of the Issue.FindTicketById method
    	result = redmine_call(m, parameters)
    	
    	if result.nil?
    		return false
    	else 
    		return result
    	end
    	
    rescue Exception => e
      m.reply "error: #{e.message}"
    end
  end
  

  # Count time start
  def redmine_counter_start(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			if  @registry[certificate[:username]]
				m.reply "Vous avez déjà une tache en cours #{certificate[:username]}."
			else
				resulted_task = redmine_check_task(m, params)
				if resulted_task
					tasktostore = Array.new
					tasktostore.push Redminelogger.new(params[:task], Time.now, certificate[:username], "true", resulted_task['project_name'], resulted_task['subject'], 0 )
					@registry[certificate[:username]] = tasktostore
					m.reply "#{certificate[:username]} commence la tâche ##{params[:task]} [#{resulted_task['project_name']}][#{Bold}#{resulted_task['subject']}#{Bold}] à #{Time.now.strftime('%H:%M')} => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{params[:task]}"
				else
					m.reply "La tâche #{params[:task]} n'existe pas dans Redmine"
				end
			end
      	end
    rescue Exception => e
      m.reply "error: #{e.message}"
    end
  end

  # Fonction qui force l'arret d'une tache d'un développeur
  def redmine_force_stop(m, params)
  	if m.source.botuser.owner?
		redmine_counter_stop(m, params)
  	else
		m.reply "Tu ne dispose pas des droits nécessaires"
  	end
  end

  # Count time stop
  def redmine_counter_stop(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			time_entry_added = false
			counter_time_limit = false	
			if params[:othername]
				user_login = params[:othername]
			else
				user_login = certificate[:username]
			end
			if @registry.has_key? user_login
				task_counter = []
				@registry[user_login].each do |task_logger|
						# preparation du paramètre durée de tache
						if (task_logger.inprogress == "pause")
							# preparation du paramètre durée de tache
							gap = task_logger.alreadydone.to_i
							hours = gap/3600.to_i
							mins = ( gap/60 % 60 ).to_i
							secs = ( gap % 60 )
							real_hours = ( task_logger.alreadydone )/3600
						else
							gap = ( Time.now - task_logger.time ).to_i + task_logger.alreadydone.to_i
							gapreal = ( ( Time.now - task_logger.time ) + task_logger.alreadydone )
							hours = gap/3600.to_i
							mins = ( gap/60 % 60 ).to_i
							secs = ( gap % 60 )
							real_hours = gapreal/3600
						end
						
						# on met à jour le champ params avant de s'en servir
						params[:task] = task_logger.task
						params[:username] = user_login
						params[:spent_time] = real_hours
						# if counter time limit has been reached, it is erased and not save in redmine 
						if (gap < @redmine_counter_hour_limit*3600)

							# appel à la méthode du webservice pour l'ajout de temps pour une tache
							time_entry_added = redmine_add_time_entry(m, params)
							if time_entry_added
								# affichage d'un message
								counter_message = "La tâche ##{task_logger.task}[#{task_logger.time.strftime('%H:%M')}]; a duré  #{hours}h #{mins}min et #{secs} secondes => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{params[:task]}"
								task_counter.push counter_message
							else
								counter_message = "La tâche ##{task_logger.task} n'a pas été mise à jour, le compteur n'a pas été stoppé (problème lors de l'enregistrement)"
							end
						else
							counter_time_limit = true
							counter_message = "#{Bold}La tâche ##{task_logger.task}[débutée le #{task_logger.time.strftime('%d/%m/%Y à %H:%M')}] n'a pas été mise à jour car le compteur a dépassé #{@redmine_counter_hour_limit} heures (#{hours}h #{mins}min et #{secs} secs).#{Bold} Le compteur a été supprimé, si vous voulez quand même enregistrer ce temps, faites le dans redmine : #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{params[:task]}"
							task_counter.push counter_message
						end
				end
				if ( !task_counter.empty? and ( time_entry_added or counter_time_limit ) )
					# on indique à l'utilisateur
					@bot.say m.replyto, "#{user_login},  " +
					  task_counter.join(' ')
					# on enregistre les temps dans Redmine données dans Redmine
					# --------------------------------------------
					# on efface la tache enregistrée
					@registry.delete user_login
				elsif (task_counter.empty?)
					if @redmine_debug_mode == 1
						m.reply "Aucune Tâche en cours"
					end
				end
			else
				if @redmine_debug_mode == 1
					m.reply "Aucune Tâche en cours"
				end				
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end
  
  # Fonction qui stoppe la tache en cours et ouvre la nouvelle
  def redmine_start_stop(m, params)
  	  redmine_counter_stop(m, params)
  	  params[:task] = params[:task_to_start]
  	  redmine_counter_start(m, params)
  end
  
  # Count time pause/play
  def redmine_pause(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			if  @registry.has_key? certificate[:username]
				#m.reply "Vous avez une tache en cours #{certificate[:username]}."
				
				@registry[certificate[:username]].each do |task_logger|
					if ( task_logger.inprogress == "true" )
							# preparation du paramètre durée de tache
							gap = ( Time.now - task_logger.time ).to_i
							hours = gap/3600.to_i
							mins = ( gap/60 % 60 ).to_i
							# enregistrement du temps déjà consommé
							task_logger.alreadydone = task_logger.alreadydone + gap
							gap_total = task_logger.alreadydone.to_i
							hours = gap_total/3600.to_i
							mins = ( gap_total/60 % 60 ).to_i
							secs = ( gap_total % 60 )
							# mise en pause de la tache
							task_logger.inprogress = "pause"
							# enregistrement de l'état de la tâche
							@registry[certificate[:username]] = task_logger
							# enregistrement de l'état de la tâche
							tasktostore = Array.new
							tasktostore.push task_logger
							@registry[certificate[:username]] = tasktostore
							# affichage d'un message
							m.reply "Mise en pause de la tâche ##{task_logger.task}, commencée à #{task_logger.time.strftime('%H:%M')}, Temps total : #{hours}h #{mins}min #{secs}s, en cours => #{task_logger.inprogress}"
					else 
							#reprise de la tache
							task_logger.inprogress = "true"
							task_logger.time = Time.now
							# calcul du temps déjà consommé
							gap = task_logger.alreadydone.to_i
							hours = gap/3600.to_i
							mins = ( gap/60 % 60 ).to_i
							secs = ( gap % 60 )
							# enregistrement de l'état de la tâche
							tasktostore = Array.new
							tasktostore.push task_logger
							@registry[certificate[:username]] = tasktostore
							# affichage d'un message
							m.reply "Reprise de la tâche ##{task_logger.task} à #{task_logger.time.strftime('%H:%M')}, Temps total : #{hours}h #{mins}min #{secs}s"
							
					end
				end
			else
				m.reply "#{certificate[:username]}: Vous n'avez pas de tâches en cours."
			end
      	end
    rescue Exception => e
      m.reply "error: #{e.message}"
    end
  end


  # Fonction qui force la suppression d'une tache d'un développeur
  def redmine_force_delete(m, params)
  	if m.source.botuser.owner?
		redmine_counter_delete(m, params)
  	else
		m.reply "Tu ne dispose pas des droits nécessaires"
  	end
  end
  
  # Delete Logged Time for a task
  def redmine_counter_delete(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			if params[:othername]
				user_login = params[:othername]
			else
				user_login = certificate[:username]
			end
			if @registry.has_key? user_login
				# j'affiche un message listant tous les temps effacés
				@registry[user_login].each do |task_logger|
						if (task_logger.inprogress == "pause")
							# preparation du paramètre durée de tache
							gap = task_logger.alreadydone.to_i
							hours = gap/3600.to_i
							mins = ( gap/60 % 60 ).to_i
							secs = ( gap % 60 )
							real_hours = ( task_logger.alreadydone )/3600
						else
							gap = ( Time.now - task_logger.time ).to_i + task_logger.alreadydone.to_i
							hours = gap/3600.to_i
							mins = ( gap/60 % 60 ).to_i
							secs = ( gap % 60 )
							real_hours = ( Time.now - task_logger.time )/3600
						end
						# affichage d'un message
						m.reply "Les temps enregistrés pour la tâche ##{task_logger.task}[#{task_logger.time.strftime('%H:%M')}]; étaient :  #{hours}h #{mins}min et #{secs} secondes soit #{real_hours}h (décimal)"
				end
				# on indique à l'utilisateur
				@bot.say m.replyto, "#{certificate[:username]},  je viens d'effacer ces heures, n'oublis pas de reporter les heures effectuées. Tape 'help redmine addtime'."
				# on efface la tache enregistrée
				@registry.delete user_login
			else
				m.reply "Aucune Tâche en cours"
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end
  
  # Add time entry to a task
  def redmine_add_time(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			resulted_task = redmine_check_task(m, params)
			if resulted_task
				# on met à jour le champ params avant de l'employer
				params[:username] = certificate[:username]
				params[:spent_time] = params[:hours]
				# appel à la méthode du webservice pour l'ajout de temps pour une tache
				redmine_add_time_entry(m, params)
				
				# on indique à l'utilisateur
				@bot.say m.replyto, "#{certificate[:username]},  la tâche #{resulted_task['id']} a été mise à jour=> #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{resulted_task['id']}"
			else
				m.reply "La tâche #{params[:task]} n'existe pas dans Redmine"
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end
  
  # Add time entry to a task
  def redmine_add_comment(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			resulted_task = redmine_check_task(m, params)
			if resulted_task
				# on met à jour le champ params avant de l'employer
				params[:username] = certificate[:username]
				messageEntry = params[:message].to_s.strip
				methodparameters	= {
									:arg0 => params[:task],
									:arg1 => params[:username],
									:arg3 => messageEntry
								}
				parameters = {
						  :method => "Ticket.AddCommentForTicket",
						  :args => methodparameters
						}
				# call of the Ticket.AddCommentForTicket method
				result = redmine_call(m, parameters)
				
				if result.nil?
					# on indique à l'utilisateur
					@bot.say m.replyto, "#{certificate[:username]},  la tâche #{resulted_task['id']} n'a pas été mise à jour (problèmes lors de l'enregistrement)"
				else 
					# on indique à l'utilisateur
					@bot.say m.replyto, "#{certificate[:username]},  la tâche #{resulted_task['id']} a été mise à jour=> #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{resulted_task['id']}"
				end
			else
				m.reply "La tâche #{params[:task]} n'existe pas dans Redmine"
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end
  
  # add a time entry on redmine task
  def redmine_add_time_entry(m, params)
    begin
    
    	#Initialisation des paramètres
    	if params[:message]
    		messageEntry = params[:message].to_s.strip
    	else
    		messageEntry =  "Mis à jour par Webservice"
    	end 
    	if ( messageEntry == "Mis à jour par Webservice" )
    		params[:make_a_comment] = 0
    	else
    		params[:make_a_comment] = 1
    	end
    	
		methodparameters	= {
							:arg0 => params[:task],
							:arg1 => params[:username],
							:arg2 => params[:spent_time],
							:arg3 => messageEntry,
							:arg4 => params[:make_a_comment]
						}
		parameters = {
				  :method => "Ticket.AddTimeEntryForTicket",
				  :args => methodparameters
				}
    	# call of the Ticket.AddTimeEntryForTicket method
    	result = redmine_call(m, parameters)
    	
    	if result.nil?
    		return false
    	else 
    		return true
    	end
    	
    rescue Exception => e
      m.reply "error: #{e.message}"
    end
  end
  
  # Kick a user if is logged, destructing launched counters
  def redmine_kick(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			if m.source.botuser.owner?
				redmine_username = ""
				if @registry.has_key? "#{params[:username]}_auth"
				
					#je sauvegarde l'utilisateur redmine de cet utilisateur authentifié
					redmine_username = @registry["#{params[:username]}_auth"][0].username
					# on efface la tache enregistrée
					@registry.delete "#{params[:username]}_auth"
					# on informe l'utilisateur
					@bot.say m.replyto, "Utilisateur #{Bold}#{params[:username]}#{Bold} supprimé"
				else
					@bot.say m.replyto, "Je n'ai aucune donnée sur cet utilisateur"
				end
				if ! redmine_username.empty?
					if @registry.has_key? redmine_username
						# j'affiche un message listant tous les temps effacés
						@registry[redmine_username].each do |task_logger|
							if (task_logger.inprogress == "pause")
								# preparation du paramètre durée de tache
								gap = task_logger.alreadydone.to_i
								hours = gap/3600.to_i
								mins = ( gap/60 % 60 ).to_i
								secs = ( gap % 60 )
								real_hours = ( task_logger.alreadydone )/3600
							else
								gap = ( Time.now - task_logger.time ).to_i  + task_logger.alreadydone.to_i
								hours = gap/3600.to_i
								mins = ( gap/60 % 60 ).to_i
								secs = ( gap % 60 )
								real_hours = ( Time.now - task_logger.time + task_logger.alreadydone)/3600
							end
								# affichage d'un message
								m.reply "Les temps enregistrés pour la tâche ##{task_logger.task}[#{task_logger.time.strftime('%H:%M')}]; étaient :  #{hours}h #{mins}min et #{secs} secondes soit #{real_hours}h (décimal)"
						end
						# on indique à l'utilisateur
						@bot.say m.replyto, "-> Tâche éffacée"
						# on efface la tache enregistrée
						@registry.delete redmine_username

					end
				end
			else 
				m.reply "Tu ne dispose pas des droits nécessaires"
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end
  
  def help(plugin, topic="")
  case topic
    when "address"
    	"redmine address => Donne l'adresse du serveur Redmine, les versions de Redmine, Ruby et de Redmine Connector"
    when "connect"
    	"connect <username> <password> => valide puis associe le couple 'nom d'utilisateur/mot de passe' avec le nom irc de l'utilisateur"
	when "disconnect"
    	"disconnect => désassocie le couple 'nom d'utilisateur/mot de passe' du nom irc de l'utilisateur" 
    when "start"
    	"start <id_task> *<message> => Ferme la tache en cours avec le message optionnel en commentaire, puis Vérifie si la tâche existe, et lance le compteur personnel"
    when "stop"
    	"stop <message> => Vérifie si une tâche est lancée, puis stoppe le compteur et enregistre le temps et le message dans Redmine"
    when "addtime"
    	"addtime <id_task> <hours> *<message> => Vérifie si la tâche existe, puis enregistre les heures dans Redmine. Le message n'est pas obligatoire."
    when "comment"
    	"comment <id_task> <message> => Vérifie si la tâche existe, puis ajoute un commentaire pour la tâche dans Redmine"
    when "delete"
    	"delete <id_tasks> => supprime le compteur actuel pour la tâche sans publier les heures dans Redmine"
    when "tasks"
    	"tasks => Affiche la tâche en cours (compteur lancé)"
	when "redmine tasks"
		"redmine tasks => Liste les tâches ouvertes qui vous sont assignées dans Redmine"
    else
    	"type 'help redmine adress|connect|disconnect|start|stop|addtime|comment|tasks' to have further informations"
    end
  end
  
  # Fonction de test
  def redmine_test(m, params)
  	# Raccourci pour appel de fonction non configuré

  end
  
   # Fonction cachée 42 pour délirer
  def answer_forty_two(m, params)
  	# Raccourci pour appel de fonction non configuré
	@bot.say m.replyto, "the answer to life the universe and everything ?"
	@bot.say m.replyto, "..."
	@bot.say m.replyto, "..."
	@bot.say m.replyto, "..."
	@bot.say m.replyto, " = 42 !"
  end 
  

end

plugin = RedminePlugin.new


  
plugin.map 'redmine address',
  :action => 'redmine_address'
plugin.map 'address',
  :action => 'redmine_address'
  
plugin.map 'redmine connect :user :password',
  :action => 'redmine_connect'
plugin.map 'connect :user :password',
  :action => 'redmine_connect'
   
plugin.map 'redmine disconnect',
  :action => 'redmine_disconnect'
plugin.map 'disconnect',
  :action => 'redmine_disconnect'
  
plugin.map 'redmine users',
  :action => 'redmine_users'
plugin.map 'users',
  :action => 'redmine_users'
  
plugin.map 'alert users',
  :action => 'alert_redmine_users'
  

plugin.map 'redmine tasks',
  :action => 'redmine_my_tasks'


plugin.map 'redmine my tasks',
  :action => 'redmine_my_tasks'
plugin.map 'my tasks',
  :action => 'redmine_my_tasks'
  
plugin.map 'redmine tasks :id_project',
  :action => 'redmine_my_tasks_by_project'
  
plugin.map 'tasks',
  :action => 'redmine_tasks'
  
plugin.map 'redmine call :method *debug',
  :action => 'redmine_call'
plugin.map 'call :method *debug',
  :action => 'redmine_call'
  
plugin.map 'redmine start :task_to_start *message',
  :action => 'redmine_start_stop',
  :defaults => {:message => "Mis à jour par Webservice"}
plugin.map 'start :task_to_start *message',
  :action => 'redmine_start_stop',
  :defaults => {:message => "Mis à jour par Webservice"}
  
plugin.map 'pause',
  :action => 'redmine_pause'
plugin.map 'clope',
  :action => 'redmine_pause'
  
plugin.map 'redmine stop *message',
  :action => 'redmine_counter_stop',
  :defaults => {:message => "Mis à jour par Webservice"}
plugin.map 'stop *message',
  :action => 'redmine_counter_stop',
  :defaults => {:message => "Mis à jour par Webservice"}
  
plugin.map 'force stop :othername *message',
  :action => 'redmine_force_stop',
  :defaults => {:message => "Mis à jour par Webservice"} 

plugin.map 'redmine addtime :task :hours *message',
  :action => 'redmine_add_time',
  :defaults => {:message => "Mis à jour par Webservice"}
plugin.map 'addtime :task :hours *message',
  :action => 'redmine_add_time',
  :defaults => {:message => "Mis à jour par Webservice"}
  
plugin.map 'redmine comment :task *message',
  :action => 'redmine_add_comment'
plugin.map 'comment :task *message',
  :action => 'redmine_add_comment'

plugin.map 'redmine delete',
  :action => 'redmine_counter_delete'
plugin.map 'delete',
  :action => 'redmine_counter_delete'
  
plugin.map 'force delete :othername',
  :action => 'redmine_force_delete'

plugin.map 'redmine kill :username',
  :action => 'redmine_kick'
plugin.map 'kill :username',
  :action => 'redmine_kick'
  
plugin.map 'the answer to life the universe and everything',
  :action => 'answer_forty_two'
