local extension = Package("mobile_sp")
extension.extensionName = "mobile"
Fk:loadTranslationTable{
  ["mobile_sp"] = "手杀专属",
  ["mxing"] = "手杀星",
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
  ["$xing__yishi1"] = "诱敌之计已成，吾且拈弓搭箭！",
  ["$xing__yishi2"] = "关羽即至吊桥，既已控弦，如何是好？",
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

local duyu = General(extension, "mobile__duyu", "qun", 4)
Fk:loadTranslationTable{
  ["mobile__duyu"] = "杜预",
  ["~mobile__duyu"] = "洛水圆石，遂道向南，吾将以俭自完耳……",
}

local wuku = fk.CreateTriggerSkill{
  name = "wuku",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:getMark("@wuku") < 3 and data.card.type == Card.TypeEquip
  end,
  on_use = function(self, event, target, player)
    player.room:addPlayerMark(player, "@wuku")
  end,
}

Fk:loadTranslationTable{
  ["wuku"] = "武库",
  [":wuku"] = "锁定技，当一名角色使用装备时，你获得1个“武库”标记。（“武库”数量至多为3）",
  ["@wuku"] = "武库",
  ["$wuku1"] = "损益万枢，竭世运机。",
  ["$wuku2"] = "胸藏万卷，充盈如库。",
}

duyu:addSkill(wuku)

local mobile__sanchen = fk.CreateTriggerSkill{
  name = "mobile__sanchen",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@wuku") == 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() then
      room:recover{ who = player, num = 1, skillName = self.name }
    end
    room:handleAddLoseSkills(player, "miewu", nil)
  end,
}

Fk:loadTranslationTable{
  ["mobile__sanchen"] = "三陈",
  [":mobile__sanchen"] = "觉醒技，结束阶段，若你已有3个“武库”，你增加一点体力上限，回复一点体力，然后获得技能〖灭吴〗。",
  ["$mobile__sanchen1"] = "贼计已穷，陈兵吴地，可一鼓而下也。",
  ["$mobile__sanchen2"] = "伐吴此举，十有九利，惟陛下察之。",
}

duyu:addSkill(mobile__sanchen)

local miewu = fk.CreateViewAsSkill{
  name = "miewu",
  pattern = ".",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeBasic or card.type == Card.TypeTrick) and not card.is_derived then
        local to_use = Fk:cloneCard(card.name)
        if ((Fk.currentResponsePattern == nil and card.skill.canUse(card.skill, Self, to_use) and not Self:prohibitUse(to_use)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names }
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:removePlayerMark(player, "@wuku")
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@wuku") > 0 and player:usedSkillTimes(self.name) == 0
  end,
  enabled_at_response = function(self, player, response)
    return player:getMark("@wuku") > 0 and player:usedSkillTimes(self.name) == 0
  end,
}

local miewu_delay = fk.CreateTriggerSkill{
  name = "#miewu_delay",
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player == target and table.contains(data.card.skillNames, miewu.name)
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, miewu.name)
  end,
}

miewu:addRelatedSkill(miewu_delay)

Fk:loadTranslationTable{
  ["miewu"] = "灭吴",
  ["#miewu_delay"] = "灭吴",
  [":miewu"] = "每回合限一次，你可以弃置1个“武库”，将一张牌当做任意一张基本牌或锦囊牌使用或打出；若如此做，你摸一张牌。",
  ["$miewu1"] = "倾荡之势已成，石城尽在眼下",
  ["$miewu2"] = "吾军势如破竹，江东六郡唾手可得。",
}

duyu:addRelatedSkill(miewu)

return extension
