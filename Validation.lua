local Addon, ns = ...
local db = ns.db
local Frame = ns.Frame

local default = {
    ActiveGuild = false,
    ActiveLog = false,
    ActivePage = false,
    ActiveTab = false,
    Settings = {
        ShowAfterScan = true,
        UseUnanchoredScan = false,
        UnanchoredScanPosition = {"CENTER", 0, 0},
        HideButton = false
    },
    Transactions = {},
    Version = 4
}

function Frame:ValidateDB()
    if not GuildBankSnapshotsDB then
        if ProLogGuildDB then
            GuildBankSnapshotsDB = ProLogGuildDB
            ProLogGuildDB = nil
        else
            GuildBankSnapshotsDB = default
        end
    else
        if not db.Version then
            -- "Version 1"
            -- {
            --  Settings = {},
            --  Transactions = {},
            --  Active = {["page"] = "transactions_tab", ["guild"] = false, ["log"] = false, ["tab"] = false}
            -- }

            -- Transactions["GUILDNAME"]["DATETIMELOG"]["money_transactions"]
            -- Transactions["GUILDNAME"]["DATETIMELOG"]["transactions"]["Tab n"]

            GuildBankSnapshotsDB.Active = nil
            GuildBankSnapshotsDB.log_dropdown = nil
            GuildBankSnapshotsDB.Settings = {
                ShowAfterScan = true
            }

            GuildBankSnapshotsDB.ActiveGuild = false
            GuildBankSnapshotsDB.ActiveLog = false
            GuildBankSnapshotsDB.ActivePage = false
            GuildBankSnapshotsDB.ActiveTab = false
            GuildBankSnapshotsDB.Version = 2

            local Temp = {}
            for k, v in pairs(GuildBankSnapshotsDB.Transactions) do
                Temp[k] = {}

                for a, b in pairs(v) do
                    Temp[k][a] = {}

                    local num_tabs = 0
                    for c, d in pairs(b["transactions"]) do
                        Temp[k][a]["tab" .. string.gsub(c, "Tab ", "")] = {
                            name = UNKNOWN or "Unknown",
                            transactions = {}
                        }

                        local tab_table = Temp[k][a]["tab" .. string.gsub(c, "Tab ", "")].transactions

                        for e, f in pairs(d) do
                            local counter = 0
                            for g, h in pairs(f) do
                                counter = counter + 1
                            end

                            local type = f[1]
                            local name = f[2] or (UNKNOWN or "Unknown")
                            local itemLink = f[3]
                            local count = f[4]
                            local tab1 = f[5] and {f[5], UNKNOWN or "Unknown"} or 0
                            local tab2 = f[6] and {f[6], UNKNOWN or "Unknown"} or 0
                            local year = f[7]
                            local month = f[8]
                            local day = f[9]
                            local hour = f[10]

                            table.insert(tab_table, {type, name, itemLink, count, tab1, tab2, year, month, day, hour})
                        end

                        num_tabs = num_tabs + 1
                    end
                    
                    Temp[k][a].MaxTabs = num_tabs

                    Temp[k][a]["tab" .. num_tabs + 1] = {
                        transactions = {}
                    }
                    local tab_table = Temp[k][a]["tab" .. num_tabs + 1].transactions
                    for c, d in pairs(b["money_transactions"]) do
                        local type = d[1]
                        local name = d[2] or (UNKNOWN or "Unknown")
                        local amount = d[3]
                        local year = d[4]
                        local month = d[5]
                        local day = d[6]
                        local hour = d[7]

                        table.insert(tab_table, {type, name, amount, year, month, day, hour})
                    end
                end
            end

            GuildBankSnapshotsDB.Transactions = Temp
        end
        if db.Version == 2 then
            if not db.Settings.UseUnanchoredScan then
                GuildBankSnapshotsDB.Settings.UseUnanchoredScan = false
            end
            if not db.Settings.UnanchoredScanPosition then
                GuildBankSnapshotsDB.Settings.UnanchoredScanPosition = {"CENTER", 0, 0}
            end

            GuildBankSnapshotsDB.Version = 3
        end
        if db.Version == 3 then
            if not db.Settings.HideButton then
                GuildBankSnapshotsDB.Settings.HideButton = false
            end

            GuildBankSnapshotsDB.Version = 4
        end        
    end
end
