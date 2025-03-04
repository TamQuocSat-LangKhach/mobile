local miaolue = fk.CreateSkill{
  name = "miaolue",
}

Fk:loadTranslationTable{
  ["miaolue"] = "妙略",
  [":miaolue"] = "游戏开始时，你获得两张<a href='underhanding_href'>【瞒天过海】</a>；当你受到伤害后，你可以选择一项：" ..
  "1.摸两张牌；2.从牌堆或弃牌堆获得一张你指定的<a href='bag_of_tricks'>智囊</a>。",

  ["miaolue_zhinang"] = "获得一张你指定的智囊",
  ["#miaolue-ask"] = "妙略：选择要获得的一种“智囊”",

  ["$miaolue1"] = "",
  ["$miaolue2"] = "",
}

local U = require "packages/utility/utility"

miaolue:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(miaolue.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local miaolue_derivecards = {
      {"underhanding", Card.Heart, 5},
      {"underhanding", Card.Diamond, 5},
    }
    local cids = table.filter(U.prepareDeriveCards(room, miaolue_derivecards, "miaolue_derivecards"), function (id)
      return room:getCardArea(id) == Card.Void
    end)
    if #cids > 0 then
      room:obtainCard(player, cids, false, fk.ReasonPrey, player, miaolue.name, MarkEnum.DestructIntoDiscard)
    end
  end,
})
miaolue:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"draw2", "miaolue_zhinang", "Cancel"},
      skill_name = miaolue.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == "draw2" then
      player:drawCards(2, miaolue.name)
    else
      local choice = room:askToChoice(player, {
        choices = {"dismantlement", "nullification", "ex_nihilo"},
        skill_name = miaolue.name,
        prompt = "#miaolue-ask",
      })
      local id = room:getCardsFromPileByRule(choice, 1, "allPiles")
      if #id > 0 then
        room:obtainCard(player, id, false, fk.ReasonPrey, player, miaolue.name)
      end
    end
  end,
})

return miaolue
