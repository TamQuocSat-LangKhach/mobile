local shanjia = fk.CreateSkill {
  name = "shanjia",
}

Fk:loadTranslationTable{
  ["shanjia"] = "缮甲",
  [":shanjia"] = "出牌阶段开始时，你可以摸三张牌，然后弃置三张牌（你每失去过一张装备区里的牌便少弃置一张），"..
  "若没有弃置不为装备牌的牌，你可以视为使用【杀】。",

  ["@shanjia"] = "缮甲弃牌",
  ["#shanjia-discard"] = "缮甲：你须弃置%arg张牌，若均为装备牌则视为使用【杀】",
  ["#shanjia-slash"] = "缮甲：你可以视为对一名角色使用【杀】",

  ["$shanjia1"] = "缮甲厉兵，伺机而行。",
  ["$shanjia2"] = "战，当取精锐之兵，而弃驽钝也。",
}

shanjia:addAcquireEffect(function (self, player)
  player.room:setPlayerMark(player, "@shanjia", 3)
end)
shanjia:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@shanjia", 0)
end)
shanjia:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanjia.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:drawCards(player, 3, shanjia.name)
    if player.dead then return end
    local x = player:getMark("@shanjia")
    if x > 0 then
      --其实这么写会有个有趣的现象，在摸牌时失去缮甲的话会不用弃牌，待验证
      local cards = room:askToDiscard(player, {
        min_num = x,
        max_num = x,
        include_equip = true,
        skill_name = shanjia.name,
        cancelable = false,
        prompt = "#shanjia-discard:::"..x,
        skip = true,
      })
      if #cards > 0 then
        local shanjia_failure = table.find(cards, function (id)
          return Fk:getCardById(id).type ~= Card.TypeEquip
        end)
        room:throwCard(cards, shanjia.name, player, player)
        if player.dead or shanjia_failure then return end
      end
    end
    room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = shanjia.name,
      prompt = "#shanjia-slash",
      extra_data = {
        bypass_times = true,
        extraUse = true,
      }
    })
  end,
})
shanjia:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(shanjia.name, true) and player:getMark("@shanjia") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local i = 0
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              i = i + 1
            end
          end
        end
      end
      if i > 0 then
        room:removePlayerMark(player, "@shanjia", i)
      end
    end
  end,
})

return shanjia
