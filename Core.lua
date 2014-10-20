-- ADD COMPATIBILITY WITH BAGNON: CHECK IF BAGNON IS LOADED AND IF SO, SET THE BUTTON UP ON ITS INTERFACE, DO NOT MANUALLY LOAD GBANK AT START.

local addon, ns = ...
local addon_prefix = "|cff00ff00Pro-Log Guild: |r"

-- -- -- -- -- LOCALIZATION -- -- -- -- --
ns.Localization = setmetatable({}, {__index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end})

ns.Locale = GetLocale()
local L = ns.Localization

-- -- -- -- -- VARIABLES -- -- -- -- --
local db
local loaded
local first = true
local query_counter, log_table, guild, date_str

-- -- -- -- -- SLASH COMMAND -- -- -- -- --
SLASH_PROLOGGUILD1 = "/plg"

function SlashCmdList.PROLOGGUILD(msg)
	ns.events:ShowFrame()
end

-- -- -- -- -- EVENT FRAME -- -- -- -- --
local events = CreateFrame("Frame", "ProLogGuildFrame", UIParent)
	  events:RegisterEvent("ADDON_LOADED")
	  events:SetScript("OnEvent", function(self, event, ...)
		  return self[event] and self[event](self, event, ...)
	  end)
	  events:Hide()
	  ns.events = events

-- -- -- -- -- EVENT FUNCTIONS: ADDON_LOADED -- -- -- -- --
function events:ADDON_LOADED(event, addon)
	local has_bagnon = false

	if addon == "Bagnon_GuildBank" then
		events:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
	elseif addon == "ProLogGuild" then
		ProLogGuildDB = ProLogGuildDB or {
			Settings = {},
			Transactions = {},
			Active = {["page"] = "transactions_tab", ["guild"] = false, ["log"] = false, ["tab"] = false}
		}

		db = ProLogGuildDB

		db.Settings = db.Settings or {}
		db.Transactions = db.Transactions or {}
		db.Active = db.Active or {["page"] = "transactions_tab", ["guild"] = false, ["log"] = false, ["tab"] = false}
		db.Active["page"] = db.Active["page"] or "transactions_tab"
		db.Active["guild"] = db.Active["guild"] or false
		db.Active["log"] = db.Active["log"] or false
		db.Active["tab"] = db.Active["tab"] or false

		print(addon_prefix .. L["Use the command \"/plg\" to open the review window."])
	elseif addon == "Blizzard_GuildBankUI" then
		local scan_btn = CreateFrame("Button", "scan_btn", GuildBankFrame, "UIPanelButtonTemplate")
			  scan_btn:SetFrameStrata("MEDIUM")
			  scan_btn:SetSize(100, 21)
			  scan_btn:SetText(L["Scan Bank"])
			  scan_btn:SetPoint("BOTTOMLEFT", GuildBankFrame, "BOTTOMLEFT", 11, 31)
			  scan_btn:SetScript("OnClick", function()
			  		if not loaded then
			  			events:CreateDisplay()
			  			events:Hide()
			  		end
			  		events:ScanLogs()
			  end)
			  ns.scan_btn = scan_btn
	end
end

function events:GUILDBANKBAGSLOTS_CHANGED(...)
	local scan_btn = CreateFrame("Button", "scan_btn", BagnonFrameguildbank.brokerDisplay or BagnonFrameguildbank, "UIPanelButtonTemplate")
		  scan_btn:SetSize(100, 21)
		  scan_btn:SetToplevel(true)
		  scan_btn:SetText(L["Scan Bank"])
		  scan_btn:SetPoint("CENTER", BagnonFrameguildbank, "BOTTOM", 0, 17)
		  scan_btn:SetScript("OnClick", function()
		  		if not loaded then
		  			events:CreateDisplay()
		  			events:Hide()
		  		end
		  		events:ScanLogs()
		  end)
		  ns.scan_btn = scan_btn

	events:UnregisterEvent("GUILDBANKBAGSLOTS_CHANGED")
end

-- -- -- -- -- FUNCTIONS: PAIRS BY KEYS -- -- -- -- --
events.pairsByKeys = function(_, t, f)
	local a = {}
		for n in pairs(t) do table.insert(a, n) end
		table.sort(a, f)
		local i = 0      -- iterator variable
		local iter = function ()   -- iterator function
			i = i + 1
			if a[i] == nil then return nil
			else return a[i], t[a[i]]
			end
		end
	return iter
end

