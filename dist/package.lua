--- LuaDist package specific functions
-- Peter Drahoš, Peter Kapec, LuaDist Project, 2010

--- Package handling functions.
-- This module deals with packages, these are unpacked dists in LuaDist terminology
-- The following functions are provided:
-- unpack - fetch and unpack a dist
-- build - compile a source dist
-- deploy - install a dist into deployment
-- pack - create dist from package
-- delete - delete package

module ("dist.package", package.seeall)

local config 	= require "dist.config"
local fetch 	= require "dist.fetch"
local persist 	= require "dist.persist"
local sys 		= require "dist.sys"
local manif 	= require "dist.manifest"
local log	    = require "dist.log"

--- Fetch and unpack zip/dist from URL into dest directory.
-- @param url string: Local packed dist or URL to fetch dist from.
-- @param dest string: Destination to unpack contents into, nil for temp directory.
-- @return path, log: Unpacked dist path or nil and log.
function unpack(url, dest)
	-- Make sure dest is set up properly
	dest = sys.path(dest) or config.temp

	-- Check types
	assert(type(url)=="string", "package.unpack: Argument 'url' is not a string.")
	assert(type(dest)=="string", "package.unpack: Argument 'dest' is not a string.")	

	-- Setup destination
	local name = url:match("([^/]+)%.[^%.]+$")
	if not name then return nil, "Could not determine dist name from " .. url end
	local pkg = sys.path(dest, name)
	local dist = pkg .. ".dist"

	-- If the files already exist
	if sys.exists(pkg) then return pkg, "Skipped unpack, destination " .. dest .. " exists." end
	
	-- Download if needed 
	if not sys.exists(dist) then
		-- Download from URL or local path. Fetch handles this
		dist = fetch.download(url)
		if not dist then return nil, "Failed to download " .. url end
	end
	
	-- Unzip
	local ok = sys.unzip(dist, pkg)
	if not ok then return nil, "Failed to unzip " .. dist .. " to " .. pkg end
	
	-- Cleanup
	if not config.debug then sys.delete(dist) end
	
	return pkg, "Unpacked " .. url .. " to " .. pkg
end

--- Build, deploy and test a source dist using CMake.
-- @param dist string: Directory of the source dist to build.
-- @param variables: Table containing optional CMake parameters.
-- @return path, log: Returns temporary directory the dist was build into and log message.
function build(dist, depl, variables)
	-- Make sure deployment is always set up
	depl = sys.path(depl) or config.root
	
	assert(type(dist)=="string", "package.build: Arument 'dist' is not a string.")
	assert(type(depl)=="string", "package.build: Argument 'depl' is not a string.")
	assert(type(variables)=="table", "package.build: Argument 'variables' is not a table.")

	-- Load dist info
	local info = manif.info(sys.path(dist, "dist.info"))
	if not info then return nil, "Directory " .. dist .. " does not contain valid dist.info." end
	
	-- Prepare temporary directory and build directory
	local install = sys.path(config.temp,info.name .. "-" .. info.version .. "-" .. config.arch .. "-" .. config.type)
	local build = sys.path(config.temp,info.name .. "-" .. info.version .. "-CMake-build")
	sys.makeDir(install)
	sys.makeDir(build)

	-- Prepare CMackeCache
	variables["CMAKE_INSTALL_PREFIX"] = install
	
	local cache = assert(io.open(build..'/cache.cmake', "w"), "Could not create cache file.")
	for k,v in pairs(variables) do
		cache:write('SET('..k..' "' .. tostring(v) ..'" CACHE STRING "" FORCE)\n')
	end
	cache:close()

	-- Determine build commands
	local make = config.make
	local cmake = config.cmake
	local ctest = config.ctest
	if config.debug then 
		make = config.makeDebug 
		cmake = config.cmakeDebug
		ctest = config.ctestDebug
	end
	
	-- Build
	local ok = sys.execute("cd " .. sys.Q(build) .. " && " .. cmake .. " -C cache.cmake " .. sys.Q(dist))
	if not ok then return nil, "CMake failed pre-cmake script in directory " .. build end
	local ok = sys.execute("cd " .. sys.Q(build) .. " && " .. make)
	if not ok then return nil, "CMake failed building in directory " .. build end
	if config.test then
		local ok = sys.execute("cd " .. sys.Q(build) .. " && " .. ctest)
		if not ok then return nil, "CMake failed test in directory " .. build end
	end

	-- Save info
	info.arch = config.arch
	info.type = config.type
	local ok = persist.save(sys.path(install, "dist.info"), info  )
	if not ok then return nil, "Cannot wite dist.info to" .. fullDist end

	-- Deploy the dist
	local ok, err = deploy(install, depl)
	if not ok then return nil, err end

	-- Clean up
	if not config.debug then sys.delete(build) sys.delete(install) end
	
	return install, "Successfully built dist in " .. install
end

