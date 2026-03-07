Name = "snapshots"
NamePretty = "Snapshots"
FixedOrder = true
HideFromProviderlist = true
Icon = "󰆚"
Parent = "system"

function GetEntries()
	return {
		{
			Text = "Manage Snapshots (GUI)",
			Icon = "󰍹",
			Actions = {
				activate = "snapshot gui",
			},
		},
		{
			Text = "Create Manual Snapshot",
			Icon = "󰆚",
			Actions = {
				activate = "snapshot create 'Created manually via Elephant menu'",
			},
		},
		{
			Text = "List Snapshots",
			Icon = "",
			Actions = {
				activate = "ghostty --class=local.floating -e bash -c 'snapshot list; echo \"\"; read -p \"Press Enter to close\"'",
			},
		},
	}
end
