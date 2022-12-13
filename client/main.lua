local QBCore = exports["qb-core"]:GetCoreObject()
local currentShop, currentData
local pedSpawned = false
local ShopPed = {}

-- Functions
local function SetupItems(shop)
    TriggerServerEvent("gct-shops:server:getStock", shop)
    print(json.encode(Config.Locations[shop]["products"]))
    local products = Config.Locations[shop]["products"]
    local playerJob = QBCore.Functions.GetPlayerData().job.name
    local items = {}
    for i = 1, #products do
        if not products[i].requiredJob then
            items[#items + 1] = products[i]
        else
            for i2 = 1, #products[i].requiredJob do
                if playerJob == products[i].requiredJob[i2] then
                    items[#items + 1] = products[i]
                end
            end
        end
    end
    return items
end

local aktifblipler = {}
local blip = false
RegisterNetEvent("gct-shops:blipAcKapa")
AddEventHandler("gct-shops:blipAcKapa", function()
    if blip then
        pasifblip()
        blip = false
    else
        aktifblip()
        blip = true
    end
end)

function aktifblip()
    for store, _ in pairs(Config.Locations) do
        if Config.Locations[store]["showblip"] then
            local blip = AddBlipForCoord(Config.Locations[store]["coords"]["x"], Config.Locations[store]["coords"]["y"],
                Config.Locations[store]["coords"]["z"])
            SetBlipSprite(blip, Config.Locations[store]["blipsprite"])
            SetBlipScale(blip, 0.6)
            SetBlipDisplay(blip, 4)
            SetBlipColour(blip, 2)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Config.Locations[store]["label"])
            EndTextCommandSetBlipName(blip)
            table.insert(aktifblipler, blip)
        end
    end
end

function pasifblip()
    for i = 1, #aktifblipler do
        RemoveBlip(aktifblipler[i])
    end
    aktifblipler = {}
end

--[[local function createBlips()
    for store, _ in pairs(Config.Locations) do
        if Config.Locations[store]["showblip"] then
            local StoreBlip = AddBlipForCoord(Config.Locations[store]["coords"]["x"], Config.Locations[store]["coords"]["y"], Config.Locations[store]["coords"]["z"])
            SetBlipSprite(StoreBlip, Config.Locations[store]["blipsprite"])
            SetBlipScale(StoreBlip, 0.6)
            SetBlipDisplay(StoreBlip, 4)
            SetBlipColour(StoreBlip, Config.Locations[store]["blipcolor"])
            SetBlipAsShortRange(StoreBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Config.Locations[store]["label"])
            EndTextCommandSetBlipName(StoreBlip)
        end
    end
end]]

-- Events
RegisterNetEvent("gct-shops:client:UpdateShop", function(shop, itemData, amount)
    TriggerServerEvent("gct-shops:server:UpdateShopItems", shop, itemData, amount)
end)

RegisterNetEvent("gct-shops:client:SetShopItems", function(shop, shopProducts, shopLabel)
    if shopProducts == nil then
        return
    end
    Config.Locations[shop]["label"] = shopLabel
    Config.Locations[shop]["products"] = shopProducts
    Wait(1500)
end)

RegisterNetEvent("gct-shops:client:openShopMenu", function(category)
    getShops(category)
end)

RegisterNetEvent("gct-shops:client:openCatMenu", function()
    setCategory()
end)

RegisterNetEvent("gct-shops:client:buyShop", function(callback)

    local mekan = exports['qb-input']:ShowInput({
        header = "Mekan Adı",
        submitText = "Onayla",
        inputs = {{
            type = 'text',
            isRequired = true,
            name = 'label',
            text = 'İsim'
        }}
    })
    if mekan then
        if not mekan.label then
            return
        end

        QBCore.Functions.TriggerCallback("gct-shops:server:buyShop", function(data)
            if data.result == "SUCCESS" then
                Config.Locations[callback.shop]["owner"] = data.id
                SetNewWaypoint(Config.Locations[callback.shop]["coords"].x, Config.Locations[callback.shop]["coords"].y)

                QBCore.Functions.Notify("Market Başarıyla Satın Alındı ve Haritanızda Konumu İşaretlendi!",
                    "success")
            else
                QBCore.Functions.Notify("İşlem Başarısız!", "error")
            end
        end, callback.shop, mekan.label)
    end

end)

RegisterNetEvent("gct-shops:client:openBossMenu", function(shop, item, amount)
    openBossMenu(shop)
end)

RegisterNetEvent("gct-shops:client:RestockShopItems", function(shop)
    local itemMenu = {{
        header = "Stok Yönetimi",
        isMenuHeader = true
    }}

    if Config.Locations[shop]["products"] ~= nil then
        for k in pairs(Config.Locations[shop]["products"]) do
            itemMenu[#itemMenu + 1] = {
                header = QBCore.Shared.Items[Config.Locations[shop]["products"][k].name].label,
                txt = Config.Locations[shop]["products"][k].amount .. " tane stokda mevcut",
                params = {
                    event = "gct-shops:client:addStockItem",
                    args = {
                        shop = shop,
                        item = k
                    }
                }
            }
        end
    end

    itemMenu[#itemMenu + 1] = {
        header = "Geri",
        icon = "fa-solid fa-angle-left",
        params = {
            event = "gct-shops:client:openBossMenu",
            args = shop
        }
    }

    exports['qb-menu']:openMenu(itemMenu)
end)

RegisterNetEvent("gct-shops:client:addStockItem", function(data)
    local shop = data.shop
    local itemName = Config.Locations[shop]["products"][data.item].name
    local oldAmount = Config.Locations[shop]["products"][data.item].amount
    local stock = exports['qb-input']:ShowInput({
        header = QBCore.Shared.Items[itemName].label .. " eşyasının stoğunu yenileyin (Tane Fiyatı: " ..
            Config.Locations[shop]["products"][data.item].stockMoney .. "$",
        submitText = "Onayla",
        inputs = {{
            type = 'number',
            isRequired = true,
            name = 'amount',
            text = 'Miktar'
        }}
    })
    if stock then
        if not stock.amount then
            return
        end
        TriggerServerEvent("gct-shops:server:RestockShopItems", stock.amount, data.item, shop)
    end
end)

RegisterNetEvent("gct-shops:client:addEmployee", function(data)
    TriggerServerEvent("gct-shops:server:addEmployee", data)
end)

RegisterNetEvent("gct-shops:client:fireEmployee", function(data)
    TriggerServerEvent("gct-shops:server:fireEmployee", data)
end)

RegisterNetEvent("gct-shops:client:employeeFire", function(data)
    local shop = data

    local employeeMenu = {{
        header = "Çalışan Yönetimi",
        isMenuHeader = true
    }}

    local employees = {}
    QBCore.Functions.TriggerCallback("gct-shops:server:getEmployees", function(data)
        if data.result == "SUCCESS" then
            employees = data.employees
            for k, v in ipairs(employees) do

                employeeMenu[#employeeMenu + 1] = {
                    header = v.name,
                    txt = "Çalışanı Kov",
                    params = {
                        event = "gct-shops:client:fireEmployee",
                        args = {
                            playerId = v.source,
                            shop = shop
                        }
                    }
                }
            end

            employeeMenu[#employeeMenu + 1] = {
                header = "Geri",
                icon = "fa-solid fa-angle-left",
                params = {
                    event = "gct-shops:client:openBossMenu",
                    args = shop
                }
            }

            exports['qb-menu']:openMenu(employeeMenu)
        end
    end, shop)
end)

RegisterNetEvent("gct-shops:client:employeeManagement", function(data)
    local shop = data
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local employeeMenu = {{
        header = "Çalışan Yönetimi",
        isMenuHeader = true
    }, {
        header = "İşe Al",
        icon = "fa-solid fa-plus",
        params = {
            event = "gct-shops:client:employeeAdd",
            args = shop
        }
    }, {
        header = "İşten Kov",
        icon = "fa-solid fa-minus",
        params = {
            event = "gct-shops:client:employeeFire",
            args = shop
        }
    }}

    employeeMenu[#employeeMenu + 1] = {
        header = "Geri",
        icon = "fa-solid fa-angle-left",
        params = {
            event = "gct-shops:client:openBossMenu",
            args = shop
        }
    }

    exports['qb-menu']:openMenu(employeeMenu)
end)

RegisterNetEvent("gct-shops:client:employeeAdd", function(data)
    local shop = data

    local deposit = exports['qb-input']:ShowInput({
        header = "Çalışan Ekle",
        submitText = "Onayla",
        inputs = {{
            type = 'number',
            isRequired = true,
            name = 'amount',
            text = 'ID'
        }}
    })
    if deposit then
        if not deposit.amount then
            return
        end

        TriggerServerEvent("gct-shops:server:addEmployee", shop, deposit.amount)
    end
end)

RegisterNetEvent("gct-shops:client:withdrawMoney", function(data)
    local shop = data.shop
    QBCore.Functions.TriggerCallback("gct-shops:server:shopBalance", function(data2)
        if data2.result == "SUCCESS" then
            local balance = data2.balance
            local deposit = exports['qb-input']:ShowInput({
                header = "Market Hesabından Para Çekin (Hesap: $" .. balance .. ")",
                submitText = "Onayla",
                inputs = {{
                    type = 'number',
                    isRequired = true,
                    name = 'amount',
                    text = 'Miktar'
                }}
            })
            if deposit then
                if not deposit.amount then
                    return
                end
                QBCore.Functions.TriggerCallback("gct-shops:server:withdrawMoney", function(data3)
                    if data3.result == "SUCCESS" then
                        QBCore.Functions.Notify("İşlem Başarılı!", "success")
                        openBossMenu(shop)
                    else
                        QBCore.Functions.Notify("İşlem Başarısız!", "error")
                        openBossMenu(shop)
                    end
                end, shop, deposit.amount)
            end
        end
    end, shop)
end)

RegisterNetEvent("gct-shops:client:revokeShop", function(source)
    TriggerServerEvent("gct-shops:server:revokeShop", GetPlayerServerId(PlayerId()))
end)

RegisterNetEvent("gct-shops:client:depositMoney", function(data)
    local shop = data.shop
    QBCore.Functions.TriggerCallback("gct-shops:server:shopBalance", function(data2)
        if data2.result ~= "FAILED" then
            local balance = data2.balance
            local deposit = exports['qb-input']:ShowInput({
                header = "Market Hesabından Para Yatırın (Hesap: $" .. balance .. ")",
                submitText = "Onayla",
                inputs = {{
                    type = 'number',
                    isRequired = true,
                    name = 'amount',
                    text = 'Miktar'
                }}
            })
            if deposit then
                if not deposit.amount then
                    return
                end
                QBCore.Functions.TriggerCallback("gct-shops:server:depositMoney", function(data3)
                    if data3.result == "SUCCESS" then
                        QBCore.Functions.Notify("İşlem Başarılı!", "success")
                        openBossMenu(shop)
                    else
                        QBCore.Functions.Notify("İşlem Başarısız!", "error")
                        openBossMenu(shop)
                    end
                end, shop, deposit.amount)
            end
        else
            QBCore.Functions.Notify("Bir Hata Oluştu!", "error")
            openBossMenu(shop)
        end
    end, shop)
end)

local function openShop(shop, data)
    local products = data.products
    local ShopItems = {}
    ShopItems.items = {}
    QBCore.Functions.TriggerCallback("gct-shops:server:getLicenseStatus", function(hasLicense, hasLicenseItem)
        ShopItems.label = data["label"]
        if data.type == "weapon" then
            if hasLicense and hasLicenseItem then
                ShopItems.items = SetupItems(shop)
                QBCore.Functions.Notify(Lang:t("success.dealer_verify"), "success")
                Wait(500)
            else
                for i = 1, #products do
                    if not products[i].requiredJob then
                        if not products[i].requiresLicense then
                            ShopItems.items[#ShopItems.items + 1] = products[i]
                        end
                    else
                        for i2 = 1, #products[i].requiredJob do
                            if QBCore.Functions.GetPlayerData().job.name == products[i].requiredJob[i2] and
                                not products[i].requiresLicense then
                                ShopItems.items[#ShopItems.items + 1] = products[i]
                            end
                        end
                    end
                end
                QBCore.Functions.Notify(Lang:t("error.dealer_decline"), "error")
                Wait(500)
                QBCore.Functions.Notify(Lang:t("error.talk_cop"), "error")
                Wait(1000)
            end
        else
            ShopItems.items = SetupItems(shop)
        end
        for k in pairs(ShopItems.items) do
            ShopItems.items[k].slot = k
        end
        ShopItems.slots = 30
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "Itemshop_" .. shop, ShopItems)
    end)
end

local function createPeds()
    if pedSpawned then
        return
    end
    for k, v in pairs(Config.Locations) do
        if not ShopPed[k] then
            ShopPed[k] = {}
        end
        local current = v["ped"]
        current = type(current) == 'string' and GetHashKey(current) or current
        RequestModel(current)

        while not HasModelLoaded(current) do
            Wait(0)
        end
        
        if v.category ~= "business" then
            ShopPed[k] = CreatePed(0, current, v["coords"].x, v["coords"].y, v["coords"].z - 1, v["coords"].w, false, false)
            TaskStartScenarioInPlace(ShopPed[k], v["scenario"], true)
            FreezeEntityPosition(ShopPed[k], true)
            SetEntityInvincible(ShopPed[k], true)
            SetBlockingOfNonTemporaryEvents(ShopPed[k], true)

            if Config.UseTarget then
                exports['qb-target']:AddTargetEntity(ShopPed[k], {
                    options = {{
                        label = v["targetLabel"],
                        icon = v["targetIcon"],
                        item = v["item"],
                        action = function()
                            openShop(k, Config.Locations[k])
                        end,
                        job = v["job"],
                        gang = v["gang"]
                    }, {
                        label = "Market Yönetim",
                        icon = "fas fa-sign-in-alt",
                        item = v["item"],
                        action = function()
                            openBossMenu(k)
                        end,
                        job = k,
                        gang = v["gang"]
                    }},
                    distance = 2.0
                })
            end
        end
    end

    if not ShopPed["buyshop"] then
        ShopPed["buyshop"] = {}
    end
    local current = Config.BuyShop.ped
    current = type(current) == 'string' and GetHashKey(current) or current
    RequestModel(current)

    while not HasModelLoaded(current) do
        Wait(0)
    end
    ShopPed["buyshop"] = CreatePed(0, current, Config.BuyShop.coords.x, Config.BuyShop.coords.y,
        Config.BuyShop.coords.z - 1, Config.BuyShop.coords.w, false, false)
    TaskStartScenarioInPlace(ShopPed["buyshop"], Config.BuyShop.scenario, true)
    FreezeEntityPosition(ShopPed["buyshop"], true)
    SetEntityInvincible(ShopPed["buyshop"], true)
    SetBlockingOfNonTemporaryEvents(ShopPed["buyshop"], true)

    if Config.UseTarget then
        exports['qb-target']:AddTargetEntity(ShopPed["buyshop"], {
            options = {{
                label = 'Market Satın Al',
                icon = 'fas fa-dollar-sign',
                action = function()
                    setCategory()
                end
            }, {
                label = 'Market Bilgileri',
                icon = 'fas fa-info',
                action = function()
                    shopInfo()
                end
            }},
            distance = 2.0
        })
    end

    pedSpawned = true
end

function shopInfo()
    QBCore.Functions.TriggerCallback("gct-shops:server:getShopInfo", function(callbak)
        print(callbak.result)
        if callbak.result == "SUCCESS" then
            local buyMenu = {{
                header = "Market Sözleşmesi",
                isMenuHeader = true
            }, {
                header = callbak.nextPay .. " | Kira Tutarı: " .. Config.Rent,
                txt = "Son Ödeme Bilgileri"
            }, {
                header = "Sözleşme Feshet",
                txt = "Sözleşme İptali",
                params = {
                    event = "gct-shops:client:revokeShop"
                }
            }}
            exports['qb-menu']:openMenu(buyMenu)
        else
            QBCore.Functions.Notify("Bir Markete Sahip Değilsin!", "error")
        end
    end)
end

function openBossMenu(shop)
    local Player = QBCore.Functions.GetPlayerData()
    if Player.job.grade.level >= 1 then
        local buyMenu = {{
            header = "Market Yönetimi",
            isMenuHeader = true
        }, {
            header = "Stokları Yenile",
            txt = "Tükenmiş Malzemeleri Yenileyin",
            params = {
                event = "gct-shops:client:RestockShopItems",
                args = shop
            }
        }, {
            header = "Çalışan Yönetimi",
            txt = "Çalışanlarınızı Yönetin",
            params = {
                event = "gct-shops:client:employeeManagement",
                args = shop
            }
        }, {
            header = "Market Hesabından Para Çek",
            txt = "Market Hesabından Para Çekin",
            params = {
                event = "gct-shops:client:withdrawMoney",
                args = {
                    shop = shop
                }
            }
        }, {
            header = "Market Hesabına Para Yatır",
            txt = "Market Hesabına Para Yatırın",
            params = {
                event = "gct-shops:client:depositMoney",
                args = {
                    shop = shop
                }
            }
        }}

        exports['qb-menu']:openMenu(buyMenu)

    else
        local buyMenu = {{
            header = "Market Yönetimi",
            isMenuHeader = true
        }, {
            header = "Stokları Yenile",
            txt = "Tükenmiş Malzemeleri Yenileyin",
            params = {
                event = "gct-shops:client:RestockShopItems",
                args = shop
            }
        }}
        exports['qb-menu']:openMenu(buyMenu)
    end

end

function setCategory()
    QBCore.Functions.TriggerCallback("gct-shops:server:haveShop", function(haveShop)
        if haveShop == false then
            
            local catMenu = {{
                header = "Market Satın Al",
                isMenuHeader = true
            }}

            for k, v in pairs(Config.Categorys) do
                catMenu[#catMenu + 1] = {
                    header = v,
                    txt = "Bu alan adı altında olan yerler",
                    params = {
                        event = "gct-shops:client:openShopMenu",
                        args = k
                    }
                }
            end

            catMenu[#catMenu + 1] = {
                header = "Kapat",
                icon = "fa-solid fa-angle-left",
                params = {
                    event = "qb-menu:closeMenu",
                }
            }

            exports['qb-menu']:openMenu(catMenu)
        else
            QBCore.Functions.Notify("Zaten Marketin Var!", "error")
        end
    end)
end

function getShops(category)
    local buyMenu = {{
        header = Config.Categorys[category],
        isMenuHeader = true
    }}

    for k, v in pairs(Config.Locations) do
        if v.owner == "" and v.buyMoney and v.category == category then
            buyMenu[#buyMenu + 1] = {
                header = v.label,
                txt = v.buyMoney .. "$",
                params = {
                    event = "gct-shops:client:buyShop",
                    args = {
                        shop = k
                    }
                }
            }

        end
    end

    buyMenu[#buyMenu + 1] = {
        header = "Geri",
        icon = "fa-solid fa-angle-left",
        params = {
            event = "gct-shops:client:openCatMenu",
        }
    }

    exports['qb-menu']:openMenu(buyMenu)
end

local function deletePeds()
    if pedSpawned then
        for _, v in pairs(ShopPed) do
            DeletePed(v)
        end
    end
end

-- Threads

local NewZones = {}
CreateThread(function()
    if not Config.UseTarget then
        for shop, _ in pairs(Config.Locations) do
            NewZones[#NewZones + 1] = CircleZone:Create(vector3(Config.Locations[shop]["coords"]["x"],
                Config.Locations[shop]["coords"]["y"], Config.Locations[shop]["coords"]["z"]),
                Config.Locations[shop]["radius"], {
                    useZ = true,
                    debugPoly = false,
                    name = shop
                })
        end

        local combo = ComboZone:Create(NewZones, {
            name = "RandomZOneName",
            debugPoly = false
        })
        combo:onPlayerInOut(function(isPointInside, _, zone)
            if isPointInside then
                currentShop = zone.name
                currentData = Config.Locations[zone.name]
                exports["qb-core"]:DrawText(Lang:t("info.open_shop"))
                Listen4Control()
            else
                exports["qb-core"]:HideText()
                listen = false
            end
        end)

        local playerJob = QBCore.Functions.GetPlayerData().job.name
        local buyShop = ComboZone:Create(NewZones, {
            name = "RandomZOneName",
            debugPoly = false
        })
        buyShop:onPlayerInOut(function(isPointInside, _, zone)
            if isPointInside then
                currentShop = zone.name
                currentData = Config.Locations[zone.name]
                exports["qb-core"]:DrawText("Market Yönetimi")
                Listen4Control()
            else
                exports["qb-core"]:HideText()
                listen = false
            end
        end)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- createBlips()
    createPeds()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    deletePeds()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- createBlips()
        createPeds()
        TriggerServerEvent("gct-shops:server:getAllStocks")

    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        deletePeds()
    end
end)
