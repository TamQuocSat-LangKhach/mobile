local extension = Package("mobile_sp")
extension.extensionName = "mobile"
Fk:loadTranslationTable{
  ["mobile_sp"] = "手杀专属",
  ["mobile"] = "手杀",
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

local lifeng = General(extension, "lifeng", "shu", 3)
local tunchu = fk.CreateTriggerSkill{
  name = "tunchu",
  anim_type = "drawcard",
  events = {fk.DrawNCards, fk.AfterDrawNCards},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.DrawNCards then
        return player:hasSkill(self.name) and #player:getPile("lifeng_liang") == 0
      else
        return player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and not player:isKongcheng()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      return player.room:askForSkillInvoke(player, self.name)
    else
      local cards = player.room:askForCard(player, 1, 999, false, self.name, true, ".", "#tunchu-put")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n + 2
    else
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(self.cost_data)
      player:addToPile("lifeng_liang", dummy, true, self.name)
    end
  end,
}
local tunchu_prohibit = fk.CreateProhibitSkill{
  name = "#tunchu_prohibit",
  prohibit_use = function(self, player, card)
    return player:hasSkill("tunchu") and #player:getPile("lifeng_liang") > 0 and card.trueName == "slash"
  end,
}
local shuliang = fk.CreateTriggerSkill{
  name = "shuliang",
  anim_type = "support",
  expand_pile = "lifeng_liang",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Finish and target:getHandcardNum() < target.hp and
    #player:getPile("lifeng_liang") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, false, self.name, true,
      ".|.|.|lifeng_liang|.|.", "#shuliang-invoke::"..target.id, "lifeng_liang")
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:moveCards({
      from = player.id,
      ids = self.cost_data,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = self.name,
      specialName = self.name,
    })
    if not target.dead then
      target:drawCards(2, self.name)
    end
  end,
}
tunchu:addRelatedSkill(tunchu_prohibit)
lifeng:addSkill(tunchu)
lifeng:addSkill(shuliang)
Fk:loadTranslationTable{
  ["lifeng"] = "李丰",
  ["tunchu"] = "屯储",
  [":tunchu"] = "摸牌阶段，若你没有“粮”，你可以多摸两张牌，然后可以将任意张手牌置于你的武将牌上，称为“粮”；若你的武将牌上有“粮”，你不能使用【杀】。",
  ["shuliang"] = "输粮",
  [":shuliang"] = "一名角色结束阶段，若其手牌数小于其体力值，你可以移去一张“粮”，然后该角色摸两张牌。",
  ["lifeng_liang"] = "粮",
  ["#tunchu-put"] = "屯储：你可以将任意张手牌置为“粮”",
  ["#shuliang-invoke"] = "输粮：你可以移去一张“粮”，令 %dest 摸两张牌",

  ["$tunchu1"] = "屯粮事大，暂不与尔等计较。",
  ["$tunchu2"] = "屯粮待战，莫动刀枪。",
  ["$shuliang1"] = "将军驰劳，酒肉慰劳。",
  ["$shuliang2"] = "将军，牌来了。",
  ["~lifeng"] = "吾，有负丞相重托。",
}

local zhaotongzhaoguang = General(extension, "zhaotongzhaoguang", "shu", 4)
local yizan = fk.CreateViewAsSkill{
  name = "yizan",
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, selected, selected_cards)
    if Self:usedSkillTimes("longyuan", Player.HistoryGame) > 0 then
      return "#yizan2"
    else
      return "#yizan1"
    end
  end,
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and not card.is_derived and
        ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    if #selected == 0 then
      return card.type == Card.TypeBasic
    elseif #selected == 1 then
      return Self:usedSkillTimes("longyuan", Player.HistoryGame) > 0 and false or true
    else
      return false
    end
  end,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    if Self:usedSkillTimes("longyuan", Player.HistoryGame) > 0 then
      if #cards ~= 1 then return end
    else
      if #cards ~= 2 then return end
    end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
}
local longyuan = fk.CreateTriggerSkill{
  name = "longyuan",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:usedSkillTimes("yizan", Player.HistoryGame) > 2
  end,
}
zhaotongzhaoguang:addSkill(yizan)
zhaotongzhaoguang:addSkill(longyuan)
Fk:loadTranslationTable{
  ["zhaotongzhaoguang"] = "赵统赵广",
  ["yizan"] = "翊赞",
  [":yizan"] = "你可以将两张牌（其中至少一张是基本牌）当任意基本牌使用或打出。",
  ["longyuan"] = "龙渊",
  [":longyuan"] = "觉醒技，准备阶段，若你本局游戏内发动过至少三次〖翊赞〗，你修改〖翊赞〗为只需一张牌。",
  ["#yizan1"] = "翊赞：你可以将两张牌（其中至少一张是基本牌）当任意基本牌使用或打出",
  ["#yizan2"] = "翊赞：你可以将一张基本牌当任意基本牌使用或打出",
}

