local extension = Package("mobile_rare")
extension.extensionName = "mobile"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["mobile_rare"] = "手杀-稀有专属",
  ["mobile"] = "手杀",
  ["mxing"] = "手杀星",
}

--袖里乾坤：孙茹 凌操 留赞 祢衡 曹纯 庞德公 马钧 郑玄 十常侍
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
  ["#sunru"] = "出水青莲",
  ["illustrator:sunru"] = "撒呀酱",
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
  ["#lingcao"] = "激流勇进",
  ["illustrator:lingcao"] = "樱花闪乱",
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
  ["#liuzan"] = "啸天亢声",
  ["cv:liuzan"] = "腾格尔",
  ["designer:liuzan"] = "东郊易尘Noah",
  ["illustrator:liuzan"] = "酸包", -- 传说皮 灵魂歌王

  ["fenyin"] = "奋音",
  [":fenyin"] = "你的回合内，当你使用和上一张牌颜色不同的牌时，你可以摸一张牌。",
  ["@fenyin"] = "奋音",

  ["$fenyin1"] = "吾军杀声震天，则敌心必乱！",
  ["$fenyin2"] = "阵前亢歌，以振军心！",
  ["~liuzan"] = "贼子们，来吧！啊…………",
}

local miheng = General(extension, "miheng", "qun", 3)
miheng.hidden = true
local mobile__kuangcai = fk.CreateTriggerSkill{
  name = "mobile__kuangcai",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local original_timeout = room.timeout
    local phase = room.logic:getCurrentEvent():findParent(GameEvent.Phase)
    if phase ~= nil then
      phase:addCleaner(function()
        room.timeout = original_timeout
      end)
    end
    room:setPlayerMark(player, "mobile__kuangcai_timeout-phase", 5)
    room.timeout = 5
    --- FIXME: 会修改其他角色的响应时间，且qml框会按原时间关闭
  end,

  refresh_events = {fk.StartPlayCard},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room.timeout = player:getMark("mobile__kuangcai_timeout-phase")
  end,
}
local mobile__kuangcai_targetmod = fk.CreateTargetModSkill{
  name = "#mobile__kuangcai_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:usedSkillTimes("mobile__kuangcai", Player.HistoryPhase) > 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return player:usedSkillTimes("mobile__kuangcai", Player.HistoryPhase) > 0
  end,
}
local mobile__kuangcai_trigger = fk.CreateTriggerSkill{
  name = "#mobile__kuangcai_trigger",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("mobile__kuangcai", Player.HistoryPhase) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, "mobile__kuangcai")
    room:removePlayerMark(player, "mobile__kuangcai_timeout-phase", 1)
    room.timeout = player:getMark("mobile__kuangcai_timeout-phase")
  end,
}
local mobile__shejian = fk.CreateTriggerSkill{
  name = "mobile__shejian",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Discard then
      local yes = true
      local suits = {}
      local events = player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              local suit = Fk:getCardById(info.cardId).suit
              if suit ~= Card.NoSuit and not table.contains(suits, suit) then
                table.insert(suits, suit)
              else
                yes = false
                break
              end
            end
          end
        end
      end, Player.HistoryPhase)
      return yes and #suits > 1 and table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper)
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#mobile__shejian-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(player, to, "he", self.name)
    room:throwCard({card}, self.name, to, player)
  end,
}
mobile__kuangcai:addRelatedSkill(mobile__kuangcai_targetmod)
mobile__kuangcai:addRelatedSkill(mobile__kuangcai_trigger)
miheng:addSkill(mobile__kuangcai)
miheng:addSkill(mobile__shejian)
Fk:loadTranslationTable{
  ["miheng"] = "祢衡",
  ["#miheng"] = "鸷鹗啄孤凤",
	["designer:miheng"] = "千幻",
  ["illustrator:miheng"] = "Thinking",

  ["mobile__kuangcai"] = "狂才",
  [":mobile__kuangcai"] = "出牌阶段开始时，你可以令你此阶段内的主动出牌时间变为5秒，响应出牌时间也变为5秒。若如此做，本阶段你使用牌无距离次数限制，"..
  "且当你使用牌时，你摸一张牌且主动出牌时间-1秒（每阶段至多以此法摸五张牌）。",
  ["mobile__shejian"] = "舌剑",
  [":mobile__shejian"] = "弃牌阶段结束时，若你本阶段弃置过至少两张牌且花色均不相同，你可以弃置一名其他角色一张牌。",
  ["#mobile__shejian-choose"] = "舌剑：你可以弃置一名其他角色一张牌",

  ["$mobile__kuangcai1"] = "博古揽今，信手拈来。",
  ["$mobile__kuangcai2"] = "功名为尘，光阴为金。",
  ["$mobile__shejian1"] = "尔等竖子，不堪为伍！",
  ["$mobile__shejian2"] = "请君洗耳，听我之言。",
  ["~miheng"] = "呵呵呵呵……这天地都容不下我！……",
}

local caochun = General(extension, "caochun", "wei", 4)
local shanjia = fk.CreateTriggerSkill{
  name = "shanjia",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        return use.from == player.id and use.card.type == Card.TypeEquip
      end, Player.HistoryGame) > 0 then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 7, function(e)
      local use = e.data[1]
      return use.from == player.id and use.card.type == Card.TypeEquip
    end, Player.HistoryGame)
    n = math.min(n, 7)
    player:drawCards(n, self.name)
    if player.dead or player:isNude() then return end
    local yes = false
    if #player:getCardIds("he") < n then
      if #player:getCardIds("e") > 0 then
        yes = true
      end
      player:throwAllCards("he")
    else
      local cards = room:askForDiscard(player, n, n, true, self.name, false, ".", nil, true)
      if table.find(cards, function(id) return table.contains(player:getCardIds("e"), id) end) then
        yes = true
      end
      room:throwCard(cards, self.name, player, player)
    end
    if not player.dead and yes then
      U.askForUseVirtualCard(room, player, "slash", nil, self.name, nil, true, true, true, true)
    end
  end,

  refresh_events = {fk.CardUsing, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function (self, event, target, player, data)
    if target == player then
      if event == fk.CardUsing then
        return player:hasSkill(self, true) and data.card.type == Card.TypeEquip and player:getMark("@shanjia") < 7
      else
        return data == self and player.room:getTag("RoundCount")
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:addPlayerMark(player, "@shanjia", 1)
    elseif event == fk.EventAcquireSkill then
      local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 7, function(e)
        local use = e.data[1]
        return use.from == player.id and use.card.type == Card.TypeEquip
      end, Player.HistoryGame)
      n = math.min(n, 7)
      room:setPlayerMark(player, "@shanjia", n)
    elseif event == fk.EventLoseSkill then
      room:addPlayerMark(player, "@shanjia", 0)
    end
  end,
}
caochun:addSkill(shanjia)
Fk:loadTranslationTable{
  ["caochun"] = "曹纯",
  ["#caochun"] = "虎豹骑首",
  ["illustrator:caochun"] = "depp",
  ["shanjia"] = "缮甲",
  [":shanjia"] = "出牌阶段开始时，你可以摸X张牌，然后弃置等量的牌（X为你于本局游戏内使用过的装备牌数且至多为7）。若你以此法弃置了装备区内的牌，"..
  "视为你使用一张无距离次数限制的【杀】。",
  ["@shanjia"] = "缮甲",

  ["$shanjia1"] = "缮甲厉兵，伺机而行。",
  ["$shanjia2"] = "战，当取精锐之兵，而弃驽钝也。",
  ["~caochun"] = "银甲在身，竟败于你手！",
}

