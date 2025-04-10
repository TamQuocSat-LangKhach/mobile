local mutao = fk.CreateSkill{
  name = "mobile__mutao",
}

Fk:loadTranslationTable{
  ["mobile__mutao"] = "募讨",
  [":mobile__mutao"] = "出牌阶段限一次，你可以选择一名角色，令其将手牌中的【杀】依次随机交给由其下家开始的每一名角色，"..
  "然后其对最后一名角色造成X点伤害（X为最后一名角色手牌中【杀】的数量且至多为2）。",

  ["#mobile__mutao"] = "募讨：选择一名角色分发其手牌中的【杀】，对最后一名角色造成伤害",

  ["$mobile__mutao1"] = "今起义兵，只为还天下清明！",
  ["$mobile__mutao2"] = "董贼不除，汉室如何可兴？",
}

mutao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#mobile__mutao",
  can_use = function(self, player)
    return player:usedSkillTimes(mutao.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not to_select:isKongcheng() and to_select:getNextAlive() ~= to_select
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    local to = target
    local cids = table.filter(target:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash"
    end)
    local num = #cids
    for _ = 1, num do
      if #cids < 1 then break end
      to = to:getNextAlive()
      local id = table.random(cids)
      if to ~= target then
        room:moveCardTo(id, Player.Hand, to, fk.ReasonGive, mutao.name, nil, false)
      end
      cids = table.filter(cids, function(i)
        return table.contains(target:getCardIds("h"), i)
      end)
    end
    num = math.min(#table.filter(to:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash"
    end), 2)
    if num > 0 and not to.dead then
      room:damage{
        from = target,
        to = to,
        damage = num,
        skillName = mutao.name,
      }
    end
  end,
})

return mutao
