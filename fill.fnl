;; Mode: fill the box with disks
;;
;; the game states will change in a cycle:
;;   fill -> play -> high-score
;;   then back to fill or quit
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

; (import-macros {: incf} :simple-macros)

; variables
;
(local pixels-per-meter 200)
(love.physics.setMeter pixels-per-meter)

(local normal-gravity 9.80665)
(local game-gravity (* normal-gravity pixels-per-meter))


; convert pixels and world metres
;
(fn pixels-to-meters [n]
  (/ n pixels-per-meter))
(fn meters-to-pixels [n]
  (* n pixels-per-meter))

; convert degrees to radians
;
(fn degree->radian [angle]
  (math.sin (* angle (/ math.pi 180))))

; disk colours
; I will need to make a bright version,
; so leave room
;
(local red [1 0 0 1])
(local yellow [1 0.75 0 1])
(local green [0 1 0 1])

; pick a random colour
;
(math.randomseed (os.time))
(fn random-color []
  "pick a random colour: red, yellow, green"
  (let [n (math.random)]
    (if (<= n 0.333)
      red
      (if (<= n 0.666)
        yellow
        green))))

;;;


; message handling
;
(var message {1 "Les disques sont prêts."
              2 "P pour jouer."
              3 "Q pour fermer le jeu."
             })

(var title-width 0)
(var message-width {})

(var line-height 30)
(var offset-y (- (/ (* (length message) line-height) 2)))


(local (w h _flags) (love.window.getMode))

(local left
    {:width 25
     :height (- h 40)
     :x 0
     :y 40
     :color [0.25 0.25 0.25 1.0]  ; dark grey
     :density 10
     :scale-x 1.0
     :scale-y 1.0
    })

(local right
    {:width 25
     :height (- h 40)
     :x (- w 25)
     :y 40
     :color [0.25 0.25 0.25 1.0]  ; dark grey
     :density 10
     :scale-x 1.0
     :scale-y 1.0
    })

(local bottom
    {:width (- w 50)
     :height 25
     :x 25  ; width of left rectangle
     :y (- h 25)  ; up from lower edge
     :color [0.25 0.25 0.25 1.0]  ; dark grey
     :density 10
     :scale-x 1.0
     :scale-y 1.0
    })

; create the box which will contain the disks
;   the sides are fixed, but I may want to make the bottom
;   move a bit to shake the balls so they move a bit
;
(fn activate []
  (var game-state _G.gs)

  ; will create it here or get it from game state
  (var world nil)

  ; will fill it here or get it from game state
  (var disks {})

  ; returning or first time through
  ;
  (if (not= game-state.world nil)

    (do  ; returning

      (set world game-state.world)
      (set disks game-state.disks)

      ; remove any remaining disks
      ;
      (each [id disk (pairs disks)]
        (: disk.body :destroy)   ; also destroys fixtures
;       (: disk.fixture :destroy)
;       (: disk.shape :destroy)  ; some say there is no point
        (tset disks id nil)))

    (do  ; first time through

      (set game-state.pixels-per-meter pixels-per-meter)
      (set game-state.pixels-to-meters pixels-to-meters)
      (set game-state.meters-to-pixels meters-to-pixels)

      ; get ready to use physics
      ; (allow bodies to sleep)
      ;
      (set world (love.physics.newWorld 0.0 game-gravity true))
      (set game-state.world world)

      ; create the box

      ;; remember, the shape (the rectangle we create next)
      ;; anchors to the body from its center, so we have to
      ;; adjust the coordinates

      ; left
      ;
      (set left.body (love.physics.newBody world
                                           (+ left.x (/ left.width 2))
                                           (+ left.y (/ left.height 2))
                                           "static"))
      (set left.shape (love.physics.newRectangleShape left.width left.height))
      (set left.fixture (love.physics.newFixture left.body left.shape left.density))
      (set game-state.left left)

      ; right
      ;
      (set right.body (love.physics.newBody world
                                           (+ right.x (/ right.width 2))
                                           (+ right.y (/ right.height 2))
                                           "static"))
      (set right.shape (love.physics.newRectangleShape right.width right.height))
      (set right.fixture (love.physics.newFixture right.body right.shape right.density))
      (set game-state.right right)

      ; bottom
      ;
      ;   find a way to give the disks a small impulse from the bottom
      ;
      (set bottom.body (love.physics.newBody world
                                           (+ bottom.x (/ bottom.width 2))
                                           (+ bottom.y (/ bottom.height 2))
                                           "static"))
      (set bottom.shape (love.physics.newRectangleShape bottom.width bottom.height))
      (set bottom.fixture (love.physics.newFixture bottom.body bottom.shape bottom.density))
      (set game-state.bottom bottom)

      ; sequential table for the disks
      ;
      (set game-state.disks disks))

    )  ; end of big if

  ;; Two options:
  ;;  1) create all disks in a grid with vertical space
  ;;     and let them fall
  ;;  2) create one disk at a time and let it fall,
  ;;     must be done in update on a timer so each
  ;;     disk has time to fall
  ;; Using option #1 for now.

  (local disk-radius 25)  ;; use diameter for calculating screen size
  (local disk-density 1)

  ; make new disks with random colours
  ;
  ; make arithmetic easier: count rows and columns from zero
  ; create 10 rows and 14 columns plus an extra row of 13 on top
  ;

  (var start-x (+ left.width 10 disk-radius))
  (var start-y (+ left.y     10 disk-radius))
  (var step-size (+ (* 2 disk-radius) 2))

  (fn new-disk [column row]
    (local disk {})
    (set disk.body (love.physics.newBody world
                                          (+ start-x (* column step-size))
                                          (+ start-y (* row step-size))
                                          "dynamic"))
    (set disk.shape (love.physics.newCircleShape disk-radius))
    (set disk.fixture (love.physics.newFixture disk.body disk.shape disk-density))
    (: disk.fixture :setRestitution 0.25)  ; not too bouncy
    (set disk.color (random-color))
    (set disk.bright false)
    disk)

  (for [row 0 9]
    (for [column 0 13]
      (tset disks (string.format "%d,%d" row column) 
            (new-disk column row))))

  (set start-x (+ left.width 15 (* 2 disk-radius)))
  (set start-y (+ 2 disk-radius))

  (for [i 0 12]
    (tset disks (string.format "top %d" i) 
          (new-disk i 0)))


