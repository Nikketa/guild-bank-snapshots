local Addon, ns = ...
local Frame = ns.Frame
local db = ns.db
local has_bagnon = ns.has_bagnon

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

local loaded
local months = {
    ["01"] = "January",
    ["02"] = "February",
    ["03"] = "March",
    ["04"] = "April",
    ["05"] = "May",
    ["06"] = "June",
    ["07"] = "July",
    ["08"] = "August",
    ["09"] = "September",
    ["10"] = "October",
    ["11"] = "November",
    ["12"] = "December",
}

function Frame:CreateFrame()
    local self = Frame
    
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
    TitleTXT:SetText("Guild Bank Snapshots (Formerly Pro-Log Guild)")
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
            if (level or 1) == 1 then
                local info = UIDropDownMenu_CreateInfo()
                for k, v in Frame:pairsByKeys(months) do
                    local counter = 0
                    for a, b in pairs(db.Transactions[selected]) do
                        local month = string.gsub(a, "/%d+/%d+%s%d+:%d+:%d+$","")
                        if tostring(month) == k then
                            counter = counter + 1
                        end
                    end

                    if counter > 0 then
                        info.menuList = k
                        info.text = v
                        info.notCheckable = true
                        info.hasArrow = true
                        info.value = {["Key1"] = k}
                        UIDropDownMenu_AddButton(info)
                    end
                end
            end

            if level == 2 then
                local Key1 = UIDROPDOWNMENU_MENU_VALUE["Key1"]
                local info = UIDropDownMenu_CreateInfo()
                info.func = self.SetValue

                if db.Transactions[selected] then                    
                    for k, v in Frame:pairsByKeys(db.Transactions[selected]) do
                        local month = string.gsub(k, "/%d+/%d+%s%d+:%d+:%d+$","")

                        if tostring(month) == Key1 then
                            info.menuList = k
                            info.text = k
                            info.arg1 = k
                            info.checked = db.ActiveLog == k
                            info.hasArrow = false
                            info.value = {["Key1"] = Key1, ["SubKey"] = k}
                            UIDropDownMenu_AddButton(info, level)
                        end
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

    local UseUnanchoredScanCHK = CreateFrame("CheckButton", Addon .. "UseUnanchoredScanCHK", CurrentScrollContent, "OptionsBaseCheckButtonTemplate")
    UseUnanchoredScanCHK:SetScript("OnClick", function(self)
        local dialog = StaticPopup_Show("PLG_ChangeScanBTN")
        if dialog then
            dialog.data  = self
        end
    end)
    UseUnanchoredScanCHK:SetScript("OnShow", function(self)
        self:SetChecked(db.Settings.UseUnanchoredScan)
    end)

    UseUnanchoredScanCHK:SetPoint("TOPLEFT", ShowAfterScanCHK, "BOTTOMLEFT", 0, -5)
    UseUnanchoredScanCHK:SetChecked(db.Settings.UseUnanchoredScan)

    local UseUnanchoredScanTXT = CurrentScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    UseUnanchoredScanTXT:SetPoint("LEFT", UseUnanchoredScanCHK, "RIGHT", 5, 0)
    UseUnanchoredScanTXT:SetText("Use un-anchored scan button")

    local ResetScanBTN = CreateFrame("Button", Addon .. "ResetScanBTN", CurrentScrollContent, "UIPanelButtonTemplate")
    ResetScanBTN:SetScript("OnClick", function(self)
        db.Settings.UnanchoredScanPosition = {"CENTER", 0, 0}
        if Frame.ScanBTN then
            Frame.ScanDrag:ClearAllPoints()
            Frame.ScanDrag:SetPoint("CENTER", 0, 0)
        end
    end)

    ResetScanBTN:SetSize(200, 21)
    ResetScanBTN:SetPoint("TOPLEFT", UseUnanchoredScanTXT, "BOTTOMLEFT", 0, -10)

    ResetScanBTN:SetText("Reset Scan Button Position")
    
    if not db.Settings.UseUnanchoredScan then
        ResetScanBTN:Disable()
    end

    local HideButtonCHK = CreateFrame("CheckButton", Addon .. "HideButtonCHK", CurrentScrollContent, "OptionsBaseCheckButtonTemplate")
    HideButtonCHK:SetScript("OnClick", function(self)
        local dialog = StaticPopup_Show("PLG_HideScanBTN")
        if dialog then
            dialog.data  = self
        end
    end)
    HideButtonCHK:SetScript("OnShow", function(self)
        self:SetChecked(db.Settings.HideButton)
    end)

    HideButtonCHK:SetPoint("TOPLEFT", UseUnanchoredScanCHK, "BOTTOMLEFT", 0, -30)
    HideButtonCHK:SetChecked(db.Settings.HideButton)

    local HideButtonTXT = CurrentScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    HideButtonTXT:SetPoint("LEFT", HideButtonCHK, "RIGHT", 5, 0)
    HideButtonTXT:SetText("Hide scan button")

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

    CurrentScrollContent = self.ScrollContentFrames["HelpTab"]

    local strings = {
        {"If you need assistance with the addon, please leave a comment on Curse/WoW Interface or email me at addons@niketa.net.", false},
        {"NAME CHANGE", true},
        {"Pro-Log Guild has gone under a name change and is now named Guild Bank Snapshots. I apologize if it causes any issues or confusion, but I feel that the new addon name will more accurately describe the description of the addon. It is also a precursor to a rewrite that I plan to work on that will hopefully improve the functionality and speed of the addon. For now, I will leave in the checks to ensure you are able to transfer your PLG data to the new name, but after some time these checks will be removed. Similarly, you will still be able to use \"/plg\" but this will eventually be removed as well.", false},
        {"Copying your PLG Database", true},
        {"You will need to manually copy your Saved Variables to get your old data back. Please follow these instructions carefully. You may need to write these instructions down or check the Curse/WoW Interface descriptions as this process needs to be done with you logged out of the game. Close out WoW completely. Any changes made to Saved Variable files while WoW is still open may be overwritten. Once you have WoW closed out, navigate to your Saved Variables folder. Go to your WoW directory, then WTF, then Account, then click on the name of your account (or the account number) and then the folder Saved Variables (NOT the server folder). Find the file ProLogGuild.lua and open it. Find the file GuildBankSnapshots.lua and open this as well. Copy the entire contents of ProLogGuild.lua into GuildBankSnapshots.lua. You may save GuildBankSnapshots.lua here, however it is strongly suggested that you change where it says \"ProLogGuildDB\" at the beginning to \"GuildBankSnapshotsDB\". If you bypass these steps, when you log into the game, GBS will update the name for you. However, this step will be removed from the addon in the future and once that happens, your data will not correctly transfer. So, it will just be easiest if you make the update yourself. Finally, please keep in mind that this will completely overwrite your current, new GBS database. It's strongly recommended you take these steps before doing any new scans. I do not have any plans to write code to merge data because it would be time consuming and a waste of time. I apologize for the extra steps you have to take to take care of this.", false},
        {"Common Issues", true},
        {"If the scan button shows up on your screen while away from the guild bank, a UI reload should get rid of it. Please report what you were doing when it happened to help troubleshoot.", false},
        {"If you have an incomplete scan (usually upon first logging in), simply delete the scan and try again. Usually when this is happening, it's because there wasn't enough time to query the bank log. The second scan should be complete.", false},
        {"If you are using an unsupported bank addon, you will have an un-anchored scan button. However, if the button does not properly produce the log, please report what addon it is, any lua errors and how it reacts.", false},
        {"Future Plans", true},
        {"Complete code overhaul (behind the scenes update)", false},
        {"Filter by names/player overview", false},
        {"Improved log export -- need to speed up export to export more at once", false},
        {"Option to choose the delay on intial scan (in case you need it to wait longer the first time to get an accurate scan)", false},
        {"Slash Commands", true},
        {"/gbs = Opens main addon frame", false},
        {"/gbs scan = Scans guild bank to create log (same function as using the button)", false}
    }

    local lines = {}

    Header = CurrentScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    Header:SetPoint("TOPLEFT", 10, -10)

    Header:SetText("Help")

    i = 1
    for k, v in pairs(strings) do
        lines[i] = CurrentScrollContent:CreateFontString(nil, "OVERLAY", v[2] and "GameFontNormalLarge" or "GameFontHighlight")
        lines[i]:SetWidth(CurrentScrollContent:GetWidth() - 20)
        lines[i]:SetPoint("TOPLEFT", i > 1 and lines[i - 1] or Header, "BOTTOMLEFT", 0, v[2] and -10 or -5)

        lines[i]:SetText(v[1])
        lines[i]:SetJustifyH("LEFT")
        lines[i]:SetWordWrap(true)

        i = i + 1
    end

-- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

    self:SelectTab("TransactionsTab")   
    self:RefreshButtons()
    self:Show()

    loaded = true
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

function Frame:Export()
    local ExportFrame, CopyEditbox

    if not export_loaded then
        ExportFrame = CreateFrame("Frame", Addon .. "ExportFrame", UIParent, "UIPanelDialogTemplate")
        ExportFrame:SetSize(450, 400)
        ExportFrame:SetPoint("CENTER", 0, 50)

        ExportFrame:SetToplevel(true)
        ExportFrame:SetFrameStrata("HIGH")
        ExportFrame:EnableMouse(true)
        ExportFrame:SetMovable(true)

        ExportFrame.TitleRegion = ExportFrame:CreateTitleRegion()
        ExportFrame.TitleRegion:SetSize(ExportFrame:GetWidth(), 23)
        ExportFrame.TitleRegion:SetPoint("TOPLEFT", ExportFrame, "TOPLEFT", 0, 0)

        ExportFrame.Title = ExportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ExportFrame.Title:SetText("PLG - Export Logs")
        ExportFrame.Title:SetPoint("LEFT", ExportFrame.TitleRegion, "LEFT", 20, 0)

        local ScrollFrame = CreateFrame("ScrollFrame", Addon .. "ExportFrameScrollFrame", ExportFrame, "UIPanelScrollFrameTemplate")
        ScrollFrame:SetSize(ExportFrame:GetWidth() - (12 + 30), ExportFrame:GetHeight() - ExportFrame.TitleRegion:GetHeight())
        ScrollFrame:SetPoint("TOPLEFT", ExportFrame.TitleRegion, "BOTTOMLEFT", 12, 0)
        ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        ScrollFrame.ScrollBar:EnableMouseWheel(true)
        ScrollFrame.ScrollBar:SetScript("OnMouseWheel", function(self, direction)
            ScrollFrameTemplate_OnMouseWheel(ScrollFrame, direction)
        end)

        local ScrollBG = ScrollFrame:CreateTexture(nil, "BACKGROUND", nil, -6)
        ScrollBG:SetPoint("TOP")
        ScrollBG:SetPoint("RIGHT", 25, 0)
        ScrollBG:SetPoint("BOTTOM")
        ScrollBG:SetWidth(26)
        ScrollBG:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar.blp")
        ScrollBG:SetTexCoord(0, 0.45, 0.1640625, 1)
        ScrollBG:SetAlpha(0.5)

        local ScrollContent = CreateFrame("Frame", Addon .. "ExportFrameScrollContent", ScrollFrame)
        ScrollContent:SetSize(ScrollFrame:GetWidth(), ScrollFrame:GetHeight())

        ScrollFrame.ScrollContent = ScrollContent
        ScrollFrame:SetScrollChild(ScrollContent)

        ExportFrame.ScrollFrame = ScrollFrame
        ExportFrame.ScrollContent = ScrollContent

