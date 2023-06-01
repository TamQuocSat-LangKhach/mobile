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
    data.disresponsive = true
    -- data.disresponsiveList = data.disresponsiveList or {}
    -- table.insert(data.disresponsiveList, data.to)
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

return extension
