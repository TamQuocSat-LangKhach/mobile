local extension = Package("mobile_rare")
extension.extensionName = "mobile"
Fk:loadTranslationTable{
  ["mobile_rare"] = "手杀-稀有专属",
  ["mobile"] = "手杀",
  ["mxing"] = "手杀星",
}

--袖里乾坤：孙茹 凌操 留赞 祢衡 曹纯 庞德公 马钧 司马师 郑玄 南华老仙 十常侍
local sunru = General(extension, "sunru", "wu", 3, 3, General.Female)
local yingjian = fk.CreateTriggerSkill{
  name = "yingjian",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and not player:prohibitUse(Fk:cloneCard("slash"))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local slash = Fk:cloneCard "slash"
    local max_num = slash.skill:getMaxTargetNum(player, slash)
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not player:isProhibited(p, slash) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 or max_num == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, max_num, "#yingjian-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local slash = Fk:cloneCard "slash"
    slash.skillName = self.name
    room:useCard {
      from = target.id,
      tos = table.map(self.cost_data, function(pid) return { pid } end),
      card = slash,
      extraUse = true,
    }
  end,
}
sunru:addSkill(yingjian)
local shixin = fk.CreateTriggerSkill{
  name = "shixin",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(self) and
      data.damageType == fk.FireDamage
  end,
  on_use = Util.TrueFunc,
}
sunru:addSkill(shixin)
Fk:loadTranslationTable{
  ["sunru"] = "孙茹",
  ["yingjian"] = "影箭",
  ["#yingjian-choose"] = "影箭：你可以视为使用无视距离的【杀】",
  [":yingjian"] = "准备阶段，你可以视为使用一张无距离限制的【杀】。",
  ["shixin"] = "释衅",
  [":shixin"] = "锁定技，防止你受到的火属性伤害。",

  ["$yingjian1"] = "翩翩逸云端，仿若桃花仙。",
  ["$yingjian2"] = "没牌，又有何不可能的？",  -- -_-||
  ["$shixin1"] = "释怀之戾气，化君之不悦。",
  ["$shixin2"] = "星星之火，安能伤我？",
  ["~sunru"] = "佑我江东，虽死无怨。",
}

local dujin = fk.CreateTriggerSkill{
  name = "dujin",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1 + #player:getCardIds(Player.Equip) // 2
  end,
}
local lingcao = General(extension, "lingcao", "wu", 4)
lingcao:addSkill(dujin)
Fk:loadTranslationTable{
  ["lingcao"] = "凌操",
  ["dujin"] = "独进",
  [":dujin"] = "摸牌阶段，你可以多摸X+1张牌，X为你装备区内牌数的一半（向下取整）",
  ["$dujin1"] = "带兵十万，不如老夫多甲一件！",
  ["$dujin2"] = "轻舟独进，破敌先锋！",
  ["~lingcao"] = "呃啊！（扑通）此箭……何来……",
}

local liuzan = General(extension, "liuzan", "wu", 4)
local fenyin = fk.CreateTriggerSkill{
  name = "fenyin",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase < Player.NotActive and self.can_fenyin
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.CardUsing, fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self)) then return end
    if event == fk.EventPhaseStart then
      return player.phase == Player.NotActive
    else
      return player.phase < Player.NotActive -- FIXME: this is a bug of FK 0.0.2!!
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(player, self.name, 0)
      room:setPlayerMark(player, "@" .. self.name, 0)
    else
      self.can_fenyin = data.card.color ~= player:getMark(self.name) and player:getMark(self.name) ~= 0
      room:setPlayerMark(player, self.name, data.card.color)
      room:setPlayerMark(player, "@" .. self.name, data.card:getColorString())
    end
  end,
}
liuzan:addSkill(fenyin)
Fk:loadTranslationTable{
  ["liuzan"] = "留赞",
  ["fenyin"] = "奋音",
  [":fenyin"] = "你的回合内，当你使用和上一张牌颜色不同的牌时，你可以摸一张牌。",
  ["@fenyin"] = "奋音",

  ["$fenyin1"] = "吾军杀声震天，则敌心必乱！",
  ["$fenyin2"] = "阵前亢歌，以振军心！",
  ["~liuzan"] = "贼子们，来吧！啊…………",
}

