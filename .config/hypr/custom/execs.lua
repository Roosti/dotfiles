-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

-- Restore the Wallpaper Engine selection saved by wallselect.
hl.on("hyprland.start", function()
    hl.exec_cmd("$HOME/.config/wallset-engine/wallpaper_startup.sh")
end)
