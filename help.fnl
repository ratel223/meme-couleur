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
(var message ["Enlève des disques de la même couleur."
              ""
              "Use the mouse to see which disks will be"
              "removed; the disks will be highlighted."
              "Click to remove them. More disks give more"
              "points. Removing 2 disks gives no points,"
              "but it can move surrounding disks. Plan"
              "ahead and arrange disks in larger groups."
              ""
              "Scoring: 3 disks give 1 point; 4 give 4;"
              "  5 give 9; 6 give 16; 7 give 25; etc."
              ""
              "P pour commencer immédiatement."
             ])
(var hint "Space will sometimes shake the disks.")

(var title-width 0)
(var hint-width 0)
(var message-width {})

(var line-height 50)
(var offset-y (- (/ (* (length message) line-height) 2)))


; count down for help, can be interrupted
;
(var time 0)  ; in seconds


(fn activate []
  (var game-state _G.gs)

  ; calculate the width of each line in the message
  ; the title uses a large font size
  (set title-width (game-state.title-font:getWidth title))
  (each [i msg (ipairs message)]
    (tset message-width i (game-state.text-font:getWidth msg)))
  (set hint-width (game-state.small-font:getWidth hint))
  (love.graphics.setBackgroundColor 0.2 0.2 0.2)
  (love.graphics.setColor 1 1 1))


(fn draw []
  (var game-state _G.gs)

  (local (w h _flags) (love.window.getMode))

  ; display title
  ;
  (love.graphics.setFont game-state.title-font)
  (love.graphics.print title (/ (- w title-width) 2) 30)

  ; display instructions
  ;
  (love.graphics.setFont game-state.text-font)
  (each [i msg (ipairs message)]
    (love.graphics.print msg
                         (/ (- w (. message-width i)) 2)
                         (+ (* 30 i) 90)))

  ; display hint
  ;
  (love.graphics.setFont game-state.small-font)
  (love.graphics.print hint (/ (- w hint-width) 2)
                            (- h 50)))


(fn update [dt]
  (var set-mode _G.sm)

  ; start game after a delay
  ;
  (incf time dt)
  (when (> time 60)
    (set-mode :fill)))


(fn keypressed [key]
  (var set-mode _G.sm)

  (when (or (= key "q") (= key "Q"))
    (love.event.quit))

  (when (or (= key "p") (= key "P"))
    (set-mode :fill)))


{:activate activate
 :draw draw
 :update update
 :keypressed keypressed}

