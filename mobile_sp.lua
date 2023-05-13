local extension = Package("mobile_sp")
extension.extensionName = "mobile"
Fk:loadTranslationTable{
  ["mobile_sp"] = "手杀专属",
}

local maojie = General(extension, "maojie", "wei", 3)
Fk:loadTranslationTable{
  ["maojie"] = "毛玠",
  ["~maojie"] = "废立大事，公不可不慎……",
}

local bingqing = fk.CreateTriggerSkill{
  name = "bingqing",
  events = {fk.CardUseFinished},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return 
      target == player and
      player:hasSkill(self.name) and
      player.phase == Player.Play and
      (data.extra_data or {}).firstCardSuitUseFinished and
      type(player:getMark("@bingqing")) == "table" and
      #player:getMark("@bingqing") > 1 and
      #player:getMark("@bingqing") < 5
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room

    local suitsNum = #player:getMark("@bingqing")
    local targets = {}
    local prompt = "#bingqing-draw"
    if suitsNum == 2 then
      targets = room.alive_players
    elseif suitsNum == 3 then
      targets = table.filter(room.alive_players, function(p)
        if p == player and not table.find(player:getCardIds({ Player.Hand, Player.Equip, Player.Judge }), function(id)
          return not player:prohibitDiscard(Fk:getCardById(id))
        end) then
          return false
        end

        return not p:isAllNude()
      end)

      prompt = "#bingqing-discard"
    else
      targets = room:getOtherPlayers(player, false)
      prompt = "#bingqing-damage"
    end

    if #targets == 0 then
      return false
    end

    targets = table.map(targets, function(p)
      return p.id
    end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local suitsNum = #player:getMark("@bingqing")
    local to = room:getPlayerById(self.cost_data)
    if suitsNum == 2 then
      to:drawCards(2, self.name)
    elseif suitsNum == 3 then
      local cardId = room:askForCardChosen(player, to, "hej", self.name)
      room:throwCard({ cardId }, self.name, to, player)
    else
      room:damage({
        from = player,
        to = to,
        damage = 1,
        damageType = fk.NormalDamage,
        skillName = self.name,
      })
    end
  end,

  refresh_events = {fk.EventPhaseChanging, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if target ~= player then
      return false
    end

    if event == fk.EventPhaseChanging then
      return
        data.from == Player.Play and
        type(player:getMark("@bingqing")) == "table"
    else
      return
        player:hasSkill(self.name, true) and
        player.phase == Player.Play and
        (type(player:getMark("@bingqing")) ~= "table" or
        not table.contains(player:getMark("@bingqing"), "log_" .. data.card:getSuitString()))
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      room:setPlayerMark(player, "@bingqing", 0)
    else
      local typesRecorded = type(player:getMark("@bingqing")) == "table" and player:getMark("@bingqing") or {}
      table.insert(typesRecorded, "log_" .. data.card:getSuitString())
      room:setPlayerMark(player, "@bingqing", typesRecorded)

      data.extra_data = data.extra_data or {}
      data.extra_data.firstCardSuitUseFinished = true
    end
  end,
}
Fk:loadTranslationTable{
  ["bingqing"] = "秉清",
  [":bingqing"] = "当你于出牌阶段内使用牌结算结束后，若此牌的花色与你于此阶段内使用并结算结束的牌花色均不相同，则你记录此牌花色直到此阶段结束，然后你根据记录的花色数，你可以执行对应效果：<br>两种，令一名角色摸两张牌；<br>三种，弃置一名角色区域内的一张牌；<br>四种，对一名角色造成1点伤害。",
  ["@bingqing"] = "秉清",
  ["#bingqing-draw"] = "秉清：你可以令一名角色摸两张牌",
  ["#bingqing-discard"] = "秉清：你可以弃置一名角色区域里的一张牌",
  ["#bingqing-damage"] = "秉清：你可以对一名其他角色造成1点伤害",

  ["$bingqing1"] = "常怀圣言，以是自励。",
  ["$bingqing2"] = "身受贵宠，不忘初心。",
}

maojie:addSkill(bingqing)

local peixiu = General(extension, "peixiu", "qun", 3)
Fk:loadTranslationTable{
  ["peixiu"] = "裴秀",
  ["~peixiu"] = "既食寒石散，便不可饮冷酒啊……",
}

local xingtu = fk.CreateTriggerSkill{
  name = "xingtu",
  events = {fk.CardUsing},
  anim_type = "drawCard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self.name) and
      type((data.extra_data or {}).xingtuNumber) == "number" and
      (data.extra_data or {}).xingtuNumber % data.card.number == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local lastNumber = player:getMark("@xingtu")
    local realNumber = math.max(data.card.number, 0)
    player.room:setPlayerMark(player, "@xingtu", realNumber)
    if lastNumber > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.xingtuNumber = lastNumber
    end
  end,
}
Fk:loadTranslationTable{
  ["xingtu"] = "行图",
  [":xingtu"] = "锁定技，当你使用牌时，若此牌的点数为X的因数，你摸一张牌；你使用点数为X的倍数的牌无次数限制（X为你使用的上一张牌的点数）。",
  ["@xingtu"] = "行图",
  ["$xingtu1"] = "制图之体有六，缺一不可言精。",
  ["$xingtu2"] = "图设分率，则宇内地域皆可绘于一尺。",
}

local xingtuBuff = fk.CreateTargetModSkill{
  name = "#xingtu-buff",
  residue_func = function(self, player, skill, scope, card)
    return (player:hasSkill(self.name) and player:getMark("@xingtu") > 0 and card.number % player:getMark("@xingtu") == 0) and
      999 or
      0
  end,
}

xingtu:addRelatedSkill(xingtuBuff)
peixiu:addSkill(xingtu)

local juezhi = fk.CreateActiveSkill{
  name = "juezhi",
  anim_type = "drawCard",
  min_card_num = 2,
  can_use = function(self, player)
    return true
  end,
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return false
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local number = 0
    for _, id in ipairs(effect.cards) do
      number = number + math.max(Fk:getCardById(id).number, 0)
    end

    number = number % 13
    number = number == 0 and 13 or number

    room:throwCard(effect.cards, self.name, from, from)

    local randomId = room:getCardsFromPileByRule(".|" .. number)
    if #randomId > 0 then
      room:obtainCard(from, randomId[1], true, fk.ReasonPrey)
    end
  end,
}
Fk:loadTranslationTable{
  ["juezhi"] = "爵制",
  [":juezhi"] = "出牌阶段，你可以弃置至少两张牌，然后从牌堆中随机获得一张点数为X的牌（X为以此法弃置的牌点数和与13的余数，若余数为0则改为13）。",
  ["$juezhi1"] = "复设五等之制，以解天下土崩之势。",
  ["$juezhi2"] = "表为建爵五等，实则藩卫帝室。",
}

peixiu:addSkill(juezhi)

return extension
