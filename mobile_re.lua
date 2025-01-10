local extension = Package("mobile_re")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["mobile_re"] = "手杀-专属",
}

local U = require "packages/utility/utility"

-- 手杀标准包修改

local mobile__yuanshu = General(extension, "mobile__yuanshu", "qun", 4)
local mobile__wangzun = fk.CreateTriggerSkill{
  name = "mobile__wangzun",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Start and player:hasSkill(self) and target.hp > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local isLord = target.role_shown and target.role == "lord"
    if isLord then
      player.room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn)
    end
    player:drawCards(isLord and 2 or 1, self.name)
  end,
}
local mobile__tongji = fk.CreateTriggerSkill{
  name = "mobile__tongji",
  events = {fk.TargetConfirming},
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target:inMyAttackRange(player) and data.from ~= player.id
    and data.card and data.card.trueName == "slash" and not target:isNude()
    and not table.contains(AimGroup:getAllTargets(data.tos), player.id)
  end,
  on_cost = function (self, event, target, player, data)
    local cards = player.room:askForDiscard(target, 1, 1, true, self.name, true, ".", "#mobile__tongji-cost:"..player.id, true)
    if #cards > 0 then
      self.cost_data = {cards = cards, tos = {target.id}}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data.cards, self.name, target, target)
    AimGroup:cancelTarget(data, target.id)
    AimGroup:addTargets(room, data, player.id)
  end,
}

mobile__yuanshu:addSkill(mobile__wangzun)
mobile__yuanshu:addSkill(mobile__tongji)

Fk:loadTranslationTable{
  ["mobile__yuanshu"] = "袁术",
  ["#mobile__yuanshu"] = "野心渐增",
  ["illustrator:mobile__yuanshu"] = "叶子", -- 精良皮肤:高自期许

  ["mobile__wangzun"] = "妄尊",
  [":mobile__wangzun"] = "锁定技，体力值大于你的角色的准备阶段，你摸一张牌（若其为主公或地主，你额外摸一张牌且其本回合的手牌上限-1）。",
  ["mobile__tongji"] = "同疾",
  [":mobile__tongji"] = "当其他角色成为【杀】的目标时，若你在其攻击范围内，且你不是此【杀】的使用者，其可弃置一张牌将此【杀】转移给你。",
  ["#mobile__tongji-cost"] = "同疾：你可以弃置一张牌，将【杀】转移给 %src",

  ["$mobile__wangzun1"] = "这玉玺，当然是能者居之。",
  ["$mobile__wangzun2"] = "我就是皇帝，我就是天！",
  ["$mobile__tongji1"] = "嗯额，反了！反了！反了！",
  ["$mobile__tongji2"] = "冒犯天威，大逆不道！",
  ["~mobile__yuanshu"] = "嗯哼，没……没有蜜水了……",
}

-- 手杀界标包修改

