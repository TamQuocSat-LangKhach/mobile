local extension = Package("m_shzl_ex")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["m_shzl_ex"] = "手杀界神话再临",
}
local xunyu = General(extension, "m_ex__xunyu", "wei", 3)
local m_ex__jieming = fk.CreateTriggerSkill{
  name = "m_ex__jieming",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function (p)
      return p.id end), 1, 1, "#m_ex__jieming-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local to = player.room:getPlayerById(self.cost_data)
    to:drawCards(2, self.name)
    if to:getHandcardNum() < to.maxHp then
      player:drawCards(1, self.name)
    end
  end,
}
xunyu:addSkill("quhu")
xunyu:addSkill(m_ex__jieming)
Fk:loadTranslationTable{
  ["m_ex__xunyu"] = "界荀彧",
  ["m_ex__jieming"] = "节命",
  [":m_ex__jieming"] = "当你受到1点伤害后，你可以令一名角色摸两张牌，然后若其手牌数小于其体力上限，你摸一张牌。",

  ["#m_ex__jieming-choose"] = "节命：你可以令一名角色摸两张牌，然后若其手牌数小于其体力上限，你摸一张牌",

  ["$m_ex__jieming1"] = "因势利导，是为良计。",
  ["$m_ex__jieming2"] = "杀身成仁，不负皇恩。",
  ["$quhu_m_ex__xunyu1"] = "驱虎伤敌，保我无虞。",
  ["$quhu_m_ex__xunyu2"] = "无需费我一兵一卒。",
  ["~m_ex__xunyu"] = "命不由人，徒叹奈何……",
}

local caopi = General(extension, "m_ex__caopi", "wei", 3)
local xingshang = fk.CreateTriggerSkill{
  name = "m_ex__xingshang",
  anim_type = "drawcard",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not (target:isNude() and not player:isWounded())
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"m_ex__xingshang_obtain::" .. target.id, "recover", "Cancel"}
    local choices = table.clone(all_choices)
    if not target:isNude() then table.remove(choices, 1) end
    if player:isWounded() then table.removeOne(choices, "recover") end
    local choice = player.room:askForChoice(player, choices, self.name, nil, false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data
    if choice == "recover" then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    else
      local cards_id = target:getCardIds{Player.Hand, Player.Equip}
      local dummy = Fk:cloneCard'slash'
      dummy:addSubcards(cards_id)
      room:obtainCard(player.id, dummy, false, fk.Discard)
    end
  end,
}
local fangzhu = fk.CreateTriggerSkill{
  name = "m_ex__fangzhu",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#m_ex__fangzhu-choose:::"..player:getLostHp(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local num = player:getLostHp()
    if to.hp > 0 and #room:askForDiscard(to, num, num, true, self.name, true, nil, "#m_ex__fangzhu-ask:::" .. num, false) > 0 then
      if not to.dead then room:loseHp(to, 1, self.name) end
    else
      to:drawCards(num, self.name)
      if not to.dead then to:turnOver() end
    end
  end,
}
caopi:addSkill(xingshang)
caopi:addSkill(fangzhu)
caopi:addSkill("songwei")
Fk:loadTranslationTable{
  ["m_ex__caopi"] = "界曹丕",
  ["m_ex__xingshang"] = "行殇",
  [":m_ex__xingshang"] = "当其他角色死亡时，你可以选择一项：1.获得其所有牌；2.回复1点体力。",
  ["m_ex__fangzhu"] = "放逐",
  [":m_ex__fangzhu"] = "当你受到伤害后，你可以令一名其他角色选择一项：1.弃置X张牌并失去1点体力；2.摸X张牌并翻面（X为你已损失的体力值）。",

  ["m_ex__xingshang_obtain"] = "获得%dest的所有牌",
  ["#m_ex__fangzhu-choose"] = "放逐：你可令一名其他角色选择摸%arg张牌并翻面，或弃置%arg张牌并失去1点体力",
  ["#m_ex__fangzhu-ask"] = "放逐：弃置%arg张牌并失去1点体力，或点击“取消”，摸%arg张牌并翻面",

  ["$m_ex__xingshang1"] = "群燕辞归鹄南翔，念君客游思断肠。",
  ["$m_ex__xingshang2"] = "霜露纷兮文下，木叶落兮凄凄。",
  ["$m_ex__fangzhu1"] = "国法不可废耳，汝先退去。",
  ["$m_ex__fangzhu2"] = "将军征战辛苦，孤当赠以良宅。",
  ["$songwei_m_ex__caopi1"] = "藩屏大宗，御侮厌难。",
  ["$songwei_m_ex__caopi2"] = "朕承符运，终受革命。",
  ["~m_ex__caopi"] = "建平所言八十，谓昼夜也，吾其决矣……",
}