local majun = General(extension, "majun", "wei", 3)
local majunwin = fk.CreateActiveSkill{ name = "majun_win_audio" }
majunwin.package = extension
Fk:addSkill(majunwin)
local jingxie_list = { "crossbow", "eight_diagram", "nioh_shield", "silver_lion", "vine" }
local jingxie = fk.CreateActiveSkill{
  name = "jingxie",
  anim_type = "support",
  card_filter = function(self, to_select, selected, targets)
    if #selected == 1 then return false end
    return table.contains(jingxie_list, Fk:getCardById(to_select).name)
  end,
  card_num = 1,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local card = Fk:getCardById(effect.cards[1])
    local ex_card = room:printCard("ex_" .. card.name, card.suit, card.number)

    from:showCards(card)
    room:moveCardTo(card, Card.Void, nil, nil, self.name, nil, true, effect.from)
    room:obtainCard(from, ex_card.id, true)
  end,
}
local jingxie_trig = fk.CreateTriggerSkill{
  name = "#jingxie_trig",
  main_skill = jingxie,
  events = {fk.AskForPeaches},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("jingxie") and player.dying
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForCard(player, 1, 1, true, "jingxie", true,
      ".|.|.|.|.|armor", "#jingxie-recast")

    if cards[1] then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("jingxie")
    room:notifySkillInvoked(player, "jingxie")
    room:recastCard(self.cost_data, player, "jingxie")
    room:recover{
      who = player,
      num = 1 - player.hp,
      recoverBy = player,
      skillName = self.name,
    }
  end,
}
jingxie:addRelatedSkill(jingxie_trig)
majun:addSkill(jingxie)
local qiaosi_choices = {
  "qiaosi_figure1",
  "qiaosi_figure2",
  "qiaosi_figure3",
  "qiaosi_figure4",
  "qiaosi_figure5",
  "qiaosi_figure6",
  "qiaosi_abort",
}
local qiaosi = fk.CreateActiveSkill{
  name = "qiaosi",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local choices = table.simpleClone(qiaosi_choices)
    local choosed = {}
    while #choosed < 3 do
      local choice = room:askForChoice(from, choices, "qiaosi_baixitu", nil, false, qiaosi_choices)
      table.removeOne(choices, choice)
      if choice == "qiaosi_abort" then
        break
      else
        table.insert(choosed, choice)
      end
    end

    local cards = {}
    for _, choice in ipairs(choosed) do
      local id_neg = "^(" .. table.concat(cards, ",") .. ")"
      if choice:endsWith("1") then
        table.insertTable(cards, room:getCardsFromPileByRule(
          ".|.|.|.|.|equip|" .. id_neg, 2, "allPiles"))

      elseif choice:endsWith("2") then
        if table.contains(choosed, "qiaosi_figure6") or math.random() > 0.75 then
          local name = math.random() < 0.75 and "analeptic" or "slash"
          table.insertTable(cards, room:getCardsFromPileByRule(
            name .. "|.|.|.|.|.|" .. id_neg, 1, "allPiles"))

        else
          table.insertTable(cards, room:getCardsFromPileByRule(
            ".|.|.|.|.|equip|" .. id_neg, 1, "allPiles"))
        end
      elseif choice:endsWith("3") then
        local name = math.random() > 0.75 and "analeptic" or "slash"
        table.insertTable(cards, room:getCardsFromPileByRule(name .. "|.|.|.|.|.|" .. id_neg, 1, "allPiles"))
      elseif choice:endsWith("4") then
        local name = math.random() > 0.75 and "peach" or "jink"
        table.insertTable(cards, room:getCardsFromPileByRule(name .. "|.|.|.|.|.|" .. id_neg, 1, "allPiles"))
      elseif choice:endsWith("5") then
        if table.contains(choosed, "qiaosi_figure1") or math.random() > 0.75 then
          local name = math.random() < 0.75 and "peach" or "jink"
          table.insertTable(cards, room:getCardsFromPileByRule(
            name .. "|.|.|.|.|.|" .. id_neg, 1, "allPiles"))

        else
          table.insertTable(cards, room:getCardsFromPileByRule(
            ".|.|.|.|.|trick|" .. id_neg, 1, "allPiles"))
        end
      elseif choice:endsWith("6") then
        table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|trick|" .. id_neg, 2, "allPiles"))
      end
    end

    if #cards == 0 then return end

    room:sendLog {
      type = "#qiaosi_log",
      card = cards,
    }

    local tmp = Fk:cloneCard("slash")
    tmp:addSubcards(cards)
    room:obtainCard(from, tmp, true)
    local choice = room:askForChoice(from, { "qiaosi_give", "qiaosi_discard" }, self.name)
    if choice == "qiaosi_discard" then
      room:askForDiscard(from, #cards, #cards, true, self.name, false)
    else
      local all = from:getCardIds("he")
      local to_give = #all > #cards and room:askForCard(from, #cards, #cards, true, self.name, false, nil, "#qiaosi-give:::" .. #cards) or all
      local tgt = room:askForChoosePlayers(from, table.map(
        room:getOtherPlayers(from), Util.IdMapper), 1, 1, "#qiaosi-give-choose", self.name, false)[1]

      tmp = Fk:cloneCard("slash")
      tmp:addSubcards(to_give)
      room:obtainCard(room:getPlayerById(tgt), tmp, false, fk.ReasonGive)
    end
  end,
}
majun:addSkill(qiaosi)
Fk:loadTranslationTable{
  ["majun"] = "马钧",
  ["jingxie"] = "精械",
  [":jingxie"] = "①出牌阶段，你可以展示你手牌区或装备区里的一张【诸葛连弩】或"
    .. "【八卦阵】或【仁王盾】或【白银狮子】或【藤甲】，然后升级此牌；"
    .. "<br>②当你进入濒死状态时，你可以重铸一张防具牌，然后将体力值回复至1点。",
  ["#jingxie-recast"] = "精械: 你可以重铸一张防具牌然后回复至1点体力",
  ["qiaosi"] = "巧思",
  [":qiaosi"] = "出牌阶段限一次，你可以表演一次“水转百戏图”，获得对应的牌，"
    .. "然后你选择一项：1.弃置等量的牌；2.将等量的牌交给一名其他角色。（不足则全给/全弃）",

  ["qiaosi_baixitu"] = "百戏图",
  ["qiaosi_figure1"] = "王：两张锦囊",
  ["qiaosi_figure2"] = "商：75%装备，25%杀/酒；选中“将”则必出杀/酒",
  ["qiaosi_figure3"] = "工：75%杀，25%酒",
  ["qiaosi_figure4"] = "农：75%闪，25%桃",
  ["qiaosi_figure5"] = "士：75%锦囊，25%闪/桃；选中“王”则必出闪/桃",
  ["qiaosi_figure6"] = "将：两张装备",
  ["qiaosi_abort"] = "不转了",
  ["#qiaosi_log"] = "巧思转出来的结果是：%card",
  ["qiaosi_give"] = "交出等量张牌",
  ["qiaosi_discard"] = "弃置等量张牌",
  ["#qiaosi-give"] = "巧思：请选择要交出的 %arg 张牌",
  ["#qiaosi-give-choose"] = "巧思：请选择要交给的目标",

  ["$jingxie1"] = "军具精巧，方保无虞。",
  ["$jingxie2"] = "巧则巧矣，未尽善也。",
  ["$qiaosi1"] = "待我稍作思量，更益其巧。",
  ["$qiaosi2"] = "虚争空言，不如思而试之。",
  ["~majun"] = "衡石不用，美玉见诬啊！",
  ["$majun_win_audio"] = "吾巧益于世间，真乃幸事！",
}

--将星独具：星张辽 星张郃 星徐晃 星甘宁 星黄忠 星魏延 星周不疑
local zhangliao = General(extension, "mxing__zhangliao", "qun", 4)
local weifeng = fk.CreateTriggerSkill{
  name = "weifeng",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.card.is_damage_card and data.tos and
      table.find(TargetGroup:getRealTargets(data.tos), function(id)
        local p = player.room:getPlayerById(id)
        return id ~= player.id and not p.dead and p:getMark(self.name) == 0
      end) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0  --偷懒
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(TargetGroup:getRealTargets(data.tos), function(id)
      local p = player.room:getPlayerById(id)
      return id ~= player.id and not p.dead and p:getMark("@weifeng") == 0
    end)
    local to
    if #targets == 1 then
      to = targets[1]
      room:doIndicate(player.id, {to})
    else
      to = room:askForChoosePlayers(player, targets, 1, 1, "#weifeng-choose", self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(targets)
      end
    end
    to = room:getPlayerById(to)
    room:setPlayerMark(to, "@weifeng", data.card.trueName)
    local mark = to:getMark(self.name)
    if mark == 0 then mark = {} end
    table.insert(mark, {player.id, data.card.trueName})
    room:setPlayerMark(to, self.name, mark)
  end,

  refresh_events = {fk.EventPhaseStart, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return target == player and (event == fk.EventPhaseStart and player.phase == Player.Start or event == fk.BuryVictim) and
      table.find(player.room.alive_players, function(p)
        return p:getMark(self.name) ~= 0 and table.find(p:getMark(self.name), function(e)
          return e[1] == player.id
        end)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:getMark(self.name) ~= 0 and table.find(p:getMark(self.name), function(e) return e[1] == player.id end) then
        room:setPlayerMark(p, "@weifeng", 0)
        local mark = p:getMark(self.name)
        for i = #mark, 1, -1 do
          if mark[i][1] == player.id then
            table.removeOne(mark, mark[i])
          end
        end
        if #mark == 0 then mark = 0 end
        room:setPlayerMark(p, self.name, mark)
      end
    end
  end,
}
local weifeng_trigger = fk.CreateTriggerSkill{
  name = "#weifeng_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("weifeng") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("weifeng")
    for i = #mark, 1, -1 do
      if player.dead then return end
      local p = room:getPlayerById(mark[i][1])
      p:broadcastSkillInvoke("weifeng")
      room:doIndicate(p.id, {player.id})
      if data.card and data.card.trueName == mark[i][2] then
        room:notifySkillInvoked(p, "weifeng", "offensive")
        data.damage = data.damage + 1
      else
        room:notifySkillInvoked(p, "weifeng", "control")
        if not p.dead and not player:isNude() then
          local id = room:askForCardChosen(p, player, "he", "weifeng", "#weifeng-prey::"..player.id)
          room:obtainCard(p.id, id, false, fk.ReasonPrey)
        end
      end
    end
    room:setPlayerMark(player, "@weifeng", 0)
    room:setPlayerMark(player, "weifeng", 0)
  end,
}
weifeng:addRelatedSkill(weifeng_trigger)
zhangliao:addSkill(weifeng)
Fk:loadTranslationTable{
  ["mxing__zhangliao"] = "星张辽",
  ["weifeng"] = "威风",
  [":weifeng"] = "锁定技，你于出牌阶段第一次使用【杀】或伤害类锦囊牌结算后，你选择其中一名没有“惧”的其他目标角色，令其获得此牌名的“惧”标记。"..
  "有“惧”的角色受到伤害时，移除“惧”并执行效果：若造成伤害的牌名与“惧”相同，则此伤害+1；若不同，你获得其一张牌。准备阶段或你死亡时，移除所有“惧”。",
  ["#weifeng-choose"] = "威风：令一名角色获得“惧”标记",
  ["@weifeng"] = "惧",
  ["#weifeng-prey"] = "威风：获得 %dest 一张牌",

  ["$weifeng1"] = "广散惧义，尽泄敌之斗志。",
  ["$weifeng2"] = "若尔等惧我，自当卷甲以降。",
  ["~mxing__zhangliao"] = "惑于女子而尽失战机，庸主误我啊。",
  ["$mxing__zhangliao_win_audio"] = "并州雄骑，自当扫清六合！",
}

local zhanghe = General(extension, "mxing__zhanghe", "qun", 4)
local zhilve = fk.CreateActiveSkill{
  name = "zhilve",
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  prompt = function (self, selected_cards, selected_targets)
    return "#"..self.interaction.data
  end,
  interaction = function(self)
    return UI.ComboBox {choices = {"zhilve1", "zhilve2"}}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if self.interaction.data == "zhilve1" then
      if #selected == 0 then
        return #target:getCardIds("ej") > 0
      elseif #selected == 1 then
        local target1 = Fk:currentRoom():getPlayerById(selected[1])
        return table.find((target1):getCardIds("ej"), function(id) return target1:canMoveCardInBoardTo(target, id) end)
      else
        return false
      end
    else
      return #selected == 0 and to_select ~= Self.id and not Self:isProhibited(target, Fk:cloneCard("slash"))
    end
  end,
  feasible = function (self, selected, selected_cards)
    if self.interaction.data == "zhilve1" then
      return #selected == 2
    elseif self.interaction.data == "zhilve2" then
      return #selected == 1
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "zhilve1" then
      local targetOne = room:getPlayerById(effect.tos[1])
      local targetTwo = room:getPlayerById(effect.tos[2])
      local cards = {}
      local cardsPosition = {}

      for _, equipId in ipairs(targetOne:getCardIds(Player.Equip)) do
        if targetOne:canMoveCardInBoardTo(targetTwo, equipId) then
          table.insert(cards, equipId)
        end
      end
      for _, equipId in ipairs(targetTwo:getCardIds(Player.Equip)) do
        if targetTwo:canMoveCardInBoardTo(targetOne, equipId) then
          table.insert(cards, equipId)
        end
      end

      if #cards > 0 then
        table.sort(cards, function(prev, next)
          local prevSubType = Fk:getCardById(prev).sub_type
          local nextSubType = Fk:getCardById(next).sub_type

          return prevSubType < nextSubType
        end)

        for _, id in ipairs(cards) do
          table.insert(cardsPosition, room:getCardOwner(id) == targetOne and 0 or 1)
        end
      end

      for _, trickId in ipairs(targetOne:getCardIds(Player.Judge)) do
        if targetOne:canMoveCardInBoardTo(targetTwo, trickId) then
          table.insert(cards, trickId)
          table.insert(cardsPosition, 0)
        end
      end
      for _, trickId in ipairs(targetTwo:getCardIds(Player.Judge)) do
        if targetTwo:canMoveCardInBoardTo(targetOne, trickId) then
          table.insert(cards, trickId)
          table.insert(cardsPosition, 1)
        end
      end

      if #cards == 0 then return end

      local firstGeneralName = targetOne.general + (targetOne.deputyGeneral ~= "" and ("/" .. targetOne.deputyGeneral) or "")
      local secGeneralName = targetTwo.general + (targetTwo.deputyGeneral ~= "" and ("/" .. targetTwo.deputyGeneral) or "")

      local data = {
        cards = cards,
        cardsPosition = cardsPosition,
        generalNames = { firstGeneralName, secGeneralName },
        playerIds = { targetOne.id, targetTwo.id }
      }
      local command = "AskForMoveCardInBoard"
      room:notifyMoveFocus(player, command)
      local result = room:doRequest(player, command, json.encode(data))

      if result == "" then
        local randomIndex = math.random(1, #cards)
        result = { cardId = cards[randomIndex], pos = cardsPosition[randomIndex] }
      else
        result = json.decode(result)
      end

      local from, to
      if result.pos == 0 then
        from, to = targetOne, targetTwo
      else
        from, to = targetTwo, targetOne
      end

      room:loseHp(player, 1, self.name)
      if not player.dead then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 1)
      end

      local cardToMove = room:getCardOwner(result.cardId):getVirualEquip(result.cardId) or Fk:getCardById(result.cardId)
      room:moveCardTo(
        cardToMove,
        cardToMove.type == Card.TypeEquip and Player.Equip or Player.Judge,
        to,
        fk.ReasonPut,
        self.name,
        nil,
        true,
        player.id
      )
    else
      room:loseHp(player, 1, self.name)
      if not player.dead then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 1)
        player:drawCards(1, self.name)
      end
      room:useVirtualCard("slash", nil, player, {room:getPlayerById(effect.tos[1])}, self.name, true)
    end
  end,
}
zhanghe:addSkill(zhilve)
Fk:loadTranslationTable{
  ["mxing__zhanghe"] = "星张郃",
  ["zhilve"] = "知略",
  [":zhilve"] = "出牌阶段限一次，你可以失去1点体力令你本回合手牌上限+1，并选择一项：1.移动场上一张牌；2.摸一张牌并视为使用一张无距离次数限制的【杀】。",
  ["#zhilve1"] = "知略：选择移动牌的来源和目标",
  ["#zhilve2"] = "知略：选择使用【杀】的目标",
  ["zhilve1"] = "移动场上一张牌",
  ["zhilve2"] = "摸一张牌并视为使用杀",

  ["$zhilve1"] = "将者，上不制天，下不制地，中不制人。",
  ["$zhilve2"] = "料敌之计，明敌之意，因况反制。",
  ["~mxing__zhanghe"] = "若非小人作梗，何至官渡之败……",
}

local xuhuang = General(extension, "mxing__xuhuang", "qun", 4)
local mxing__zhiyan = fk.CreateActiveSkill{
  name = "mxing__zhiyan",
  anim_type = "support",
  interaction = function(self)
    local choiceList = {}
    local handcardNum = #Self:getCardIds(Player.Hand)
    if handcardNum < Self.maxHp and Self:getMark("mxing__zhiyan_draw-phase") == 0 then
      table.insert(choiceList, "mxing__zhiyan_draw")
    end
    if handcardNum > Self.hp and Self:getMark("mxing__zhiyan_give-phase") == 0 then 
      table.insert(choiceList, "mxing__zhiyan_give")
    end
    if #choiceList == 0 then return false end
    return UI.ComboBox { choices = choiceList , all_choices = {"mxing__zhiyan_draw", "mxing__zhiyan_give"}}
  end,
  card_num = function(self)
    return self.interaction.data == "mxing__zhiyan_draw" and 0 or (#Self:getCardIds(Player.Hand) - Self.hp)
  end,
  target_num = function(self)
    return self.interaction.data == "mxing__zhiyan_draw" and 0 or 1
  end,
  can_use = function(self, player)
    local handcardNum = #player:getCardIds(player.Hand)
    return
      (handcardNum < player.maxHp and player:getMark("mxing__zhiyan_draw-phase") == 0) or
      (handcardNum > player.hp and player:getMark("mxing__zhiyan_give-phase") == 0)
  end,
  card_filter = function(self, to_select, selected)
    return
      self.interaction.data == "mxing__zhiyan_give" and
      #selected < (#Self:getCardIds(Player.Hand) - Self.hp) and
      Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return self.interaction.data == "mxing__zhiyan_give" and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    if self.interaction.data == "mxing__zhiyan_draw" then
      from:drawCards(from.maxHp - #from:getCardIds(Player.Hand), self.name)
      room:setPlayerMark(from, "mxing__zhiyan_draw-phase", 1)
    else
      local pack = Fk:cloneCard("slash")
      pack:addSubcards(effect.cards)
      room:moveCardTo(pack, Player.Hand, room:getPlayerById(effect.tos[1]), fk.ReasonGive, self.name)
      room:setPlayerMark(from, "mxing__zhiyan_give-phase", 1)
    end
  end,
}
local mxing__zhiyanProhibit = fk.CreateProhibitSkill{
  name = "#mxing__zhiyan_prohibit",
  is_prohibited = function(self, from, to)
    return from:getMark("mxing__zhiyan_draw-phase") > 0 and from ~= to
  end,
}
mxing__zhiyan:addRelatedSkill(mxing__zhiyanProhibit)
xuhuang:addSkill(mxing__zhiyan)
Fk:loadTranslationTable{
  ["mxing__xuhuang"] = "星徐晃",
  ["mxing__zhiyan"] = "治严",
  [":mxing__zhiyan"] = "出牌阶段每项各限一次，你可以：1.将手牌摸至体力上限，然后你于此阶段内不能对其他角色使用牌；2.将多于体力值的手牌交给一名其他角色。",
  ["mxing__zhiyan_draw"] = "将手牌摸至体力上限",
  ["mxing__zhiyan_give"] = "交给其他角色多于体力值的牌",

  ["$mxing__zhiyan1"] = "治军严谨，方得精锐之师。",
  ["$mxing__zhiyan2"] = "精兵当严于律己，束身自修。",
  ["~mxing__xuhuang"] = "唉，明主未遇，大功未成……",
}

local ganning = General(extension, "mxing__ganning", "qun", 4)
local jinfan = fk.CreateTriggerSkill{
  name = "jinfan",
  anim_type = "drawcard",
  expand_pile = "jinfan&",
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Discard and not player:isKongcheng()
      else
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromSpecialName == "jinfan&" then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local success, dat = player.room:askForUseActiveSkill(target, "jinfan_active", "#jinfan-invoke", true)
      if success then
        self.cost_data = dat.cards
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      player:addToPile("jinfan&", self.cost_data, true, self.name)
    else
      local room = player.room
      local suits = {}
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerSpecial and info.fromSpecialName == "jinfan&" then
              table.insertIfNeed(suits, Fk:getCardById(info.cardId):getSuitString())
            end
          end
        end
      end
      for _, suit in ipairs(suits) do
        if player.dead then return end
        local cards = room:getCardsFromPileByRule(".|.|"..suit)
        if #cards > 0 then
          room:obtainCard(player, cards[1], false, fk.ReasonJustMove)
        end
      end
    end
  end,
}
local jinfan_active = fk.CreateActiveSkill{
  name = "jinfan_active",
  mute = true,
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Player.Equip or table.find(Self:getPile("jinfan&"), function(id)
      return Fk:getCardById(to_select).suit == Fk:getCardById(id).suit end) then return end
    if #selected == 0 then
      return true
    else
      return table.every(selected, function(id) return Fk:getCardById(to_select).suit ~= Fk:getCardById(id).suit end)
    end
  end,
}
local sheque = fk.CreateTriggerSkill{
  name = "sheque",
  events = {fk.EventPhaseStart},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player ~= target and target.phase == Player.Start and #target:getCardIds("e") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askForUseCard(player, "slash", "slash", "#sheque-invoke::"..target.id, true,
      {must_targets = {target.id}, bypass_distances = true})
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local dat = self.cost_data
    dat.extra_data = dat.extra_data or {}
    dat.extra_data.sheque = true
    player.room:useCard(self.cost_data)
  end,

  refresh_events = {fk.TargetSpecified, fk.CardUseFinished},
  can_refresh = function (self, event, target, player, data)
    if event == fk.TargetSpecified then
      return target == player and data.extra_data and data.extra_data.sheque
    else
      return data.extra_data and data.extra_data.shequeNullified
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
      data.extra_data.shequeNullified = data.extra_data.shequeNullified or {}
      data.extra_data.shequeNullified[tostring(data.to)] = (data.extra_data.shequeNullified[tostring(data.to)] or 0) + 1
    else
      for key, num in pairs(data.extra_data.shequeNullified) do
        local p = room:getPlayerById(tonumber(key))
        if p:getMark(fk.MarkArmorNullified) > 0 then
          room:removePlayerMark(p, fk.MarkArmorNullified, num)
        end
      end
      data.shequeNullified = nil
    end
  end,
}
Fk:addSkill(jinfan_active)
ganning:addSkill(jinfan)
ganning:addSkill(sheque)
Fk:loadTranslationTable{
  ["mxing__ganning"] = "星甘宁",
  ["jinfan"] = "锦帆",
  [":jinfan"] = "弃牌阶段开始时，你可以将任意张手牌置于武将牌上，称为“铃”（每种花色限一张），你可以将“铃”如手牌般使用或打出；当“铃”离开你的武将牌时，"..
  "你从牌堆获得一张同花色的牌。",
  ["sheque"] = "射却",
  [":sheque"] = "一名其他角色的准备阶段，若其装备区有牌，你可以对其使用一张无距离限制的【杀】，此【杀】无视防具。",
  ["jinfan&"] = "铃",
  ["jinfan_active"] = "锦帆",
  ["#jinfan-invoke"] = "锦帆：你可以将任意张手牌置为“铃”",
  ["#sheque-invoke"] = "射却：你可以对 %dest 使用一张无距离限制且无视防具的【杀】",

  ["$jinfan1"] = "扬锦帆，劫四方，快意逍遥！",
  ["$jinfan2"] = "铃声所至之处，再无安宁！",
  ["$sheque1"] = "看我此箭，取那轻舟冒进之人性命！",
  ["$sheque2"] = "纵有劲甲良盾，也难挡我神射之威！",
  ["~mxing__ganning"] = "铜铃声……怕是听不到了……",
  ["$mxing__ganning_win_audio"] = "又是大丰收啊！弟兄们，扬帆起航！",
}

local huangzhong = General(extension, "mxing__huangzhong", "qun", 4)
local shidi = fk.CreateTriggerSkill{
  name = "shidi",
  events = {fk.EventPhaseStart},
  mute = true,
  frequency = Skill.Compulsory,
  switch_skill_name = "shidi",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if player:getSwitchSkillState(self.name) == fk.SwitchYin then
        return player.phase == Player.Start
      elseif player:getSwitchSkillState(self.name) == fk.SwitchYang then
        return player.phase == Player.Finish
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(self.name, player:getSwitchSkillState(self.name) + 1)
    player.room:notifySkillInvoked(player, self.name, "switch")
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self) and data.card.trueName == "slash" then
      if player:getSwitchSkillState(self.name) == fk.SwitchYin then
        return data.card.color == Card.Black and data.from == player.id
      elseif player:getSwitchSkillState(self.name) == fk.SwitchYang then
        return data.card.color == Card.Red and data.from ~= player.id and table.contains(TargetGroup:getRealTargets(data.tos), player.id)
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    if player:getSwitchSkillState(self.name) == fk.SwitchYang then
      table.insertTable(data.disresponsiveList, table.map(player.room.alive_players, function(p) return p.id end))
    else
      table.insertIfNeed(data.disresponsiveList, player.id)
    end
  end,
}
local shidiBuff = fk.CreateDistanceSkill{
  name = "#shidi-buff",
  correct_func = function(self, from, to)
    if from:hasSkill("shidi") and from:getSwitchSkillState("shidi") == fk.SwitchYang then
      return -1
    end
    if to:hasSkill("shidi") and to:getSwitchSkillState("shidi") == fk.SwitchYin then
      return 1
    end
  end,
}
local yishi = fk.CreateTriggerSkill{
  name = "xing__yishi",
  anim_type = "control",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to ~= player and #data.to:getCardIds(Player.Equip) > 0
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage - 1
    local room = player.room

    if #data.to:getCardIds(Player.Equip) > 0 then
      local cardId = room:askForCardChosen(player, data.to, "e", self.name)
      room:obtainCard(player, cardId, true, fk.ReasonPrey)
    end

    return data.damage < 1
  end,
}
local qishe = fk.CreateViewAsSkill{
  name = "qishe",
  anim_type = "offensive",
  pattern = "analeptic",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("analeptic")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_response = function(self, player, cardResponding)
    return not cardResponding
  end
}
local qisheBuff = fk.CreateMaxCardsSkill{
  name = "#qishe-buff",
  correct_func = function(self, player)
    return player:hasSkill(self) and #player:getCardIds(Player.Equip) or 0
  end,
}
shidi:addRelatedSkill(shidiBuff)
qishe:addRelatedSkill(qisheBuff)
huangzhong:addSkill(shidi)
huangzhong:addSkill(yishi)
huangzhong:addSkill(qishe)
Fk:loadTranslationTable{
  ["mxing__huangzhong"] = "星黄忠",
  ["shidi"] = "势敌",
  [":shidi"] = "锁定技，准备阶段开始时，转换为阳；结束阶段开始时，转换为阴；阳：你计算与其他角色的距离-1，且你使用的黑色【杀】不可被响应；"..
  "阴：其他角色计算与你的距离+1，且你不可响应其他角色对你使用的红色【杀】。",
  ["xing__yishi"] = "义释",
  [":xing__yishi"] = "当你对其他角色造成伤害时，你可以令此伤害-1并获得其装备区里的一张牌。",
  ["qishe"] = "骑射",
  [":qishe"] = "你可以将一张装备牌当【酒】使用；你的手牌上限+X（X为你装备区里的牌数）。",

  ["$shidi1"] = "诈败以射之，其必死矣！",
  ["$shidi2"] = "呃啊，中其拖刀计矣！",
  ["$xing__yishi1"] = "昨日释忠之恩，今吾虚射以报。",
  ["$xing__yishi2"] = "君刀不砍头颅，吾箭只射盔缨。",
  ["$qishe1"] = "诱敌之计已成，吾且拈弓搭箭！",
  ["$qishe2"] = "关羽即至吊桥，既已控弦，如何是好？",
  ["~mxing__huangzhong"] = "关云长义释黄某，吾又安忍射之……",
}

local weiyan = General(extension, "mxing__weiyan", "qun", 4)
weiyan.shield = 1
local guli = fk.CreateViewAsSkill{
  name = "guli",
  prompt = "#guli",
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card:addSubcards(Self:getCardIds("h"))
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
}
local guli_record = fk.CreateTriggerSkill{
  name = "#guli_record",
  mute = true,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "guli")
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
    data.extra_data = data.extra_data or {}
    data.extra_data.guli = data.extra_data.guli or {}
    data.extra_data.guli[tostring(data.to)] = (data.extra_data.guli[tostring(data.to)] or 0) + 1
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.guli
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.guli) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
    end
    data.extra_data.guli = nil
  end,
}
local guli_trigger = fk.CreateTriggerSkill{
  name = "#guli_trigger",
  mute = true,
  main_skill = guli,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("guli") and table.contains(data.card.skillNames, "guli") and data.damageDealt
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "guli", nil, "#guli-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, "guli")
    if player.dead or player:getHandcardNum() >= player.maxHp then return end
    player:drawCards(player.maxHp - player:getHandcardNum(), "guli")
  end,
}
local aosi = fk.CreateTriggerSkill{
  name = "aosi",
  frequency = Skill.Compulsory,
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      not data.to.dead and player:inMyAttackRange(data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    room:setPlayerMark(data.to, "@@aosi-phase", 1)
  end,
}
local aosi_targetmod = fk.CreateTargetModSkill{
  name = "#aosi_targetmod",
  frequency = Skill.Compulsory,
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill("aosi") and scope == Player.HistoryPhase and to:getMark("@@aosi-phase") > 0
  end,
}
guli:addRelatedSkill(guli_record)
guli:addRelatedSkill(guli_trigger)
aosi:addRelatedSkill(aosi_targetmod)
weiyan:addSkill(guli)
weiyan:addSkill(aosi)
Fk:loadTranslationTable{
  ["mxing__weiyan"] = "星魏延",
  ["guli"] = "孤厉",
  [":guli"] = "出牌阶段限一次，你可以将所有手牌当一张无视防具的【杀】使用。此牌结算后，若此牌造成过伤害，你可以失去1点体力，然后将手牌摸至体力上限。",
  ["aosi"] = "骜肆",
  [":aosi"] = "锁定技，当你于出牌阶段对一名在你攻击范围内的其他角色造成伤害后，你于此阶段对其使用牌无次数限制。",
  ["#guli"] = "孤厉：你可以将所有手牌当一张无视防具的【杀】使用",
  ["#guli-invoke"] = "孤厉：你可以失去1点体力，将手牌补至体力上限",
  ["@@aosi-phase"] = "骜肆",

  ["~mxing__weiyan"] = "使君为何弃我而去……呃啊！",
}

local zhoubuyi = General(extension, "mxing__zhoubuyi", "wei", 3)
local huiyao = fk.CreateActiveSkill{
  name = "huiyao",
  anim_type = "masochism",
  card_num = 0,
  target_num = 1,
  prompt = "#huiyao",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:damage{
      from = nil,
      to = player,
      damage = 1,
      skillName = self.name,
    }
    if player.dead then return end
    local targets = table.map(room:getOtherPlayers(target), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#huiyao-choose::"..target.id, self.name, false, true)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    room:doIndicate(target.id, {to})

    local logic = room.logic
    local damageStruct = {
      from = target,
      to = room:getPlayerById(to),
      damageType = fk.NormalDamage,
      damage = 1,
      skillName = self.name,
    }

    local stages = {
      {fk.PreDamage, damageStruct.from},
      {fk.DamageCaused, damageStruct.from},
      {fk.DamageInflicted, damageStruct.to},
    }
    for _, struct in ipairs(stages) do
      local event, p = table.unpack(struct)
      if logic:trigger(event, p, damageStruct) or damageStruct.damage < 1 then
        logic:breakEvent(false)
      end
    end
    if damageStruct.to.dead then return false end
    local damage_nature_table = {
      [fk.NormalDamage] = "normal_damage",
      [fk.FireDamage] = "fire_damage",
      [fk.ThunderDamage] = "thunder_damage",
      [fk.IceDamage] = "ice_damage",
    }
    room:sendLog{
      type = "#Damage",
      to = {damageStruct.from.id},
      from = damageStruct.to.id,
      arg = damageStruct.damage,
      arg2 = damage_nature_table[damageStruct.damageType],
    }
    room:sendLogEvent("Damage", {
      to = damageStruct.to.id,
      damageType = damage_nature_table[damageStruct.damageType],
      damageNum = damageStruct.damage,
    })

    stages = {
      {fk.Damage, damageStruct.from},
      {fk.Damaged, damageStruct.to},
      {fk.DamageFinished, damageStruct.to},
    }
    for _, struct in ipairs(stages) do
      local event, p = table.unpack(struct)
      logic:trigger(event, p, damageStruct)
    end

    logic:trigger(fk.DamageFinished, damageStruct.to, damageStruct)

    --[[local event = GameEvent:new(GameEvent.Damage)
    event.parent = logic:getCurrentEvent()
    logic.current_event_id = logic.current_event_id + 1
    event.id = logic.current_event_id
    event.data = event.data or {}
    event.data[1] = damageStruct
    logic.all_game_events[event.id] = event
    logic.event_recorder[event.event] = logic.event_recorder[event.event] or {}
    table.insert(logic.event_recorder[event.event], event)]]--
  end,
}
local quesong = fk.CreateTriggerSkill{
  name = "quesong",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Finish then
      return #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
        local damage = e.data[5]
        return damage and player == damage.to
      end, Player.HistoryTurn) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#quesong-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"yl_draw"}
    if to:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(to, choices, self.name)
    if choice == "yl_draw" then
      to:drawCards(math.max(#to:getAvailableEquipSlots() - #to:getCardIds("e"), 1), self.name)
    else
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
zhoubuyi:addSkill(huiyao)
zhoubuyi:addSkill(quesong)
Fk:loadTranslationTable{
  ["mxing__zhoubuyi"] = "星周不疑",
  ["huiyao"] = "慧夭",
  [":huiyao"] = "出牌阶段限一次，你可以受到1点无来源伤害并选择一名其他角色，<font color='red'>视为</font>其对你选择的另一名角色造成1点伤害。",
  ["quesong"] = "雀颂",
  [":quesong"] = "一名角色结束阶段，若你本回合受到过伤害，你可以令一名角色选择一项：1.摸X张牌并复原武将牌（X为其装备区空置栏位数，至少为1）"..
  "回复1点体力。",
  ["#huiyao"] = "慧夭：你可以受到1点无来源伤害，选择一名其他角色，令其<font color='red'>视为</font>造成伤害",
  ["#huiyao-choose"] = "慧夭：选择一名角色，视为 %dest 对其造成1点伤害",
  ["#quesong-choose"] = "雀颂：你可以令一名角色选择摸牌或回复体力",
}

return extension
