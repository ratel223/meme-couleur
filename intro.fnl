;; Mode for the introduction
;;
;; using the template developped by Phil Hegelberg and packaged
;; by Alexander Griffith
;;

;;  mode template for Löve2D and Fennel
;;  Copyright (C) 2024  Phil Hegelberg
;;  Copyright (C) 2024  Alexander Griffith
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;;
;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <https://www.gnu.org/licenses/>.

(import-macros {: incf} :simple-macros)

; message handling
;
(local (major minor revision) (love.getVersion))
(var title "Même Couleur")
(var message ["Enlève des groupes de disques"
              "qui ont la même couleur."
              "Le jeu va commencer bientôt."
              " "
              "P to play   H for Help   Q to Quit"
;             " "
;             (: "Löve2D Version: %s.%s.%s" :format  major minor revision)
             ])

(var title-width 0)
(var message-width {})

(var line-height 50)
(var offset-y (- (/ (* (length message) line-height) 2)))


; count down for intro, can be interrupted
;
(var time 0)  ; in seconds


(fn activate []
  (var game-state _G.gs)

  ; calculate the width of each line in the message
  ; the title uses a large font size
  (set title-width (game-state.title-font:getWidth title))
  (each [i msg (ipairs message)]
    (tset message-width i (game-state.text-font:getWidth msg)))
  (love.graphics.setBackgroundColor 0.2 0.2 0.2)
  (love.graphics.setColor 1 1 1))


(fn draw []
  (var game-state _G.gs)

  (local (w h _flags) (love.window.getMode))

  ; display title
  ;
  (love.graphics.setFont game-state.title-font)
  (love.graphics.print title (/ (- w title-width) 2) 100)

  ; display instructions
  ;
  (love.graphics.setFont game-state.text-font)
  (each [i msg (ipairs message)]
    (love.graphics.print msg
                         (/ (- w (. message-width i)) 2)
                         (+ (* 30 i) 200))))


(fn update [dt]
  (var set-mode _G.sm)

  ; start game after 30 seconds
  ;
  (incf time dt)
  (when (> time 30)
    (set-mode :fill)))


(fn keypressed [key]
  (var set-mode _G.sm)

  (when (or (= key "p") (= key "P"))
    (set-mode :fill))

  (when (or (= key "h") (= key "H"))
    (set-mode :help))

  (when (or (= key "q") (= key "Q"))
    (love.event.quit)))


{:activate activate
 :draw draw
 :update update
 :keypressed keypressed}