local zhangfei = General(extension, "m_ex__zhangfei", "shu", 4)
local liyong = fk.CreateTriggerSkill{
  name = "liyong",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@liyong-phase", 1)
  end,
}
local liyong_delay = fk.CreateTriggerSkill{
  name = "#liyong_delay",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified, fk.DamageCaused, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target and target == player then
      if event == fk.TargetSpecified then
        return data.card.trueName == "slash" and player:getMark("@@liyong-phase") > 0
      elseif data.card and data.card.trueName == "slash" then
        if player.room.logic:damageByCardEffect() then
          local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
          if use_event == nil then return end
          local use = use_event.data[1]
          if use.extra_data and use.extra_data.liyong then
            if event == fk.Damage then
              return true
            else
              return use.extra_data.liyong == player.id and not data.to.dead and not player.dead
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      player:broadcastSkillInvoke("liyong")
      room:notifySkillInvoked(player, "liyong", "offensive")
      room:setPlayerMark(player, "@@liyong-phase", 0)
      data.extra_data = data.extra_data or {}
      data.extra_data.liyong = player.id
      data.disresponsiveList = data.disresponsiveList or {}
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        local p = room:getPlayerById(id)
        if not p.dead then
          room:addPlayerMark(p, MarkEnum.UncompulsoryInvalidity.."-turn", 1)
          table.insertIfNeed(data.disresponsiveList, id)
        end
      end
    elseif event == fk.DamageCaused then
      data.damage = data.damage + 1
    elseif event == fk.Damage then
      room:loseHp(player, 1, "liyong")
    end
  end,
}
liyong:addRelatedSkill(liyong_delay)
zhangfei:addSkill("os_ex__paoxiao")
zhangfei:addSkill(liyong)
Fk:loadTranslationTable{
  ["m_ex__zhangfei"] = "界张飞",
  ["#m_ex__zhangfei"] = "万夫不当",
  ["illustrator:m_ex__zhangfei"] = "木美人",

  ["liyong"] = "厉勇",
  [":liyong"] = "锁定技，当你于出牌阶段使用的【杀】被【闪】抵消后，你本阶段使用下一张【杀】指定目标后，目标非锁定技失效直到回合结束，此【杀】"..
  "不可被响应且对目标角色造成伤害+1；此【杀】造成伤害后，若目标角色未死亡，你失去1点体力。",
  ["@@liyong-phase"] = "厉勇",
  ["#liyong_delay"] = "厉勇",
}

