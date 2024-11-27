;;; Mode: play - tag disks, remove them
;;;
;;; the game states will change in a cycle:
;;;   fill -> play -> high-score
;;;   then back to fill or quit
;;;

(local fennel (require :lib.fennel))

; Simple User Interface Toolkit for Löve2D
;
(local SUIT (require :lib.suit))

; use JSON to store the High Scores
;
(local json (require :lib.json))

(import-macros {: decf} :simple-macros)
(import-macros {: incf} :simple-macros)

; will be using a new instance of SUIT each time the player
; starts another game; without this, SUIT remembers that the
; player submitted the input text widget
;
; function calls must use colon syntax
; (instead of the dot syntax)
;
(var suit {})

; manage score and disk count
;
(var score 0)
(var score-str "    0")
(var high-score [])

(var disks-tagged 0)
(var disks-tagged-str "  0")
(var str-width 0)
(var str-height 0)

(var x-gap 5)
(var y-gap 5)

; manage GUI to get user name
;
(var user-name "")
(var input {:text ""})
(var focused false)  ; focus only once

; there are four phases:
; - playing
; - getting name
; - recording name & score
; - all done
; 
(local INIT 0)
(local PLAY 1)
(local NAME 2)
(local RECORD 3)
(local DONE 4)
(var phase INIT)

; for the physics world
;
(local velocityIterations 16)
(local positionIterations 6)

; used when the game is over
;
(local game-over-str "Game over!")

; cool-down for ball impulse
;
;   will bet set after an impulse and count-down to zero
;
(var cool-down 0)

(fn square [n]
  (* n n))


;; Löve2D function - a c t i v a t e


(fn activate []
  (var game-state _G.gs)

  (set phase PLAY)

  ; use JSON for high scores
  ;
  (when (not= nil (love.filesystem.getInfo "high-score.json"))
    (set high-score (json.decode (love.filesystem.read "high-score.json"))))

  ; while testing, show the high-score table
  ;
; (print (string.format "High Score\n%s" (fennel.view high-score)))

  ; reset score
  ;
  (set score 0)
  (set score-str "    0")
  (set disks-tagged 0)
  (set disks-tagged-str "  0")

  ; allow disks to settle from their initial fall
  ; (they start higher and separated)
  ;
  (set cool-down 3)

  ; The second time I play, submitted is already set before
  ; I get a chance to input anything; I do not even see the
  ; text input sidget. Some state is maintained inside SUIT:
  ; Create a new instance every time through this play mode.
  ;
  (set suit (SUIT.new))

  ; reset variables for getting the user's name
  ;
  (set focused false)  ; used by GUI
  (set input {:text ""})
  (set user-name ""))


;; Löve2D function - d r a w


(fn draw []

  (var game-state _G.gs)
  (var world game-state.world)

  (local (w h _flags) (love.window.getMode))

  (love.graphics.setBackgroundColor 0 0 0 1)

  ; display the score in the top-left corner
  ; the number of selected disks in the top-right corner
  ;
  (love.graphics.setColor [0 0 1 1])
  (love.graphics.setFont game-state.game-font)
  (set score-str (string.format "%5d points" score))
  (love.graphics.print score-str x-gap y-gap)

  (love.graphics.setColor [0 0 1 1])
  (set disks-tagged-str (string.format "%3d" disks-tagged))
  (set str-width (game-state.game-font:getWidth disks-tagged-str))
  (love.graphics.print disks-tagged-str (- w str-width x-gap) y-gap)

  ; draw box
  ;
  (local left game-state.left)
  (love.graphics.setColor left.color)
  (love.graphics.polygon "fill" (: left.body :getWorldPoints
                           (left.shape:getPoints)))

  (local right game-state.right)
  (love.graphics.setColor right.color)
  (love.graphics.polygon "fill" (: right.body :getWorldPoints
                           (right.shape:getPoints)))

  (local bottom game-state.bottom)
  (love.graphics.setColor bottom.color)
  (love.graphics.polygon "fill" (: bottom.body :getWorldPoints
                           (bottom.shape:getPoints)))

  ; draw disks
  ;
  (var disks game-state.disks)
  (each [_ disk (pairs disks)]
    (let [(x y) (disk.body:getPosition)]
      (var radius (: disk.shape :getRadius))
      (when disk.bright
        (love.graphics.setColor [0 0 1 1])
        (love.graphics.circle "fill" x y radius)
        (set radius (* radius 0.8)))
      (love.graphics.setColor disk.color)
      (love.graphics.circle "fill" x y radius)))

  ; when the game is over, say so
  ;
  (when ( or (= phase NAME)
             (= phase RECORD)
             (= phase DONE))
    ; display game-over message
    ;
    (love.graphics.setColor [0.10 0.10 1 1])
    (love.graphics.setFont game-state.title-font)
    (set str-height (game-state.text-font:getHeight))
    (set str-width (game-state.title-font:getWidth game-over-str))
    (love.graphics.print game-over-str
                         (- (/ w 2) (/ str-width 2) x-gap)
                         (- (/ h 2) 100)))

  ; when the game is over, get the player's name
  ;
  (when (= phase NAME)
    (: suit :draw))

  (love.graphics.setColor 1 1 1 1))


