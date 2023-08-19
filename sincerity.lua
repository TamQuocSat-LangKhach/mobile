local extension = Package("sincerity")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["sincerity"] = "手杀-始计篇·信",
}

local xinpi = General(extension, "mobile__xinpi", "wei", 3)
local mobile__yinju = fk.CreateActiveSkill{
  name = "mobile__yinju",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__yinju",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local use = room:askForUseCard(target, "slash", "slash", "#mobile__yinju-slash:"..player.id, true,
      {must_targets = {player.id}, bypass_distances = true, bypass_times = true})
    if use then
      room:useCard(use)
    else
      room:setPlayerMark(target, "@@mobile__yinju", 1)
    end
  end,
}
local mobile__yinju_trigger = fk.CreateTriggerSkill{
  name = "#mobile__yinju_trigger",

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target:getMark("@@mobile__yinju") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@mobile__yinju", 0)
    target:skip(Player.Play)
    target:skip(Player.Discard)
  end,
}
local mobile__chijie = fk.CreateTriggerSkill{
  name = "mobile__chijie",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and #AimGroup:getAllTargets(data.tos) == 1 and data.from ~= player.id and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#mobile__chijie-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|7~13",
    }
    room:judge(judge)
    if judge.card.number > 6 then
      AimGroup:cancelTarget(data, player.id)
    end
  end,
}
mobile__yinju:addRelatedSkill(mobile__yinju_trigger)
xinpi:addSkill(mobile__yinju)
xinpi:addSkill(mobile__chijie)
Fk:loadTranslationTable{
  ["mobile__xinpi"] = "辛毗",
  ["mobile__yinju"] = "引裾",
  [":mobile__yinju"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.跳过其下回合出牌阶段和弃牌阶段；2.对你使用一张无距离限制的【杀】。",
  ["mobile__chijie"] = "持节",
  [":mobile__chijie"] = "每回合限一次，当你成为其他角色使用牌的唯一目标时，你可以进行判定，若点数大于6，则取消之。",
  ["#mobile__yinju"] = "引裾：令一名其他角色选择对你使用【杀】，或跳过其下回合出牌阶段和弃牌阶段",
  ["@@mobile__yinju"] = "引裾",
  ["#mobile__yinju-slash"] = "引裾：你需对 %src 使用【杀】，否则跳过你下回合出牌阶段和弃牌阶段",
  ["#mobile__chijie-invoke"] = "持节：你可以判定，若点数大于6，则取消此%arg",

  ["$mobile__yinju1"] = "伐吴者，兴师劳民，徒而无功，万望陛下三思！",
  ["$mobile__yinju2"] = "今当屯田罢兵，徐图吴蜀，安能急躁冒进乎？",
  ["$mobile__chijie1"] = "节度在此，诸将莫要轻进。",
  ["$mobile__chijie2"] = "吾奉天子明诏，整肃六军。",
  ["~mobile__xinpi"] = "生而立于朝堂，亡而留名青史，我，已无憾矣。",
}

local wangling = General(extension, "mobile__wangling", "wei", 4)
local xingqi = fk.CreateTriggerSkill{
  name = "xingqi",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.CardUsing then
        return data.card.sub_type ~= Card.SubtypeDelayedTrick and
          (player:getMark("@$wangling_bei") == 0 or not table.contains(player:getMark("@$wangling_bei"), data.card.trueName))
      else
        return player.phase == Player.Finish and player:getMark("@$wangling_bei") ~= 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local choices = {"Cancel"}
      table.insertTable(choices, player:getMark("@$wangling_bei"))
      local choice = player.room:askForChoice(player, choices, self.name, "#xingqi-invoke")
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@$wangling_bei")
    if event == fk.CardUsing then
      if mark == 0 then mark = {} end
      table.insert(mark, data.card.trueName)
      room:setPlayerMark(player, "@$wangling_bei", mark)
    else
      table.removeOne(mark, self.cost_data)
      if #mark == 0 then mark = 0 end
      room:setPlayerMark(player, "@$wangling_bei", mark)
      local cards = room:getCardsFromPileByRule(self.cost_data)
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,
}
local zifu = fk.CreateTriggerSkill{
  name = "zifu",
  anim_type = "negative",
  events = {fk.EventPhaseEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("zifu-phase") == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
    player.room:addPlayerMark(player, "@$wangling_bei", 0)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and player.phase == Player.Play and player:getMark("zifu-phase") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zifu-phase", 1)
  end,
}
local mibei = fk.CreateTriggerSkill{
  name = "mibei",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  frequency = Skill.Quest,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and not player:getQuestSkillState(self.name) and
      player:getMark("@$wangling_bei") ~= 0 and #player:getMark("@$wangling_bei") > 5 then
      local nums = {0, 0, 0}
      for _, name in ipairs(player:getMark("@$wangling_bei")) do
        local card = Fk:cloneCard(name)
        if card.type == Card.TypeBasic then
          nums[1] = nums[1] + 1
        elseif card.type == Card.TypeTrick then
          nums[2] = nums[2] + 1
        elseif card.type == Card.TypeEquip then
          nums[3] = nums[3] + 1
        end
      end
      return table.every(nums, function(num) return num > 1 end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {"basic", "trick", "equip"}
    local cards = {}
    while #types > 0 do
      local pattern = table.random(types)
      table.removeOne(types, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|"..pattern))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
    room:handleAddLoseSkills(player, "mouli", nil, true, false)
    room:updateQuestSkillState(player, self.name, false)
  end,
}
local mibei_trigger = fk.CreateTriggerSkill{
  name = "#mibei_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("mibei", true) and player.phase == Player.Discard and
      player:getMark("@$wangling_bei") == 0 and player:getMark("mibei_fail-turn") > 0 and not player:getQuestSkillState("mibei")
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("mibei", 2)
    room:notifySkillInvoked(player, "mibei", "negative")
    room:changeMaxHp(player, -1)
    if not player.dead then
      room:updateQuestSkillState(player, "mibei", true)
    end
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill("mibei", true) and player.phase == Player.Start and player:getMark("@$wangling_bei") == 0 and
      not player:getQuestSkillState("mibei")
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "mibei_fail-turn", 1)
  end,
}
local mouli = fk.CreateActiveSkill{
  name = "mouli",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#mouli",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getMark("@$wangling_bei") ~= 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = player:getMark("@$wangling_bei")
    local choice = room:askForChoice(target, mark, self.name, "#mouli-invoke:"..player.id)
    table.removeOne(mark, choice)
    if #mark == 0 then mark = 0 end
    room:setPlayerMark(player, "@$wangling_bei", mark)
    local cards = room:getCardsFromPileByRule(choice)
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
mibei:addRelatedSkill(mibei_trigger)
wangling:addSkill(xingqi)
wangling:addSkill(zifu)
wangling:addSkill(mibei)
wangling:addRelatedSkill(mouli)
Fk:loadTranslationTable{
  ["mobile__wangling"] = "王凌",
  ["xingqi"] = "星启",
  [":xingqi"] = "当你使用一张不为延时锦囊的牌时，若没有此牌名的“备”，则记录此牌牌名为“备”。结束阶段，你可以移除一个“备”，获得牌堆中一张同名牌。",
  ["zifu"] = "自缚",
  [":zifu"] = "锁定技，出牌阶段结束时，若你本阶段未使用牌，你本回合手牌上限-1并移除你所有的“备”。",
  ["mibei"] = "秘备",
  [":mibei"] = "使命技，<br>\
  <strong>成功</strong>：当你使用牌结算后，若你拥有每种牌类别的“备”各不少于两个，你从牌堆获得每种类别的牌各一张，然后获得技能〖谋立〗。<br>\
  <strong>失败</strong>：弃牌阶段结束时，若此时和本回合准备阶段开始时你均没有“备”，你减1点体力上限且使命失败。",
  ["mouli"] = "谋立",
  [":mouli"] = "出牌阶段限一次，你可以令一名其他角色移除你的一个“备”，然后其获得牌堆中一张同名牌。",
  ["@$wangling_bei"] = "备",
  ["#xingqi-invoke"] = "星启：你可以移除一个“备”，获得牌堆中一张同名牌",
  ["#mouli-invoke"] = "谋立：移除 %src 的一个“备”，你获得牌堆中一张同名牌",
  ["#mouli"] = "谋立：令一名其他角色移除你的一个“备”，然后其获得牌堆中一张同名牌",

  ["~mobile__wangling"] = "一生尽忠事魏，不料今日晚节尽毁啊！",
}

local mifuren = General(extension, "mobile__mifuren", "shu", 3, 3, General.Female)
local mobile__guixiu = fk.CreateTriggerSkill{
  name = "mobile__guixiu",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
      (player:getHandcardNum() < player.hp or player:isWounded())
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel"}
    if player:getHandcardNum() < player.hp then
      table.insert(choices, "mobile__guixiu_draw")
    end
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#mobile__guixiu-invoke", false,
      {"Cancel", "mobile__guixiu_draw", "recover"})
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data[1] == "m" then
      player:drawCards(player.hp - player:getHandcardNum(), self.name)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local qingyu = fk.CreateTriggerSkill{
  name = "qingyu",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  frequency = Skill.Quest,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getHandcardNum() > 1 and not player:getQuestSkillState(self.name) and
      player:usedSkillTimes("#qingyu_trigger", Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 2, 2, false, self.name, false, ".", "#qingyu-invoke", true)
    if #cards == 2 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, self.name, player, player)
    return true
  end,
}
local qingyu_trigger = fk.CreateTriggerSkill{
  name = "#qingyu_trigger",
  mute = true,
  events = {fk.EventPhaseStart, fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill("qingyu", true) and not player:getQuestSkillState("qingyu") then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start and not player:isWounded() and player:isKongcheng()
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:broadcastSkillInvoke("qingyu", 1)
      room:notifySkillInvoked(player, "qingyu", "special")
      room:handleAddLoseSkills(player, "xuancun", nil, true, false)
      room:updateQuestSkillState(player, "qingyu", false)
    else
      room:broadcastSkillInvoke("qingyu", 2)
      room:notifySkillInvoked(player, "qingyu", "negative")
      room:changeMaxHp(player, -1)
      if not player.dead then
        room:updateQuestSkillState(player, "qingyu", true)
      end
    end
  end,
}
local xuancun = fk.CreateTriggerSkill{
  name = "xuancun",
  anim_type = "support",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.to == player.NotActive and player.hp > player:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil,
      "#xuancun-invoke::"..target.id..":"..math.min(2, player.hp - player:getHandcardNum()))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    target:drawCards(math.min(2, player.hp - player:getHandcardNum()), self.name)
  end,
}
qingyu:addRelatedSkill(qingyu_trigger)
mifuren:addSkill(mobile__guixiu)
mifuren:addSkill(qingyu)
mifuren:addRelatedSkill(xuancun)
Fk:loadTranslationTable{
  ["mobile__mifuren"] = "糜夫人",
  ["mobile__guixiu"] = "闺秀",
  [":mobile__guixiu"] = "结束阶段，你可以选择一项：1.将手牌摸至体力值；2.回复1点体力。",
  ["qingyu"] = "清玉",
  [":qingyu"] = "使命技，当你受到伤害时，你需弃置两张手牌并防止此伤害。<br>\
  <strong>成功</strong>：准备阶段，若你未受伤且没有手牌，你获得技能〖悬存〗。<br>\
  <strong>失败</strong>：当你进入濒死状态时，你减1点体力上限且使命失败。",
  ["xuancun"] = "悬存",
  [":xuancun"] = "其他角色回合结束后，若你的体力值大于手牌数，你可以令其摸X张牌（X为你体力值与手牌数之差且至多为2）。",
  ["#mobile__guixiu-invoke"] = "闺秀：你可以执行一项",
  ["mobile__guixiu_draw"] = "摸牌至体力值",
  ["#qingyu-invoke"] = "清玉：你需弃置两张手牌，防止你受到的伤害",
  ["#xuancun-invoke"] = "悬存：你可以令 %dest 摸%arg张牌",
}

local wangfuzhaolei = General(extension, "wangfuzhaolei", "shu", 4)
local xunyi = fk.CreateTriggerSkill{
  name = "xunyi",
  events = {fk.GameStart, fk.Damaged, fk.Damage, fk.Death},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name, true) then
      if event == fk.GameStart then
        return true
      elseif event == fk.Damaged then
        if player:hasSkill(self.name) and player:getMark(self.name) ~= 0 and data.from then
          return (target == player and data.from.id ~= player:getMark(self.name)) or
            (player:getMark(self.name) == target.id and data.from ~= player)
        end
      elseif event == fk.Damage then
        if player:hasSkill(self.name) and player:getMark(self.name) ~= 0 and target then
          return (target == player and data.to.id ~= player:getMark(self.name)) or
            (player:getMark(self.name) == target.id and data.to ~= player)
        end
      else
        return target == player or (player:getMark(self.name) ~= 0 and player:getMark(self.name) == target.id)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke(self.name)
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name, "special")
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#xunyi-choose", self.name, false, false)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:setPlayerMark(to, "@@xunyi", 1)
      room:setPlayerMark(player, self.name, to.id)
    elseif event == fk.Damaged then
      room:notifySkillInvoked(player, self.name, "negative")
      local to = room:getPlayerById(player:getMark(self.name))
      if target == player and not to:isNude() then
        room:doIndicate(player.id, {to.id})
        room:askForDiscard(to, 1, 1, true, self.name, false)
      elseif target == to and not player:isNude() then
        room:doIndicate(to.id, {player.id})
        room:askForDiscard(player, 1, 1, true, self.name, false)
      end
    elseif event == fk.Damage then
      room:notifySkillInvoked(player, self.name, "support")
      local to = room:getPlayerById(player:getMark(self.name))
      if target == player then
        room:doIndicate(player.id, {to.id})
        to:drawCards(1, self.name)
      elseif target == to then
        room:doIndicate(to.id, {player.id})
        player:drawCards(1, self.name)
      end
    elseif event == fk.Death then
      room:notifySkillInvoked(player, self.name, "special")
      room:setPlayerMark(player, self.name, 0)
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#xunyi-choose", self.name, true, false)
      if #to > 0 then
        room:setPlayerMark(room:getPlayerById(to[1]), "@@xunyi", 1)
        room:setPlayerMark(player, self.name, to[1])
      end
    end
  end,
}
wangfuzhaolei:addSkill(xunyi)
Fk:loadTranslationTable{
  ["wangfuzhaolei"] = "王甫赵累",
  ["xunyi"] = "殉义",
  [":xunyi"] = "游戏开始时，你选择一名其他角色，令其获得“义”标记。<br>当你或有“义”的角色受到1点伤害后，若伤害来源不为另一方，"..
  "另一方弃置一张牌。<br>当你或有“义”的角色造成1点伤害后，若受伤角色不为另一方，另一方摸一张牌。<br>当有“义”的角色死亡时，你可以转移“义”标记。",
  ["@@xunyi"] = "义",
  ["#xunyi-choose"] = "殉义：选择一名角色获得“义”标记",
}

local zhouchu = General(extension, "mobile__zhouchu", "wu", 4)
local xianghai = fk.CreateFilterSkill{
  name = "xianghai",
  card_filter = function(self, to_select, player)
    return player:hasSkill(self.name) and to_select.type == Card.TypeEquip and
      not table.contains(player:getCardIds("ej"), to_select.id)
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("analeptic", to_select.suit, to_select.number)
    card.skillName = self.name
    return card
  end,
}
local xianghai_maxcards = fk.CreateMaxCardsSkill{
  name = "#xianghai_maxcards",
  correct_func = function(self, player)
    return - #table.filter(Fk:currentRoom().alive_players, function(p) return p:hasSkill(xianghai.name) and p ~= player end)
  end,
}
local chuhai = fk.CreateActiveSkill{
  name = "chuhai",
  anim_type = "offensive",
  prompt = "#chuhai-active",
  frequency = Skill.Quest,
  mute = true,
  max_card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:getQuestSkillState(self.name)
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:notifySkillInvoked(player, self.name)
    room:broadcastSkillInvoke(self.name, 1)
    room:drawCards(player, 1, self.name)
    if player.dead or player:isKongcheng() or target.dead or target:isKongcheng() then return false end
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      local cards = target.player_cards[Player.Hand]
      if #cards > 0 then
        room:fillAG(player, cards)
        room:delay(5000)
        room:closeAG(player)
        local types = {}
        for _, id in ipairs(cards) do
          table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
        end

        local toObtain = {}
        for _, type_name in ipairs(types) do
          local randomCard = room:getCardsFromPileByRule(".|.|.|.|.|" .. type_name, 1)
          if #randomCard == 0 then
            randomCard = room:getCardsFromPileByRule(".|.|.|.|.|" .. type_name, 1, "discardPile")
          end
          if #randomCard > 0 then
            table.insert(toObtain, randomCard[1])
          end
        end

        if #toObtain > 0 then
          player.room:moveCards({
            ids = toObtain,
            to = player.id,
            toArea = Player.Hand,
            moveReason = fk.ReasonPrey,
            proposer = player.id,
            skillName = self.name,
          })
        end
      end
      room:addPlayerMark(target, "@@chuhai-phase")
      local targetRecorded = type(player:getMark("chuhai_target-phase")) == "table" and player:getMark("chuhai_target-phase") or {}
      table.insertIfNeed(targetRecorded, target.id)
      room:setPlayerMark(player, "chuhai_target-phase", targetRecorded)
    end
  end,
}
local chuhai_trigger = fk.CreateTriggerSkill{
  name = "#chuhai_trigger",
  events = {fk.AfterCardsMove, fk.PindianResultConfirmed},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(chuhai.name) or player:getQuestSkillState(chuhai.name) then return false end
    if event == fk.AfterCardsMove and #player.player_cards[Player.Equip] > 2 then
      for _, move in ipairs(data) do
        if move.to and move.to == player.id and move.toArea == Player.Equip then
          return true
        end
      end
    elseif event == fk.PindianResultConfirmed then
      if data.from == player and data.winner ~= player and data.fromCard.number < 7 then
        local parentPindianEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian, true)
        if parentPindianEvent then
          local pindianData = parentPindianEvent.data[1]
          return pindianData.reason == chuhai.name
        end
      end
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, chuhai.name, "special")
      room:broadcastSkillInvoke(chuhai.name, 2)
      room:updateQuestSkillState(player, chuhai.name, false)
      if player:isWounded() then
        room:recover({
          who = player,
          num = player.maxHp - player.hp,
          recoverBy = player,
          skillName = chuhai.name
        })
      end
      room:handleAddLoseSkills(player, "-xianghai|zhangming")
    elseif event == fk.PindianResultConfirmed then
      room:notifySkillInvoked(player, chuhai.name, "negative")
      room:broadcastSkillInvoke(chuhai.name, 3)
      room:updateQuestSkillState(player, chuhai.name, true)
    end
  end,
}
local chuhai_delay = fk.CreateTriggerSkill{
  name = "#chuhai_delay",
  mute = true,
  events = {fk.Damage, fk.PindianCardsDisplayed},
  can_trigger = function(self, event, target, player, data)
    if event == fk.Damage and player == target then
      return type(player:getMark("chuhai_target-phase")) == "table" and table.contains(player:getMark("chuhai_target-phase"), data.to.id)
    elseif event == fk.PindianCardsDisplayed then
      return data.reason == chuhai.name and data.from == player and #player.player_cards[Player.Equip] < 4
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      local types = table.filter({Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide,
      Card.SubtypeOffensiveRide, Card.SubtypeTreasure}, function (type_name) return not player:getEquipment(type_name) end)
      if #types == 0 then return false end
      local cards1, cards2 = {}, {}
      for i = 1, #types, 1 do
        table.insert(cards1, {})
        table.insert(cards2, {})
      end
      for i = 1, #room.draw_pile, 1 do
        local card = Fk:getCardById(room.draw_pile[i])
        if card.type == Card.TypeEquip and table.contains(types, card.sub_type) then
          table.insert(cards1[table.indexOf(types, card.sub_type)], card.id)
        end
      end
      for i = 1, #room.discard_pile, 1 do
        local card = Fk:getCardById(room.discard_pile[i])
        if card.type == Card.TypeEquip and table.contains(types, card.sub_type) then
          table.insert(cards2[table.indexOf(types, card.sub_type)], card.id)
        end
      end

      for i = 1, #types, 1 do
        if #cards1[i] > 0 then
          room:moveCards({
            ids = {table.random(cards1[i])},
            to = player.id,
            toArea = Card.PlayerEquip,
            moveReason = fk.ReasonPut,
          })
          break
        end
        if #cards2[i] > 0 then
          room:moveCards({
            ids = {table.random(cards2[i])},
            to = player.id,
            toArea = Card.PlayerEquip,
            moveReason = fk.ReasonPut,
          })
          break
        end
      end

    elseif event == fk.PindianCardsDisplayed then
      data.fromCard.number = math.min(data.fromCard.number + 4 - #player.player_cards[Player.Equip], 13)
    end
  end,
}
local zhangming = fk.CreateTriggerSkill{
  name = "zhangming",
  anim_type = "drawcard",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 and
      player ~= data.to and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {"basic", "trick", "equip"}
    local to = data.to
    if not to.dead then
      local cards = table.filter(to.player_cards[Player.Hand], function (id)
        return not to:prohibitDiscard(Fk:getCardById(id))
      end)
      if #cards > 0 then
        local id = table.random(cards)
        table.removeOne(types, Fk:getCardById(id):getTypeString())
        room:throwCard(id, self.name, to)
      end
    end
    local toObtain = {}
    for _, type_name in ipairs(types) do
      local randomCard = room:getCardsFromPileByRule(".|.|.|.|.|" .. type_name, 1)
      if #randomCard == 0 then
        randomCard = room:getCardsFromPileByRule(".|.|.|.|.|" .. type_name, 1, "discardPile")
      end
      if #randomCard > 0 then
        table.insert(toObtain, randomCard[1])
      end
    end
    if #toObtain > 0 then
      player.room:moveCards({
        ids = toObtain,
        to = player.id,
        toArea = Player.Hand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
    local zhangmingcards = player:getMark("zhangming-turn") == 0 and {} or player:getMark("zhangming-turn")
    table.insertTable(zhangmingcards, table.filter(toObtain, function (id)
      return room:getCardArea(id) == Player.Hand and room:getCardOwner(id) == player end))
    room:setPlayerMark(player, "zhangming-turn", zhangmingcards)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if type(player:getMark("zhangming-turn")) == "table" then
      room:setPlayerMark(player, "zhangming-turn", table.filter(player:getMark("zhangming-turn"), function (id)
        return room:getCardArea(id) == Player.Hand and room:getCardOwner(id) == player end))
    end
  end,
}
local zhangming_trigger = fk.CreateTriggerSkill{
  name = "#zhangming_trigger",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhangming.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and data.card.suit == Card.Club
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
}
local zhangming_maxcards = fk.CreateMaxCardsSkill{
  name = "#zhangming_maxcards",
  exclude_from = function(self, player, card)
    return player:getMark("zhangming-turn") ~= 0 and table.contains(player:getMark("zhangming-turn"), card.id)
  end,
}
xianghai:addRelatedSkill(xianghai_maxcards)
chuhai:addRelatedSkill(chuhai_trigger)
chuhai:addRelatedSkill(chuhai_delay)
zhangming:addRelatedSkill(zhangming_trigger)
zhangming:addRelatedSkill(zhangming_maxcards)
zhouchu:addSkill(xianghai)
zhouchu:addSkill(chuhai)
zhouchu:addRelatedSkill(zhangming)
Fk:loadTranslationTable{
  ["mobile__zhouchu"] = "周处",
  ["xianghai"] = "乡害",
  [":xianghai"] = "锁定技，其他角色的手牌上限-1，你手牌中的装备牌均视为【酒】。",
  ["chuhai"] = "除害",
  [":chuhai"] = "使命技，出牌阶段限一次，你可以摸一张牌，并与一名其他角色拼点，此次你的拼点牌点数增加X（X为4减去你装备区的装备数量）。若你赢："..
  "你观看其手牌，从牌堆或弃牌堆随机获得其手牌中拥有的类别牌各一张；你于此阶段对其造成伤害后，将牌堆或弃牌堆中一张你空置装备栏对应类型的装备牌，"..
  "置入你对应的装备区。<br>\
  <strong>成功</strong>：当一张装备牌进入你的装备区后，若你的装备区有不少于3张装备，则你将体力值回复至上限，获得〖彰名〗，失去〖乡害〗。<br>\
  <strong>失败</strong>：若你于使命达成前，你使用〖除害〗拼点没赢，且你的拼点结果不大于6点，则使命失败。",
  ["zhangming"] = "彰名",
  [":zhangming"] = "锁定技，你使用♣牌不能被响应。每回合限一次，你对其他角色造成伤害后，其随机弃置一张手牌，然后你从牌堆或弃牌堆中获得"..
  "与其弃置牌类型不同的牌各一张（若其无法弃置手牌，改为你从牌堆或弃牌堆获得所有类型牌各一张），以此法获得的牌不计入本回合手牌上限。",
  ["#chuhai_trigger"] = "除害",
  ["#chuhai_delay"] = "除害",
  ["#chuhai-active"] = "发动除害，选择与你拼点的角色",
  ["@@chuhai-phase"] = "除害",
  ["#zhangming_trigger"] = "彰名",

  ["$xianghai1"] = "快快闪开，伤到你们可就不好了，哈哈哈！",
  ["$xianghai2"] = "你自己撞上来的，这可怪不得小爷我！",
  ["$chuhai1"] = "有我在此，安敢为害？！",
  ["$chuhai2"] = "小小孽畜，还不伏诛？！",
  ["$chuhai3"] = "此番不成，明日再战！",
  ["$zhangming1"] = "心怀远志，何愁声名不彰！",
  ["$zhangming2"] = "从今始学，成为有用之才！",
  ["~mobile__zhouchu"] = "改励自砥，誓除三害……",
}

local wujing = General(extension, "mobile__wujing", "wu", 4)
local heji = fk.CreateTriggerSkill{
  name = "heji",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if data.card.trueName == "duel" or (data.card.trueName == "slash" and data.card.color == Card.Red) then
      local targets = TargetGroup:getRealTargets(data.tos)
      return #targets == 1 and targets[1] ~= player.id and not player.room:getPlayerById(targets[1]).dead
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = TargetGroup:getRealTargets(data.tos)
    local use = player.room:askForUseCard(player, "slash,duel", "slash,duel", "#heji-use::" .. targets[1], true,
      { must_targets = targets, bypass_distances = true, bypass_times = true })
    if use then
      if not use.card:isVirtual() then
        use.extra_data = {hejiDrawer = player.id}
      end
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(self.cost_data)
  end,
}
local heji_delay = fk.CreateTriggerSkill{
  name = "#heji_delay",
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.hejiDrawer == player.id
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room.draw_pile > 0 then
      local cards = room:getCardsFromPileByRule(".|.|heart,diamond", 1)
      if #cards > 0 then
        room:obtainCard(player, cards[1], false, fk.ReasonJustMove)
      end
    end
  end,
}
local liubing = fk.CreateTriggerSkill{
  name = "liubing",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player ~= target and target.phase == Player.Play then
      if data.card.trueName == "slash" and data.card.color == Card.Black and not data.damageDealt then
        local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
        return #cardlist == 1 and player.room:getCardArea(cardlist[1]) == Card.Processing
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
    if table.every(cardlist, function(id) return player.room:getCardArea(id) == Card.Processing end) then
      player.room:obtainCard(player.id, data.card, false)
    end
  end,
}
local liubing_trigger = fk.CreateTriggerSkill{
  name = "#liubing_trigger",
  frequency = Skill.Compulsory,
  mute = true,
  events = {fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(liubing.name) and player:usedSkillTimes(self.name) == 0 and
      data.card.trueName == "slash" and not (data.card:isVirtual() and #data.card.subcards == 0)
  end,
  on_use = function(self, event, target, player, data)
    if data.card.suit ~= Card.Diamond then
      local diamondSlash = Fk:cloneCard(data.card.name)
      diamondSlash:addSubcard(data.card)
      diamondSlash.skillName = self.name
      diamondSlash.suit = Card.Diamond
      diamondSlash.color = Card.Red
      data.card = diamondSlash
    end
  end,
}
heji:addRelatedSkill(heji_delay)
liubing:addRelatedSkill(liubing_trigger)
wujing:addSkill(heji)
wujing:addSkill(liubing)
Fk:loadTranslationTable{
  ["mobile__wujing"] = "吴景",
  ["heji"] = "合击",
  ["#heji_delay"] = "合击",
  [":heji"] = "若一名角色使用【决斗】或红色【杀】仅指定唯一其他角色为目标，此牌结算后，你可从手牌中对相同目标使用一张无次数和距离限制的"..
  "【杀】或【决斗】。若你使用的不为转化牌，你使用此牌时随机获得一张红色牌。",
  ["liubing"] = "流兵",
  [":liubing"] = "锁定技，你每回合使用的第一张非虚拟【杀】花色视为<font color='red'>♦</font>。其他角色于出牌阶段使用的非转化黑色【杀】"..
  "结算后，若未造成伤害，你获得之。",
  ["#liubing_trigger"] = "流兵",
  ["#heji-use"] = "合击：你可以对%dest使用一张手牌中的【杀】或者【决斗】",

  ["$heji1"] = "你我合势而击之，区区贼寇岂会费力？",
  ["$heji2"] = "伯符！今日之战，务必全力攻之！",
  ["$liubing1"] = "尔等流寇，亦可展吾军之勇。",
  ["$liubing2"] = "流寇不堪大用，勤加操练可为精兵。",
  ["~mobile__wujing"] = "贼寇未除，奈何吾身先丧……",
}

local yanghu = General(extension, "mobile__yanghu", "qun", 3)
yanghu.subkingdom = "jin"
local mobile__mingfa = fk.CreateTriggerSkill{
  name = "mobile__mingfa",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() end), function(p) return p.id end)
    local to, card =  room:askForChooseCardAndPlayers(player, targets, 1, 1, ".|.|.|hand", "#mobile__mingfa-invoke", self.name, true)
    if #to > 0 and card then
      self.cost_data = {to[1], card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    player:showCards(self.cost_data[2])
    if player.dead or to:isKongcheng() then return end
    local pindian = player:pindian({to}, self.name, Fk:getCardById(self.cost_data[2]))
    room:sendLog{
      type = "#ShowPindianCard",
      from = player.id,
      card = {self.cost_data[2]},
    }
    room:moveCards({
      ids = {self.cost_data[2]},
      from = player.id,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
      skillName = self.name,
      moveVisible = true,
    })
    if player.dead then return end
    if pindian.results[to.id].winner == player then
      if not to.dead and not to:isNude() then
        local id = room:askForCardChosen(player, to, "he", self.name)
        room:obtainCard(player, id, false, fk.ReasonPrey)
      end
      if not player.dead then
        player:drawCards(1, self.name)
      end
    else
      room:setPlayerMark(player, "mobile__mingfa-turn", 1)
    end
  end,

  refresh_events = {fk.PindianCardsDisplayed},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (player == data.from or data.results[player.id])
  end,
  on_refresh = function(self, event, target, player, data)
    if player == data.from then
      data.fromCard.number = data.fromCard.number + 2
    elseif data.results[player.id] then
      data.results[player.id].toCard.number = data.results[player.id].toCard.number + 2
    end
  end,
}
local mobile__mingfa_prohibit = fk.CreateProhibitSkill{
  name = "#mobile__mingfa_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("mobile__mingfa-turn") > 0 and from ~= to
  end,
}
local rongbei = fk.CreateActiveSkill{
  name = "rongbei",
  anim_type = "support",
  target_num = 1,
  card_num = 0,
  frequency = Skill.Limited,
  prompt = "#rongbei",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and #target:getCardIds("e") < #target:getAvailableEquipSlots()
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local subtype_string_table = {
      [Card.SubtypeArmor] = "armor",
      [Card.SubtypeWeapon] = "weapon",
      [Card.SubtypeTreasure] = "treasure",
      [Card.SubtypeDelayedTrick] = "delayed_trick",
      [Card.SubtypeDefensiveRide] = "defensive_ride",
      [Card.SubtypeOffensiveRide] = "offensive_ride",
    }
    for _, slot in ipairs(target:getAvailableEquipSlots()) do
      if target.dead then return end
      local type = Util.convertSubtypeAndEquipSlot(slot)
      if #target:getEquipments(type) < #target:getAvailableEquipSlots(type) then
        local id = room:getCardsFromPileByRule(".|.|.|.|.|"..subtype_string_table[type], 1, "allPiles")[1]
        if id then
          room:useCard({
            from = effect.tos[1],
            tos = {{effect.tos[1]}},
            card = Fk:getCardById(id),
          })
        end
      end
    end
  end,
}
mobile__mingfa:addRelatedSkill(mobile__mingfa_prohibit)
yanghu:addSkill(mobile__mingfa)
yanghu:addSkill(rongbei)
Fk:loadTranslationTable{
  ["mobile__yanghu"] = "羊祜",
  ["mobile__mingfa"] = "明伐",
  [":mobile__mingfa"] = "你的拼点牌点数+2。出牌阶段开始时，你可以展示一张手牌并用此牌与一名角色拼点，若你赢，你获得其一张牌并摸一张牌；"..
  "若你没赢，你本回合使用牌不能指定其他角色为目标。",
  ["rongbei"] = "戎备",
  [":rongbei"] = "限定技，出牌阶段，你可以选择一名装备区有空置装备栏的角色，其为每个空置的装备栏从牌堆或弃牌堆随机使用一张对应类别的装备。",
  ["#mobile__mingfa-invoke"] = "明伐：你可以展示一张手牌并用此牌拼点，若赢则获得其一张牌并摸一张牌",
  ["#rongbei"] = "戎备：令一名角色每个空置的装备栏随机使用一张装备",
}

local godsunce = General(extension, "godsunce", "god", 1, 6)
local yingba = fk.CreateActiveSkill{
  name = "yingba",
  anim_type = "offensive",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return Self.id ~= to_select and Fk:currentRoom():getPlayerById(to_select).maxHp > 1
  end,
  on_use = function(self, room, effect)
    local to = room:getPlayerById(effect.tos[1])
    room:changeMaxHp(to, -1)
    room:addPlayerMark(to, "@yingba_pingding")

    room:changeMaxHp(room:getPlayerById(effect.from), -1)
  end,
}
local yingbaBuff = fk.CreateTargetModSkill{
  name = "#yingba-buff",
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill("yingba") and to and to:getMark("@yingba_pingding") > 0
  end,
}
local fuhai = fk.CreateTriggerSkill{
  name = "fuhai",
  events = {fk.TargetSpecified, fk.Death},
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return end
    if event == fk.TargetSpecified then
      return
        target == player and
        player.room:getPlayerById(data.to):getMark("@yingba_pingding") > 0 and
        player:usedSkillTimes(self.name) < 2
    else
      return player.room:getPlayerById(data.who):getMark("@yingba_pingding") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      player:drawCards(1, self.name)
    else
      local room = player.room
      local deadOne = room:getPlayerById(data.who)
      local pingdingNum = deadOne:getMark("@yingba_pingding")

      player.room:changeMaxHp(player, pingdingNum)
      player:drawCards(pingdingNum, self.name)
    end
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self.name) and
      player.room:getPlayerById(data.to):getMark("@yingba_pingding") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insert(data.disresponsiveList, data.to)
  end,
}
local pinghe = fk.CreateTriggerSkill{
  name = "pinghe",
  events = {fk.DamageInflicted},
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self.name) and
      player.maxHp > 1 and
      not player:isKongcheng() and
      data.from and
      data.from ~= player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    local tos, cardId = room:askForChooseCardAndPlayers(player, table.map(room:getOtherPlayers(player, false), function(p)
      return p.id end), 1, 1, ".|.|.|hand", "#pinghe-give", self.name, false, true )
    room:obtainCard(tos[1], cardId, false, fk.ReasonGive)
    if player:hasSkill(yingba.name, true) and data.from:isAlive() then
      room:addPlayerMark(data.from, "@yingba_pingding")
    end
    return true
  end,
}
local pingheBuff = fk.CreateMaxCardsSkill {
  name = "#pinghe-buff",
  frequency = Skill.Compulsory,
  fixed_func = function(self, player)
    return player:hasSkill("pinghe") and player:getLostHp() or nil
  end
}
yingba:addRelatedSkill(yingbaBuff)
pinghe:addRelatedSkill(pingheBuff)
godsunce:addSkill(yingba)
godsunce:addSkill(fuhai)
godsunce:addSkill(pinghe)
Fk:loadTranslationTable{
  ["godsunce"] = "神孙策",
  ["yingba"] = "英霸",
  [":yingba"] = "出牌阶段限一次，你可以令一名体力上限大于1的其他角色减1点体力上限，并令其获得一枚“平定”标记，然后你减1点体力上限；"..
  "你对拥有“平定”标记的角色使用牌无距离限制。",
  ["fuhai"] = "覆海",
  [":fuhai"] = "锁定技，拥有“平定”标记的角色不能响应你对其使用的牌；当你使用牌指定拥有“平定”标记的角色为目标后，你摸一张牌；当拥有“平定”标记"..
  "的角色死亡时，你加X点体力上限并摸X张牌（X为其“平定”标记数）。",
  ["pinghe"] = "冯河",
  [":pinghe"] = "锁定技，你的手牌上限基值为你已损失的体力值；当你受到其他角色造成的伤害时，若你的体力上限大于1且你有手牌，你防止此伤害，"..
  "减1点体力上限并将一张手牌交给一名其他角色，然后若你有技能〖英霸〗，伤害来源获得一枚“平定”标记。",
  ["#pinghe-give"] = "冯河：请交给一名其他角色一张手牌",
  ["@yingba_pingding"] = "平定",

  ["$yingba1"] = "从我者可免，拒我者难容！",
  ["$yingba2"] = "卧榻之侧，岂容他人鼾睡！",
  ["$fuhai1"] = "翻江复蹈海，六合定乾坤！",
  ["$fuhai2"] = "力攻平江东，威名扬天下！",
  ["$pinghe1"] = "不过胆小鼠辈，吾等有何惧哉！",
  ["$pinghe2"] = "只可得胜而返，岂能败战而归！",
  ["~godsunce"] = "无耻小人！竟敢暗算于我……",
}

local godTaishici = General(extension, "godtaishici", "god", 4)
Fk:loadTranslationTable{
  ["godtaishici"] = "神太史慈",
  ["~godtaishici"] = "魂归……天地……",
}

local dulie = fk.CreateTriggerSkill{
  name = "dulie",
  events = {fk.TargetConfirming},
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self.name) and
      data.card.trueName == "slash" and
      player.room:getPlayerById(data.from).hp > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|heart",
    }

    room:judge(judge)
    if judge.card.suit == Card.Heart then
      AimGroup:cancelTarget(data, player.id)
      return true
    end
  end,
}
Fk:loadTranslationTable{
  ["dulie"] = "笃烈",
  [":dulie"] = "锁定技，当你成为体力值大于你的角色使用【杀】的目标时，你判定，若结果为<font color='red'>♥</font>，取消之。",
  ["$dulie1"] = "素来言出必践，成吾信义昭彰！",
  ["$dulie2"] = "小信如若不成，大信将以何立？",
}

