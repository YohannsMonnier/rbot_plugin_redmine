# :title: Authentified Webservice Client for Redmine
#
# Author:: Yohann MONNIER - Internethic
#
# Version:: 0.0.1
#
# License:: MIT license

#require 'rss'

require 'xmlrpc/client'
require "net/https"
require 'openssl'
require 'pp'

class RedminePlugin < Plugin

  Redminelogger = Struct.new('Redminelogger', :task, :time, :for, :inprogress, :projectname, :taskname)
  RedmineAuth = Struct.new('RedmineAuth', :nickname, :username, :password)
  
  # initialize configuration
  def initialize
  	super
  	
  	
  	###############
  	##  SETTINGS ##
    ###############
    # These five variables are the only you need to set.
    @redmine_url_prefixe = "http://"
    @redmine_url_suffixe = "redmine/"
    @redmine_webservice_user = "admin"
    @redmine_webservice_pass = "admin"


    # Other variables - should not be changed
    @redmine_webservice_path =  "redmine_webservice/api"
    @redmine_issue_show_path = "issues/show"
    @redmine_project_show_path = "projects/show"
    @redmine_rapid_url = @redmine_url_prefixe + @redmine_url_suffixe
    
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
								gap = (Time.now - task_logger.time).to_i
								hours = gap/3600.to_i
								mins = (gap/60 % 60).to_i
								secs = (gap % 60)

								m.reply "Task ##{task_logger.task} (#{hours}h #{mins}m #{secs}s) : [#{task_logger.projectname}] #{task_logger.taskname}(!!) => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{task_logger.task}"
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
			m.reply "Today #{certificate[:username]}'s tasks in progress :"
			if @registry.has_key? certificate[:username]
				task_detected = false
				@registry[certificate[:username]].each do |task_logger|
					task_detected = true
					gap = (Time.now - task_logger.time).to_i
					hours = gap/3600.to_i
					mins = (gap/60 % 60).to_i
					secs = (gap % 60)
					
					m.reply "Task ##{task_logger.task} (#{hours}h #{mins}m #{secs}s) : [#{task_logger.projectname}] #{task_logger.taskname} => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{task_logger.task}"
				end
				if !task_detected
					m.reply "sorry I dont know"
				end
				
			else
				m.reply "sorry I dont know"
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
     end
	if params[:debug] == "true"
		# liste des parametres
     	pp params[:args]
		m.reply "arg0 : [#{arg0}], arg1 : [#{arg1}], arg2 : [#{arg2}], arg3 : [#{arg3}]."  
	end
		
	begin
		# appel à la méthode passée en paramètre
		result = @redmineserver.call( methods , arg0, arg1, arg2, arg3 )
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
					m.reply "Versions => Redmine[#{result[0]}], Ruby[#{result[1]}], RedmineServices[#{result[2]}]"
					true
			when "Ticket.FindTicketById"
					# display task result
					m.reply "La tâche #{result['id']} existe dans Redmine"
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
					tasktostore.push Redminelogger.new(params[:task], Time.now, certificate[:username], "true", resulted_task['project_name'], resulted_task['subject'] )
					@registry[certificate[:username]] = tasktostore
					m.reply "#{certificate[:username]} commence la tâche ##{params[:task]} à #{Time.now.strftime('%H:%M')} => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{params[:task]}"
				else
					m.reply "La tâche #{params[:task]} n'existe pas dans Redmine"
				end
			end
      	end
    rescue Exception => e
      m.reply "error: #{e.message}"
    end
  end

  # Count time stop
  def redmine_counter_stop(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
				
			if @registry.has_key? certificate[:username]
				task_counter = []
				@registry[certificate[:username]].each do |task_logger|
						# preparation du paramètre durée de tache
						gap = ( Time.now - task_logger.time ).to_i
						hours = gap/3600.to_i
						mins = ( gap/60 % 60 ).to_i
						secs = ( gap % 60 )
						real_hours = ( Time.now - task_logger.time )/3600
						# on met à jour le champ params avant de l'employer
						params[:task] = task_logger.task
						params[:username] = certificate[:username]
						params[:spent_time] = real_hours
						# appel à la méthode du webservice pour l'ajout de temps pour une tache
						time_entry_added = redmine_add_time_entry(m, params)
						if time_entry_added
							# affichage d'un message
							counter_message = "La tâche ##{task_logger.task}[#{task_logger.time.strftime('%H:%M')}]; a duré  #{hours}h #{mins}min et #{secs} secondes => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{params[:task]}"
							task_counter.push counter_message
						else
							counter_message = "La tâche ##{task_logger.task} n'a pas été mise à jour, le compteur n'a pas été stoppé (problème lors de l'enregistrement)"
						end
				end
				if (!task_counter.empty? and time_entry_added)
					# on indique à l'utilisateur
					@bot.say m.replyto, "#{certificate[:username]},  " +
					  task_counter.join(' ')
					# on enregistre les temps dans Redmine données dans Redmine
					# --------------------------------------------
					# on efface la tache enregistrée
					@registry.delete certificate[:username]
				elsif (task_counter.empty?)
					m.reply "Aucune Tâche en cours"
				end
			else
				m.reply "Aucune Tâche en cours"
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end

  # Delete Logged Time for a task
  def redmine_counter_delete(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			if @registry.has_key? certificate[:username]
				# j'affiche un message listant tous les temps effacés
				@registry[certificate[:username]].each do |task_logger|
					if task_logger.task == params[:task]
						gap = ( Time.now - task_logger.time ).to_i
						hours = gap/3600.to_i
						mins = ( gap/60 % 60 ).to_i
						secs = ( gap % 60 )
						real_hours = ( Time.now - task_logger.time )/3600
						# affichage d'un message
						m.reply "Les temps enregistrés pour la tâche ##{task_logger.task}[#{task_logger.time.strftime('%H:%M')}]; étaient :  #{hours}h #{mins}min et #{secs} secondes soit #{real_hours}h (décimal)"
					end
				end
				# on indique à l'utilisateur
				@bot.say m.replyto, "#{certificate[:username]},  je viens d'effacer ces heures, n'oublis pas de reporter les heures effectuées. Tape 'help redmine addtime'."
				# on efface la tache enregistrée
				@registry.delete certificate[:username]
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
		methodparameters	= {
							:arg0 => params[:task],
							:arg1 => params[:username],
							:arg2 => params[:spent_time],
							:arg3 => messageEntry
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
								gap = ( Time.now - task_logger.time ).to_i
								hours = gap/3600.to_i
								mins = ( gap/60 % 60 ).to_i
								secs = ( gap % 60 )
								real_hours = ( Time.now - task_logger.time )/3600
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
    	"redmine connect <username> <password> => valide puis associe le couple 'nom d'utilisateur/mot de passe' avec le nom irc de l'utilisateur"
	when "disconnect"
    	"redmine disconnect => désassocie le couple 'nom d'utilisateur/mot de passe' du nom irc de l'utilisateur" 
    when "start"
    	"redmine start <id_task> => Vérifie si la tâche existe, puis lance un compteur personnel"
    when "stop"
    	"redmine stop <message> => Vérifie si une tâche est lancée, puis stoppe le compteur et enregistre le temps et le message dans Redmine"
    when "addtime"
    	"addtime <id_task> <hours> => Vérifie si la tâche existe, puis enregistre les heures dans Redmine"
    when "addcomment"
    	"addcomment <id_task> <message> => Vérifie si la tâche existe, puis ajoute un commentaire pour la tâche dans Redmine"
    when "delete"
    	"delete <id_tasks> => supprime le compteur actuel pour la tâche sans publier les heures dans Redmine"
    when "tasks"
    	"tasks => Affiche la tâche en cours (compteur lancé)"
	when "redmine tasks"
		"redmine tasks => Liste les tâches ouvertes qui vous sont assignées dans Redmine"
    else
    	"type 'help redmine adress|connect|disconnect|start|stop|addtime|tasks' to have further informations"
    end
  end
  
  # Fonction de test
  def redmine_test(m, params)
  	# Raccourci pour appel de fonction non configuré
  end

end

plugin = RedminePlugin.new

plugin.map 'redmine test :test',
  :action => 'redmine_test'
  
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
  
plugin.map 'redmine start :task',
  :action => 'redmine_counter_start'
plugin.map 'start :task',
  :action => 'redmine_counter_start'
  
plugin.map 'redmine stop *message',
  :action => 'redmine_counter_stop'
plugin.map 'stop *message',
  :action => 'redmine_counter_stop'

plugin.map 'redmine addtime :task :hours *message',
  :action => 'redmine_add_time'
plugin.map 'addtime :task :hours *message',
  :action => 'redmine_add_time'
  
plugin.map 'redmine comment :task *message',
  :action => 'redmine_add_comment'
plugin.map 'comment :task *message',
  :action => 'redmine_add_comment'

plugin.map 'redmine delete :task',
  :action => 'redmine_counter_delete'
plugin.map 'delete :task',
  :action => 'redmine_counter_delete'

plugin.map 'redmine kill :username',
  :action => 'redmine_kick'
plugin.map 'kill :username',
  :action => 'redmine_kick'
