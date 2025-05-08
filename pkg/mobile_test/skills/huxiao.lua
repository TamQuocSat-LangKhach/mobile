local huxiao = fk.CreateSkill {
  name = "mobile__huxiao",
}

Fk:loadTranslationTable{
  ["mobile__huxiao"] = "虎啸",
  [":mobile__huxiao"] = "出牌阶段限一次，你可以选择一项：1.对一名体力值不小于你的角色造成1点火焰伤害；2.本回合使用牌无距离限制；"..
  "背水：弃置一张红色牌。",

  ["mobile__huxiao_damage"] = "对一名体力值不小于你的角色造成1点火焰伤害",
  ["mobile__huxiao_use"] = "本回合使用牌无距离限制",
  ["mobile__huxiao_beishui"] = "背水：弃置一张红色牌",
  ["@@mobile__huxiao-turn"] = "虎啸",

  ["$mobile__huxiao1"] = "",
  ["$mobile__huxiao2"] = "",
}

huxiao:addEffect("active", {
  anim_type = "offensive",
  min_card_num = 0,
  max_card_num = 1,
  min_target_num = 0,
  max_target_num = 1,
  interaction = UI.ComboBox { choices = {"mobile__huxiao_damage", "mobile__huxiao_use", "mobile__huxiao_beishui"} },
  can_use = function(self, player)
    return player:usedSkillTimes(huxiao.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, player, to_select, selected)
    if self.interaction.data == "mobile__huxiao_beishui" then
      return #selected == 0 and Fk:getCardById(to_select).color == Card.Red and not player:prohibitDiscard(to_select)
    end
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if self.interaction.data ~= "mobile__huxiao_use" then
      return #selected == 0 and to_select.hp >= player.hp
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if self.interaction.data == "mobile__huxiao_damage" then
      return #selected == 1 and #selected_cards == 0
    elseif self.interaction.data == "mobile__huxiao_use" then
      return #selected == 0 and #selected_cards == 0
    elseif self.interaction.data == "mobile__huxiao_beishui" then
      return #selected == 1 and #selected_cards == 1
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if self.interaction.data ~= "mobile__huxiao_damage" then
      room:setPlayerMark(player, "@@mobile__huxiao-turn", 1)
    end
    if #effect.cards > 0 then
      room:throwCard(effect.cards, huxiao.name, player, player)
    end
    if self.interaction.data ~= "mobile__huxiao_use" then
      local target = effect.tos[1]
      if not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = huxiao.name,
        }
      end
    end
  end,
})

huxiao:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and player:getMark("@@mobile__huxiao-turn") > 0
  end,
})

return huxiao
