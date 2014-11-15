local Addon, ns = ...

local db = setmetatable({}, {__index = function(t, k)
    return _G["ProLogGuildDB"][k]
end})

local Frame = CreateFrame("Frame", Addon .. "Frame", UIParent)
Frame:SetScript("OnEvent", function(self, event, ...)
	return self[event] and self[event](self, event, ...)
end)

Frame:RegisterEvent("ADDON_LOADED")
Frame:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")

Frame:Hide()

ns.Frame = Frame
ns.db = db

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

local has_bagnon

function Frame:ADDON_LOADED(event, addon, ...)
	if addon == Addon then
		Frame:ValidateDB()

		db.ActiveGuild = false
		db.ActiveLog = false
		db.ActivePage = false
		db.ActiveTab = false
	elseif addon == "Bagnon_GuildBank" then
		has_bagnon = true
	end
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

local copy_lines = {}
local copy_loaded

function Frame:CopyText()
	if (db.ActivePage ~= "TransactionsTab" and db.ActivePage ~= "MoneyTab") or not db.ActiveGuild or not db.ActiveLog or not db.ActiveTab then
		return false
	end

	table.wipe(copy_lines)

	local transactions_table = db.ActivePage == "TransactionsTab" and db.Transactions[db.ActiveGuild][db.ActiveLog]["tab" .. db.ActiveTab] or db.Transactions[db.ActiveGuild][db.ActiveLog]["tab" .. db.Transactions[db.ActiveGuild][db.ActiveLog].MaxTabs + 1]

	for k, v in pairs(transactions_table.transactions) do
		local msg = Frame:FormatMsg(v, db.ActivePage == "TransactionsTab" and "item" or "money")

		if msg then
			table.insert(copy_lines, msg)
		end
	end

	local msg = ""
	for k, v in pairs(copy_lines) do
		msg = msg ~= "" and msg .. "\n" .. v or v
	end

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

	local CopyFrame, CopyEditbox

	if not copy_loaded then
		CopyFrame = CreateFrame("Frame", Addon .. "CopyFrame", UIParent)
		CopyFrame:SetSize(450, 340)
		CopyFrame:SetPoint("CENTER", 0, 50)

		CopyFrame:SetToplevel(true)
		CopyFrame:SetFrameStrata("HIGH")
		CopyFrame:EnableMouse(true)
		CopyFrame:SetMovable(true)

		CopyFrame:SetBackdrop({
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

		Frame.CopyFrame = CopyFrame

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

		local CopyScrollFrame = CreateFrame("ScrollFrame", Addon .. "CopyScrollFrame", CopyFrame, "UIPanelScrollFrameTemplate")
		CopyScrollFrame:SetSize(375, 250)
		CopyScrollFrame:SetPoint("TOP", 0, -30)

	    CopyScrollFrame.ScrollBar:EnableMouseWheel(true)
	    CopyScrollFrame.ScrollBar:SetScript("OnMouseWheel", function(self, direction)
	        ScrollFrameTemplate_OnMouseWheel(CopyScrollFrame, direction)
	    end)

		local ScrollContent = CreateFrame("Frame", nil, CopyScrollFrame)
		ScrollContent:SetSize(CopyScrollFrame:GetWidth(), CopyScrollFrame:GetHeight())

		CopyFrame.ScrollFrame = CopyScrollFrame
		CopyScrollFrame.ScrollContent = ScrollContent
		CopyScrollFrame:SetScrollChild(ScrollContent)

		local CopyEditBox = CreateFrame("Editbox", "CopyEditBox", ScrollContent)
		CopyEditBox:SetScript("OnEscapePressed", function(this)
			this:SetText("")
			this:ClearFocus()
			Frame.CopyFrame:Hide()
		end)

		CopyEditBox:SetAllPoints(ScrollContent)

		CopyEditBox:SetFontObject(GameFontHighlightSmall)
		CopyEditBox:SetAutoFocus(true)
		CopyEditBox:SetMultiLine(true)
		CopyEditBox:SetMaxLetters(9000)

		Frame.CopyEditBox = CopyEditBox

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

		local CopyCloseBTN = CreateFrame("Button", Addon .. "CopyCloseBTN", CopyFrame, "UIPanelButtonTemplate")
		CopyCloseBTN:SetScript("OnClick", function(self)
			Frame.CopyFrame:Hide()
		end)

		CopyCloseBTN:SetSize(150, 25)
		CopyCloseBTN:SetPoint("TOP", CopyScrollFrame, "BOTTOM", 0, -15)

		CopyCloseBTN:SetText("Close")

		copy_loaded = true
	end

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

	Frame.CopyEditBox:SetText(msg)
	Frame.CopyEditBox:SetFocus()
	Frame.CopyEditBox:HighlightText()
	Frame.CopyFrame:Show()
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

function Frame:CountLogs(guild)
	local counter = 0
	local gcounter = 0

	if guild == "ALL_GUILDS" then
		for k, v in pairs(db.Transactions) do
			gcounter = gcounter + 1
		end
	elseif guild and db.Transactions[guild] then	
		for k, v in pairs(db.Transactions[guild]) do
			for a, b in pairs(v) do
				counter = counter + 1
			end
		end
	else
		for k, v in pairs(db.Transactions) do
			gcounter = gcounter + 1

			for a, b in pairs(v) do
				counter = counter + 1
			end
		end
	end

	return guild == "ALL_GUILDS" and gcounter or counter
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

local loaded

function Frame:CreateFrame(self)
	if loaded then
		self:RefreshButtons()
		self:Show()
		return
	end

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

	self:EnableMouse(true)
	self:SetMovable(true)
	self:SetToplevel(true)

	self:SetSize(832, 447)
	self:SetPoint("CENTER", 0, 0)

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

	self.Textures = {
		{point = "TOPLEFT", file = "BID-TOPLEFT", w = 256, h = 256, x = 0, y = 0},
		{point = "TOP", file = "AUCTION-TOP", w = 320, h = 256, x = 256, y = 0},
		{point = "TOPRIGHT", file = "AUCTION-TOPRIGHT", w = 256, h = 256, x = 0, y = 0, anchor = "TOP"},
		{point = "BOTTOMLEFT", file = "BID-BOTLEFT", w = 256, h = 256, x = 0, y = -256},
		{point = "BOTTOM", file = "AUCTION-BOT", w = 320, h = 256, x = 256, y = -256},
		{point = "BOTTOMRIGHT", file = "BID-BOTRIGHT", w = 256, h = 256, x = 0, y = 0, anchor = "BOTTOM"},
	}

	for k, v in pairs(self.Textures) do
		self[v.point] = self:CreateTexture(nil, "BACKGROUND")
		self[v.point]:SetSize(v.w, v.h)
		self[v.point]:SetTexture("Interface\\AUCTIONFRAME\\UI-AUCTIONFRAME-" .. v.file .. ".BLP")

		if v.anchor then
			self[v.point]:SetPoint("TOPLEFT", self[v.anchor], "TOPRIGHT", v.x, v.y)
		else
			self[v.point]:SetPoint("TOPLEFT", v.x, v.y)
		end
	end

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

	local Portrait = self:CreateTexture(nil, "BACKGROUND")
	Portrait:SetSize(58, 58)
	Portrait:SetPoint("TOPLEFT", 8, -7)
	SetPortraitTexture(Portrait, "player")

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

	local TitleRegion = self:CreateTitleRegion()
	TitleRegion:SetPoint("CENTER", self, "TOP", 0, -30)
	TitleRegion:SetSize(self:GetWidth(), 45)

	local TitleTXT = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	TitleTXT:SetText("PLG (Pro-Log Guild)")
	TitleTXT:SetPoint("TOPLEFT", 85, -18)

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --
	
	local CloseBTN = CreateFrame("Button", Addon .. "CloseBTN", self, "UIPanelCloseButton")
	CloseBTN:SetPoint("TOPRIGHT", 3, -8)

	local DeleteAllBTN = CreateFrame("Button", Addon .. "DeleteAllBTN", self, "UIPanelButtonTemplate")
	DeleteAllBTN:SetScript("OnClick", function()
		StaticPopup_Show("PLG_DeleteAllConfirmation")
	end)

	DeleteAllBTN:SetSize(80, 22)
	DeleteAllBTN:SetText("Delete All")
	DeleteAllBTN:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -8, 16)

	self.DeleteAllBTN = DeleteAllBTN

	local DeleteBTN = CreateFrame("Button", Addon .. "DeleteBTN", self, "UIPanelButtonTemplate")
	DeleteBTN:SetScript("OnClick", function()
		StaticPopup_Show("PLG_DeleteConfirmation")
	end)

	DeleteBTN:SetSize(80, 22)
	DeleteBTN:SetText("Delete")
	DeleteBTN:SetPoint("RIGHT", DeleteAllBTN, "LEFT", 0, 0)

	self.DeleteBTN = DeleteBTN

	local ExportBTN = CreateFrame("Button", Addon .. "ExportBTN", self, "UIPanelButtonTemplate")
	ExportBTN:SetScript("OnClick", function()
		self:Export()
	end)

	ExportBTN:SetSize(80, 22)
	ExportBTN:SetText("Export")
	ExportBTN:SetPoint("RIGHT", DeleteBTN, "LEFT", 0, 0)

	self.ExportBTN = ExportBTN

	local CopyBTN = CreateFrame("Button", Addon .. "CopyBTN", self)
	CopyBTN:SetScript("OnClick", function()
		self:CopyText()
	end)

	local texture = "Interface\\Buttons\\UI-GuildButton-PublicNote-%s.blp"
	CopyBTN:SetNormalTexture(string.format(texture, "Up"))
	CopyBTN:SetPushedTexture(string.format(texture, "Up"))
	CopyBTN:SetDisabledTexture(string.format(texture, "Disabled"))

	CopyBTN:SetSize(16, 16)
	CopyBTN:SetPoint("TOPRIGHT", self, "TOPRIGHT", -15, -45)

	self.CopyBTN = CopyBTN

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

	self.Tabs = {
		["Tab" .. 1] = {"TransactionsTab", "Item Transactions", 1},
		["Tab" .. 2] = {"MoneyTab", "Money Transactions", 2},
		["Tab" .. 3] = {"SettingsTab", "Settings", 3},
		["Tab" .. 4] = {"HelpTab", "Help", 4}
	}

	self.TabButtons = {}

	for k, v in self:pairsByKeys(self.Tabs) do
		local tab = CreateFrame("Button", Addon .. v[1], self, "CharacterFrameTabButtonTemplate")
		tab:SetScript("OnClick", function()
			self:SelectTab(v[1])
		end)

		tab:SetText(v[2])

		if k == "Tab1" then
			tab:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 25, 12)
		else
			tab:SetPoint("LEFT", Addon .. self.Tabs["Tab" .. v[3] - 1][1], "RIGHT", -15, 0)
		end

		self.TabButtons[v[1]] = tab
	end

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --
	
	self.GuildTabBTNs = {}

	for i = 1, MAX_GUILDBANK_TABS do
		local tab = CreateFrame("Button", Addon .. "GuildTabBTN" .. i, self, "OptionsFrameTabButtonTemplate")
		tab:SetScript("OnClick", function(self)
			Frame:LoadLogs(i)
		end)

		tab:SetText(i)
		tab:Disable()

		self["GuildTabBTNs" .. i] = tab
		
		PanelTemplates_TabResize(tab, 0)

		if i == 1 then
			tab:SetPoint("TOPLEFT", 70, -45)
		else
			tab:SetPoint("TOPLEFT", Addon .. "GuildTabBTN" .. (i - 1), "TOPRIGHT", -10, 0)
		end
	end

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --
	
	local GuildDROP = CreateFrame("Frame", Addon .. "GuildDROP", self, "UIDropDownMenuTemplate")
	UIDropDownMenu_SetWidth(GuildDROP, 150)
	UIDropDownMenu_SetText(GuildDROP, db.ActiveGuild or "Select a guild...")
	GuildDROP:SetPoint("TOPLEFT", Addon .. "GuildTabBTN" .. MAX_GUILDBANK_TABS, "TOPRIGHT", 5, 5)

	UIDropDownMenu_Initialize(GuildDROP, function(self, level, menuList)
		local info = UIDropDownMenu_CreateInfo()

		if (level or 1) == 1 then
			info.func = self.SetValue

			for k, v in Frame:pairsByKeys(db.Transactions) do
				info.menuList = k
				info.text = k
				info.arg1 = k
				info.checked = db.ActiveGuild == k
				info.hasArrow = false
				UIDropDownMenu_AddButton(info)
			end
		end
	end)

	function GuildDROP:SetValue(selected)
		db.ActiveGuild = selected

		UIDropDownMenu_SetText(GuildDROP, selected)

		if db.ActiveLog then
			db.ActiveLog = false
			UIDropDownMenu_SetText(LogDROP, "Select a log...")
		end

		UIDropDownMenu_Initialize(LogDROP, function(self, level, menuList)
			local info = UIDropDownMenu_CreateInfo()

			if (level or 1) == 1 then
				info.func = self.SetValue

				if db.Transactions[selected] then
					for k, v in Frame:pairsByKeys(db.Transactions[selected]) do

						info.menuList = k
						info.text = k
						info.arg1 = k
						info.checked = db.ActiveLog == k
						info.hasArrow = false
						UIDropDownMenu_AddButton(info)
					end
				end
			end
		end)

		for k, v in pairs(Frame.ScrollContentFrames) do
			for a, b in pairs(v.Elements) do
				b:ClearAllPoints()
				b:Hide()
			end
		end

		Frame:RefreshButtons()

		CloseDropDownMenus()
	end

	Frame.GuildDROP = GuildDROP

	local LogDROP = CreateFrame("Frame", "LogDROP", self, "UIDropDownMenuTemplate")
	UIDropDownMenu_SetWidth(LogDROP, 175)
	UIDropDownMenu_SetText(LogDROP, db.ActiveLog or "Select a log...")
	LogDROP:SetPoint("TOPLEFT", GuildDROP, "TOPRIGHT", -15, 0)

	function LogDROP:SetValue(selected)
		db.ActiveLog = selected
		db.ActiveTab = 1

		UIDropDownMenu_SetText(LogDROP, selected)

		Frame:RefreshButtons()
		if db.ActivePage ~= "TransactionsTab" and db.ActivePage ~= "MoneyTab" then
			Frame:SelectTab("TransactionsTab")
		end
		Frame:LoadLogs(db.ActivePage == "TransactionsTab" and 1)

		CloseDropDownMenus()
	end
	
	Frame.LogDROP = LogDROP

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --
	
	local ScrollFrame = CreateFrame("ScrollFrame", Addon .. "ScrollFrame", self, "UIPanelScrollFrameTemplate")
	ScrollFrame:SetSize(770, 325)
	ScrollFrame:SetPoint("TOPLEFT", 25, -78)

	ScrollFrame.ScrollBar:EnableMouseWheel(true)
	ScrollFrame.ScrollBar:SetScript("OnMouseWheel", function(self, direction)
		ScrollFrameTemplate_OnMouseWheel(ScrollFrame, direction)
	end)

	local ScrollFrameBG = ScrollFrame:CreateTexture(nil, "BACKGROUND", nil, -6)
	ScrollFrameBG:SetPoint("TOP")
	ScrollFrameBG:SetPoint("RIGHT", 25, 0)
	ScrollFrameBG:SetPoint("BOTTOM")
	ScrollFrameBG:SetWidth(26)
	ScrollFrameBG:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar.blp")
	ScrollFrameBG:SetTexCoord(0, 0.45, 0.1640625, 1)
	ScrollFrameBG:SetAlpha(0.5)

	self.ScrollFrame = ScrollFrame

	self.ScrollContentFrames = {}

	for k, v in pairs(self.Tabs) do
		local ScrollContent = CreateFrame("Frame", Addon .. v[1] .. "ScrollContent", ScrollFrame)
		ScrollContent:SetSize(ScrollFrame:GetWidth(), ScrollFrame:GetHeight())

		ScrollContent.Elements = {}

		self.ScrollContentFrames[v[1]] = ScrollContent
	end

	ScrollFrame:SetScrollChild(self.ScrollContentFrames["TransactionsTab"])

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

	local CurrentScrollContent = self.ScrollContentFrames["SettingsTab"]

	local Header = CurrentScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	Header:SetPoint("TOPLEFT", 10, -10)

	Header:SetText("Settings")

	local ShowAfterScanCHK = CreateFrame("CheckButton", Addon .. "ShowAfterScanCHK", CurrentScrollContent, "OptionsBaseCheckButtonTemplate")
	ShowAfterScanCHK:SetScript("OnClick", function(self)
		db.Settings.ShowAfterScan = self:GetChecked() and true or false
	end)
	ShowAfterScanCHK:SetScript("OnShow", function(self)
		self:SetChecked(db.Settings.ShowAfterScan)
	end)

	ShowAfterScanCHK:SetPoint("TOPLEFT", Header, "BOTTOMLEFT", 0, -5)
	ShowAfterScanCHK:SetChecked(db.Settings.ShowAfterScan)

	local ShowAfterScanTXT = CurrentScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	ShowAfterScanTXT:SetPoint("LEFT", ShowAfterScanCHK, "RIGHT", 5, 0)
	ShowAfterScanTXT:SetText("Show log frame after bank scan")

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

	CurrentScrollContent = self.ScrollContentFrames["HelpTab"]

	Header = CurrentScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	Header:SetPoint("TOPLEFT", 10, -10)

	Header:SetText("Help")

	local HelpMsg = CurrentScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	HelpMsg:SetWidth(CurrentScrollContent:GetWidth() - 20)
	HelpMsg:SetPoint("TOPLEFT", Header, "BOTTOMLEFT", 0, -5)

	HelpMsg:SetText("If you need assistance with the addon, please leave a comment on Curse/WoW Interface or email me at addons@niketa.net.")
	HelpMsg:SetJustifyH("LEFT")
	HelpMsg:SetWordWrap(true)