-- -- -- -- -- FUNCTIONS: SHOW FRAME -- -- -- -- --
function events:ShowFrame()
	local self = events

	if loaded then
		if self:IsVisible() then self:Hide() else self:Show() end
	else
		self:CreateDisplay()
	end
end

-- -- -- -- -- FUNCTIONS: GENERATE FRAME -- -- -- -- --
function events:CreateDisplay()
	local self = events

	db.Active["page"] = "transactions_tab"
	db.Active["guild"] = false
	db.Active["log"] = false
	db.Active["tab"] = false

	self:EnableMouse(true)
	self:SetMovable(true)
	self:SetToplevel(true)

	-- -- TEXTURES -- --
	self.textures = {
		{point = "TOPLEFT", file = "BID-TOPLEFT", w = 256, h = 256, x = 0, y = 0},
		{point = "TOP", file = "AUCTION-TOP", w = 320, h = 256, x = 256, y = 0},
		{point = "TOPRIGHT", file = "AUCTION-TOPRIGHT", w = 256, h = 256, x = 0, y = 0, anchor = "TOP"},
		{point = "BOTTOMLEFT", file = "BID-BOTLEFT", w = 256, h = 256, x = 0, y = -256},
		{point = "BOTTOM", file = "AUCTION-BOT", w = 320, h = 256, x = 256, y = -256},
		{point = "BOTTOMRIGHT", file = "BID-BOTRIGHT", w = 256, h = 256, x = 0, y = 0, anchor = "BOTTOM"},
	}

	for k, v in pairs(self.textures) do
		self[v.point] = self:CreateTexture(nil, "BACKGROUND")
		self[v.point]:SetSize(v.w, v.h)
		self[v.point]:SetTexture("Interface\\AUCTIONFRAME\\UI-AUCTIONFRAME-" .. v.file .. ".BLP")
		if v.anchor then
			self[v.point]:SetPoint("TOPLEFT", self[v.anchor], "TOPRIGHT", v.x, v.y)
		else
			self[v.point]:SetPoint("TOPLEFT", v.x, v.y)
		end
	end

	local portrait = self:CreateTexture(nil, "BACKGROUND")
		  portrait:SetHeight(58)
		  portrait:SetWidth(58)
		  portrait:SetPoint("TOPLEFT", 8, -7)
		  SetPortraitTexture(portrait, "player")

	-- -- TITLE -- --
	local title_region = self:CreateTitleRegion()
		  title_region:SetPoint("CENTER", self, "TOP", 0, -30)
		  title_region:SetSize(832, 45)

	local title = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		  title:SetText(L["Pro-Log Guild"])
		  title:SetPoint("TOPLEFT", 85, -18)
	
	-- -- BUTTONS -- --
	local close_btn = CreateFrame("Button", nil, self, "UIPanelCloseButton")
	      close_btn:SetPoint("TOPRIGHT", 3, -8)

	local delete_all = CreateFrame("Button", "delete_all", self, "UIPanelButtonTemplate")
		  delete_all:SetSize(80, 22)
		  delete_all:SetText(L["Delete All"])
		  delete_all:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -8, 16)
		  delete_all:SetScript("OnClick", function()
		  		StaticPopup_Show("PLG_DeleteAllConfirmation")
		  end)
		  if events:CountLogs() == 0 and events:CountGuilds() == 0 then delete_all:Disable() end

	local delete_btn = CreateFrame("Button", "delete_btn", self, "UIPanelButtonTemplate")
		  delete_btn:SetSize(80, 22)
		  delete_btn:SetText(L["Delete"])
		  delete_btn:SetPoint("RIGHT", delete_all, "LEFT", 0, 0)
		  delete_btn:SetScript("OnClick", function()
		  		StaticPopup_Show("PLG_DeleteConfirmation")
		  end)
		  if events:CountLogs() == 0 or not db.Active.log then delete_btn:Disable() end
	
	local export_btn = CreateFrame("Button", "export_btn", self, "UIPanelButtonTemplate")
		  export_btn:SetSize(80, 22)
		  export_btn:SetText(L["Export"])
		  export_btn:SetPoint("RIGHT", delete_btn, "LEFT", 0, 0)
		  export_btn:Disable() -- Until I create the button script...

	local copy_btn = CreateFrame("Button", "copy_btn", self)
		  copy_btn:SetSize(16, 16)  
		  copy_btn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up.blp")
		  copy_btn:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up.blp")
		  copy_btn:SetDisabledTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Disabled.blp")
	      copy_btn:SetPoint("TOPRIGHT", self, "TOPRIGHT", -15, -45)
		  copy_btn:SetScript("OnClick", function()
		  		events:CopyText()
		  end)
		  if not db.Active.log then copy_btn:Disable() end

	-- -- TABS -- --
	self.tabs = {{"transactions_tab", "Item Transactions"}, {"money_tab", "Money Transactions"}, {"settings_tab", "Settings"}, {"help_tab", "Help"}}

	local counter = 0
	for k, v in pairs(self.tabs) do
		counter = counter + 1
		local tab = CreateFrame("Button", v[1], self, "CharacterFrameTabButtonTemplate")
			  tab:SetText(L[v[2]])
			  if counter == 1 then
 					tab:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 25, 12)
			  else
 					tab:SetPoint("LEFT", self.tabs[counter - 1][1], "RIGHT", -15, 0)
			  end
			  tab:SetScript("OnClick", function()
			  		self:SelectTab(v[1])
			  end)
			  self[v[1]] = tab

		if db.Active.page == v[1] then
			PanelTemplates_SelectTab(tab)
		else
			PanelTemplates_DeselectTab(tab)
		end
	end

	-- -- SCROLL FRAME/BAR -- --
	local scrollframe = CreateFrame("ScrollFrame", "scrollframe", self, "UIPanelScrollFrameTemplate")
		  scrollframe:SetSize(770, 325)
		  scrollframe:SetPoint("TOPLEFT", 25, -78)

	scrollframe.ScrollBar:EnableMouseWheel(true)
	scrollframe.ScrollBar:SetScript("OnMouseWheel", function(self, direction)
		ScrollFrameTemplate_OnMouseWheel(scrollframe, direction)
	end)

	local scrollframebg = scrollframe:CreateTexture(nil, "BACKGROUND", nil, -6)
		  scrollframebg:SetPoint("TOP")
		  scrollframebg:SetPoint("RIGHT", 25, 0)
		  scrollframebg:SetPoint("BOTTOM")
		  scrollframebg:SetWidth(26)
		  scrollframebg:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar.blp")
		  scrollframebg:SetTexCoord(0, 0.45, 0.1640625, 1)
		  scrollframebg:SetAlpha(0.5)

	local content = CreateFrame("Frame", nil, scrollframe)
		  content:SetSize(scrollframe:GetWidth(), scrollframe:GetHeight())
	
	scrollframe:SetScrollChild(content)
	self.scrollframe = scrollframe
	self.content = content

	self:SetSize(832, 447)
	self:SetPoint("CENTER", 0, 0)
	self:Show()

	-- -- DROPDOWNS: LOGS -- --
	local log_dropdown = CreateFrame("Frame", "log_dropdown", self, "UIDropDownMenuTemplate")
		  UIDropDownMenu_SetWidth(log_dropdown, 175)
		  UIDropDownMenu_SetText(log_dropdown, db["Active"].log or L["Select a log..."])
		  log_dropdown:SetPoint("TOPRIGHT", self, "TOPRIGHT", -25, -40)
		  db.log_dropdown = log_dropdown

	-- Set Values
	function log_dropdown:SetValue(selected)
		db["Active"].log = selected
		UIDropDownMenu_SetText(log_dropdown, db["Active"].log)

		if db["Active"].page == "transactions_tab" then
			events:DisplayTransactions("Tab 1")
			events:ResetGuildTabs()
		elseif db["Active"].page == "money_tab" then
			events:DisplayMoneyTransactions()
			events:ResetGuildTabs()
		end

		events:RefreshButtons()

		CloseDropDownMenus()
	end

	-- -- DROPDOWNS: GUILDS -- --
	local guild_dropdown = CreateFrame("Frame", "guild_dropdown", self, "UIDropDownMenuTemplate")
		  UIDropDownMenu_SetWidth(guild_dropdown, 175)
		  UIDropDownMenu_SetText(guild_dropdown, db["Active"].guild or L["Select a guild..."])
		  guild_dropdown:SetPoint("TOPRIGHT", log_dropdown, "TOPLEFT", 20, 0)

	UIDropDownMenu_Initialize(guild_dropdown, function(self, level, menuList)
		local info = UIDropDownMenu_CreateInfo()
		if (level or 1) == 1 then
			info.func = self.SetValue

			for k, v in events:pairsByKeys(db.Transactions) do
				info.text, info.arg1, info.menuList = k, k, k
				info.checked, info.hasArrow = db["Active"].guild == k, false
				UIDropDownMenu_AddButton(info)
			end
		end
	end)

	-- Set Values
	function guild_dropdown:SetValue(selected)
		db["Active"].guild = selected
		UIDropDownMenu_SetText(guild_dropdown, db["Active"].guild)

		if db["Active"].log then
			db["Active"].log = false
			UIDropDownMenu_SetText(log_dropdown, L["Select a log..."])
		end

		UIDropDownMenu_Initialize(log_dropdown, function(self, level, menuList)
			local info = UIDropDownMenu_CreateInfo()
			if (level or 1) == 1 then
				info.func = self.SetValue

				if db.Transactions[selected] then
					for k, v in events:pairsByKeys(db.Transactions[selected]) do
						info.text, info.arg1, info.menuList = k, k, k
						info.checked, info.hasArrow = db["Active"].log == k, false
						UIDropDownMenu_AddButton(info)
					end
				end
			end
		end)

		db["Active"].tab = 1
		events:ResetGuildTabs()
		events:RefreshButtons()
		events:ClearLogLines()

		CloseDropDownMenus()
	end

	-- -- TABS: TOP GUILD TAB BUTTONS -- --
	for i = 1, 8 do
		local tab = CreateFrame("Button", "guild_tabs_" .. i, self, "OptionsFrameTabButtonTemplate")
			  tab:SetText(i)
			  tab:Disable()
			  tab:SetScript("OnClick", function(self)
			  		db["Active"].tab = i
			  		events:DisplayTransactions("Tab " .. i)
			  		events:ResetGuildTabs()
			  end)
			  events["guild_tabs_" .. i] = tab
		
		PanelTemplates_TabResize(tab, 0)

		if i == 1 then
			tab:SetPoint("TOPLEFT", 70, -45)
		else
			tab:SetPoint("TOPLEFT", "guild_tabs_" .. (i - 1), "TOPRIGHT", -10, 0)
		end
	end

	loaded = true
