local extension = Package:new("mobile_derived", Package.CardPack)
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["mobile_derived"] = "手杀衍生牌",
}

local raidAndFrontalAttackSkill = fk.CreateActiveSkill{
  name = "raid_and_frontal_attack_skill",
  can_use = Util.CanUse,
  target_filter = Util.TargetFilter,
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card)
    return user.id ~= to_select
  end,
  on_effect = function(self, room, effect)
    local cardResponded = room:askForResponse(room:getPlayerById(effect.to), "raid_and_frontal_attack", "slash,jink", "#RFA-response:" .. effect.from, true, nil, effect)

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
          damage = 1,
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
  is_damage_card = true,
  skill = raidAndFrontalAttackSkill,
}
Fk:loadTranslationTable{
  ["raid_and_frontal_attack"] = "奇正相生",
  [":raid_and_frontal_attack"] = "出牌阶段，对一名其他角色使用。当此牌指定目标后，你为其指定“奇兵”或“正兵”。目标角色可以打出一张【杀】或【闪】，然后若其为：“正兵”目标且未打出【杀】，你对其造成1点伤害；“奇兵”目标且未打出【闪】，你获得其一张牌。",
  ["raid_and_frontal_attack_skill"] = "奇正相生",
  ["RFA_raid"] = "奇兵",
  ["RFA_frontal"] = "正兵",
  ["#RFA-response"] = "正兵：未出闪，%src获得你牌；奇兵：未出杀，你受到其伤害",
  ["#RFA-choose"] = "正兵：%dest不出闪，你获得其牌；奇兵：其不出杀，其受到伤害",
  ["slash,jink"] = "杀或闪", -- FIXME
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
      player:drawCards(2, "ex_silver_lion")
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
  ["#ex_nioh_shield_skill"] = "仁王金刚盾",

  ["ex_vine"] = "桐油百韧甲",
  [":ex_vine"] = "装备牌·防具<br /><b>防具技能</b>：锁定技。【南蛮入侵】、【万箭齐发】和普通【杀】对你无效。你不能被横置。每当你受到火焰伤害时，此伤害+1。",
  ["#ex_vine_skill"] = "桐油百韧甲",

  ["ex_silver_lion"] = "照月狮子盔",
  [":ex_silver_lion"] = "装备牌·防具<br /><b>防具技能</b>：锁定技。每当你受到伤害时，若此伤害大于1点，防止多余的伤害。每当你失去装备区里的【照月狮子盔】后，你回复1点体力并摸两张牌。",
  ["#ex_silver_lion_skill"] = "照月狮子盔",
}

local mobile__catapult_skill = fk.CreateTriggerSkill{
  name = "#mobile__catapult_skill",
  attached_equip = "mobile__catapult",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and data.to ~= player and #data.to:getCardIds("e") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#mobile__catapult-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(data.to:getCardIds("e"), self.name, data.to, player)
  end,
}
Fk:addSkill(mobile__catapult_skill)
local mobile__catapult = fk.CreateWeapon{
  name = "&mobile__catapult",
  suit = Card.Diamond,
  number = 9,
  attack_range = 9,
  equip_skill = mobile__catapult_skill,
}
extension:addCard(mobile__catapult)
Fk:loadTranslationTable{
  ["mobile__catapult"] = "霹雳车",
  [":mobile__catapult"] = "装备牌·武器<br /><b>攻击范围</b>：9<br /><b>武器技能</b>：当你对其他角色造成伤害后，你可以弃置其装备区内的所有牌。",
  ["#mobile__catapult_skill"] = "霹雳车",
  ["#mobile__catapult-invoke"] = "霹雳车：你可以弃置 %dest 装备区内的所有牌",
}