godTaishici:addSkill(dulie)

local powei = fk.CreateTriggerSkill{
  name = "powei",
  events = {fk.GameStart, fk.EventPhaseChanging, fk.Damaged, fk.EnterDying},
  frequency = Skill.Quest,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:getQuestSkillState(self.name) or not player:hasSkill(self.name) then
      return false
    end

    if event == fk.GameStart then
      return true
    elseif event == fk.EventPhaseChanging then
      return data.from == Player.RoundStart and (target == player or target:getMark("@@powei_wei") > 0)
    elseif event == fk.Damaged then
      return target:getMark("@@powei_wei") > 0
    else
      return target == player and player.hp < 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    self.cost_data = nil
    if event == fk.EventPhaseChanging and target:getMark("@@powei_wei") > 0 then
      local room = player.room

      local choices = { "Cancel" }
      if target.hp <= player.hp and target ~= player and target:getHandcardNum() > 0 then
        table.insert(choices, 1, "powei_prey")
      end
      if table.find(player:getCardIds(Player.Hand), function(id)
        return not player:prohibitDiscard(Fk:getCardById(id))
      end) then
        table.insert(choices, 1, "powei_damage")
      end

      if #choices == 1 then
        return false
      end

      local choice = room:askForChoice(player, choices, self.name)
      if choice == "Cancel" then
        return false
      end

      if choice == "powei_damage" then
        local cardIds = room:askForDiscard(player, 1, 1, false, self.name, true, nil, "#powei-damage::" .. target.id, true)
        if #cardIds == 0 then
          return false
        end

        self.cost_data = cardIds[1]
      else
        self.cost_data = choice
      end
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name)
      room:broadcastSkillInvoke(self.name, 1)
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:setPlayerMark(p, "@@powei_wei", 1)
      end
    elseif event == fk.EventPhaseChanging then
      if target == player then
        if table.find(room.alive_players, function(p)
          return p:getMark("@@powei_wei") > 0
        end) then
          room:notifySkillInvoked(player, self.name)
          room:broadcastSkillInvoke(self.name, 1)
          local hasLastPlayer = false
          for _, p in ipairs(room:getAlivePlayers()) do
            if p:getMark("@@powei_wei") > (hasLastPlayer and 1 or 0) and not (#room.alive_players < 3 and p:getNextAlive() == player) then
              hasLastPlayer = true
              room:removePlayerMark(p, "@@powei_wei")
              local nextPlayer = p:getNextAlive()
              if nextPlayer == player then
                nextPlayer = player:getNextAlive()
              end

              room:addPlayerMark(nextPlayer, "@@powei_wei")
            else
              hasLastPlayer = false
            end
          end
        else
          room:notifySkillInvoked(player, self.name)
          room:broadcastSkillInvoke(self.name, 2)
          room:updateQuestSkillState(player, self.name)
          room:handleAddLoseSkills(player, "shenzhuo")
        end
      end

      if type(self.cost_data) == "number" then
        room:notifySkillInvoked(player, self.name, "offensive")
        room:broadcastSkillInvoke(self.name, 1)
        room:throwCard({ self.cost_data }, self.name, player, player)
        room:damage({
          from = player,
          to = target,
          damage = 1,
          damageType = fk.NormalDamage,
          skillName = self.name,
        })

        room:setPlayerMark(player, "powei_debuff-turn", target.id)
      elseif self.cost_data == "powei_prey" then
        room:notifySkillInvoked(player, self.name, "control")
        room:broadcastSkillInvoke(self.name, 1)
        local cardId = room:askForCardChosen(player, target, "h", self.name)
        room:obtainCard(player, cardId, false, fk.ReasonPrey)
        room:setPlayerMark(player, "powei_debuff-turn", target.id)
      end
    elseif event == fk.Damaged then
      room:setPlayerMark(target, "@@powei_wei", 0)
    else
      room:notifySkillInvoked(player, self.name, "negative")
      room:broadcastSkillInvoke(self.name, 3)
      room:updateQuestSkillState(player, self.name, true)
      if player.hp < 1 then
        room:recover({
          who = player,
          num = 1 - player.hp,
          recoverBy = player,
          skillName = self.name,
        })
      end

      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("@@powei_wei") > 0 then
          room:setPlayerMark(p, "@@powei_wei", 0)
        end
      end

      if #player:getCardIds(Player.Equip) > 0 then
        room:throwCard(player:getCardIds(Player.Equip), self.name, player, player)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["powei"] = "破围",
  [":powei"] = "使命技，游戏开始时，你令所有其他角色获得“围”标记；回合开始时，你令所有拥有“围”标记的角色将“围”标记移动至下家"..
  "（若下家为你，则改为移动至你的下家）；有“围”标记的角色受到伤害后，移去其“围”标记；有“围”的角色的回合开始时，你可以选择一项并令"..
  "你于本回合内视为处于其攻击范围内：1.弃置一张手牌，对其造成1点伤害；2.若其体力值不大于你，你获得其一张手牌。<br>\
  <strong>成功</strong>：回合开始时，若场上没有“围”标记，则你获得技能〖神著〗；<br>\
  <strong>失败</strong>：当你进入濒死状态时，若你的体力值小于1，你回复体力至1点，移去场上所有的“围”标记，然后弃置你装备区里所有的牌。",
  ["@@powei_wei"] = "围",
  ["powei_damage"] = "弃一张手牌对其造成1点伤害",
  ["powei_prey"] = "获得其1张手牌",
  ["#powei-damage"] = "破围：你可以弃置一张手牌，对 %dest 造成1点伤害",
  ["$powei1"] = "君且城中等候，待吾探敌虚实。",
  ["$powei2"] = "弓马骑射洒热血，突破重围显英豪！",
  ["$powei3"] = "敌军尚犹严防，有待明日再看！",
}

