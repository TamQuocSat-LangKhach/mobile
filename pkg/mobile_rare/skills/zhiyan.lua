local zhiyan = fk.CreateSkill {
  name = "mxing__zhiyan",
}

Fk:loadTranslationTable{
  ["mxing__zhiyan"] = "治严",
  [":mxing__zhiyan"] = "出牌阶段各限一次，你可以：1.将手牌摸至体力上限，然后你于此阶段内不能对其他角色使用牌；2.将多于体力值的手牌交给一名其他角色。",

  ["#mxing__zhiyan"] = "治严：执行一项",
  ["mxing__zhiyan_draw"] = "将手牌摸至体力上限",
  ["mxing__zhiyan_give"] = "交给其他角色多于体力值的牌",

  ["$mxing__zhiyan1"] = "治军严谨，方得精锐之师。",
  ["$mxing__zhiyan2"] = "精兵当严于律己，束身自修。",
}

zhiyan:addEffect("active", {
  anim_type = "support",
  interaction = function(self, player)
    local choices = {}
    if player:getHandcardNum() < player.maxHp and player:getMark("mxing__zhiyan_draw-phase") == 0 then
      table.insert(choices, "mxing__zhiyan_draw")
    end
    if player:getHandcardNum() > player.hp and player:getMark("mxing__zhiyan_give-phase") == 0 then
      table.insert(choices, "mxing__zhiyan_give")
    end
    if #choices == 0 then return false end
    return UI.ComboBox { choices = choices , all_choices = {"mxing__zhiyan_draw", "mxing__zhiyan_give"}}
  end,
  card_num = function(self, player)
    return self.interaction.data == "mxing__zhiyan_draw" and 0 or (player:getHandcardNum() - player.hp)
  end,
  target_num = function(self)
    return self.interaction.data == "mxing__zhiyan_draw" and 0 or 1
  end,
  can_use = function(self, player)
    return (player:getHandcardNum() < player.maxHp and player:getMark("mxing__zhiyan_draw-phase") == 0) or
      (player:getHandcardNum() > player.hp and player:getMark("mxing__zhiyan_give-phase") == 0)
  end,
  card_filter = function(self, player, to_select, selected)
    return self.interaction.data == "mxing__zhiyan_give" and
      #selected < (player:getHandcardNum() - player.hp) and
      not table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return self.interaction.data == "mxing__zhiyan_give" and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if self.interaction.data == "mxing__zhiyan_draw" then
      room:setPlayerMark(player, "mxing__zhiyan_draw-phase", 1)
      player:drawCards(player.maxHp - player:getHandcardNum(), zhiyan.name)
    else
      room:setPlayerMark(player, "mxing__zhiyan_give-phase", 1)
      room:moveCardTo(effect.cards, Player.Hand, effect.tos[1], fk.ReasonGive, zhiyan.name, nil, false, player)
    end
  end,
})
zhiyan:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and from:getMark("mxing__zhiyan_draw-phase") > 0 and from ~= to
  end,
})

return zhiyan
