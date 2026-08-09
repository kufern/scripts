utils = require("mp.utils") -- mpv helper functions
math.randomseed(os.time()) -- random seed
file_path = mp.get_script_directory() .. "/dir.txt"

function normalize_path(path)
	path = path:gsub("\\", "/")
	path = path:gsub("//+", "/")
	return path
end
