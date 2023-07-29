local extension = Package("mobile_sp")
extension.extensionName = "mobile"
Fk:loadTranslationTable{
  ["mobile_sp"] = "手杀专属",
  ["mxing"] = "手杀星",
}

local sunru = General(extension, "sunru", "wu", 3, 3, General.Female)
local yingjian = fk.CreateTriggerSkill{
  name = "yingjian",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
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
    return target == player and player:hasSkill(self.name) and
      data.damageType == fk.FireDamage
  end,
  on_use = Util.TrueFunc,
}
sunru:addSkill(shixin)
Fk:loadTranslationTable{
  ["sunru"] = "孙茹",
  ["yingjian"] = "影箭",
  ["#yingjian-choose"] = "影箭: 你现在可以视为使用无视距离的【杀】",
  [":yingjian"] = "准备阶段，你可以视为使用一张无距离限制的【杀】。",
  ["shixin"] = "释衅",
  [":shixin"] = "锁定技，防止你受到的火属性伤害。",
}

local liuzan = General(extension, "liuzan", "wu", 4)
local fenyin = fk.CreateTriggerSkill{
  name = "fenyin",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase < Player.NotActive and self.can_fenyin
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.CardUsing, fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self.name)) then return end
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
    local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
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

-- local yangyi = General(extension, "yangyi", "shu", 3)
-- Fk:loadTranslationTable{
--   ["yangyi"] = "杨仪",
--   ["~yangyi"] = "废立大事，公不可不慎……",
-- }

-- local duoduan = fk.CreateTriggerSkill{
--   name = "duoduan",
--   events = {fk.TargetConfirmed},
--   anim_type = "defensive",
--   can_trigger = function(self, event, target, player, data)
--     return
--       target == player and
--       player:hasSkill(self.name) and
--       player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
--       not player:isNude() and
--       data.card.trueName == "slash"
--   end,
--   on_cost = function(self, event, target, player, data)
--     local cardIds = player.room:askForCard(player, 1, 1, true, self.name, false, nil, "#duoduan-recast::" .. data.from)
--     if #cardIds > 0 then
--       self.cost_data = cardIds[1]
--       return true
--     end

--     return false
--   end,
--   on_use = function(self, event, target, player, data)
--     local room = player.room
--     room:recastCard({ self.cost_data }, player, self.name)

--     local user = room:getPlayerById(data.from)
--     if not user:isAlive() then
--       return false
--     end

--     local choices = { "duoduan_drawCards" }
--     if not player:isNude() then
--       table.insert(choices, "duoduan_discard")
--     end

--     local choice = room:askForChoice(player, choices, self.name, "#duoduan-choose::" .. data.from)
--     local parentUseEvent = GameEvent:findParent(GameEvent.UseCard)
--     if choice == "duoduan_drawCards" then
--       user:drawCards(2, self.name)
--       if parentUseEvent then
--         parentUseEvent.nullifiedTargets = room.players
--       end
--     else
--       local toThrow = room:askForDiscard(user, 1, 1, true, self.name, true)
--       if #toThrow > 0 and parentUseEvent then
--         parentUseEvent.disresponsiveList = room.players
--       end
--     end
--   end,
-- }
-- Fk:loadTranslationTable{
--   ["duoduan"] = "度断",
--   [":duoduan"] = "每回合限一次，当你成为【杀】的目标后，你可以重铸一张牌，然后你选择一项令使用者执行：1.摸两张牌然后此【杀】对所有目标无效；2.弃置一张牌然后此【杀】不可被响应。",
--   ["#duoduan-recast"] = "度断：你可以重铸一张牌令%dest执行一项效果",
--   ["#duoduan-choose"] = "度断：令%dest摸牌此杀无效或弃牌此杀不能被响应",
--   ["$duoduan1"] = "制图之体有六，缺一不可言精。",
--   ["$duoduan2"] = "图设分率，则宇内地域皆可绘于一尺。",
-- }

-- yangyi:addSkill(duoduan)

