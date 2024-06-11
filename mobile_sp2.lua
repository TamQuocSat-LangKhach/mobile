local extension = Package("mobile_sp2")
extension.extensionName = "mobile"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["mobile_sp2"] = "手杀-SP2",
  ["mob_sp"] = "手杀SP",
}

local simafu = General(extension, "simafu", "wei", 3)
simafu.subkingdom = "jin"
local xunde = fk.CreateTriggerSkill{
  name = "xunde",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and (player == target or player:distanceTo(target) == 1)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xunde-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.number >= 6 and player ~= target and not target.dead
    and room:getCardArea(judge.card.id) == Card.DiscardPile then
      room:obtainCard(target, judge.card)
    end
    if judge.card.number <= 6 and data.from and not data.from.dead then
      room:askForDiscard(data.from, 1, 1, false, self.name, false)
    end
  end,
}
local chenjie = fk.CreateTriggerSkill{
  name = "chenjie",
  anim_type = "drawcard",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForResponse(player, "", ".|.|"..data.card:getSuitString(),
      "#chenjie-invoke::"..target.id..":"..data.card:getSuitString(true)..":"..data.reason, true)
    if card then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(self.cost_data, player, data, self.name, false)
    if not player.dead then
      player:drawCards(2, self.name)
    end
  end,
}
simafu:addSkill(xunde)
simafu:addSkill(chenjie)
Fk:loadTranslationTable{
  ["simafu"] = "司马孚",
  ["#simafu"] = "阐忠弘道",
  ["illustrator:simafu"] = "鬼画府",

  ["xunde"] = "勋德",
  [":xunde"] = "当一名角色受到伤害后，若你与其距离1以内，你可判定，若点数不小于6且该角色不为你，你令其获得此判定牌；"..
  "若点数不大于6，你令来源弃置一张手牌。",
  ["chenjie"] = "臣节",
  [":chenjie"] = "当一名角色的判定牌生效前，你可以打出一张与判定牌相同花色的牌代替之，然后你摸两张牌。",
  ["#xunde-invoke"] = "勋德：%dest 受到伤害，你可以判定，根据点数执行效果",
  ["#chenjie-invoke"] = "臣节：你可以打出一张%arg牌修改 %dest 的 %arg2 判定并摸两张牌",

  ["$xunde1"] = "陛下所托，臣必尽心尽力！",
  ["$xunde2"] = "纵吾荏弱难持，亦不推诿君命！",
  ["$chenjie1"] = "臣心怀二心，不可事君也。",
  ["$chenjie2"] = "竭力致身，以尽臣节。",
  ["~simafu"] = "身辅六公，亦难报此恩……",
}

local mobile__simafu = General(extension, "mobile__simafu", "wei", 3)
mobile__simafu.subkingdom = "jin"
local panxiang = fk.CreateTriggerSkill{
  name = "panxiang",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"panxiang1", "panxiang2", "Cancel"}
    local choices = table.simpleClone(all_choices)
    if player:getMark("panxiang_"..target.id) ~= 0 then
      table.removeOne(choices, player:getMark("panxiang_"..target.id))
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#panxiang-invoke::"..target.id, false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "panxiang_"..target.id, self.cost_data)
    room:notifySkillInvoked(player, self.name, "support")
    room:doIndicate(player.id, {target.id})
    if self.cost_data == "panxiang1" then
      player:broadcastSkillInvoke(self.name, math.random(3, 4))
      data.damage = data.damage - 1
      if data.from and not data.from.dead then
        room:drawCards(data.from, 2, self.name)
      end
    else
      player:broadcastSkillInvoke(self.name, math.random(1, 2))
      data.damage = data.damage + 1
      if not target.dead then
        room:drawCards(target, 3, self.name)
      end
    end
  end,
}
local mobile__chenjie = fk.CreateTriggerSkill{
  name = "mobile__chenjie",
  anim_type = "drawcard",
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:hasSkill("panxiang", true) and player:getMark("panxiang_"..target.id) ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("hej")
    if not player.dead then
      player:drawCards(4, self.name)
    end
  end,
}
mobile__simafu:addSkill(panxiang)
mobile__simafu:addSkill(mobile__chenjie)
Fk:loadTranslationTable{
  ["mobile__simafu"] = "司马孚",
  ["#mobile__simafu"] = "徒难夷惠",
  --["illustrator:mobile__simafu"] = "鬼画府",

  ["panxiang"] = "蹒襄",
  [":panxiang"] = "当一名角色受到伤害时，你可以选择一项（不能选择上次对该角色发动时选择的选项）：1.令此伤害-1，然后伤害来源摸两张牌；"..
  "2.令此伤害+1，然后其摸三张牌。",
  ["mobile__chenjie"] = "臣节",
  [":mobile__chenjie"] = "若你有“蹒襄”，当一名成为过“蹒襄”目标的角色死亡后，你弃置你区域内所有牌，然后摸四张牌。",

  ["#panxiang-invoke"] = "蹒襄：是否改变 %dest 受到的伤害？",
  ["panxiang1"] = "伤害-1，伤害来源摸两张牌",
  ["panxiang2"] = "伤害+1，其摸三张牌",

  ["$panxiang1"] = "老臣受命督军，自竭拒吴蜀于疆外。",
  ["$panxiang2"] = "身负托孤之重，但坐论清谈，此亦可乎？",
  ["$panxiang3"] = "诸卿当早拜嗣君，以镇海内，而但哭邪？",
  ["$panxiang4"] = "殿下当以国事为重，奈何效匹夫之孝乎？",
  ["$mobile__chenjie1"] = "臣心怀二心，不可事君也。",
  ["$mobile__chenjie2"] = "竭力致身，以尽臣节。",
  ["~mobile__simafu"] = "生此篡逆之事，罪臣难辞其咎……",
}

