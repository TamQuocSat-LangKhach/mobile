local xuanfeng = fk.CreateSkill {
  name = "m_ex__xuanfeng_active",
}

Fk:loadTranslationTable{
  ["m_ex__xuanfeng_active"] = "旋风",
}

xuanfeng:addEffect("active", {
  card_filter = Util.FalseFunc,
  interaction = function(self, player)
    return UI.ComboBox { choices = {"m_ex__xuanfeng_discard", "m_ex__xuanfeng_movecard"}}
  end,
  target_filter = function(self, player, to_select, selected)
    if to_select == player then return false end
    if self.interaction.data == "m_ex__xuanfeng_movecard" then
      if #selected == 0 then
        return #to_select:getCardIds(Player.Equip) > 0
      elseif #selected == 1 then
        return selected[1]:canMoveCardsInBoardTo(to_select, "e") or to_select:canMoveCardsInBoardTo(selected[1], "e")
      end
    else
      return #selected == 0 and not to_select:isNude()
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if self.interaction.data == "m_ex__xuanfeng_movecard" then
      return #selected == 2
    end
    return #selected == 1
  end,
})

return xuanfeng