local hujinding = General(extension, "hujinding", "shu", 2, 6, General.Female)
local renshi = fk.CreateTriggerSkill{
  name = "renshi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.every(data.card:isVirtual() and data.card.subcards or {data.card.id}, function(id)
      return room:getCardArea(id) == Card.Processing end) then
      room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    end
    room:changeMaxHp(player, -1)
    return true
  end,
}
local wuyuan = fk.CreateActiveSkill{
  name = "wuyuan",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:getCardById(effect.cards[1])
    room:obtainCard(target, card, false, fk.ReasonGive)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if not target.dead then
      if card.color == Card.Red and target:isWounded() then
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      local n = card.name ~= "slash" and 2 or 1
      target:drawCards(n, self.name)
    end
  end,
}
local huaizi = fk.CreateMaxCardsSkill{
  name = "huaizi",
  frequency = Skill.Compulsory,
  fixed_func = function(self, player)
    if player:hasSkill(self.name) then
      return player.maxHp
    end
  end
}
hujinding:addSkill(renshi)
hujinding:addSkill(wuyuan)
hujinding:addSkill(huaizi)
Fk:loadTranslationTable{
  ["hujinding"] = "胡金定",
  ["renshi"] = "仁释",
  [":renshi"] = "锁定技，当你受到【杀】造成的伤害时，若你已受伤，你防止此伤害，获得此【杀】并减1点体力上限。",
  ["wuyuan"] = "武缘",
  [":wuyuan"] = "出牌阶段限一次，你可以交给一名其他角色一张【杀】，然后你回复1点体力，其摸一张牌。若此【杀】为：红色【杀】，该角色额外回复1点体力；"..
  "非普通【杀】，该角色额外摸一张牌。",
  ["huaizi"] = "怀子",
  [":huaizi"] = "锁定技，你的手牌上限等于体力上限。",

  ["$renshi1"] = "巾帼于乱世，只能飘零如尘。",
  ["$renshi2"] = "还望您可以手下留情！",
  ["$wuyuan1"] = "夫君，此次出征，还望您记挂妾身！",
  ["$wuyuan2"] = "云长，一定要平安归来啊！",
  ["~hujinding"] = "云长，重逢不久，又要相别么……",
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
peixiu.subkingdom = "jin"
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
    player:broadcastSkillInvoke(self.name, player:getSwitchSkillState(self.name) + 1)
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
Fk:loadTranslationTable{
  ["mxing__zhiyan"] = "治严",
  [":mxing__zhiyan"] = "出牌阶段每项各限一次，你可以：1.将手牌摸至体力上限，然后你于此阶段内不能对其他角色使用牌；2.将多于体力值数量的手牌交给一名其他角色。",
  ["mxing__zhiyan_draw"] = "将手牌摸至体力上限",
  ["mxing__zhiyan_give"] = "交给其他角色多于体力值的牌",
  ["$mxing__zhiyan1"] = "治军严谨，方得精锐之师。",
  ["$mxing__zhiyan2"] = "精兵当严于律己，束身自修。",
}

local xingZhiyanProhibit = fk.CreateProhibitSkill{
  name = "#mxing__zhiyan_prohibit",
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
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "support")

      room:changeMaxHp(player, 1)
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    else
      player:broadcastSkillInvoke(self.name, 2)
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
wangjun.subkingdom = "jin"
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

  ["mobile__wangyuanji_win_audio"] = "胜利语音",
  ["$mobile__wangyuanji_win_audio"] = "苍生黎庶，都会有一个美好的未来了。",
}

local win = fk.CreateActiveSkill{ name = "mobile__wangyuanji_win_audio" }
win.package = extension
Fk:addSkill(win)

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


Fk:loadTranslationTable{
  ["$weimu_mobile__wangyuanji"] = "宫闱之内，何必擅涉外事！",
  ["$mingzhe_mobile__wangyuanji"] = "谦瑾行事，方能多吉少恙。",
}


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
      return Self:canUse(to_use) and not Self:prohibitUse(to_use)
    end)
    if #names > 0 then
      return UI.ComboBox {choices = names, all_choices = mark }
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
      player:broadcastSkillInvoke(self.name)
      local mark = player:getMark("@$zhiyi-turn")
      if type(mark) ~= "table" then return false end
      if table.every(mark, function (card_name)
        local to_use = Fk:cloneCard(card_name)
        return not (player:canUse(to_use) and not player:prohibitUse(to_use))
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
    room:drawCards(player, 3, "poxiang_draw")
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

  refresh_events = {fk.AfterCardsMove, fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == "poxiang_draw" then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
              room:setCardMark(Fk:getCardById(id), "@@poxiang-inhand", 1)
            end
          end
        end
      end
    elseif event == fk.AfterTurnEnd then
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        room:setCardMark(Fk:getCardById(id), "@@poxiang-inhand", 0)
      end
    end
  end,
}

local poxiang_maxcards = fk.CreateMaxCardsSkill{
  name = "#poxiang_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@poxiang-inhand") > 0
  end,
}

poxiang:addRelatedSkill(poxiang_refresh)
poxiang:addRelatedSkill(poxiang_maxcards)

Fk:loadTranslationTable{
  ["poxiang"] = "破降",
  [":poxiang"] = "出牌阶段限一次，你可以交给一名其他角色一张牌，然后你摸三张牌，移去所有“绝”并失去1点体力，你以此法获得的牌本回合不计入手牌上限。",
  ["#poxiang-active"] = "发动破降，选择一张牌交给一名角色，然后摸三张牌，移去所有绝并失去1点体力",
  ["@@poxiang-inhand"] = "破降",
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
              if from:canUse(card) and not from:prohibitUse(card) and not from:isProhibited(player, card) and
                  (card.skill:modTargetFilter(player.id, {}, pid, card, false)) then
                local tos = {{player.id}}
                if card.skill:getMinTargetNum() == 2 then
                  local targets = table.filter(room.alive_players, function (p)
                    return card.skill:targetFilter(p.id, {player.id}, {}, card)
                  end)
                  if #targets > 0 then
                    local to_slash = room:askForChoosePlayers(from, table.map(targets, function (p)
                      return p.id
                    end), 1, 1, "#jueyong-choose::"..player.id..":"..card:toLogString(), self.name, false)
                    if #to_slash > 0 then
                      table.insert(tos, to_slash)
                    end
                  end
                end

                if #tos >= card.skill:getMinTargetNum() then
                  jy_remove = false
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
  ["#jueyong-choose"] = "绝勇：选择对%dest使用的%arg的副目标",

  ["$jueyong1"] = "敌围何惧，有死而已！",
  ["$jueyong2"] = "身陷敌阵，战而弥勇！",
}

fuqian:addSkill(jueyong)