end

-- -- -- -- -- FUNCTIONS: SELECT TAB -- -- -- -- --
function events:SelectTab(tab)
	local self = events

	for k, v in pairs(self.tabs) do
		PanelTemplates_DeselectTab(self[v[1]])
	end

	PanelTemplates_SelectTab(self[tab])

	db.Active.page = tab

	events:ClearLogLines()
	events:ClearSettingsElements()
	events:ClearHelpElements()
	
	if tab == "transactions_tab" then
		if db["Active"].log and db["Active"].tab then
			events:DisplayTransactions("Tab " .. db["Active"].tab)
		end
	elseif tab == "money_tab" then
		if db["Active"].log then
			events:DisplayMoneyTransactions()
		end
	elseif tab == "settings_tab" then
		events:DisplaySettings()
	elseif tab == "help_tab" then
		events:DisplayHelp()
	end

	events:ResetGuildTabs()
end

-- -- -- -- -- FUNCTIONS: COUNT LOGS -- -- -- -- --
function events:CountLogs()
	local counter = 0

	for k, v in pairs(db.Transactions) do
		for n in pairs(v) do
			counter = counter + 1
		end
	end

	return counter
end

-- -- -- -- -- FUNCTIONS: COUNT GUILDS -- -- -- -- --
function events:CountGuilds()
	local counter = 0

	for k, v in pairs(db.Transactions) do
		counter = counter + 1
	end

	return counter
