local baoxi_viewas = fk.CreateSkill {
  name = "baoxi_viewas",
}

Fk:loadTranslationTable{
  ["baoxi_viewas"] = "暴袭",
}

baoxi_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(true), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(player:getMark("baoxiUseCard"))
    card.skillName = "baoxi"
    card:addSubcard(cards[1])
    return card
  end,
})

return baoxi_viewas