local zhouqun = General(extension, "zhouqun", "shu", 3)
local tiansuanProhibit = fk.CreateProhibitSkill{
  name = "#tiansuan_prohibit",
  is_prohibited = function() return false end,
  prohibit_use = function(self, player, card)
    return (card.trueName == "peach" or card.trueName == "analeptic")
      and player:getMark("@tiansuan") == "tiansuanC"
  end,
}
local tiansuanTrig = fk.CreateTriggerSkill{
  name = "#tiansuan_trig",
  events = { fk.DamageInflicted, fk.Damaged },
  on_cost = Util.TrueFunc,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return end
    if event == fk.DamageInflicted then
      return player:getMark("@tiansuan") ~= 0
    elseif event == fk.Damaged then
      return player:getMark("@tiansuan") == "tiansuanS"
    end
  end,
  on_use = function(self, event, target, player, data)
    -- local room = player.room
    if event == fk.Damaged then
      player:drawCards(data.damage, "tiansuan")
      return
    end

    local mark = player:getMark("@tiansuan")
    if mark == "tiansuanSSR" then
      return true
    elseif mark == "tiansuanS" then
      if data.damage > 1 then data.damage = 1 end
    elseif mark == "tiansuanA" then
      data.damageType = fk.FireDamage
      if data.damage > 1 then data.damage = 1 end
    elseif mark == "tiansuanB" or mark == "tiansuanC" then
      data.damage = data.damage + 1
    end
  end,

  refresh_events = { fk.TurnStart },
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("tiansuan") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "tiansuan", 0)
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@tiansuan") ~= 0 then
        room:setPlayerMark(p, "@tiansuan", 0)
      end
    end
  end
}
local tiansuan = fk.CreateActiveSkill{
  name = "tiansuan",
  card_filter = Util.FalseFunc,
  interaction = UI.ComboBox {
    choices = { "tiansuanNone", "tiansuanSSR", "tiansuanS", "tiansuanA", "tiansuanB", "tiansuanC" }
  },
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "tiansuan", 1)
    local choices = {
      "SSR", "SSR",
      "S", "S", "S",
      "A", "A", "A", "A",
      "B", "B", "B",
      "C", "C",
    }
    local dat = self.interaction.data
    if dat ~= "tiansuanNone" then
      table.insert(choices, dat:sub(9))
    end
    local result = "tiansuan" .. table.random(choices)
    room:doBroadcastNotify("ShowToast", Fk:translate("tiansuan_result") .. Fk:translate(result))

    local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper),
      1, 1, "#tiansuan-choose:::" .. result, self.name, false)
    local tgt = room:getPlayerById(tos[1])
    room:setPlayerMark(tgt, "@tiansuan", result)

    if tgt == player then return end
    if result == "tiansuanSSR" then
      if tgt:isKongcheng() then return end
      local cids = tgt.player_cards[Player.Hand]
      room:fillAG(player, cids)

      local id = room:askForAG(player, cids, false, self.name)
      room:closeAG(player)

      if not id then return false end
      room:obtainCard(player, id, false)
    elseif result == "tiansuanS" then
      if tgt:isNude() then return end
      local id = room:askForCardChosen(player, tgt, "he", self.name)
      room:obtainCard(player, id, false)
    end
  end,
}
tiansuan:addRelatedSkill(tiansuanProhibit)
tiansuan:addRelatedSkill(tiansuanTrig)
zhouqun:addSkill(tiansuan)
Fk:loadTranslationTable{
  ['zhouqun'] = '周群',
  ['tiansuan'] = '天算',
  ['#tiansuan_trig'] = '天算',
  [':tiansuan'] = '每轮限一次，出牌阶段，你可以抽取一个“命运签”' ..
    '（在抽签开始前，你可以悄悄作弊，额外放入一个“命运签”增加其抽中的机会）。' ..
    '<br/>然后你选择一名角色，其获得命运签的效果直到你的下回合开始。' ..
    '<br/>若其获得的是“上上签”，你观看其手牌并从其区域内获得一张牌；' ..
    '若其获得的是“上签”，你从其处获得一张牌。' ..
    '<br/>各种“命运签”的效果如下：' ..
    '<br/>上上签：防止受到的伤害。' ..
    '<br/>上签：受到伤害时，若伤害值大于1，则将伤害值改为1；每受到一点伤害后，你摸一张牌。' ..
    '<br/>中签：受到伤害时，将伤害改为火焰伤害，若此伤害值大于1，则将伤害值改为1。' ..
    '<br/>下签：受到伤害时，伤害值+1。' ..
    '<br/>下下签：受到伤害时，伤害值+1；不能使用【桃】和【酒】。 ',
  ['tiansuanNone'] = '我足够会玩了，不需要作弊',
  ['tiansuanSSR'] = '上上签',
  ['tiansuanS'] = '上签',
  ['tiansuanA'] = '中签',
  ['tiansuanB'] = '下签',
  ['tiansuanC'] = '下下签',
  ['tiansuan_result'] = '天算的抽签结果是：',
  ['@tiansuan'] = '天算',
  ['#tiansuan-choose'] = '天算：抽签结果是 %arg ，请选择一名角色获得签的效果',

  ['$tiansuan1'] = '汝既持签问卜，亦当应天授命。',
  ['$tiansuan2'] = '尔若居正体道，福寿自当天成。',
  ['~zhouqun'] = '及时止损，过犹不及…',
}

