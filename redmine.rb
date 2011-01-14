# :title: Rbot Authentified REST Client for Redmine
#
# Author:: Yohann MONNIER - Internethic
#
# Version:: 0.9.2
#
# This version will only work with the lastest release of Redmine (>1.1)
#
# License:: MIT license

require 'active_resource'
require 'net/https'
require 'openssl'
require 'pp'

# Issue model rbot side
class ::Issue < ::ActiveResource::Base
	self.proxy = ''
	self.timeout = 5
end
# Timelog model rbot side
class ::TimeEntry < ::ActiveResource::Base
	self.element_name = 'time_entry'
  self.collection_name = 'time_entries'		
	# self.collection_name = 'time_entries'		
	self.proxy = ''
	self.timeout = 5
end
# User model rbot side
class ::RedmineUser < ::ActiveResource::Base
	self.element_name = 'users'
	self.collection_name = 'users'	
	self.proxy = ''
	self.timeout = 5
end
# Admin model rbot side
class ::Admin < ::ActiveResource::Base
	self.collection_name = 'admin'
	self.proxy = ''
	self.timeout = 5
end

class RedminePlugin < Plugin

  Redminelogger = Struct.new('Redminelogger', :task, :time, :for, :inprogress, :projectname, :taskname, :alreadydone)
  RedmineAuth = Struct.new('RedmineAuth', :nickname, :username, :password)
  
  # Initialize configuration
  def initialize
    super  	
    ###############
    ##  SETTINGS ##
    ###############
    # These five variables are the only you need to set.
    @redmine_url_prefixe = "http://"
    @redmine_url_suffixe = "0.0.0.0:3000/"
    @redmine_webservice_default_user = "yohann"
    @redmine_webservice_default_pass = "monnier"

	@redmine_rbot_language = "EN" # or FR

    # Other variables - should not be changed
    @redmine_issue_show_path = "issues/show"
    @redmine_project_show_path = "projects/show"
    @rbot_connector_version = "0.9.2"
    @redmine_rapid_url = @redmine_url_prefixe + @redmine_url_suffixe
    @redmine_counter_hour_limit = 12
	@redmine_dev_activity = 9 
    @redmine_debug_mode = 0
		# language
		if @redmine_rbot_language == "FR"
		
			@redmine_test = "mon test"
			@redmine_l_address = "Adressse"
			@redmine_l_connector = "Connecteur Rbot"
			@redmine_l_welcome = "Bienvenue"
			@redmine_l_sorry= "Désolé"
			@redmine_l_alreadyknownas = "Vous êtes déjà authentifié en tant que"
			@redmine_l_redminedoesnotknowyou= "Redmine ne vous connais pas"
			@redmine_l_byebye = "Aurevoir"
			@redmine_l_hello = "Bonjour"
			@redmine_l_pleaseconnect = "veuillez vous authentifier pour accéder à cette fonctionnalité"
			@redmine_l_rightnow = "En ce moment"
			@redmine_l_connectedusersare = "les utilisateurs connectés sont"
			@redmine_l_aka = "as"
			@redmine_l_pause = "en pause"
			@redmine_l_running = "en cours"
			@redmine_l_task = "Tâche"
			@redmine_l_notaskrunning = "Aucune tâche en cours"
			@redmine_l_youhavenottherights = "Tu ne dispose pas des droits nécessaires"
			@redmine_l_usersthatdontruntasksare = "les utilisateurs qui n'ont pas lancé de compteur sont"
			@redmine_l_youdidnotlaunchtask =	"Tu n'as démarré aucune tâche en ce moment ? Lance le compteur ;) (aide ? => help redmine start)"
			@redmine_l_currenttaskof =	"Tâche en cours de"
			@redmine_l_error =	"Erreur"
			@redmine_l_youhavealreadyarunningtask =	"Vous avez déjà une tache en cours"
			@redmine_l_thetask = "La tâche"
			@redmine_l_doesnotexistsinredmine = "n'existe pas dans Redmine"
			@redmine_l_last = "a duré" #took
			@redmine_l_hasnotbeenupdated = "n'a pas été mise à jour, le compteur n'a pas été stoppé (problème lors de l'enregistrement)"
			@redmine_l_startedon = "débutée le" #started on
			@redmine_l_hasnotbeenupdatedcauseofcounter = "n'a pas été mise à jour car le compteur a dépassé"
			@redmine_l_updateitinredmine = "Le compteur a été supprimé, si vous voulez quand même enregistrer ce temps, faites le dans redmine"
			@redmine_l_pausingtask = "Mise en pause de la tâche"
			@redmine_l_totaltime = "Temps total"
			@redmine_l_on = "à"
			@redmine_l_startagain = "Reprise de la tâche"
			@redmine_l_youhavenotarunningtask =	"Vous n'avez pas de tâches en cours"
			@redmine_l_timesavedforthistask =	"Les temps enregistrés pour la tâche"
			@redmine_l_were = "étaient"
			@redmine_l_ijusterasedthishoursdontforgettoreportit = "je viens d'effacer ces heures, n'oublis pas de reporter les heures effectuées"
			@redmine_l_hasbeenupdated = "a été mise à jour"
			@redmine_l_defaultcommentmessage = "Mis à jour par Webservice"
			@redmine_l_user = "Utilisateur"
			@redmine_l_erased = "supprimé"
			@redmine_l_ihavenodataonthisuser = "Je n'ai aucune donnée sur cet utilisateur"
			@redmine_l_taskerased = "Tâche effacée"
			@redmine_l_isstarting = "commence la tâche"
		else
			@redmine_test = "my test"
			@redmine_l_address = "Addresss"
			@redmine_l_connector = "Rbot connector"
			@redmine_l_welcome = "Welcome"
			@redmine_l_sorry= "Sorry"
			@redmine_l_alreadyknownas = "You are already logged in as"
			@redmine_l_redminedoesnotknowyou= "Redmine does not know you"
			@redmine_l_byebye = "Bye bye"
			@redmine_l_hello = "Hello"
			@redmine_l_pleaseconnect = "Please log in to use this feature"
			@redmine_l_rightnow = "Right now"
			@redmine_l_connectedusersare = "Connected users are"
			@redmine_l_aka = "as"
			@redmine_l_pause = "pause"
			@redmine_l_running = "running"
			@redmine_l_task = "Task"
			@redmine_l_notaskrunning = "No running task"
			@redmine_l_youhavenottherights = "You do not have the rights for that"
			@redmine_l_usersthatdontruntasksare = "User who did not launch timer are"
			@redmine_l_youdidnotlaunchtask =	"Your did not start a task ? Launch the timer ;) (need help ? => help redmine)"
			@redmine_l_currenttaskof =	"Current task of"
			@redmine_l_error =	"Error"
			@redmine_l_youhavealreadyarunningtask =	"You have already launched a task"
			@redmine_l_thetask = "The task"
			@redmine_l_doesnotexistsinredmine = "does not exist in Redmine"
			@redmine_l_last = "took" #took
			@redmine_l_hasnotbeenupdated = "have not been updated, the timer has not be stopped"
			@redmine_l_startedon = "started at" #started on
			@redmine_l_hasnotbeenupdatedcauseofcounter = "have not been updated, because the timer have overpass"
			@redmine_l_updateitinredmine = "The timer has been deleted, if you want to save this time entry, do it in Redmine"
			@redmine_l_pausingtask = "Suspending task"
			@redmine_l_totaltime = "Total time"
			@redmine_l_on = "at"
			@redmine_l_startagain = "Resuming task"
			@redmine_l_youhavenotarunningtask =	"You do not have a running task"
			@redmine_l_timesavedforthistask =	"Timelogs for the task"
			@redmine_l_were = "were"
			@redmine_l_ijusterasedthishoursdontforgettoreportit = "I erased this time entry, don't forget to report your time in Redmine"
			@redmine_l_hasbeenupdated = "has been updated"
			@redmine_l_defaultcommentmessage = "Updated by Webservice"
			@redmine_l_user = "User"
			@redmine_l_erased = "deleted"
			@redmine_l_ihavenodataonthisuser = "I have no data on this user"
			@redmine_l_taskerased = "Task deleted"
			@redmine_l_isstarting = "is starting"
		end
    
  end
  
  # Fonction de test
  def redmine_test(m, params)
  	# Raccourci pour appel de fonction non configuré
		begin

				m.reply "#{@redmine_test} !"

		rescue Exception => e
			m.reply e.message
			m.reply e.backtrace.inspect
    end

  end

  # Display the known redmine adress
  def redmine_address(m, params)
  	 begin	
  	 	certificate = redmine_check_auth(m)
		if ! certificate
			# Dont do anything, user is not connected
		else
  		m.reply "#{@redmine_l_address} : #{@redmine_rapid_url}, #{@redmine_l_connector} : #{@rbot_connector_version} !"
