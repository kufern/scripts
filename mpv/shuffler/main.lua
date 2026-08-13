utils = require("mp.utils") -- mpv helper functions
math.randomseed(os.time()) -- random seed

audio_extensions = {
	aa = true, aac = true, aax = true, act = true, aiff = true, alac = true, ape = true, au = true, flac = true, m4a = true, m4b = true,
	m4p = true, mmf = true, mp1 = true, mp2 = true, mp3 = true, mpc = true, ogg = true, oga = true, mogg = true, opus = true, ra = true,
	rw = true, raw = true, rf64 = true, sln = true, tta = true, voc = true, vox = true, wav = true, wma = true, wv = true, webm = true,
	cda = true
} -- set of audio extensions

all_files = {}

local separator = package.config:sub(1,1) == "\\" and "\\" or "/"

function normalize_path(path)
	path = path:gsub("[/\\]", separator)
	path = path:gsub(separator .. "+", separator)
	path = path:gsub("^%s*(.-)%s*$", "%1")
	return path
end

function get_files(path) -- get files recursively
	local all_files_in_path = utils.readdir(path) or {}
	for _, name in ipairs(all_files_in_path) do
		if name ~= "." and name ~= ".." then
			local entire_path = path .. "/" .. name
			entire_path = normalize_path(entire_path)
			local info = utils.file_info(entire_path)
			if info and info.is_dir then
				get_files(entire_path)
			else
				local extension = name:match("%.([^%.]+)$")
				if extension and audio_extensions[extension:lower()] then
					table.insert(all_files, entire_path)
				end
			end
		end
	end
end

dir_path = normalize_path(mp.get_script_directory() .. "/dir.txt")
shuffle_path = normalize_path(mp.get_script_directory() .. "/shuffle.m3u8")

if mp.get_property_native("idle-active") then
	
	mp.osd_message("Starting shuffle...")
	
	-- read files in dir.txt
	local get_dir = io.open(dir_path, "r")
	if not get_dir then
		mp.osd_message("Could not open dir.txt")
		return
	end
	
	for dir in get_dir:lines() do
		local clean_dir = normalize_path(dir)
		if clean_dir ~= "" then
			get_files(clean_dir)
		end
	end
	
	get_dir:close()
	
	-- shuffle files
	local total_index = #all_files
	local already_picked = {}
	local shuffled = {}
	
	if total_index == 0 then
		mp.osd_message("No audio files found")
		return
	end
	
	for i = 1, math.min(100, total_index) do
		local file_index
		repeat
			file_index = math.random(1, total_index)
		until not already_picked[file_index]
		already_picked[file_index] = true
		table.insert(shuffled, all_files[file_index])
	end
	
	local append_shuffle = io.open(shuffle_path, "w")
	if append_shuffle then
		for _, file in ipairs(shuffled) do
			append_shuffle:write(file .. "\n")
		end
		append_shuffle:close()
		mp.commandv("loadfile", shuffle_path, "replace")
	else
		mp.osd_message("Failed to write to shuffle.m3u8")
		return
	end
end