local simafu = General(extension, "simafu", "wei", 3)
simafu.subkingdom = "jin"
local xunde = fk.CreateTriggerSkill{
  name = "xunde",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:distanceTo(target) <= 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xunde-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
      skipDrop = true,
    }
    room:judge(judge)
    if data.card.number >= 6 and target ~= player and not target.dead and room:getCardArea(data.card:getEffectiveId()) == Card.Processing then
      room:doIndicate(player.id, {target.id})
      room:obtainCard(target, data.card, true, fk.ReasonJustMove)
    elseif data.card.number <= 6 and data.from and not data.from.dead and not data.from:isKongcheng() then
      room:doIndicate(player.id, {data.from.id})
      room:askForDiscard(data.from, 1, 1, false, self.name, false)
    end
  end,
}
local chenjie = fk.CreateTriggerSkill{
  name = "chenjie",
  anim_type = "drawcard",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForResponse(player, "", ".|.|"..data.card:getSuitString(),
      "#chenjie-invoke::"..target.id..":"..data.card:getSuitString(), true)
    if card then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(self.cost_data, player, data, self.name, false)
    player:drawCards(2, self.name)
  end,
}
simafu:addSkill(xunde)
simafu:addSkill(chenjie)
Fk:loadTranslationTable{
  ["simafu"] = "司马孚",
  ["xunde"] = "勋德",
  [":xunde"] = "当一名角色受到伤害后，若你与其距离1以内，你可进行一次判定，若点数不小于6且该角色不为你，则你令该角色获得此判定牌；"..
  "若点数不大于6，你令伤害来源弃置一张手牌。",
  ["chenjie"] = "臣节",
  [":chenjie"] = "当一名角色的判定牌生效前，你可以打出一张与判定牌相同花色的牌代替之，然后你摸两张牌。",
  ["#xunde-invoke"] = "勋德：%dest 受到伤害，你可以判定，根据点数执行效果",
  ["#chenjie-invoke"] = "臣节：你可以打出一张%arg牌修改 %dest 的判定并摸两张牌",

  ["$xunde1"] = "陛下所托，臣必尽心尽力！",
  ["$xunde2"] = "纵吾荏弱难持，亦不推诿君命！",
  ["$chenjie1"] = "臣心怀二心，不可事君也。",
  ["$chenjie2"] = "竭力致身，以尽臣节。",
  ["~simafu"] = "身辅六公，亦难报此恩……",
}

local yangfu = General(extension, "yangfu", "wei", 4)
local jiebing = fk.CreateTriggerSkill{
  name = "jiebing",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (not data.from or
      table.find(player.room:getOtherPlayers(player), function(p) return p ~= data.from and not p:isNude() end))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() and (not data.from or p ~= data.from) end), function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#jiebing-choose", self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    local ids = table.random(room:getPlayerById(to):getCardIds("he"), 2)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(ids)
    room:obtainCard(player, dummy, false, fk.ReasonPrey)
    ids = table.filter(ids, function(id) return room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand end)
    if #ids == 0 then return end
    player:showCards(ids)
    if player.dead then return end
    for _, id in ipairs(ids) do
      if room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand and
        Fk:getCardById(id).type == Card.TypeEquip and not player:isProhibited(player, Fk:getCardById(id)) then
        room:useCard({
          from = player.id,
          tos = {{player.id}},
          card = Fk:getCardById(id),
        })
      end
    end
  end,
}
local hannan = fk.CreateActiveSkill{
  name = "hannan",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#hannan",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    local from, to
    if pindian.results[target.id].winner == player then
      from, to = player, target
    elseif pindian.results[target.id].winner == target then
      from, to = target, player
    end
    if to and not to.dead then
      room:damage{
        from = from,
        to = to,
        damage = 2,
        skillName = self.name,
      }
    end
  end,
}
yangfu:addSkill(jiebing)
yangfu:addSkill(hannan)
Fk:loadTranslationTable{
  ["yangfu"] = "杨阜",
  ["jiebing"] = "借兵",
  [":jiebing"] = "锁定技，当你受到伤害后，你选择除伤害来源外的一名其他角色，随机获得其两张牌并展示之，若为装备牌则你使用之。",
  ["hannan"] = "扞难",
  [":hannan"] = "出牌阶段限一次，你可以与一名其他角色拼点，拼点赢的角色对没赢的角色造成2点伤害。",
  ["#jiebing-choose"] = "借兵：选择一名角色，随机获得其两张牌",
  ["#hannan"] = "扞难：你可以拼点，赢的角色对没赢的角色造成2点伤害！",

  ["$jiebing1"] = "敌寇势大，情况危急，只能多谢阁下。",
  ["$jiebing2"] = "将军借兵之恩，阜退敌后自当报还。",
  ["$hannan1"] = "贼寇虽勇，阜亦戮力以捍！",
  ["$hannan2"] = "纵使信布之勇，亦非无策可当！",
  ["~yangfu"] = "汝背父叛君，吾誓，杀……",
}

local qianzhao = General(extension, "qianzhao", "wei", 4)
local shihe = fk.CreateActiveSkill{
  name = "shihe",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#shihe",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      if target.dead then return end
      local mark = target:getMark("@@shihe")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, player.id)
      room:setPlayerMark(target, "@@shihe", mark)
    elseif not player.dead and not player:isNude() then
      local id = table.random(player:getCardIds("he"))
      room:throwCard({id}, self.name, player, player)
    end
  end,
}
local shihe_trigger = fk.CreateTriggerSkill{
  name = "#shihe_trigger",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target and target:getMark("@@shihe") ~= 0 and data.to == player and table.contains(target:getMark("@@shihe"), player.id)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("shihe")
    room:notifySkillInvoked(player, "shihe", "defensive")
    return true
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@shihe") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@shihe", 0)
  end,
}
local zhenfu = fk.CreateTriggerSkill{
  name = "zhenfu",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and target:hasSkill(self.name) and player.phase == Player.Finish then
      local events = player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            return true
          end
        end
      end, Player.HistoryTurn)
      return #events > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, "#zhenfu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeShield(room:getPlayerById(self.cost_data), 1)
  end,
}
shihe:addRelatedSkill(shihe_trigger)
qianzhao:addSkill(shihe)
qianzhao:addSkill(zhenfu)
Fk:loadTranslationTable{
  ["qianzhao"] = "牵招",
  ["shihe"] = "势吓",
  [":shihe"] = "出牌阶段限一次，你可以与一名其他角色拼点，若你赢，直到其下回合结束防止其对你造成的伤害；没赢，你随机弃置一张牌。",
  ["zhenfu"] = "镇抚",
  [":zhenfu"] = "结束阶段，若你本回合因弃置失去过牌，你可以令一名其他角色获得1点护甲。",
  ["#shihe"] = "势吓：你可以拼点，若赢，防止其对你造成伤害；若没赢，你随机弃置一张牌",
  ["@@shihe"] = "势吓",
  ["#zhenfu-choose"] = "镇抚：你可以令一名其他角色获得1点护甲",
}