-- local gongsun = fk.CreateTriggerSkill{
--   name = "gongsun",
--   events = {fk.EventPhaseStart},
--   anim_type = "control",
--   can_trigger = function(self, event, target, player, data)
--     return
--       target == player and
--       player:hasSkill(self.name) and
--       player.phase == Player.Play and
--       #player:getCardIds({ Player.Hand, Player.Equip }) > 1
--   end,
--   on_cost = function(self, event, target, player, data)
--     local cardIds = player.room:askForCard(player, 1, 1, true, self.name, false, nil, "#duoduan-recast::" .. data.from)
--     if #cardIds > 0 then
--       self.cost_data = cardIds[1]
--       return true
--     end

--     return false
--   end,
--   on_use = function(self, event, target, player, data)
--     local room = player.room
--     room:recastCard({ self.cost_data }, player, self.name)

--     local user = room:getPlayerById(data.from)
--     if not user:isAlive() then
--       return false
--     end

--     local choices = { "duoduan_drawCards" }
--     if not player:isNude() then
--       table.insert(choices, "duoduan_discard")
--     end

--     local choice = room:askForChoice(player, choices, self.name, "#duoduan-choose::" .. data.from)
--     local parentUseEvent = GameEvent:findParent(GameEvent.UseCard)
--     if choice == "duoduan_drawCards" then
--       user:drawCards(2, self.name)
--       if parentUseEvent then
--         parentUseEvent.nullifiedTargets = room.players
--       end
--     else
--       local toThrow = room:askForDiscard(user, 1, 1, true, self.name, true)
--       if #toThrow > 0 and parentUseEvent then
--         parentUseEvent.disresponsiveList = room.players
--       end
--     end
--   end,
-- }
-- Fk:loadTranslationTable{
--   ["duoduan"] = "度断",
--   [":duoduan"] = "每回合限一次，当你成为【杀】的目标后，你可以重铸一张牌，然后你选择一项令使用者执行：1.摸两张牌然后此【杀】对所有目标无效；2.弃置一张牌然后此【杀】不可被响应。",
--   ["#duoduan-recast"] = "度断：你可以重铸一张牌令%dest执行一项效果",
--   ["#duoduan-choose"] = "度断：令%dest摸牌此杀无效或弃牌此杀不能被响应",
--   ["$duoduan1"] = "制图之体有六，缺一不可言精。",
--   ["$duoduan2"] = "图设分率，则宇内地域皆可绘于一尺。",
-- }

local peixiu = General(extension, "peixiu", "qun", 3)
Fk:loadTranslationTable{
  ["peixiu"] = "裴秀",
  ["~peixiu"] = "既食寒石散，便不可饮冷酒啊……",
}

local xingtu = fk.CreateTriggerSkill{
  name = "xingtu",
  events = {fk.CardUsing},
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self.name) and data.card.number > 0 and
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
    return (player:hasSkill(self.name) and player:getMark("@xingtu") > 0 and card and card.number > 0 and card.number % player:getMark("@xingtu") == 0) and
      999 or
      0
  end,
}

xingtu:addRelatedSkill(xingtuBuff)
peixiu:addSkill(xingtu)