local laimin = General(extension, "laimin", "shu", 3)
local laishou = fk.CreateTriggerSkill{
  name = "laishou",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.DamageInflicted then
        return data.damage >= player.hp and player.maxHp < 9
      elseif event == fk.EventPhaseStart then
        return player.phase == Player.Start and player.maxHp > 8
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      player:broadcastSkillInvoke(self.name, math.random(1, 2))
      room:notifySkillInvoked(player, self.name, "defensive")
      room:changeMaxHp(player, data.damage)
      return true
    elseif event == fk.EventPhaseStart then
      player:broadcastSkillInvoke(self.name, 3)
      room:notifySkillInvoked(player, self.name, "negative")
      room:killPlayer({who = player.id})
    end
  end,
}
local luanqun = fk.CreateActiveSkill{
  name = "luanqun",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#luanqun",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:doIndicate(player.id, table.map(room.alive_players, Util.IdMapper))
    local targets = table.filter(room.alive_players, function(p) return not p:isKongcheng() end)
    local extraData = {
      num = 1,
      min_num = 1,
      include_equip = false,
      pattern = ".",
      reason = self.name,
    }
    for _, p in ipairs(targets) do
      p.request_data = json.encode({"choose_cards_skill", "#luanqun-card", true, extraData})
    end
    room:notifyMoveFocus(room.alive_players, self.name)
    room:doBroadcastRequest("AskForUseActiveSkill", targets)
    for _, p in ipairs(targets) do
      local id
      if p.reply_ready then
        local replyCard = json.decode(p.client_reply).card
        id = json.decode(replyCard).subcards[1]
      else
        id = table.random(p:getCardIds("h"))
      end
      room:setPlayerMark(p, "luanqun-tmp", id)
    end

    local all_cards = {}
    for _, p in ipairs(targets) do
      if not p.dead then
        local id = p:getMark("luanqun-tmp")
        p:showCards({id})
        if table.contains(p:getCardIds("h"), id) then
          table.insertIfNeed(all_cards, id)
        end
      end
    end
    if player.dead or #all_cards == 0 then return end
    local my_card = Fk:getCardById(player:getMark("luanqun-tmp"))
    local available_cards = table.filter(all_cards, function(id) return Fk:getCardById(id).color == my_card.color end)
    table.removeOne(available_cards, my_card.id)
    local cards, choice = U.askforChooseCardsAndChoice(player, available_cards, {"OK"}, self.name, "#luanqun-get", {"Cancel"}, 1, 1, all_cards)
    if choice ~= "Cancel" then
      room:moveCardTo(Fk:getCardById(cards[1]), Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    end
    local mark = U.getMark(player, self.name)
    for _, p in ipairs(targets) do
      if not p.dead and p:getMark("luanqun-tmp") ~= 0 then
        local card = Fk:getCardById(p:getMark("luanqun-tmp"))
        room:setPlayerMark(p, "luanqun-tmp", 0)
        if card.color ~= my_card.color then
          table.insert(mark, p.id)
        end
      end
    end
    if not player.dead and #mark > 0 then
      room:setPlayerMark(player, self.name, mark)
    end
  end,
}
local luanqun_trigger = fk.CreateTriggerSkill{
  name = "#luanqun_trigger",
  mute = true,
  events = {fk.TurnStart, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return player:getMark("luanqun") ~= 0 and table.contains(player:getMark("luanqun"), target.id)
    elseif event == fk.TargetConfirmed then
      return target == player and data.card.trueName == "slash" and
        player.room:getPlayerById(data.from):getMark("luanqun"..player.id.."-turn") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local mark = U.getMark(player, "luanqun")
      table.removeOne(mark, target.id)
      room:setPlayerMark(player, "luanqun", mark)
      room:setPlayerMark(target, "luanqun"..player.id.."-turn", 1)
      room:setPlayerMark(target, "luanqun_target"..player.id.."-turn", 1)
    else
      local src = room:getPlayerById(data.from)
      room:setPlayerMark(src, "luanqun_target"..player.id.."-turn", 0)
      data.disresponsiveList = data.disresponsiveList or {}
      table.insertIfNeed(data.disresponsiveList, player.id)
    end
  end,
}
local luanqun_prohibit = fk.CreateProhibitSkill{
  name = "#luanqun_prohibit",
  is_prohibited = function(self, from, to, card)
    if card.trueName == "slash" and from.phase == Player.Play then
      local targets = table.filter(Fk:currentRoom().alive_players, function(p)
        return from:getMark("luanqun_target"..p.id.."-turn") > 0
      end)
      return #targets > 0 and not table.contains(targets, to)
    end
  end,
}
luanqun:addRelatedSkill(luanqun_trigger)
luanqun:addRelatedSkill(luanqun_prohibit)
laimin:addSkill(laishou)
laimin:addSkill(luanqun)
Fk:loadTranslationTable{
  ["laimin"] = "来敏",
  ["#laimin"] = "悖骴乱群",
  ["laishou"] = "来寿",
  [":laishou"] = "锁定技，当你受到致命伤害时，若你的体力上限小于9，防止此伤害并增加等量的体力上限。准备阶段，若你的体力上限不小于9，你死亡。",
  ["luanqun"] = "乱群",
  [":luanqun"] = "出牌阶段限一次，若你有手牌，你可以令所有角色同时展示一张手牌，然后你可以获得其中一张与你展示牌颜色相同的牌。令所有与你"..
  "展示牌颜色不同的角色于其下回合出牌阶段使用第一张【杀】只能指定你为目标，且你不能响应其下回合使用的【杀】。",
  ["#luanqun"] = "乱群：令所有角色展示一张手牌，你可以获得其中一张与你展示颜色相同的牌",
  ["#luanqun-card"] = "乱群：请展示一张手牌",
  ["#luanqun-get"] = "乱群：你可以获得其中一张牌",

  ["$laishou1"] = "黄耇鲐背，谓之永年。",
  ["$laishou2"] = "养怡和之福，得乔松之寿。",
  ["$laishou3"] = "福寿将终，竟未得期颐！",
  ["$luanqun1"] = "年过杖朝，自是从心所欲，何来逾矩之理？",
  ["$luanqun2"] = "位居执慎，博涉多闻，更应秉性而论！",
  ["~laimin"] = "狂嚣之言，一言十过啊……",
}

local huban = General(extension, "mobile__huban", "wei", 4)
local yilie = fk.CreateTriggerSkill{
  name = "mobile__yilie",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and table.find(player.room.alive_players, function(p) return p ~= player end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(
      player,
      table.map(room:getOtherPlayers(player), Util.IdMapper),
      1,
      1,
      "#mobile__yilie-choose",
      self.name,
      false
    )[1]

    local toPlayer = room:getPlayerById(to)
    local yiliePlayers = U.getMark(toPlayer, "@@mobile__yilie")
    table.insertIfNeed(yiliePlayers, player.id)
    room:setPlayerMark(toPlayer, "@@mobile__yilie", yiliePlayers)
  end,
}
local yilieDelay = fk.CreateTriggerSkill{
  name = "#yilie_delay",
  events = {fk.DamageInflicted, fk.Damage, fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:isAlive() then
      return false
    end

    if event == fk.DamageInflicted then
      return table.contains(U.getMark(target, "@@mobile__yilie"), player.id) and player:getMark("@mobile__yilie_lie") == 0
    elseif event == fk.Damage then
      if not target then return end
      return table.contains(U.getMark(target, "@@mobile__yilie"), player.id) and data.to ~= player and player:isWounded()
    else
      return target == player and player.phase == Player.Finish and player:getMark("@mobile__yilie_lie") > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, "mobile__yilie", "support")
    player:broadcastSkillInvoke("mobile__yilie")

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      room:setPlayerMark(player, "@mobile__yilie_lie", data.damage)
      return true
    elseif event == fk.Damage then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    else
      player:drawCards(1, self.name)
      room:loseHp(player, player:getMark("@mobile__yilie_lie"), self.name)
      room:setPlayerMark(player, "@mobile__yilie_lie", 0)
    end
  end,
}
yilie:addRelatedSkill(yilieDelay)
huban:addSkill(yilie)
Fk:loadTranslationTable{
  ["mobile__huban"] = "胡班",
  ["#mobile__huban"] = "昭义烈勇",

  ["mobile__yilie"] = "义烈",
  [":mobile__yilie"] = "锁定技，游戏开始时，你选择一名其他角色。当该角色受到伤害时，若你没有“烈”标记，则你获得等同于伤害值数量的“烈”标记，" ..
  "然后防止此伤害；当该角色对其他角色造成伤害后，你回复1点体力；结束阶段开始时，若你有“烈”标记，则你摸一张牌并失去X点体力（X为你的“烈”标记数），" ..
  "然后移去你的所有“烈”标记。",
  ["#yilie_delay"] = "义烈",
  ["@@mobile__yilie"] = "义烈",
  ["@mobile__yilie_lie"] = "烈",
  ["#mobile__yilie-choose"] = "义烈：请选择一名其他角色，你为其抵挡伤害，且其造成伤害后你回复体力",

  ["$mobile__yilie1"] = "禽兽尚且知义，而况于人乎？",
  ["$mobile__yilie2"] = "班虽无名，亦有忠义在骨！",
  ["$mobile__yilie3"] = "身不慕生，宁比泰山之重！",
  ["~mobile__huban"] = "生虽微而志不可改，位虽卑而节不可夺……",
}

local chengui = General(extension, "mobile__chengui", "qun", 3)
local guimou = fk.CreateTriggerSkill{
  name = "guimou",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.TurnEnd, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return
      (
        event == fk.GameStart or
        target == player
      ) and
      player:hasSkill(self) and
      (
        event ~= fk.EventPhaseStart or
        (player.phase == Player.Start and player:getMark("@[private]guimou") ~= 0)
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local targets = {}
      local minValue = 999
      for _, p in ipairs(room:getOtherPlayers(player)) do
        local recordVal = p.tag["guimou_record" .. player.id] or 0
        if minValue >= recordVal then
          if minValue > recordVal then
            targets = {}
            minValue = recordVal
          end
          if not p:isKongcheng() then
            table.insert(targets, p.id)
          end
        end
      end

      if #targets > 0 then
        local to = targets[1]
        if #targets > 1 then
          to = room:askForChoosePlayers(player, targets, 1, 1, "#guimou-invoke", self.name, true)[1]
        end

        local choices = {"guimou_option_discard"}
        local canGive = table.filter(room.alive_players, function(p) return p.id ~= to and p ~= player end)
        if #canGive > 0 then
          table.insert(choices, 1, "guimou_option_give")
        end
        local ids, choice = U.askforChooseCardsAndChoice(
          player,
          room:getPlayerById(to):getCardIds("h"),
          choices,
          self.name,
          "#guimou-view::" .. to,
          {"Cancel"},
          1,
          1
        )

        if choice == "guimou_option_give" then
          local toGive = room:askForChoosePlayers(
            player,
            table.map(canGive, Util.IdMapper),
            1,
            1,
            "#guimou-give:::" .. Fk:getCardById(ids[1]):toLogString(),
            self.name,
            false
          )[1]
          room:obtainCard(room:getPlayerById(toGive), ids[1], false, fk.ReasonGive, player.id)
        elseif choice == "guimou_option_discard" then
          room:throwCard(ids, self.name, room:getPlayerById(to), player)
        end
      end

      for _, p in ipairs(room.alive_players) do
        p.tag["guimou_record" .. player.id] = nil
      end
      room:setPlayerMark(player, "@[private]guimou", 0)
    else
      local choices = { "guimou_use", "guimou_discard", "guimou_gain" }
      local choice
      if event == fk.GameStart then
        choice = table.random(choices)
      else
        choice = room:askForChoice(player, choices, self.name, "#guimou-choose")
      end

      for _, p in ipairs(room.alive_players) do
        p.tag["guimou_record" .. player.id] = nil
      end
      U.setPrivateMark(player, "guimou", { choice })
    end
  end,

  refresh_events = {fk.EventPhaseEnd, fk.AfterCardUseDeclared, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      return target == player and player.phase == Player.Start and player:getMark("@[private]guimou") ~= 0
    elseif event == fk.AfterCardUseDeclared then
      return target ~= player and U.getPrivateMark(player, "guimou")[1] == "guimou_use"
    else
      local guimouMark = U.getPrivateMark(player, "guimou")[1]
      if guimouMark == "guimou_discard" then
        return table.find(data, function(info)
          return info.moveReason == fk.ReasonDiscard and info.proposer and info.proposer ~= player.id
        end)
      elseif guimouMark == "guimou_gain" then
        return table.find(data, function(info)
          return info.toArea == Player.Hand and info.to and info.to ~= player.id
        end)
      end
    end

    return false
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      for _, p in ipairs(room.alive_players) do
        p.tag["guimou_record" .. player.id] = nil
      end
      room:setPlayerMark(player, "@[private]guimou", 0)
    elseif event == fk.AfterCardUseDeclared then
      target.tag["guimou_record" .. player.id] = (target.tag["guimou_record" .. player.id] or 0) + 1
    else
      local guimouMark = U.getPrivateMark(player, "guimou")[1]
      if guimouMark == "guimou_discard" then
        table.forEach(data, function(info)
          if info.moveReason == fk.ReasonDiscard and info.proposer and info.proposer ~= player.id then
            local to = room:getPlayerById(info.proposer)
            to.tag["guimou_record" .. player.id] = (to.tag["guimou_record" .. player.id] or 0) + #info.moveInfo
          end
        end)
      elseif guimouMark == "guimou_gain" then
        table.forEach(data, function(info)
          if info.toArea == Player.Hand and info.to and info.to ~= player.id then
            local to = room:getPlayerById(info.to)
            to.tag["guimou_record" .. player.id] = (to.tag["guimou_record" .. player.id] or 0) + #info.moveInfo
          end
        end)
      end
    end
  end,
}
local zhouxian = fk.CreateTriggerSkill{
  name = "zhouxian",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and data.card.is_damage_card
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3)
    room:moveCardTo(ids, Card.Processing, nil, fk.ReasonJustMove, self.name)
    local types = {}
    for _, id in ipairs(ids) do
      table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
    end

    room:moveCardTo(
      table.filter(ids, function(id) return room:getCardArea(id) == Card.Processing end),
      Card.DiscardPile,
      nil,
      fk.ReasonPutIntoDiscardPile,
      self.name,
      nil,
      true,
      player.id
    )

    local from = room:getPlayerById(data.from)
    if from:isAlive() then
      local toDiscard = room:askForDiscard(
        from,
        1,
        1,
        true,
        self.name,
        true,
        ".|.|.|.|.|" .. table.concat(types, ","),
        "#zhouxian-discard::" .. player.id .. ":" .. data.card:toLogString()
      )

      if #toDiscard > 0 then
        return false
      end
    end

    AimGroup:cancelTarget(data, player.id)
    return true
  end,
}
chengui:addSkill(guimou)
chengui:addSkill(zhouxian)
Fk:loadTranslationTable{
  ["mobile__chengui"] = "陈珪",
  ["#mobile__chengui"] = "弄辞巧掇",

  ["guimou"] = "诡谋",
  [":guimou"] = "锁定技，游戏开始时你随机选择一项，或回合结束时你选择一项：直到你的下个准备阶段开始时，1.记录使用牌最少的其他角色；" ..
  "2.记录弃置牌最少的其他角色；3.记录获得牌最少的其他角色。准备阶段开始时，你选择被记录的一名角色，观看其手牌并可选择其中一张牌，" ..
  "弃置此牌或将此牌交给另一名其他角色。",
  ["zhouxian"] = "州贤",
  [":zhouxian"] = "锁定技，当你成为其他角色使用伤害牌的目标时，你亮出牌堆顶三张牌，然后其须弃置一张亮出牌中含有的一种类别的牌，否则取消此目标。",
  ["@[private]guimou"] = "诡谋",
  ["#guimou-choose"] = "诡谋：你选择一项，你下个准备阶段令该项值最少的角色受到惩罚",
  ["guimou_use"] = "使用牌",
  ["guimou_discard"] = "弃置牌",
  ["guimou_gain"] = "获得牌",
  ["guimou_option_give"] = "给出此牌",
  ["guimou_option_discard"] = "弃置此牌",
  ["#guimou-invoke"] = "诡谋：选择其中一名角色查看其手牌，可选择其中一张给出或弃置",
  ["#guimou-give"] = "诡谋：将 %arg 交给另一名其他角色",
  ["#guimou-view"] = "当前观看的是 %dest 的手牌",
  ["#zhouxian-discard"] = "州贤：请弃置一张亮出牌中含有的一种类别的牌，否则取消 %arg 对 %dest 的目标",

  ["$guimou1"] = "不过卒合之师，岂是将军之敌乎？",
  ["$guimou2"] = "连鸡势不俱栖，依珪计便可一一解离。",
  ["$zhouxian1"] = "今未有苛暴之乱，汝敢言失政之语。",
  ["$zhouxian2"] = "曹将军神武应期，如何以以身试祸。",
  ["~mobile__chengui"] = "布非忠良之士，将军宜早图之……",
}

local muludawang = General(extension, "muludawang", "qun", 3)
muludawang.shield = 1
local shoufa = fk.CreateTriggerSkill{
  name = "shoufa",
  anim_type = "offensive",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self)) then
      return false
    end

    local room = player.room
    if event == fk.Damage then
      return U.getActualDamageEvents(room, 1, function(e) return e.data[1].from == player end)[1].data[1] == data
    else
      return
        player:usedSkillTimes(self.name, Player.HistoryTurn) < (5 + player:getMark("shoufa_damage_triggered-turn")) and
        table.find(
          room.alive_players,
          function(p)
            local distance = table.contains({"m_1v2_mode", "brawl_mode"}, room.settings.gameMode) and 0 or 1
            return p ~= player and p:distanceTo(player) > distance
          end
        )
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local isDoudizhu = table.contains({"m_1v2_mode", "brawl_mode"}, room.settings.gameMode)
    local targets = table.filter(
      room.alive_players,
      function(p)
        if event == fk.Damage then
          return player:distanceTo(p) < (isDoudizhu and 2 or 3)
        end

        return p:distanceTo(player) > (isDoudizhu and 0 or 1)
      end
    )

    if #targets > 0 then
      local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#shoufa-choose", self.name)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:setPlayerMark(player, "shoufa_damage_triggered-turn", 1)
    end

    local targetPlayer = room:getPlayerById(self.cost_data)
    local beasts = { "shoufa_bao", "shoufa_ying", "shoufa_xiong", "shoufa_tu" }
    local beast = type(player:getMark("@zhoulin")) == "string" and player:getMark("@zhoulin") or table.random(beasts)

    if beast == beasts[1] then
      room:damage({
        to = targetPlayer,
        damage = 1,
        damageType = fk.NormalDamage,
        skillName = self.name,
      })
    elseif beast == beasts[2] then
      if targetPlayer == player then
        if #player:getCardIds("e") > 0 then
          room:obtainCard(player, table.random(player:getCardIds("e")), true, fk.ReasonPrey, player.id)
        end
      elseif not targetPlayer:isNude() then
        room:obtainCard(player, table.random(targetPlayer:getCardIds("he")), false, fk.ReasonPrey, player.id)
      end
    elseif beast == beasts[3] then
      local equips = table.filter(
        targetPlayer:getCardIds("e"),
        function(id) return not (player == targetPlayer and player:prohibitDiscard(Fk:getCardById(id))) end
      )
      if #equips > 0 then
        room:throwCard(table.random(equips), self.name, targetPlayer, player)
      end
    else
      targetPlayer:drawCards(1, self.name)
    end

    return false
  end,
}
local zhoulin = fk.CreateActiveSkill{
  name = "zhoulin",
  anim_type = "support",
  prompt = "#zhoulin",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:hasSkill(shoufa)
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:changeShield(player, 2)

    local choiceList = { "zhoulin_bao", "zhoulin_ying", "zhoulin_xiong", "zhoulin_tu" }
    local choice = room:askForChoice(player, choiceList, self.name)
    room:setPlayerMark(player, "@zhoulin", "shoufa_" .. choice:split("_")[2])
  end,
}
local zhoulinRefresh = fk.CreateTriggerSkill{
  name = "#zhoulin_refresh",
  refresh_events = { fk.TurnStart },
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@zhoulin") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@zhoulin", 0)
  end,
}
local yuxiang = fk.CreateTriggerSkill{
  name = "yuxiang",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = { fk.DamageInflicted },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.shield > 0 and data.damageType == fk.FireDamage
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local yuxiangDistance = fk.CreateDistanceSkill{
  name = "#yuxiang_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(yuxiang) and from.shield > 0 then
      return -1
    elseif to:hasSkill(yuxiang) and to.shield > 0 then
      return 1
    end

    return 0
  end,
}
zhoulin:addRelatedSkill(zhoulinRefresh)
yuxiang:addRelatedSkill(yuxiangDistance)
muludawang:addSkill(shoufa)
muludawang:addSkill(zhoulin)
muludawang:addSkill(yuxiang)
Fk:loadTranslationTable{
  ["muludawang"] = "木鹿大王",
  ["#muludawang"] = "八纳洞主",

  ["shoufa"] = "兽法",
  [":shoufa"] = "当你每回合首次造成伤害后，你可以选择你距离2以内的一名角色；每回合限五次，当你受到伤害后，" ..
  "你可以选择与你距离大于1的一名角色（若为斗地主，则上述距离改为你距离1以内和与你距离不小于1）。其随机执行一种效果：" ..
  "豹，其受到1点无来源伤害；鹰，你随机获得其一张牌；熊，你随机弃置其装备区里的一张牌；兔，其摸一张牌。",
  ["zhoulin"] = "咒鳞",
  [":zhoulin"] = "限定技，出牌阶段，若你有“兽法”，则你可以获得2点护甲并选择一种野兽效果，令你直到你的下个回合开始，" ..
  "“兽法”必定执行此野兽效果。",
  ["yuxiang"] = "御象",
  [":yuxiang"] = "锁定技，若你有护甲，则你拥有以下效果：你计算与其他角色的距离-1；其他角色计算与你的距离+1；当你受到火焰伤害时，此伤害+1。",
  ["#shoufa-choose"] = "兽法：请选择一名角色令其执行野兽效果",
  ["shoufa_bao"] = "豹",
  ["shoufa_ying"] = "鹰",
  ["shoufa_xiong"] = "熊",
  ["shoufa_tu"] = "兔",
  ["@zhoulin"] = "咒鳞",
  ["#zhoulin"] = "你可以选择一种野兽，令兽法直到你下回合开始前必定执行此效果",
  ["zhoulin_bao"] = "豹：受到伤害",
  ["zhoulin_ying"] = "鹰：被你获得牌",
  ["zhoulin_xiong"] = "熊：被你弃装备区牌",
  ["zhoulin_tu"] = "兔：摸牌",

  ["$shoufa1"] = "毒蛇恶蝎，奉旨而行！",
  ["$shoufa2"] = "虎豹豺狼，皆听我令！",
  ["$zhoulin1"] = "料一山野书生，安识我南中御兽之术！",
  ["$zhoulin2"] = "本大王承天大法，岂与诸葛亮小计等同！",
  ["$yuxiang1"] = "额啊啊，好大的火光啊！",
  ["~muludawang"] = "啊啊，诸葛亮神人降世，吾等难挡天威。",
}

local jianggan = General(extension, "mobile__jianggan", "wei", 3)
local daoshu = fk.CreateActiveSkill{
  name = "mobile__daoshu",
  prompt = "#mobile__daoshu",
  mute = true,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local room = Fk:currentRoom()
    local target = room:getPlayerById(to_select)
    if target:getHandcardNum() < 2 then
      return false
    end

    if table.contains({"m_1v2_mode", "brawl_mode", "m_2v2_mode"}, room.room_settings.gameMode) then
      return target.role ~= Self.role
    end

    return to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke(self.name, 1)
    room:notifySkillInvoked(player, self.name, "offensive")
    local target = room:getPlayerById(effect.tos[1])

    local cardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not card.is_derived then
        table.insertIfNeed(cardNames, card.name)
      end
    end
    local randomNames = table.random(cardNames, 3)
    room:setPlayerMark(target, "mobile__daoshu_names", randomNames)
    local _, dat = room:askForUseActiveSkill(target, "mobile__daoshu_choose", "#mobile__daoshu-choose", false)
    room:setPlayerMark(target, "mobile__daoshu_names", 0)

    local cardChosen = dat and dat.cards[1] or table.random(target:getCardIds("h"))
    local newName = dat and dat.interaction or table.random(
      table.filter(randomNames,
      function(name) return name ~= Fk:getCardById(cardChosen).name end)
    )
    local newHandIds = table.map(target:getCardIds("h"), function(id)
      if id == cardChosen then
        local card = Fk:getCardById(id)
        return {
          cid = 0,
          name = newName,
          extension = card.package.extensionName,
          number = card.number,
          suit = card:getSuitString(),
          color = card:getColorString(),
        }
      end

      return id
    end)

    local friends = { player }
    if table.contains({"m_1v2_mode", "brawl_mode", "m_2v2_mode"}, room.settings.gameMode) then
      friends = U.GetFriends(room, player)
    end
    for _, p in ipairs(friends) do
      p.request_data = json.encode({
        path = "packages/utility/qml/ChooseCardsAndChoiceBox.qml",
        data = {
          newHandIds,
          { "OK" },
          "#mobile__daoshu-guess",
          nil,
          1,
          1,
          {}
        },
      })
    end

    room:notifyMoveFocus(friends, self.name)
    room:doBroadcastRequest("CustomDialog", friends)

    local friendIds = table.map(friends, Util.IdMapper)
    room:sortPlayersByAction(friendIds)
    for _, pid in ipairs(friendIds) do
      local p = room:getPlayerById(pid)
      if p:isAlive() then
        local cardGuessed
        if p.reply_ready then
          cardGuessed = json.decode(p.client_reply).cards[1]
        else
          cardGuessed = table.random(target:getCardIds("h"))
        end

        if cardGuessed == 0 then
          if p == player then
            player:broadcastSkillInvoke(self.name, 2)
          end
          room:damage{
            from = p,
            to = target,
            damage = 1,
            skillName = self.name,
          }
        else
          if p == player then
            player:broadcastSkillInvoke(self.name, 3)
          end
          if# p:getCardIds("h") > 1 then
            local canDiscard = table.filter(p:getCardIds("h"), function(id) return not p:prohibitDiscard(Fk:getCardById(id)) end)
            if #canDiscard then
              room:throwCard(table.random(canDiscard, 2), self.name, p, p)
            end
          else
            room:loseHp(p, 1, self.name)
          end
        end
      end
    end
  end,
}
local daoshuChoose = fk.CreateActiveSkill{
  name = "mobile__daoshu_choose",
  mute = true,
  card_num = 1,
  target_num = 0,
  interaction = function()
    return UI.ComboBox { choices = Self:getMark("mobile__daoshu_names") }
  end,
  card_filter = function(self, to_select, selected)
    return
      #selected == 0 and
      Fk:currentRoom():getCardArea(to_select) == Player.Hand and
      Fk:getCardById(to_select).name ~= self.interaction.data
  end,
  target_filter = Util.FalseFunc,
}
local daizui = fk.CreateTriggerSkill{
  name = "daizui",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = { fk.DamageInflicted },
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      math.max(0, player.hp) + player.shield <= data.damage and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card and data.from:isAlive() and U.hasFullRealCard(room, data.card) then
      data.from:addToPile("daizui_shi", data.card, true, self.name)
    end
    return true
  end,
}
local daizuiRegain = fk.CreateTriggerSkill{
  name = "#daizui_regain",
  mute = true,
  events = { fk.TurnEnd },
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("daizui_shi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, player:getPile("daizui_shi"), true, fk.ReasonPrey, player.id, "daizui")
  end,
}
Fk:addSkill(daoshuChoose)
daizui:addRelatedSkill(daizuiRegain)
jianggan:addSkill(daoshu)
jianggan:addSkill(daizui)
Fk:loadTranslationTable{
  ["mobile__jianggan"] = "蒋干",
  ["#mobile__jianggan"] = "虚义伪诚",

  ["mobile__daoshu"] = "盗书",
  [":mobile__daoshu"] = "出牌阶段限一次，你可以选择一名手牌数不少于2的其他角色，该角色从随机三个牌名中选择一个，" ..
  "并将一张牌名不同的手牌伪装成此牌名的牌，然后你观看其伪装后的手牌，并猜测其中伪装过的牌（若为2v2或斗地主，" ..
  "则改为选择一名手牌数不少于2的敌方角色，且你与友方角色同时猜测）。猜中的角色对该角色各造成1点伤害，" ..
  "猜错的角色分别随机弃置两张手牌，若手牌不足则改为失去1点体力。",
  ["daizui"] = "戴罪",
  [":daizui"] = "限定技，当你受到伤害时，若伤害值不小于你的体力值和护甲之和，你可以防止此伤害，然后将对你造成伤害的牌置于伤害来源的武将牌上，" ..
  "称为“释”。本回合结束时，其获得其“释”。",
  ["#mobile__daoshu"] = "盗书：你可与队友查看1名敌人的手牌，并找出其伪装牌名的牌",
  ["mobile__daoshu_choose"] = "盗书伪装",
  ["#mobile__daoshu-choose"] = "盗书：请选择左侧的牌名并选择一张手牌，将此牌伪装成此牌名",
  ["#mobile__daoshu-guess"] = "猜测其中伪装牌名的牌",
  ["daizui_shi"] = "释",
  ["#daizui_regain"] = "戴罪",

  ["$mobile__daoshu1"] = "嗨！不过区区信件，何妨故友一观？",
  ["$mobile__daoshu2"] = "幸吾有备而来，不然为汝所戏矣。",
  ["$mobile__daoshu3"] = "亏我一世英名，竟上了周瑜的大当！",
  ["$daizui1"] = "望丞相权且记过，容干将功折罪啊！",
  ["$daizui2"] = "干，谢丞相不杀之恩！",
  ["~mobile__jianggan"] = "唉，假信害我不浅啊……",
}

local yangfeng = General(extension, "yangfeng", "qun", 4)
local xuetu = fk.CreateActiveSkill{
  name = "xuetu",
  anim_type = "support",
  switch_skill_name = "xuetu",
  card_num = 0,
  target_num = 1,
  prompt = function(self)
    return "#xuetu_" .. Self:getSwitchSkillState(self.name, false, true)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return
      #selected == 0 and
      not (Self:getSwitchSkillState(self.name) == fk.SwitchYang and not Fk:currentRoom():getPlayerById(to_select):isWounded())
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    else
      target:drawCards(2, self.name)
    end
  end,
}
local xuetuV2 = fk.CreateActiveSkill{
  name = "xuetu_v2",
  card_num = 0,
  target_num = 1,
  mute = true,
  interaction = function()
    local options = { "xuetu_v2_recover", "xuetu_v2_draw" }
    local choices = table.filter(options, function(option) return not table.contains(U.getMark(Self, "xuetu_v2_used-phase"), option) end)
    return UI.ComboBox {choices = choices, all_choices = options }
  end,
  can_use = function(self, player)
    return #U.getMark(player, "xuetu_v2_used-phase") < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return
      #selected == 0 and
      not (self.interaction.data == "xuetu_v2_recover" and not Fk:currentRoom():getPlayerById(to_select):isWounded())
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke(xuetu.name)
    room:notifySkillInvoked(player, self.name, "support")
    local target = room:getPlayerById(effect.tos[1])

    local xuetuUsed = U.getMark(player, "xuetu_v2_used-phase")
    table.insertIfNeed(xuetuUsed, self.interaction.data)
    room:setPlayerMark(player, "xuetu_v2_used-phase", xuetuUsed)

    if self.interaction.data == "xuetu_v2_recover" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    else
      target:drawCards(2, self.name)
    end
  end,
}
local xuetuV3 = fk.CreateActiveSkill{
  name = "xuetu_v3",
  anim_type = "offensive",
  switch_skill_name = "xuetu_v3",
  card_num = 0,
  target_num = 1,
  prompt = function(self)
    return "#xuetu_v3_" .. Self:getSwitchSkillState(self.name, false, true)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }

      room:askForDiscard(target, 2, 2, true, self.name, false)
    else
      player:drawCards(1, self.name)
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local weiming = fk.CreateTriggerSkill{
  name = "weiming",
  mute = true,
  frequency = Skill.Quest,
  events = {fk.EventPhaseStart, fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    if player:getQuestSkillState(self.name) or not player:hasSkill(self) then
      return false
    end

    local room = player.room
    if event == fk.EventPhaseStart then
      return
        target == player and
        player.phase == Player.Play and
        table.find(room.alive_players, function(p) return p ~= player and not table.contains(U.getMark(p, "@@weiming"), player.id) end)
    end

    return table.contains(player.tag["weimingTargets"] or {}, data.who) or (data.damage and data.damage.from == player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "offensive")

      local targets = table.map(
        table.filter(
          room.alive_players,
          function(p) return p ~= player and not table.contains(U.getMark(p, "@@weiming"), player.id) end
        ),
        Util.IdMapper
      )
      if #targets == 0 then
        return false
      end

      local toId = room:askForChoosePlayers(player, targets, 1, 1, "#weiming-choose", self.name, false)[1]
      local to = room:getPlayerById(toId)

      local weimingTargets = player.tag["weimingTargets"] or {}
      table.insertIfNeed(weimingTargets, toId)
      player.tag["weimingTargets"] = weimingTargets

      local weimingOwners = U.getMark(to, "@@weiming")
      table.insertIfNeed(weimingOwners, player.id)
      room:setPlayerMark(to, "@@weiming", weimingOwners)
    else
      for _, p in ipairs(room.alive_players) do
        local weimingOwners = U.getMark(p, "@@weiming")
        table.removeOne(weimingOwners, player.id)
        room:setPlayerMark(p, "@@weiming", #weimingOwners > 0 and weimingOwners or 0)
      end
      if table.contains(player.tag["weimingTargets"] or {}, data.who) then
        player:broadcastSkillInvoke(self.name, 3)
        room:notifySkillInvoked(player, self.name, "negative")
        room:updateQuestSkillState(player, self.name, true)
        room:handleAddLoseSkills(player, "-xuetu|-xuetu_v2|xuetu_v3")
      else
        player:broadcastSkillInvoke(self.name, 2)
        room:notifySkillInvoked(player, self.name, "offensive")
        room:updateQuestSkillState(player, self.name)
        room:handleAddLoseSkills(player, "-xuetu|-xuetu_v3|xuetu_v2")
      end
    end
  end,
}
yangfeng:addSkill(xuetu)
yangfeng:addSkill(weiming)
yangfeng:addRelatedSkill(xuetuV2)
yangfeng:addRelatedSkill(xuetuV3)
Fk:loadTranslationTable{
  ["yangfeng"] = "杨奉",
  ["#yangfeng"] = "忠勇半途",

  ["xuetu"] = "血途",
  [":xuetu"] = "转换技，出牌阶段限一次，你可以：阳，令一名角色回复1点体力；阴，令一名角色摸两张牌。" ..
  "<br><strong>二级</strong>：出牌阶段各限一次，你可以选择一项：1.令一名角色回复1点体力；2.令一名角色摸两张牌。" ..
  "<br><strong>三级</strong>：转换技，出牌阶段限一次，你可以：阳，回复1点体力并令一名角色弃置两张牌；阴，摸一张牌并对一名角色造成1点伤害。",
  ["xuetu_v2"] = "血途",
  [":xuetu_v2"] = "出牌阶段各限一次，你可以选择一项：1.令一名角色回复1点体力；2.令一名角色摸两张牌。",
  ["xuetu_v3"] = "血途",
  [":xuetu_v3"] = "转换技，出牌阶段限一次，你可以：阳，回复1点体力并令一名角色弃置两张牌；阴，摸一张牌并对一名角色造成1点伤害。",
  ["weiming"] = "威命",
  [":weiming"] = "使命技，出牌阶段开始时，你标记一名未标记过的其他角色。<br>" ..
  "<strong>成功</strong>：当你杀死一名未标记的角色后，你将“血途”修改至二级；<br>" ..
  "<strong>失败</strong>：当一名已被标记的角色死亡后，你将“血途”修改至三级；<br>",
  ["#xuetu_yang"] = "血途：你可令一名角色回复1点体力",
  ["#xuetu_yin"] = "血途：你可令一名角色摸两张牌",
  ["xuetu_v2_recover"] = "令一名角色回复1点体力",
  ["xuetu_v2_draw"] = "令一名角色摸两张牌",
  ["#xuetu_v3_yang"] = "血途：你可回复1点体力并令一名角色弃两张牌",
  ["#xuetu_v3_yin"] = "血途：你可摸一张牌并对一名角色造成1点伤害",
  ["@@weiming"] = "威命",
  ["#weiming-choose"] = "威命：选择1名未被选择过的角色，如其在你杀死其他未被选择过的角色死亡前死亡，则威命失败",

  ["$xuetu1"] = "天子仪仗在此，逆贼安扰圣驾。",
  ["$xuetu2"] = "末将救驾来迟，还望陛下恕罪。",
  ["$xuetu_v31"] = "徐、扬粮草甚多，众将随我前往。",
  ["$xuetu_v32"] = "哈哈哈哈，所过之处，粒粟不留。",
  ["$weiming1"] = "诸位东归洛阳，奉愿随驾以护。",
  ["$weiming2"] = "不遵皇命，视同倡乱之贼。",
  ["$weiming3"] = "布局良久，于今功亏一篑啊。",
  ["~yangfeng"] = "刘备！本共图吕布，何设鸿门相欺！",
}

local guanqiujian = General(extension, "mob_sp__guanqiujian", "wei", 4)
local cuizhen = fk.CreateTriggerSkill{
  name = "cuizhen",
  anim_type = "control",
  events = {fk.GameStart, fk.TargetSpecified, fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return table.contains({"aaa_role_mode", "aab_role_mode", "vanished_dragon"}, room.settings.gameMode) and
          table.find(room:getOtherPlayers(player), function(p)
            return #p:getAvailableEquipSlots(Card.SubtypeWeapon) > 0
          end)
      elseif event == fk.TargetSpecified and target == player and player.phase == Player.Play and data.card.is_damage_card then
        local to = player.room:getPlayerById(data.to)
        return not to.dead and to:getHandcardNum() >= to.hp and #to:getAvailableEquipSlots(Card.SubtypeWeapon) > 0
      elseif event == fk.DrawNCards and target == player then
        return table.find(player.room.alive_players, function(p)
          return table.contains(p.sealedSlots, Player.WeaponSlot)
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return #p:getAvailableEquipSlots(Card.SubtypeWeapon) > 0
      end), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 2, "#cuizhen-choose", self.name)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    elseif event == fk.TargetSpecified then
      return player.room:askForSkillInvoke(player, self.name, data, "#cuizhen-invoke::"..data.to)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:sortPlayersByAction(self.cost_data)
      for _, id in ipairs(self.cost_data) do
        local p = room:getPlayerById(id)
        if not p.dead and #p:getAvailableEquipSlots(Card.SubtypeWeapon) > 0 then
          room:abortPlayerArea(p, Player.WeaponSlot)
        end
      end
    elseif event == fk.TargetSpecified then
      room:doIndicate(player.id, {data.to})
      room:abortPlayerArea(room:getPlayerById(data.to), Player.WeaponSlot)
    elseif event == fk.DrawNCards then
      local n = 0
      for _, p in ipairs(room.alive_players) do
        for _, slot in ipairs(p.sealedSlots) do
          if slot == Player.WeaponSlot then
            n = n + 1
          end
        end
      end
      data.n = data.n + math.min(n, 2)
    end
  end,
}
local kuili = fk.CreateTriggerSkill{
  name = "kuili",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player:isKongcheng() then
      room:askForDiscard(player, data.damage, data.damage, false, self.name, false)
    end
    if data.from and not data.from.dead and table.contains(data.from.sealedSlots, Player.WeaponSlot) then
      room:resumePlayerArea(data.from, Player.WeaponSlot)
    end
  end,
}
guanqiujian:addSkill(cuizhen)
guanqiujian:addSkill(kuili)
Fk:loadTranslationTable{
  ["mob_sp__guanqiujian"] = "毌丘俭",
  ["#mob_sp__guanqiujian"] = "才识拔干",
  --["illustrator:mob_sp__guanqiujian"] = "",

  ["cuizhen"] = "摧阵",
  [":cuizhen"] = "游戏开始时，若为身份模式，则你可以选择至多两名其他角色，废除其武器栏；"..
  "当你于出牌阶段内使用【杀】或伤害类锦囊牌指定其他角色为目标后，若其手牌数不小于体力值，则你可以废除其武器栏；"..
  "摸牌阶段，你额外摸X张牌（X为场上被废除的武器栏数，且至多为2）。",
  ["kuili"] = "溃离",
  [":kuili"] = "锁定技，当你受到伤害后，你弃置X张手牌（X为伤害值）；若伤害来源的武器栏被废除，则恢复之。",
  ["#cuizhen-choose"] = "摧阵：你可以废除至多两名角色的武器栏！",
  ["#cuizhen-invoke"] = "摧阵：是否废除 %dest 的武器栏？",

  ["$cuizhen1"] = "欲活命者，还不弃兵卸甲！",
  ["$cuizhen2"] = "全军大进，誓讨司马乱贼！",
  ["$kuili1"] = "此犹有转胜之机，吾等切不可自乱。",
  ["$kuili2"] = "不患败战于人，但恐军心已溃啊。",
  ["~mob_sp__guanqiujian"] = "汝不讨篡权逆臣，何杀吾讨贼义军……",
}

local lizhaojiaobo = General(extension, "lizhaojiaobo", "wei", 4)
local function DoZuoyou(player, status)
  local room = player.room
  if status == "yang" then
    player:drawCards(2, "zuoyou")
    if not player.dead and not player:isKongcheng() then
      room:askForDiscard(player, 1, 1, false, "zuoyou", false)
    end
  else
    if player:getHandcardNum() > 1 then
      room:askForDiscard(player, 2, 2, false, "zuoyou", false)
      if not player.dead then
        room:changeShield(player, 1)
      end
    end
  end
end
local zuoyou = fk.CreateActiveSkill{
  name = "zuoyou",
  anim_type = "switch",
  switch_skill_name = "zuoyou",
  card_num = 0,
  target_num = 1,
  prompt = function(self)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return "#zuoyou-yang"
    else
      return "#zuoyou-yin"
    end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return #selected == 0
    else
      return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getHandcardNum() > 1
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local status = player:getSwitchSkillState(self.name, true) == fk.SwitchYang and "yang" or "yin"
    room:setPlayerMark(player, "zuoyou-phase", target.id)
    DoZuoyou(target, status)
  end,
}
local shishoul = fk.CreateTriggerSkill{
  name = "shishoul",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.name == "zuoyou" and player:getMark("zuoyou-phase") ~= player.id
  end,
  on_use = function(self, event, target, player, data)
    local status = player:getSwitchSkillState("zuoyou") == fk.SwitchYang and "yang" or "yin"
    DoZuoyou(player, status)
  end,
}
lizhaojiaobo:addSkill(zuoyou)
lizhaojiaobo:addSkill(shishoul)
Fk:loadTranslationTable{
  ["lizhaojiaobo"] = "李昭焦伯",
  ["#lizhaojiaobo"] = "竭诚尽节",
  --["illustrator:lizhaojiaobo"] = "",

  ["zuoyou"] = "佐佑",
  [":zuoyou"] = "转换技，出牌阶段限一次，阳：你可以令一名角色摸两张牌，然后其弃置一张手牌；阴：" ..
  "你可以令一名手牌数不少于2的角色弃置两张手牌，然后其获得1点护甲。",
  ["shishoul"] = "侍守",
  [":shishoul"] = "锁定技，当其他角色执行了“佐佑”的一项后，你执行“佐佑”的另一项。",
  ["#zuoyou-yang"] = "佐佑：你可以令一名角色摸两张牌，然后其弃置一张手牌",
  ["#zuoyou-yin"] = "佐佑：你可以令一名角色弃置两张手牌，然后其获得1点护甲",

  ["$zuoyou1"] = "陛下亲讨乱贼，臣等安不随护！",
  ["$zuoyou2"] = "纵有亡身之险，亦忠陛下一人！",
  ["$shishoul1"] = "此乃天子御驾，尔等谁敢近前！	",
  ["$shishoul2"] = "吾等侍卫在侧，必保陛下无虞！",
  ["~lizhaojiaobo"] = "陛下！！尔等乱臣，安敢弑君！呃啊……",
}

local chengjiw = General(extension, "chengjiw", "wei", 4)
local kuangli = fk.CreateTriggerSkill{
  name = "kuangli",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Play and #player.room.alive_players > 1
      elseif event == fk.TargetSpecified and player.phase == Player.Play then
        local to = player.room:getPlayerById(data.to)
        return not to.dead and to:getMark("@@kuangli-turn") > 0 and player:getMark("kuangli-phase") < 2
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local n = math.random(1, #room.alive_players - 1)
      local targets = table.random(room:getOtherPlayers(player), n)
      room:doIndicate(player.id, table.map(targets, Util.IdMapper))
      for _, p in ipairs(targets) do
        room:setPlayerMark(p, "@@kuangli-turn", 1)
      end
    else
      room:addPlayerMark(player, "kuangli-phase", 1)
      local to = room:getPlayerById(data.to)
      if not player:isNude() and not player.dead then
        local id = table.random(player:getCardIds("he"))
        room:throwCard(id, self.name, player, player)
      end
      if not to:isNude() and not to.dead then
        local id = table.random(to:getCardIds("he"))
        room:throwCard(id, self.name, to, to)
      end
      if not player.dead then
        player:drawCards(1, self.name)
      end
    end
  end,
}
local xiongsi = fk.CreateActiveSkill{
  name = "xiongsi",
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  prompt = function(self, card)
    return "#xiongsi-active"
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:getHandcardNum() > 2 and
      table.find(player:getCardIds("h"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:throwAllCards("h")
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead then
        room:loseHp(p, 1, self.name)
      end
    end
  end,
}
chengjiw:addSkill(kuangli)
chengjiw:addSkill(xiongsi)
Fk:loadTranslationTable{
  ["chengjiw"] = "成济",
  ["#chengjiw"] = "劣犬良弓",
  --["illustrator:chengjiw"] = "",

  ["kuangli"] = "狂戾",
  [":kuangli"] = "锁定技，出牌阶段开始时，场上随机任意名其他角色获得“狂戾”标记直到回合结束；每阶段限两次，" ..
  "当你于出牌阶段内使用牌指定一名拥有“狂戾”标记的角色为目标后，你与其各随机弃置一张牌，然后你摸一张牌。",
  ["xiongsi"] = "凶肆",
  [":xiongsi"] = "限定技，出牌阶段，若你的手牌不少于三张，你可以弃置所有手牌，然后令所有其他角色各失去1点体力。",
  ["@@kuangli-turn"] = "狂戾",
  ["#xiongsi-active"] = "凶肆：你可以弃置所有手牌，令所有其他角色各失去1点体力！",

  ["$kuangli1"] = "我已受命弑君，汝等还不散去！	",
  ["$kuangli2"] = "谁再聚众作乱，我就将其杀之！",
  ["$xiongsi1"] = "既想杀人灭口，那就同归于尽！	",
  ["$xiongsi2"] = "贾充！你不仁就别怪我不义！",
  ["~chengjiw"] = "汝等要卸磨杀驴吗？呃啊……",
}

return extension