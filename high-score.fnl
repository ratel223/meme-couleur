;; Mode for displaying the high scores
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

; use JSON to store the High Scores
;
(local json (require :lib.json))

; message handling
;
(var title "High Score")

(var title-width 0)
(var message {})
(var score-width 0)
(var max-width 0)

(var high-score {})

(var line-height 50)
(var offset-y 0)

(local play-again-str "Espace pour continuer.")
(var str-width 0)
(var str-height 0)

(var x-gap 5)
(var y-gap 5)


; count down for restart, can be interrupted
;
(var time 0)  ; in seconds


(fn activate []
  (var game-state _G.gs)

  ; reset the delay time
  ;
  (set time 0)

  ; Löve2d directory where I save the high-score file
  ; reading and writing files defaults to this directory.
  ;   Linux:   ~/.local/share/love/
  ;   Windows: %appdata%\LOVE\
  ;
  (when (not= nil (love.filesystem.getInfo "high-score.json"))
    (set high-score (json.decode (love.filesystem.read "high-score.json"))))

  ; build message from high scores
  ;
  ; maximum score is (153 disks - 2)^2 = 22801 (5 digits)
  ;
  (set score-width (game-state.game-font:getWidth "00000  "))
  (set message [])
  (each [_ score (ipairs high-score)]
    (table.insert message
                  { :s (string.format "%5d  " (. score 1))
                    :n (string.format "%s" (. score 2))}))

  (set offset-y (- (/ (* (length message) line-height) 2)))

  ; centre title
  ;
  (set title-width (game-state.title-font:getWidth title))

  ; centre high scores as a block
  ;
  ; calculate the width of each line in the message
  ; find the widest message line
  ;
  (set max-width 0)
  (each [i msg (ipairs message)]
    (let [name-w  (game-state.text-font:getWidth (. msg :n))
          width (+ score-width name-w)]
      (set max-width (math.max max-width width))))

  ;
  (love.graphics.setBackgroundColor 0.2 0.2 0.2)
  (love.graphics.setColor 1 1 1))


(fn draw []
  (var game-state _G.gs)

  (local (w h _flags) (love.window.getMode))

  ; display title
  ;
  (love.graphics.setFont game-state.title-font)
  (love.graphics.print title (/ (- w title-width) 2) 50)

  ; display high scores
  ;
  ; the fonts do not align vertically, lift the names a bit
  ; score at 125
  ; name  at 118
  ; spacing is 33
  ;
  (love.graphics.setFont game-state.text-font)
  (var left-edge (/ (- w max-width) 2))
  (each [i msg (ipairs message)]
    (love.graphics.setFont game-state.game-font)
    (love.graphics.print (. msg :s)
                         left-edge
                         (+ (* 33 i) 125))
    (love.graphics.setFont game-state.text-font)
    (love.graphics.print (. msg :n)
                         (+ score-width left-edge)  ; after score
                         (+ (* 33 i) 118)))

  ; display Play again?
  ;
  ; Play again message near bottom at 530
  ;
  (love.graphics.setFont game-state.text-font)
  (set str-width (game-state.text-font:getWidth play-again-str))
  (set str-height (game-state.text-font:getHeight))
  (love.graphics.print play-again-str
                      (- (/ w 2) (/ str-width 2) x-gap)
;                     (+ (- (/ h 2) 100) (* 2 str-height))
                      530))


(fn update [dt]
  (var set-mode _G.sm)

  ; re-start game after 30 seconds
  ;
  (incf time dt)
  (when (> time 30)
    (set-mode :fill)))


(fn keypressed [key]
  (var set-mode _G.sm)

  (when (= key "space")
    (set-mode :fill))

  (when (= key "q")
    (love.event.quit)))


{:activate activate
 :draw draw
 :update update
 :keypressed keypressed}

