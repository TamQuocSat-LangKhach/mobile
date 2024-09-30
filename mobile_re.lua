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
    return target ~= player and player:hasSkill(self) and target:inMyAttackRange(player) and data.from ~= player
    and data.card and data.card.trueName == "slash" and not target:isNude()
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
    player:addToPile(self.name, self.cost_data, false, self.name)
  end,
}
local qingjian_delay = fk.CreateTriggerSkill{
  name = "#m_ex__qingjian_delay",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and #player:getPile("m_ex__qingjian") > 0 and #player.room:getOtherPlayers(player) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local move = room:askForYiji(player, player:getPile("m_ex__qingjian"), room:getOtherPlayers(player), "m_ex__qingjian",
    #player:getPile("m_ex__qingjian"), #player:getPile("m_ex__qingjian"), nil, "m_ex__qingjian", true)
    local cards = room:doYiji(room, move, player.id, "m_ex__qingjian")
    player:broadcastSkillInvoke("ex__qingjian")
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

return extension
