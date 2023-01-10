local QBCore = exports['qb-core']:GetCoreObject()

MySQL.query('SELECT * FROM player_shops', {}, function(result)
    if result then
        for k, v in pairs(result) do
            Config.Locations[v.name]["owner"] = v.citizenid

        end
    end
end)

QBCore.Functions.CreateCallback('gct-shops:server:haveShop', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)

    if Player then
        local result = MySQL.Sync.fetchScalar("SELECT `name` FROM player_shops WHERE `citizenid` = @id", {["@id"] = Player.PlayerData.citizenid})
        
        if result then
            cb(true)

        else
            cb(false)
        end
    
    end

    cb(false)
end)

QBCore.Functions.CreateCallback('gct-shops:server:getShopMoney', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)

    if Player then
        MySQL.query("SELECT * FROM player_shops WHERE `citizenid` = @id", {
            ["@id"] = Player.PlayerData.citizenid
        }, function(result)
            if result[1] then
                cb(result[1].money)
            else
                cb(0)
            end
        end)    
    end
end)

QBCore.Functions.CreateCallback('gct-shops:server:getShopInfo', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)

    if Player then
        MySQL.query("SELECT * FROM player_shops WHERE `citizenid` = @id", {
            ["@id"] = Player.PlayerData.citizenid 
        }, function(result)
      
            if result[1] ~= nil and result[1].name ~= nil then
            
                local data = {}
                local nextPayDate = (os.time(tonumber(result.date)) + os.date(432000))
                nextPayDate = os.date("%d/%m/%Y", nextPayDate)
    
                data = {
                    result = "SUCCESS",
                    nextPay = nextPayDate
                }
                cb(data)
            else
                
                local data = {
                    result = "FAILED",
                }
                cb(data)
            end
        end)
    end
end)

RegisterNetEvent('gct-shops:server:UpdateShopItems', function(shop, itemData, amount)
    Config.Locations[shop]["products"][itemData.slot].amount = Config.Locations[shop]["products"][itemData.slot].amount - amount
    if Config.Locations[shop]["products"][itemData.slot].amount <= 0 then
        Config.Locations[shop]["products"][itemData.slot].amount = 0
    end
    local oldMoney = MySQL.Sync.fetchScalar("SELECT `money` FROM player_shops WHERE `name` = @name", {["@name"] = shop})

    MySQL.Async.execute("UPDATE player_shops SET `money` = @amount WHERE `name`= @name", {
        ["@amount"] = (Config.Locations[shop]["products"][itemData.slot].price * amount) + oldMoney,
        ["@name"] = shop,
        ["@shop"] = json.encode(Config.Locations[shop]["products"])
    })

    TriggerClientEvent('gct-shops:client:SetShopItems', -1, shop, Config.Locations[shop]["products"])
end)

RegisterNetEvent('gct-shops:server:addEmployee', function(shop, playerId)
    local shop = shop

    if playerId ~= -1 and playerId ~= nil then
        local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
        Player.Functions.SetJob(shop, 0)
        TriggerClientEvent('QBCore:Notify', source, "Çalışan İşe Alındı!")
        TriggerClientEvent('QBCore:Notify', playerId, "İşe Alındın!")
    else
        TriggerClientEvent('QBCore:Notify', source, "Bir Hata Oluştu!")
    end
end)

RegisterNetEvent('gct-shops:server:fireEmployee', function(data)
    local shop = data.shop
    local playerId = data.playerId
   
    if playerId ~= -1 and playerId ~= nil then
        local Player = QBCore.Functions.GetPlayer(playerId)
        Player.Functions.SetJob("unemployed", 0)
        TriggerClientEvent('QBCore:Notify', source, "Çalışan İşten Kovuldu!")
        TriggerClientEvent('QBCore:Notify', playerId, "İşten Kovuldun!")
    else
        TriggerClientEvent('QBCore:Notify', source, "Bir Hata Oluştu!")
    end
end)

