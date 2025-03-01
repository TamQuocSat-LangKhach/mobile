local jianyu = fk.CreateSkill {
  name = "jianyu",
}

Fk:loadTranslationTable{
  ["jianyu"] = "谏喻",
  [":jianyu"] = "每轮限一次，出牌阶段，你可以选择两名角色，直到你下回合开始，当这些角色于其出牌阶段使用牌指定对方为目标后，你令目标摸一张牌。",

  ["#jianyu"] = "谏喻：指定两名角色，直到你下回合开始，这些角色互相使用牌时，目标摸一张牌",
  ["@@jianyu"] = "谏喻",

  ["$jianyu1"] = "斟酌损益，进尽忠言，此臣等之任也。",
  ["$jianyu2"] = "两相匡护，以各安其分，兼尽其用。",
}

jianyu:addLoseEffect(function (self, player, is_death)
  if is_death and player:getMark("jianyu_targets") ~= 0 then
    local room = player.room
    local targets = player:getMark("jianyu_targets")
    room:setPlayerMark(player, "jianyu_targets", 0)
    for _, p in ipairs(targets) do
      if not table.find(room.alive_players, function(src)
        return src:getMark("jianyu_targets") ~= 0 and table.contains(src:getMark("jianyu_targets"), p)
      end) then
        room:setPlayerMark(p, "@@jianyu", 0)
      end
    end
  end
end)

jianyu:addEffect("active", {
  anim_type = "control",
  prompt = "#jianyu",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(jianyu.name, Player.HistoryRound) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < 2
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:setPlayerMark(player, "jianyu_targets", effect.tos)
    room:setPlayerMark(effect.tos[1], "@@jianyu", 1)
    room:setPlayerMark(effect.tos[2], "@@jianyu", 1)
  end,
})
jianyu:addEffect(fk.TargetSpecified, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("jianyu_targets") ~= 0 and data.from ~= data.to and
      table.contains(player:getMark("jianyu_targets"), data.from) and
      table.contains(player:getMark("jianyu_targets"), data.to) and
      not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, {data.to})
    data.to:drawCards(1, jianyu.name)
  end,
})
jianyu:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("jianyu_targets") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("jianyu_targets")
    room:setPlayerMark(player, "jianyu_targets", 0)
    for _, p in ipairs(targets) do
      if not table.find(room.alive_players, function(src)
        return src:getMark("jianyu_targets") ~= 0 and table.contains(src:getMark("jianyu_targets"), p)
      end) then
        room:setPlayerMark(p, "@@jianyu", 0)
      end
    end
  end,
})

return jianyu