local xiahoudun = General(extension, "m_ex__xiahoudun", "wei", 4)
local qingjian = fk.CreateTriggerSkill{
  name = "m_ex__qingjian",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and player.phase ~= Player.Draw
     and not player:isKongcheng() then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand and move.skillName ~= self.name then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForCard(player, 1, 9999, false, self.name, true, ".", "#m_ex__qingjian-cost")
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("ex__qingjian")
    player:addToPile("$m_ex__qingjian", self.cost_data, false, self.name)
  end,
}
local qingjian_delay = fk.CreateTriggerSkill{
  name = "#m_ex__qingjian_delay",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and #player:getPile("$m_ex__qingjian") > 0
    and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getPile("$m_ex__qingjian")
    local move = room:askForYiji(player, cards, room:getOtherPlayers(player, false), "m_ex__qingjian",
    #cards, #cards, nil, "$m_ex__qingjian", true)
    player:broadcastSkillInvoke("ex__qingjian")
    cards = room:doYiji(move, player.id, "m_ex__qingjian")
    if #cards > 1 and not player.dead then
      player:drawCards(1, "m_ex__qingjian")
    end
  end,
}
qingjian:addRelatedSkill(qingjian_delay)
xiahoudun:addSkill("ex__ganglie")
xiahoudun:addSkill(qingjian)
Fk:loadTranslationTable{
  ["m_ex__xiahoudun"] = "界夏侯惇",
  ["#m_ex__xiahoudun"] = "独眼的罗刹",
  ["illustrator:m_ex__xiahoudun"] = "木美人", -- 皮肤:浴血奋战

  ["m_ex__qingjian"] = "清俭",
  [":m_ex__qingjian"] = "每回合限一次，当你于你的摸牌阶段外获得牌后，你可以将任意张手牌扣置于你的武将牌上；一名角色的结束阶段，若你的武将牌上"..
  "有“清俭”牌，你将这些牌分配给其他角色，若交出的牌大于一张，你摸一张牌。",
  ["#m_ex__qingjian-cost"] = "清俭：你可以将任意张手牌扣置于你的武将牌上",
  ["#m_ex__qingjian_delay"] = "清俭",
  ["$m_ex__qingjian"] = "清俭",
}

local huatuo = General(extension, "m_ex__huatuo", "qun", 3)
local qingnang = fk.CreateActiveSkill{
  name = "m_ex__qingnang",
  anim_type = "support",
  prompt = "#m_ex__qingnang",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and table.contains(Self:getCardIds("h"), to_select) and not Self:prohibitDiscard(to_select)
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):isWounded()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addTableMark(player, "m_ex__qingnang-phase", target.id)
    local yes = Fk:getCardById(effect.cards[1]).color == Card.Red
    room:throwCard(effect.cards, self.name, player, player)
    if target:isWounded() and not target.dead then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    end
    if yes and not player.dead and not player:isKongcheng() then
      local targets = table.filter(room.alive_players, function (p)
        return p:isWounded() and not table.contains(player:getTableMark("m_ex__qingnang-phase"), p.id)
      end)
      if #targets > 0 then
        targets = table.map(targets, Util.IdMapper)
        room:askForUseActiveSkill(player, self.name, "#m_ex__qingnang-invoke", true, {exclusive_targets = targets})
      end
    end
  end,
}
huatuo:addSkill("jijiu")
huatuo:addSkill(qingnang)
Fk:loadTranslationTable{
  ["m_ex__huatuo"] = "界华佗",
  ["#m_ex__huatuo"] = "神医",
  ["illustrator:m_ex__huatuo"] = "刘小狼Syaoran",

  ["m_ex__qingnang"] = "青囊",
  [":m_ex__qingnang"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名已受伤角色，令其回复1点体力。若弃置的牌为红色，你可以再对本阶段"..
  "未选择过的角色发动〖青囊〗。",
  ["#m_ex__qingnang"] = "青囊：弃置一张手牌，令一名角色回复1点体力，若弃置了红色牌则可以继续发动",
  ["#m_ex__qingnang-invoke"] = "青囊：你可以继续对本阶段未选择过的角色发动“青囊”",

  ["$m_ex__qingnang1"] = "普济众生，乃行医本分。",
  ["$m_ex__qingnang2"] = "先来一剂补药。",
  ["$jijiu_m_ex__huatuo1"] = "救死扶伤，悬壶济世。",
  ["$jijiu_m_ex__huatuo2"] = "妙手仁心，药到病除。",
  ["~m_ex__huatuo"] = "生老病死，命不可违。",
}


local yuanshu = General(extension, "m_ex__yuanshu", "qun", 4)
local yongsi = fk.CreateTriggerSkill{
  name = "m_ex__yongsi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.DrawNCards then
        return true
      else
        return player.phase == Player.Discard
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DrawNCards then
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      data.n = #kingdoms
    else
      if player:isNude() or #room:askForDiscard(player, 1, 1, true, self.name, true, nil, "#m_ex__yongsi-discard") == 0 then
        room:loseHp(player, 1, self.name)
      end
    end
  end,
}
local jixiy = fk.CreateTriggerSkill{
  name = "jixiy",
  frequency = Skill.Wake,
  events = {fk.AfterTurnEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local room = player.room
    local dat = {}
    local turn_events = room.logic:getEventsByRule(GameEvent.Turn, 3, function (e)
      if e.data[1] == player then
        if e.end_id < 0 then
          table.insert(dat, {e.id, room.logic.current_event_id + 1})  --当前回合的end_id还是-1……
        else
          table.insert(dat, {e.id, e.end_id})
        end
        return true
      end
    end, 1)
    if #turn_events < 3 then return end
    return #room.logic:getEventsByRule(GameEvent.LoseHp, 1, function (e)
      if e.data[1] == player and table.find(dat, function (ids)
        return e.id > ids[1] and e.id < ids[2]
      end) then
        return true
      end
    end, dat[1][1]) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = self.name,
      }
    end
    if player.dead then return end
    local choice = room:askForChoice(player, {"jixiy1", "jixiy2"}, self.name)
    if choice == "jixiy1" then
      room:handleAddLoseSkills(player, "mobile__wangzun", nil, true, false)
    else
      player:drawCards(2, self.name)
      if player.dead then return end
      local skills = {}
      for _, p in ipairs(room.alive_players) do
        if p ~= player and p.role == "lord" then
          for _, s in ipairs(p.player_skills) do
            if s.lordSkill and not player:hasSkill(s, true)  then
              table.insert(skills, s.name)
            end
          end
        end
      end
      if #skills > 0 then
        room:handleAddLoseSkills(player, table.concat(skills, "|"), nil)
      end
    end
  end,
}
yuanshu:addSkill(yongsi)
yuanshu:addSkill(jixiy)
yuanshu:addRelatedSkill("mobile__wangzun")
Fk:loadTranslationTable{
  ["m_ex__yuanshu"] = "界袁术",
  ["#m_ex__yuanshu"] = "仲家帝",
  ["illustrator:m_ex__yuanshu"] = "魔奇士", -- 史诗皮肤:登极至尊

  ["m_ex__yongsi"] = "庸肆",
  [":m_ex__yongsi"] = "锁定技，摸牌阶段，你改为摸X张牌（X为全场势力数）；弃牌阶段开始时，你需弃置一张牌，否则失去1点体力。",
  ["jixiy"] = "觊玺",
  [":jixiy"] = "觉醒技，回合结束后，若你连续三个自己的回合未失去过体力，你加1点体力上限，回复1点体力，然后选择一项：1.获得技能〖妄尊〗；"..
  "2.摸两张牌，然后获得主公的主公技。",
  ["#m_ex__yongsi-discard"] = "庸肆：你需弃置一张牌，否则失去1点体力",
  ["jixiy1"] = "获得技能“妄尊”",
  ["jixiy2"] = "摸两张牌，获得主公的主公技",

  ["$m_ex__yongsi1"] = "乱世之中，必出枭雄。",
  ["$m_ex__yongsi2"] = "得此玉玺，是为天助！",
  ["$jixiy1"] = "朕是开国之君，哈哈哈哈哈哈……",
  ["$jixiy2"] = "受命于天，既寿永昌。",
  ["$mobile__wangzun_m_ex__yuanshu1"] = "四世三公算什么？朕乃九五至尊！",
  ["$mobile__wangzun_m_ex__yuanshu2"] = "追随我的人，都是开国元勋！",
  ["~m_ex__yuanshu"] = "朕，要千秋万代……",
}