local poweiDebuff = fk.CreateAttackRangeSkill{  --FIXME!!!
  name = "#powei-debuff",
  within_func = function (self, from, to)
    return to:getMark("powei_debuff-turn") == from.id
  end,
}

powei:addRelatedSkill(poweiDebuff)
godTaishici:addSkill(powei)

local shenzhuo = fk.CreateTriggerSkill{
  name = "shenzhuo",
  events = {fk.CardUseFinished},
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self.name) and
      data.card.trueName == "slash" and
      not data.card:isVirtual()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, { "shenzhuo_drawOne", "shenzhuo_drawThree" }, self.name)
    if choice == "shenzhuo_drawOne" then
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "shenzhuo-turn")
    else
      player:drawCards(3, self.name)
      room:setPlayerMark(player, "@shenzhuo_debuff-turn", "shenzhuo_debuff")
    end
  end,
}
Fk:loadTranslationTable{
  ["shenzhuo"] = "神著",
  [":shenzhuo"] = "锁定技，当你使用非转化且非虚拟的【杀】结算结束后，你须选择一项：1.摸一张牌，令你于本回合内使用【杀】的次数上限+1；"..
  "2.摸三张牌，令你于本回合内不能使用【杀】。",
  ["shenzhuo_drawOne"] = "摸1张牌，可以继续出杀",
  ["shenzhuo_drawThree"] = "摸3张牌，本回合不能出杀",
  ["@shenzhuo_debuff-turn"] = "神著",
  ["shenzhuo_debuff"] = "不能出杀",
  ["$shenzhuo1"] = "力引强弓百斤，矢除贯手著棼！",
  ["$shenzhuo2"] = "箭既已在弦上，吾又岂能不发！",
}

local shenzhuoBuff = fk.CreateTargetModSkill{
  name = "#shenzhuo-buff",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("shenzhuo-turn")
    end
  end,
}

local shenzhuoDebuff = fk.CreateProhibitSkill{
  name = "#shenzhuo-debuff",
  prohibit_use = function(self, player, card)
    return player:getMark("@shenzhuo_debuff-turn") ~= 0 and card.trueName == "slash"
  end,
}

shenzhuo:addRelatedSkill(shenzhuoBuff)
shenzhuo:addRelatedSkill(shenzhuoDebuff)
godTaishici:addRelatedSkill(shenzhuo)

return extension
