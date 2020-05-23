--- === Website ===
---
--- Website class that subclasses [Entity](Entity.html) to represent some automatable website entity
---
local File = require("file")
local Entity = require("entity")
local Cheatsheet = require("cheatsheet")
local Website = Entity:subclass("Website")
local spoonPath = hs.spoons.scriptPath()

--- Website.links
--- Variable
--- An array of website links used in the default [`Website:getSelectionItems`](#getSelectionItems) method (defaults to an empty list). Any of the following values can be inserted:
---  * A complete URL string, i.e. `"https://translate.google.com"`
---  * A URL path string that can be appended to the website entity's initialized URL, i.e. `"/calendar"`
---  * A table containing a `name` string and `link` field that can be either the complete URL string or URL path, i.e.
---  ```
---  { name = "Google Translate", link = "https://translate.google.com" }
---  ```
Website.links = {}

--- Website.displaySelectionModalIcons
--- Variable
--- A boolean value to specify whether to show favicons in the selection modal or not. Defaults to `true`.
Website.displaySelectionModalIcons = true

--- Website.behaviors
--- Variable
--- Website [behaviors](Entity.html#behaviors) defined to invoke event handlers with the URL of the website.
--- Currently supported behaviors:
--- * `default` - Simply triggers the event handler with the initialized website url
--- * `select` - Generates a list of choice items from [`Website:getSelectionItems`](#getSelectionItems) and displays them in a selection modal for selection
--- * `website` - Triggers the appropriate event handler for the website. Depending on whether the workflow includes select mode, the select mode behavior will be triggered instead
Website.behaviors = Entity.behaviors + {
    default = function(self, eventHandler)
        eventHandler(self.url)
        return true
    end,
    select = function(self, eventHandler)
        local choices = self:getSelectionItems()

        if choices and #choices > 0 then
            local function onSelection(choice)
                if choice then
                    eventHandler(choice.url or self.url, choice)
                end
            end

            self:showSelectionModal(choices, onSelection)
        end

        return true
    end,
    website = function(self, eventHandler, _, _, workflow)
        local shouldSelect = false

        for _, event in pairs(workflow) do
            if event.mode == "select" then
                shouldSelect = true
                break
            end
        end

        if shouldSelect and Website.behaviors.select then
            return Website.behaviors.select(self, eventHandler)
        end

        return self.behaviors.default(self, eventHandler)
    end,
}

--- Website:getDomain(url) -> string
--- Method
--- Retrieves the domain part of the url argument
---
--- Parameters:
---  * `url` - The url string
---
--- Returns:
---   * The string domain of the url or `nil`
function Website.getDomain(url)
    return url:match("[%w%.]*%.(%w+%.%w+)") or url:match("[%w%.]*%/(%w+%.%w+)")
end

--- Website:getSelectionItems() -> table of choices or nil
--- Method
--- Generates a list of selection items using the instance's [`Website.links`](Website.html#links) list. Each item will display the page favicon if the [`Website.displaySelectionModalIcons`](Website.html#displaySelectionModalIcons) option is set to `true`.
---
--- Returns:
---   * A list of choice objects
function Website:getSelectionItems()
    local choices = {}

    for index, link in pairs(self.links) do
        local linkStr = link.link or link

        if string.sub(linkStr, 1, 1) == "/" then
            linkStr = self.url..linkStr
        end

        local choice = {}

        if link.name and link.link then
            choice.text = link.name
            choice.subText = linkStr
            choice.url = linkStr
        else
            choice.text = linkStr
            choice.url = linkStr
        end

        if self.displaySelectionModalIcons then
            local domain = self.getDomain(linkStr)

            if domain then
                local favicon = "http://www.google.com/s2/favicons?domain_url="..domain

                -- Asynchronously load favicon images individually per selection item
                hs.image.imageFromURL(favicon, function(image)
                    if not self.selectionModal then
                        return
                    end

                    if choices[index] then
                        choices[index].image = image
                        self.selectionModal:choices(choices)
                    end
                end)
            end
        end

        table.insert(choices, choice)
    end

    return choices
end

--- Website:openWith(url)
--- Method
--- Opens a URL with an application selected from a modal
---
--- Parameters:
---  * `url` - the target url that should be opened with the selected application
---
--- Returns:
---   * None
function Website:openWith(url)
    local allApplicationsPath = spoonPath.."/bin/AllApplications"
    local shellscript = allApplicationsPath.." -path \".empty.webloc\""
    local output = hs.execute(shellscript)
    local choices = File.createFileChoices(string.gmatch(output, "[^\n]+"))

    local function onSelection(choice)
        if not choice then return end

        hs.execute("open -a \""..choice.fileName.."\" "..url)
    end

    -- Defer execution to avoid conflicts with the prior selection modal that just closed
    hs.timer.doAfter(0, function()
        self:showSelectionModal(choices, onSelection, {
            placeholderText = "Open with application",
        })
    end)
end

--- Website:initialize(name, url, links, shortcuts)
--- Method
--- Initializes a new website entity instance with its name, url, links, and custom shortcuts. By default, a cheatsheet and common shortcuts are initialized.
---
--- Parameters:
---  * `name` - The name of the website
---  * `url` - The website URL
---  * `links` - Related links to initialize [`Website.links`](#links)
---  * `shortcuts` - The list of shortcuts containing keybindings and actions for the url entity
---
--- Returns:
---  * None
function Website:initialize(name, url, links, shortcuts)
    local commonShortcuts = {
        { nil, nil, self.open, { url, "Open Website" } },
        { { "shift" }, "o", function(...) self:openWith(...) end, { name, "Open Website with Application" } },
        { { "shift" }, "/", function() self.cheatsheet:show() end, { name, "Show Cheatsheet" } },
    }

    local mergedShortcuts = self:mergeShortcuts(shortcuts, commonShortcuts)

    self.url = url
    self.name = name
    self.links = links
    self.shortcuts = mergedShortcuts

    local cheatsheetDescription = "Ki shortcut keybindings registered for "..self.name
    self.cheatsheet = Cheatsheet:new(self.name, cheatsheetDescription, mergedShortcuts)
end

--- Website:open(url)
--- Method
--- Opens the url
---
--- Parameters:
---  * `url` - the address of the url to open
---
--- Returns:
---   * None
function Website.open(url)
    if not url then return nil end

    hs.urlevent.openURL(url)
end

return Website