; (each [_ disk (pairs disks)]
;   (let [(x y) (disk.body:getPosition)]
;     (print (string.format "inertia %d" (: disk.body :getInertia)))
;     (print (string.format "mass    %d" (: disk.body :getMass)))
;     (print (string.format "position %d,%d" x y))))

; (_G.pp disks)

  ; calculate the width of each line in the message
  ; the title uses a large font size
  (for [i 1 (# message)]
    (tset message-width i (game-state.text-font:getWidth (. message i))))
  (love.graphics.setBackgroundColor 0.2 0.2 0.2)
  (love.graphics.setColor 1 1 1)
  )  ; end of activate


(fn draw []

  (var game-state _G.gs)

  (local world game-state.world)
  (local disks game-state.disks)

  (local (w h _flags) (love.window.getMode))

  (love.graphics.setBackgroundColor 0 0 0 1)

  ; draw box
  ;
  (love.graphics.setColor left.color)
  (love.graphics.rectangle "fill"
                           left.x left.y left.width left.height)

  (love.graphics.setColor right.color)
  (love.graphics.rectangle "fill"
                           right.x right.y right.width right.height)

  (love.graphics.setColor bottom.color)
  (love.graphics.rectangle "fill"
                           bottom.x bottom.y bottom.width bottom.height)

  ; draw disks
  ;
  (each [_ disk (pairs disks)]
    (let [(x y) (disk.body:getPosition)]
      (love.graphics.setColor disk.color)
      (love.graphics.circle "fill" x y (: disk.shape :getRadius))))

  ; display instructions
  ;
  (love.graphics.setColor 0.1 0.1 0.1 1)
  (var max-w 0)  ; find longest line
  (for [i 1 (# message)]
    (set max-w (math.max max-w (. message-width i))))
  (local gap 20)
  (love.graphics.rectangle "fill"
                           (- (/ (- w max-w) 2) gap)
                           (+ 200 gap)
                           (+ (* 2 gap) max-w)
                           (+ (* 2 gap) (* line-height (# message))))
  (love.graphics.setFont game-state.text-font)
  (love.graphics.setColor 0.9 0.9 0.9 1)
  (for [i 1 (# message)]
    (love.graphics.print (. message i)
                         (/ (- w (. message-width i)) 2)
                         (+ (* line-height i) 200))))

(fn update [dt]
  (var game-state _G.gs)
  ; not moving anything yet, do this in the play mode
  )

(fn keypressed [key]
  (var game-state _G.gs)
  (var set-mode _G.sm)

  (when (or (= key "q") (= key "Q"))
    (love.event.quit))

  (when (or (= key "h") (= key "H"))
    (set-mode :help))

  (when (or (= key "p") (= key "P"))
    ; tilt the world left before playing
    ;
    (let [angle 5]  ; angle in degrees
      (: game-state.world :setGravity
        (- (* game-gravity (math.sin (degree->radian angle))))
        (* game-gravity (math.cos (degree->radian angle)))))
    (set-mode :play)))

{:activate activate
 :draw draw
 :update update
 :keypressed keypressed}