-- -- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

        local InstructionsHeader = ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        InstructionsHeader:SetPoint("TOPLEFT", 10, -10)
        InstructionsHeader:SetText("Instructions")

        local Instructions = ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        Instructions:SetPoint("TOPLEFT", InstructionsHeader, "BOTTOMLEFT", 0, -5)
        Instructions:SetWordWrap(true)
        Instructions:SetJustifyH("LEFT")
        Instructions:SetWidth(ScrollContent:GetWidth() - 20)
        Instructions:SetText("To create a CSV file that you can open in Excel, select the log you wish to export and copy and paste the text found below into any text editor (such as Notepad). Save the file with a \".csv\" extension. Be sure that you are actually saving the file as a CSV and not a rich text file named \"Example.csv.txt\". In some cases, you may need to select a file type of \"All Files\". Please take note that at the moment you can only export one log at a time, due to the length of time required to export logs. Until (unless) I can find a quicker way to export (either reformatting the database or a different method), this will have to be the limitation of exporting.")

        local ExportHeader = ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        ExportHeader:SetPoint("TOPLEFT", Instructions, "BOTTOMLEFT", 0, -20)
        ExportHeader:SetText("Export")

-- -- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

        local ExportGuild, ExportLog

        local ExportGuildDROP = CreateFrame("Frame", Addon .. "ExportGuildDROP", ExportFrame, "UIDropDownMenuTemplate")
        UIDropDownMenu_SetWidth(ExportGuildDROP, 150)
        UIDropDownMenu_SetText(ExportGuildDROP, ExportGuild or "Select a guild...")
        ExportGuildDROP:SetPoint("TOPLEFT", ExportHeader, "BOTTOMLEFT", -15, -5)

-- -- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

        UIDropDownMenu_Initialize(ExportGuildDROP, function(self, level, menuList)
            local info = UIDropDownMenu_CreateInfo()

            if (level or 1) == 1 then
                info.func = self.SetValue

                for k, v in Frame:pairsByKeys(db.Transactions) do
                    info.menuList = k
                    info.text = k
                    info.arg1 = k
                    info.checked = ExportGuild == k
                    info.hasArrow = false
                    UIDropDownMenu_AddButton(info)
                end
            end
        end)