local pangdegong = General(extension, "pangdegong", "qun", 3)
local pingcai = fk.CreateActiveSkill{
  name = "pingcai",
  mute = true,
  card_num = 0,
  target_num = 0,
  prompt = "#pingcai",
  interaction = function()
    return UI.ComboBox {choices = {"pingcai_wolong", "pingcai_pangtong", "pingcai_simahui", "pingcai_xushu"}}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:notifySkillInvoked(player, self.name, "control")
    player:broadcastSkillInvoke(self.name, 1)
    if math.random() < 0.03 then  --看看哪个倒霉蛋失败
      room:doBroadcastNotify("ShowToast", Fk:translate("pingcai_fail"))
      return
    end
    room:doBroadcastNotify("ShowToast", Fk:translate("pingcai_success"))
    if self.interaction.data == "pingcai_wolong" then
      local n = table.find(room.alive_players, function(p)
        return string.find(p.general, "wolong") or string.find(p.deputyGeneral, "wolong")
      end) and 2 or 1
      local targets = table.map(room.alive_players, Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, n, "#pingcai_wolong:::"..n, self.name, false)
      if #tos > 0 then
        player:broadcastSkillInvoke(self.name, 2)
        for _, id in ipairs(tos) do
          local p = room:getPlayerById(id)
          if not p.dead then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              damageType = fk.FireDamage,
              skillName = self.name,
            }
          end
        end
      end
    elseif self.interaction.data == "pingcai_pangtong" then
      local n = table.find(room.alive_players, function(p)
        return p.general:endsWith("pangtong") or p.deputyGeneral:endsWith("pangtong") or
          p.general == "wolongfengchu" or p.deputyGeneral == "wolongfengchu"
      end) and 4 or 3
      local targets = table.map(table.filter(room.alive_players, function(p) return not p.chained end), Util.IdMapper)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 3, n, "#pingcai_pangtong:::"..n, self.name, false)
      if #tos > 0 then
        player:broadcastSkillInvoke(self.name, 3)
        for _, id in ipairs(tos) do
          local p = room:getPlayerById(id)
          if not p.dead then
            p:setChainState(true)
          end
        end
      end
    elseif self.interaction.data == "pingcai_simahui" then
      local pattern = "armor"
      if table.find(room.alive_players, function(p)
        return p.general:endsWith("simahui") or p.deputyGeneral:endsWith("simahui")
      end) then
        pattern = "equip"
      end
      local excludeIds = {}
      if pattern == "armor" then
        for _, p in ipairs(room.alive_players) do
          for _, id in ipairs(p:getCardIds("e")) do
            if Fk:getCardById(id).sub_type ~= Card.SubtypeArmor then
              table.insert(excludeIds, id)
            end
          end
        end
      end
      local targets = room:askForChooseToMoveCardInBoard(player, "#pingcai_simahui:::"..pattern, self.name, true, "e", false, excludeIds)
      if #targets == 0 then return end
      player:broadcastSkillInvoke(self.name, 4)
      room:askForMoveCardInBoard(player, room:getPlayerById(targets[1]), room:getPlayerById(targets[2]), self.name)
    elseif self.interaction.data == "pingcai_xushu" then
      local targets = table.map(room.alive_players, Util.IdMapper)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#pingcai_xushu", self.name, false)
      if #to > 0 then
        player:broadcastSkillInvoke(self.name, 5)
        to = room:getPlayerById(to[1])
        to:drawCards(1, self.name)
        if not to.dead and to:isWounded() then
          room:recover({
            who = to,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
        if not player.dead and
        table.find(room.alive_players, function(p)
          return p.general:endsWith("xushu") or p.deputyGeneral:endsWith("xushu")
        end) then
          player:drawCards(1, self.name)
        end
      end
    end
  end,
}
local yinship = fk.CreateTriggerSkill{
  name = "yinship",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and table.contains({2, 3, 7}, data.to)
  end,
  on_use = Util.TrueFunc,
}
local yinship_prohibit = fk.CreateProhibitSkill{
  name = "#yinship_prohibit",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
    return to:hasSkill(self) and card.sub_type == Card.SubtypeDelayedTrick
  end,
}
yinship:addRelatedSkill(yinship_prohibit)
pangdegong:addSkill(pingcai)
pangdegong:addSkill(yinship)
Fk:loadTranslationTable{
  ["pangdegong"] = "庞德公",
  ["#pangdegong"] = "德懿举世",
  ["illustrator:pangdegong"] = "Town",
  ["pingcai"] = "评才",
  [":pingcai"] = "出牌阶段限一次，你可以挑选一个宝物，擦拭掉上面的灰尘。如果擦拭成功，你可以根据宝物类型执行对应的效果："..
  "卧龙：对一名角色造成1点火焰伤害。若场上有存活的卧龙诸葛亮，则改为对至多两名角色各造成1点火焰伤害。<br>"..
  "凤雏：横置至多三名角色的武将牌。若场上有存活的庞统，则改为横置至多四名角色的武将牌。<br>"..
  "水镜：移动场上的一张防具牌。若场上有存活的司马徽，则改为移动场上的一张装备牌。<br>"..
  "玄剑：令一名角色摸一张牌并回复1点体力。若场上有存活的徐庶，则改为令一名角色摸一张牌并回复1点体力，然后你摸一张牌。",
  ["yinship"] = "隐世",
  [":yinship"] = "锁定技，你只有摸牌、出牌和弃牌阶段；你不能被选择为延时锦囊牌的目标。",
  ["#pingcai"] = "评才：选择一个宝物擦拭灰尘！",
  ["pingcai_success"] = "擦拭成功！",
  ["pingcai_fail"] = "擦拭失败！",
  ["pingcai_wolong"] = "卧龙",
  ["pingcai_pangtong"] = "凤雏",
  ["pingcai_simahui"] = "水镜",
  ["pingcai_xushu"] = "玄剑",
  ["#pingcai_wolong"] = "卧龙：对至多%arg名角色造成1点火焰伤害",
  ["#pingcai_pangtong"] = "凤雏：横置至多%arg名角色的武将牌",
  ["#pingcai_simahui"] = "水镜：移动场上的一张%arg",
  ["#pingcai_xushu"] = "玄剑：令一名角色摸一张牌并回复1点体力",

  ["$pingcai1"] = "吾有众好友，分为卧龙、凤雏、水镜、元直。",
  ["$pingcai2"] = "孔明能借天火之势。",
  ["$pingcai3"] = "士元虑事环环相扣。",
  ["$pingcai4"] = "德操深谙处世之道。",
  ["$pingcai5"] = "元直侠客惩恶扬善。",
  ["~pangdegong"] = "吾知人而不自知，何等荒唐。",
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
  --"qiaosi_abort",
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
    --[[
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
    --]]
    local choosed = room:askForChoices(from, qiaosi_choices, 0, 3, "qiaosi_baixitu", nil, false, false)

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
      room:obtainCard(room:getPlayerById(tgt), tmp, false, fk.ReasonGive, from.id)
    end
  end,
}
majun:addSkill(qiaosi)
Fk:loadTranslationTable{
  ["majun"] = "马钧",
  ["#majun"] = "没渊瑰璞",
  ["cv:majun"] = "金垚",
  ["designer:majun"] = "Loun老萌",
  ["illustrator:majun"] = "聚一_小道恩",

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

local zhengxuan = General(extension, "zhengxuan", "qun", 3)
local zhengjing = fk.CreateActiveSkill{
  name = "zhengjing",
  mute = true,
  card_num = 0,
  target_num = 0,
  prompt = "#zhengjing",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:notifySkillInvoked(player, self.name, "drawcard")
    player:broadcastSkillInvoke(self.name, math.random(1, 2))
    local basics = {}
    local equips = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeEquip then
        table.insertIfNeed(equips, card.name)
      else
        table.insertIfNeed(basics, card.name)
      end
    end
    local random = math.random()
    local n = 5
    if random < 0.3 then
      n = 4
      if random < 0.1 then
        n = 3
      end
    end
    if #basics == 0 and #equips == 0 then return end
    local all_choices = {}
    if #equips > 0 and math.random() < 0.5 then  --至多只出现一个装备
      all_choices = {table.random(equips)}
    end
    table.insertTable(all_choices, table.random(basics, n - #all_choices))
    table.insert(all_choices, "bomb")
    room:delay(2000)
    local patterns = {}
    local audio = table.random({{3, 4, 5, 6}, {7, 8, 9, 10}, {11, 12, 13, 14}})
    for i = 1, math.random(n, 2 * n), 1 do
      player:broadcastSkillInvoke(self.name, i % 4 == 0 and audio[4] or audio[i % 4])
      local choices = table.random(all_choices, math.random(math.min(3, #all_choices), #all_choices))
      table.shuffle(choices)
      local choice = room:askForChoice(player, choices, self.name, "#zhengjing_choice")
      room:sendLog{type = "#ZhengjingChoice", from = player.id, arg = choice, toast = true}
      table.insertIfNeed(patterns, choice)
      if choice == "bomb" then
        break
      end
    end
    if #patterns == 0 or table.contains(patterns, "bomb") then return end
    local cards = {}
    for _, pattern in ipairs(patterns) do
      table.insertTable(cards, room:getCardsFromPileByRule(pattern))
    end
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    })
    room:setPlayerMark(player, "zhengjing", cards)
    local _, dat = room:askForUseActiveSkill(player, "zhengjing_active", "#zhengjing-give", true)
    if dat then
      room:getPlayerById(dat.targets[1]):addToPile("zhengxuan_jing", dat.cards, true, self.name)
    end
    cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #cards > 0 and not player.dead then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
  end,
}
local zhengjing_active = fk.CreateActiveSkill{
  name = "zhengjing_active",
  mute = true,
  min_card_num = 1,
  target_num = 1,
  expand_pile = function() return U.getMark(Self, "zhengjing") end,
  card_filter = function(self, to_select, selected)
    return table.contains(U.getMark(Self, "zhengjing"), to_select)
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and #cards > 0
  end,
}
local zhengjing_trigger = fk.CreateTriggerSkill{
  name = "#zhengjing_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and #player:getPile("zhengxuan_jing") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:skip(Player.Judge)
    player:skip(Player.Draw)
    room:moveCardTo(player:getPile("zhengxuan_jing"), Card.PlayerHand, player, fk.ReasonPrey, "zhengjing", nil, true, player.id)
  end,
}
Fk:addSkill(zhengjing_active)
zhengjing:addRelatedSkill(zhengjing_trigger)
zhengxuan:addSkill(zhengjing)
Fk:loadTranslationTable{
  ["zhengxuan"] = "郑玄",
  ["#zhengxuan"] = "兼采定道",
  ["designer:zhengxuan"] = "Loun老萌",
  ["illustrator:zhengxuan"] = "monkey",

  ["zhengjing"] = "整经",
  [":zhengjing"] = "出牌阶段限一次，你可以整理一次经典，并将你整理出的任意牌置于一名角色的武将牌上，称为“经”，然后你获得剩余的牌。"..
  "武将牌上有“经”的角色准备阶段，其获得所有“经”，然后跳过本回合的判定阶段和摸牌阶段。",
  ["#zhengjing"] = "整经：开始整理经典！",
  ["bomb"] = "炸弹",
  ["#zhengjing_choice"] = "整理经典！",
  ["#ZhengjingChoice"] = "%from 整理出了 %arg",
  ["zhengjing_active"] = "整经",
  ["#zhengjing-give"] = "整经：你可以将整理出的牌置为一名角色的“经”",
  ["zhengxuan_jing"] = "经",
  ["#zhengjing_trigger"] = "整经",

  ["$zhengjing1"] = "兼采今古，博学并蓄，择善以教之。",
  ["$zhengjing2"] = "君子需通六艺，亦当识明三礼。",
  ["$zhengjing3"] = "关关雎鸠，在河之洲",
  ["$zhengjing4"] = "窈窕淑女，君子好逑",
  ["$zhengjing5"] = "参差荇菜，左右流之",
  ["$zhengjing6"] = "窈窕淑女，寤寐求之",
  ["$zhengjing7"] = "蒹葭苍苍，白露为霜",
  ["$zhengjing8"] = "所谓伊人，在水一方",
  ["$zhengjing9"] = "溯游从之，道阻且长",
  ["$zhengjing10"] = "溯洄从之，宛在水中央",
  ["$zhengjing11"] = "淇则有岸，隰则有泮",
  ["$zhengjing12"] = "总角之宴，言笑晏晏",
  ["$zhengjing13"] = "信誓旦旦，不思其反",
  ["$zhengjing14"] = "反是不思，亦已焉哉",  --选的三首诗离谱
  ["~zhengxuan"] = "注易未毕，奈何寿数将近……",
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

local mxing__zhangliao_win = fk.CreateActiveSkill{ name = "mxing__zhangliao_win_audio" }
mxing__zhangliao_win.package = extension
Fk:addSkill(mxing__zhangliao_win)

Fk:loadTranslationTable{
  ["mxing__zhangliao"] = "星张辽",
  ["#mxing__zhangliao"] = "蹈锋饮血",
  ["illustrator:mxing__zhangliao"] = "王强",
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

local mxing__zhanghe_win = fk.CreateActiveSkill{ name = "mxing__zhanghe_win_audio" }
mxing__zhanghe_win.package = extension
Fk:addSkill(mxing__zhanghe_win)

Fk:loadTranslationTable{
  ["mxing__zhanghe"] = "星张郃",
  ["#mxing__zhanghe"] = "宁国中郎将",
  ["illustrator:mxing__zhanghe"] = "王强",
  ["zhilve"] = "知略",
  [":zhilve"] = "出牌阶段限一次，你可以失去1点体力令你本回合手牌上限+1，并选择一项：1.移动场上一张牌；2.摸一张牌并视为使用一张无距离次数限制的【杀】。",
  ["#zhilve1"] = "知略：选择移动牌的来源和目标",
  ["#zhilve2"] = "知略：选择使用【杀】的目标",
  ["zhilve1"] = "移动场上一张牌",
  ["zhilve2"] = "摸一张牌并视为使用杀",

  ["$zhilve1"] = "将者，上不制天，下不制地，中不制人。",
  ["$zhilve2"] = "料敌之计，明敌之意，因况反制。",
  ["~mxing__zhanghe"] = "若非小人作梗，何至官渡之败……",
  ["$mxing__zhanghe_win_audio"] = "水因地制流，兵因敌制胜！",
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
      from:drawCards(from.maxHp - from:getHandcardNum(), self.name)
      room:setPlayerMark(from, "mxing__zhiyan_draw-phase", 1)
    else
      room:moveCardTo(effect.cards, Player.Hand, room:getPlayerById(effect.tos[1]), fk.ReasonGive, self.name, nil, false, from.id)
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

local mxing__xuhuang_win = fk.CreateActiveSkill{ name = "mxing__xuhuang_win_audio" }
mxing__xuhuang_win.package = extension
Fk:addSkill(mxing__xuhuang_win)

Fk:loadTranslationTable{
  ["mxing__xuhuang"] = "星徐晃",
  ["#mxing__xuhuang"] = "沉详性严",
	["illustrator:mxing__xuhuang"] = "王强",
  ["mxing__zhiyan"] = "治严",
  [":mxing__zhiyan"] = "出牌阶段每项各限一次，你可以：1.将手牌摸至体力上限，然后你于此阶段内不能对其他角色使用牌；2.将多于体力值的手牌交给一名其他角色。",
  ["mxing__zhiyan_draw"] = "将手牌摸至体力上限",
  ["mxing__zhiyan_give"] = "交给其他角色多于体力值的牌",

  ["$mxing__zhiyan1"] = "治军严谨，方得精锐之师。",
  ["$mxing__zhiyan2"] = "精兵当严于律己，束身自修。",
  ["~mxing__xuhuang"] = "唉，明主未遇，大功未成……",
  ["$mxing__xuhuang_win_audio"] = "幸遇明主，更应立功报效国君。",
}

local ganning = General(extension, "mxing__ganning", "qun", 4)
local jinfan = fk.CreateTriggerSkill{
  name = "jinfan",
  anim_type = "drawcard",
  expand_pile = "jinfan&",
  derived_piles = "jinfan&",
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
      local _, dat = player.room:askForUseActiveSkill(target, "jinfan_active", "#jinfan-invoke", true)
      if dat then
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

local mxing__ganning_win = fk.CreateActiveSkill{ name = "mxing__ganning_win_audio" }
mxing__ganning_win.package = extension
Fk:addSkill(mxing__ganning_win)

Fk:loadTranslationTable{
  ["mxing__ganning"] = "星甘宁",
  ["#mxing__ganning"] = "铃震没羽",
  ["illustrator:mxing__ganning"] = "王强",
  
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
      if player:getSwitchSkillState(self.name) == fk.SwitchYang then
        return data.card.color == Card.Black and data.from == player.id
      elseif player:getSwitchSkillState(self.name) == fk.SwitchYin then
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
  ["#mxing__huangzhong"] = "强挚烈弓",
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
  ["#mxing__weiyan"] = "骜勇孤战",
  ["guli"] = "孤厉",
  [":guli"] = "出牌阶段限一次，你可以将所有手牌当一张无视防具的【杀】使用。此牌结算后，若此牌造成过伤害，你可以失去1点体力，然后将手牌摸至体力上限。",
  ["aosi"] = "骜肆",
  [":aosi"] = "锁定技，当你于出牌阶段对一名在你攻击范围内的其他角色造成伤害后，你于此阶段对其使用牌无次数限制。",
  ["#guli"] = "孤厉：你可以将所有手牌当一张无视防具的【杀】使用",
  ["#guli-invoke"] = "孤厉：你可以失去1点体力，将手牌补至体力上限",
  ["@@aosi-phase"] = "骜肆",

  ["$guli1"] = "今若弑此昏聩主，纵蒙恶名又如何？",
  ["$guli2"] = "韩玄少谋多忌，吾今当诛之！",
  ["$aosi1"] = "凶慢骜肆，天生狂骨！",
  ["$aosi2"] = "暴戾恣睢，傲视诸雄！",
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
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#huiyao-choose::"..target.id, self.name, false, true)
    if #tos > 0 then
      room:doIndicate(target.id, tos)
      room:damage{
        from = target,
        to = room:getPlayerById(tos[1]),
        damage = 1,
        skillName = self.name,
        isVirtualDMG = true,
      }
    end
  end,
}
local quesong = fk.CreateTriggerSkill{
  name = "quesong",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Finish then
      return #U.getActualDamageEvents(player.room, 1, function(e) return e.data[1].to == player end) > 0
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
    local x = (#to:getCardIds("e") > 2) and 2 or 3
    local choices = {"quesong_draw:::"..x}
    if to:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(to, choices, self.name)
    if choice == "recover" then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    else
      to:drawCards(x, self.name)
      to:reset()
    end
  end,
}
zhoubuyi:addSkill(huiyao)
zhoubuyi:addSkill(quesong)
Fk:loadTranslationTable{
  ["mxing__zhoubuyi"] = "星周不疑",
  ["#mxing__zhoubuyi"] = "稚雀清声",
  ["huiyao"] = "慧夭",
  [":huiyao"] = "出牌阶段限一次，你可以受到1点无来源伤害并选择一名其他角色，<font color='red'>视为</font>其对你选择的另一名角色造成1点伤害。",
  ["quesong"] = "雀颂",
  [":quesong"] = "一名角色结束阶段，若你本回合受到过伤害，你可以令一名角色选择一项：1.摸三张牌（若其装备区里的牌数大于2，则改为摸两张牌）并复原武将牌；2.回复1点体力。",
  ["#huiyao"] = "慧夭：你可以受到1点无来源伤害，选择一名其他角色，令其<font color='red'>视为</font>造成伤害",
  ["#huiyao-choose"] = "慧夭：选择一名角色，视为 %dest 对其造成1点伤害",
  ["#quesong-choose"] = "雀颂：你可以令一名角色选择摸牌或回复体力",
  ["quesong_draw"] = "摸%arg张牌并复原",

  ["$huiyao1"] = "幸有仓舒为伴，吾不至居高寡寒。",
  ["$huiyao2"] = "通悟而无笃学之念，则必盈天下之叹也。",
  ["$quesong1"] = "承白雀之瑞，显周公之德。",
  ["$quesong2"] = "挽汉室于危亡，继光武之中兴。",
  ["~mxing__zhoubuyi"] = "慧童亡，天下伤……",
}

local shichangshi = General(extension, "shichangshi", "qun", 1)

local shichangshi_win = fk.CreateActiveSkill{ name = "shichangshi_win_audio" }
shichangshi_win.package = extension
Fk:addSkill(shichangshi_win)

Fk:loadTranslationTable{
  ["shichangshi"] = "十常侍",
  ["$shichangshi_win_audio"] = "十常侍威势更甚，再无人可掣肘。",
}

local tenChangShiMapper = {
  ["changshi__zhangrang"] = "changshi__taoluan",
  ["changshi__zhaozhong"] = "changshi__chiyan",
  ["changshi__sunzhang"] = "changshi__zimou",
  ["changshi__bilan"] = "changshi__picai",
  ["changshi__xiayun"] = "changshi__yaozhuo",
  ["changshi__hankui"] = "changshi__xiaolu",
  ["changshi__lisong"] = "changshi__kuiji",
  ["changshi__duangui"] = "changshi__chihe",
  ["changshi__guosheng"] = "changshi__niqu",
  ["changshi__gaowang"] = "changshi__miaoyu",
}

Fk:loadTranslationTable{
  ["changshi"] = "常侍",
  ["changshi__zhangrang"] = "张让",
  ["changshi__zhaozhong"] = "赵忠",
  ["changshi__sunzhang"] = "孙璋",
  ["changshi__bilan"] = "毕岚",
  ["changshi__xiayun"] = "夏恽",
  ["changshi__hankui"] = "韩悝",
  ["changshi__lisong"] = "栗嵩",
  ["changshi__duangui"] = "段珪",
  ["changshi__guosheng"] = "郭胜",
  ["changshi__gaowang"] = "高望",

  [":changshi__zhangrang-specificSkillDesc"] = "滔乱：（滔乱）",
  [":changshi__zhaozhong-specificSkillDesc"] = "鸱咽：（破军）",
  [":changshi__sunzhang-specificSkillDesc"] = "自谋：（勤政）",
  [":changshi__bilan-specificSkillDesc"] = "庀材：（慧识）",
  [":changshi__xiayun-specificSkillDesc"] = "谣诼：（义争）",
  [":changshi__hankui-specificSkillDesc"] = "宵赂：（巧思）",
  [":changshi__lisong-specificSkillDesc"] = "窥机：（魄袭）",
  [":changshi__duangui-specificSkillDesc"] = "叱吓：（烈弓）",
  [":changshi__guosheng-specificSkillDesc"] = "逆取：（评才）",
  [":changshi__gaowang-specificSkillDesc"] = "妙语：（龙魂）",
}

local hiddenChangshi = General(extension, "hiddenChangshi", "qun", 1)
hiddenChangshi.total_hidden = true

local changshiTaoluan = fk.CreateViewAsSkill{
  name = "changshi__taoluan",
  pattern = ".",
  interaction = function()
    local names = {}
    local mark = Self:getMark("@$taoluan")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeBasic or card:isCommonTrick()) and not card.is_derived and
        Self:canUse(card) then
        if mark == 0 or (not table.contains(mark, card.trueName)) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = function(self, player)
    return false
  end,
}
Fk:loadTranslationTable{
  ["changshi__taoluan"] = "滔乱",
  [":changshi__taoluan"] = "出牌阶段限一次，你可以将一张牌当任意基本牌或普通锦囊牌使用。",
  ["$changshi__taoluan1"] = "罗绮朱紫，皆若吾等手中傀儡。",
}

hiddenChangshi:addSkill(changshiTaoluan)
shichangshi:addRelatedSkill("changshi__taoluan")

local changshiChiyan = fk.CreateTriggerSkill{
  name = "changshi__chiyan",
  anim_type = "offensive",
  events = {fk.TargetSpecified, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" then
      if event == fk.TargetSpecified then
        local to = player.room:getPlayerById(data.to)
        return not to.dead and to.hp > 0 and not to:isNude()
      elseif event == fk.DamageCaused then
        return not data.chain and #player:getCardIds(Player.Hand) >= #data.to:getCardIds(Player.Hand) and
        #player:getCardIds(Player.Equip) >= #data.to:getCardIds(Player.Equip)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      if player.room:askForSkillInvoke(player, self.name, nil, "#changshi__chiyan-invoke::"..data.to) then
        player.room:doIndicate(player.id, {data.to})
        return true
      end
    elseif event == fk.DamageCaused then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local to = room:getPlayerById(data.to)
      local cards = room:askForCardsChosen(player, to, 1, 1, "he", self.name)
      to:addToPile(self.name, cards, false, self.name)
    else
      data.damage = data.damage + 1
    end
  end,
}

local changshiChiyanDelay = fk.CreateTriggerSkill{
  name = "#changshi__chiyan_delay",
  mute = true,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return data.to == Player.NotActive and #player:getPile("changshi__chiyan") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player.id, player:getPile("changshi__chiyan"), false)
  end,
}
Fk:loadTranslationTable{
  ["changshi__chiyan"] = "鸱咽",
  [":changshi__chiyan"] = "当你使用【杀】指定目标后，你可以将其一张牌扣置于其武将牌旁，该角色于本回合结束时获得此牌；当你使用【杀】对手牌数和"..
  "装备区内的牌数均不大于你的目标角色造成伤害时，此伤害+1。",
  ["#changshi__chiyan-invoke"] = "是否对%dest发动 鸱咽",
  ["$changshi__chiyan1"] = "逆臣乱党，都要受这啄心之刑。",
}

changshiChiyan:addRelatedSkill(changshiChiyanDelay)
hiddenChangshi:addSkill(changshiChiyan)
shichangshi:addRelatedSkill("changshi__chiyan")

local changshiZimou = fk.CreateTriggerSkill{
  name = "changshi__zimou",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      player.phase == Player.Play and
      table.contains({ 2, 4, 6 }, player:getMark("@" .. self.name))
  end,
  on_use = function(self, event, player, target, data)
    local count = player:getMark("@" .. self.name)

    local cardList = "analeptic"
    if count == 4 then
      cardList = "slash"
    elseif count == 6 then
      cardList = "duel"
    end
    local randomCard = player.room:getCardsFromPileByRule(cardList)
    if #randomCard > 0 then
      player.room:moveCards({
        ids = { randomCard[1] },
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@" .. self.name, 1)
  end,
}
Fk:loadTranslationTable{
  ["changshi__zimou"] = "自谋",
  [":changshi__zimou"] = "锁定技，当你于出牌阶段内使用：第二张牌时，你随机获得一张【酒】；第四张牌时，你随机获得一张【杀】；第六张牌时，"..
  "你随机获得一张【决斗】。",
  ["@changshi__zimou"] = "自谋",
  ["$changshi__zimou1"] = "在宫里当差，还不是为这利字！",
}

hiddenChangshi:addSkill(changshiZimou)
shichangshi:addRelatedSkill("changshi__zimou")

local changshiPicai = fk.CreateActiveSkill{
  name = "changshi__picai",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
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
    while true do
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
        not room:askForSkillInvoke(from, self.name, nil, "#changshi__picai-ask")
      then
        break
      end
    end

    local alivePlayerIds = table.map(room.alive_players, function(p)
      return p.id
    end)

    cardsJudged = table.filter(cardsJudged, function(card)
      return room:getCardArea(card.id) == Card.Processing
    end)
    if #cardsJudged == 0 then
      return false
    end

    local targets = room:askForChoosePlayers(from, alivePlayerIds, 1, 1, "#changshi__picai-give", self.name, true)
    
    if #targets > 0 then
      room:moveCardTo(cardsJudged, Card.PlayerHand, room:getPlayerById(targets[1]), fk.ReasonGive, self.name, nil, true, from.id)
    else
      room:moveCards({
        ids = table.map(cardsJudged, function(card)
          return card:getEffectiveId()
        end),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
      })
    end
  end,
}
Fk:loadTranslationTable{
  ["changshi__picai"] = "庀材",
  [":changshi__picai"] = "出牌阶段限一次，你可以进行判定，若结果与本次流程中的其他判定结果均不同，你可重复此流程。最后你可将本次流程中所有生效的判定牌"..
  "交给一名角色。",
  ["#changshi__picai-ask"] = "庀材：你可以重复此流程",
  ["#changshi__picai-give"] = "庀材：你可以将这些判定牌交给一名角色",
  ["$changshi__picai1"] = "修得广厦千万，可庇汉室不倾。",
}

hiddenChangshi:addSkill(changshiPicai)
shichangshi:addRelatedSkill("changshi__picai")

local changshiYaozhuo = fk.CreateActiveSkill{
  name = "changshi__yaozhuo",
  anim_type = "control",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return
      #selected < 1 and
      Self.id ~= to_select and
      Self:canPindian(target)
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local pindian = from:pindian({ to }, self.name)
    if pindian.results[to.id].winner == from then
      room:setPlayerMark(to, "@@changshi__yaozhuo", true)
    else
      room:askForDiscard(from, 2, 2, true, self.name, false)
    end
  end,
}
local changshiYaozhuoDebuff = fk.CreateTriggerSkill{
  name = "#changshi__Yaozhuo-debuff",
  mute = true,
  priority = 3,
  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target:getMark("@@changshi__yaozhuo") == true and data.from == Player.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    target.room:setPlayerMark(target, "@@changshi__yaozhuo", 0)
    target:skip(Player.Draw)
  end,
}
Fk:loadTranslationTable{
  ["changshi__yaozhuo"] = "谣诼",
  [":changshi__yaozhuo"] = "出牌阶段限一次，你可以与一名角色拼点。若你：赢，跳过其下个摸牌阶段；没赢：你弃置两张牌。",
  ["@@changshi__yaozhuo"] = "谣诼",
  ["$changshi__yaozhuo1"] = "上蔽天听，下诓朝野！",
}

changshiYaozhuo:addRelatedSkill(changshiYaozhuoDebuff)
hiddenChangshi:addSkill(changshiYaozhuo)
shichangshi:addRelatedSkill("changshi__yaozhuo")

local changshixiaolu = fk.CreateActiveSkill{
  name = "changshi__xiaolu",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_num = 0,
  card_num = 0,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    from:drawCards(2, self.name)
    if from.dead or from:isKongcheng() then return end
    local choice = room:askForChoice(from, { "changshi__xiaolu_give", "changshi__xiaolu_discard" }, self.name)
    if choice == "changshi__xiaolu_discard" then
      room:askForDiscard(from, 2, 2, false, self.name, false)
    else
      local all = from:getCardIds("h")
      local to_give = #all > 2 and room:askForCard(from, 2, 2, false, self.name, false, nil, "#changshi__xiaolu-give:::" .. 2) or all
      local tgt = room:askForChoosePlayers(from, table.map(
        room:getOtherPlayers(from), Util.IdMapper), 1, 1, "#changshi__xiaolu-give-choose", self.name, false)[1]

      local tmp = Fk:cloneCard("slash")
      tmp:addSubcards(to_give)
      room:obtainCard(room:getPlayerById(tgt), tmp, false, fk.ReasonGive, from.id)
    end
  end,
}
Fk:loadTranslationTable{
  ["changshi__xiaolu"] = "宵赂",
  [":changshi__xiaolu"] = "出牌阶段限一次，你可以摸两张牌，然后选择一项：1.弃置两张手牌；2.将两张手牌交给一名其他角色。",
  ["changshi__xiaolu_give"] = "交出两张手牌",
  ["changshi__xiaolu_discard"] = "弃置两张手牌",
  ["#changshi__xiaolu-give"] = "宵赂：请选择要交出的 %arg 张牌",
  ["#changshi__xiaolu-give-choose"] = "宵赂：请选择要交给的目标",
  ["$changshi__xiaolu1"] = "咱家上下打点，自是要费些银子。",
}

hiddenChangshi:addSkill(changshixiaolu)
shichangshi:addRelatedSkill("changshi__xiaolu")

local changshiKuiji = fk.CreateActiveSkill{
  name = "changshi__kuiji",
  anim_type = "control",
  prompt = "#changshi__kuiji-prompt",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local player_hands = player:getCardIds("h")
    local target_hands = target:getCardIds("h")
    local cards = room:askForPoxi(player, "changshi__kuiji_discard", {
      { player.general, player_hands },
      { target.general, target_hands },
    }, nil, true)
    if #cards == 0 then return end
    local cards1 = table.filter(cards, function(id) return table.contains(player_hands, id) end)
    local cards2 = table.filter(cards, function(id) return table.contains(target_hands, id) end)
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = player.id,
        ids = cards1,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = target.id,
        ids = cards2,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))

    return false
  end,
}
Fk:addPoxiMethod{
  name = "changshi__kuiji_discard",
  card_filter = function(to_select, selected, data)
    local suit = Fk:getCardById(to_select).suit
    if suit == Card.NoSuit then return false end
    return not table.find(selected, function(id) return Fk:getCardById(id).suit == suit end)
  end,
  feasible = function(selected)
    return #selected == 4
  end,
  prompt = function ()
    return "#changshi__kuiji-poxi_prompt"
  end
}
Fk:loadTranslationTable{
  ["changshi__kuiji"] = "窥机",
  [":changshi__kuiji"] = "出牌阶段限一次，你可以观看一名其他角色的手牌并可弃置你与其手牌中共计四张花色各不相同的牌。",
  ["changshi__kuiji_discard"] = "窥机观看",
  ["#changshi__kuiji-prompt"] = "窥机：选择一名有手牌的其他角色，并可弃置你与其手牌中共计四张花色各不相同的牌",
  ["#changshi__kuiji-poxi_prompt"] = "窥机：弃置双方手里四张不同花色的牌",
  ["$changshi__kuiji1"] = "同道者为忠，殊途者为奸！",
}

hiddenChangshi:addSkill(changshiKuiji)
shichangshi:addRelatedSkill("changshi__kuiji")

local changshiChihe = fk.CreateTriggerSkill{
  name = "changshi__chihe",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      data.card.trueName == "slash" and
      #AimGroup:getAllTargets(data.tos) == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cardUseEvent = room.logic:getCurrentEvent().parent
    cardUseEvent.changshiChiheUsed = true

    local cards = room:getNCards(2)
    room:moveCardTo(cards, Card.Processing)

    local idsMatched = table.filter(cards, function(id)
      local c = Fk:getCardById(id)
      return data.card.suit == c.suit
    end)

    room:setPlayerMark(room:getPlayerById(data.to), self.name, table.map(cards, function (id) return Fk:getCardById(id).suit end))
    if #idsMatched > 0 then
      data.additionalDamage = (data.additionalDamage or 0) + #idsMatched
    end

    local cardsInProcessing = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #cardsInProcessing > 0 then
      room:moveCardTo(cardsInProcessing, Card.DiscardPile)
    end
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.room.logic:getCurrentEvent().changshiChiheUsed
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      room:setPlayerMark(p, self.name, 0)
    end
  end,
}

local changshiChiheProhibit = fk.CreateProhibitSkill{
  name = "#changshiChihe_prohibit",
  prohibit_use = function(self, player, card)
    -- FIXME: 确保是因为【杀】而出闪，并且指明好事件id
    if Fk.currentResponsePattern ~= "jink" or card.name ~= "jink" or player:getMark("changshi__chihe") == 0 then
      return false
    end
    if table.contains(player:getMark("changshi__chihe"), card.suit) then
      return true
    end
  end,
}
Fk:loadTranslationTable{
  ["changshi__chihe"] = "叱吓",
  [":changshi__chihe"] = "当你使用【杀】指定唯一目标后，你可以亮出牌堆顶两张牌，令其不能使用与亮出的牌花色相同的牌响应此【杀】，"..
  "且其中每有一张牌与此【杀】花色相同，此【杀】伤害基数便+1。",
  ["$changshi__chihe1"] = "想见圣上？哼哼，你怕是没这个福分了！",
}

changshiChihe:addRelatedSkill(changshiChiheProhibit)
hiddenChangshi:addSkill(changshiChihe)
shichangshi:addRelatedSkill("changshi__chihe")

local changshiNiqu = fk.CreateActiveSkill{
  name = "changshi__niqu",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    room:damage({
      from = room:getPlayerById(effect.from),
      to = room:getPlayerById(effect.tos[1]),
      damage = 1,
      damageType = fk.FireDamage,
      skillName = self.name
    })

    return false
  end,
}
Fk:loadTranslationTable{
  ["changshi__niqu"] = "逆取",
  [":changshi__niqu"] = "出牌阶段限一次，你可以对一名其他角色造成1点火焰伤害。",
  ["$changshi__niqu1"] = "离心离德，为吾等所不容！",
}

hiddenChangshi:addSkill(changshiNiqu)
shichangshi:addRelatedSkill("changshi__niqu")

local changshiMiaoyu = fk.CreateViewAsSkill{
  name = "changshi__miaoyu",
  pattern = "peach,slash,jink,nullification",
  card_filter = function(self, to_select, selected)
    if #selected == 2 then
      return false
    elseif #selected == 1 then
      return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(selected[1]))
    else
      local suit = Fk:getCardById(to_select).suit
      local c
      if suit == Card.Heart then
        c = Fk:cloneCard("peach")
      elseif suit == Card.Diamond then
        c = Fk:cloneCard("fire__slash")
      elseif suit == Card.Club then
        c = Fk:cloneCard("jink")
      elseif suit == Card.Spade then
        c = Fk:cloneCard("nullification")
      else
        return false
      end
      return (Fk.currentResponsePattern == nil and c.skill:canUse(Self, c)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
    end
  end,
  view_as = function(self, cards)
    if #cards == 0 or #cards > 2 then
      return nil
    end
    local suit = Fk:getCardById(cards[1]).suit
    local c
    if suit == Card.Heart then
      c = Fk:cloneCard("peach")
    elseif suit == Card.Diamond then
      c = Fk:cloneCard("fire__slash")
    elseif suit == Card.Club then
      c = Fk:cloneCard("jink")
    elseif suit == Card.Spade then
      c = Fk:cloneCard("nullification")
    else
      return nil
    end
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    local num = #use.card.subcards
    if num == 2 then
      local suit = Fk:getCardById(use.card.subcards[1]).suit
      if suit == Card.Diamond then
        use.additionalDamage = (use.additionalDamage or 0) + 1
      elseif suit == Card.Heart then
        use.additionalRecover = (use.additionalRecover or 0) + 1
      end
    end
  end,
}
local changshiMiaoyuDiscard = fk.CreateTriggerSkill{
  name = "#changshi__miaoyu_discard",
  events = {fk.CardUseFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "changshi__miaoyu") and #data.card.subcards == 2 and
      Fk:getCardById(data.card.subcards[1]).color == Card.Black
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not room.current:isNude() then
      local cid = room:askForCardChosen(player, room.current, "he", self.name)
      room:throwCard({cid}, self.name, room.current, player)
    end
  end,
}
Fk:loadTranslationTable{
  ["changshi__miaoyu"] = "妙语",
  [":changshi__miaoyu"] = "你可以将至多两张同花色的牌按以下规则使用或打出：<font color='red'>♥</font>当【桃】，<font color='red'>♦</font>当火【杀】，"..
  "♣当【闪】，♠当【无懈可击】。若你以此法使用或打出了两张：红桃牌，此牌回复基数+1；方块牌，此牌伤害基数+1；黑色牌，你弃置当前回合角色一张牌。",
  ["$changshi__miaoyu1"] = "小伤无碍，安心修养便可。",
}

changshiMiaoyu:addRelatedSkill(changshiMiaoyuDiscard)
hiddenChangshi:addSkill(changshiMiaoyu)
shichangshi:addRelatedSkill("changshi__miaoyu")

local danggu = fk.CreateTriggerSkill{
  name = "danggu",
  frequency = Skill.Compulsory,
  anim_type = "negative",
  events = {fk.GameStart, fk.AfterPlayerRevived},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self)
    elseif event == fk.AfterPlayerRevived then
      return
        target == player and
        data.reason == "rest" and
        type(player.tag["changshi_cards"]) == "table" and
        #player.tag["changshi_cards"] > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    ---@param room Room
    ---@param player ServerPlayer
    ---@param generals string[]
    local doJieDang = function(room, player, generals)
      if type(generals) ~= "table" or #generals < 2 then
        return
      end

      generals = table.simpleClone(generals)

      local mainGeneral
      local deputyGeneral
      if #generals < 3 then
        mainGeneral = generals[1]
        deputyGeneral = generals[2]
      else
        mainGeneral = table.random(generals)
        table.removeOne(generals, mainGeneral)
        local deputyGenerals = table.random(generals, 4)

        local haters = {
          ["changshi__bilan"] = 'changshi__hankui',
          ["changshi__hankui"] = 'changshi__bilan',
          ["changshi__duangui"] = 'changshi__guosheng',
          ["changshi__guosheng"] = 'changshi__duangui',
        }

        local disabledGeneral = ""
        local hater = haters[mainGeneral]
        if hater and table.contains(deputyGenerals, hater) then
          disabledGeneral = hater
        elseif math.random() < 0.1 then
          disabledGeneral = table.random(deputyGenerals)
        end

        local result = room:askForCustomDialog(
          player, "jiedang",
          "packages/mobile/qml/JieDangBox.qml",
          { mainGeneral, deputyGenerals, disabledGeneral }
        )

        if result ~= "" then
          deputyGeneral = json.decode(result).general
        else
          deputyGeneral = table.random(deputyGenerals)
        end
      end

      player.tag['jiedang_before_generals'] = { player.general, player.deputyGeneral }
      table.removeOne(generals, mainGeneral)
      table.removeOne(generals, deputyGeneral)
      player.tag['changshi_cards'] = generals
      room:setPlayerMark(player, "@&changshiCards", #generals > 0 and generals or 0)

      room:changeHero(player, mainGeneral, true, false, false, false)
      room:changeHero(player, deputyGeneral, true, true, false, false)
      room:handleAddLoseSkills(player, tenChangShiMapper[mainGeneral] .. "|" .. tenChangShiMapper[deputyGeneral], nil, false)
    end
    if event == fk.GameStart then
      local tenChangShis = {}
      for changShi, _ in pairs(tenChangShiMapper) do
        table.insert(tenChangShis, changShi)
      end
      room:setPlayerMark(player, "@&changshiCards", tenChangShis)

      doJieDang(room, player, tenChangShis)
    elseif event == fk.AfterPlayerRevived then
      doJieDang(room, player, player.tag['changshi_cards'])
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = { fk.BeforeGameOverJudge, fk.GameFinished, fk.AfterPropertyChange },
  can_refresh = function(self, event, target, player, data)
    if not player.tag['jiedang_before_generals'] then
      return false
    end
    
    if event == fk.AfterPropertyChange then
      return target == player and data.results and (data.results.generalChange or data.results.deputyChange)
    else
      return event == fk.GameFinished or target == player
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterPropertyChange then
      if data.results.generalChange then
        local beforeGeneral = data.results.generalChange[1]
        if tenChangShiMapper[beforeGeneral] then
          room:handleAddLoseSkills(player, "-" .. tenChangShiMapper[beforeGeneral], nil, false)
        end

        if not tenChangShiMapper[player.general] then
          player.tag['jiedang_before_generals'][1] = player.general
        end
      end

      if data.results.deputyChange then
        local beforeGeneral = data.results.deputyChange[1]
        if tenChangShiMapper[beforeGeneral] then
          room:handleAddLoseSkills(player, "-" .. tenChangShiMapper[beforeGeneral], nil, false)
        end

        if not tenChangShiMapper[player.deputyGeneral] then
          player.tag['jiedang_before_generals'][2] = player.deputyGeneral
        end
      end
    else
      local generals = player.tag['jiedang_before_generals']

      local hasDangGu = player:hasSkill(self, true, true)
      local hasMoWang = player:hasSkill("mowang", true, true)

      if #generals > 1 then
        if event == fk.GameFinished then
          room:setPlayerProperty(player, "deputyGeneral", generals[2])
        else
          room:changeHero(player, generals[2], false, true, false, false)
        end
      end
      if generals[1] ~= "" then
        if event == fk.GameFinished then
          room:setPlayerProperty(player, "general", generals[1])
        else
          room:changeHero(player, generals[1], false, false, false, false)
        end
      end

      if event == fk.GameFinished then
        return false
      end

      local toObtain = {}
      if hasDangGu and not player:hasSkill(self) then
        table.insert(toObtain, self.name)
      end
      if hasMoWang and not player:hasSkill("mowang") then
        table.insert(toObtain, "mowang")
      end

      if #toObtain > 0 then
        room:handleAddLoseSkills(player, table.concat(toObtain, "|"), nil, false)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["danggu"] = "党锢",
  [":danggu"] = "锁定技，游戏开始时，你获得十张不同的“常侍牌”，然后你进行一次“结党”（随机展示一张“常侍”牌，然后随机展示四张“常侍”牌，你从中选择一张与"..
  "最初展示的“常侍”牌互相认可的与其组成双将。）；当你因休整而返回游戏后，你进行一次“结党”并摸一张牌。",
  ["@&changshiCards"] = "常侍",
  ["jiedang"] = "结党",
  ["$JieDang"] = "结党",

  ["$changshi__zhangrang_taunt1"] = "吾乃当今帝父，汝岂配与我同列？",
  ["$changshi__zhaozhong_taunt1"] = "汝此等语，何不以溺自照？",
  ["$changshi__sunzhang_taunt1"] = "闻谤而怒，见誉而喜，汝万万不能啊！",
  ["$changshi__bilan_taunt1"] = "吾虽鄙夫，亦远胜尔等狂叟！",
  ["$changshi__xiayun_taunt1"] = "贪财好贿，其罪尚小，不敬不逊，却为大逆！",
  ["$changshi__hankui_taunt1"] = "切！宁享短福，莫为汝等庸奴！",
  ["$changshi__lisong_taunt1"] = "区区不才，可为帝之耳目，试问汝有何能？",
  ["$changshi__duangui_taunt1"] = "哼，不过襟裾牛马，衣冠狗彘尓！",
  ["$changshi__guosheng_taunt1"] = "此昏聩之徒，吾羞与为伍。",
  ["$changshi__gaowang_taunt1"] = "若非吾之相助，汝安有今日？",
}

shichangshi:addSkill(danggu)

local mowang = fk.CreateTriggerSkill{
  name = "mowang",
  frequency = Skill.Compulsory,
  anim_type = "negative",
  events = {fk.BeforeGameOverJudge, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if event == fk.BeforeGameOverJudge then
      return
        target == player and
        player:hasSkill(self, false, true) and
        player:hasSkill("danggu", true, true) and
        type(player.tag["changshi_cards"]) == "table" and
        #player.tag["changshi_cards"] > 0 and
        player.maxHp > 0
    else
      return target == player and player:hasSkill(self)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.BeforeGameOverJudge then
      player._splayer:setDied(false)
      room:setPlayerRest(player, 1)
    else
      room:killPlayer({ who = player.id })
    end
  end,
}

shichangshi:addSkill(mowang)
Fk:loadTranslationTable{
  ["mowang"] = "殁亡",
  [":mowang"] = "锁定技，当你即将死亡时，若你拥有技能“党锢”且你仍有未亮出的“常侍”牌，则改为休整一轮；回合结束时，你死亡。",
}

for generalName, _  in pairs(tenChangShiMapper) do
  local changshi = General(extension, generalName, "qun", 0)
  changshi.total_hidden = true
  changshi:addSkill("danggu")
  changshi:addSkill("mowang")
end

local mobile__yanxiang = General(extension, "mobile__yanxiang", "qun", 3)

local kujian = fk.CreateActiveSkill{
  name = "kujian",
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  max_card_num = 3,
  min_card_num = 1,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and #selected < 2
  end,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    table.forEach(effect.cards, function(cid)
      room:setCardMark(Fk:getCardById(cid), "@@kujian", 1)
    end)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false, effect.from)
  end,
}
local kujian_judge = fk.CreateTriggerSkill{
  name = "#kujian_judge",
  events = {fk.CardUsing, fk.CardResponding, fk.AfterCardsMove},
  anim_type = "drawcard",
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event ~= fk.AfterCardsMove then
      if player == target then return false end
      return table.find(Card:getIdList(data.card), function(id)
        return Fk:getCardById(id):getMark("@@kujian") > 0
      end)
    else
      for _, move in ipairs(data) do
        if move.from ~= player.id and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
          if table.find(move.moveInfo, function(info)
            return Fk:getCardById(info.cardId):getMark("@@kujian") > 0 and info.fromArea == Card.PlayerHand
          end) then
            return true
          end
        end
      end
    end
    return false
  end,
  on_trigger = function(self, event, target, player, data)
    if event ~= fk.AfterCardsMove then
      self:doCost(event, target, player, data)
    else
      local room = player.room
      local targets = {}
      for _, move in ipairs(data) do
        if move.from ~= player.id and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@kujian") > 0 and info.fromArea == Card.PlayerHand then
              table.insert(targets, move.from)
            end
          end
        end
      end
      room:sortPlayersByAction(targets)
      for _, target_id in ipairs(targets) do
        if not player:hasSkill(self) then break end
        local skill_target = room:getPlayerById(target_id)
        if skill_target and not skill_target.dead and not player.dead and not (skill_target:isNude() and player:isNude()) then
          self:doCost(event, skill_target, player, data)
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("kujian")
    if event ~= fk.AfterCardsMove then
      room:notifySkillInvoked(player, "kujian", "drawcard")
      table.forEach(Card:getIdList(data.card), function(id)
        return room:setCardMark(Fk:getCardById(id), "@@kujian", 0)
      end)
      room:doIndicate(player.id, {target.id})
      player:drawCards(2, self.name)
      target:drawCards(2, self.name)
    else
      room:notifySkillInvoked(player, "kujian", "negative")
      room:doIndicate(player.id, {target.id})
      for _, move in ipairs(data) do
        if move.from ~= player.id and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              room:setCardMark(Fk:getCardById(info.cardId), "@@kujian", 0)
            end
          end
        end
      end
      room:askForDiscard(player, 1, 1, true, self.name, false, nil, "#kujian-discard")
      room:askForDiscard(target, 1, 1, true, self.name, false, nil, "#kujian-discard")
    end
  end,
  
  --[[
    refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea ~= Card.Processing and move.toArea ~= Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId):getMark("@@kujian") > 0 then
            room:setCardMark(Fk:getCardById(info.cardId), "@@kujian", 0)
          end
        end
      end
    end
  end,
  --]]
}
kujian:addRelatedSkill(kujian_judge)

local ruilian = fk.CreateTriggerSkill{
  name = "ruilian",
  events = {fk.RoundStart, fk.TurnEnd},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (event == fk.RoundStart or (tonumber(target:getMark("@ruilian-turn")) > 0 and table.contains(target:getMark("_ruilianGiver"), player.id)))
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.RoundStart then
      local target = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1, "#ruilian-ask", self.name, true)
      if #target > 0 then
        self.cost_data = target[1]
        return true
      end
    else
      local cids = target:getMark("_ruilianCids-turn")
      local cardType = {}
      table.forEach(cids, function(cid)
        table.insertIfNeed(cardType, Fk:getCardById(cid):getTypeString())
      end)
      table.insert(cardType, "Cancel")
      local choice = player.room:askForChoice(player, cardType, self.name, "#ruilian-type:" .. target.id)
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      local target = room:getPlayerById(self.cost_data)
      room:setPlayerMark(target, "@@ruilian", 1)
      local ruilianGiver = type(target:getMark("_ruilianGiver")) == "table" and target:getMark("_ruilianGiver") or {}
      table.insertIfNeed(ruilianGiver, player.id)
      room:setPlayerMark(target, "_ruilianGiver", ruilianGiver)
    else
      local id = room:getCardsFromPileByRule(".|.|.|.|.|" .. self.cost_data, 1, "discardPile")
      if #id > 0 then
        room:obtainCard(player, id[1], false, fk.ReasonPrey)
      end
      id = room:getCardsFromPileByRule(".|.|.|.|.|" .. self.cost_data, 1, "discardPile")
      if #id > 0 then
        room:obtainCard(target, id[1], false, fk.ReasonPrey)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    if player ~= player.room.current then return false end
    if event == fk.AfterCardsMove then
      if player:getMark("@ruilian-turn") == 0 then return false end
      local cids = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.insert(cids, info.cardId)
            end
          end
        end
      end
      if #cids > 0 then
        --self.cost_data = cids
        return true
      end
      return false
    else
      return target == player and player:getMark("@@ruilian") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local cids = type(player:getMark("_ruilianCids-turn")) == "table" and player:getMark("_ruilianCids-turn") or {}
      local otherCids = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.insert(otherCids, info.cardId)
            end
          end
        end
      end
      table.insertTable(cids, otherCids)
      room:setPlayerMark(player, "_ruilianCids-turn", cids)
      room:setPlayerMark(player, "@ruilian-turn", #player:getMark("_ruilianCids-turn"))
    else
      room:setPlayerMark(player, "@ruilian-turn", "0")
      room:setPlayerMark(player, "@@ruilian", 0)
    end
  end,
}

mobile__yanxiang:addSkill(kujian)
mobile__yanxiang:addSkill(ruilian)

Fk:loadTranslationTable{
  ["mobile__yanxiang"] = "阎象",
  ["#mobile__yanxiang"] = "明尚夙达",
  ["kujian"] = "苦谏",
  [":kujian"] = "出牌阶段限一次，你可将至多两张手牌标记为“谏”并交给一名其他角色。当其他角色使用或打出“谏”牌时，你与其各摸两张牌。当其他角色非因使用或打出从手牌区失去“谏”牌后，你与其各弃置一张牌。",
  ["ruilian"] = "睿敛",
  [":ruilian"] = "每轮开始时，你可选择一名角色，其下个回合结束前，若其此回合弃置过牌，你可选择其此回合弃置过的牌中的一种类别，你与其各从弃牌堆中获得一张此类别的牌。",

  ["#kujian-discard"] = "苦谏：请弃置一张牌",
  ["#kujian_judge"] = "苦谏",
  ["#ruilian-ask"] = "你可对一名角色发动“睿敛”",
  ["@@ruilian"] = "睿敛",
  ["@ruilian-turn"] = "睿敛",
  ["#ruilian-type"] = "睿敛：你可选择 %src 此回合弃置过的牌中的一种类别，你与其各从弃牌堆中获得一张此类别的牌",
  ["@@kujian"] = "谏",

  ["$kujian1"] = "吾之所言，皆为公之大业。",
  ["$kujian2"] = "公岂徒有纳谏之名乎！",
  ["$kujian3"] = "明公虽奕世克昌，未若有周之盛。",
  ["$ruilian1"] = "公若擅进庸肆，必失民心！",
  ["$ruilian2"] = "外敛虚进之势，内减弊民之政。",
  ["~mobile__yanxiang"] = "若遇明主，或可青史留名……",
}

local nanhualaoxian = General(extension, "nanhualaoxian", "qun", 3)

local yufeng = fk.CreateActiveSkill{
  name = "mobile__yufeng",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  prompt = "#mobile__yufeng-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local maxScore = math.random() <= 0.6 and 3 or 2
    local score = 0
    local findBig = math.random() < 0.5
    local cardsRevealed = {}
    for i = 1, maxScore + 1 do
      if #room.draw_pile + #room.discard_pile == 0 then
        break
      end

      local choice
      if i > 1 then
        local lastNumber = Fk:getCardById(cardsRevealed[i - 1]):getNumberStr()
        choice = room:askForChoice(
          player,
          {"mobile__yufeng_more:::" .. lastNumber, "mobile__yufeng_less:::" .. lastNumber},
          self.name,
          "#mobile__yufeng-choice"
        )
      end

      local cardToReveal
      local randomNum = math.random()
      if randomNum <= 0.7 or i == 1 then
        local numberToApproach = findBig and 13 or 1
        local minDiff = 99
        for _, id in ipairs(room.discard_pile) do
          local cardNumber = Fk:getCardById(id).number
          if cardNumber == numberToApproach then
            cardToReveal = id
            minDiff = 0
            break
          elseif math.abs(cardNumber - numberToApproach) < minDiff then
            cardToReveal = id
            minDiff = math.abs(cardNumber - numberToApproach)
          end
        end
        if minDiff > 0 then
          for _, id in ipairs(room.draw_pile) do
            local cardNumber = Fk:getCardById(id).number
            if cardNumber == numberToApproach then
              cardToReveal = id
              break
            elseif math.abs(cardNumber - numberToApproach) < minDiff then
              cardToReveal = id
              minDiff = math.abs(cardNumber - numberToApproach)
            end
          end
        end

        findBig = not findBig
      elseif randomNum > 0.7 and randomNum <= 0.95 then
        for i = 1, 3 do
          local randomIndex = math.random(1, #room.draw_pile + #room.discard_pile)
          if randomIndex <= #room.draw_pile then
            cardToReveal = room.draw_pile[randomIndex]
          else
            cardToReveal = room.discard_pile[randomIndex - #room.draw_pile]
          end

          if not table.contains({6, 7, 8}, Fk:getCardById(cardToReveal).number) then
            break
          end
        end

        local numberFound = Fk:getCardById(cardToReveal).number
        findBig = math.abs(numberFound - 13) > math.abs(numberFound - 1)
      else
        local randomMidNumber = math.random(6, 8)
        for _, id in ipairs(room.discard_pile) do
          if Fk:getCardById(id).number == randomMidNumber then
            cardToReveal = id
            break
          end
        end
        if not cardToReveal then
          for _, id in ipairs(room.draw_pile) do
            if Fk:getCardById(id).number == randomMidNumber then
              cardToReveal = id
              break
            end
          end
        end

        if not cardToReveal then
          local randomIndex = math.random(1, #room.draw_pile + #room.discard_pile)
          if randomIndex <= #room.draw_pile then
            cardToReveal = room.draw_pile[randomIndex]
          else
            cardToReveal = room.discard_pile[randomIndex - #room.draw_pile]
          end

          local numberFound = Fk:getCardById(cardToReveal).number
          findBig = math.abs(numberFound - 13) > math.abs(numberFound - 1)
        else
          findBig = math.random() <= 0.5
        end
      end

      table.insert(cardsRevealed, cardToReveal)

      local curNumber = Fk:getCardById(cardToReveal).number
      room:moveCards{
        ids = { cardToReveal },
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      if choice then
        local lastNumber = Fk:getCardById(cardsRevealed[i - 1]).number
        if
          (choice:startsWith("mobile__yufeng_more") and lastNumber >= curNumber) or
          (choice:startsWith("mobile__yufeng_less") and lastNumber <= curNumber)
        then
          room:setCardEmotion(cardToReveal, "judgebad")
          room:delay(1000)
          break
        else
          score = score + 1
          room:setCardEmotion(cardToReveal, "judgegood")
        end
      end
      room:delay(1000)
    end

    if #cardsRevealed == 0 then
      return
    end

    cardsRevealed = table.filter(cardsRevealed, function(id) return room:getCardArea(id) == Card.Processing end)
    if #cardsRevealed > 0 then
      room:moveCards({
        ids = cardsRevealed,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end

    local chatStr = "score_full"
    if score == 0 then
      chatStr = "score_zero"
    elseif score == 1 then
      chatStr = "score_one"
    elseif score < maxScore then
      chatStr = "score_not_full"
    end
    player:chat(Fk:translate(chatStr))

    if not (score < maxScore and math.random() < 0.2) then
      local tos = player.room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, score,
      "#mobile__yufeng-choose:::" .. score, self.name, true)
      for _, pid in ipairs(tos) do
        room:setPlayerMark(room:getPlayerById(pid), "@@mobile__yufeng", 1)
      end
      score = score - #tos
    end
    if score > 0 then
      player:drawCards(score, self.name)
    end
  end,
}
local yufeng_delay = fk.CreateTriggerSkill{
  name = "#mobile__yufeng_delay",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Start and player:getMark("@@mobile__yufeng") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = "mobile__yufeng",
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if judge.card.color == Card.Black then
      player:skip(Player.Play)
      player:skip(Player.Discard)
    elseif judge.card.color == Card.Red then
      player:skip(Player.Draw)
    end
    room:setPlayerMark(player, "@@mobile__yufeng", 0)
  end,
}
yufeng:addRelatedSkill(yufeng_delay)
nanhualaoxian:addSkill(yufeng)

local peace_spell = {{"js__peace_spell", Card.Heart, 3}}
local tianshu = fk.CreateTriggerSkill{
  name = "mobile__tianshu",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(self) and player.phase == Player.Play and not player:isNude() then
      local spell = U.prepareDeriveCards(player.room, peace_spell, "mobile__tianshu_spell")[1]
      return table.contains({Card.Void, Card.DrawPile, Card.DiscardPile}, player.room:getCardArea(spell))
    end
  end,
  on_cost = function (self, event, target, player, data)
    local ids = table.filter(player:getCardIds("he"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)
    local tos, cid = player.room:askForChooseCardAndPlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1, 
    tostring(Exppattern{ id = ids }), "#mobile__tianshu-invoke", self.name, true)
    if #tos == 1 and cid then
      self.cost_data = {tos[1], cid}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    room:throwCard(self.cost_data[2], self.name, player, player)
    local spell = U.prepareDeriveCards(room, peace_spell, "mobile__tianshu_spell")[1]
    if not to.dead and table.contains({Card.Void, Card.DrawPile, Card.DiscardPile}, room:getCardArea(spell)) then
      room:moveCardTo(spell, Player.Hand, to, fk.ReasonPrey, self.name)
      local c = Fk:getCardById(spell)
      if table.contains(to:getCardIds("h"), spell) and c.name == "js__peace_spell" and to:canUseTo(c, to) then
        room:useCard{from = player.id, tos = {{to.id}}, card = c}
      end
    end
  end,
}
nanhualaoxian:addSkill(tianshu)

local mobile__nanhualaoxian_win = fk.CreateActiveSkill{ name = "nanhualaoxian_win_audio" }
mobile__nanhualaoxian_win.package = extension
Fk:addSkill(mobile__nanhualaoxian_win)

Fk:loadTranslationTable{
  ["nanhualaoxian"] = "南华老仙",
  ["#nanhualaoxian"] = "冯虚御风",
  ["cv:nanhualaoxian"] = "宋国庆",
  ["illustrator:nanhualaoxian"] = "君桓文化",

  ["mobile__yufeng"] = "御风",
  [":mobile__yufeng"] = "出牌阶段限一次，你可以进行一次御风飞行。若失败你摸X张牌；若成功，则你可选择至多X名其他角色，" ..
  "其下一个准备阶段进行一次判定：若结果为黑色，其跳过接下来的出牌和弃牌阶段；若结果为红色，其跳过接下来的摸牌阶段" ..
  "（若选择角色数不足X，剩余的分数改为摸等量张牌）（X为御风飞行得分，至多为3）。" ..
  "<br/><font color='grey'>#\"<b>御风飞行</b>\"：随机亮出牌堆和弃牌堆中的一张牌，然后重复猜测下一张亮出的牌比上一张亮出的牌点数更大或更小，" ..
  "直到达到分数上限或猜错（2分或3分），每猜对一次得一分。",
  ["#mobile__yufeng-prompt"] = "你可玩一次小游戏，成功后令他人跳过摸牌或出牌弃牌阶段",
  ["#mobile__yufeng-choose"] = "御风：选择至多 %arg 名其他角色，其下回合跳过摸牌或出牌弃牌阶段",
  ["@@mobile__yufeng"] = "御风",
  ["#mobile__yufeng_delay"] = "御风",
  ["mobile__yufeng_more"] = "下一张牌点数比%arg大",
  ["mobile__yufeng_less"] = "下一张牌点数比%arg小",
  ["#mobile__yufeng-choice"] = "御风：猜测下一张牌的点数",
  ["score_zero"] = "惜哉，未能窥见星辰。",
  ["score_one"] = "风紧，赶紧跑。",
  ["score_not_full"] = "星辰已纳入囊中。",
  ["score_full"] = "满载而归，哈哈。",

  ["mobile__tianshu"] = "天书",
  [":mobile__tianshu"] = "出牌阶段开始时，若【太平要术】不在游戏内、在牌堆或弃牌堆中，你可以弃置一张牌，令一名角色获得【太平要术】并使用之。",
  ["#mobile__tianshu-invoke"] = "天书：你可弃置一张牌，令一名角色获得【太平要术】并使用",
  
  ["$mobile__yufeng1"] = "广开兮天门，纷吾乘兮玄云。",
  ["$mobile__yufeng2"] = "高飞兮安翔，乘清气兮御阴阳。",
  ["$mobile__tianshu1"] = "其耆欲深者，其天机浅。",
  ["$mobile__tianshu2"] = "杀生者不死，生生者不生。",
  ["$nanhualaoxian_win_audio"] = "纷总总兮九州，何寿夭兮在予？",
  ["~nanhualaoxian"] = "天机求而近，执而远……",
}


return extension
