--  enable use of Fennel for Löve2D and Fennel
--  Copyright (C) 2024  Alexander Griffith
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.

-- bootstrap the compiler
--

local fennel = require("lib.fennel").install({correlate=true,
                                              moduleName="lib.fennel"})

debug.traceback = fennel.traceback

local love_searcher = function(env)
   return function(module_name)
      local path = module_name:gsub("%.", "/") .. ".fnl"
      if love.filesystem.getInfo(path) then
         return function(...)
            local code = love.filesystem.read(path)
            return fennel.eval(code, {env=env}, ...)
         end, path
      end
   end
end

table.insert(package.loaders, love_searcher(_G))
table.insert(fennel["macro-searchers"], love_searcher("_COMPILER"))

-- do the rest in Fennel
--
require("wrap")
