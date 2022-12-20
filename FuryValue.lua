local function gearscore_getStat(stats, statName)
    return stats[statName] or 0;
end

local function EnumerateTooltipLines_helper(...)
    local result = {};
    for i = 1, select('#', ...) do
        local region = select(i, ...);
        if region and region:GetObjectType() == 'FontString' then
            local text = region:GetText();
            if text ~= nil then
                table.insert(result, text);
            end
        end
    end
    return result;
end

local function gearscore_program(tooltip)
    local _, itemLink = tooltip:GetItem()
    if itemLink and itemlink ~= '' then
        local _, _, _, _, _, itemType, _, _, itemEquipLoc = GetItemInfo(itemLink);
        if itemEquipLoc ~= '' and (itemType == 'Armure' or itemType == 'Arme') then
            local stats = GetItemStats(itemLink);
            local spellName = GetItemSpell(itemLink);
            local arpen = gearscore_getStat(stats, 'ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT');
            local pa = gearscore_getStat(stats, 'ITEM_MOD_ATTACK_POWER_SHORT');
            local agi = gearscore_getStat(stats, 'ITEM_MOD_AGILITY_SHORT');
            local armure = gearscore_getStat(stats, 'RESISTANCE0_NAME');
            local expertise = gearscore_getStat(stats, 'ITEM_MOD_EXPERTISE_RATING_SHORT');
            local toucher = gearscore_getStat(stats, 'ITEM_MOD_HIT_RATING_SHORT');
            local hate = gearscore_getStat(stats, 'ITEM_MOD_HASTE_RATING_SHORT');
            local force = gearscore_getStat(stats, 'ITEM_MOD_STRENGTH_SHORT');
            local crit = gearscore_getStat(stats, 'ITEM_MOD_CRIT_RATING_SHORT');
            local gearscore = arpen + expertise + toucher + pa / 1.8 + agi / 1.2225 + armure / 64.8 + hate / 2 + force / 0.69 + crit / 0.999;
            local red = gearscore_getStat(stats, 'EMPTY_SOCKET_RED');
            local yellow = gearscore_getStat(stats, 'EMPTY_SOCKET_YELLOW');
            local blue = gearscore_getStat(stats, 'EMPTY_SOCKET_BLUE');
            local gs_chasse_full_force = (red * 20 + yellow * 20 + blue * 20) / 0.69;
            local gs_bonus_de_chasse = 0;
            local tooltipTxt = EnumerateTooltipLines_helper(tooltip:GetRegions());
            for key, text in pairs(tooltipTxt) do
                local indexStart, indexEnd = string.find(text, _G['ITEM_SOCKET_BONUS']:sub(1, -3));
                if indexStart ~= nil then
                    local bonusString = string.sub(text, indexEnd + 2);
                    local searchForce = string.find(bonusString, ' Force');
                    local searchAgi = string.find(bonusString, ' Agilité');
                    local searchPa = string.find(bonusString, ' à la puissance d\'attaque');
                    local searchToucher = string.find(bonusString, ' au score de toucher');
                    local searchExpertise = string.find(bonusString, ' au score d\'expertise');
                    local searchCritique = string.find(bonusString, ' au score de coup critique');
                    local searchHate = string.find(bonusString, ' au score de hâte');
                    local searchArpen = string.find(bonusString, ' au score de pénétration d\'armure');
                    if searchForce ~= nil then
                        local valueForce = tonumber(string.sub(bonusString, 1, searchForce));
                        gs_bonus_de_chasse = valueForce / 0.69;
                    elseif searchAgi ~= nil then
                        local valueAgi = tonumber(string.sub(bonusString, 1, searchAgi));
                        gs_bonus_de_chasse = valueAgi / 1.2225;
                    elseif searchHate ~= nil then
                        local valueHate = tonumber(string.sub(bonusString, 1, searchHate));
                        gs_bonus_de_chasse = valueHate / 2;
                    elseif searchPa ~= nil then
                        local valuePa = tonumber(string.sub(bonusString, 1, searchPa));
                        gs_bonus_de_chasse = valuePa / 1.8;
                    elseif searchToucher ~= nil then
                        local valueToucher = tonumber(string.sub(bonusString, 1, searchToucher));
                        gs_bonus_de_chasse = valueToucher;
                    elseif searchExpertise ~= nil then
                        local valueExpertise = tonumber(string.sub(bonusString, 1, searchExpertise));
                        gs_bonus_de_chasse = valueExpertise;
                    elseif searchCritique ~= nil then
                        local valueCritique = tonumber(string.sub(bonusString, 1, searchCritique));
                        gs_bonus_de_chasse = valueCritique / 0.999;
                    elseif searchArpen ~= nil then
                        local valueArpen = tonumber(string.sub(bonusString, 1, searchArpen));
                        gs_bonus_de_chasse = valueArpen;
                    end
                end
            end
            local gs_chasse_respectant_couleurs = red * 20 / 0.69 + yellow * 10 / 0.69 + yellow * 10 / 0.999 + blue * 10 / 0.69 + gs_bonus_de_chasse;
            if gs_chasse_respectant_couleurs > gs_chasse_full_force then
                gearscore = gearscore + gs_chasse_respectant_couleurs;
            else
                gearscore = gearscore + gs_chasse_full_force;
            end
            if itemEquipLoc == 'INVTYPE_HEAD' then
                local meta = gearscore_getStat(stats, 'EMPTY_SOCKET_META');
                if meta > 0 then
                    tooltip:AddLine('Value: ' .. gearscore .. ' (sans compter la meta)', 1, 0.4, 1);
                else
                    tooltip:AddLine('Value: ' .. gearscore .. ' (mais pas de meta :/)', 1, 0.4, 1);
                end
            else
                tooltip:AddLine('Value: ' .. gearscore, 1, 0.4, 1);
            end
            if gs_chasse_respectant_couleurs > gs_chasse_full_force then
                tooltip:AddLine('A gemmer en respectant les couleurs.', 1, 0.4, 1);
            elseif red > 0 or blue > 0 or yellow > 0 then
                tooltip:AddLine('A gemmer full force.', 1, 0.4, 1);
            end
            if itemType == 'Arme' then
                tooltip:AddLine('Ne prend pas en compte les dégâts/dps/vitesse de l\'arme.', 1, 0.4, 1);
            end
            if spellName ~= nil then
                tooltip:AddLine('Ne prend pas en compte le "utiliser".', 1, 0.4, 1);
            end
        end
    end
end

if gearscore_init == nil then
    gearscore_init = true;
    GameTooltip:HookScript('OnTooltipSetItem', gearscore_program);
    AtlasLootTooltip:HookScript('OnTooltipSetItem', gearscore_program);
    ItemRefTooltip:HookScript('OnTooltipSetItem', gearscore_program);
    ShoppingTooltip1:HookScript('OnTooltipSetItem', gearscore_program);
    ShoppingTooltip2:HookScript('OnTooltipSetItem', gearscore_program);
end