Fk:loadTranslationTable{
  ["ruanhui"] = "阮慧",
  ["mingcha"] = "明察",
  [":mingcha"] = "摸牌阶段开始时，你亮出牌堆顶三张牌，然后你可以放弃摸牌并获得其中点数不大于8的牌，若如此做，你可以选择一名其他角色，随机获得其一张牌。",
  ["jingzhong"] = "敬重",
  [":jingzhong"] = "弃牌阶段结束时，若你本阶段弃置过至少两张黑色牌，你可以选择一名其他角色；其下回合出牌阶段限三次，当其使用牌结算后，你获得之。",
}

local caosong = General(extension, "mobile__caosong", "wei", 3)
local yijin = fk.CreateTriggerSkill{
  name = "yijin",
  frequency = Skill.Compulsory,
  anim_type = "special",
  events = {fk.GameStart, fk.TurnStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      elseif event == fk.TurnStart then
        return target == player and (player:getMark(self.name) == 0 or #player:getMark(self.name) == 0)
      else
        return target == player and player.phase == Player.Play and player:getMark(self.name) ~= 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local mark = {}
      for i = 1, 6, 1 do
        table.insert(mark, "wd_gold")
      end
      room:setPlayerMark(player, "@$yijin", mark)
      room:setPlayerMark(player, self.name,
        {"@@yijin_wushi", "@@yijin_houren", "@@yijin_guxiong", "@@yijin_yongbi", "@@yijin_tongshen", "@@yijin_jinmi"})
    elseif event == fk.TurnStart then
      room:killPlayer({who = player.id})
    else
      room:askForUseActiveSkill(player, "yijin_active", "#yijin-choose", false, nil, false)
    end
  end,
}
local yijin_active = fk.CreateActiveSkill{
  name = "yijin_active",
  mute = true,
  card_num = 0,
  target_num = 1,
  interaction = function()
    if Self:getMark("yijin") ~= 0 then
      return UI.ComboBox {choices = Self:getMark("yijin")}
    end
  end,
  prompt = function (self)
    return "#"..self.interaction.data
  end,
  card_filter = function(self, to_select, selected, targets)
    return false
  end,
  target_filter = function(self, to_select, selected, cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      for name, _ in pairs(target.mark) do
        if name:startsWith("@@yijin_") then
          return false
        end
      end
      return true
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = player:getMark("@$yijin")
    if #mark == 1 then
      mark = 0
    else
      table.remove(mark, 1)
    end
    room:setPlayerMark(player, "@$yijin", mark)
    mark = player:getMark("yijin")
    if #mark == 1 then
      mark = 0
    else
      table.removeOne(mark, self.interaction.data)
    end
    room:setPlayerMark(player, "yijin", mark)
    room:setPlayerMark(target, self.interaction.data, 1)
  end,
}
local yijin_trigger = fk.CreateTriggerSkill{
  name = "#yijin_trigger",
  mute = true,
  events = {fk.DrawNCards, fk.EventPhaseChanging, fk.EventPhaseStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.DrawNCards then
        return player:getMark("@@yijin_wushi") > 0
      elseif event == fk.EventPhaseChanging then
        return (data.to == Player.NotActive and player:getMark("@@yijin_houren") > 0) or
          (data.to == Player.Draw and player:getMark("@@yijin_yongbi") > 0) or
          ((data.to == Player.Play or data.to == Player.Discard) and player:getMark("@@yijin_jinmi") > 0)
      elseif event == fk.EventPhaseStart then
        return player.phase == Player.Play and player:getMark("@@yijin_guxiong") > 0
      elseif event == fk.DamageInflicted then
        return data.damageType ~= fk.NormalDamage and player:getMark("@@yijin_tongshen") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DrawNCards then
      data.n = data.n + 4
    elseif event == fk.EventPhaseChanging then
      if player:getMark("@@yijin_houren") > 0 then
        if player:isWounded() then
          room:recover({
            who = player,
            num = math.min(3, player:getLostHp()),
            recoverBy = player,
            skillName = "yijin",
          })
        end
      else
        return true
      end
    elseif event == fk.EventPhaseStart then
      room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 3)
      room:loseHp(player, 1, "yijin")
    elseif event == fk.DamageInflicted then
      return true
    end
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    for name, _ in pairs(target.mark) do
      if name:startsWith("@@yijin_") then
        player.room:setPlayerMark(player, name, 0)
      end
    end
  end,
}
local yijin_targetmod = fk.CreateTargetModSkill{
  name = "#yijin_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@yijin_wushi") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
local guanzong = fk.CreateActiveSkill{
  name = "guanzong",
  anim_type = "special",
  card_num = 0,
  target_num = 2,
  prompt = "#guanzong",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected < 2 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local logic = room.logic
    local damageStruct = {
      from = room:getPlayerById(effect.tos[1]),
      to = room:getPlayerById(effect.tos[2]),
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
      local event, player = table.unpack(struct)
      if logic:trigger(event, player, damageStruct) or damageStruct.damage < 1 then
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
      local event, player = table.unpack(struct)
      logic:trigger(event, player, damageStruct)
    end

    logic:trigger(fk.DamageFinished, damageStruct.to, damageStruct)
  end,
}
Fk:addSkill(yijin_active)
yijin:addRelatedSkill(yijin_trigger)
yijin:addRelatedSkill(yijin_targetmod)
caosong:addSkill(yijin)
caosong:addSkill(guanzong)
Fk:loadTranslationTable{
  ["mobile__caosong"] = "曹嵩",
  ["yijin"] = "亿金",
  [":yijin"] = "锁定技，游戏开始时，你获得6枚“金”标记；回合开始时，若你没有“金”，你死亡。出牌阶段开始时，你令一名没有“金”的其他角色获得一枚“金”和"..
  "对应的效果直到其下回合结束：<br>膴士：摸牌阶段摸牌数+4、出牌阶段使用【杀】次数上限+1；<br>厚任：回合结束时回复3点体力；<br>"..
  "贾凶：出牌阶段开始时失去1点体力，本回合手牌上限-3；<br>拥蔽：跳过摸牌阶段；<br>通神：防止受到的非雷电伤害；<br>金迷：跳过出牌阶段和弃牌阶段。",
  ["guanzong"] = "惯纵",
  [":guanzong"] = "出牌阶段限一次，你可以令一名其他角色<font color='red'>视为</font>对另一名其他角色造成1点伤害。",
  ["yijin_active"] = "亿金",
  ["#yijin-choose"] = "亿金：将一种“金”交给一名其他角色",
  ["@$yijin"] = "金",
  ["@@yijin_wushi"] = "膴士",
  ["#@@yijin_wushi"] = "膴士：摸牌阶段摸牌数+4、出牌阶段使用【杀】次数+1",
  ["@@yijin_houren"] = "厚任",
  ["#@@yijin_houren"] = "厚任：回合结束时回复3点体力",
  ["@@yijin_guxiong"] = "贾凶",
  ["#@@yijin_guxiong"] = "贾凶：出牌阶段开始时失去1点体力，手牌上限-3",
  ["@@yijin_yongbi"] = "拥蔽",
  ["#@@yijin_yongbi"] = "拥蔽：跳过摸牌阶段",
  ["@@yijin_tongshen"] = "通神",
  ["#@@yijin_tongshen"] = "通神：防止受到的非雷电伤害",
  ["@@yijin_jinmi"] = "金迷",
  ["#@@yijin_jinmi"] = "金迷：跳过出牌阶段和弃牌阶段",
  ["#guanzong"] = "惯纵：选择两名角色，<font color='red'>视为</font>第一名角色对第二名角色造成1点伤害",
}

local gongsunkang = General(extension, "gongsunkang", "qun", 4)
local juliao = fk.CreateDistanceSkill{
  name = "juliao",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if to:hasSkill(self.name) then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms - 1
    end
    return 0
  end,
}
local taomie = fk.CreateTriggerSkill{
  name = "taomie",
  anim_type = "offensive",
  events = {fk.Damage, fk.Damaged, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.DamageCaused then
        return data.to:getMark("@@taomie") > 0
      elseif event == fk.Damage then
        return not data.to.dead and data.to:getMark("@@taomie") == 0
      elseif event == fk.Damaged then
        return data.from and not data.from.dead and data.to:getMark("@@taomie") == 0 and not data.taomie
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      return true
    else
      local prompt
      if event == fk.Damage then
        prompt = "#taomie-invoke::"..data.to.id
      else
        prompt = "#taomie-invoke::"..data.from.id
      end
      return player.room:askForSkillInvoke(player, self.name, nil, prompt)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      local all_choices = {"taomie_damage", "taomie_prey", "taomie_beishui"}
      local choices = table.clone(all_choices)
      if data.to:isNude() then
        choices = {"taomie_damage"}
      end
      local choice = room:askForChoice(player, choices, self.name, nil, false, all_choices)
      if choice ~= "taomie_prey" then
        data.damage = data.damage + 1
      end
      if choice ~= "taomie_damage" then
        if choice == "taomie_beishui" then
          room:setPlayerMark(data.to, "@@taomie", 0)
          data.taomie = true
        end
        if data.to:isNude() then return end
        room:doIndicate(player.id, {data.to.id})
        local id = room:askForCardChosen(player, data.to, "hej", self.name)
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
        if player.dead then return end
        local targets = table.map(room:getOtherPlayers(data.to), function(p) return p.id end)
        if #targets == 0 or room:getCardOwner(id) ~= player or room:getCardArea(id) ~= Card.PlayerHand then return end
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#taomie-choose:::"..Fk:getCardById(id):toLogString(), self.name, true)
        if #to > 0 then
          to = to[1]
        else
          to = player.id
        end
        if to ~= player.id then
          room:obtainCard(to, id, false, fk.ReasonGive)
        end
      end
    else
      for _, p in ipairs(room.alive_players) do
        room:setPlayerMark(p, "@@taomie", 0)
      end
      if event == fk.Damage then
        room:doIndicate(player.id, {data.to.id})
        room:setPlayerMark(data.to, "@@taomie", 1)
      else
        room:doIndicate(player.id, {data.from.id})
        room:setPlayerMark(data.from, "@@taomie", 1)
      end
    end
  end
}
local taomie_attackrange = fk.CreateAttackRangeSkill{
  name = "#taomie_attackrange",
  main_skill = taomie,
  within_func = function (self, from, to)
    if from:hasSkill("taomie") then
      return to:getMark("@@taomie") > 0
    end
    if to:hasSkill("taomie") then
      return from:getMark("@@taomie") > 0
    end
  end,
}
taomie:addRelatedSkill(taomie_attackrange)
gongsunkang:addSkill(juliao)
gongsunkang:addSkill(taomie)
Fk:loadTranslationTable{
  ["gongsunkang"] = "公孙康",
  ["juliao"] = "据辽",
  [":juliao"] = "锁定技，其他角色计算与你的距离+X（X为场上势力数-1）。",
  ["taomie"] = "讨灭",
  [":taomie"] = "当你受到伤害后或当你造成伤害后，你可以令伤害来源或受伤角色获得“讨灭”标记（如场上已有标记则转移给该角色），"..
  "你和拥有“讨灭”标记的角色互相视为在对方的攻击范围内；当你对有“讨灭”标记的角色造成伤害时，你选择一项：1.令此伤害+1；"..
  "2.你获得其区域里的一张牌并可将此牌交给另一名角色；背水：弃置其“讨灭”标记，本次伤害不令其获得“讨灭”标记。",
  ["#taomie-invoke"] = "讨灭：是否令 %dest 获得“讨灭”标记？",
  ["@@taomie"] = "讨灭",
  ["taomie_damage"] = "此伤害+1",
  ["taomie_prey"] = "获得其区域内一张牌，且可以交给另一名角色",
  ["taomie_beishui"] = "背水：弃置其“讨灭”标记，且本次伤害不令其获得标记",
  ["#taomie-choose"] = "讨灭：你可以将此%arg交给另一名角色",
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
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
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

local guonvwang = General(extension, "mobile__guozhao", "wei", 3, 3, General.Female)

local yichong = fk.CreateTriggerSkill{
  name = "yichong",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.EventPhaseStart then
      return target == player and player.phase == Player.Start
    elseif event == fk.AfterCardsMove then
      local mark = player:getMark("@yichong")
      if type(mark) ~= "table" or mark[1] > 4 then return false end
      mark = player:getMark("yichong_target")
      if type(mark) ~= "table" then return false end
      local room = player.room
      local to = room:getPlayerById(mark[1])
      if to == nil or to.dead then return false end
      for _, move in ipairs(data) do
        if move.to == mark[1] and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == to and
            Fk:getCardById(id):getSuitString(true) == mark[2] then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
        return p.id end), 1, 1, "#yichong-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    elseif event == fk.AfterCardsMove then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:getPlayerById(self.cost_data)
      local suits = {"log_spade", "log_club", "log_heart", "log_diamond"}
      local choice = room:askForChoice(player, suits, self.name)
      local cards = table.filter(to:getCardIds({Player.Hand, Player.Equip}), function (id)
        return Fk:getCardById(id):getSuitString(true) == choice
      end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      end
      if not (player.dead or to.dead) then
        local mark = player:getMark("yichong_target")
        if type(mark) == "table" then
          local orig_to = room:getPlayerById(mark[1])
          local mark2 = orig_to:getMark("@yichong_que")
          if type(mark2) == "table" then
            table.removeOne(mark2, mark[2])
            room:setPlayerMark(orig_to, "@yichong_que", #mark2 > 0 and mark2 or 0)
          end
        end
        local mark2 = type(to:getMark("@yichong_que")) == "table" and to:getMark("@yichong_que") or {}
        table.insert(mark2, choice)
        room:setPlayerMark(to, "@yichong_que", mark2)
        room:setPlayerMark(player, "yichong_target", {self.cost_data, choice})
        room:setPlayerMark(player, "@yichong", {0})
      end
    else
      local mark = player:getMark("@yichong")
      if type(mark) ~= "table" or mark[1] > 4 then return false end
      local x = 5 - mark[1]
      mark = player:getMark("yichong_target")
      if type(mark) ~= "table" then return false end
      local to = room:getPlayerById(mark[1])
      if to == nil or to.dead then return false end
      local cards = {}
      for _, move in ipairs(data) do
        if move.to == mark[1] and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == to and
                Fk:getCardById(id):getSuitString(true) == mark[2] then
              table.insert(cards, id)
            end
          end
        end
      end
      if #cards == 0 then
        return false
      elseif #cards > x then
        cards = table.random(cards, x)
      end
      room:setPlayerMark(player, "@yichong", {5-x+#cards})
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    end
  end,

  refresh_events = {fk.TurnStart, fk.EventLoseSkill, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventLoseSkill and data ~= self then return false end
    return player == target and type(player:getMark("yichong_target")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("yichong_target")
    local to = room:getPlayerById(mark[1])
    local mark2 = to:getMark("@yichong_que")
    if type(mark2) == "table" then
      table.removeOne(mark2, mark[2])
      room:setPlayerMark(to, "@yichong_que", #mark2 > 0 and mark2 or 0)
    end
    room:setPlayerMark(player, "yichong_target", 0)
    room:setPlayerMark(player, "@yichong", 0)
  end,
}

local wufei = fk.CreateTriggerSkill{
  name = "wufei",
  events = {fk.TargetSpecified, fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) or player ~= target then return false end
    local mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end
    local to = player.room:getPlayerById(mark[1])
    if to == nil or to.dead then return false end
    if event == fk.TargetSpecified then
      return data.firstTarget and (data.card.trueName == "slash" or (data.card:isCommonTrick() and data.card.is_damage_card))
    elseif event == fk.Damaged then
      return to.hp > player.hp and to.hp > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      return true
    end
    local mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#wufei-invoke::"..mark[1]) then
      room:doIndicate(player.id, {mark[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end
    local to = player.room:getPlayerById(mark[1])
    if to == nil or to.dead then return false end
    player:broadcastSkillInvoke(self.name)
    if event == fk.TargetSpecified then
      player.room:notifySkillInvoked(player, self.name, "control")
      data.extra_data = data.extra_data or {}
      data.extra_data.wufei = mark[1]
    else
      player.room:notifySkillInvoked(player, self.name, "masochism")
      player.room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
    end
  end,

  refresh_events = {fk.PreDamage},
  can_refresh = function(self, event, target, player, data)
    if data.card then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return use.extra_data and use.extra_data.wufei
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data[1]
      data.from = room:getPlayerById(use.extra_data.wufei)
    end
  end,
}

guonvwang:addSkill(yichong)
guonvwang:addSkill(wufei)

Fk:loadTranslationTable{
  ["mobile__guozhao"] = "郭女王",
  ["yichong"] = "易宠",
  [":yichong"] = "准备阶段，你可以选择一名其他角色并指定一种花色，获得其所有该花色的牌，并令其获得“雀”标记直到你下个回合开始"..
  "（若场上已有“雀”标记则转移给该角色）。拥有“雀”标记的角色获得你指定花色的牌时，你获得此牌（你至多因此“雀”标记获得五张牌）。",
  ["wufei"] = "诬诽",
  [":wufei"] = "你使用【杀】或伤害类普通锦囊指定目标后，令拥有“雀”标记的其他角色代替你成为伤害来源。"..
  "你受到伤害后，若拥有“雀”标记的角色体力值大于1且大于你，你可以令其受到1点伤害。",

  ["#yichong-choose"] = "你可以发动 易宠，选择一名其他角色，获得其一种花色的所有牌",
  ["@yichong_que"] = "雀",
  ["@yichong"] = "易宠",
  ["#wufei-invoke"] = "你可发动 诬诽，令%dest受到1点伤害",

  ["$yichong1"] = "处椒房之尊，得陛下隆宠！",
  ["$yichong2"] = "三千宠爱？当聚于我一身！",
  ["$wufei1"] = "巫蛊实乃凶邪之术，陛下不可不察！",
  ["$wufei2"] = "妾不该多言，只怕陛下为其所害。",
  ["~mobile__guozhao"] = "不觉泪下……沾衣裳……",
}

local mobile__sufei = General(extension, "mobile__sufei", "wu", 4)
local zhengjian = fk.CreateTriggerSkill{
  name = "zhengjian",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Finish and table.find(player.room.alive_players, function(p) return type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0 end)
      else
        return table.find(player.room.alive_players, function(p) return not (type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0) end)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local targets = table.filter(player.room.alive_players, function(p) return type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0 end)
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#zhengjian-choose", self.name, false)
      local to = room:getPlayerById(tos[1])
      room:setPlayerMark(to, "@zhengjian", "0")
    else
      for _, p in ipairs(room.alive_players) do
        local mark = type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") or 0
        room:setPlayerMark(p, "@zhengjian", 0)
        if mark > 0 then
          local x = math.min(mark, p.maxHp, 5)
          p:drawCards(x, self.name)
        end
      end
    end
  end,
  refresh_events = {fk.CardUsing, fk.CardResponding, fk.Deathed},
  can_refresh = function (self, event, target, player, data)
    if event == fk.Deathed then
      return not table.find(player.room.alive_players, function(p) return p:hasSkill(self.name,true) end)
    else
      return target == player and not (type(player:getMark("@zhengjian")) == "number" and player:getMark("@zhengjian") == 0)
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.Deathed then
      for _, p in ipairs(room.alive_players) do
        room:setPlayerMark(p, "@zhengjian", 0)
      end
    else
      local mark = type(player:getMark("@zhengjian")) == "number" and player:getMark("@zhengjian") or 0
      room:setPlayerMark(player, "@zhengjian", math.min(5,mark+1))
    end
  end,
}
mobile__sufei:addSkill(zhengjian)
local gaoyuan = fk.CreateTriggerSkill{
  name = "gaoyuan",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if target == player and player:hasSkill(self.name) and data.card.trueName == "slash" then
      return table.find(room:getOtherPlayers(player), function (p)
        return p.id ~= data.from and not room:getPlayerById(data.from):isProhibited(p, data.card) and not (type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0)
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function (p)
      return p.id ~= data.from and not room:getPlayerById(data.from):isProhibited(p, data.card) and not (type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0)
    end)
    if #targets == 0 then
      return false
    elseif #targets == 1 then
      local card = room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#gaoyuan-invoke:"..targets[1].id)
      if #card > 0 then
        self.cost_data = {targets[1].id, card[1]}
        return true
      end
    else
      local tos, cid = room:askForChooseCardAndPlayers(player, targets, 1, 1, nil, "#gaoyuan-choose", self.name, true, true)
      if #tos > 0 then
        self.cost_data = {tos[1], cid}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = self.cost_data[1]
    room:doIndicate(player.id, { to })
    room:throwCard(self.cost_data[2], self.name, player, player)
    TargetGroup:removeTarget(data.targetGroup, player.id)
    TargetGroup:pushTargets(data.targetGroup, to)
  end,
}
mobile__sufei:addSkill(gaoyuan)
Fk:loadTranslationTable{
  ["mobile__sufei"] = "苏飞",
  ["zhengjian"] = "诤荐",
  [":zhengjian"] = "锁定技，结束阶段，你令一名角色获得“诤荐”标记，然后其于你的下个回合开始时摸X张牌并移去“诤荐”标记（X为其此期间使用或打出牌的数量且至多为其体力上限且至多为5）。",
  ["@zhengjian"] = "诤荐",
  ["#zhengjian-choose"] = "选择“诤荐”的目标",
  ["gaoyuan"] = "告援",
  [":gaoyuan"] = "当你成为一名角色使用【杀】的目标时，你可以弃置一张牌，将此【杀】转移给另一名有“诤荐”标记的其他角色。",
  ["#gaoyuan-choose"] = "告援：你可以弃置一张牌，将此【杀】转移给一名有“诤荐”标记的其他角色",
  ["#gaoyuan-invoke"] = "告援：你可以弃置一张牌，将此【杀】转移给%src",


  ["$zhengjian1"] = "此人有雄猛逸才，还请明公观之。",
  ["$zhengjian2"] = "若明公得此人才，定当如虎添翼。",
  ["$gaoyuan1"] = "烦请告知兴霸，请他务必相助。",
  ["$gaoyuan2"] = "如今事急，唯有兴霸可救。",
  ["~mobile__sufei"] = "本可共图大业，奈何主公量狭器小啊……",
}

return extension