;; Löve2D function - u p d a t e


; find all disks which touch the selected disk
;
; start with selected disk, build a list, and repeat
;
; How do I know when to stop? Check only new disks.
; The will be duplication.
;
(fn find-touching [disk-list]
  (var game-state _G.gs)
  (var new-disks {})
  (each [selected-id selected-disk (pairs disk-list)]
    (each [id disk (pairs game-state.disks)]
      (when (not= id selected-id)
        (when (: disk.body :isTouching selected-disk.body)
          (when (and (= selected-disk.color disk.color)
                     (not disk.bright))  ; avoid infinite loop
            (tset new-disks id disk)
            (set disk.bright true))))))

  ; recurse if new disks found this pass
  ;
  (when (not= nil (next new-disks))
    ; more disks to check
    (find-touching new-disks)))


(fn update [dt]
  (var game-state _G.gs)
  (var disks game-state.disks)

  ; for the GUI code
  ;
  (var input-state {})

  ; count-down the timer
  ;
  (when (> cool-down 0)
    (decf cool-down dt))

  ; shake-up the ballswith an impulse,
  ; enforce a delay between uses
  ;
  ; don't test floating point numbers for equality with zero
  ;
  (when (and (<= cool-down 0)
             (= phase PLAY)
             (love.keyboard.isDown "space"))
    (set cool-down 0.5)  ; 1/2 a second to avoid "key bounce"
    (each [_ disk (pairs disks)]
      (: disk.body :applyLinearImpulse 0 20)))
  
  ; update the physics world
  ;
  (: game-state.world :update dt velocityIterations positionIterations)

  ; search for a disk under the mouse cursor
  ;
  ; assuming that stopping the search loop when I have found
  ; the disk will be faster than checking all disks, might not
  ; make a significant difference
  ;
  (var selected-disks {})
  (each [_ disk (pairs disks)]
    (set disk.bright false))
  (let [mouse-x (love.mouse.getX)
        mouse-y (love.mouse.getY)]
    (each [id disk (pairs disks) &until (not= nil (next selected-disks))]
      (when (: disk.fixture :testPoint mouse-x mouse-y)
        (set disk.bright true)
        (tset selected-disks id disk))))

  ; find all disks which touch the selected disk
  ;
  (when (not= nil (next selected-disks))
    (find-touching selected-disks))

  ; count the selected disks
  ;
  (var num-bright 0)
  (each [_ disk (pairs disks)]
    (when disk.bright
      (incf num-bright)))
  (set disks-tagged num-bright)
  
  ; the game is over when there are no disks touching
  ; a disk of the same colour
  ;
  (when (and (<= cool-down 0)  ; look-out for floating-point checks
             (= phase PLAY))
    (var game-over true)  ; reset on first touching same colour
    (each [id disk (pairs disks) &until (not game-over)]
      (each [other-id other-disk (pairs disks)]
        (when (not= id other-id)
          (when (: disk.body :isTouching other-disk.body)
            (when (= disk.color other-disk.color)
              (set game-over false))))))
    (when game-over
      ; the game is over, get user's name
      (set phase NAME)))

  ; handle GUI to get the user's name
  ;
  (when (= phase NAME)
    (local (w h _flags) (love.window.getMode))

    ; put the layout origin jut below and to the left of centre
    ; the layout will grow down and to the right from this point
    ;
    (: suit.layout :reset (- (/ w 2) 150) (+ (/ h 2) 50))

    ; put label at layout origin, this is the prompt
    ;
    (love.graphics.setFont game-state.text-font)
    (set str-height (game-state.text-font:getHeight))
    (: suit :Label "Dis-moi ton nom" {:align "left"} (: suit.layout :row 300 str-height))

    ; next is the text input widget
    ;
    (when (not focused)  ; force focus only once
      (set input.forcefocus true)
      (set focused true))
    (set input-state (: suit :Input input {:id "name"} (: suit.layout :row 300 str-height)))

;   (print "state is")
;   (_G.pp input-state)

; debug: show input text as it is entered
;   (: suit :Label (.. "« " input.text " »") {:align "left"} (: suit :layout:row))

    (when input-state.submitted
        (set user-name input.text)
        (set phase RECORD)))

  ; the game is over, wait for user's name
  ; add it to high-score
  ;
  (when (= phase RECORD)
    ; add score to table, sort, truncate when more than ten
    ;
    (table.insert high-score [score user-name])
    (var n 0) (each [_ _ (pairs high-score)] (incf n))
    (when (>= n 2)
      (table.sort high-score (fn [a b] (> (. a 1) (. b 1)))))
    (when (> n 10)
      ; this code should ensure there are never more than ten
      ; entries in the file, but if there are too many, this
      ; will not fix the problem
      (table.remove high-score 11))
    (love.filesystem.write "high-score.json" (json.encode high-score))
    (set phase DONE)
    (set cool-down 2))  ; seconds

  ; after getting the player's name, go display the
  ; high-score list
  ;
  (when (and (<= cool-down 0)
             (= phase DONE))
    (var set-mode _G.sm)
    (set-mode :high-score))

  )  ; end of update


