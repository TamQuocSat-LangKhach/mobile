local extension = Package:new("mobile_derived", Package.CardPack)
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["mobile_derived"] = "手杀衍生牌",
}

local raidAndFrontalAttackSkill = fk.CreateActiveSkill{
  name = "raid_and_frontal_attack_skill",
  target_filter = function(self, to_select, selected, _, card)
    return #selected == 0 and Self ~= Fk:currentRoom():getPlayerById(to_select)
  end,
  target_num = 1,
  on_effect = function(self, room, effect)
    local cardResponded = room:askForResponse(room:getPlayerById(effect.to), "slash,jink", nil, "#RFA-response:" .. effect.from, false, nil, effect)

    if cardResponded then
      room:responseCard({
        from = effect.to,
        card = cardResponded,
        responseToEvent = effect,
      })
    end

    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)

    local RFAChosen = (effect.extra_data or {}).RFAChosen or "RFA_raid"
    if not (cardResponded and cardResponded.trueName == (RFAChosen == "RFA_frontal" and "jink" or "slash")) then
      if RFAChosen == "RFA_raid" then
        room:damage({
          from = from,
          to = to,
          card = effect.card,
          damage = 1 + (effect.additionalDamage or 0),
          damageType = fk.NormalDamage,
          skillName = self.name,
        })
      else
        if not to:isNude() then
          local cardId = room:askForCardChosen(from, to, "he", self.name)
          room:obtainCard(from, cardId, room:getCardArea(cardId) == Player.Equip, fk.ReasonPrey)
        end
      end
    end
  end
}

local raidAndFrontalAttackSkillChoose = fk.CreateTriggerSkill{
  name = "raid_and_frontal_attack_choose",
  global = true,
  priority = 0, -- game rule
  events = { fk.TargetSpecified },
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.name == "raid_and_frontal_attack"
  end,
  on_trigger = function(self, event, target, player, data)
    local choice = player.room:askForChoice(player, { "RFA_frontal", "RFA_raid" }, "raid_and_frontal_attack", "#RFA-choose::" .. data.to)
    data.extra_data = data.extra_data or {}
    data.extra_data.RFAChosen = choice
  end,
}
Fk:addSkill(raidAndFrontalAttackSkillChoose)

local raidAndFrontalAttack = fk.CreateTrickCard{
  name = "&raid_and_frontal_attack",
  suit = Card.Spade,
  number = 2,
  skill = raidAndFrontalAttackSkill,
}
Fk:loadTranslationTable{
  ["raid_and_frontal_attack"] = "奇正相生",
  [":raid_and_frontal_attack"] = "出牌阶段，对一名其他角色使用。当此牌指定目标后，你为其指定“奇兵”或“正兵”。目标角色可以打出一张【杀】或【闪】，然后若其为：“正兵”目标且未打出【杀】，你对其造成1点伤害；“奇兵”目标且未打出【闪】，你获得其一张牌。",
  ["RFA_raid"] = "奇兵",
  ["RFA_frontal"] = "正兵",
  ["#RFA-response"] = "正兵：未出闪，%src获得你牌；奇兵：未出杀，你受到其伤害",
  ["#RFA-choose"] = "正兵：%dest不出闪，你获得其牌；奇兵：其不出杀，其受到伤害",
}

extension:addCards({
  raidAndFrontalAttack,
  raidAndFrontalAttack:clone(Card.Spade, 4),
  raidAndFrontalAttack:clone(Card.Spade, 6),
  raidAndFrontalAttack:clone(Card.Spade, 8),

  raidAndFrontalAttack:clone(Card.Club, 3),
  raidAndFrontalAttack:clone(Card.Club, 5),
  raidAndFrontalAttack:clone(Card.Club, 7),
  raidAndFrontalAttack:clone(Card.Club, 9),
})

return extension