end

-- -- -- -- -- FUNCTIONS: GET MAX TABS -- -- -- -- --
function events:GetMaxTabs()
	local i = 0
	for k, v in events:pairsByKeys(db.Transactions[db["Active"].guild][db["Active"].log].transactions) do
		i = i + 1
	end
	return i
end

-- -- -- -- -- FUNCTIONS: RESET GUILD TABS -- -- -- -- --
function events:ResetGuildTabs()
	local x = (db["Active"].log and db["Active"].page == "transactions_tab") and events:GetMaxTabs()

	for i = 1, 8 do
		events["guild_tabs_" .. i]:Disable()
	end
	if x then
		for i = 1, x do
			events["guild_tabs_" .. i]:Enable()
		end
	end

	if db["Active"].tab then
		events:HighlightGuildTab(db["Active"].tab)
	end
end

-- -- -- -- -- FUNCTIONS: HIGHLIGHT SELECTED GUILD TAB -- -- -- -- --
function events:HighlightGuildTab(x)
	events["guild_tabs_" .. db["Active"].tab]:Enable()
	events["guild_tabs_" .. x]:Disable()

	db["Active"].tab = x
end

-- -- -- -- -- FUNCTIONS: CLEAR LOG LINES -- -- -- -- --
function events:ClearLogLines()
	for i = 1, 26 do
		if events.content["line_" .. i] then
			events.content["line_" .. i]:SetFontObject("GameFontHighlight")
			events.content["line_" .. i]:ClearAllPoints()
			events.content["line_" .. i]:SetText()
			events.content["line_" .. i]:Hide()
		end
	end
