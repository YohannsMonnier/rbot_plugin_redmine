Redminux : Redmine plugin for Rbot
=================================

Plugin for Rbot which enables interaction between irc bot and redmine.

Author
------

Yohann Monnier - Internethic - http://www.internethic.com


Dependencies
------------

Redmine version 1.1+


Version 0.9.1
-----------
- use the native REST API of Redmine Without hacks

Wiki
----

Le but de ce projet est de créer un robot IRC capable d'interagir avec Redmine.

Liste des fonctionnalités
--------------------------
- Identification du développeur
- Liste des tâches par développeur (ouvertes)
- Liste des tâches d'un projet
- Chronomètre par développeur pour minuter les tâches par développeur

La fonction connect : 
--------------------

Cette fonction permet de s'identifier à Redmine.

Le robot vérifie l'identité de l'utilisateur sur redmine et enregistre la correspondance nickname irc et login redmine.
Voici comment utiliser cette fonction :

!connect username password

Il est évidemment conseillé de le faire dans une conversation privée avec votre robot.

La fonction disconnect : 
------------------------

Cette fonction permet d'effacer les informations d'identification, ainsi que les tâches en cours.

Voici comment utiliser cette fonction : 

!disconnect

La fonction redmine tasks : 
---------------------------

Cette fonction permet de lister les tâche qui sont assignées à l'utilisateur.

Sans ajouter de paramètre, on récupère l'ensemble des tâches ouvertes qui nous sont assignées. La fonction peut aussi être utilisée comme ceci !redmine tasks identifiant-projet pour se voir lister l'ensemble des tâches qui sont assignées à l'utilisateur et ouverte pour un projet en particulier, c'est plus rapide quand de nombreux projets sont ouverts.

La fonction start : 
-------------------

Cette fonction ferme la tâche en cours (si une tâche est ouverte) pour ouvrir la nouvelle tâche.

La fonction peut être utilisée comme ceci 

!start numTache 

Cependant, si vous fermez une tache , vous pouvez aussi spécifier un message pour le commentaire comme ceci : !start numTache Commentaire Ce commentaire n'est cependant pas obligatoire.

La fonction pause : 
-------------------

Cette fonction met en pause la tâche en cours (si une tâche est ouverte).

La fonction peut être utilisée comme ceci 

!pause 


La fonction stop : 
------------------

cette fonction permet maintenant de fermer automatiquement la tâche en cours, sans avoir à spécifier le numéro de la tâche.

Voici comment utiliser cette fonction : 

!stop ou !stop Commentaire

Le commentaire n'est pas obligatoire.

La fonction delete : 
--------------------

cette fonction permet maintenant de fermer automatiquement la tâche en cours, sans enregistrer le temps dans redmine.

Voici comment utiliser cette fonction : 

!delete


La fonction tasks : 
-------------------

Cette fonction permet d'afficher la tâche en cours de l'utilisateur.

Voici comment utiliser cette fonction : 

!tasks


La fonction addtime : 
---------------------

cette fonction permet d'ajouter du temps pour un tache, par exemple si on a pas eu le temps de démarrer le compteur et qu'on s'en aperçoit trop tard.

Voici comment utiliser cette fonction : 

!addtime numTache nbHeure Commentaire

Le commentaire n'est pas obligatoire.


La fonction comment : 
---------------------

cette fonction permet de déposer un commentaire pour une tache. Utile lorsque l'on veut donner une information à un collaborateur sur la tâche en cours.
Voici comment utiliser cette fonction : 

!comment numTache Commentaire

Cette fois ci, le message est évidement obligatoire.


Fonctions administrateur (chef de projet)
-----------------------------------------
Pour utiliser ces fonctions, il faut s'authentifier en administrateur de Rbot.
Pour cela, utiliser la fonction auth : 

!auth passwordAdminRbot
La fonction users : cette fonction liste les utilisateurs connectés, et si ils ont lancé une tâche, affiche la tâche en cours.
Voici comment utiliser cette fonction : 

!users
La fonction alert users : cette fonction liste les utilisateurs connectés qui n'ont pas lancé de tâche.
Elle envoi aussi un message d'alerte aux utilisateurs qui n'ont pas lancés de tâche, leur demandant de le faire le plus rapidement possible.
Voici comment utiliser cette fonction : 

!alert users
La fonction force task : cette fonction permet maintenant d'afficher la tâche en cours d'un autre utilisateur.
Voici comment utiliser cette fonction : 

!force task nom_d_utilisateur
La fonction force stop : cette fonction permet maintenant de fermer automatiquement la tâche en cours d'un autre utilisateur.
Voici comment utiliser cette fonction : 

!force stop nom_d_utilisateur ou !force stop nom_d_utilisateur Commentaire

Le commentaire n'est pas obligatoire.
La fonction force delete : cette fonction permet maintenant de fermer automatiquement la tâche en cours d'un autre utilisateur, sans enregistrer le temps dans redmine.
Voici comment utiliser cette fonction : 

!force delete nom_d_utilisateur
La fonction kill : cette fonction permet de déconnecter un utilisateur identifié.
Elle est utile lorsqu'un utilisateur a oublié de fermer sa tâche et/ou de se déconnecter avant de quitter IRC. Elle est généralement utilisée par l'administrateur après qu'il ait lancé une commance "users" pour vérifier que personne n'ait oublié de fermer ses tâches avant de partir le soir. C'est avec le nom IRC que l'on supprime les données d'identification et les tâches de l'utilisateur.
Voici comment utiliser cette fonction : 

!kill ircUserName


Version 0.0.6
-------------

- use the new Rest API from Redmine
- some hidden features ;)

|
|
|

Old versions Dependencies
-------------------------

Works only if you have installed [redmine_webservice plugin](http://github.com/YohannsMonnier/redmine_webservice/tree/master)  on your redmine server.

Version 0.0.2
-------------

- pause a task
- get tasks in progress
- delete a timer
- save a timer for an other user
- delete a timer for an other user


Version 0.0.1
-------------

- connect users to redmine
- get all your tasks
- get all your tasks for a project
- lauch a timer for a task
- save a timer for a task
- get your current timer data
- disconnect from redmine
