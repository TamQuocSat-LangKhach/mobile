local miewu = fk.CreateSkill {
  name = "miewu",
}

Fk:loadTranslationTable{
  ["miewu"] = "灭吴",
  [":miewu"] = "每回合限一次，你可以弃置1个“武库”，将一张牌当做任意一张基本牌或锦囊牌使用或打出；若如此做，你摸一张牌。",

  ["#miewu"] = "灭吴：弃置1枚武库标记，将一张牌当任意基本牌或锦囊牌使用或打出，然后摸一张牌",

  ["$miewu1"] = "倾荡之势已成，石城尽在眼下",
  ["$miewu2"] = "吾军势如破竹，江东六郡唾手可得。",
}

local U = require "packages/utility/utility"

miewu:addEffect("viewas", {
  pattern = ".",
  prompt = "#miewu",
  interaction = function(self, player)
    local all_names = U.getAllCardNames("btd")
    local names = U.getViewAsCardNames(player, miewu.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = miewu.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:removePlayerMark(player, "@wuku")
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@wuku") > 0 and player:usedSkillTimes(miewu.name) == 0
  end,
  enabled_at_response = function(self, player, response)
    return player:getMark("@wuku") > 0 and player:usedSkillTimes(miewu.name) == 0
  end,
})

local miewu_spec = {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, miewu.name) and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, miewu.name)
  end,
}

miewu:addEffect(fk.CardUseFinished, miewu_spec)
miewu:addEffect(fk.CardRespondFinished, miewu_spec)

return miewu
