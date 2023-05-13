local extension = Package("wisdom")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["wisdom"] = "智包",
}

local godguojia = General(extension, "godguojia", "god", 3)
Fk:loadTranslationTable{
  ["godguojia"] = "神郭嘉",
  ["~godguojia"] = "可叹桢干命也迂……",
}

local godHuishi = fk.CreateActiveSkill{
  name = "mobile__god_huishi",
  anim_type = "drawCard",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player.maxHp < 10
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return false
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)

    local cardsJudged = {}
    while from.maxHp < 10 do
      local parsePattern = table.concat(table.map(cardsJudged, function(card)
        return card:getSuitString()
      end), ",")

      local judge = {
        who = from,
        reason = self.name,
        pattern = ".|.|" .. (parsePattern == "" and "." or "^(" .. parsePattern .. ")"),
        skipDrop = true,
      }
      room:judge(judge)

      table.insert(cardsJudged, judge.card)

      if
        not table.every(cardsJudged, function(card)
          return card == judge.card or judge.card:compareSuitWith(card, true)
        end) or
        not room:askForSkillInvoke(from, self.name, nil, "#mobile__god_huishi-ask")
      then
        break
      end

      room:changeMaxHp(from, 1)
    end

    local alivePlayerIds = table.map(room.alive_players, function(p)
      return p.id
    end)
    local targets = room:askForChoosePlayers(from, alivePlayerIds, 1, 1, "#mobile__god_huishi-give", self.name)
    if #targets > 0 then
      local to = targets[1]
      local pack = Fk:cloneCard("slash")
      pack:addSubcards(cardsJudged)
      room:obtainCard(to, pack, true, fk.ReasonGive)

      if
        table.every(room.alive_players, function(p)
          return p:getHandcardNum() <= room:getPlayerById(to):getHandcardNum()
        end)
      then
        room:changeMaxHp(from, -1)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["mobile__god_huishi"] = "慧识",
  [":mobile__god_huishi"] = "出牌阶段限一次，若你的体力上限小于10，你可以判定，若结果与本次流程中的其他判定结果均不同，且你的体力上限小于10，你可加1点体力上限并重复此流程。最后你将本次流程中所有生效的判定牌交给一名角色，若其手牌为全场最多，你减1点体力上限。",
  ["#mobile__god_huishi-ask"] = "慧识：你可以加1点体力上限并重复此流程",
  ["#mobile__god_huishi-give"] = "慧识：你可以将这些判定牌交给一名角色",
  ["$mobile__god_huishi1"] = "聪以知远，明以察微。",
  ["$mobile__god_huishi2"] = "见微知著，识人心智。",
}

godguojia:addSkill(godHuishi)

local tianyi = fk.CreateTriggerSkill{
  name = "mobile__tianyi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return 
      target == player and
      player.phase == Player.Start and
      player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryGame) < 1
  end,
  can_wake = function(self, event, target, player, data)
    return table.every(player.room.alive_players, function(p)
      return p:getMark("mobile__tianyi_damaged_count") > 0
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 2)
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name,
    })

    local alivePlayerIds = table.map(room.alive_players, function(p)
      return p.id
    end)
    local target = room:askForChoosePlayers(player, alivePlayerIds, 1, 1, "#mobile__tianyi-choose", self.name, true)[1]
    room:handleAddLoseSkills(room:getPlayerById(target), "zuoxing")
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return data.to == player and player:getMark("mobile__tianyi_damaged_count") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "mobile__tianyi_damaged_count")
  end,
}
Fk:loadTranslationTable{
  ["mobile__tianyi"] = "天翊",
  [":mobile__tianyi"] = "觉醒技，准备阶段开始时，若所有存活角色于本局游戏内均受到过伤害，你加2点体力上限，回复1点体力，令一名角色获得技能“佐幸”。",
  ["#mobile__tianyi-choose"] = "天翊：请选择一名角色获得技能“佐幸”",
  ["$mobile__tianyi1"] = "天命靡常，惟德是辅。",
  ["$mobile__tianyi2"] = "可成吾志者，必此人也！",
}

godguojia:addSkill(tianyi)