local offensiveSiegeEngineSkill = fk.CreateTriggerSkill{
  name = "#offensive_siege_engine_skill",
  attached_equip = "offensive_siege_engine",
  events = {fk.AfterCardsMove, fk.BeforeCardsMove, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then
      return false
    end

    if event == fk.AfterCardsMove then
      return
        #player:getCardIds("e") > 1 and
        table.find(
          data,
          function(move)
            return
              move.to == player.id and
              move.toArea == Card.PlayerEquip and
              table.find(
                move.moveInfo,
                function(info)
                  return
                    Fk:getCardById(info.cardId).name == "offensive_siege_engine" and
                    not player:prohibitDiscard(info.cardId)
                end
              )
          end
        )
    elseif event == fk.BeforeCardsMove then
      return
        table.find(
          data,
          function(move)
            return
              (move.to == player.id and move.toArea == Card.PlayerEquip) or
              (
                move.skillName ~= "quchong" and
                move.skillName ~= "gamerule_aborted" and
                move.skillName ~= self.name and
                move.from == player.id and
                table.find(
                  move.moveInfo,
                  function(info)
                    return
                      Fk:getCardById(info.cardId).name == "offensive_siege_engine" and
                      info.fromArea == Card.PlayerEquip
                  end
                )
              )
          end
        )
    end

    return target == player
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      local room = player.room
      return
        room:askForSkillInvoke(
          player,
          self.name,
          data,
          "#offensive_siege_engine-invoke::" .. data.to.id .. ":" .. math.min(room:getBanner("RoundCount"), 3)
        )
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local toRemove = table.filter(
        player:getCardIds("e"),
        function(id) return Fk:getCardById(id).name ~= "offensive_siege_engine" end
      )

      room:throwCard(toRemove, self.name, player, player)
    elseif event == fk.BeforeCardsMove then
      local toVoid = {}
      local toRemoveIndex = {}
      for index, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerEquip then
          move.to = nil
          move.toArea = Card.DiscardPile
        end

        if
          move.skillName ~= "quchong" and
          move.skillName ~= "gamerule_aborted" and
          move.skillName ~= self.name and
          move.from == player.id
        then
          local newMoveInfos = {}
          for _, info in ipairs(move.moveInfo) do
            if
              Fk:getCardById(info.cardId).name == "offensive_siege_engine" and
              info.fromArea == Card.PlayerEquip
            then
              local durability = player:getMark("@offensive_siege_engine_durability")
              durability = math.max(durability - 1, 0)
              room:setPlayerMark(player, "@offensive_siege_engine_durability", durability)
              if durability < 1 then
                table.insert(toVoid, info)
              end
            else
              table.insert(newMoveInfos, info)
            end
          end

          if #move.moveInfo > #newMoveInfos then
            move.moveInfo = newMoveInfos
            if #newMoveInfos == 0 then
              table.insert(toRemoveIndex, index)
            end
          end
        end
      end

      if #toRemoveIndex > 0 then
        for i, index in ipairs(toRemoveIndex) do
          table.remove(data, index - (i - 1))
        end
      end

      if #toVoid > 0 then
        room:sendLog{ type = "#destructDerivedCards", card = table.map(toVoid, function(info) return info.cardId end) }
        local newMoveData = {
          moveInfo = toVoid,
          from = player.id,
          toArea = Card.Void,
          moveReason = fk.ReasonPut,
          skillName = self.name,
        }
        table.insert(data, newMoveData)
      end

      if #data == 0 then
        return true
      end
    else
      local durability = player:getMark("@offensive_siege_engine_durability")
      durability = math.max(durability - 1, 0)
      room:setPlayerMark(player, "@offensive_siege_engine_durability", durability)
      if durability < 1 then
        local siegeEngines = table.filter(
          player:getCardIds("e"),
          function(id) return Fk:getCardById(id).name == "offensive_siege_engine" end
        )
        room:sendLog{ type = "#destructDerivedCards", card = siegeEngines }
        room:moveCards{
          ids = siegeEngines,
          from = player.id,
          toArea = Card.Void,
          skillName = self.name,
          moveReason = fk.ReasonJustMove
        }
      end

      data.damage = data.damage + math.min(room:getBanner("RoundCount"), 3)
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function (self, event, target, player, data)
    return
      table.find(
        data,
        function(move)
          return
            (
              (move.skillName == "quchong" and move.moveReason == fk.ReasonRecast) or
              move.skillName == "gamerule_aborted" or
              not player:hasSkill(self)
            ) and
            move.from == player.id and
            move.toArea ~= Card.Void and
            table.find(
              move.moveInfo,
              function(info)
                return
                  Fk:getCardById(info.cardId).name == "offensive_siege_engine" and
                  info.fromArea == Card.PlayerEquip
              end
            )
        end
      )
  end,
  on_refresh = function (self, event, target, player, data)
    local mirror_moves = {}
    local to_void = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea ~= Card.Void then
        local move_info = {}
        local mirror_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if Fk:getCardById(id).name == "offensive_siege_engine" and info.fromArea == Card.PlayerEquip then
              table.insert(mirror_info, info)
              table.insert(to_void, id)
          else
            table.insert(move_info, info)
          end
        end
        move.moveInfo = move_info
        if #mirror_info > 0 then
          local mirror_move = table.clone(move)
          mirror_move.to = nil
          mirror_move.toArea = Card.Void
          mirror_move.moveInfo = mirror_info
          mirror_move.skillName = self.name
          table.insert(mirror_moves, mirror_move)
        end
      end
    end
    if #to_void > 0 then
      local room = player.room
      table.insertTable(data, mirror_moves)
      room:sendLog{ type = "#destructDerivedCards", card = to_void, }
      room:setPlayerMark(player, "@offensive_siege_engine_durability", 0)
      for _, id in ipairs(to_void) do
        room:setCardMark(Fk:getCardById(id), "offensive_siege_engine_durability", 0)
      end
    end
  end,
}
Fk:addSkill(offensiveSiegeEngineSkill)
local offensiveSiegeEngine = fk.CreateWeapon{
  name = "&offensive_siege_engine",
  suit = Card.Diamond,
  number = 1,
  attack_range = 9,
  equip_skill = offensiveSiegeEngineSkill,
  on_install = function(self, room, player)
    local cardMark = self:getMark("offensive_siege_engine_durability")
    if cardMark == 0 then
      room:setPlayerMark(player, "@offensive_siege_engine_durability", 2)
      room:setCardMark(self, "offensive_siege_engine_durability", 2)
    else
      room:setPlayerMark(player, "@offensive_siege_engine_durability", cardMark)
    end
    Weapon.onInstall(self, room, player)
  end,
  on_uninstall = function(self, room, player)
    room:setCardMark(self, "offensive_siege_engine_durability", player:getMark("@offensive_siege_engine_durability"))
    room:setPlayerMark(player, "@offensive_siege_engine_durability", 0)
    Weapon.onUninstall(self, room, player)
  end,
}
extension:addCard(offensiveSiegeEngine)
Fk:loadTranslationTable{
  ["offensive_siege_engine"] = "大攻车·进击",
  [":offensive_siege_engine"] = "装备牌·武器<br /><b>攻击范围</b>：9<br /><b>耐久度</b>：2<br />" ..
  "<b>武器技能</b>：当此牌进入装备区后，弃置你装备区里的其他牌；当其他装备牌进入装备区前，改为将之置入弃牌堆；" ..
  "当你造成伤害时，你可以令此牌减1点耐久度，令此伤害+X（X为游戏轮数且至多为3）；当此牌不因“渠冲”而离开装备区时，防止之，然后此牌-1点耐久度；" ..
  "当此牌耐久度减至0时，销毁此牌。",
  ["#offensive_siege_engine_skill"] = "大攻车·进击",
  ["@offensive_siege_engine_durability"] = "进击耐久",
  ["#offensive_siege_engine"] = "大攻车·进击",
  ["#offensive_siege_engine-invoke"] = "大攻车·进击：你可令【大攻车】减一点耐久度，使对 %dest 造成的伤害+%arg",
}

local defensiveSiegeEngineSkill = fk.CreateTriggerSkill{
  name = "#defensive_siege_engine_skill",
  attached_equip = "defensive_siege_engine",
  events = {fk.AfterCardsMove, fk.BeforeCardsMove, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then
      return false
    end

    if event == fk.AfterCardsMove then
      return
        #player:getCardIds("e") > 1 and
        table.find(
          data,
          function(move)
            return
              move.to == player.id and
              move.toArea == Card.PlayerEquip and
              table.find(
                move.moveInfo,
                function(info)
                  return
                    Fk:getCardById(info.cardId).name == "defensive_siege_engine" and
                    not player:prohibitDiscard(info.cardId)
                end
              )
          end
        )
    elseif event == fk.BeforeCardsMove then
      return
        table.find(
          data,
          function(move)
            return
              (move.to == player.id and move.toArea == Card.PlayerEquip) or
              (
                move.skillName ~= "quchong" and
                move.skillName ~= "gamerule_aborted" and
                move.skillName ~= self.name and
                move.from == player.id and
                table.find(
                  move.moveInfo,
                  function(info)
                    return
                      Fk:getCardById(info.cardId).name == "defensive_siege_engine" and
                      info.fromArea == Card.PlayerEquip
                  end
                )
              )
          end
        )
    end

    return target == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local toRemove = table.filter(
        player:getCardIds("e"),
        function(id) return Fk:getCardById(id).name ~= "defensive_siege_engine" end
      )

      room:throwCard(toRemove, self.name, player, player)
    elseif event == fk.BeforeCardsMove then
      local toVoid = {}
      local toRemoveIndex = {}
      for index, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerEquip then
          move.to = nil
          move.toArea = Card.DiscardPile
        end

        if
          move.skillName ~= "quchong" and
          move.skillName ~= "gamerule_aborted" and
          move.skillName ~= self.name and
          move.from == player.id
        then
          local newMoveInfos = {}
          for _, info in ipairs(move.moveInfo) do
            if
              Fk:getCardById(info.cardId).name == "defensive_siege_engine" and
              info.fromArea == Card.PlayerEquip
            then
              local durability = player:getMark("@defensive_siege_engine_durability")
              durability = math.max(durability - 1, 0)
              room:setPlayerMark(player, "@defensive_siege_engine_durability", durability)
              if durability < 1 then
                table.insert(toVoid, info)
              end
            else
              table.insert(newMoveInfos, info)
            end
          end

          if #move.moveInfo > #newMoveInfos then
            move.moveInfo = newMoveInfos
            if #newMoveInfos == 0 then
              table.insert(toRemoveIndex, index)
            end
          end
        end
      end

      if #toRemoveIndex > 0 then
        for i, index in ipairs(toRemoveIndex) do
          table.remove(data, index - (i - 1))
        end
      end

      if #toVoid > 0 then
        room:sendLog{ type = "#destructDerivedCards", card = table.map(toVoid, function(info) return info.cardId end) }
        local newMoveData = {
          moveInfo = toVoid,
          from = player.id,
          toArea = Card.Void,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
        }
        table.insert(data, newMoveData)
      end

      if #data == 0 then
        return true
      end
    else
      local durability = player:getMark("@defensive_siege_engine_durability")
      local newDurability = math.max(durability - data.damage, 0)
      room:setPlayerMark(player, "@defensive_siege_engine_durability", newDurability)
      if newDurability < 1 then
        local siegeEngines = table.filter(
          player:getCardIds("e"),
          function(id) return Fk:getCardById(id).name == "defensive_siege_engine" end
        )
        room:sendLog{ type = "#destructDerivedCards", card = siegeEngines }
        room:moveCards{
          ids = siegeEngines,
          from = player.id,
          toArea = Card.Void,
          skillName = self.name,
          moveReason = fk.ReasonJustMove
        }
      end

      data.damage = math.max(data.damage - durability, 0)
      if data.damage < 1 then
        return true
      end
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function (self, event, target, player, data)
    return
      table.find(
        data,
        function(move)
          return
            (
              (move.skillName == "quchong" and move.moveReason == fk.ReasonRecast) or
              move.skillName == "gamerule_aborted" or
              not player:hasSkill(self)
            ) and
            move.from == player.id and
            move.toArea ~= Card.Void and
            table.find(
              move.moveInfo,
              function(info)
                return
                  Fk:getCardById(info.cardId).name == "defensive_siege_engine" and
                  info.fromArea == Card.PlayerEquip
              end
            )
        end
      )
  end,
  on_refresh = function (self, event, target, player, data)
    local mirror_moves = {}
    local to_void = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea ~= Card.Void then
        local move_info = {}
        local mirror_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if Fk:getCardById(id).name == "defensive_siege_engine" and info.fromArea == Card.PlayerEquip then
            table.insert(mirror_info, info)
            table.insert(to_void, id)
          else
            table.insert(move_info, info)
          end
        end
        move.moveInfo = move_info
        if #mirror_info > 0 then
          local mirror_move = table.clone(move)
          mirror_move.to = nil
          mirror_move.toArea = Card.Void
          mirror_move.moveInfo = mirror_info
          mirror_move.skillName = self.name
          table.insert(mirror_moves, mirror_move)
        end
      end
    end
    if #to_void > 0 then
      local room = player.room
      table.insertTable(data, mirror_moves)
      room:sendLog{ type = "#destructDerivedCards", card = to_void, }
      room:setPlayerMark(player, "@defensive_siege_engine_durability", 0)
      for _, id in ipairs(to_void) do
        room:setCardMark(Fk:getCardById(id), "defensive_siege_engine_durability", 0)
      end
    end
  end,
}
Fk:addSkill(defensiveSiegeEngineSkill)
local defensiveSiegeEngine = fk.CreateWeapon{
  name = "&defensive_siege_engine",
  suit = Card.Diamond,
  number = 1,
  attack_range = 9,
  equip_skill = defensiveSiegeEngineSkill,
  on_install = function(self, room, player)
    local cardMark = self:getMark("defensive_siege_engine_durability")
    if cardMark == 0 then
      room:setPlayerMark(player, "@defensive_siege_engine_durability", 3)
      room:setCardMark(self, "defensive_siege_engine_durability", 3)
    else
      room:setPlayerMark(player, "@defensive_siege_engine_durability", cardMark)
    end
    Weapon.onInstall(self, room, player)
  end,
  on_uninstall = function(self, room, player)
    room:setCardMark(self, "defensive_siege_engine_durability", player:getMark("@defensive_siege_engine_durability"))
    room:setPlayerMark(player, "@defensive_siege_engine_durability", 0)
    Weapon.onUninstall(self, room, player)
  end,
}
extension:addCard(defensiveSiegeEngine)
Fk:loadTranslationTable{
  ["defensive_siege_engine"] = "大攻车·守御",
  [":defensive_siege_engine"] = "装备牌·武器<br /><b>攻击范围</b>：9<br /><b>耐久度</b>：3<br />" ..
  "<b>武器技能</b>：当此牌进入装备区后，弃置你装备区里的其他牌；当其他装备牌进入装备区前，改为将之置入弃牌堆；" ..
  "当你受到伤害时，此牌减等量点耐久度（不足则全减），令此伤害-X（X为减少的耐久度）；当此牌不因“渠冲”而离开装备区时，防止之，然后此牌减1点耐久度；" ..
  "当此牌耐久度减至0时，销毁此牌。",
  ["#defensive_siege_engine_skill"] = "大攻车·守御",
  ["@defensive_siege_engine_durability"] = "守御耐久",
  ["#defensive_siege_engine"] = "大攻车·守御",
}

local enemyAtTheGatesSkill = fk.CreateActiveSkill{
  name = "mobile__enemy_at_the_gates_skill",
  prompt = "#mobile__enemy_at_the_gates_skill",
  can_use = Util.CanUse,
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card)
    return user.id ~= to_select
  end,
  target_filter = Util.TargetFilter,
  on_effect = function(self, room, cardEffectEvent)
    local player = room:getPlayerById(cardEffectEvent.from)
    local to = room:getPlayerById(cardEffectEvent.to)
    local cards = room:getNCards(4)
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    for _, id in ipairs(cards) do
      local card = Fk:getCardById(id)
      if card.trueName == "slash" and not player:prohibitUse(card) and not player:isProhibited(to, card) and to:isAlive() then
        card.skillName = self.name
        room:useCard({
          card = card,
          from = player.id,
          tos = { {to.id} },
          extraUse = true,
        })
      end
    end
    cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #cards > 0 then
      room:delay(#cards * 150)
      room:moveCardTo(table.reverse(cards), Card.DrawPile, nil, fk.ReasonPut, self.name, nil, true, player.id)
    end
  end,
}
local enemyAtTheGates = fk.CreateTrickCard{
  name = "&mobile__enemy_at_the_gates",
  suit = Card.Spade,
  number = 7,
  skill = enemyAtTheGatesSkill,
}
extension:addCards{
  enemyAtTheGates,
}
Fk:loadTranslationTable{
  ["mobile__enemy_at_the_gates"] = "兵临城下",
  [":mobile__enemy_at_the_gates"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名其他角色<br /><b>效果</b>：你展示牌堆顶的四张牌，依次对目标角色使用其中的【杀】，然后将其余的牌以原顺序放回牌堆顶。",
  ["#mobile__enemy_at_the_gates_skill"] = "选择一名其他角色，你展示牌堆顶四张牌，依次对其使用其中【杀】，其余牌放回牌堆顶",
  ["mobile__enemy_at_the_gates_skill"] = "兵临城下",
}

return extension
