utils = require("mp.utils") -- mpv helper functions
math.randomseed(os.time()) -- random seed

function normalize_path(path) -- remove double slash and backslash
	path = path:gsub("\\", "/")
	path = path:gsub("//+", "/")
	return path
end

dir_path = mp.get_script_directory() .. "/dir.txt"
shuffle_path = mp.get_script_directory() .. "/shuffle.m3u8"

if mp.get_property_native("idle-active") then
	local get_dir = io.open(dir_path)
	for dir in get_dir:lines() do
		local clean_dir = dir:gsub("^%s*(.-)%s*$", "%1")
	end
end