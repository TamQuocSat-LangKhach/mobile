local extension = Package("sincerity")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["sincerity"] = "信包",
}

local godsunce = General(extension, "godsunce", "god", 1, 6)
Fk:loadTranslationTable{
  ["godsunce"] = "神孙策",
  ["~godsunce"] = "无耻小人！竟敢暗算于我……",
}

local yingba = fk.CreateActiveSkill{
  name = "yingba",
  anim_type = "offensive",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return Self.id ~= to_select and Fk:currentRoom():getPlayerById(to_select).maxHp > 1
  end,
  on_use = function(self, room, effect)
    local to = room:getPlayerById(effect.tos[1])
    room:changeMaxHp(to, -1)
    room:addPlayerMark(to, "@yingba_pingding")

    room:changeMaxHp(room:getPlayerById(effect.from), -1)
  end,
}
Fk:loadTranslationTable{
  ["yingba"] = "英霸",
  [":yingba"] = "出牌阶段限一次，你可以令一名体力上限大于1的其他角色减1点体力上限，并令其获得一枚“平定”标记，然后你减1点体力上限；你对拥有“平定”标记的角色使用牌无距离限制。",
  ["@yingba_pingding"] = "平定",
  ["$yingba1"] = "从我者可免，拒我者难容！",
  ["$yingba2"] = "卧榻之侧，岂容他人鼾睡！",
}

local yingbaBuff = fk.CreateTargetModSkill{
  name = "#yingba-buff",
  distance_limit_func =  function(self, player, skill, card, to)
    if player:hasSkill(self.name) and to and to:getMark("@yingba_pingding") > 0 then
      return 999
    end

    return 0
  end
}

yingba:addRelatedSkill(yingbaBuff)
godsunce:addSkill(yingba)

local fuhai = fk.CreateTriggerSkill{
  name = "fuhai",
  events = {fk.TargetSpecified, fk.Death},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then
      return false
    end

    if event == fk.TargetSpecified then
      return
        target == player and
        player.room:getPlayerById(data.to):getMark("@yingba_pingding") > 0 and
        player:usedSkillTimes(self.name) < 2
    else
      return player.room:getPlayerById(data.who):getMark("@yingba_pingding") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      player:drawCards(1, self.name)
    else
      local room = player.room
      local deadOne = room:getPlayerById(data.who)
      local pingdingNum = deadOne:getMark("@yingba_pingding")

      player.room:changeMaxHp(player, pingdingNum)
      player:drawCards(pingdingNum, self.name)
    end
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self.name) and
      player.room:getPlayerById(data.to):getMark("@yingba_pingding") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insert(data.disresponsiveList, data.to)
  end,
}
Fk:loadTranslationTable{
  ["fuhai"] = "覆海",
  [":fuhai"] = "锁定技，拥有“平定”标记的角色不能响应你对其使用的牌；当你使用牌指定拥有“平定”标记的角色为目标后，你摸一张牌；当拥有“平定”标记的角色死亡时，你加X点体力上限并摸X张牌（X为其“平定”标记数）。",
  ["$fuhai1"] = "翻江复蹈海，六合定乾坤！",
  ["$fuhai2"] = "力攻平江东，威名扬天下！",
}

godsunce:addSkill(fuhai)

local pinghe = fk.CreateTriggerSkill{
  name = "pinghe",
  events = {fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self.name) and
      player.maxHp > 1 and
      not player:isKongcheng() and
      data.from and
      data.from ~= player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)

    local tos, cardId = room:askForChooseCardAndPlayers(
      player,
      table.map(room:getOtherPlayers(player, false), function(p)
        return p.id
      end),
      1,
      1,
      ".|.|.|hand",
      "#pinghe-give",
      self.name
    )

    room:obtainCard(tos[1], cardId, false, fk.ReasonGive)

    if player:hasSkill(yingba.name) and data.from:isAlive() then
      room:addPlayerMark(data.from, "@yingba_pingding")
    end

    return true
  end,
}
Fk:loadTranslationTable{
  ["pinghe"] = "冯河",
  [":pinghe"] = "锁定技，你的手牌上限基值为你已损失的体力值；当你受到其他角色造成的伤害时，若你的体力上限大于1且你有手牌，你防止此伤害，减1点体力上限并将一张手牌交给一名其他角色，然后若你有技能“英霸”，伤害来源获得一枚“平定”标记。",
  ["#pinghe-give"] = "冯河：请交给一名其他角色一张手牌",
  ["$pinghe1"] = "不过胆小鼠辈，吾等有何惧哉！",
  ["$pinghe2"] = "只可得胜而返，岂能败战而归！",
}

