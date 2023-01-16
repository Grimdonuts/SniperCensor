add_hook('postbeginlevel', 'GrantSniperItem')

function GrantSniperItem()
    if (Global.player:isInInventory('SniperCensor') ~= 1) then
        local sniper = SpawnScript('global.collectibles.SniperCensor', 'SniperCensor')
        Global.player:addToInventory(sniper,0,1)
    end
end