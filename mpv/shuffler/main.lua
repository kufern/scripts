local utils = require("mp.utils") -- mpv helper functions

-- add directories

script_dir = mp.get_script_directory()
dir = nil

file = io.open(script_dir .. "/dir.txt", "a+")
while true do
	io.write("Add new directory: ")
	dir = io.read()

	if dir == "" then
		print("No data written")
	elseif dir == "exit" then
		file:close()
		print("Completed adding directories.")
		break
	else
		dir_metadata = utils.file_info(dir)
		if dir_metadata and dir_metadata.is_directory then
			file:write(dir .. "\n")
			file:flush()
		elseif not dir_metadata then
			print("Directory does not exist.")
		elseif not dir_metadata.is_directory then
			print("This is not a directory.")
		end
	end
end