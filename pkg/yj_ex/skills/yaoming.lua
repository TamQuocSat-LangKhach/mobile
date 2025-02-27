local yaoming = fk.CreateSkill{
  name = "m_ex__yaoming",
}

yaoming:addEffect("active", {
  times = function (self, player)
    return player:getMark("m_ex__yaoming_times")
  end,
  mute = true,
  card_num = 0,
  target_num = 1,
  prompt = "#m_ex__yaoming",
  interaction = function()
    return UI.ComboBox {choices = { "m_ex__yaoming_draw", "m_ex__yaoming_throw" } }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to, selected)
    if #selected > 0 or not self.interaction.data then return false end
    if self.interaction.data == "m_ex__yaoming_throw" then
      return player ~= to and not to:isNude() and to:getHandcardNum() >= player:getHandcardNum()
    else
      return to:getHandcardNum() <= Self:getHandcardNum()
    end
  end,
  can_use = function(self, player)
    return player:getMark("m_ex__yaoming_times") > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local choice = self.interaction.data
    local mark = choice.."_mark"
    if player:getMark("@m_ex__yaoming") ~= 0 and player:getMark("@m_ex__yaoming") ~= mark then
      room:setPlayerMark(player, "@m_ex__yaoming", 0)
    else
      room:removePlayerMark(player, "m_ex__yaoming_times")
      room:setPlayerMark(player, "@m_ex__yaoming", mark)
    end
    local to = effect.tos[1]
    player:broadcastSkillInvoke(yaoming.name)
    if choice == "m_ex__yaoming_throw" then
      room:notifySkillInvoked(player, yaoming.name, "control", {to.id})
      local id = room:askToChooseCard(player, {target = to, flag = "he", skill_name = yaoming.name})
      room:throwCard({id}, yaoming.name, to, player)
    else
      room:notifySkillInvoked(player, yaoming.name, "drawcard", {to.id})
      to:drawCards(1, yaoming.name)
    end
  end,
})

yaoming:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yaoming.name)
  end,
  on_cost = function (self, event, target, player, data)
    local _, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "m_ex__yaoming",
      prompt = "#m_ex__yaoming",
      cancelable = true,
      skip = true,
    })
    if dat then
      event:setCostData(self, {tos = dat.targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skill = Fk.skills["m_ex__yaoming"]
    if skill and skill:isInstanceOf(ActiveSkill) then
      local skill_data = SkillUseData:new{from = player, tos = event:getCostData(self).tos, cards = {}}
      skill:onUse(player.room, skill_data)
    end
  end,
})

--- 受伤攒次数这下不算发动技能
yaoming:addEffect(fk.Damaged, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(yaoming.name) and player:getMark("m_ex__yaoming_times") < 4
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "m_ex__yaoming_times")
  end,
})

yaoming:addAcquireEffect(function (self, player)
  player.room:setPlayerMark(player, "m_ex__yaoming_times", 2)
end)

yaoming:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "m_ex__yaoming_times", 0)
  player.room:setPlayerMark(player, "@m_ex__yaoming", 0)
end)

Fk:loadTranslationTable{
  --- 经谋诸葛瑾测试，不是蓄力技
  ["m_ex__yaoming"] = "邀名",
  [":m_ex__yaoming"] = "剩余可用X次（X初始为2且最大为4），出牌阶段或当你受到伤害后，你可以选择一项：1.弃置手牌数不小于你的一名其他角色的一张牌；2.令手牌数不大于你的一名角色摸一张牌。若与你上次选择的选项不同，则剩余可用次数+1，并清除已记录的选项。当你受到1点伤害后，剩余可用次数+1。",

  ["#m_ex__yaoming"] = "你可发动 邀名，弃置一名角色一张牌或令其摸一张牌",
  ["m_ex__yaoming_throw"] = "弃置手牌数不小于你的其他角色一张牌",
  ["m_ex__yaoming_draw"] = "令手牌数不大于你的一名角色摸一张牌",
  ["@m_ex__yaoming"] = "邀名",
  ["m_ex__yaoming_throw_mark"] = "弃牌",
  ["m_ex__yaoming_draw_mark"] = "摸牌",

  ["$m_ex__yaoming1"] = "山不让纤介，而成其危；海不辞丰盈，而成其邃。",
  ["$m_ex__yaoming2"] = "取上方可得中，取下则无所得矣。",
}

return yaoming