-- 一将

local jikang = General(extension, "mobile__jikang", "wei", 3)

local mobile__qingxian = fk.CreateActiveSkill{
  name = "mobile__qingxian",
  anim_type = "control",
  min_card_num = 1,
  min_target_num = 1,
  prompt = "#mobile__qingxian",
  card_filter = function(self, to_select, selected)
    return #selected < Self.hp and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return Self.id ~= to_select and #selected < #selected_cards
  end,
  feasible = function(self, selected, selected_cards)
    return #selected >= 1 and #selected == #selected_cards
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player.hp > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local targets = table.map(effect.tos, Util.Id2PlayerMapper)
    local numMap = {}
    for _, p in ipairs(targets) do
      numMap[p.id] = #p:getCardIds("e") - #player:getCardIds("e")
    end
    local draw = #targets == player.hp
    room:throwCard(effect.cards, self.name, player, player)
    for _, p in ipairs(targets) do
      if not p.dead then
        if numMap[p.id] > 0 then
          room:loseHp(p, 1, self.name)
        elseif numMap[p.id] == 0 then
          p:drawCards(1, self.name)
        else
          room:recover { num = 1, skillName = self.name, who = p, recoverBy = player }
        end
      end
    end
    if draw and not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
jikang:addSkill(mobile__qingxian)

local mobile__juexiang = fk.CreateTriggerSkill{
  name = "mobile__juexiang",
  anim_type = "offensive",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self, false, true) and target == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = (data.damage or {}).from
    if from and not from.dead then
      from:throwAllCards("e")
      if not from.dead then
        room:loseHp(from, 1, self.name)
      end
    end
    local targets = room:getOtherPlayers(player, false)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#mobile__juexiang-choose", self.name, true)
    if #tos > 0 then
      local to = room:getPlayerById(tos[1])
      room:handleAddLoseSkills(to, "mobile__canyun")
      targets = table.filter(room.alive_players, function (p)
        return table.find(p:getCardIds("ej"), function(id) return Fk:getCardById(id).suit == Card.Club end)
      end)
      if #targets == 0 then return end
      tos = room:askForChoosePlayers(to, table.map(targets, Util.IdMapper), 1, 1, "#mobile__juexiang-throw", self.name, true)
      if #tos > 0 then
        local second = room:getPlayerById(tos[1])
        local card_data = {}
        local equip = table.filter(second:getCardIds("e"), function(id) return Fk:getCardById(id).suit == Card.Club end)
        if #equip > 0 then
          table.insert(card_data, { "$Equip", equip })
        end
        local judge = table.filter(second:getCardIds("j"), function(id) return Fk:getCardById(id).suit == Card.Club end)
        if #judge > 0 then
          table.insert(card_data, { "$Judge", judge })
        end
        local card = room:askForCardChosen(to, second, { card_data = card_data }, self.name)
        room:throwCard(card, self.name, second, to)
        room:handleAddLoseSkills(to, "mobile__juexiang")
      end
    end
  end,
}
jikang:addSkill(mobile__juexiang)

