local jieyue = fk.CreateSkill {
  name = "m_ex__jieyue_active",
}

Fk:loadTranslationTable{
  ["m_ex__jieyue_active"] = "节钺",
}

jieyue:addEffect("active", {
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then
      return Fk:currentRoom():getCardArea(to_select) ~= Fk:currentRoom():getCardArea(selected[1])
    end
    return #selected == 0
  end,
  feasible = function(self, player, selected, selected_cards)
    local x = 0
    if #player.player_cards[Player.Hand] > 0 then x = x + 1 end
    if #player.player_cards[Player.Equip] > 0 then x = x + 1 end
    return #selected_cards == x
  end,
})

return jieyue