local juezhi = fk.CreateActiveSkill{
  name = "juezhi",
  anim_type = "drawcard",
  min_card_num = 2,
  can_use = function(self, player)
    return true
  end,
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
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

local xinghuangzhong = General(extension, "mxing__huangzhong", "qun", 4)
Fk:loadTranslationTable{
  ["mxing__huangzhong"] = "星黄忠",
  ["~mxing__huangzhong"] = "关云长义释黄某，吾又安忍射之……",
}

local shidi = fk.CreateTriggerSkill{
  name = "shidi",
  events = {fk.EventPhaseStart},
  mute = true,
  frequency = Skill.Compulsory,
  switch_skill_name = "shidi",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self.name) and
      (
        (player.phase == Player.Start and player:getSwitchSkillState(self.name) == fk.SwitchYin) or
        (player.phase == Player.Finish and player:getSwitchSkillState(self.name) == fk.SwitchYang)
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke(self.name, player:getSwitchSkillState(self.name) + 1)
    room:notifySkillInvoked(player, self.name, "switch")
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return
      player:hasSkill(self.name) and
      data.card.trueName == "slash" and
      (
        (player:getSwitchSkillState(self.name) == fk.SwitchYang and data.card.color == Card.Black and data.from == player.id) or
        (
          player:getSwitchSkillState(self.name) == fk.SwitchYin and
          data.card.color == Card.Red and
          data.from ~= player.id and
          table.contains(TargetGroup:getRealTargets(data.tos), player.id)
        )
      )
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room

    data.disresponsiveList = data.disresponsiveList or {}
    if player:getSwitchSkillState(self.name) == fk.SwitchYang then
      table.insertTable(data.disresponsiveList, table.map(room.players, function(p) return p.id end))
    else
      table.insertIfNeed(data.disresponsiveList, player.id)
    end
  end,
}
Fk:loadTranslationTable{
  ["shidi"] = "势敌",
  [":shidi"] = "锁定技，准备阶段开始时，转换为阳；结束阶段开始时，转换为阴；阳：你计算与其他角色的距离-1，且你使用的黑色【杀】不可被响应；阴：其他角色计算与你的距离+1，且你不可响应其他角色对你使用的红色【杀】。",
  ["$shidi1"] = "诈败以射之，其必死矣！",
  ["$shidi2"] = "呃啊，中其拖刀计矣！",
}

local shidiBuff = fk.CreateDistanceSkill{
  name = "#shidi-buff",
  correct_func = function(self, from, to)
    if from:hasSkill("shidi") and from:getSwitchSkillState("shidi") == fk.SwitchYang then
      return -1
    elseif to:hasSkill("shidi") and to:getSwitchSkillState("shidi") == fk.SwitchYin then
      return 1
    end
  end,
}

shidi:addRelatedSkill(shidiBuff)
xinghuangzhong:addSkill(shidi)

local xingYishi = fk.CreateTriggerSkill{
  name = "xing__yishi",
  anim_type = "control",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to ~= player and #data.to:getCardIds(Player.Equip) > 0
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
Fk:loadTranslationTable{
  ["xing__yishi"] = "义释",
  [":xing__yishi"] = "当你对其他角色造成伤害时，你可以令此伤害-1并获得其装备区里的一张牌。",
  ["$xing__yishi1"] = "昨日释忠之恩，今吾虚射以报。",
  ["$xing__yishi2"] = "君刀不砍头颅，吾箭只射盔缨。",
}

xinghuangzhong:addSkill(xingYishi)

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
Fk:loadTranslationTable{
  ["qishe"] = "骑射",
  [":qishe"] = "你可以将一张装备牌当【酒】使用；你的手牌上限+X（X为你装备区里的牌数）。",
  ["$qishe1"] = "诱敌之计已成，吾且拈弓搭箭！",
  ["$qishe2"] = "关羽即至吊桥，既已控弦，如何是好？",
}

local qisheBuff = fk.CreateMaxCardsSkill{
  name = "#qishe-buff",
  correct_func = function(self, player)
    return player:hasSkill(self.name) and #player:getCardIds(Player.Equip) or 0
  end,
}

shidi:addRelatedSkill(qisheBuff)
xinghuangzhong:addSkill(qishe)

local xingxuhuang = General(extension, "mxing__xuhuang", "qun", 4)
Fk:loadTranslationTable{
  ["mxing__xuhuang"] = "星徐晃",
  ["~mxing__xuhuang"] = "唉，明主未遇，大功未成……",
}

local xingZhiyan = fk.CreateActiveSkill{
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

    return UI.ComboBox { choices = choiceList }
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
Fk:loadTranslationTable{
  ["mxing__zhiyan"] = "治严",
  [":mxing__zhiyan"] = "出牌阶段每项各限一次，你可以：1.将手牌摸至体力上限，然后你于此阶段内不能对其他角色使用牌；2.将多于体力值数量的手牌交给一名其他角色。",
  ["mxing__zhiyan_draw"] = "将手牌摸至体力上限",
  ["mxing__zhiyan_give"] = "交给其他角色多于体力值的牌",
  ["$mxing__zhiyan1"] = "治军严谨，方得精锐之师。",
  ["$mxing__zhiyan2"] = "精兵当严于律己，束身自修。",
}

local xingZhiyanProhibit = fk.CreateProhibitSkill{
  name = "#xingZhiyan-prohibit",
  is_prohibited = function(self, from, to)
    return from:getMark("mxing__zhiyan_draw-phase") > 0 and from ~= to
  end,
}

xingZhiyan:addRelatedSkill(xingZhiyanProhibit)
xingxuhuang:addSkill(xingZhiyan)

local yangbiao = General(extension, "yangbiao", "qun", 3)
Fk:loadTranslationTable{
  ["yangbiao"] = "杨彪",
  ["~yangbiao"] = "未能效死佑汉，只因宗族之重……",
}

local zhaohan = fk.CreateTriggerSkill{
  name = "zhaohan",
  mute = true,
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) < 7
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:usedSkillTimes(self.name, Player.HistoryGame) < 5 then
      room:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "support")

      room:changeMaxHp(player, 1)
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    else
      room:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")

      room:changeMaxHp(player, -1)
    end
  end,
}
Fk:loadTranslationTable{
  ["zhaohan"] = "昭汉",
  [":zhaohan"] = "锁定技，准备阶段开始时，若X：小于4，你加1点体力上限并回复1点体力；不小于4且小于7，你减1点体力上限（X为你发动过本技能的次数）。",
  ["$zhaohan1"] = "天道昭昭，再兴如光武亦可期。",
  ["$zhaohan2"] = "汉祚将终，我又岂能无憾。",
}

yangbiao:addSkill(zhaohan)

local rangjie = fk.CreateTriggerSkill{
  name = "rangjie",
  events = {fk.Damaged},
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_trigger = function(self, event, target, player, data)
    local ret
    for i = 1, data.damage do
      ret = self:doCost(event, target, player, data)
      if ret then return ret end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choices = { "rangjie_obtain", "Cancel" }
    local room = player.room
    if #room:canMoveCardInBoard() > 0 then
      table.insert(choices, 1, "rangjie_move")
    end

    local choice = room:askForChoice(player, choices, self.name)

    if choice == "Cancel" then
      return false
    end

    if choice == "rangjie_obtain" then
      self.cost_data = room:askForChoice(player, { "basic", "trick", "equip" }, self.name)
    else
      local targets = room:askForChooseToMoveCardInBoard(player, "#rangjie-move", self.name)
      if #targets == 0 then
        return false
      end

      self.cost_data = targets
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if type(self.cost_data) == "string" then
      local cardIds = room:getCardsFromPileByRule(".|.|.|.|.|" .. self.cost_data)
      if #cardIds > 0 then
        room:obtainCard(player, cardIds[1], true, fk.ReasonPrey)
      end
    else
      local targets = table.map(self.cost_data, function(pId)
        return room:getPlayerById(pId)
      end)
      room:askForMoveCardInBoard(player, targets[1], targets[2], self.name)
    end

    player:drawCards(1, self.name)
  end,
}
Fk:loadTranslationTable{
  ["rangjie"] = "让节",
  [":rangjie"] = "当你受到1点伤害后，你可以选择一项：1.移动场上一张牌；2.从牌堆中随机获得一张你指定类别的牌。最后你摸一张牌。",
  ["rangjie_move"] = "移动场上一张牌",
  ["rangjie_obtain"] = "获得指定类别的牌",
  ["#rangjie-move"] = "让节：请选择两名角色，移动其场上的一张牌",
  ["$rangjie1"] = "公既执掌权柄，又何必令君臣遭乱。",
  ["$rangjie2"] = "公虽权倾朝野，亦当尊圣上之意。",
}

yangbiao:addSkill(rangjie)

local mobileYizheng = fk.CreateActiveSkill{
  name = "mobile__yizheng",
  anim_type = "control",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return
      #selected < 1 and
      Self.id ~= to_select and
      Self.hp >= target.hp and
      target:getHandcardNum() > 0
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local pindian = from:pindian({ to }, self.name)
    
    if pindian.results[to.id].winner == from then
      room:setPlayerMark(to, "@@mobile__yizheng", true)
    else
      room:changeMaxHp(from, -1)
    end
  end,
}
Fk:loadTranslationTable{
  ["mobile__yizheng"] = "义争",
  [":mobile__yizheng"] = "出牌阶段限一次，你可以与一名体力值不大于你的角色拼点。若你：赢，跳过其下个摸牌阶段；没赢，你减1点体力上限。",
  ["@@mobile__yizheng"] = "义争",
  ["#yizheng-debuff"] = "义争",
  ["$mobile__yizheng1"] = "一人劫天子，一人质公卿，此可行邪？",
  ["$mobile__yizheng2"] = "诸军举事，当上顺天心，奈何如是！",
}

local mobileYizhengDebuff = fk.CreateTriggerSkill{
  name = "#yizheng-debuff",
  mute = true,
  priority = 3,
  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target:getMark("@@mobile__yizheng") == true and data.from == Player.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    target.room:setPlayerMark(target, "@@mobile__yizheng", 0)
    target:skip(Player.Draw)
  end,
}

mobileYizheng:addRelatedSkill(mobileYizhengDebuff)
yangbiao:addSkill(mobileYizheng)

local wangjun = General(extension, "wangjun", "qun", 4)
Fk:loadTranslationTable{
  ["wangjun"] = "王濬",
  ["~wangjun"] = "问鼎金瓯碎，临江铁索寒……",
}

local zhujian = fk.CreateActiveSkill{
  name = "zhujian",
  anim_type = "drawcard",
  min_target_num = 2,
  max_target_num = 999,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #Fk:currentRoom():getPlayerById(to_select):getCardIds(Player.Equip) > 0
  end,
  on_use = function(self, room, effect)
    local tos = table.simpleClone(effect.tos)
    room:sortPlayersByAction(tos)
    local targets = table.map(effect.tos, function(pId)
      return room:getPlayerById(pId)
    end)

    for _, p in ipairs(targets) do
      p:drawCards(1, self.name)
    end
  end,
}
Fk:loadTranslationTable{
  ["zhujian"] = "筑舰",
  [":zhujian"] = "出牌阶段限一次，你可以令至少两名装备区里有牌的角色各摸一张牌。",
  ["$zhujian1"] = "修橹筑楼舫，伺时补金瓯。",
  ["$zhujian2"] = "连舫披金甲，王气自可收。",
}

wangjun:addSkill(zhujian)

local duansuo = fk.CreateActiveSkill{
  name = "duansuo",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return Fk:currentRoom():getPlayerById(to_select).chained
  end,
  on_use = function(self, room, effect)
    local tos = table.simpleClone(effect.tos)
    room:sortPlayersByAction(tos)
    local targets = table.map(effect.tos, function(pId)
      return room:getPlayerById(pId)
    end)

    for _, p in ipairs(targets) do
      p:setChainState(false)
    end

    for _, p in ipairs(targets) do
      room:damage({
        from = room:getPlayerById(effect.from),
        to = p,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = self.name,
      })
    end
  end,
}
Fk:loadTranslationTable{
  ["duansuo"] = "断索",
  [":duansuo"] = "出牌阶段限一次，你可以重置至少一名角色，然后对这些角色各造成1点火焰伤害。",
  ["$duansuo1"] = "吾心如炬，无碍寒江铁索。",
  ["$duansuo2"] = "熔金断索，克敌建功！",
}

wangjun:addSkill(duansuo)

local wangyuanji = General(extension, "mobile__wangyuanji", "wei", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["mobile__wangyuanji"] = "王元姬",
  ["~mobile__wangyuanji"] = "世事沉浮，非是一人可逆啊……",
  --["mobile__wangyuanji-winner"] = "苍生黎庶，都会有一个美好的未来了。",
}

local qianchong = fk.CreateTriggerSkill{
  name = "qianchong",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play then
      local colors = {}
      for _, id in ipairs(player.player_cards[Player.Equip]) do
        table.insertIfNeed(colors, Fk:getCardById(id).color)
      end
      table.removeOne(colors, Card.NoColor)
      return #colors ~= 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local choice = player.room:askForChoice(player, {"basic", "trick", "equip"}, self.name, "#qianchong-choice")
    player.room:setPlayerMark(player, "@qianchong-phase", choice)
  end,

  refresh_events = {fk.AfterCardsMove, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return event == fk.AfterCardsMove or (data == self and player == target)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local equips = player.player_cards[Player.Equip]
    local hasweimu = player:hasSkill(self.name, true) and #equips > 0 and table.every(equips, function (id)
      return Fk:getCardById(id).color == Card.Black end)
    local hasmingzhe = player:hasSkill(self.name, true) and #equips > 0 and table.every(equips, function (id)
      return Fk:getCardById(id).color == Card.Red end)

    local qianchong_skills = type(player:getMark("qianchong_skills")) == "table" and player:getMark("qianchong_skills") or {}
    local skillchange = {}
    if hasweimu and not player:hasSkill("weimu", true) then
      table.insert(skillchange, "weimu")
      table.insertIfNeed(qianchong_skills, "weimu")
    elseif not hasweimu and player:hasSkill("weimu", true) and table.contains(qianchong_skills, "weimu") then
      table.insert(skillchange, "-weimu")
      table.removeOne(qianchong_skills, "mingzhe")
    end
    if hasmingzhe and not player:hasSkill("mingzhe", true) then
      table.insert(skillchange, "mingzhe")
      table.insertIfNeed(qianchong_skills, "mingzhe")
    elseif not hasmingzhe and player:hasSkill("mingzhe", true) and table.contains(qianchong_skills, "mingzhe") then
      table.insert(skillchange, "-mingzhe")
      table.removeOne(qianchong_skills, "mingzhe")
    end
    if #skillchange > 0 then
      room:handleAddLoseSkills(player, table.concat(skillchange, "|"), nil, true, false)
    end
    room:setPlayerMark(player, "qianchong_skills", qianchong_skills)
  end,
}