local mobile__canyun = fk.CreateActiveSkill{
  name = "mobile__canyun",
  anim_type = "control",
  min_card_num = 1,
  min_target_num = 1,
  prompt = "#mobile__qingxian",
  card_filter = function(self, to_select, selected)
    return #selected < Self.hp and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return Self.id ~= to_select and #selected < #selected_cards
    and not table.contains(Self:getTableMark(self.name), to_select)
  end,
  feasible = function(self, selected, selected_cards)
    return #selected >= 1 and #selected == #selected_cards
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player.hp > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local mark = player:getTableMark(self.name)
    table.insertTable(mark, effect.tos)
    room:setPlayerMark(player, self.name, mark)
    local targets = table.map(effect.tos, Util.Id2PlayerMapper)
    local numMap = {}
    for _, p in ipairs(targets) do
      numMap[p.id] = #p:getCardIds("e") - #player:getCardIds("e")
    end
    local draw = #targets == player.hp
    room:throwCard(effect.cards, self.name, player, player)
    for _, p in ipairs(targets) do
      if not p.dead then
        if numMap[p.id] > 0 then
          room:loseHp(p, 1, self.name)
        elseif numMap[p.id] == 0 then
          p:drawCards(1, self.name)
        else
          room:recover { num = 1, skillName = self.name, who = p, recoverBy = player }
        end
      end
    end
    if draw and not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
jikang:addRelatedSkill(mobile__canyun)

Fk:loadTranslationTable{
  ["mobile__jikang"] = "嵇康",
  ["#mobile__jikang"] = "峻峰孤松",
  ["illustrator:mobile__jikang"] = "黑羽", -- 稀有皮:肃肃如风

  ["mobile__qingxian"] = "清弦",
  [":mobile__qingxian"] = "出牌阶段限一次，你可以选择至多X名其他角色并弃置等量的牌（X为你的体力值），若这些角色装备区内的牌数：小于你，其回复1点体力；大于你，其失去1点体力；等于你，其摸一张牌。若你选择的目标数等于X，你摸一张牌。",
  ["#mobile__qingxian"] = "选择至多体力值名其他角色并弃等量牌：装备数大于你的掉血，等于摸牌，小于回血",

  ["mobile__juexiang"] = "绝响",
  [":mobile__juexiang"] = "当你死亡时，杀死你的角色弃置装备区里的所有牌并失去1点体力，然后你可以令一名其他角色获得技能“残韵”，且该角色可以弃置场上一张♣牌，若其如此做，其获得技能“绝响”。",
  ["#mobile__juexiang-choose"] = "绝响：你可以令一名其他角色获得技能“残韵”",
  ["#mobile__juexiang-throw"] = "绝响：你可以可以弃置场上一张♣牌，并获得技能“绝响”",

  ["mobile__canyun"] = "残韵",
  [":mobile__canyun"] = "出牌阶段限一次，你可以选择至多X名其他角色并弃置等量的牌（X为你的体力值，且每名角色每局游戏限一次），若这些角色装备区内的牌数：小于你，其回复1点体力；大于你，其失去1点体力；等于你，其摸一张牌。若你选择的目标数等于X，你摸一张牌。",

  ["$mobile__qingxian1"] = "弹琴则明己性，听琴如见其人。",
  ["$mobile__qingxian2"] = "弦音自有妙，俗人不可知。",
  ["$mobile__juexiang1"] = "一曲广陵散，从此绝凡尘。",
  ["$mobile__juexiang2"] = "古之琴音，今绝响矣！",
  ["~mobile__jikang"] = "琴声依旧，伴我长眠……",
}

-- SP

local zhanggong = General(extension, "mobile__zhanggong", "wei", 3)

local mobile__qianxinz = fk.CreateActiveSkill{
  name = "mobile__qianxinz",
  anim_type = "offensive",
  min_card_num = 1,
  target_num = 0,
  prompt = "#mobile__qianxinz",
  card_filter = function(self, to_select, selected)
    return table.contains(Self.player_cards[Player.Hand], to_select)
    and #selected < math.min(2, #Fk:currentRoom().alive_players - 1)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local tos = table.random(room:getOtherPlayers(player, false), #effect.cards)
    if #tos ~= #effect.cards then return end
    local moves = {}
    for i, p in ipairs(tos) do
      table.insert(moves, {
        from = player.id,
        to = p.id,
        ids = {effect.cards[i]},
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        skillName = self.name,
        moveVisible = false,
        proposer = player.id,
        moveMark = {"@@mobile__mail-inhand", player.id},
      })
    end
    room:moveCards(table.unpack(moves))
  end,
}

local mobile__qianxinz_trigger = fk.CreateTriggerSkill{
  name = "#mobile__qianxinz_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return target.phase == Player.Start and target ~= player and table.find(target:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@mobile__mail-inhand") == player.id
    end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(target:getCardIds("h")) do
      if Fk:getCardById(id):getMark("@@mobile__mail-inhand") == player.id then
        room:setCardMark(Fk:getCardById(id), "@@mobile__mail-inhand", 0)
      end
    end
    if player.dead then return end
    local sname = "mobile__qianxinz"
    player:broadcastSkillInvoke(sname)
    room:notifySkillInvoked(player, sname, "control")
    room:doIndicate(player.id, {target.id})
    local choice = room:askForChoice(target, {"mobile__qianxinz1:"..player.id, "mobile__qianxinz2"}, sname)
    if choice ~= "mobile__qianxinz2" then
      player:drawCards(2, sname)
    else
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 2)
    end
  end,
}
mobile__qianxinz:addRelatedSkill(mobile__qianxinz_trigger)