-- -- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

        local ExportLogDROP = CreateFrame("Frame", "ExportLogDROP", ExportFrame, "UIDropDownMenuTemplate")
        UIDropDownMenu_SetWidth(ExportLogDROP, 175)
        UIDropDownMenu_SetText(ExportLogDROP, ExportLog or "Select a log...")
        ExportLogDROP:SetPoint("TOPLEFT", ExportGuildDROP, "TOPRIGHT", -15, 0)

-- -- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

        function ExportGuildDROP:SetValue(selected)
            ExportGuild = selected

            UIDropDownMenu_SetText(ExportGuildDROP, selected)

            if ExportLog then
                ExportLog = false
                UIDropDownMenu_SetText(ExportLogDROP, "Select a log...")
            end

            UIDropDownMenu_Initialize(ExportLogDROP, function(self, level, menuList)
                -- local info = UIDropDownMenu_CreateInfo()

                -- if (level or 1) == 1 then
                --     info.func = self.SetValue

                --     if db.Transactions[selected] then
                --         for k, v in Frame:pairsByKeys(db.Transactions[selected]) do

                --             info.menuList = k
                --             info.text = k
                --             info.arg1 = k
                --             info.checked = ExportLog == k
                --             info.hasArrow = false
                --             UIDropDownMenu_AddButton(info)
                --         end
                --     end
                -- end
                if (level or 1) == 1 then
                    local info = UIDropDownMenu_CreateInfo()
                    for k, v in Frame:pairsByKeys(months) do
                        local counter = 0
                        for a, b in pairs(db.Transactions[selected]) do
                            local month = string.gsub(a, "/%d+/%d+%s%d+:%d+:%d+$","")
                            if tostring(month) == k then
                                counter = counter + 1
                            end
                        end

                        if counter > 0 then
                            info.menuList = k
                            info.text = v
                            info.notCheckable = true
                            info.hasArrow = true
                            info.value = {["Key1"] = k}
                            UIDropDownMenu_AddButton(info)
                        end
                    end
                end

                if level == 2 then
                    local Key1 = UIDROPDOWNMENU_MENU_VALUE["Key1"]
                    local info = UIDropDownMenu_CreateInfo()
                    info.func = self.SetValue

                    if db.Transactions[selected] then                    
                        for k, v in Frame:pairsByKeys(db.Transactions[selected]) do
                            local month = string.gsub(k, "/%d+/%d+%s%d+:%d+:%d+$","")

                            if tostring(month) == Key1 then
                                info.menuList = k
                                info.text = k
                                info.arg1 = k
                                info.checked = ExportLog == k
                                info.hasArrow = false
                                info.value = {["Key1"] = Key1, ["SubKey"] = k}
                                UIDropDownMenu_AddButton(info, level)
                            end
                        end
                    end
                end
            end)

            ExportCopyEditBox:SetText("")
            ExportCopyEditBox:Disable()
            ExportCopyEditBox:ClearFocus()
            CloseDropDownMenus()
        end

-- -- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

        local ExportCopyScrollFrame = CreateFrame("ScrollFrame", Addon .. "ExportCopyScrollFrame", ExportFrame, "UIPanelScrollFrameTemplate")
        ExportCopyScrollFrame:SetSize(ScrollContent:GetWidth() - 46, 100)
        ExportCopyScrollFrame:SetPoint("TOPLEFT", ExportGuildDROP, "BOTTOMLEFT",  15, -20)

        ExportCopyScrollFrame.Texture = ExportCopyScrollFrame:CreateTexture()
        ExportCopyScrollFrame.Texture:SetAllPoints(ExportCopyScrollFrame)
        ExportCopyScrollFrame.Texture:SetTexture(.1, .1, .1, 1)

        ExportCopyScrollFrame.ScrollBar:EnableMouseWheel(true)
        ExportCopyScrollFrame.ScrollBar:SetScript("OnMouseWheel", function(self, direction)
            ScrollFrameTemplate_OnMouseWheel(ExportCopyScrollFrame, direction)
        end)

-- -- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

        local ExportCopyScrollContent = CreateFrame("Frame", nil, ExportCopyScrollFrame)
        ExportCopyScrollContent:SetSize(ExportCopyScrollFrame:GetWidth(), ExportCopyScrollFrame:GetHeight())

        ExportFrame.ScrollFrame = ExportCopyScrollFrame
        ExportCopyScrollFrame.ScrollContent = ExportCopyScrollContent
        ExportCopyScrollFrame:SetScrollChild(ExportCopyScrollContent)

