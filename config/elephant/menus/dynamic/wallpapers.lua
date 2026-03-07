Name = "wallpapers"
NamePretty = "Wallpapers"
HideFromProviderlist = true
Cache = false
SearchName = true

local function ShellEscape(s)
	return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function FormatName(filename)
	local name = filename:gsub("^%d+", ""):gsub("^%-", "")
	name = name:gsub("%.[^%.]+$", "")
	name = name:gsub("[%-_]", " ")
	name = name:gsub("%S+", function(word)
		return word:sub(1, 1):upper() .. word:sub(2):lower()
	end)
	return name
end

local function ScanDir(dir, label, entries)
	local handle = io.popen(
		"find -L " .. ShellEscape(dir)
			.. " -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort"
	)
	if not handle then
		return
	end

	for line in handle:lines() do
		local filename = line:match("([^/]+)$")
		if filename then
			table.insert(entries, {
				Text = FormatName(filename),
				Sub = label,
				Preview = line,
				PreviewType = "file",
				Actions = {
					activate = "theme-set --wallpaper " .. ShellEscape(line),
				},
			})
		end
	end
	handle:close()
end

function GetEntries()
	local entries = {}
	local home = os.getenv("HOME") or ""
	local themes_dir = home .. "/.local/share/dotfiles/themes"

	-- Scan all theme backgrounds
	local theme_handle = io.popen("find " .. ShellEscape(themes_dir) .. " -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort")
	if theme_handle then
		for theme_path in theme_handle:lines() do
			local theme_name = theme_path:match("([^/]+)$")
			ScanDir(theme_path .. "/backgrounds", theme_name, entries)
		end
		theme_handle:close()
	end

	-- Scan custom wallpapers
	ScanDir(home .. "/Pictures/Wallpapers", "Custom", entries)
	ScanDir(home .. "/Pictures/dotfiles-wallpapers", "Tinte", entries)

	return entries
end
