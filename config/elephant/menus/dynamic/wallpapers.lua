Name = "wallpapers"
NamePretty = "Wallpapers"
HideFromProviderlist = true
Cache = false

function SetWallpaper(value)
	os.execute("theme-set --wallpaper '" .. value .. "' &")
end

function ScanDir(dir, label, entries)
	local handle = io.popen(
		"find -L '"
			.. dir
			.. "' -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort"
	)

	if handle then
		for line in handle:lines() do
			local filename = line:match("([^/]+)$")
			if filename then
				table.insert(entries, {
					Text = filename:gsub("%.[^.]+$", ""),
					Sub = label,
					Value = line,
					Preview = line,
					PreviewType = "file",
					Actions = {
						apply = "lua:SetWallpaper",
					},
				})
			end
		end
		handle:close()
	end
end

function GetEntries()
	local entries = {}
	local home = os.getenv("HOME") or ""
	local themes_dir = home .. "/.local/share/dotfiles/themes"

	-- Scan all theme backgrounds
	local theme_handle = io.popen("find '" .. themes_dir .. "' -maxdepth 1 -mindepth 1 -type d | sort")
	if theme_handle then
		for theme_path in theme_handle:lines() do
			local theme_name = theme_path:match("([^/]+)$")
			local bg_dir = theme_path .. "/backgrounds"
			ScanDir(bg_dir, "Theme: " .. theme_name, entries)
		end
		theme_handle:close()
	end

	-- Scan custom wallpapers directory
	local custom_dir = home .. "/Pictures/Wallpapers"
	ScanDir(custom_dir, "Custom", entries)

	-- Also scan ~/Pictures/dotfiles-wallpapers (used by Tinte)
	local tinte_dir = home .. "/Pictures/dotfiles-wallpapers"
	ScanDir(tinte_dir, "Tinte", entries)

	return entries
end

