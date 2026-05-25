--!strict
-- StarterPlayer/StarterPlayerScripts/Client/UIController.client.lua
-- Copy into StarterPlayerScripts/Client when using Rojo mapping in default.project.json.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Shared.Packages.Roact)
local MenuTemplate = require(ReplicatedStorage.Shared.UI.Components.MenuTemplate)
local ThemeConfig = require(ReplicatedStorage.Shared.UI.Themes.ThemeConfig)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local themeNames = {
	"SciFi",
	"Fantasy",
	"ModernMinimal",
	"Cyberpunk",
	"Cartoon",
	"DarkFPS",
	"InventoryShop",
	"Lobby",
}

local currentThemeIndex = 1
local selectedNav = "Home"
local uiHandle: any

local function mountMenu()
	if uiHandle then
		Roact.unmount(uiHandle)
	end

	local themeName = themeNames[currentThemeIndex]
	local theme = ThemeConfig.GetTheme(themeName)

	local element = Roact.createElement(MenuTemplate, {
		theme = theme,
		title = string.format("Template Pack - %s", theme.name),
		contentTitle = string.format("Current Theme: %s", themeName),
		contentDescription = "Use primary/secondary/nav buttons to test hover + click tween animations.",
		navItems = { "Home", "Play", "Shop", "Loadout", "Settings" },
		selectedNav = selectedNav,
		onSelectNav = function(item)
			selectedNav = item
			mountMenu()
		end,
		onPrimary = function()
			currentThemeIndex = (currentThemeIndex % #themeNames) + 1
			mountMenu()
		end,
		onSecondary = function()
			currentThemeIndex -= 1
			if currentThemeIndex < 1 then
				currentThemeIndex = #themeNames
			end
			mountMenu()
		end,
		primaryText = "Next Theme",
		secondaryText = "Previous Theme",
		disabledText = "Disabled Button",
	})

	uiHandle = Roact.mount(element, playerGui, "TemplatePackMenu")
end

mountMenu()

-- How to add a new theme later:
-- 1) Add a new key in ReplicatedStorage/Shared/UI/Themes/ThemeConfig.lua with the same field shape.
-- 2) Append the theme key name to `themeNames` in this file.
-- 3) Optionally customize menu text/nav entries via MenuTemplate props.
