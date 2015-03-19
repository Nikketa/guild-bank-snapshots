local Addon, ns = ...
local Frame = ns.Frame
local db = ns.db
local has_bagnon = ns.has_bagnon

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

local frame_opened

function Frame:GUILDBANKFRAME_CLOSED(...)
    frame_opened = false

    if db.Settings.HideButton then
        return
    end

    if db.Settings.UseUnanchoredScan then
        db.Settings.UnanchoredScanPosition = {Frame.ScanDrag:GetPoint()}
        Frame.ScanDrag:Hide()
    end
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

local first = true

function Frame:GUILDBANKFRAME_OPENED(...)
    frame_opened = true

    if db.Settings.HideButton then
        return
    end

    if Frame.ScanBTN then
        if db.Settings.UseUnanchoredScan or ((not GuildBankFrame or not GuildBankFrame:IsVisible()) and not has_bagnon) then
            Frame.ScanDrag:Show()
        end
        return
    end

    local ScanBTN

    if db.Settings.UseUnanchoredScan or ((not GuildBankFrame or not GuildBankFrame:IsVisible()) and not has_bagnon) then
        if not db.Settings.UseUnanchoredScan then
            Frame:Print("It appears that you are not using a supported guild bank addon, so you will have to use the un-anchored scan button. To stop seeing this message, select to use this button as default under the settings tab. If you are seeing this (and the scan button is made) and you are not at the guild bank, please report as much information as possible on the Curse or WoW Interface comments.")
        end

        local point = db.Settings.UnanchoredScanPosition

        local ScanDrag = CreateFrame("Frame", Addon .. "ScanDrag", UIParent)
        ScanDrag:SetPoint(point[1], point[2], point[3], point[4], point[5])
        ScanDrag:SetSize(130, 22)

        ScanDrag:EnableMouse(true)
        ScanDrag:SetMovable(true)
        ScanDrag:SetToplevel(true)

        ScanDrag.texture = ScanDrag:CreateTexture(nil, "BACKGROUND")
        ScanDrag.texture:SetAllPoints(ScanDrag)
        ScanDrag.texture:SetTexture(0, 0, 0, 0.5)

        ScanDrag.title_region = ScanDrag:CreateTitleRegion()
        ScanDrag.title_region:SetAllPoints(ScanDrag)

        ScanBTN = CreateFrame("Button", Addon .. "ScanBTN", ScanDrag, "UIPanelButtonTemplate")
        ScanBTN:SetScript("OnClick", Frame.ScanBank)

        ScanBTN:SetSize(100, 21)
        ScanBTN:SetPoint("TOPRIGHT", ScanDrag, "TOPRIGHT", 0, 0)

        ScanBTN:SetText("Scan Bank")

        Frame.ScanDrag = ScanDrag
    else
        local parent = has_bagnon and (BagnonFrameguildbank.brokerDisplay or BagnonFrameguildbank) or GuildBankFrame
        local point = has_bagnon and {"CENTER", BagnonFrameguildbank, "BOTTOM", 0, 17} or {"BOTTOMLEFT", GuildBankFrame, "BOTTOMLEFT", 11, 31}

        ScanBTN = CreateFrame("Button", Addon .. "ScanBTN", parent, "UIPanelButtonTemplate")
        ScanBTN:SetScript("OnClick", function(self)
            Frame:ScanBank()
        end)

        ScanBTN:SetToplevel(has_bagnon)
        ScanBTN:SetSize(100, 21)
        ScanBTN:SetPoint(point[1], point[2], point[3], point[4], point[5])

        ScanBTN:SetText("Scan Bank")
    end

    Frame.ScanBTN = ScanBTN
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

function Frame:ScanBank()
    if not frame_opened then
        Frame:Print("You must be at the guild bank to use the scan feature.")
        return
    end

    Frame:Print("Starting scan...")
    if not db.Settings.HideButton then
        Frame.ScanBTN:Disable()
    end

    for i = 1, MAX_GUILDBANK_TABS + 1 do
        QueryGuildBankLog(i)
    end

    if first then
        C_Timer.After(5, Frame.ScanLogs)
        Frame:Print("Please wait... Your first scan will take longer than usual.")
        first = nil
    else
        C_Timer.After(1, Frame.ScanLogs)
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

    if not db.Settings.HideButton then
        Frame.ScanBTN:Enable()
    end
    Frame:Print("Scan finished!")

    if db.Settings.ShowAfterScan then
        Frame:CreateFrame(Frame)
        Frame:SetLog(guild, datetime)
    end
end