zhanggong:addSkill(mobile__qianxinz)

zhanggong:addSkill("zhenxing")

Fk:loadTranslationTable{
  ["mobile__zhanggong"] = "张恭",
  ["#mobile__zhanggong"] = "西域长歌",
  ["illustrator:mobile__zhanggong"] = "B_LEE",
  ["designer:mobile__zhanggong"] = "笔枔",

  ["mobile__qianxinz"] = "遣信",
  [":mobile__qianxinz"] = "出牌阶段限一次，你可以将至多两张手牌随机分配给等量名其他角色各一张，称为“信”，然后该角色的下个准备阶段，若其有“信”，其选择一项：1.令你摸两张牌；2.本回合的手牌上限-2。",
  ["#mobile__qianxinz"] = "遣信：选择至多两张手牌，随机分配给等量名其他角色",
  ["#mobile__qianxinz_trigger"] = "遣信",
  ["@@mobile__mail-inhand"] = "信",
  ["mobile__qianxinz1"] = "%src 摸两张牌",
  ["mobile__qianxinz2"] = "你本回合手牌上限-2",

  ["$mobile__qianxinz1"] = "兵困绝地，将至如归！",
  ["$mobile__qianxinz2"] = "临危之际，速速来援！",
  --["$zhenxing1"] = "东征西讨，募军百里挑一。",
  --["$zhenxing2"] = "众口铄金，积毁销骨。",
  ["~mobile__zhanggong"] = "大漠孤烟，孤立无援啊……",
}


return extension
