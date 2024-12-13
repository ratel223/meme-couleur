# Même Couleur

## English

Remove disks which touch and have the same colour.

Use the mouse to see which disks will be removed; the disks
will be highlighted. Click to remove them. More disks give
more points. Removing 2 disks gives no points, but it can move
surrounding disks. Plan ahead and arrange disks in larger
groups.

Scoring: 3 disks give 1 point; 4 give 4;
         5 give 9; 6 give 16; 7 give 25;
         etc.

The formula to calculate points is (n-2)^2.

## En français

Enlève des disques de la même couleur.

Il y a plusieurs disques dans la boîte; ils sont rouges, jaunes,
ou verts. Tu peux enlever les disques qui ont la même couleur et
se touchent. Plus tu enlèves de disques à la fois, plus tu
gagnes des points. Attention, la différence est énorme: deux
donne 0, trois donne 1, quatre donne 4, cinq donne 9, six donne
16; un disque de plus fait beaucoup de différence.

La formule pour calculer les points est (n-2)^2.

## Hint

Tapping the space bar will shake the box holding the disks. This
forces the disks to move. They may not move much or they may get
into a better configuration (allowing more disks to be removed).

## Installation

![Löve2D logo](https://github.com/ratel223/meme-couleur/blob/main/Love-game-icon-0.10.png "Löve2D logo")

Made with Löve2D and Fennel.

Download [Löve2D](https://love2d.org/) from the main page. They
have options for Windows, macOS, Linux, and Android. You may
have to configure your computer to associate .love files with
the Löve2D executable.

Note: I have not tested this on MacOS or Android.

## Lua and Fennel

Fennel is a programming language that brings together the
simplicity, speed, and reach of Lua with the flexibility of
a lisp syntax and macro system.

Lua is flexible enough to read the Fennel code and compile it
dynamically.

## Game structure

The game structure comes from Alexander Griffith's min-love2d-fennel
This, in turn, is based on technomancy's Lisp Game Jam winner
EXO_encounter 667.

(min-love2d-fennel](https://gitlab.com/alexjgriffith/min-love2d-fennel]
  
(EXO_encounter 667)[https://love2d.org/forums/viewtopic.php?t=85189]

Löve2D loads and executes the file main.lua. In this case, it
configures Lua to load Fennel files and dynamically compile
them. The game uses modes for intro, help, fill, play, and high
scores. There is a script for each mode; requiring a mode
returns a table with the functions for that mode. The wrap
script uses this table to execute the code for the current mode.

## Screenshots

![Game Intro](https://github.com/ratel223/meme-couleur/blob/main/screenshots/M%C3%AAme_Couleur_intro.png "Intro")

![Help screen](https://github.com/ratel223/meme-couleur/blob/main/screenshots/M%C3%AAme_Couleur_help.png "Help")

![Filled, ready to play](https://github.com/ratel223/meme-couleur/blob/main/screenshots/M%C3%AAme_Couleur_fill.png "Filled")

![Playing game](https://github.com/ratel223/meme-couleur/blob/main/screenshots/M%C3%AAme_Couleur_play.png "Playing")

![Playing, many red disks selected](https://github.com/ratel223/meme-couleur/blob/main/screenshots/M%C3%AAme_Couleur_many_red_disks.png "many red disks")