RegisterNetEvent('gct-shops:server:revokeShop', function(src)
    local Player = QBCore.Functions.GetPlayer(src)
    
    MySQL.Async.execute("DELETE FROM player_shops WHERE citizenid = '".. Player.PlayerData.citizenid .."'")
    TriggerClientEvent('QBCore:Notify', source, "Market Sözleşmesi Feshedildi!")
    
end)

RegisterNetEvent('gct-shops:server:RestockShopItems', function(amount, item, shop, oldAmount)
    if amount ~= nil then

        if QBCore.Functions.GetPlayer(source).PlayerData.money.bank < (amount * Config.Locations[shop]["products"][item].stockMoney) then
            QBCore.Functions.Notify("Bankanızda Yetersiz Para!", "error")
            return
        end

        QBCore.Functions.GetPlayer(source).Functions.RemoveMoney("bank", (amount * Config.Locations[shop]["products"][item].stockMoney))
        Config.Locations[shop]["products"][item].amount = oldAmount + amount

        MySQL.Async.execute("UPDATE player_shops SET `shop` = @shop WHERE `name`= @name", {
            ["@name"] = shop,
            ["@shop"] = json.encode(Config.Locations[shop]["products"])
        })
        
        TriggerClientEvent("gct-shops:client:SetShopItems", source, shop, Config.Locations[shop]["products"], Config.Locations[shop]["label"])
        TriggerClientEvent('QBCore:Notify', source, "Stok Yenilendi!")
    end
end)

RegisterNetEvent('gct-shops:server:getAllStocks', function(source)
    MySQL.query('SELECT * FROM player_shops', {}, function(result)
        TriggerClientEvent('gct-shops:client:SetAllShopItems', -1, result)
    end)
end)

RegisterNetEvent('gct-shops:server:getStock', function(source, shop)
    MySQL.query("SELECT * FROM player_shops WHERE `name` = @name", {
        ["@name"] = shop
    }, function(result)
        if result[1] then
            local shopItems = json.decode(result[1].shop)
    

            TriggerClientEvent('gct-shops:client:SetShopItems', -1, shop, shopItems, result[1].label)
        end
    end)
end)

QBCore.Functions.CreateCallback('gct-shops:server:getEmployees', function(source, cb, shop)
    local employees = {}
    local Players = QBCore.Functions.GetPlayers()
    for k, src in pairs(Players) do
        local Player = QBCore.Functions.GetPlayer(src)
        
        if Player.PlayerData.job.name == shop and Player.PlayerData.job.grade.level == 0 then
            employees[#employees + 1] = {
                source = Player.PlayerData.source,
                name = Player.PlayerData.charinfo.firstname ..' '.. Player.PlayerData.charinfo.lastname
            }
        end
    end
    
    cb({
        result = "SUCCESS",
        employees = employees
    })
end)

