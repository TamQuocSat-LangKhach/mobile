local anda_active = fk.CreateSkill {
  name = "anda_active",
}

Fk:loadTranslationTable{
  ["anda_active"] = "谙达",
}

anda_active:addEffect("active", {
  card_num = 2,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return table.every(selected, function(id)
      return Fk:getCardById(to_select):compareColorWith(Fk:getCardById(id), true)
    end)
  end,
})

return anda_active
