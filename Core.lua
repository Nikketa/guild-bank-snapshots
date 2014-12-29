local Addon, ns = ...

local db = setmetatable({}, {__index = function(t, k)
    return _G["ProLogGuildDB"][k]
end})

local Frame = CreateFrame("Frame", Addon .. "Frame", UIParent)
Frame:SetScript("OnEvent", function(self, event, ...)
	return self[event] and self[event](self, event, ...)
end)

Frame:RegisterEvent("ADDON_LOADED")
Frame:RegisterEvent("GUILDBANKFRAME_CLOSED")
Frame:RegisterEvent("GUILDBANKFRAME_OPENED")

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

ns.has_bagnon = has_bagnon

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

Frame.pairsByKeys = function(_, t, f)
	local a = {}

	for n in pairs(t) do
		table.insert(a, n)
	end

	table.sort(a, f)

	local i = 0
	local iter = function ()
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	
	return iter
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

function Frame:Print(msg)
	print("|cff00ff00PLG: |r" .. msg)
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

SLASH_PROLOGGUILD1 = "/plg"

function SlashCmdList.PROLOGGUILD(msg)
	if msg == "scan" then
		Frame:ScanBank()
	else
		Frame:CreateFrame()
	end
end