end

-- -- -- -- -- FUNCTIONS: CLEAR SETTINGS -- -- -- -- --
function events:ClearSettingsElements()
	if events.settings then
		for k, v in pairs(events.settings) do
			v:ClearAllPoints()
			v:Hide()
		end
	end
end

-- -- -- -- -- FUNCTIONS: CLEAR HELP -- -- -- -- --
function events:ClearHelpElements()
	if events.help then
		for k, v in pairs(events.help) do
			v:ClearAllPoints()
			v:Hide()
		end
	end
end

local first_scan = true

-- -- -- -- -- FUNCTIONS: SCAN LOGS -- -- -- -- --
function events:ScanLogs()
	local self = events

	print(addon_prefix .. L["Beginning scan. Do not leave the bank until finished."])

	ns.scan_btn:Disable()
	StaticPopup_Show("PLG_Scanning")

	self:RegisterEvent("GUILDBANKLOG_UPDATE")

	query_counter = 0
	max_tabs = GetNumGuildBankTabs()

	guild = GetGuildInfo("player")
	date_str = date("%m/%d/%Y %H:%M:%S")

	db.Transactions[guild] = db.Transactions[guild] or {}
	db.Transactions[guild][date_str] = {transactions = {}, money_transactions = {}}

	db["Active"].page = "transactions_tab"
	db["Active"].tab = 1

	log_table = db.Transactions[guild][date_str]

	for i = 1, MAX_GUILDBANK_TABS do
		-- GuildBankFrameTab2:Click()
		SetCurrentGuildBankTab(i)
		QueryGuildBankLog(i)
	end

	QueryGuildBankLog(MAX_GUILDBANK_TABS + 1)
end

-- -- -- -- -- HOOKS: GUILDBANKLOG_UPDATE -- -- -- -- --
events:HookScript("OnEvent", function(self, event, ...)
	if event ~= "GUILDBANKLOG_UPDATE" then return end

    query_counter = query_counter + 1

	if first then
		if query_counter == max_tabs + 1 then
    		query_counter = 0
    		first = nil

    		QueryGuildBankLog(1)
    	elseif query_counter <= max_tabs then
    		QueryGuildBankLog(query_counter)
    	end
	else
    	if query_counter == max_tabs + 1 then
    		local num_transactions = GetNumGuildBankMoneyTransactions()
    		
    		for i = 1, num_transactions do
    			log_table.money_transactions[(num_transactions + 1) - i] = {GetGuildBankMoneyTransaction(i)}
    		end

    		events:UnregisterEvent("GUILDBANKLOG_UPDATE")

    		scan_btn:Enable()
			StaticPopup_Hide("PLG_Scanning")

			print(addon_prefix .. L["Scan finished."])

			guild_dropdown:SetValue(guild)
			log_dropdown:SetValue(date_str)

			events:Show()

			first_scan = nil
    	elseif query_counter <= max_tabs then
    		local num_transactions = GetNumGuildBankTransactions(query_counter)
    		
    		log_table.transactions["Tab " .. query_counter] = {}

    		for i = 1, num_transactions do
    			log_table.transactions["Tab " .. query_counter][(num_transactions + 1) - i] = {GetGuildBankTransaction(query_counter, i)}
    		end
    		
    		QueryGuildBankLog(query_counter)
    	end
    end
end)

-- -- -- -- -- FUNCTIONS: REFRESH BUTTONS -- -- -- -- --
function events:RefreshButtons()
	local self = events

	if self:CountLogs() == 0 then
		if events:CountGuilds() == 0 then
			delete_all:Disable()
		end
		delete_btn:Disable()
		copy_btn:Disable()
	elseif not db.Active.log then
		delete_all:Enable()
		delete_btn:Disable()
		copy_btn:Disable()
	else
		delete_all:Enable()
		delete_btn:Enable()
		copy_btn:Enable()
	end
end

