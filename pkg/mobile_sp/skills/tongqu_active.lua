local tongquActive = fk.CreateSkill {
  name = "tongqu_active",
}

Fk:loadTranslationTable{
  ["tongqu_active"] = "通渠",
}

tongquActive:addEffect("active", {
  card_num = 1,
  min_target_num = 0,
  max_target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:getMark("@@tongqu") > 0
  end,
  feasible = function (self, player, selected, selected_cards)
    if #selected_cards == 1 then
      if #selected == 0 then
        return not player:prohibitDiscard(Fk:getCardById(selected_cards[1]))
      elseif #selected == 1 then
        return true
      end
    end
  end,
})

return tongquActive