local qianchong_targetmod = fk.CreateTargetModSkill{
  name = "#qianchong_targetmod",
  residue_func = function(self, player, skill, scope, card)
    return (card and card:getTypeString() == player:getMark("@qianchong-phase")) and 999 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return (card and card:getTypeString() == player:getMark("@qianchong-phase")) and 999 or 0
  end,
}

qianchong:addRelatedSkill(qianchong_targetmod)

Fk:loadTranslationTable{
  ["qianchong"] = "谦冲",
  [":qianchong"] = "锁定技，如果你的装备区所有牌均为黑色，则你拥有〖帷幕〗；如果你装备区所有牌均为红色，则你拥有〖明哲〗。出牌阶段开始时，若你不满足上述条件，则你选择一种类型的牌，本阶段内使用此类型的牌无次数和距离限制。",
  ["#qianchong-choice"] = "谦冲：选择一种类别，此阶段内使用此类别的牌无次数和距离限制",
  ["@qianchong-phase"] = "谦冲",
  ["$qianchong1"] = "细行策划，只盼能助夫君一臂之力。",
}

wangyuanji:addSkill(qianchong)

local shangjian = fk.CreateTriggerSkill{
  name = "shangjian",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Finish and
      player:getMark("shangjian-turn") > 0 and player:getMark("shangjian-turn") <= player.hp
  end,
  on_use = function(self, event, target, player, data)
    player.room:drawCards(player, player:getMark("shangjian-turn"), self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    local fuckYoka = {}
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if parentUseData then
      local use = parentUseData.data[1]
      if use.card.type == Card.TypeEquip and use.from == player.id then
        fuckYoka = use.card:isVirtual() and use.card.subcards or {use.card.id}
      end
    end
    local x = 0
    for _, move in ipairs(data) do
      if move.from and move.from == player.id then
        x = x + #table.filter(move.moveInfo, function(info)
          return (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and not table.contains(fuckYoka, info.cardId) end)
      end
      if move.to ~= player.id or move.toArea ~= Card.PlayerEquip then
        x = x + #table.filter(move.moveInfo, function(info)
          return (info.fromArea == Card.Processing) and table.contains(fuckYoka, info.cardId) end)
      end
    end
    if x > 0 then
      self.cost_data = x
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "shangjian-turn", self.cost_data)
    if player:hasSkill(self.name, true) then
      player.room:setPlayerMark(player, "@shangjian-turn", player:getMark("shangjian-turn"))
    end
  end,
}