-- -- -- -- -- BLIZZ CONSTANTS (ENGLISH)... IN CASE THEY ARE NOT AVAILABLE DUE TO NOT LOADING WITH BAGNON -- -- -- -- --
GUILDBANK_MOVE_FORMAT = GUILDBANK_MOVE_FORMAT or "%s moved %s x %d from %s to %s"
GUILD_BANK_LOG_TIME_PREPEND = GUILD_BANK_LOG_TIME_PREPEND or "|cff009999   "
GUILD_BANK_LOG_TIME = GUILD_BANK_LOG_TIME or "( %s ago )"
NORMAL_FONT_COLOR_CODE = NORMAL_FONT_COLOR_CODE or "|cffffd200"
UNKNOWN = UNKNOWN or "Unknown"
GUILDBANK_DEPOSIT_MONEY_FORMAT = GUILDBANK_DEPOSIT_MONEY_FORMAT or "%s deposited %s"
GUILDBANK_WITHDRAW_MONEY_FORMAT = GUILDBANK_WITHDRAW_MONEY_FORMAT or "%s |cffff2020withdrew|r %s"
GUILDBANK_REPAIR_MONEY_FORMAT = GUILDBANK_REPAIR_MONEY_FORMAT or "%s withdrew %s for repairs"
GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT = GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT or "%s withdrew %s to purchase a guild bank tab"
GUILDBANK_BUYTAB_MONEY_FORMAT = GUILDBANK_BUYTAB_MONEY_FORMAT or "%s purchased a guild bank tab for %s"
GUILDBANK_UNLOCKTAB_FORMAT = GUILDBANK_UNLOCKTAB_FORMAT or "%s unlocked a guild bank tab with a Guild Vault Voucher."
GUILDBANK_AWARD_MONEY_SUMMARY_FORMAT = GUILDBANK_AWARD_MONEY_SUMMARY_FORMAT or "A total of %s was deposited last week from Guild Perk: Cash Flow "
GUILDBANK_DEPOSIT_FORMAT = GUILDBANK_DEPOSIT_FORMAT or "%s deposited %s"
GUILDBANK_LOG_QUANTITY = GUILDBANK_LOG_QUANTITY or " x %d"
GUILDBANK_WITHDRAW_FORMAT = GUILDBANK_WITHDRAW_FORMAT or "%s |cffff2020withdrew|r %s"

-- -- -- -- -- FUNCTIONS: FORMAT LOG -- -- -- -- --
function events:FormatLogMsg(log, log_type, copy)
	local msg
	local type = log[1]
	local name = log[2]

	if not name then
		name = UNKNOWN
	end

	name = NORMAL_FONT_COLOR_CODE .. name .. FONT_COLOR_CODE_CLOSE

	if log_type == "money" then
		local money
		local amount = log[3]
		local year = log[4]
		local month = log[5]
		local day = log[6]
		local hour = log[7]

		money = GetDenominationsFromCopper(amount)

		if type == "deposit" then
			msg = format(GUILDBANK_DEPOSIT_MONEY_FORMAT, name, money)
		elseif type == "withdraw" then
			msg = format(GUILDBANK_WITHDRAW_MONEY_FORMAT, name, money)
		elseif type == "repair" then
			msg = format(GUILDBANK_REPAIR_MONEY_FORMAT, name, money)
		elseif type == "withdrawForTab" then
			msg = format(GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT, name, money)
		elseif type == "buyTab" then
			if amount > 0 then
				msg = format(GUILDBANK_BUYTAB_MONEY_FORMAT, name, money)
			else
				msg = format(GUILDBANK_UNLOCKTAB_FORMAT, name)
			end
		elseif type == "depositSummary" then
			msg = format(GUILDBANK_AWARD_MONEY_SUMMARY_FORMAT, money)
		end

		msg = msg .. GUILD_BANK_LOG_TIME_PREPEND .. format(GUILD_BANK_LOG_TIME, RecentTimeDate(year, month, day, hour))
	elseif log_type == "item" then
		local itemLink = log[3]
		local count = log[4]
		local tab1 = log[5]
		local tab2 = log[6]
		local year = log[7]
		local month = log[8]
		local day = log[9]
		local hour = log[10]

		if type == "deposit" then
			msg = format(GUILDBANK_DEPOSIT_FORMAT, name, itemLink)
			if count > 1 then
				msg = msg .. format(GUILDBANK_LOG_QUANTITY, count)
			end
		elseif type == "withdraw" then
			msg = format(GUILDBANK_WITHDRAW_FORMAT, name, itemLink)
			if count > 1 then
				msg = msg .. format(GUILDBANK_LOG_QUANTITY, count)
			end
		elseif type == "move" then
			msg = format(GUILDBANK_MOVE_FORMAT, name, itemLink, count, "tab " .. tab1, "tab " .. tab2)
		end

		msg = msg .. GUILD_BANK_LOG_TIME_PREPEND .. format(GUILD_BANK_LOG_TIME, RecentTimeDate(year, month, day, hour))
	end

	return msg