-- -- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

        local ExportCopyEditBox = CreateFrame("Editbox", "ExportCopyEditBox", ExportCopyScrollContent)
        ExportCopyEditBox:SetScript("OnEscapePressed", function(this)
            this:HighlightText()
            this:ClearFocus()
        end)
        ExportCopyEditBox:SetScript("OnEditFocusGained", function(this)
            this:HighlightText()
        end)

        ExportCopyEditBox:SetAllPoints(ExportCopyScrollContent)

        ExportCopyEditBox:SetFontObject(GameFontHighlightSmall)
        ExportCopyEditBox:SetAutoFocus(false)
        ExportCopyEditBox:SetMultiLine(true)
        ExportCopyEditBox:SetMaxLetters(9000)
        ExportCopyEditBox:Disable()

-- -- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

        function ExportLogDROP:SetValue(selected)
            ExportLog = selected

            UIDropDownMenu_SetText(ExportLogDROP, selected)

            local msg = Frame:GetExportMsg(ExportGuild, ExportLog)

            ExportCopyEditBox:SetMaxLetters(strlen(msg))
            ExportCopyEditBox:SetText(msg)
            ExportCopyEditBox:HighlightText()
            ExportCopyEditBox:Enable()
            ExportCopyEditBox:SetFocus()

            CloseDropDownMenus()
        end        

-- -- ///////////////////////////////////////////////////////////////////////////////////////////////////////// --

        Frame.ExportFrame = ExportFrame

        export_loaded = true
    else
        Frame.ExportFrame:Show()
    end
end

-- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --

function Frame:GetExportMsg(ExportGuild, ExportLog)
    local msg = ""

    local t = db.Transactions[ExportGuild][ExportLog]

    for tab_name, tab_contents in pairs(t) do
        local MaxTabs = t.MaxTabs
        local MoneyTab = "tab" .. (MaxTabs + 1)

        if tab_name ~= "MaxTabs" then
            local prefix = ExportGuild .. "," .. ExportLog .. "," .. tab_name .. "," .. (tab_contents.name or "Money Transactions")
            for key, transaction in pairs(tab_contents.transactions) do
                local line = prefix
                for k, v in pairs(transaction) do
                    v = type(v) == "table" and "Tab " .. v[1] .. " (" .. v[2] .. ")" or ((tab_name == MoneyTab and k == 3) and v .. ",,," or v)

                    line = line .. "," .. v
                end

                line = line .. "," .. Frame:FormatMsg(transaction, tab_name ~= MoneyTab and "item" or "money")

                msg = msg ~= "" and msg .. "\n" .. line or "guild,log,tab,tabName,type,name,itemLink/moneyAmount,count,tab1,tab2,year,month,day,hour,line\n" .. line
            end
        end
    end
    
    return msg
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

function Frame:RefreshButtons()
    if Frame:CountLogs() == 0 then
        Frame.DeleteBTN:Disable()
        Frame.ExportBTN:Disable()
    elseif not db.ActiveLog then
        Frame.DeleteBTN:Disable()
    else
        Frame.DeleteBTN:Enable()
        Frame.ExportBTN:Enable()
    end

    if not db.ActiveLog or db.ActivePage ~= "TransactionsTab" then
        if db.ActivePage ~= "MoneyTab" then
            Frame.CopyBTN:Disable()
            -- Frame.ExportBTN:Disable()
        end

        for i = 1, MAX_GUILDBANK_TABS do
            Frame["GuildTabBTNs" .. i]:Disable()
        end
    else
        Frame.CopyBTN:Enable()
        -- Frame.ExportBTN:Enable()

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

StaticPopupDialogs["PLG_ChangeScanBTN"] = {
    text = "Changing this setting requires a UI reload. Would you like to continue?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        db.Settings.UseUnanchoredScan = data:GetChecked()
        if Frame.ScanDrag then
            db.Settings.UnanchoredScanPosition = {Frame.ScanDrag:GetPoint()}
        end
        ReloadUI()
    end,
    OnCancel = function(self, data)
        data:SetChecked(db.Settings.UseUnanchoredScan)
    end,
    whileDead = true,
    hideOnEscape = true
}

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

StaticPopupDialogs["PLG_HideScanBTN"] = {
    text = "Changing this setting requires a UI reload. Would you like to continue?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        db.Settings.HideButton = data:GetChecked()
        ReloadUI()
    end,
    OnCancel = function(self, data)
        data:SetChecked(db.Settings.HideButton)
    end,
    whileDead = true,
    hideOnEscape = true
}
