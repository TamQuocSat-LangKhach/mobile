local fubi = fk.CreateSkill {
  name = "fubi",
}

Fk:loadTranslationTable{
  ["fubi"] = "辅弼",
  [":fubi"] = "出牌阶段限一次，你可以选择一名有〖定仪〗效果的角色并选择一项：1.更换其〖定仪〗效果；2.弃置一张牌，直到你下回合开始，"..
  "其〖定仪〗效果加倍。",

  ["#fubi"] = "辅弼：更换一名角色“定仪”效果，或弃一张牌令一名角色“定仪”效果加倍直到你下回合开始",
  ["#fubi-choice"] = "辅弼：选择为 %dest 更换的“定仪”效果",

  ["$fubi1"] = "辅君弼主，士之所志也。",
  ["$fubi2"] = "献策思计，佐定江山。",
}

fubi:addEffect("active", {
  anim_type = "support",
  prompt = "#fubi",
  min_card_num = 0,
  max_card_num = 1,
  target_num = 1,
  can_use = function (self, player)
    return player:usedSkillTimes(fubi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select:getMark("@dingyi") ~= 0
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if #effect.cards == 0 then
      local all_choices = {"dingyi1", "dingyi2", "dingyi3", "dingyi4"}
      local choices = table.simpleClone(all_choices)
      table.removeOne(choices, target:getMark("@dingyi"))
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = fubi.name,
        prompt = "#fubi-choice::"..target.id,
        all_choices = all_choices,
      })
      room:setPlayerMark(target, "@dingyi", choice)
    else
      room:throwCard(effect.cards, fubi.name, player, player)
      room:addPlayerMark(target, fubi.name, 1)
      room:setPlayerMark(player, "fubi_using", target.id)
    end
  end,
})
fubi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("fubi_using") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local p = room:getPlayerById(player:getMark("fubi_using"))
    room:setPlayerMark(player, "fubi_using", 0)
    room:removePlayerMark(p, "fubi", 1)
  end,
})

return fubi