local pingheBuff = fk.CreateMaxCardsSkill {
  name = "#pinghe-buff",
  frequency = Skill.Compulsory,
  fixed_func = function(self, player)
    return player:hasSkill("pinghe") and player:getLostHp() or nil
  end
}

pinghe:addRelatedSkill(pingheBuff)
godsunce:addSkill(pinghe)

local godTaishici = General(extension, "godtaishici", "god", 4)
Fk:loadTranslationTable{
  ["godtaishici"] = "神太史慈",
  ["~godtaishici"] = "魂归……天地……",
}

local dulie = fk.CreateTriggerSkill{
  name = "dulie",
  events = {fk.TargetConfirming},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self.name) and
      data.card.trueName == "slash" and
      player.room:getPlayerById(data.from).hp > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|heart",
    }

    room:judge(judge)
    if judge.card.suit == Card.Heart then
      AimGroup:cancelTarget(data, player.id)
      return true
    end
  end,
}
Fk:loadTranslationTable{
  ["dulie"] = "笃烈",
  [":dulie"] = "锁定技，当你成为体力值大于你的角色使用【杀】的目标时，你判定，若结果为红桃，取消之。",
  ["$dulie1"] = "素来言出必践，成吾信义昭彰！",
  ["$dulie2"] = "小信如若不成，大信将以何立？",
}

godTaishici:addSkill(dulie)