Fk:loadTranslationTable{
  ["shangjian"] = "尚俭",
  [":shangjian"] = "锁定技，一名角色的结束阶段，若你于此回合失去的牌（非因使用装备牌而失去的牌数与你使用装备牌的过程中未进入你装备区的牌数之和）不大于你的体力值，你摸等同于失去数量的牌。",
  ["@shangjian-turn"] = "尚俭",
  ["$shangjian1"] = "如今乱世，当秉俭行之节。",
  ["$shangjian2"] = "百姓尚处寒饥之困，吾等不可奢费财力。",
}

wangyuanji:addSkill(shangjian)

--[[
Fk:loadTranslationTable{
  ["$weimu-mobile__wangyuanji"] = "宫闱之内，何必擅涉外事！",
  ["$mingzhe-mobile__wangyuanji"] = "谦瑾行事，方能多吉少恙。",
}
]]

wangyuanji:addRelatedSkill("weimu")
wangyuanji:addRelatedSkill("mingzhe")

local yanghuiyu = General(extension, "mobile__yanghuiyu", "wei", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["mobile__yanghuiyu"] = "羊徽瑜",
  ["~mobile__yanghuiyu"] = "桃符，一定要平安啊……",
}

local hongyi = fk.CreateActiveSkill{
  name = "hongyi",
  anim_type = "control",
  prompt = "#hongyi-active",
  max_card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(target, "@@hongyi")
    local targetRecorded = type(player:getMark("hongyi_targets")) == "table" and player:getMark("hongyi_targets") or {}
    table.insertIfNeed(targetRecorded, effect.tos[1])
    room:setPlayerMark(player, "hongyi_targets", targetRecorded)
  end,
}

