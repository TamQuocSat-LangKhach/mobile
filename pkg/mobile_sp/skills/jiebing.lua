local jiebing = fk.CreateSkill{
  name = "jiebing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiebing"] = "借兵",
  [":jiebing"] = "锁定技，当你受到伤害后，你选择除伤害来源外的一名其他角色，随机获得其一张牌并展示之，若此牌为装备牌，则你使用之。",

  ["#jiebing-choose"] = "借兵：选择一名角色，随机获得其一张牌",

  ["$jiebing1"] = "敌寇势大，情况危急，只能多谢阁下。",
  ["$jiebing2"] = "将军借兵之恩，阜退敌后自当报还。",
}

jiebing:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiebing.name) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude() and data.from ~= p
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude() and p ~= data.from
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = jiebing.name,
      prompt = "#jiebing-choose",
      cancelable = false,
    })[1]
    local id = table.random(to:getCardIds("he"))
    room:obtainCard(player, id, false, fk.ReasonPrey)
    if not table.contains(player:getCardIds("h"), id) or player.dead then return end
    player:showCards({id})
    if not table.contains(player:getCardIds("h"), id) or player.dead then return end
    if Fk:getCardById(id).type == Card.TypeEquip and not player:isProhibited(player, Fk:getCardById(id)) then
      room:useCard({
        from = player,
        tos = {player},
        card = Fk:getCardById(id),
      })
    end
  end,
})

return jiebing
