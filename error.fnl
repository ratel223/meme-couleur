;;  handle errors for Löve2D and Fennel
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
;; This mode has two purposes:
;; * display the stack trace that caused the error
;; * allow the user to decide whether to retry after reloading or quit

;; Since we can't know which module needs to be reloaded, we rely on the user
;; doing a ,reload foo in the repl.

(var state {})

(local explanation "Press escape to quit.
Press space to return to the previous mode after reloading in the repl.")


; convert compiler's ansi escape codes to love2d-friendly codes
; the Löve2D print function accepts a table with a mixture of
; strings and colour triplets
;
(fn color-msg [msg]
  (case (msg:match "(.*)\027%[7m(.*)\027%[0m(.*)")
    (pre selected post) [[1 1 1] pre
                         [1 0.2 0.2] selected
                         [1 1 1] post]
    ; else
    _ msg))


(fn activate [old-mode msg traceback]
  (print "error: activate")
  (print msg "")
  (print traceback)
  (set state.old-mode old-mode)
  (set state.msg (color-msg msg))
  (set state.traceback traceback))


(fn update [dt]
  nil)


(fn draw []
  (love.graphics.clear 0.34 0.61 0.86)
  (love.graphics.setColor 0.9 0.9 0.9)
  (love.graphics.print state.msg 10 10)
  (love.graphics.print explanation 15 25)
  (love.graphics.print state.traceback 15 50))


(fn keypressed [key]
  (match key
    :escape (love.event.quit)
    :space (_G.set-mode state.old-mode)))


{: draw : keypressed : activate}