local powei = fk.CreateTriggerSkill{
  name = "powei",
  events = {fk.GameStart, fk.EventPhaseChanging, fk.Damaged, fk.EnterDying},
  frequency = Skill.Quest,
  can_trigger = function(self, event, target, player, data)
    if player:getQuestSkillState(self.name) or not player:hasSkill(self.name) then
      return false
    end

    if event == fk.GameStart then
      return true
    elseif event == fk.EventPhaseChanging then
      return data.from == Player.RoundStart and (target == player or target:getMark("@@powei_wei") > 0)
    elseif event == fk.Damaged then
      return target:getMark("@@powei_wei") > 0
    else
      return target == player and player.hp < 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    self.cost_data = nil
    if event == fk.EventPhaseChanging and target:getMark("@@powei_wei") > 0 then
      local room = player.room

      local choices = { "Cancel" }
      if target.hp <= player.hp and target ~= player and target:getHandcardNum() > 0 then
        table.insert(choices, 1, "powei_prey")
      end
      if table.find(player:getCardIds(Player.Hand), function(id)
        return not player:prohibitDiscard(id)
      end) then
        table.insert(choices, 1, "powei_damage")
      end

      if #choices == 1 then
        return false
      end

      local choice = room:askForChoice(player, choices, self.name)
      if choice == "Cancel" then
        return false
      end

      if choice == "powei_damage" then
        local cardIds = room:askForDiscard(player, 1, 1, false, self.name, true, nil, "#powei-damage::" .. target.id, true)
        if #cardIds == 0 then
          return false
        end

        self.cost_data = cardIds[1]
      else
        self.cost_data = choice
      end      
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:setPlayerMark(p, "@@powei_wei", 1)
      end
    elseif event == fk.EventPhaseChanging then
      if target == player then
        if table.find(room.alive_players, function(p)
          return p:getMark("@@powei_wei") > 0
        end) then
          local hasLastPlayer = false
          for _, p in ipairs(room:getAlivePlayers()) do
            if p:getMark("@@powei_wei") > (hasLastPlayer and 1 or 0) and not (#room.alive_players < 3 and p:getNextAlive() == player)  then
              hasLastPlayer = true
              room:removePlayerMark(p, "@@powei_wei")
              local nextPlayer = p:getNextAlive()
              if nextPlayer == player then
                nextPlayer = player:getNextAlive()
              end

              room:addPlayerMark(nextPlayer, "@@powei_wei")
            else
              hasLastPlayer = false
            end
          end
        else
          room:updateQuestSkillState(player, self.name)
          room:handleAddLoseSkills(player, "shenzhuo")
        end
      end

      if type(self.cost_data) == "number" then
        room:throwCard({ self.cost_data }, self.name, player, player)
        room:damage({
          from = player,
          to = target,
          damage = 1,
          damageType = fk.NormalDamage,
          skillName = self.name,
        })

        room:setPlayerMark(player, "powei_debuff-turn", target.id)
      elseif self.cost_data == "powei_prey" then
        local cardId = room:askForCardChosen(player, target, "h", self.name)
        room:obtainCard(player, cardId, false, fk.ReasonPrey)
        room:setPlayerMark(player, "powei_debuff-turn", target.id)
      end
    elseif event == fk.Damaged then
      room:setPlayerMark(target, "@@powei_wei", 0)
    else
      room:updateQuestSkillState(player, self.name, true)
      if player.hp < 1 then
        room:recover({
          who = player,
          num = 1 - player.hp,
          recoverBy = player,
          skillName = self.name,
        })
      end

      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("@@powei_wei") > 0 then
          room:setPlayerMark(p, "@@powei_wei", 0)
        end
      end

      if #player:getCardIds(Player.Equip) > 0 then
        room:throwCard(player:getCardIds(Player.Equip), self.name, player, player)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["powei"] = "破围",
  [":powei"] = "使命技，游戏开始时，你令所有其他角色获得“围”标记；回合开始时，你令所有拥有“围”标记的角色将“围”标记移动至下家（若下家为你，则改为移动至你的下家）；有“围”标记的角色受到伤害后，移去其“围”标记；有“围”的角色的回合开始时，你可以选择一项并令你于本回合内视为处于其攻击范围内：1.弃置一张手牌，对其造成1点伤害；2.若其体力值不大于你，你获得其一张手牌。",
  ["@@powei_wei"] = "围",
  ["powei_damage"] = "弃一张手牌对其造成1点伤害",
  ["powei_prey"] = "获得其1张手牌",
  ["#powei-damage"] = "破围：你可以弃置一张手牌，对 %dest 造成1点伤害",
  ["$powei1"] = "弓马骑射洒热血，突破重围显英豪！",
  ["$powei2"] = "敌军尚犹严防，有待明日再看！",
  ["$powei2"] = "君且城中等候，待吾探敌虚实。",
}

local poweiDebuff = fk.CreateAttackRangeSkill{  --FIXME!!!
  name = "#powei-debuff",
  within_func = function (self, from, to)
    return to:getMark("powei_debuff-turn") == from.id
  end,
}

powei:addRelatedSkill(poweiDebuff)
godTaishici:addSkill(powei)

local shenzhuo = fk.CreateTriggerSkill{
  name = "shenzhuo",
  events = {fk.CardUseFinished},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self.name) and
      data.card.trueName == "slash" and
      not data.card:isVirtual()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, { "shenzhuo_drawOne", "shenzhuo_drawThree" }, self.name)
    if choice == "shenzhuo_drawOne" then
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "shenzhuo-turn")
    else
      player:drawCards(3, self.name)
      room:setPlayerMark(player, "@shenzhuo_debuff-turn", "shenzhuo_debuff")
    end
  end,
}
Fk:loadTranslationTable{
  ["shenzhuo"] = "神著",
  [":shenzhuo"] = "锁定技，当你使用非转化且非虚拟的【杀】结算结束后，你须选择一项：1.摸一张牌，令你于本回合内使用【杀】的次数上限+1；2.摸三张牌，令你于本回合内不能使用【杀】。",
  ["shenzhuo_drawOne"] = "摸1张牌，可以继续出杀",
  ["shenzhuo_drawThree"] = "摸3张牌，本回合不能出杀",
  ["@shenzhuo_debuff-turn"] = "神著",
  ["shenzhuo_debuff"] = "不能出杀",
  ["$shenzhuo1"] = "力引强弓百斤，矢除贯手著棼！",
  ["$shenzhuo2"] = "箭既已在弦上，吾又岂能不发！",
}

local shenzhuoBuff = fk.CreateTargetModSkill{
  name = "#shenzhuo-buff",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("shenzhuo-turn")
    end
  end,
}

local shenzhuoDebuff = fk.CreateProhibitSkill{
  name = "#shenzhuo-debuff",
  prohibit_use = function(self, player, card)
    return player:getMark("@shenzhuo_debuff-turn") ~= 0 and card.trueName == "slash"
  end,
}

shenzhuo:addRelatedSkill(shenzhuoBuff)
shenzhuo:addRelatedSkill(shenzhuoDebuff)
godTaishici:addRelatedSkill(shenzhuo)

return extension