local xuhuang = General(extension, "m_ex__xuhuang", "wei", 4)
local m_ex__duanliang = fk.CreateViewAsSkill{
  name = "m_ex__duanliang",
  anim_type = "control",
  pattern = "supply_shortage",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and Fk:getCardById(to_select).type ~= Card.TypeTrick
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("supply_shortage")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
local m_ex__duanliang_targetmod = fk.CreateTargetModSkill{
  name = "#m_ex__duanliang_targetmod",
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(m_ex__duanliang.name) and skill.name == "supply_shortage_skill" and to:getHandcardNum() >= player:getHandcardNum()
  end,
}
m_ex__duanliang:addRelatedSkill(m_ex__duanliang_targetmod)

local m_ex__jiezi = fk.CreateTriggerSkill{
  name = "m_ex__jiezi",
  anim_type = "support",
  events = {fk.EventPhaseChanging},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player ~= target and target and target.skipped_phases[Player.Draw] and
        player:usedSkillTimes(self.name, Player.HistoryTurn) < 1 then
      return data.to == Player.Play or data.to == Player.Discard or data.to == Player.Finish
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    player:drawCards(1, self.name)
  end,
}

xuhuang:addSkill(m_ex__duanliang)
xuhuang:addSkill(m_ex__jiezi)
Fk:loadTranslationTable{
  ["m_ex__xuhuang"] = "界徐晃",
  ["m_ex__duanliang"] = "断粮",
  [":m_ex__duanliang"] = "①你可将一张不为锦囊牌的黑色牌转化为【兵粮寸断】使用。②你对手牌数不小于你的角色使用【兵粮寸断】无距离关系的限制。",
  ["m_ex__jiezi"] = "截辎",
  [":m_ex__jiezi"] = "其他角色的出牌阶段、弃牌阶段或结束阶段开始前，若其跳过过摸牌阶段且你于此回合内未发动过此技能，你摸一张牌。",

  ["$m_ex__duanliang1"] = "粮不三载，敌军已犯行军大忌。",
  ["$m_ex__duanliang2"] = "断敌粮秣，此战可胜。",
  ["$m_ex__jiezi1"] = "因粮于敌，敌军食可足也。	",
  ["$m_ex__jiezi2"] = "食敌一钟，当吾二十钟。",
  ["~m_ex__xuhuang"] = "敌军防备周全，是吾轻敌……",
}	

local dengai = General(extension, "m_ex__dengai", "wei", 4)
local tuntian = fk.CreateTriggerSkill{
  name = "m_ex__tuntian",
  anim_type = "special",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase == Player.NotActive then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
  end,

  refresh_events = {fk.FinishJudge},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and data.reason == self.name and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_refresh = function(self, event, target, player, data)
    if data.card.suit == Card.Heart then
      player.room:obtainCard(player, data.card, true, fk.ReasonJustMove)
    else
      player:addToPile("dengai_field", data.card, true, self.name)
    end
  end,
}
local tuntian_distance = fk.CreateDistanceSkill{
  name = "#m_ex__tuntian_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      return -#from:getPile("dengai_field")
    end
  end,
}
tuntian:addRelatedSkill(tuntian_distance)

dengai:addSkill(tuntian)
dengai:addSkill("zaoxian")
dengai:addRelatedSkill("jixi")

Fk:loadTranslationTable{
  ["m_ex__dengai"] = "界邓艾",
  ["m_ex__tuntian"] = "屯田",
  [":m_ex__tuntian"] = "当你于回合外失去牌后，你可以进行判定：若结果为红桃，则你获得此判定牌；否则你将生效后的判定牌置于你的武将牌上，称为“田”；你计算与其他角色的距离-X（X为“田”的数量）。",

  ["$m_ex__tuntian1"] = "休养生息，是为以备不虞。",
  ["$m_ex__tuntian2"] = "战损难免，应以军务减之。",
  ["$zaoxian_m_ex__dengai1"] = "用兵以险，则战之以胜！",
  ["$zaoxian_m_ex__dengai2"] = "已至马阁山，宜速进军破蜀！",
  ["$jixi_m_ex__dengai1"] = "攻敌之不备，斩将夺辎！",
  ["$jixi_m_ex__dengai2"] = "奇兵正攻，敌何能为？",
  ["~m_ex__dengai"] = "一片忠心，换来这般田地。",
}

local jiangwei = General(extension, "m_ex__jiangwei", "shu", 4)
local tiaoxin = fk.CreateActiveSkill{
  name = "m_ex__tiaoxin",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
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
    local use = room:askForUseCard(target, "slash", "slash", "#tiaoxin-use", true, {exclusive_targets = {player.id} })
    if use then
      room:useCard(use)
    else
      if not target:isNude() then
        local card = room:askForCardChosen(player, target, "he", self.name)
        room:throwCard({card}, self.name, target, player)
      end
    end
  end
}
local zhiji = fk.CreateTriggerSkill{
  name = "m_ex__zhiji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "draw2" then
      player:drawCards(2)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "ex__guanxing", nil, true, false)
  end,
}
jiangwei:addSkill(tiaoxin)
jiangwei:addSkill(zhiji)
jiangwei:addRelatedSkill("ex__guanxing")
Fk:loadTranslationTable{
  ["m_ex__jiangwei"] = "界姜维",
  ["m_ex__tiaoxin"] = "挑衅",
  [":m_ex__tiaoxin"] = "出牌阶段限一次，你可以选择一名其他角色，然后除非该角色对你使用一张【杀】，否则你弃置其一张牌。",
  ["m_ex__zhiji"] = "志继",
  [":m_ex__zhiji"] = "觉醒技，准备阶段，若你没有手牌，你回复1点体力或摸两张牌，减1点体力上限，然后获得〖观星〗。",

  ["$m_ex__tiaoxin1"] = "黄口竖子，何必上阵送命？",
  ["$m_ex__tiaoxin2"] = "汝如欲大败而归，则可进军一战！",
  ["$m_ex__zhiji1"] = "维定当奋身以复汉室。",
  ["$m_ex__zhiji2"] = "丞相之志，维必竭力而为。",
  ["$ex__guanxing_m_ex__jiangwei1"] = "知天易则观之，逆天难亦行之。",
  ["$ex__guanxing_m_ex__jiangwei2"] = "欲尽人事，亦先听天命。",
  ["~m_ex__jiangwei"] = "可惜大计未成，吾已身陨。",
}