-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

	self:SelectTab("TransactionsTab")	
	self:RefreshButtons()
	self:Show()

	loaded = true
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

local export_lines = {}
local export_loaded

function Frame:Export()
		if (db.ActivePage ~= "TransactionsTab" and db.ActivePage ~= "MoneyTab") or not db.ActiveGuild or not db.ActiveLog or not db.ActiveTab then
		return false
	end

	table.wipe(export_lines)

	local transactions_table = db.ActivePage == "TransactionsTab" and db.Transactions[db.ActiveGuild][db.ActiveLog]["tab" .. db.ActiveTab] or db.Transactions[db.ActiveGuild][db.ActiveLog]["tab" .. db.Transactions[db.ActiveGuild][db.ActiveLog].MaxTabs + 1]

	local msg = ""
	for k, v in pairs(transactions_table.transactions) do
		local formatted = Frame:FormatMsg(v, db.ActivePage == "TransactionsTab" and "item" or "money")

		if formatted then
			local string = ""
			for a, b in pairs(v) do
				b = type(b) == "table" and "Tab " .. b[1] .. " (" .. b[2] .. ")" or b

				string = string ~= "" and string .. "," .. b or b
			end

			msg = msg ~= "" and msg .. "\n" .. (string .. "," .. formatted) or (string .. "," .. formatted)
		end
	end

	msg = (db.ActivePage == "TransactionsTab" and "type,name,itemLink,count,tab1,tab2,year,month,day,hour,line" or "type,name,amount,years,months,days,hours,line") .. "\n" .. msg

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

	local ExportFrame, CopyEditbox

	if not export_loaded then
		ExportFrame = CreateFrame("Frame", Addon .. "ExportFrame", UIParent)
		ExportFrame:SetSize(450, 450)
		ExportFrame:SetPoint("CENTER", 0, 50)

		ExportFrame:SetToplevel(true)
		ExportFrame:SetFrameStrata("HIGH")
		ExportFrame:EnableMouse(true)
		ExportFrame:SetMovable(true)

		ExportFrame:SetBackdrop({
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

		Frame.ExportFrame = ExportFrame

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

		local ExportScrollFrame = CreateFrame("ScrollFrame", Addon .. "ExportScrollFrame", ExportFrame, "UIPanelScrollFrameTemplate")
		ExportScrollFrame:SetSize(375, 250)
		ExportScrollFrame:SetPoint("TOP", 0, -30)

	    ExportScrollFrame.ScrollBar:EnableMouseWheel(true)
	    ExportScrollFrame.ScrollBar:SetScript("OnMouseWheel", function(self, direction)
	        ScrollFrameTemplate_OnMouseWheel(ExportScrollFrame, direction)
	    end)

		local ScrollContent = CreateFrame("Frame", nil, ExportScrollFrame)
		ScrollContent:SetSize(ExportScrollFrame:GetWidth(), ExportScrollFrame:GetHeight())

		ExportFrame.ScrollFrame = ExportScrollFrame
		ExportScrollFrame.ScrollContent = ScrollContent
		ExportScrollFrame:SetScrollChild(ScrollContent)

		local ExportEditBox = CreateFrame("Editbox", "ExportEditBox", ScrollContent)
		ExportEditBox:SetScript("OnEscapePressed", function(this)
			this:SetText("")
			this:ClearFocus()
			Frame.ExportFrame:Hide()
		end)

		ExportEditBox:SetAllPoints(ScrollContent)

		ExportEditBox:SetFontObject(GameFontHighlightSmall)
		ExportEditBox:SetAutoFocus(true)
		ExportEditBox:SetMultiLine(true)
		ExportEditBox:SetMaxLetters(9000)

		Frame.ExportEditBox = ExportEditBox

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

		local Warning = ExportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		Warning:SetWidth(375)
		Warning:SetPoint("TOP", ExportScrollFrame, "BOTTOM", 0, -10)

		Warning:SetText("This will allow you to export the current tab of the current log, not the entire log.")
		Warning:SetJustifyH("CENTER")
		Warning:SetWordWrap(true)

		local Instructions = ExportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		Instructions:SetWidth(375)
		Instructions:SetPoint("TOP", Warning, "BOTTOM", 0, -5)

		Instructions:SetText("INSTRUCTIONS: To create a CSV file that you can open in Excel, copy and paste the above text into any text editor (such as Notepad). Save the file with a \".csv\" extension. Be sure that you are actually saving the file as a CSV and not a rich text file named \"TestFile.csv.txt\". In some cases, you may need to select a file type of \"All Files\".")
		Instructions:SetJustifyH("LEFT")
		Instructions:SetWordWrap(true)

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

		local ExportCloseBTN = CreateFrame("Button", Addon .. "ExportCloseBTN", ExportFrame, "UIPanelButtonTemplate")
		ExportCloseBTN:SetScript("OnClick", function(self)
			Frame.ExportFrame:Hide()
		end)

		ExportCloseBTN:SetSize(150, 25)
		ExportCloseBTN:SetPoint("TOP", Instructions, "BOTTOM", 0, -15)

		ExportCloseBTN:SetText("Close")

		export_loaded = true
	end

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

	Frame.ExportEditBox:SetText(msg)
	Frame.ExportEditBox:SetFocus()
	Frame.ExportEditBox:HighlightText()
	Frame.ExportFrame:Show()
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

-- GUILDBANK_MOVE_FORMAT = GUILDBANK_MOVE_FORMAT or "%s moved %s x %d from %s to %s"
-- GUILD_BANK_LOG_TIME_PREPEND = GUILD_BANK_LOG_TIME_PREPEND or "|cff009999   "
-- GUILD_BANK_LOG_TIME = GUILD_BANK_LOG_TIME or "( %s ago )"
-- NORMAL_FONT_COLOR_CODE = NORMAL_FONT_COLOR_CODE or "|cffffd200"
-- FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE or "|r"
-- UNKNOWN = UNKNOWN or "Unknown"
-- GUILDBANK_DEPOSIT_MONEY_FORMAT = GUILDBANK_DEPOSIT_MONEY_FORMAT or "%s deposited %s"
-- GUILDBANK_WITHDRAW_MONEY_FORMAT = GUILDBANK_WITHDRAW_MONEY_FORMAT or "%s |cffff2020withdrew|r %s"
-- GUILDBANK_REPAIR_MONEY_FORMAT = GUILDBANK_REPAIR_MONEY_FORMAT or "%s withdrew %s for repairs"
-- GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT = GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT or "%s withdrew %s to purchase a guild bank tab"
-- GUILDBANK_BUYTAB_MONEY_FORMAT = GUILDBANK_BUYTAB_MONEY_FORMAT or "%s purchased a guild bank tab for %s"
-- GUILDBANK_UNLOCKTAB_FORMAT = GUILDBANK_UNLOCKTAB_FORMAT or "%s unlocked a guild bank tab with a Guild Vault Voucher."
-- GUILDBANK_AWARD_MONEY_SUMMARY_FORMAT = GUILDBANK_AWARD_MONEY_SUMMARY_FORMAT or "A total of %s was deposited last week from Guild Perk: Cash Flow "
-- GUILDBANK_DEPOSIT_FORMAT = GUILDBANK_DEPOSIT_FORMAT or "%s deposited %s"
-- GUILDBANK_LOG_QUANTITY = GUILDBANK_LOG_QUANTITY or " x %d"
-- GUILDBANK_WITHDRAW_FORMAT = GUILDBANK_WITHDRAW_FORMAT or "%s |cffff2020withdrew|r %s"

function Frame:FormatMsg(line, log_type)
	local msg

	local type = line[1]
	local name = line[2]

	if not name then
		name = UNKNOWN or "Unknown"
	end

	name = (NORMAL_FONT_COLOR_CODE or "|cffffd200") .. name .. (FONT_COLOR_CODE_CLOSE or "|r")

	if log_type == "money" then
		local money
		local amount = line[3]
		local year = line[4]
		local month = line[5]
		local day = line[6]
		local hour = line[7]

		money = GetDenominationsFromCopper(amount)

		if type == "deposit" then
			msg = format(GUILDBANK_DEPOSIT_MONEY_FORMAT or "%s deposited %s", name, money)
		elseif type == "withdraw" then
			msg = format(GUILDBANK_WITHDRAW_MONEY_FORMAT or "%s |cffff2020withdrew|r %s", name, money)
		elseif type == "repair" then
			msg = format(GUILDBANK_REPAIR_MONEY_FORMAT or "%s withdrew %s for repairs", name, money)
		elseif type == "withdrawForTab" then
			msg = format(GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT or "%s withdrew %s to purchase a guild bank tab", name, money)
		elseif type == "buyTab" then
			if amount > 0 then
				msg = format(GUILDBANK_BUYTAB_MONEY_FORMAT or "%s purchased a guild bank tab for %s", name, money)
			else
				msg = format(GUILDBANK_UNLOCKTAB_FORMAT or "%s unlocked a guild bank tab with a Guild Vault Voucher.", name)
			end
		elseif type == "depositSummary" then
			msg = format(GUILDBANK_AWARD_MONEY_SUMMARY_FORMAT or "A total of %s was deposited last week from Guild Perk: Cash Flow ", money)
		end

		if not msg then
			return
		end
		msg = msg .. (GUILD_BANK_LOG_TIME_PREPEND or "|cff009999   ") .. format(GUILD_BANK_LOG_TIME or "( %s ago )", RecentTimeDate(year, month, day, hour))
	elseif log_type == "item" then
		local itemLink = line[3]
		local count = line[4]
		local tab1 = line[5] ~= 0 and "Tab " .. line[5][1] .. " (" .. line[5][2] .. ")" or line[5]
		local tab2 = line[6] ~= 0 and "Tab " .. line[6][1] .. " (" .. line[6][2] .. ")" or line[6]
		local year = line[7]
		local month = line[8]
		local day = line[9]
		local hour = line[10]

		if type == "deposit" then
			msg = format(GUILDBANK_DEPOSIT_FORMAT or "%s deposited %s", name, itemLink)
			if count > 1 then
				msg = msg .. format(GUILDBANK_LOG_QUANTITY or " x %d", count)
			end
		elseif type == "withdraw" then
			msg = format(GUILDBANK_WITHDRAW_FORMAT or "%s |cffff2020withdrew|r %s", name, itemLink)
			if count > 1 then
				msg = msg .. format(GUILDBANK_LOG_QUANTITY or " x %d", count)
			end
		elseif type == "move" then
			msg = format(GUILDBANK_MOVE_FORMAT or "%s moved %s x %d from %s to %s", name, itemLink, count, tab1, tab2)
		end

		if not msg then
			return
		end
		msg = msg .. (GUILD_BANK_LOG_TIME_PREPEND or "|cff009999   ") .. format(GUILD_BANK_LOG_TIME or "( %s ago )", RecentTimeDate(year, month, day, hour))
	end

	return msg
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

local first = true

function Frame:GUILDBANKBAGSLOTS_CHANGED(...)
	if (has_bagnon and not BagnonFrameguildbank:IsVisible()) and not GuildBankFrame:IsVisible() or Frame.ScanBTN then
		return
	end

	local parent = has_bagnon and (BagnonFrameguildbank.brokerDisplay or BagnonFrameguildbank) or GuildBankFrame
	local point = has_bagnon and {"CENTER", BagnonFrameguildbank, "BOTTOM", 0, 17} or {"BOTTOMLEFT", GuildBankFrame, "BOTTOMLEFT", 11, 31}

	local ScanBTN = CreateFrame("Button", Addon .. "ScanBTN", parent, "UIPanelButtonTemplate")
	ScanBTN:SetScript("OnClick", function(self)
		Frame:Print("Starting scan...")
		self:Disable()

		for i = 1, MAX_GUILDBANK_TABS + 1 do
			QueryGuildBankLog(i)
		end

		if first then
			C_Timer.After(2, Frame.ScanLogs)
			first = nil
		else
			C_Timer.After(1, Frame.ScanLogs)
		end
	end)

	ScanBTN:SetToplevel(has_bagnon)
	ScanBTN:SetSize(100, 21)
	ScanBTN:SetPoint(point[1], point[2], point[3], point[4], point[5])

	ScanBTN:SetText("Scan Bank")

	Frame.ScanBTN = ScanBTN

	Frame:UnregisterEvent("GUILDBANKBAGSLOTS_CHANGED")
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

function Frame:LoadLogs(tab)
	if not db.ActiveLog then
		return
	end

	local ScrollContent = self.ScrollContentFrames[db.ActivePage]
	db.ActiveTab = tab or db.ActiveTab

	ScrollContent:GetParent().ScrollBar:SetValue(0)

	local lines = ScrollContent.Elements

	for k, v in pairs(lines) do
		v:ClearAllPoints()
		v:Hide()
	end

	local transactions_table = tab and db.Transactions[db.ActiveGuild][db.ActiveLog]["tab" .. tab] or db.Transactions[db.ActiveGuild][db.ActiveLog]["tab" .. db.Transactions[db.ActiveGuild][db.ActiveLog].MaxTabs + 1]

	lines["header"] = lines["header"] or ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	lines["header"]:SetText(tab and ("Tab " .. tab .. " (" .. transactions_table.name .. ")") or "Money Log")
	lines["header"]:SetPoint("TOPLEFT", 10, -10)

	lines["header"]:Show()

	local i = 1
	for k, v in pairs(transactions_table.transactions) do
		local msg = Frame:FormatMsg(v, tab and "item" or "money")

		if msg then
			lines[i] = lines[i] or ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			lines[i]:SetWidth(ScrollContent:GetWidth() - 20)
			lines[i]:SetPoint("TOPLEFT", i > 1 and lines[i - 1] or lines["header"], "BOTTOMLEFT", 0, -5)

			lines[i]:SetText(msg)
			lines[i]:SetWordWrap(true)
			lines[i]:SetJustifyH("LEFT")

			lines[i]:Show()

			i = i + 1
		end
	end

	Frame:RefreshButtons()
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

Frame.pairsByKeys = function(_, t, f)
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

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

function Frame:Print(msg)
	print("|cff00ff00PLG: |r" .. msg)
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

function Frame:RefreshButtons()
	if Frame:CountLogs() == 0 or not db.ActiveLog then
		Frame.DeleteBTN:Disable()
		Frame.ExportBTN:Disable()
	else
		Frame.DeleteBTN:Enable()
		Frame.ExportBTN:Enable()
	end

	if not db.ActiveLog or db.ActivePage ~= "TransactionsTab" then
		if db.ActivePage ~= "MoneyTab" then
			Frame.CopyBTN:Disable()
			Frame.ExportBTN:Disable()
		end

		for i = 1, MAX_GUILDBANK_TABS do
			Frame["GuildTabBTNs" .. i]:Disable()
		end
	else
		Frame.CopyBTN:Enable()
		Frame.ExportBTN:Enable()

		for i = 1, MAX_GUILDBANK_TABS do
			if i <= db.Transactions[db.ActiveGuild][db.ActiveLog].MaxTabs and i ~= db.ActiveTab then
				Frame["GuildTabBTNs" .. i]:Enable()
			else
				Frame["GuildTabBTNs" .. i]:Disable()
			end
		end
	end

	if Frame:CountLogs() == 0 and Frame:CountLogs("ALL_GUILDS") == 0 then
		Frame.DeleteAllBTN:Disable()
	else
		Frame.DeleteAllBTN:Enable()
	end

	if not db.ActiveGuild then
		UIDropDownMenu_DisableDropDown(Frame.LogDROP)
	else
		UIDropDownMenu_EnableDropDown(Frame.LogDROP)
	end
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

function Frame:ScanLogs()
	local num_transactions, type, name, amount, itemLink, count, tab1, tab2, year, month, day, hour
	local guild = GetGuildInfo("player")
	local datetime = date("%m/%d/%Y %H:%M:%S")
	
	db.Transactions[guild] = db.Transactions[guild] or {}
	db.Transactions[guild][datetime] = {}

	local log_table = db.Transactions[guild][datetime]
	log_table.MaxTabs = GetNumGuildBankTabs()

	local tabs = log_table.MaxTabs + 1

	for tab = 1, tabs do
		num_transactions = tab < tabs and GetNumGuildBankTransactions(tab) or GetNumGuildBankMoneyTransactions()

		log_table["tab" .. tab] = {
			name = GetGuildBankTabInfo(tab),
			transactions = {}
		}

		local tab_table = log_table["tab" .. tab]["transactions"]
		for i = num_transactions, 1, -1 do
			if tab < tabs then
				type, name, itemLink, count, tab1, tab2, year, month, day, hour = GetGuildBankTransaction(tab, i)

				local tab1_name = tab1 and GetGuildBankTabInfo(tab1)
				local tab2_name = tab2 and GetGuildBankTabInfo(tab2)

				name = name or (UNKNOWN or "Unknown")
				tab1 = tab1 and {tab1, tab1_name} or 0
				tab2 = tab2 and {tab2, tab2_name} or 0

				table.insert(tab_table, {type, name, itemLink, count, tab1, tab2, year, month, day, hour})
			else
				type, name, amount, year, month, day, hour = GetGuildBankMoneyTransaction(i)

				name = name or (UNKNOWN or "Unknown")

				table.insert(tab_table, {type, name, amount, year, month, day, hour})
			end
		end
	end

	Frame.ScanBTN:Enable()
	Frame:Print("Scan finished!")

	if db.Settings.ShowAfterScan then
		Frame:CreateFrame(Frame)
		Frame:SetLog(guild, datetime)
	end
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

function Frame:SelectTab(tab)
	for k, v in pairs(Frame.TabButtons) do
		PanelTemplates_DeselectTab(v)
	end	

	PanelTemplates_SelectTab(Frame.TabButtons[tab])

	for k, v in pairs(Frame.ScrollContentFrames) do
		v:Hide()
		for a, b in pairs(v.Elements) do
			b:ClearAllPoints()
			b:Hide()
		end
	end

	db.ActivePage = tab
	Frame.ScrollFrame:SetScrollChild(self.ScrollContentFrames[tab])
	self.ScrollContentFrames[tab]:Show()

	if tab == "TransactionsTab" then
		Frame:LoadLogs(db.ActiveTab or 1)
	elseif tab == "MoneyTab" then
		Frame:LoadLogs()
	end

	Frame:RefreshButtons()
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

function Frame:SetLog(guild, log)
	if guild == "CLEARCODE" then
		if db.ActiveGuild then
			db.ActiveGuild = false
			UIDropDownMenu_SetText(Frame.GuildDROP, "Select a guild...")
		end

		if db.ActiveLog then
			db.ActiveLog = false
			UIDropDownMenu_SetText(Frame.LogDROP, "Select a log...")
		end

		db.ActiveTab = false

		for k, v in pairs(self.ScrollContentFrames) do
			for a, b in pairs(v.Elements) do
				b:ClearAllPoints()
				b:Hide()
			end
		end
	else
		db.ActiveGuild = guild
		db.ActiveLog = log

		Frame.GuildDROP:SetValue(guild)
		Frame.LogDROP:SetValue(log)

		if db.ActivePage == "TransactionsTab" then
			Frame:LoadLogs(1)
		elseif db.ActivePage == "MoneyTab" then
			Frame:LoadLogs()
		end
	end
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

StaticPopupDialogs["PLG_DeleteAllConfirmation"] = {
	text = "Are you sure you want to delete all logs?",
	button1 = "Delete",
	button2 = "Cancel",
	OnAccept = function()
		table.wipe(db.Transactions)

		Frame:Print(Frame:CountLogs("ALL_GUILDS") == 0 and "All logs have been deleted." or "There was a problem deleting all of your logs.")

		Frame:SetLog("CLEARCODE")
		Frame:RefreshButtons()
	end,
	whileDead = true,
	hideOnEscape = true
}

StaticPopupDialogs["PLG_DeleteConfirmation"] = {
	text = "Are you sure you want to delete this log?",
	button1 = "Delete",
	button2 = "Cancel",
	OnAccept = function()
		db.Transactions[db.ActiveGuild][db.ActiveLog] = nil
		if Frame:CountLogs(db.ActiveGuild) == 0 then
			db.Transactions[db.ActiveGuild] = nil
		end

		Frame:Print((not db.Transactions[db.ActiveGuild] or not db.Transactions[db.ActiveGuild][db.ActiveLog]) and "The log has been deleted." or "There was a problem deleting the log.")

		Frame:SetLog("CLEARCODE")
		Frame:RefreshButtons()
	end,
	whileDead = true,
	hideOnEscape = true
}

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

SLASH_PROLOGGUILD1 = "/plg"

function SlashCmdList.PROLOGGUILD(msg)
	Frame:CreateFrame(Frame)
end
