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

local crossbowAudio = fk.CreateTriggerSkill{
  name = "#ex_crossbowAudio",
  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      data.card.trueName == "slash" and player:usedCardTimes("slash", Player.HistoryPhase) > 1
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/mobile/audio/card/ex_crossbow")
    room:setEmotion(player, "./packages/standard_cards/image/anim/crossbow")
  end,
}
local crossbowSkill = fk.CreateTargetModSkill{
  name = "#ex_crossbow_skill",
  attached_equip = "ex_crossbow",
  bypass_times = function(self, player, skill, scope)
    if player:hasSkill(self) and skill.trueName == "slash_skill"
      and scope == Player.HistoryPhase then
      return true
    end
  end,
}
crossbowSkill:addRelatedSkill(crossbowAudio)
Fk:addSkill(crossbowSkill)

local crossbow = fk.CreateWeapon{
  name = "&ex_crossbow",
  suit = Card.Club,
  number = 1,
  attack_range = 3,
  equip_skill = crossbowSkill,
}

local eightDiagramSkill = fk.CreateTriggerSkill{
  name = "#ex_eight_diagram_skill",
  attached_equip = "ex_eight_diagram",
  events = {fk.AskForCardUse, fk.AskForCardResponse},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none")))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setEmotion(player, "./packages/standard_cards/image/anim/eight_diagram")
    local judgeData = {
      who = player,
      reason = self.name,
      pattern = ".|.|club,heart,diamond",
    }
    room:judge(judgeData)

    if judgeData.card.suit ~= Card.Spade then
      if event == fk.AskForCardUse then
        data.result = {
          from = player.id,
          card = Fk:cloneCard('jink'),
        }
        data.result.card.skillName = "ex_eight_diagram"

        if data.eventData then
          data.result.toCard = data.eventData.toCard
          data.result.responseToEvent = data.eventData.responseToEvent
        end
      else
        data.result = Fk:cloneCard('jink')
        data.result.skillName = "ex_eight_diagram"
      end

      return true
    end
  end
}
Fk:addSkill(eightDiagramSkill)
local eightDiagram = fk.CreateArmor{
  name = "&ex_eight_diagram",
  suit = Card.Spade,
  number = 2,
  equip_skill = eightDiagramSkill,
}

local niohShieldSkill = fk.CreateTriggerSkill{
  name = "#ex_nioh_shield_skill",
  attached_equip = "ex_nioh_shield",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    local effect = data ---@type CardEffectEvent
    return player.id == effect.to and player:hasSkill(self) and
      effect.card.trueName == "slash" and (effect.card.color == Card.Black or effect.card.suit == Card.Heart)
  end,
  on_use = function(_, _, _, player)
    player.room:setEmotion(player, "./packages/standard_cards/image/anim/nioh_shield")
    return true
  end,
}
Fk:addSkill(niohShieldSkill)
local niohShield = fk.CreateArmor{
  name = "&ex_nioh_shield",
  suit = Card.Club,
  number = 2,
  equip_skill = niohShieldSkill,
}

local vineSkill = fk.CreateTriggerSkill{
  name = "#ex_vine_skill",
  attached_equip = "ex_vine",
  mute = true,
  frequency = Skill.Compulsory,

  events = {fk.PreCardEffect, fk.DamageInflicted, fk.BeforeChainStateChange},
  can_trigger = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      return target == player and player:hasSkill(self) and
        data.damageType == fk.FireDamage
    elseif event == fk.BeforeChainStateChange then
      return target == player and player:hasSkill(self) and not player.chained
    end
    local effect = data ---@type CardEffectEvent
    return player.id == effect.to and player:hasSkill(self) and
      (effect.card.name == "slash" or effect.card.name == "savage_assault" or
      effect.card.name == "archery_attack")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      room:broadcastPlaySound("./packages/mobile/audio/card/ex_vineburn")
      room:setEmotion(player, "./packages/maneuvering/image/anim/vineburn")
      data.damage = data.damage + 1
    else
      room:broadcastPlaySound("./packages/mobile/audio/card/ex_vine")
      room:setEmotion(player, "./packages/maneuvering/image/anim/vine")
      return true
    end
  end,
}
Fk:addSkill(vineSkill)
local vine = fk.CreateArmor{
  name = "&ex_vine",
  equip_skill = vineSkill,
  suit = Card.Club,
  number = 2,
}

local silverLionSkill = fk.CreateTriggerSkill{
  name = "#ex_silver_lion_skill",
  attached_equip = "ex_silver_lion",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.damage > 1
  end,
  on_use = function(_, _, player, _, data)
    player.room:setEmotion(player, "./packages/maneuvering/image/anim/silver_lion")
    data.damage = 1
  end,
}
Fk:addSkill(silverLionSkill)
local silverLion = fk.CreateArmor{
  name = "&ex_silver_lion",
  suit = Card.Club,
  number = 1,
  equip_skill = silverLionSkill,
  on_uninstall = function(self, room, player)
    Armor.onUninstall(self, room, player)
    if player:isAlive() and self.equip_skill:isEffectable(player) then
      room:broadcastPlaySound("./packages/mobile/audio/card/ex_silver_lion")
      room:setEmotion(player, "./packages/maneuvering/image/anim/silver_lion")
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          skillName = self.name
        }
      end
      player:drawCards(2)
    end
  end,
}

extension:addCards({
  crossbow,
  eightDiagram,
  niohShield,
  vine,
  silverLion,
})

Fk:loadTranslationTable{
  ["ex_crossbow"] = "元戎精械弩",
  [":ex_crossbow"] = "装备牌·武器<br /><b>攻击范围</b>：3<br /><b>武器技能</b>：锁定技。你于出牌阶段内使用【杀】无次数限制。",

  ["ex_eight_diagram"] = "先天八卦阵",
  [":ex_eight_diagram"] = "装备牌·防具<br /><b>防具技能</b>：每当你需要使用或打出一张【闪】时，你可以进行判定：若结果不为♠，视为你使用或打出了一张【闪】。",
  ["#ex_eight_diagram_skill"] = "先天八卦阵",

  ["ex_nioh_shield"] = "仁王金刚盾",
  [":ex_nioh_shield"] = '装备牌·防具<br /><b>防具技能</b>：锁定技，黑色【杀】和<font color="red">♥</font>【杀】对你无效。',

  ["ex_vine"] = "桐油百韧甲",
  [":ex_vine"] = "装备牌·防具<br /><b>防具技能</b>：锁定技。【南蛮入侵】、【万箭齐发】和普通【杀】对你无效。你不能被横置。每当你受到火焰伤害时，此伤害+1。",

  ["ex_silver_lion"] = "照月狮子盔",
  [":ex_silver_lion"] = "装备牌·防具<br /><b>防具技能</b>：锁定技。每当你受到伤害时，若此伤害大于1点，防止多余的伤害。每当你失去装备区里的【照月狮子盔】后，你回复1点体力并摸两张牌。",
}

return extension