end

-- -- -- -- -- FUNCTIONS: DISPLAY LOGS: TRANSACTIONS -- -- -- -- --
function events:DisplayTransactions(tab)
	events:ClearLogLines()
	events:ClearSettingsElements()
	events:ClearHelpElements()

	local i = 1

	events.content["line_" .. i] = events.content["line_" .. i] or events.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	local line = events.content["line_" .. i]
		  line:SetText(L[tab])
		  line:SetWidth(events.content:GetWidth() - 20)
		  line:SetWordWrap(true)
		  line:SetFontObject("GameFontNormalLarge")
		  line:SetJustifyH("LEFT")
		  line:Show()
		  line:SetPoint("TOPLEFT", 10, -10)

	for k, v in pairs(db.Transactions[db["Active"].guild][db["Active"].log].transactions[tab]) do
		i = i + 1
		local msg = events:FormatLogMsg(v, "item")

		events.content["line_" .. i] = events.content["line_" .. i] or events.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		local line = events.content["line_" .. i]
			  line:SetText(msg)
			  line:SetWidth(events.content:GetWidth() - 20)
			  line:SetWordWrap(true)
			  line:SetJustifyH("LEFT")
			  line:Show()
			  line:SetPoint("TOPLEFT", events.content["line_" .. i - 1], "BOTTOMLEFT", 0, -5)
	end

	events:HighlightGuildTab(string.gsub(tab, "Tab ", ""))
end

-- -- -- -- -- FUNCTIONS: DISPLAY LOGS: MONEY TRANSACTIONS -- -- -- -- --
function events:DisplayMoneyTransactions()
	events:ClearLogLines()
	events:ClearSettingsElements()
	events:ClearHelpElements()

	local i = 0
	for k, v in pairs(db.Transactions[db["Active"].guild][db["Active"].log].money_transactions) do
		i = i + 1
		local msg = events:FormatLogMsg(v, "money")

		events.content["line_" .. i] = events.content["line_" .. i] or events.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		local line = events.content["line_" .. i]
			  line:SetText(msg)
			  line:SetWidth(events.content:GetWidth() - 20)
			  line:SetWordWrap(true)
			  line:SetJustifyH("LEFT")
			  line:Show()

		if i == 1 then
			line:SetPoint("TOPLEFT", 10, -10)
		else
			line:SetPoint("TOPLEFT", events.content["line_" .. i - 1], "BOTTOMLEFT", 0, -5)
		end
	end
end

-- -- -- -- -- FUNCTIONS: DISPLAY SETTINGS -- -- -- -- --
function events:DisplaySettings()
	events:ClearLogLines()
	events:ClearSettingsElements()
	events:ClearHelpElements()

	events.settings = events.settings or {}

	events.settings["description"] = events.settings["description"] or events.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	local desc = events.settings["description"]
		  desc:SetText(L["There are currently no settings available to change. If you have a request, please leave a comment on WoW Interface or Curse or email me at addons@niketa.net."])
		  desc:SetWidth(events.content:GetWidth() - 20)
		  desc:SetWordWrap(true)
		  desc:SetJustifyH("LEFT")
		  desc:Show()
		  desc:SetPoint("TOPLEFT", 10, -10)
end

-- -- -- -- -- FUNCTIONS: DISPLAY HELP -- -- -- -- --
function events:DisplayHelp()
	events:ClearLogLines()
	events:ClearSettingsElements()
	events:ClearHelpElements()

	events.help = events.help or {}

	events.help["description"] = events.help["description"] or events.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	local desc = events.help["description"]
		  desc:SetText(L["If you need assistance with the addon, please leave a comment on either WoW Interface or Curse or email me at addons@niketa.net. If there are any questions coming in, I will add them to this section for others to reference."])
		  desc:SetWidth(events.content:GetWidth() - 20)
		  desc:SetWordWrap(true)
		  desc:SetJustifyH("LEFT")
		  desc:Show()
		  desc:SetPoint("TOPLEFT", 10, -10)
end

