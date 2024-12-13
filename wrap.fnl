;;  manage the game states and entry point for for Löve2D and Fennel
;;  Copyright (C) Phil Hegelberg
;;  Copyright (C) 2024  Alexander Griffith
;;  Copyright (C) 2024  Claude Marinier
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


;; remove disks of the same colour
;;
;; will build it in stages
;; started with EXE encounter 667 by Phil Hagelberg
;; using min-love2d-fennel framework (based on 667)
;;

;; This module contains non-game-specific bits and mode-changing
;; logic.
;;

(local fennel (require :lib.fennel))
(local repl (require :lib.stdio))

; pretty printing
;
(fn pp [x]
  (print (fennel.view x)))
(set _G.pp pp)


; get and save the window's size
;
(var (width height) (love.window.getMode))

;; so we can access game state from all the modes
;; and from the REPL
;;
(var game-state
  {:title-font (love.graphics.newFont "fonts/Fontin-Bold.otf" 48)
   :text-font (love.graphics.newFont "fonts/Quicksand-Medium.ttf" 32)
   :game-font (love.graphics.newFont "fonts/FantasqueSansMono-Regular.ttf" 32)
   :small-font (love.graphics.newFont "fonts/Quicksand-Medium.ttf" 20)
   :width width
   :height height
   :scale 1
   :world nil
   :box {}
   :version "1.2" })
(set _G.gs game-state)


(local canvas (love.graphics.newCanvas game-state.width game-state.height))

; the mode and its name will be set later
;
(var mode nil)
(var mode-name nil)

; require a module and catch errors
;
(fn safe-require [module-name]
  (match (pcall require module-name)
    (true module)
      module
    (false error-msg)
      (do
        (print (string.format "require failed for \"%s\"" module-name))
        (print (string.format "error is %s" error-msg))
        (love.event.quit))))

; move from one mode to the other
; each mode defines functions and puts them in a table
; the wrap module executes these functions when needed
;
; I would like to catch all errors from require; tried pcall,
; but the require fails anddoes not return.
;
(fn set-mode [new-mode-name ...]
; (print (string.format "new mode is %s" new-mode-name))
  (set mode-name new-mode-name)
  (set mode (safe-require new-mode-name))
; (print (string.format "new mode table\n%s"
;                       (fennel-view mode 2)))
  (when mode.activate
    (match (pcall mode.activate ...)
      (false msg) (print mode-name "activate error" msg))))
(set _G.sm set-mode)

; call this with an anonymous function, like this
;   (safely #(my-function arg1 arg2))
; xpcall expects a function with no arguments, so
; wrap it
;
(fn safely [function]
  (xpcall (fn [] (function))
          #(set-mode :error mode-name $ (fennel.traceback))))


; let's get going
; - setup the canvas and the REPL
; - set mode to intro, this triggers the activation function
;
(fn love.load [args]
  (canvas:setFilter "nearest" "nearest")

  ; use the stdio module for the REPL
  ;
  (when (~= :web (. args 1)) (repl.start))

  (set-mode :intro))

; evaluate input from the REPL and pretty print result
;
(fn love.handlers.stdin [line]
  (let [(ok val) (pcall fennel.eval line)]
    (print (if ok (fennel.view val) val))))


;; the next three functions are called by Löve2D
;; once per frame


(fn love.draw []
  ;; the canvas allows you to get sharp pixel-art style scaling; if you
  ;; don't want that, just skip that and call mode.draw directly.
  (love.graphics.setCanvas canvas)
  (love.graphics.clear)
  (love.graphics.setColor 1 1 1)
  (safely #(mode.draw game-state))
  (love.graphics.setCanvas)
  (love.graphics.setColor 1 1 1)
  (love.graphics.draw canvas 0 0 0 game-state.scale game-state.scale))


(fn love.update [dt]
  (when mode.update
    (safely #(mode.update dt))))


(fn love.keypressed [key]
  (if (and (love.keyboard.isDown "lctrl" "rctrl" "capslock")
           (or (= key "q") (= key "x")))
    (love.event.quit)
    (safely #(mode.keypressed key))))