local caiwenji = General(extension, "m_ex__caiwenji", "qun", 3, 3, General.Female)
local beige = fk.CreateTriggerSkill{
  name = "m_ex__beige",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card and data.card.trueName == "slash" and not data.to.dead and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#beige-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.suit == Card.Heart then
      if target:isWounded() then
        room:recover{
          who = target,
          num = data.damage,
          recoverBy = player,
          skillName = self.name
        }
      end
    elseif judge.card.suit == Card.Diamond then
      target:drawCards(3, self.name)
    elseif judge.card.suit == Card.Club then
      if data.from and not data.from.dead then
        if #data.from:getCardIds{Player.Hand, Player.Equip} < 3 then
          data.from:throwAllCards("he")
        else
          room:askForDiscard(data.from, 2, 2, true, self.name, false, ".")
        end
      end
    elseif judge.card.suit == Card.Spade then
      if data.from and not data.from.dead then
        data.from:turnOver()
      end
    end
  end,
}

caiwenji:addSkill(beige)
caiwenji:addSkill("duanchang")

Fk:loadTranslationTable{
  ["m_ex__caiwenji"] = "界蔡文姬",
  ["m_ex__beige"] = "悲歌",
  [":m_ex__beige"] = "当一名角色受到【杀】造成的伤害后，你可以弃置一张牌，令其进行判定，若结果为：<font color='red'>♥</font>，其回复X点体力（X为其本次受到的伤害值）；<font color='red'>♦</font>，其摸三张牌；♣，伤害来源弃置两张牌；♠，伤害来源翻面。",

  ["$m_ex__beige1"] = "人多暴猛兮如虺蛇，控弦披甲兮为骄奢。",
  ["$m_ex__beige2"] = "两拍张弦兮弦欲绝，志摧心折兮自悲嗟。",
  ["$duanchang_m_ex__caiwenji1"] = "雁高飞兮邈难寻，空断肠兮思愔愔。",
  ["$duanchang_m_ex__caiwenji2"] = "为天有眼兮，为何使我独飘流？",
  ["~m_ex__caiwenji"] = "今别子兮归故乡，旧怨平兮新怨长！",
}

