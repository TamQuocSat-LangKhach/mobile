local dingyi = fk.CreateSkill {
  name = "dingyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dingyi"] = "定仪",
  [":dingyi"] = "锁定技，游戏开始时，你选择一项对全场角色生效：1.摸牌阶段摸牌数+1；2.手牌上限+2；3.攻击范围+1；4.脱离濒死状态时回复1点体力。",

  ["#dingyi-choice"] = "定仪：选择一项对所有角色生效",
  ["@dingyi"] = "定仪",
  ["dingyi1"] = "额外摸牌",
  ["dingyi2"] = "手牌上限",
  ["dingyi3"] = "攻击范围",
  ["dingyi4"] = "额外回复",

  ["$dingyi1"] = "经国序民，还需制礼定仪。",
  ["$dingyi2"] = "无礼而治世，欲使国泰，安可得哉？",
}

dingyi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dingyi.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"dingyi1", "dingyi2", "dingyi3", "dingyi4"},
      skill_name = dingyi.name,
      prompt = "#dingyi-choice",
    })
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@dingyi", choice)
    end
  end,
})
dingyi:addEffect(fk.DrawNCards, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@dingyi") == "dingyi1"
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + (2 ^ player:getMark("fubi"))
  end,
})
dingyi:addEffect(fk.AfterDying, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@dingyi") == "dingyi4" and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = math.min(player.maxHp - player.hp, (2 ^ player:getMark("fubi"))),
      recoverBy = player,
      skillName = dingyi.name,
    }
  end,
})
dingyi:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:getMark("@dingyi") == "dingyi2" then
      return 2 * (2 ^ player:getMark("fubi"))
    end
  end,
})
dingyi:addEffect("atkrange", {
  correct_func = function(self, from, to)
    if from:getMark("@dingyi") == "dingyi3" then
      return (2 ^ from:getMark("fubi"))
    end
  end,
})

return dingyi
