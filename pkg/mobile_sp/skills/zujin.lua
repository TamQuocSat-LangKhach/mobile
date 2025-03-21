local zujin = fk.CreateSkill{
  name = "zujin",
}

Fk:loadTranslationTable{
  ["zujin"] = "阻进",
  [":zujin"] = "每回合每种牌名限一次，若你未受伤或体力值不为最低，你可以将一张基本牌当【杀】使用或打出；"..
  "若你已受伤，你可以将一张基本牌当【闪】或【无懈可击】使用或打出。",

  ["#zujin-slash"] = "阻进：你可以将一张基本牌当【杀】使用或打出",
  ["#zujin-jink"] = "阻进：你可以将一张基本牌当【闪】或【无懈可击】使用或打出",

  ["$zujin1"] = "静守待援，不可中诱敌之计。",
  ["$zujin2"] = "错估军情，今唯退守狄道矣。",
  ["$zujin3"] = "蜀军远来必疲，今当先发以制。",
}

local U = require "packages/utility/utility"

zujin:addEffect("viewas", {
  pattern = "slash,jink,nullification",
  prompt = function (self, player)
    if Fk.currentResponsePattern == nil or Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("slash")) then
      return "#zujin-slash"
    else
      return "#zujin-jink"
    end
  end,
  interaction = function(self, player)
    local all_names = {"slash", "jink", "nullification"}
    local names = player:getViewAsCardNames(zujin.name, all_names, nil, player:getTableMark("zujin-turn"))
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = zujin.name
    return card
  end,
  before_use = function(self, player)
    player.room:addTableMark(player, "zujin-turn", self.interaction.data)
  end,
  enabled_at_play = function(self, player)
    return (not player:isWounded() or table.find(Fk:currentRoom().alive_players, function(p)
        return p.hp < player.hp
      end)) and
      #player:getViewAsCardNames(zujin.name, {"slash"}, nil, player:getTableMark("zujin-turn")) > 0
  end,
  enabled_at_response = function(self, player, response)
    if not player:isWounded() or table.find(Fk:currentRoom().alive_players, function(p)
      return p.hp < player.hp
    end) then
      if #player:getViewAsCardNames(zujin.name, {"slash"}, nil, player:getTableMark("zujin-turn")) > 0 then
        return true
      end
    end
    if player:isWounded() then
      if #player:getViewAsCardNames(zujin.name, {"jink", "nullification"}, nil, player:getTableMark("zujin-turn")) > 0 then
        return true
      end
    end
  end,
})

return zujin