#			# Configuration of the connector
#			#			::Admin.site = @redmine_rapid_url
#			#			::Admin.user = @redmine_webservice_default_user
#			#			::Admin.password = @redmine_webservice_default_pass
#			#			redmine = Admin.find(:info)
#			# m.reply "Version : #{redmine.redmine_version.name}, BDD : #{redmine.db_adapter.name}, Connecteur Rbot : #{@rbot_connector_version} !"
    	end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end	
  end
  
  def redmine_get_user(username)
    begin	
			@registry.keys.each do |key_data|
				# utilisateurs connectés
				if key_data.include? "_auth"
					# recuperons les données de l'utilisateur
					authstored = @registry[key_data]
					# Si l'utilisateur est l'utilisateur recherché on renvoi son tableau de valeur
					if authstored[0].username == username
						return authstored
					end
				end
			end
			# Si aucun utilisateur n'a été trouvé, on retourne faux à la fonction appelante
			return false
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end	
  end

  def redmine_get_user_list(m)
    begin	
			userlist = Hash.new	
			@registry.keys.each do |key_data|
				# utilisateurs connectés
				if key_data.include? "_auth"
					# recuperons les données de l'utilisateur
					userdata = @registry[key_data]
					# Si le login est déjà connu, on ajoute le nickname, sinon on crée une nouvelle cases
					if  userlist.has_key? userdata[0].username
							userlist[userdata[0].username][:nickname] = "#{userlist[userdata[0].username][:nickname]}, #{userdata[0].nickname}"
					else
							userlist[userdata[0].username] = {:nickname => userdata[0].nickname, :firtone => userdata[0].nickname}
					end
				end
			end
			# Retourne la liste des utilisateurs redmine
			return userlist
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end	
  end
 
  # Check authentification in Redmine in order to authentify User in Redmine Bot system
  def redmine_connect(m, params)
  	begin
		# Configuration of the connector
		::RedmineUser.site = @redmine_rapid_url
		::RedmineUser.user = params[:user]
		::RedmineUser.password = params[:password]
		# Looking for this user
		user = RedmineUser.find('current')    	
    	
    if ! user.nil?	
    		#on teste si il est déjà authentifié ou non
    		if ! @registry["#{m.sourcenick}_auth"]
					authtostore = @registry["#{m.sourcenick}_auth"] || Array.new	
					authtostore.push RedmineAuth.new(m.sourcenick, params[:user], params[:password])
					@registry["#{m.sourcenick}_auth"] = authtostore			
    			m.reply "#{@redmine_l_welcome} #{user.firstname.capitalize} #{user.lastname.capitalize} !"
    		else
    			authstored = @registry["#{m.sourcenick}_auth"]
    			m.reply "#{@redmine_l_sorry} #{m.sourcenick}, #{@redmine_l_alreadyknownas} #{authstored[0].username} !"
    		end
    # Si le couple user/password ne fonctionne pas
    else
    	m.reply "#{@redmine_l_redminedoesnotknowyou} !"
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
			m.reply "#{@redmine_l_byebye} #{certificate[:username]}."
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
			m.reply "#{@redmine_l_hello} #{m.sourcenick}, #{@redmine_l_pleaseconnect}."
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
  # @TODO : Corriger ce système pour n'afficher qu'une par user redmine avec la liste des utilisateurs connectés
  def redmine_users(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			if m.source.botuser.owner?
				m.reply "#{Underline}#{@redmine_l_rightnow}, " + m.sourcenick + ", #{@redmine_l_connectedusersare}:#{Underline}"
				# récupération de la liste des utilisateurs
				list_of_user = redmine_get_user_list(m)

				list_of_user.keys.each do |key_data|
					# utilisateurs connectés
						# recuperons les données de l'utilisateur
						nicknamelist = list_of_user[key_data]
						# on affiche le nom de l'utilisateur
						m.reply "#{Bold}#{key_data} #{@redmine_l_aka} #{nicknamelist[:nickname]}#{Bold}"

						if @registry.has_key? key_data
							@registry[key_data].each do |task_logger|
								if (task_logger.inprogress == "pause")
									# preparation du paramètre durée de tache
									gap = task_logger.alreadydone.to_i
									hours = gap/3600.to_i
									mins = ( gap/60 % 60 ).to_i
									secs = ( gap % 60 )
									real_hours = ( task_logger.alreadydone )/3600
									pause_message = "[#{@redmine_l_pause}]"
								else
									gap = ( Time.now - task_logger.time ).to_i + task_logger.alreadydone.to_i
									hours = gap/3600.to_i
									mins = ( gap/60 % 60 ).to_i
									secs = ( gap % 60 )
									real_hours = ( Time.now - task_logger.time )/3600
									pause_message = "[#{@redmine_l_running}]"
								end
								m.reply "#{@redmine_l_task} ##{task_logger.task}#{pause_message} (#{hours}h #{mins}m #{secs}s) : [#{task_logger.projectname}] #{task_logger.taskname}(!!) => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{task_logger.task}"
							end
						else
							m.reply "#{@redmine_l_notaskrunning}"
						end
				end
			else
				m.reply "#{@redmine_l_youhavenottherights}"
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
				m.reply "#{Underline}#{@redmine_l_rightnow}, " + m.sourcenick + ", #{@redmine_l_usersthatdontruntasksare}:#{Underline}"

				@registry.keys.each do |key_data|
					# utilisateurs connectés
					if key_data.include? "_auth"
						# recuperons les données de l'utilisateur
						authstored = @registry[key_data]
						nickname = key_data.gsub('_auth', '')
					
						# Si l'utilisateur n'a pas de taches, on lui indique par message
						if ! @registry.has_key? authstored[0].username
							# on affiche le nom de l'utilisateur pour l'administrateur
							m.reply "#{Bold}#{nickname} #{@redmine_l_aka} #{authstored[0].username}#{Bold} - #{@redmine_l_notaskrunning}"
							# on envoie le message à l'utilisateur
							@bot.say nickname , "#{Bold}#{nickname}#{Bold}, #{@redmine_l_youdidnotlaunchtask}"
						end
					end
				end
			else
				m.reply "#{@redmine_l_youhavenottherights}"
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end
  
  # Display the tasks for this user
  def redmine_my_tasks(m, params)
  	begin
		certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			## Loading All issues for this user
			# Configuration of the connector
			::Issue.site = @redmine_rapid_url
			::Issue.user = certificate[:username]
			::Issue.password = certificate[:password]
			# Get All Issues for a user
			issues = Issue.find(:all, :params => { :assigned_to_id => 'me',:set_filter => 1 })
			issues.each do |issue|
	    	  # Display Issues one by one
	    	  redmine_display_an_issue(m, issue)
	    	end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end	
  end
  
  # Display the tasks for this user for one project
  def redmine_my_tasks_by_project(m, params)
  	begin
		certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			## Loading All issues for this user
			# Configuration of the connector
			::Issue.site = @redmine_rapid_url
			::Issue.user = certificate[:username]
			::Issue.password = certificate[:password]
			# Get All Issues for a user and for one project
			issues = Issue.find(:all, :params => { :assigned_to_id => 'me',:set_filter => 1, :project_id => params[:id_project] })
			issues.each do |issue|
	    	  # Display Issues one by one
	    	  redmine_display_an_issue(m, issue)
	    	end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end	
  end
  
  # Display the known redmine users by project
  def redmine_display_an_issue(m, issue)
  	begin
		m.reply "#{@redmine_l_task} ##{issue.id} : [#{issue.project.name}] #{issue.subject} (#{issue.priority.name}) => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{issue.id}"
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end	
  end
 
   # Fonction qui force l'arret d'une tache d'un développeur
  def redmine_force_tasks(m, params)
  	if m.source.botuser.owner?
			redmine_tasks(m, params)
  	else
			m.reply "#{@redmine_l_youhavenottherights}"
  	end
  end
  
   # Display the known pending redmine tasks for this user
  def redmine_tasks(m, params)
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
			m.reply "#{Underline}#{@redmine_l_currenttaskof} #{user_login} :#{Underline}"
			if @registry.has_key? user_login
				task_detected = false
				@registry[user_login].each do |task_logger|
					task_detected = true
						if (task_logger.inprogress == "pause")
							# preparation du paramètre durée de tache
							gap = task_logger.alreadydone.to_i
							hours = gap/3600.to_i
							mins = ( gap/60 % 60 ).to_i
							secs = ( gap % 60 )
							real_hours = ( task_logger.alreadydone )/3600
							pause_message = "[#{@redmine_l_pause}]"
						else
							gap = ( Time.now - task_logger.time ).to_i + task_logger.alreadydone.to_i
							hours = gap/3600.to_i
							mins = ( gap/60 % 60 ).to_i
							secs = ( gap % 60 )
							real_hours = ( Time.now - task_logger.time )/3600
							pause_message = "[#{@redmine_l_running}]"
						end
					
					m.reply "#{@redmine_l_task} ##{task_logger.task}#{pause_message} (#{hours}h #{mins}m #{secs}s) : [#{task_logger.projectname}] #{task_logger.taskname} => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{task_logger.task}"
				end
				if !task_detected
					if @redmine_debug_mode == 1
						m.reply "#{@redmine_l_notaskrunning}"
					end
				end
				
			else
				#if @redmine_debug_mode == 1
					m.reply "#{@redmine_l_notaskrunning}"
				#end
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end


 # check if the task given in parameter exists in Redmine
  def redmine_check_task(m, params, certificate)
    begin   	
       	## Loading one issue by its id
		# Configuration of the connector
		::Issue.site = @redmine_rapid_url
		::Issue.user = certificate[:username]
		::Issue.password = certificate[:password]
		# Get one issue
		issue = Issue.find(params[:task])
    	
    	if issue.nil?
    		return false
    	else 
    		return issue
    	end
    	
    rescue Exception => e
      m.reply "#{@redmine_l_error}: #{e.message}"
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
				m.reply "#{@redmine_l_youhavealreadyarunningtask} #{certificate[:username]}."
			else
				resulted_task = redmine_check_task(m, params, certificate)
				if resulted_task
					tasktostore = Array.new
					tasktostore.push Redminelogger.new(params[:task], Time.now, certificate[:username], "true", resulted_task.project.name, resulted_task.subject, 0 )
					@registry[certificate[:username]] = tasktostore
					m.reply "#{certificate[:username]} #{@redmine_l_isstarting} ##{params[:task]} [#{resulted_task.project.name}][#{Bold}#{resulted_task.subject}#{Bold}] #{@redmine_l_on} #{Time.now.strftime('%H:%M')} => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{params[:task]}"
				else
					m.reply "#{@redmine_l_thetask} #{params[:task]} #{@redmine_l_doesnotexistsinredmine}"
				end
			end
      	end
    rescue Exception => e
      m.reply "#{@redmine_l_error}: #{e.message}"
    end
  end

  # Fonction qui force l'arret d'une tache d'un développeur
  def redmine_force_stop(m, params)
  	if m.source.botuser.owner?
		redmine_counter_stop(m, params)
  	else
		m.reply "#{@redmine_l_youhavenottherights}"
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
				certificate[:username] = params[:othername]
				# Get the data in order to close the task
				otheruserdata = redmine_get_user( params[:othername] )
				certificate[:password] = otheruserdata[0].password
			end
			# Configuring local params
			user_login = certificate[:username]
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
							real_hours = ( task_logger.alreadydone.to_f )/3600.to_f
						else
							gap = ( Time.now - task_logger.time ).to_i + task_logger.alreadydone.to_i
							gapreal = ( ( Time.now - task_logger.time ) + task_logger.alreadydone )
							hours = gap/3600.to_i
							mins = ( gap/60 % 60 ).to_i
							secs = ( gap % 60 )
							real_hours = gapreal.to_f/3600.to_f
						end
						
						# on met à jour le champ params avant de s'en servir
						params[:task] = task_logger.task
						params[:username] = user_login
						params[:spent_time] = real_hours
						# if counter time limit has been reached, it is erased and not save in redmine 
						if (gap < @redmine_counter_hour_limit*3600)

							# appel à la méthode du webservice pour l'ajout de temps pour une tache
							time_entry_added = redmine_add_time_entry(m, params, certificate)
							if time_entry_added
								# affichage d'un message
								counter_message = "#{@redmine_l_thetask} ##{task_logger.task}[#{task_logger.time.strftime('%H:%M')}]; #{@redmine_l_last} #{hours}h #{mins}min  #{secs}s => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{params[:task]}"
								task_counter.push counter_message
							else
								counter_message = "#{@redmine_l_thetask} ##{task_logger.task} #{@redmine_l_hasnotbeenupdated}"
							end
						else
							counter_time_limit = true
							counter_message = "#{Bold}#{@redmine_l_thetask} ##{task_logger.task}[#{@redmine_l_startedon} #{task_logger.time.strftime('%d/%m/%Y - %H:%M')}] #{@redmine_l_hasnotbeenupdatedcauseofcounter} #{@redmine_counter_hour_limit}h (#{hours}h #{mins}min et #{secs} secs).#{Bold} #{@redmine_l_updateitinredmine} : #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{params[:task]}"
							task_counter.push counter_message
						end
				end
				if ( !task_counter.empty? and ( time_entry_added or counter_time_limit ) )
					# on indique à l'utilisateur
					@bot.say m.replyto, "#{user_login},  " +
					  task_counter.join(' ')
					# on efface la tache enregistrée
					@registry.delete user_login
				elsif (task_counter.empty?)
					if @redmine_debug_mode == 1
						m.reply "#{@redmine_l_notaskrunning}"
					end
				end
			else
				if @redmine_debug_mode == 1
					m.reply "#{@redmine_l_notaskrunning}"
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
							m.reply "#{@redmine_l_pausingtask} ##{task_logger.task}, #{@redmine_l_startedon} #{task_logger.time.strftime('%H:%M')}, #{@redmine_l_totaltime} : #{hours}h #{mins}min #{secs}s, #{@redmine_l_running} => #{task_logger.inprogress}"
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
							m.reply "#{@redmine_l_startagain} ##{task_logger.task} #{@redmine_l_on} #{task_logger.time.strftime('%H:%M')}, #{@redmine_l_totaltime} : #{hours}h #{mins}min #{secs}s"
							
					end
				end
			else
				m.reply "#{certificate[:username]}: #{@redmine_l_youhavenotarunningtask}."
			end
      	end
    rescue Exception => e
      m.reply "#{@redmine_l_error}: #{e.message}"
    end
  end


  # Fonction qui force la suppression d'une tache d'un développeur
  def redmine_force_delete(m, params)
  	if m.source.botuser.owner?
		redmine_counter_delete(m, params)
  	else
		m.reply "#{@redmine_l_youhavenottherights}"
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
						m.reply "#{@redmine_l_timesavedforthistask} ##{task_logger.task}[#{task_logger.time.strftime('%H:%M')}]; #{@redmine_l_were} :  #{hours}h #{mins}min, #{secs}secs"
				end
				# on indique à l'utilisateur
				@bot.say m.replyto, "#{certificate[:username]}, #{@redmine_l_ijusterasedthishoursdontforgettoreportit}."
				# on efface la tache enregistrée
				@registry.delete user_login
			else
				m.reply "#{@redmine_l_notaskrunning}"
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
			resulted_task = redmine_check_task(m, params, certificate)
			if resulted_task
				# on met à jour le champ params avant de l'employer
				params[:username] = certificate[:username]
				params[:spent_time] = params[:hours]
				# appel à la méthode du webservice pour l'ajout de temps pour une tache
				redmine_add_time_entry(m, params, certificate)
				
				# on indique à l'utilisateur
				@bot.say m.replyto, "#{certificate[:username]}, #{@redmine_l_thetask} ##{resulted_task.id} #{@redmine_l_hasbeenupdated} => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{resulted_task.id}"
			else
				m.reply "#{@redmine_l_thetask} ##{params[:task]} #{@redmine_l_doesnotexistsinredmine}"
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end
  
  # Add a comment on a Redmine task
  def redmine_add_comment(m, params)
    begin
    	certificate = redmine_check_auth(m)
		if ! certificate
			# ne rien faire, l'utilisateur n'est pas connecté
		else
			resulted_task = redmine_check_task(m, params, certificate)
			if ! resulted_task.nil?
				# Best way to save text line
				messageEntry = params[:message].to_s.strip
				# Ajout d'un commentaire
				resulted_task.notes = messageEntry	
				# Save an issue
				if ! resulted_task.save
					# on indique à l'utilisateur
					@bot.say m.replyto, "#{certificate[:username]}, #{@redmine_l_thetask} ##{resulted_task.id} #{@redmine_l_hasnotbeenupdated}"
				else 
					# on indique à l'utilisateur
					@bot.say m.replyto, "#{certificate[:username]}, #{@redmine_l_thetask} ##{resulted_task.id} #{@redmine_l_hasbeenupdated} => #{@redmine_rapid_url}#{@redmine_issue_show_path}/#{resulted_task.id}"
				end
			else
				m.reply "#{@redmine_l_thetask} ##{params[:task]} #{@redmine_l_doesnotexistsinredmine}"
			end
		end
    rescue Exception => e
      m.reply e.message
      m.reply e.backtrace.inspect
    end
  end
  
  # add a time entry on redmine task
  def redmine_add_time_entry(m, params, certificate)
    begin
     	#Initialisation des paramètres
     	if (params[:message] &&  !params[:message].empty?)
     		messageEntry = params[:message].to_s.strip
     	else
     		messageEntry =  "#{@redmine_l_defaultcommentmessage}"
     	end 
		## Save a new time entry
		# Configuration of the connector
		::TimeEntry.site = @redmine_rapid_url
		::TimeEntry.user = certificate[:username]
		::TimeEntry.password = certificate[:password]
		# Saving the new timelog
		newtimeentry = TimeEntry.new(:issue_id => params[:task], :comments => messageEntry, :activity_id =>@redmine_dev_activity, :hours => params[:spent_time])
		if ! newtimeentry.save
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
					@bot.say m.replyto, "#{@redmine_l_user} #{Bold}#{params[:username]}#{Bold} #{@redmine_l_erased}"
				else
					@bot.say m.replyto, "#{@redmine_l_ihavenodataonthisuser}"
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
								m.reply "#{@redmine_l_timesavedforthistask} ##{task_logger.task}[#{task_logger.time.strftime('%H:%M')}]; #{@redmine_l_were} :  #{hours}h #{mins}min, #{secs}secs"
						end
						# on indique à l'utilisateur
						@bot.say m.replyto, "-> #{@redmine_l_taskerased}"
						# on efface la tache enregistrée
						@registry.delete redmine_username

					end
				end
			else 
				m.reply "#{@redmine_l_youhavenottherights}"
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
  

  
   # Fonction cachée 42 pour rire
  def answer_forty_two(m, params)
  	# Raccourci pour appel de fonction non configuré
		@bot.say m.replyto, "the answer to life the universe and everything ?"
		@bot.say m.replyto, "..."
		@bot.say m.replyto, "..."
		@bot.say m.replyto, "..."
		@bot.say m.replyto, " = 42 !"
  end 

   # Fonction cachée 42 pour rire
  def forty_two_answer(m, params)
  	# Raccourci pour appel de fonction non configuré
		@bot.say m.replyto, "42 ?"
		@bot.say m.replyto, "..."
		@bot.say m.replyto, "..."
		@bot.say m.replyto, "..."
		@bot.say m.replyto, " = the answer to life the universe and everything !"
  end 

end

plugin = RedminePlugin.new

plugin.map 'test *try',
  :action => 'redmine_test',
  :defaults => {:try => "default"}
  
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
  
# This is only for retro compatibility
plugin.map 'tasks',
  :action => 'redmine_tasks'

plugin.map 'task',
  :action => 'redmine_tasks'
  
plugin.map 'force task :othername',
  :action => 'redmine_force_tasks'
  
plugin.map 'redmine start :task_to_start *message',
  :action => 'redmine_start_stop',
  :defaults => {:message => ""}
plugin.map 'start :task_to_start *message',
  :action => 'redmine_start_stop',
  :defaults => {:message => ""}
  
plugin.map 'pause',
  :action => 'redmine_pause'
plugin.map 'clope',
  :action => 'redmine_pause'
  
plugin.map 'redmine stop *message',
  :action => 'redmine_counter_stop',
  :defaults => {:message => ""}
plugin.map 'stop *message',
  :action => 'redmine_counter_stop',
  :defaults => {:message => ""}
  
plugin.map 'force stop :othername *message',
  :action => 'redmine_force_stop',
  :defaults => {:message => ""} 

plugin.map 'redmine addtime :task :hours *message',
  :action => 'redmine_add_time',
  :defaults => {:message => ""}
plugin.map 'addtime :task :hours *message',
  :action => 'redmine_add_time',
  :defaults => {:message => ""}
  
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
plugin.map '42',
  :action => 'forty_two_answer'
