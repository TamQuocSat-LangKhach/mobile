local lianhuan = fk.CreateSkill{
  name = "m_ex__lianhuan",
}

Fk:loadTranslationTable{
  ["m_ex__lianhuan"] = "连环",
  [":m_ex__lianhuan"] = "你可以将一张♣手牌当【铁索连环】使用或重铸，你使用【铁索连环】时可以额外指定一个目标。",

  ["#m_ex__lianhuan"] = "连环：你可以将一张♣手牌当【铁索连环】使用或重铸",
  ["#m_ex__lianhuan-choose"] = "连环：你可以为 %arg 额外指定一个目标",

  ["$m_ex__lianhuan1"] = "将多兵众，不可以敌，使其自累，以杀其势。",
  ["$m_ex__lianhuan2"] = "善用兵者，运巧必防损，立谋虑中变。",
}

lianhuan:addEffect("active", {
  mute = true,
  prompt = "#m_ex__lianhuan",
  card_num = 1,
  min_target_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Club and table.contains(player:getHandlyIds(), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards == 1 then
      local card = Fk:cloneCard("iron_chain")
      card:addSubcard(selected_cards[1])
      card.skillName = lianhuan.name
      return player:canUse(card) and card.skill:targetFilter(player, to_select, selected, selected_cards, card)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    player:broadcastSkillInvoke(lianhuan.name)
    if #effect.tos == 0 then
      room:notifySkillInvoked(player, lianhuan.name, "drawcard")
      room:recastCard(effect.cards, player, lianhuan.name)
    else
      room:notifySkillInvoked(player, lianhuan.name, "control")
      room:sortByAction(effect.tos)
      room:useVirtualCard("iron_chain", effect.cards, player, effect.tos, lianhuan.name)
    end
  end,
})
lianhuan:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(lianhuan.name) and data.card.trueName == "iron_chain" and
      #data:getExtraTargets() > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = data:getExtraTargets(),
      skill_name = lianhuan.name,
      prompt = "#m_ex__lianhuan-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:sendLog{
      type = "#AddTargetsBySkill",
      from = player.id,
      to = {to.id},
      arg = lianhuan.name,
      arg2 = data.card:toLogString()
    }
    data:addTarget(to)
  end,
})

return lianhuan