local hongyi_delay = fk.CreateTriggerSkill{
  name = "#hongyi_delay",
  anim_type = "control",
  events = {fk.DamageCaused},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and target:getMark("@@hongyi") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      if data.to and not data.to.dead then
        room:drawCards(data.to, 1, hongyi.name)
      end
    elseif judge.card.color == Card.Black then
      data.damage = data.damage - 1
    end
  end,

  refresh_events = {fk.EventPhaseChanging, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging and data.from ~= Player.NotActive then return false end
    return player == target and type(player:getMark("hongyi_targets")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("hongyi_targets")
    if type(targets) == "table" then
      for _, pid in ipairs(targets) do
        room:removePlayerMark(room:getPlayerById(pid), "@@hongyi")
      end
    end
    room:setPlayerMark(player, "hongyi_targets", 0)
  end,
}

hongyi:addRelatedSkill(hongyi_delay)

Fk:loadTranslationTable{
  ["hongyi"] = "弘仪",
  ["#hongyi_delay"] = "弘仪",
  [":hongyi"] = "出牌阶段限一次，你可以指定一名其他角色，然后直到你的下个回合开始时，其造成伤害时进行一次判定：若结果为红色，则受伤角色摸一张牌；若结果为黑色则此伤害-1。",

  ["#hongyi-active"] = "发动弘仪，选择一名其他角色",
  ["@@hongyi"] = "弘仪",
  ["$hongyi1"] = "克明礼教，约束不端之行。",
  ["$hongyi2"] = "训成弘操，以扬正明之德。",
}

yanghuiyu:addSkill(hongyi)

local quanfeng = fk.CreateTriggerSkill{
  name = "quanfeng",
  events = {fk.Deathed, fk.AskForPeaches},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      if event == fk.Deathed then
        return player:hasSkill(hongyi.name, true)
      else
        return player == target and player.dying and player.hp < 1
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = event == fk.Deathed and "#quanfeng1-invoke::" .. target.id or "#quanfeng2-invoke"
    return player.room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Deathed then
      room:handleAddLoseSkills(player, "-hongyi", nil, true, false)

      local skills = {}
      for _, skill_name in ipairs(Fk.generals[target.general]:getSkillNameList()) do
        if not Fk.skills[skill_name].lordSkill then
          table.insertIfNeed(skills, skill_name)
        end
      end
      if target.deputyGeneral and target.deputyGeneral ~= "" then
        for _, skill_name in ipairs(Fk.generals[target.deputyGeneral]:getSkillNameList()) do
          if not Fk.skills[skill_name].lordSkill then
            table.insertIfNeed(skills, skill_name)
          end
        end
      end
      if #skills > 0 then
        room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
      end
      room:changeMaxHp(player, 1)
      if not player.dead and player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    elseif event == fk.AskForPeaches then
      room:changeMaxHp(player, 2)
      if not player.dead and player:isWounded() then
        room:recover({
          who = player,
          num = math.min(4, player:getLostHp()),
          recoverBy = player,
          skillName = self.name
        })
      end
    end
  end,
}

Fk:loadTranslationTable{
  ["quanfeng"] = "劝封",
  [":quanfeng"] = "限定技，当一名其他角色死亡后，你可失去技能〖弘仪〗，然后获得其武将牌的所有技能（主公技除外），若如此做，你加1点体力上限并回复1点体力。当你处于濒死状态时，你可以加2点体力上限，回复4点体力。",
  ["#quanfeng1-invoke"] = "劝封：可失去弘仪并获得%dest的所有技能，然后加1点体力上限和体力",
  ["#quanfeng2-invoke"] = "劝封：是否加2点体力上限，回复4点体力",
  ["$quanfeng1"] = "媛容德懿，应追谥之。",
  ["$quanfeng2"] = "景怀之号，方配得上前人之德。",
}

yanghuiyu:addSkill(quanfeng)

local zhangyi = General(extension, "mobile__zhangyiy", "shu", 4)
Fk:loadTranslationTable{
  ["mobile__zhangyiy"] = "张翼",
  ["~mobile__zhangyiy"] = "唯愿百姓，不受此乱所害，哎……",
}

local zhiyi_viewas = fk.CreateViewAsSkill{
  name = "zhiyi_viewas",
  interaction = function()
    local mark = Self:getMark("@$zhiyi-turn")
    if type(mark) ~= "table" then return nil end
    local names = table.filter(mark, function (card_name)
      local to_use = Fk:cloneCard(card_name)
      return to_use.skill:canUse(Self, to_use) and not Self:prohibitUse(to_use)
    end)
    if #names > 0 then
      return UI.ComboBox {choices = names}
    end
  end,
  card_filter = function() return false end,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "zhiyi"
    return card
  end,
}

Fk:addSkill(zhiyi_viewas)

local zhiyi = fk.CreateTriggerSkill{
  name = "zhiyi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.CardUsing, fk.CardResponding},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.CardUsing or event == fk.CardResponding then
      if player == target and data.card.type == Card.TypeBasic then
        local mark = player:getMark("@$zhiyi-turn")
        return type(mark) ~= "table" or not table.contains(mark, data.card.name)
      end
    elseif event == fk.EventPhaseStart and target.phase == Player.Finish then
      local mark = player:getMark("@$zhiyi-turn")
      return type(mark) == "table" and #mark > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing or event == fk.CardResponding then
      local mark = player:getMark("@$zhiyi-turn")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, data.card.name)
      room:setPlayerMark(player, "@$zhiyi-turn", mark)
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name)
      room:broadcastSkillInvoke(self.name)
      local mark = player:getMark("@$zhiyi-turn")
      if type(mark) ~= "table" then return false end
      if table.every(mark, function (card_name)
        local to_use = Fk:cloneCard(card_name)
        return not (to_use.skill:canUse(player, to_use) and not player:prohibitUse(to_use))
      end) then
        room:drawCards(player, 1, self.name)
        return false
      end
      local success, dat = player.room:askForUseActiveSkill(player, "zhiyi_viewas", "#zhiyi-choose", true)
      if success then
        local card = Fk.skills["zhiyi_viewas"]:viewAs(dat.cards)
        room:useCard{
          from = player.id,
          tos = table.map(dat.targets, function(id) return {id} end),
          card = card,
        }
      else
        room:drawCards(player, 1, self.name)
      end
    end
  end,
}