QBCore.Functions.CreateCallback('gct-shops:server:buyShop', function(source, cb, shop, shopName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Config.Locations[shop] ~= nil then
        local hasShop = MySQL.Sync.fetchScalar("SELECT name FROM player_shops WHERE `citizenid` = @id", {["@id"] = Player.PlayerData.citizenid})

        if hasShop then
            TriggerClientEvent('QBCore:Notify', "Zaten Bir Markete Sahipsin!")
            cb("FAILED")
        end

        if Player.PlayerData.money.bank >= Config.Locations[shop]["buyMoney"]  then
            Player.Functions.RemoveMoney('bank', Config.Locations[shop]["buyMoney"])
            
            MySQL.Async.execute("INSERT INTO player_shops (`citizenid`, `name`, `money`, `date`, `shop`, `label`) VALUES (@identifier, @name, @money, @date, @shop, @label)", {
                ["@identifier"] = Player.PlayerData.citizenid,
                ["@name"] = shop,
                ["@money"] = 0,
                ["@date"] = os.time(),
                ["@shop"] = json.encode(Config.Locations[shop]["products"]),
                ["@label"] = shopName
            })

            Player.Functions.SetJob(shop, 1)

            cb({
                id = Player.PlayerData.citizenid,
                result = "SUCCESS"
            })
        end
    end
    cb("FAILED")
end)

QBCore.Functions.CreateCallback('gct-shops:server:shopBalance', function(source, cb, shop)
    local src = source
    if Config.Locations[shop] ~= nil then
        local _balance = MySQL.Sync.fetchScalar("SELECT `money` FROM player_shops WHERE `name` = @name", {["@name"] = shop})
        cb({
            result = "SUCCESS",
            balance = _balance
        })
    else
        cb({
            result = "FAILED"
        })
    end
end)

QBCore.Functions.CreateCallback('gct-shops:server:getShops', function(source, cb, shop)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Config.Locations[shop] ~= nil then
        MySQL.Async.execute("SELECT * FROM player_shops", {}, function(rowChanged)
            if rowChanged then
                cb({
                    result = "SUCCESS",
                    id = Player.PlayerData.citizenid
                })
            end
        end)
    end
    cb({
        result = "FAILED"
    })
end)

QBCore.Functions.CreateCallback('gct-shops:server:withdrawMoney', function(source, cb, shop, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Config.Locations[shop] ~= nil then
        local money = MySQL.Sync.fetchScalar("SELECT money FROM player_shops WHERE `name`= @name", {["@name"] = shop})
        if money >= tonumber(amount) then
            MySQL.Async.execute("UPDATE player_shops SET `money` = @amount WHERE `name`= @name", {
                ["@amount"] = money - tonumber(amount),
                ["@name"] = shop
            })
            Player.Functions.AddMoney("bank", tonumber(amount))

            cb({
                result = "SUCCESS"
            })
        else
            cb({
                result = "FAILED"
            })
        end
    else
        cb({
            result = "FAILED"
        })
    end
    
end)

QBCore.Functions.CreateCallback('gct-shops:server:depositMoney', function(source, cb, shop, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Config.Locations[shop] ~= nil then
        if Player.PlayerData.money.bank >= tonumber(amount) then 
            Player.Functions.RemoveMoney("bank", tonumber(amount))
            local money = MySQL.Sync.fetchScalar("SELECT money FROM player_shops WHERE `name`= @name", {["@name"] = shop})
            
            MySQL.Async.execute("UPDATE player_shops SET `money` = @amount WHERE `name`= @name", {
                ["@amount"] = tonumber(amount) + money,
                ["@name"] = shop
            })

            cb({
                result = "SUCCESS"
            })
        end
    else
        cb({
            result = "FAILED"
        })   
    end
    
end)

QBCore.Functions.CreateCallback('gct-shops:server:getLicenseStatus', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local licenseTable = Player.PlayerData.metadata["licences"]
    local licenseItem = Player.Functions.GetItemByName("weaponlicense")
    cb(licenseTable.weapon, licenseItem)
end)

function RentCheck()
    if next(QBCore.Players) then
        for _, Player in pairs(QBCore.Players) do
            if Player then
                local payment = Config.Rent
                for i, v in ipairs(Config.Locations) do
                    if Player.PlayerData.job and payment > 0 and Player.PlayerData.job.name == i and Player.PlayerData.job.grade.level > 0 then
                        if Player.PlayerData.money.bank >= payment then
                            Player.Functions.RemoveMoney("bank", payment)
                            TriggerClientEvent('QBCore:Notify', "Market Kirası Ödendi!")
                        else
                            TriggerClientEvent('QBCore:Notify', "Market Kirası Ödenmediği için Sahibi Marketi Geri Aldı!")
                            MySQL.Async.execute("DELETE FROM player_shops WHERE `name` = @name", {
                                ["@name"] = i
                            })
                        end
                    end
                end
            end
        end
    end
    SetTimeout(2 * (60 * 1000), RentCheck)
end

RentCheck()