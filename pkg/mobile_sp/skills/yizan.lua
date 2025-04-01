local yizan = fk.CreateSkill {
  name = "yizan",
}

Fk:loadTranslationTable{
  ["yizan"] = "翊赞",
  [":yizan"] = "你可以将两张牌（其中至少一张是基本牌）当任意基本牌使用或打出。",

  ["#yizan1"] = "翊赞：你可以将两张牌（其中至少一张是基本牌）当任意基本牌使用或打出",
  ["#yizan2"] = "翊赞：你可以将一张基本牌当任意基本牌使用或打出",

  ["$yizan1"] = "承吾父之勇，翊军立阵。",
  ["$yizan2"] = "继先帝之志，季兴大汉。",
}

local U = require "packages/utility/utility"

yizan:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, selected, selected_cards)
    if Self:usedSkillTimes("longyuan", Player.HistoryGame) > 0 then
      return "#yizan2"
    else
      return "#yizan1"
    end
  end,
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(yizan.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    if #selected == 0 then
      return card.type == Card.TypeBasic
    elseif Self:usedSkillTimes("longyuan", Player.HistoryGame) == 0 then
      return #selected == 1
    else
      return false
    end
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    if Self:usedSkillTimes("longyuan", Player.HistoryGame) > 0 then
      if #cards ~= 1 then return end
    else
      if #cards ~= 2 then return end
    end
    if not table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeBasic end) then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = yizan.name
    return card
  end,
})

return yizan
