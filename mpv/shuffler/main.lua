utils = require("mp.utils") -- mpv helper functions
file_path = mp.get_script_directory() .. "/dir.txt"

if mp.get_property_native("idle-active") then

-- add directories

	existing_dir = {}

	local file_read = io.open(file_path, "r")
	if file_read then
		for line in file_read:lines() do
			local clean_line = line:gsub("^%s*(.-)%s*$", "")
			if clean_line ~= "" then
				existing_dir[clean_line] = true
			end
		end
		file_read:close()
	end

	io.write("Add new directory?")
	local ans = io.read()
	if ans:lower() == "y" then
		while true do
			io.write("New directory: ")
			local dir = io.read()

			if dir == "" then
				print("No data written")
			elseif dir == "exit" then
				print("Completed adding directories.")
				break
			else
				local clean_dir = dir:gsub("^%s*(.-)%s*$", "")
				local metadata = utils.file_info(clean_dir)
				if metadata and metadata.is_directory then
					if existing_dir[clean_dir] then
						print("Directory is already here.")
					else
						local file_append = io.open(file_path, "a")
						if file_append then
							file_append:write(clean_dir .. "\n")
							file_append:close()
							existing_dir[clean_dir] = true
							print("Directory added.")
						else
							print("Failed to open file.")
						end
					end
				elseif not metadata then
					print("Directory does not exist.")
				elseif not metadata.is_directory then
					print("This is not a directory.")
				end
			end
		end
	else
		print("Preparing to shuffle...")
	end

-- find all music files

	all_files = {}
	audio_extensions = {
		aiff = true, alac = true, flac = true, m4a = true, mp1 = true, mp2 = true, mp3 = true, oga = true, ogg = true, mogg = true, opus = true,
		qoa = true, raw = true, wav = true, wma = true
	}

	function recursive_files(dir)
		local all_files_in_dir = utils.readdir(dir) or {}
		for _, name in ipairs(all_files_in_dir) do
			if name ~= "." and name ~= ".." then
				local entire_path = dir .. "/" .. name
				local info = utils.file_info(entire_path)
				if info and info.is_directory then
					recursive_files(entire_path)
				else
					local extension = name:match("%.([^%.]+)$")
					if extension and audio_extensions[extension:lower()] then
						table.insert(all_files, entire_path)
					end
				end
			end
		end
	end

	for dir in pairs(existing_dir) do
		recursive_files(dir)
	end

-- shuffle files

	local total_index = #all_files
	local already_picked = {}
	local shuffled = {}

	if total_index == 0 then
		print("No files found.")
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

	shuffled_files = mp.get_script_directory() .. "/shuffle.m3u8"
	append_shuffle = io.open(shuffled_files, "w")
	if append_shuffle then
		for _, file in ipairs(shuffled) do
			append_shuffle:write(file .. "\n")
		end
		append_shuffle:close()
	end

-- play files

	mp.commandv("loadfile", shuffled_files, "replace")
end