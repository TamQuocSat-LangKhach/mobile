local sk = fk.CreateSkill {
  name = "#ex_crossbow_skill",
  tags = { Skill.Compulsory },
}

sk:addEffect("targetmod", {
  attached_equip = "ex_crossbow",
  bypass_times = function(self, player, skill, scope, card)
    if player:hasSkill(skill.name) and card and card.trueName == "slash_skill" and scope == Player.HistoryPhase then
      --FIXME: 无法检测到非转化的cost选牌的情况，如活墨等
      local cardIds = Card:getIdList(card)
      local crossbows = table.filter(player:getEquipments(Card.SubtypeWeapon), function(id)
        return self.attached_equip == Fk:getCardById(id).name
      end)
      return #crossbows == 0 or not table.every(crossbows, function(id)
        return table.contains(cardIds, id)
      end)
    end
  end,
})
sk:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(sk.name) and player.phase == Player.Play and
      data.card.trueName == "slash" and player:usedCardTimes("slash", Player.HistoryPhase) > 1
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/mobile/audio/card/ex_crossbow")
    room:setEmotion(player, "./packages/standard_cards/image/anim/crossbow")
    room:sendLog{
      type = "#InvokeSkill",
      from = player.id,
      arg = "ex_crossbow",
    }
  end,
})

return sk
