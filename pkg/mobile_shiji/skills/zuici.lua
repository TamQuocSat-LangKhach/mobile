local zuici = fk.CreateSkill {
  name = "zuici",
}

Fk:loadTranslationTable{
  ["zuici"] = "罪辞",
  [":zuici"] = "当你受到有〖定仪〗效果的角色造成的伤害后，你可以令其失去〖定仪〗效果，然后其从牌堆中获得你选择的一张智囊牌。",

  ["#zuici-invoke"] = "罪辞：你可以令 %dest 失去“定仪”效果并获得你指定的一种智囊",

  ["$zuici1"] = "既为朝堂宁定，吾请辞便是。",
  ["$zuici2"] = "国事为先，何惧清名有损！",
}

zuici:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zuici.name) and
      data.from and not data.from.dead and data.from:getMark("@dingyi") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"Cancel", "dismantlement", "ex_nihilo", "nullification"},
      skill_name = zuici.name,
      prompt = "#zuici-invoke::"..data.from.id
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {data.from}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(data.from, "@dingyi", 0)
    local cards = room:getCardsFromPileByRule(event:getCostData(self).choice)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, data.from, fk.ReasonJustMove, zuici.name, nil, false, player)
    end
  end,
})

return zuici
