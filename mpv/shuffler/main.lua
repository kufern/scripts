utils = require("mp.utils") -- mpv helper functions
file_path = mp.get_script_directory() .. "/dir.txt"

-- add directories

local existing_dir = {}
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

while true do
	io.write("Add new directory: ")
	dir = io.read()

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