Fk:loadTranslationTable{
  ["zhiyi"] = "执义",
  [":zhiyi"] = "锁定技，一名角色的结束阶段，若你本回合使用或打出过基本牌，你选择一项：1.视为使用任意一张你本回合使用或打出过的基本牌；2.摸一张牌。",

  ["@$zhiyi-turn"] = "执义",
  ["#zhiyi-choose"] = "执义：选择视为使用一张基本牌，或点取消则摸一张牌",

  ["$zhiyi1"] = "岂可擅退而误国家之功？",
  ["$zhiyi2"] = "统摄不懈，只为破敌！",
}

zhangyi:addSkill(zhiyi)

local fuqian = General(extension, "fuqian", "shu", 4)
Fk:loadTranslationTable{
  ["fuqian"] = "傅佥",
  ["~fuqian"] = "生为蜀臣，死……亦当为蜀！",
}

local poxiang = fk.CreateActiveSkill{
  name = "poxiang",
  anim_type = "drawcard",
  prompt = "#poxiang-active",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    room:obtainCard(effect.tos[1], effect.cards[1], false, fk.ReasonGive)
    local player = room:getPlayerById(effect.from)
    room:drawCards(player, 3, self.name)
    local pile = player:getPile("jueyong_desperation")
    if #pile > 0 then
      room:moveCards({
        from = player.id,
        ids = pile,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
      })
    end
    room:loseHp(player, 1, self.name)
  end
}

local poxiang_refresh = fk.CreateTriggerSkill{
  name = "#poxiang_refresh",

  refresh_events = {fk.AfterCardsMove, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from == player.id and (move.to ~= player.id or move.toArea ~= Card.PlayerHand) then
          for _, info in ipairs(move.moveInfo) do
            room:setCardMark(Fk:getCardById(info.cardId), "@@poxiang", 0)
          end
        elseif move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == "poxiang" then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
              room:setCardMark(Fk:getCardById(id), "@@poxiang", 1)
            end
          end
        end
      end
    elseif event == fk.TurnEnd then
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        room:setCardMark(Fk:getCardById(id), "@@poxiang", 0)
      end
    end
  end,
}

local poxiang_maxcards = fk.CreateMaxCardsSkill{
  name = "#poxiang_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@poxiang") > 0
  end,
}

poxiang:addRelatedSkill(poxiang_refresh)
poxiang:addRelatedSkill(poxiang_maxcards)

Fk:loadTranslationTable{
  ["poxiang"] = "破降",
  [":poxiang"] = "出牌阶段限一次，你可以交给一名其他角色一张牌，然后你摸三张牌，移去所有“绝”并失去1点体力，你以此法获得的牌本回合不计入手牌上限。",
  ["#poxiang-active"] = "发动破降，选择一张牌交给一名角色，然后摸三张牌，移去所有绝并失去1点体力",
  ["@@poxiang"] = "破降",
  ["$poxiang1"] = "王瓘既然假降，吾等可将计就计。",
  ["$poxiang2"] = "佥率已降两千魏兵，便可大破魏军主力。",
}

