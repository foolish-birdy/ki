----------------------------------------------------------------------------------------------------
-- Spotify application
--
local Application = spoon.Ki.Application
local Spotify = Application:new("Spotify")

-- Initialize menu item events
Spotify.search = Application.createMenuItemEvent("Search", { focusAfter = true })
Spotify.newPlaylist = Application.createMenuItemEvent("New Playlist", { focusAfter = true })
Spotify.newPlaylistFolder = Application.createMenuItemEvent("New Playlist Folder", { focusAfter = true })

-- Action to play or pause the current song
function Spotify.togglePlay()
    hs.spotify.playpause()
    return false
end

-- Action to play the previous song
function Spotify.playPrevious()
    hs.spotify.previous()
    return false
end

-- Action to play the next song
function Spotify.playNext()
    hs.spotify.next()
    return false
end

-- Action to stop the currently playing song
function Spotify.stop()
    hs.spotify.pause()
    return false
end

Spotify:registerShortcuts({
    { nil, "space", Spotify.togglePlay, { "Playback", "Toggle Play" } },
    { nil, "p", Spotify.playPrevious, { "Playback", "Previous" } },
    { nil, "n", Spotify.playNext, { "Playback", "Next" } },
    { nil, "s", Spotify.stop, { "Playback", "Stop" } },
    { nil, "l", Spotify.search, { "Edit", "Search" } },
    { { "shift" }, "n", Spotify.newPlaylist, { "File", "New Playlist" } },
    { { "shift" }, "f", Spotify.search, { "Edit", "Search" } },
    { { "cmd", "shift" }, "n", Spotify.newPlaylistFolder, { "File", "New Playlist Folder" } },
})

return Spotify