local m_ex__pangtong = General:new(extension, "m_ex__pangtong", "shu", 3)
local m_ex__lianhuan = fk.CreateActiveSkill{
  name = "m_ex__lianhuan",
  mute = true,
  card_num = 1,
  min_target_num = 0,
  prompt = "#m_ex__lianhuan",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, selected_targets)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Club and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected_cards == 1 then
      local card = Fk:cloneCard("iron_chain")
      card:addSubcard(selected_cards[1])
      return card.skill:canUse(Self, card) and card.skill:targetFilter(to_select, selected, selected_cards, card) and
        not Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), card)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke(self.name)
    if #effect.tos == 0 then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:recastCard(effect.cards, player, self.name)
    else
      room:notifySkillInvoked(player, self.name, "control")
      room:sortPlayersByAction(effect.tos)
      room:useVirtualCard("iron_chain", effect.cards, player, table.map(effect.tos, Util.Id2PlayerMapper), self.name)
    end
  end,
}
local m_ex__lianhuan_trigger = fk.CreateTriggerSkill{
  name = "#m_ex__lianhuan_trigger",
  mute = true,
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.name == "iron_chain" then
      local current_targets = TargetGroup:getRealTargets(data.tos)
      for _, p in ipairs(player.room.alive_players) do
        if not table.contains(current_targets, p.id) and not player:isProhibited(p, data.card) and
            data.card.skill:modTargetFilter(p.id, current_targets, data.from, data.card, true) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local current_targets = TargetGroup:getRealTargets(data.tos)
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if not table.contains(current_targets, p.id) and not player:isProhibited(p, data.card) and
          data.card.skill:modTargetFilter(p.id, current_targets, data.from, data.card, true) then
        table.insert(targets, p.id)
      end
    end
    local tos = room:askForChoosePlayers(player, targets, 1, 1,
    "#m_ex__lianhuan-choose:::"..data.card:toLogString(), self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(m_ex__lianhuan.name)
    player.room:notifySkillInvoked(player, m_ex__lianhuan.name, "control")
    TargetGroup:pushTargets(data.tos, self.cost_data)
  end,
}
m_ex__lianhuan:addRelatedSkill(m_ex__lianhuan_trigger)
m_ex__pangtong:addSkill(m_ex__lianhuan)
local doNiepan = function (room, player)
  player:throwAllCards("hej")
  if player.dead then return end
  player:drawCards(3, "m_ex__niepan")
  if not player.dead and player:isWounded() then
    room:recover({
      who = player,
      num = math.min(3, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = "m_ex__niepan",
    })
  end
  if not player.dead then
    player:reset()
  end
end
local m_ex__niepan = fk.CreateActiveSkill{
  name = "m_ex__niepan",
  anim_type = "defensive",
  frequency = Skill.Limited,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    doNiepan (room, player)
  end,
}
local m_ex__niepan_trigger = fk.CreateTriggerSkill{
  name = "#m_ex__niepan_trigger",
  mute = true,
  main_skill = m_ex__niepan,
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(m_ex__niepan.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(m_ex__niepan.name)
    room:notifySkillInvoked(player, m_ex__niepan.name)
    doNiepan (room, player)
  end,
}
m_ex__niepan:addRelatedSkill(m_ex__niepan_trigger)
m_ex__pangtong:addSkill(m_ex__niepan)
Fk:loadTranslationTable{
  ["m_ex__pangtong"] = "界庞统",
  ["m_ex__lianhuan"] = "连环",
  [":m_ex__lianhuan"] = "你可以将一张梅花手牌当【铁索连环】使用或重铸，你使用【铁索连环】时可以额外指定一个目标。",
  ["#m_ex__lianhuan"] = "连环：你可以将一张梅花手牌当【铁索连环】使用或重铸",
  ["#m_ex__lianhuan_trigger"] = "连环",
  ["#m_ex__lianhuan-choose"] = "连环：你可以为 %arg 额外指定一个目标",
  ["m_ex__niepan"] = "涅槃",
  [":m_ex__niepan"] = "限定技，出牌阶段，或当你处于濒死状态时，你可以弃置你区域里所有的牌，摸三张牌，将体力值回复至3点，复原武将牌。",
  ["#m_ex__niepan_trigger"] = "涅槃",
  
  ["$m_ex__lianhuan1"] = "将多兵众，不可以敌，使其自累，以杀其势。",
  ["$m_ex__lianhuan2"] = "善用兵者，运巧必防损，立谋虑中变。",
  ["$m_ex__niepan1"] = "凤凰折翅，涅槃再生。",
  ["$m_ex__niepan2"] = "九天之志，展翅翱翔。",
  ["~m_ex__pangtong"] = "落……凤……坡……",
}

return extension