fuqian:addSkill(poxiang)

local jueyong = fk.CreateTriggerSkill{
  name = "jueyong",
  anim_type = "defensive",
  events = {fk.TargetConfirming, fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) or player ~= target then return false end
    if event == fk.TargetConfirming then
      if data.card.trueName ~= "peach" and data.card.trueName ~= "analeptic" and
      not (data.extra_data and data.extra_data.useByJueyong) and
      not data.card:isVirtual() and data.card.trueName == Fk:getCardById(data.card.id, true).trueName then
        if data.tos and #AimGroup:getAllTargets(data.tos) == 1 then
          return #player:getPile("jueyong_desperation") < player.hp
        end
      end
    elseif event == fk.EventPhaseStart then
      return player.phase == Player.Finish and #player:getPile("jueyong_desperation") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirming then
      TargetGroup:removeTarget(data.targetGroup, player.id)
      if room:getCardArea(data.card) ~= Card.Processing then return false end
      player:addToPile("jueyong_desperation", data.card, true, self.name)
      if table.contains(player:getPile("jueyong_desperation"), data.card.id) then
        local mark = player:getMark(self.name)
        if type(mark) ~= "table" then mark = {} end
        table.insert(mark, {data.card.id, data.from})
        room:setPlayerMark(player, self.name, mark)
      end
    elseif event == fk.EventPhaseStart then
      while #player:getPile("jueyong_desperation") > 0 do
        local id = player:getPile("jueyong_desperation")[1]
        local jy_remove = true
        local card = Fk:getCardById(id)
        local mark = player:getMark(self.name)
        if type(mark) == "table" then
          local pid
          for _, jy_record in ipairs(mark) do
            if #jy_record == 2 and jy_record[1] == id then
              pid = jy_record[2]
              break
            end
          end
          if pid ~= nil then
            local from = room:getPlayerById(pid)
            if from ~= nil and not from.dead then
              if not from:prohibitUse(card) and not from:isProhibited(player, card) then
                Self = from -- for targetFilter
                room:setPlayerMark(from, MarkEnum.BypassDistancesLimit, 1)
                room:setPlayerMark(from, MarkEnum.BypassTimesLimit, 1)
                local usecheak = card.skill:canUse(from, card) and
                (card.skill:getMinTargetNum() == 0 or card.skill:targetFilter(player.id, {}, {}, card))
                room:setPlayerMark(from, MarkEnum.BypassDistancesLimit, 0)
                room:setPlayerMark(from, MarkEnum.BypassTimesLimit, 0)

                local tos = {{player.id}}
                if usecheak and card.trueName == "collateral" then
                  usecheak = false
                  local targets = table.filter(room.alive_players, function (p)
                    return card.skill:targetFilter(p.id, {player.id}, {}, card)
                  end)
                  if #targets > 0 then
                    local to_slash = room:askForChoosePlayers(from, table.map(targets, function (p)
                      return p.id
                    end), 1, 1, "#collateral-choose::"..player.id..":"..card:toLogString(), "collateral_skill", false)
                    if #to_slash > 0 then
                      usecheak = true
                      table.insert(tos, to_slash)
                    end
                  end
                end

                if usecheak then
                  jy_remove = false
                  room:moveCards({
                    from = player.id,
                    ids = {id},
                    toArea = Card.Processing,
                    moveReason = fk.ReasonUse,
                    skillName = self.name,
                  })
                  room:useCard({
                    from = pid,
                    tos = tos,
                    card = card,
                    extra_data = {useByJueyong = true}
                  })
                end
              end
            end
          end
        end
        if jy_remove then
          room:moveCards({
            from = player.id,
            ids = {id},
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPutIntoDiscardPile,
            skillName = self.name,
          })
        end
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return type(player:getMark(self.name)) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local pile = player:getPile("jueyong_desperation")
    if #pile == 0 then
      room:setPlayerMark(player, self.name, 0)
      return false
    end
    local mark = player:getMark(self.name)
    local to_record = {}
    for _, jy_record in ipairs(mark) do
      if #jy_record == 2 and table.contains(pile, jy_record[1]) then
        table.insert(to_record, jy_record)
      end
    end
    room:setPlayerMark(player, self.name, to_record)
  end,
}

Fk:loadTranslationTable{
  ["jueyong"] = "绝勇",
  [":jueyong"] = "锁定技，当你成为一张非因〖绝勇〗使用的、非转化且非虚拟的牌（【桃】和【酒】除外）指定的目标时，若你是此牌的唯一目标，且此时“绝”的数量小于你的体力值，你取消之。然后将此牌置于你的武将牌上，称为“绝”。结束阶段，若你有“绝”，则按照置入顺序从前到后依次结算“绝”，令其原使用者对你使用（若此牌使用者不在场，则将此牌置入弃牌堆）。",

  ["jueyong_desperation"] = "绝",

  ["$jueyong1"] = "敌围何惧，有死而已！",
  ["$jueyong2"] = "身陷敌阵，战而弥勇！",
}

fuqian:addSkill(jueyong)

return extension
