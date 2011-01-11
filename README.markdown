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

Le but de ce projet est de cr�er un robot IRC capable d'interagir avec Redmine.

Liste des fonctionnalit�s
--------------------------
- Identification du d�veloppeur
- Liste des t�ches par d�veloppeur (ouvertes)
- Liste des t�ches d'un projet
- Chronom�tre par d�veloppeur pour minuter les t�ches par d�veloppeur

La fonction connect : 
--------------------

Cette fonction permet de s'identifier � Redmine.

Le robot v�rifie l'identit� de l'utilisateur sur redmine et enregistre la correspondance nickname irc et login redmine.
Voici comment utiliser cette fonction :

!connect username password

Il est �videmment conseill� de le faire dans une conversation priv�e avec votre robot.

La fonction disconnect : 
------------------------

Cette fonction permet d'effacer les informations d'identification, ainsi que les t�ches en cours.

Voici comment utiliser cette fonction : 

!disconnect

La fonction redmine tasks : 
---------------------------

Cette fonction permet de lister les t�che qui sont assign�es � l'utilisateur.

Sans ajouter de param�tre, on r�cup�re l'ensemble des t�ches ouvertes qui nous sont assign�es. La fonction peut aussi �tre utilis�e comme ceci !redmine tasks identifiant-projet pour se voir lister l'ensemble des t�ches qui sont assign�es � l'utilisateur et ouverte pour un projet en particulier, c'est plus rapide quand de nombreux projets sont ouverts.

La fonction start : 
-------------------

Cette fonction ferme la t�che en cours (si une t�che est ouverte) pour ouvrir la nouvelle t�che.

La fonction peut �tre utilis�e comme ceci 

!start numTache 

Cependant, si vous fermez une tache , vous pouvez aussi sp�cifier un message pour le commentaire comme ceci : !start numTache Commentaire Ce commentaire n'est cependant pas obligatoire.

La fonction pause : 
-------------------

Cette fonction met en pause la t�che en cours (si une t�che est ouverte).

La fonction peut �tre utilis�e comme ceci 

!pause 


La fonction stop : 
------------------

cette fonction permet maintenant de fermer automatiquement la t�che en cours, sans avoir � sp�cifier le num�ro de la t�che.

Voici comment utiliser cette fonction : 

!stop ou !stop Commentaire

Le commentaire n'est pas obligatoire.

La fonction delete : 
--------------------

cette fonction permet maintenant de fermer automatiquement la t�che en cours, sans enregistrer le temps dans redmine.

Voici comment utiliser cette fonction : 

!delete


La fonction tasks : 
-------------------

Cette fonction permet d'afficher la t�che en cours de l'utilisateur.

Voici comment utiliser cette fonction : 

!tasks


La fonction addtime : 
---------------------

cette fonction permet d'ajouter du temps pour un tache, par exemple si on a pas eu le temps de d�marrer le compteur et qu'on s'en aper�oit trop tard.

Voici comment utiliser cette fonction : 

!addtime numTache nbHeure Commentaire

Le commentaire n'est pas obligatoire.


La fonction comment : 
---------------------

cette fonction permet de d�poser un commentaire pour une tache. Utile lorsque l'on veut donner une information � un collaborateur sur la t�che en cours.
Voici comment utiliser cette fonction : 

!comment numTache Commentaire

Cette fois ci, le message est �videment obligatoire.


Fonctions administrateur (chef de projet)
-----------------------------------------
Pour utiliser ces fonctions, il faut s'authentifier en administrateur de Rbot.
Pour cela, utiliser la fonction auth : 

!auth passwordAdminRbot
La fonction users : cette fonction liste les utilisateurs connect�s, et si ils ont lanc� une t�che, affiche la t�che en cours.
Voici comment utiliser cette fonction : 

!users
La fonction alert users : cette fonction liste les utilisateurs connect�s qui n'ont pas lanc� de t�che.
Elle envoi aussi un message d'alerte aux utilisateurs qui n'ont pas lanc�s de t�che, leur demandant de le faire le plus rapidement possible.
Voici comment utiliser cette fonction : 

!alert users
La fonction force task : cette fonction permet maintenant d'afficher la t�che en cours d'un autre utilisateur.
Voici comment utiliser cette fonction : 

!force task nom_d_utilisateur
La fonction force stop : cette fonction permet maintenant de fermer automatiquement la t�che en cours d'un autre utilisateur.
Voici comment utiliser cette fonction : 

!force stop nom_d_utilisateur ou !force stop nom_d_utilisateur Commentaire

Le commentaire n'est pas obligatoire.
La fonction force delete : cette fonction permet maintenant de fermer automatiquement la t�che en cours d'un autre utilisateur, sans enregistrer le temps dans redmine.
Voici comment utiliser cette fonction : 

!force delete nom_d_utilisateur
La fonction kill : cette fonction permet de d�connecter un utilisateur identifi�.
Elle est utile lorsqu'un utilisateur a oubli� de fermer sa t�che et/ou de se d�connecter avant de quitter IRC. Elle est g�n�ralement utilis�e par l'administrateur apr�s qu'il ait lanc� une commance "users" pour v�rifier que personne n'ait oubli� de fermer ses t�ches avant de partir le soir. C'est avec le nom IRC que l'on supprime les donn�es d'identification et les t�ches de l'utilisateur.
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