-- -- -- -- -- FUNCTIONS: COPY TEXT -- -- -- -- --
function events:CopyText()
	if db["Active"].page ~= "transactions_tab" and db["Active"].page ~= "money_tab" then
		return false
	end

	local msg = ""

	for i = 1, 25 do
		if events.content["line_" .. i] then
			if events.content["line_" .. i]:GetText() ~= "" then
				msg = msg ~= "" and msg .. "\n" .. events.content["line_" .. i]:GetText() or events.content["line_" .. i]:GetText()
			end
		end
	end

	if not events.copy_frame then
		events.copy_frame = CreateFrame("Frame", "copy_frame", UIParent)
		local frame = events.copy_frame
			  frame:SetPoint("CENTER", 0, 50)
			  frame:SetSize(450, 340)
			  frame:SetToplevel(true)
			  frame:SetFrameStrata("HIGH")
			  frame:EnableMouse(true)
			  frame:SetMovable(true)
			  frame:SetBackdrop({
			  		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			  		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			  		edgeSize = 25,
			  		insets = {
				  		left = 8,
				  		right = 8,
				  		top = 8,
				  		bottom = 8
				  	}
			  })

		events.copy_editbox = CreateFrame("ScrollFrame", "copy_editbox", frame, "InputScrollFrameTemplate")
		local copy_editbox = events.copy_editbox
			  copy_editbox:SetSize(375, 250)
			  copy_editbox:SetPoint("TOP", 0, -30)
			  copy_editbox.EditBox:SetFontObject(GameFontHighlightSmall)
			  copy_editbox.EditBox:SetAutoFocus(true)
			  copy_editbox.EditBox:SetMultiLine(true)
			  copy_editbox.EditBox:SetMaxLetters(9000)
			  copy_editbox.EditBox:SetScript("OnEscapePressed", function(this)
				  this:SetText("")
				  this:ClearFocus()
				  events.copy_frame:Hide()
			  end)

		local copy_close = CreateFrame("Button", "copy_close", frame, "UIPanelButtonTemplate")
			  copy_close:SetSize(150, 25)
			  copy_close:SetText(L["Close"])
			  copy_close:SetPoint("TOP", copy_editbox, "BOTTOM", 0, -15)
			  copy_close:SetScript("OnClick", function(self)
			  		events.copy_frame:Hide()
			  end)
	end

	events.copy_editbox.EditBox:SetText(msg)
	events.copy_editbox.EditBox:SetFocus()
	events.copy_editbox.EditBox:HighlightText()
	events.copy_frame:Show()
end

-- -- -- -- -- STATIC POPUPS: DELETE ALL -- -- -- -- --
StaticPopupDialogs["PLG_DeleteAllConfirmation"] = {
  text = L["Are you sure you want to delete all logs?"],
  button1 = L["Delete"],
  button2 = L["Cancel"],
  OnAccept = function()
      table.wipe(db.Transactions)
	  print(addon_prefix .. L["All logs have been deleted."])
	  if db["Active"].guild then
	  		db["Active"].guild = false
	  		UIDropDownMenu_SetText(guild_dropdown, L["Select a guild..."])
	  end
	  if db["Active"].log then
	  		db["Active"].log = false
	  		UIDropDownMenu_SetText(log_dropdown, L["Select a log..."])
	  end
	  events:ClearLogLines()
	  events:ResetGuildTabs()
	  events:RefreshButtons()
  end,
  whileDead = true,
  hideOnEscape = true
}

-- -- -- -- -- STATIC POPUPS: DELETE -- -- -- -- --
StaticPopupDialogs["PLG_DeleteConfirmation"] = {
  text = L["Are you sure you want to delete this log?"],
  button1 = L["Delete"],
  button2 = L["Cancel"],
  OnAccept = function()
      db.Transactions[db["Active"].guild][db["Active"].log] = nil
	  print(addon_prefix .. L["The log has been deleted."])
	  if db["Active"].log then
	  		db["Active"].log = false
	  		UIDropDownMenu_SetText(log_dropdown, L["Select a log..."])
	  end
	  db["Active"].tab = 1
	  events:ClearLogLines()
	  events:ResetGuildTabs()
	  events:RefreshButtons()
  end,
  whileDead = true,
  hideOnEscape = true
}

-- -- -- -- -- STATIC POPUPS: SCAN STATUS -- -- -- -- --
StaticPopupDialogs["PLG_Scanning"] = {
  text = L["Scanning bank. Please wait... (If this process is taking too long - 15+ sec, you can try the following: cancel and scan again, click through some of the bank logs to expedite the process, or reload your UI.)"],
  button2 = "Cancel",
  OnCancel = function()
    events:UnregisterEvent("GUILDBANKLOG_UPDATE")
	first_scan = nil
	ns.scan_btn:Enable()
  end,
  whileDead = true,
  hideOnEscape = false
}
