local powei_active = fk.CreateSkill {
  name = "powei_active",
}

Fk:loadTranslationTable{
  ["powei_active"] = "破围",
}

powei_active:addEffect("active", {
  interaction = function(self, player)
    local all_choices = {"powei_damage", "powei_prey"}
    local choices = table.simpleClone(all_choices)
    if Fk:currentRoom().current.hp > player.hp then
      table.remove(choices, 2)
    end
    if #choices == 0 then return end
    return UI.ComboBox { choices = choices , all_choices = all_choices}
  end,
  target_num = 0,
  card_filter = function (self, player, to_select, selected)
    if self.interaction.data == "powei_damage" then
      return #selected == 0 and table.contains(player:getCardIds("h"), to_select) and
        not player:prohibitDiscard(to_select)
    else
      return false
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    if self.interaction.data == "powei_damage" then
      return #selected_cards == 1
    else
      return #selected_cards == 0
    end
  end,
})

return powei_active