--- Deploy dist into deployment directory.
-- @param dist string: Directory of the dist to deploy.
-- @param depl string: Deployment directory nil for default.
-- @return ok, log: Returns true on success and log message.
function deploy(dist, depl)
	-- Make sure deployment is always set up
	depl = sys.path(depl) or config.root
	
	assert(type(dist)=="string", "package.deploy: Argument 'dist' is not a string.")
	assert(type(depl)=="string", "package.deploy: Argument 'depl' is not a string.")

	-- Load dist info
	local info = manif.info(sys.path(dist, "dist.info"))
	if not info then return nil, "Directory " .. dist .. " does not contain valid dist.info" end

	-- Relative and full path to dist deployment
	local distRel = config.dists .. "/" .. info.name .. "-" .. info.version
	local distPath = sys.path(depl, distRel)
    
    -- If we are deploying a dist into itself
    if distPath == dist then return 
        true, "Skipping, already deployed"
    end

	-- Copy to install dir
	sys.makeDir(depl)
	sys.makeDir(distPath)
	
	-- Collect files to process
	local files = sys.list(dist)

	-- Simple copy deployment
	for i = 1, #files do
		local file = files[i]
		if file~="dist.info" then
			local path = sys.path(dist, file)
			-- Create directory in depl
			if sys.isDir(path) then
				local ok, err = sys.makeDir(sys.path(depl, file))
				if not ok then return nil, "Failed to install " .. dist .. "/" .. file .. " to " .. depl end
			-- Copy files to depl
			else
				local ok, err = sys.copy(sys.path(dist, file), sys.path(depl, file))
				if not ok then return nil, "Failed to install " .. dist .. "/" .. file .. " to " .. depl end
			end
		end
	end		
	
	-- Modify and save dist.info
	info.files = files

	local ok = persist.save(sys.path(distPath, "dist.info"), info)
	if not ok then return nil, "Cannot wite dist.info to" .. distPath end
	
	return true, "Successfully deployed dist to " .. depl
end

--- Pack a package to create a dist.
-- @param dist string: deployed dist to pack.
-- @param depl string: deployment dir to pack from.
-- @param dir string: Optional destination for the dist, current directory will be used by default.
-- @return ok, log: Returns success and log message.
function pack(dist, depl, dir)
	depl = depl or dist
	assert(type(dist)=="string", "package.pack: Argument 'dist' is not a string.")
	assert(not dir or type(dir)=="string", "package.pack: Argument 'dir' is no a string.")
	if not dir then dir = sys.curDir() end

	-- Get the manifest of the dist
	local info = manif.info(sys.path(dist, "dist.info"))
	if not info then return nil, "Dist does not contain valid dist.info in " .. dist  end

	-- Create temporary folder
	local pkg = info.name .. "-" .. info.version .. "-" .. info.arch .. "-" .. info.type
	if info.arch == "Universal" and info.type == "source" then
		pkg = info.name .. "-" .. info.version
	end

	local tmp = sys.path(config.temp, pkg)
	sys.makeDir(tmp)

	-- Copy dist files into temporary folder
	local files = info.files or sys.list(dist)
	if not files then return nil, "Failed to collect files for dist in " .. dist end
	
	for i = 1, #files do
		local file = files[i]
		if sys.isDir(sys.path(depl, file)) then 
			sys.makeDir(sys.path(tmp, file))
		elseif file ~= "dist.info" then
			local ok = sys.copy(sys.path(depl, file), sys.path(tmp, file))
			if not ok then return nil, "Pack failed to copy file " .. file end
		end
	end
	
	-- Clean obsolete dist.info entries
	info.path = nil
	info.files = nil
	local ok, err = persist.save(sys.path(tmp, "dist.info"), info)
	if not ok then return nil, "Could not update dist.info." end
		
	-- Zip dist files in the temporary folder. The zip will be placed into LuaDist/tmp folder
	-- This cleans up .git .svn and Mac .DS_Store files.
	local ok = sys.zip(config.temp, pkg .. ".dist", pkg, '-x "*.git*" -x "*.svn*" -x "*~" -x "*.DS_Store*"')
	if not ok then return nil, "Failed to compress files in" .. pkg end
	local ok = sys.move(tmp .. ".dist", dir .. "/") -- Adding the "/" gets around ambiguity issues on Windows.
	if not ok then return nil, "Could not move dist to target directory " .. dir end

	-- Remove the temporary folder
	if not config.debug then sys.delete(tmp) end
	return true, "Sucessfully packed dist " .. dist .. " to " .. dir
end

--- Delete a deployed dist.
-- @param dist string: dist to delete.
-- @param depl string: deployment dir to delete from.
-- @return ok, log: Returns success and nlog message.
function delete(dist, depl)
	assert(type(dist)=="string", "package.delete: Argument 'dist' is not a string.")
	assert(type(dist)=="string", "package.delete: Argument 'depl' is not a string.")
	
	-- Get the manifest of the dist
	local info = manif.info(sys.path(dist, "dist.info"))
	if not info then return nil, "Dist does not contain valid dist.info in " .. dist  end

	-- Delete installed files
	local files = info.files
	if not files then return nil, "Failed to collect files for dist in " .. dist end
	
	-- Remove list backwards to empty dirs 1st.
	for i = #files, 1, -1 do
		local file = sys.path(depl, files[i])
		-- Delete deployed file
		if sys.isFile(file) then
			sys.delete(file)
		end
		-- Delete empty directories
		if sys.isDir(file) then
			local contents = sys.dir(file)
			if #contents == 0 then
				sys.delete(file)
			end
		end
	end
	
	-- Delete dist directory
	local ok = sys.delete(dist)
	if not ok then return nil, "Deleting dist files failed in " .. dist end
		
	return true, "Successfully removed dist " .. dist
end