(fn love.textedited [text start len]
  (when (= phase NAME)
    ; for IME input
    (: suit :textedited text start len)))

(fn love.textinput [text]
  (when (= phase NAME)
    ; forward text input to SUIT
    (: suit :textinput text)))

(fn keypressed [key]
  (when (= phase NAME)
    ; forward keypresses to SUIT
    (: suit :keypressed key))

  ; I am not sure this is needed, since it is done
  ; automatically after the player's name is provided
  ;
; (when (and (= phase DONE)
;            (= key "space"))
;   (var set-mode _G.sm)
;   (set-mode :high-score))

  (when (and (= key "q")
             (= key "Q"))
    (love.event.quit)))


(fn love.mousepressed [x y button istouch presses]
  "remove selected disks on mouse click"

  (var game-state _G.gs)
  (var disks game-state.disks)


  (when (= 1 button)
    (set cool-down 4)  ; seconds, allow remaining disks to settle
    (var num-bright 0)
    (each [_ disk (pairs disks)]
      (when disk.bright
        (incf num-bright)))
    (when (>= num-bright 2)
      (each [id disk (pairs disks)]
        (when disk.bright
          (: disk.body :destroy)   ; also destroys fixtures
;         (: disk.fixture :destroy)
;         (: disk.shape :destroy)  ; some say there is no point
          (tset disks id nil)))
      ; increase the score faster, it was (n-2)^2
      (incf score (square (- num-bright 1)))))) ; scoring is (n-1)^2

{:activate activate
 :draw draw
 :update update
 :keypressed keypressed}