local limitedHuishi = fk.CreateActiveSkill{
  name = "mobile__limited_huishi",
  anim_type = "support",
  frequency = Skill.Limited,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return true
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    
    local wakeSkills = {}
    if #room.alive_players <= from.maxHp then
      wakeSkills = table.map(table.filter(to.player_skills, function(s)
        return s.frequency == Skill.Wake and to:usedSkillTimes(s.name, Player.HistoryGame) < 1
      end), function(skill)
        return skill.name 
      end)
    end

    if #wakeSkills > 0 and from.maxHp >= #room.alive_players then
      local choice = room:askForChoice(from, wakeSkills, self.name, "#mobile__limited_huishi")
      local toWakeSkills = type(to:getMark("@mobile__limited_huishi")) == "table" and to:getMark("@mobile__limited_huishi") or {}
      table.insertIfNeed(toWakeSkills, choice)
      room:setPlayerMark(to, "@mobile__limited_huishi", toWakeSkills)

      toWakeSkills = type(to:getMark(MarkEnum.StraightToWake)) == "table" and to:getMark(MarkEnum.StraightToWake) or {}
      table.insertIfNeed(toWakeSkills, choice)
      room:setPlayerMark(to, MarkEnum.StraightToWake, toWakeSkills)
    else
      to:drawCards(4, self.name)
    end

    room:changeMaxHp(from, -2)
  end,
}
Fk:loadTranslationTable{
  ["mobile__limited_huishi"] = "辉逝",
  [":mobile__limited_huishi"] = "限定技，出牌阶段，你可以选择一名角色，若其有未发动过的觉醒技且你的体力上限不小于存活角色数，你选择其中一项技能，视为该角色满足其觉醒条件；否则其摸四张牌。最后你减2点体力上限。",
  ["@mobile__limited_huishi"] = "辉逝",
  ["$mobile__limited_huishi1"] = "丧家之犬，主公实不足虑也。",
  ["$mobile__limited_huishi2"] = "时事兼备，主公复有何忧？",
}

local limitedHuishiClear = fk.CreateTriggerSkill{
  name = "#mobile__limited_huishi-clear",
  refresh_events = {fk.BeforeTriggerSkillUse},
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      data.willUse and
      data.skill.frequency == Skill.Wake and
      type(player:getMark("@mobile__limited_huishi")) == "table" and
      table.contains(player:getMark("@mobile__limited_huishi"), data.skill.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room

    local toWakeSkills = player:getMark("@mobile__limited_huishi")
    table.removeOne(toWakeSkills, data.skill.name)
    room:setPlayerMark(player, "@mobile__limited_huishi", #toWakeSkills > 0 and toWakeSkills or 0)

    toWakeSkills = type(player:getMark(MarkEnum.StraightToWake)) == "table" and player:getMark(MarkEnum.StraightToWake) or {}
    table.removeOne(toWakeSkills, data.skill.name)
    room:setPlayerMark(player, MarkEnum.StraightToWake, #toWakeSkills > 0 and toWakeSkills or 0)
  end,
}
limitedHuishi:addRelatedSkill(limitedHuishiClear)

godguojia:addSkill(limitedHuishi)

local zuoxing = fk.CreateViewAsSkill{
  name = "zuoxing",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and card.skill.canUse(Self, card) and not Self:prohibitUse(card) then
        table.insertIfNeed(names, card.name)
      end
    end
    return UI.ComboBox { choices = names }
  end,
  enabled_at_play = function(self, player)
    return
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function(p)
        return table.contains({ p.general, p.deputyGeneral }, "godguojia") and p.maxHp > 1
      end)
  end,
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    local firstGodGuojia = table.find(room:getAlivePlayers(), function(p)
      return table.contains({ p.general, p.deputyGeneral }, "godguojia") and p.maxHp > 1
    end)

    if firstGodGuojia then
      room:changeMaxHp(firstGodGuojia, -1)
    end
  end,
}
Fk:loadTranslationTable{
  ["zuoxing"] = "佐幸",
  [":zuoxing"] = "出牌阶段限一次，若场上有存活且体力上限大于1的神郭嘉，你可以令其中于当前结算顺序上的第一个神郭嘉减1点体力上限，并视为使用一张普通锦囊牌。",
  ["$zuoxing1"] = "以聪虑难，悉咨于上。",
  ["$zuoxing2"] = "身计国谋，不可两遂。",
}

godguojia:addRelatedSkill(zuoxing)

return extension
