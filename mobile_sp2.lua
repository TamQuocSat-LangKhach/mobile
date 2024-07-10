local extension = Package("mobile_sp2")
extension.extensionName = "mobile"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["mobile_sp2"] = "手杀-SP2",
  ["mob_sp"] = "手杀SP",
  ["mobile2"] = "手杀",
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
        -- return table.contains({"aaa_role_mode", "aab_role_mode", "vanished_dragon"}, room.settings.gameMode) and
        return table.find(room:getOtherPlayers(player), function(p)
          return #p:getAvailableEquipSlots(Card.SubtypeWeapon) > 0
        end)
      elseif event == fk.TargetSpecified and target == player and player.phase == Player.Play and data.card.is_damage_card then
        local to = player.room:getPlayerById(data.to)
        return not to.dead and to:getHandcardNum() >= to.hp and #to:getAvailableEquipSlots(Card.SubtypeWeapon) > 0
      elseif event == fk.DrawNCards and target == player then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return #p:getAvailableEquipSlots(Card.SubtypeWeapon) > 0
      end), Util.IdMapper)
      --local max = table.contains({"aaa_role_mode", "aab_role_mode", "vanished_dragon"}, room.settings.gameMode) and 3 or 2
      local tos = room:askForChoosePlayers(player, targets, 1, 3 , "#cuizhen-choose", self.name)
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
      local n = 1
      for _, p in ipairs(room.alive_players) do
        for _, slot in ipairs(p.sealedSlots) do
          if slot == Player.WeaponSlot then
            n = n + 1
          end
        end
      end
      data.n = data.n + math.min(n, 3)
    end
  end,
}
local kuili = fk.CreateTriggerSkill{
  name = "kuili",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      data.from and
      data.from:isAlive() and
      table.contains(data.from.sealedSlots, Player.WeaponSlot)
  end,
  on_use = function(self, event, target, player, data)
    player.room:resumePlayerArea(data.from, Player.WeaponSlot)
  end,
}
guanqiujian:addSkill(cuizhen)
guanqiujian:addSkill(kuili)
Fk:loadTranslationTable{
  ["mob_sp__guanqiujian"] = "毌丘俭",
  ["#mob_sp__guanqiujian"] = "才识拔干",
  --["illustrator:mob_sp__guanqiujian"] = "",

  ["cuizhen"] = "摧阵",
  [":cuizhen"] = "游戏开始时，你可以选择至多三名其他角色，废除其武器栏；"..
  "当你于出牌阶段内使用【杀】或伤害类锦囊牌指定其他角色为目标后，若其手牌数不小于体力值，则你可以废除其武器栏；"..
  "摸牌阶段，你额外摸X张牌（X为场上被废除的武器栏数+1，至多为3）。",
  ["kuili"] = "溃离",
  [":kuili"] = "锁定技，当你受到伤害后，你恢复伤害来源的武器栏。",
  ["#cuizhen-choose"] = "摧阵：你可以废除至多三名角色的武器栏！",
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
    player:drawCards(3, "zuoyou")
    if not player.dead and not player:isKongcheng() then
      room:askForDiscard(player, 2, 2, false, "zuoyou", false)
    end
  else
    if table.contains({"m_2v2_mode"}, room.settings.gameMode) then
      if not player.dead then
        room:changeShield(player, 1)
      end
    elseif player:getHandcardNum() > 0 then
      room:askForDiscard(player, 1, 1, false, "zuoyou", false)
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
      return
        #selected == 0 and
        (
          table.contains({"m_2v2_mode"}, Fk:currentRoom().room_settings.gameMode) or
          Fk:currentRoom():getPlayerById(to_select):getHandcardNum() > 0
        )
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
  [":zuoyou"] = "转换技，出牌阶段限一次，阳：你可以令一名角色摸三张牌，然后其弃置两张手牌；阴：" ..
  "你可以令一名手牌数不少于1的角色弃置一张手牌，然后其获得1点护甲（若为2v2模式，则改为令一名角色获得1点护甲）。",
  ["shishoul"] = "侍守",
  [":shishoul"] = "锁定技，当其他角色执行了“佐佑”的一项后，你执行“佐佑”的另一项。",
  ["#zuoyou-yang"] = "佐佑：你可以令一名角色摸三张牌，然后其弃置两张手牌",
  ["#zuoyou-yin"] = "佐佑：你可以令一名角色弃置一张手牌，然后其获得1点护甲",

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
        return
          player.phase == Player.Play and
          #player.room.alive_players > 1 and
          math.random(0, #player.room.alive_players - 1) > 0
      elseif event == fk.TargetSpecified and player.phase == Player.Play then
        local to = player.room:getPlayerById(data.to)
        return not to.dead and to:getMark("@@kuangli-turn") > 0 and player:getMark("kuangli-phase") < 1
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
        room:throwCard(id, self.name, to, player)
      end
      if not player.dead then
        player:drawCards(2, self.name)
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
  [":kuangli"] = "锁定技，出牌阶段开始时，场上随机任意名其他角色获得“狂戾”标记直到回合结束；每阶段限一次，" ..
  "当你于出牌阶段内使用牌指定一名拥有“狂戾”标记的角色为目标后，你随机弃置你与其各一张牌，然后你摸两张牌。",
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

local caomao = General(extension, "mobile__caomao", "wei", 3)
local caomao2 = General(extension, "mobile2__caomao", "wei", 3)
local caomaoWin = fk.CreateActiveSkill{ name = "mobile__caomao_win_audio" }
caomaoWin.package = extension
Fk:addSkill(caomaoWin)

caomao2.total_hidden = true

Fk:loadTranslationTable{
  ["mobile__caomao"] = "曹髦",
  ["#mobile__caomao"] = "未知",
  --["illustrator:chengjiw"] = "",
  ["$mobile__caomao_win_audio"] = "少康诛寒浞以中兴，朕夷司马未尝不可！",
  ["~mobile__caomao"] = "纵不成身死，朕亦为太祖子孙，大魏君王……",

  ["mobile2__caomao"] = "曹髦",
}

local qianlong = fk.CreateTriggerSkill{
  name = "mobile__qianlong",
  anim_type = "support",
  events = {fk.GameStart, fk.Damaged, fk.Damage, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:getMark("@mobile__qianlong_daoxin") > 98 then
      return false
    end

    if event == fk.AfterCardsMove then
      return table.find(data, function(move) return move.to == player.id and move.toArea == Card.PlayerHand end)
    elseif event == fk.Damaged or event == fk.Damage then
      return target == player
    end

    return event == fk.GameStart
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 0
    if event == fk.GameStart then
      num = 20
    elseif event == fk.Damage then
      num = 15 * data.damage
    elseif event == fk.Damaged then
      num = 10 * data.damage
    else
      num = 5
    end

    local daoxin = player:getMark("@mobile__qianlong_daoxin")
    num = math.min(99 - daoxin, num)
    if num > 0 then
      room:setPlayerMark(player, "@mobile__qianlong_daoxin", daoxin + num)
      if player:getMark("@mobile__qianlong_daoxin") >= 25 and not player:hasSkill("mobile_qianlong__qingzheng") then
        room:handleAddLoseSkills(player, "mobile_qianlong__qingzheng")
      end
      if player:getMark("@mobile__qianlong_daoxin") >= 50 and not player:hasSkill("mobile_qianlong__jiushi") then
        room:handleAddLoseSkills(player, "mobile_qianlong__jiushi")
      end
      if player:getMark("@mobile__qianlong_daoxin") >= 75 and not player:hasSkill("mobile_qianlong__fangzhu") then
        room:handleAddLoseSkills(player, "mobile_qianlong__fangzhu")
      end
      if player:getMark("@mobile__qianlong_daoxin") >= 99 and not player:hasSkill("juejin") then
        room:handleAddLoseSkills(player, "juejin")
      end
    end
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function (self, event, target, player, data)
    return target == player and data == self
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.EventAcquireSkill then
      if player:getMark("@mobile__qianlong_daoxin") >= 25 and not player:hasSkill("mobile_qianlong__qingzheng") then
        room:handleAddLoseSkills(player, "mobile_qianlong__qingzheng")
      end
      if player:getMark("@mobile__qianlong_daoxin") >= 50 and not player:hasSkill("mobile_qianlong__jiushi") then
        room:handleAddLoseSkills(player, "mobile_qianlong__jiushi")
      end
      if player:getMark("@mobile__qianlong_daoxin") >= 75 and not player:hasSkill("mobile_qianlong__fangzhu") then
        room:handleAddLoseSkills(player, "mobile_qianlong__fangzhu")
      end
      if player:getMark("@mobile__qianlong_daoxin") >= 99 and not player:hasSkill("juejin") then
        room:handleAddLoseSkills(player, "juejin")
      end
    else
      local toLose = {
        "-mobile_qianlong__qingzheng",
        "-mobile_qianlong__jiushi",
        "-mobile_qianlong__fangzhu",
        "-juejin",
      }
      room:handleAddLoseSkills(player, table.concat(toLose, "|"))
    end
  end,
}
Fk:loadTranslationTable{
  ["mobile__qianlong"] = "潜龙",
  [":mobile__qianlong"] = "持恒技，游戏开始时，你获得20点道心值；如下情况时，你获得对应数量的道心值：当你受到1点伤害后——" ..
  "10点；当你造成1点伤害后——15点；当你获得牌后——5点。<br>你根据道心值视为拥有以下技能：25点-〖清正〗；50点-〖酒诗〗；75点-〖放逐〗；" ..
  "99点-〖决进〗。你的道心值上限为99。",
  ["@mobile__qianlong_daoxin"] = "道心值",

  ["$mobile__qianlong1"] = "暗蓄忠君之士，以待破局之机！",
  ["$mobile__qianlong2"] = "若安司马于外，或则皇权可收！",
  ["$mobile__qianlong3"] = "朕为天子，岂忍威权日去！",
  ["$mobile__qianlong4"] = "假以时日，必讨司马一族！",
  ["$mobile__qianlong5"] = "权臣震主，竟视天子于无物！",
  ["$mobile__qianlong6"] = "朕行之决矣！正使死又何惧？",
}

qianlong.permanent_skill = true
caomao:addSkill(qianlong)

local QLqingzheng = fk.CreateTriggerSkill{
  name = "mobile_qianlong__qingzheng",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      player.phase == Player.Play and
      table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id).suit ~= Card.NoSuit end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
    if #targets > 0 then
      local to = room:askForChoosePlayers(
        player,
        table.map(targets, Util.IdMapper),
        1,
        1,
        "#mobile_qianlong__qingzheng-choose",
        self.name,
        true
      )
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:getPlayerById(self.cost_data)

    local suits = {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      local suit = Fk:getCardById(id):getSuitString(true)
      if suit ~= "log_nosuit" then
        table.insertIfNeed(suits, suit)
      end
    end
    local choices = room:askForChoices(player, suits, 1, 1, self.name, "#mobile_qianlong__qingzheng-discard", false)
    local cards = table.filter(player.player_cards[Player.Hand], function (id)
      return not player:prohibitDiscard(Fk:getCardById(id)) and table.contains(choices, Fk:getCardById(id):getSuitString(true))
    end)
    if #cards > 0 then
      room:throwCard(cards, self.name, player, player)
    end
    if player.dead then return end
    local cids = to.player_cards[Player.Hand]
    local cards1 = {}
    if #cids > 0 then
      local id1 = room:askForCardChosen(
        player,
        to,
        { card_data = { { "$Hand", cids }  } },
        self.name,
        "#mobile_qianlong__qingzheng-throw"
      )
      cards1 = table.filter(cids, function(id) return Fk:getCardById(id).suit == Fk:getCardById(id1).suit end)
      room:throwCard(cards1, self.name, to, player)
    end
    if #cards > #cards1 and not to.dead then
      room:damage{ from = player, to = to, damage = 1, skillName = self.name }
      if player:hasSkill("mou__jianxiong") and player:getMark("@mou__jianxiong") < 2 then
        if room:askForSkillInvoke(player, self.name, nil, "#mou__qingzheng-addmark") then
          room:addPlayerMark(player, "@mou__jianxiong", 1)
        end
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["mobile_qianlong__qingzheng"] = "清正",
  [":mobile_qianlong__qingzheng"] = "持恒技，出牌阶段开始时，你可以选择一名有手牌的其他角色，你弃置一种花色的所有手牌，" ..
  "然后观看其手牌并选择一种花色的牌，其弃置所有该花色的手牌。若如此做且你以此法弃置的牌数大于其弃置的手牌，你对其造成1点伤害。",
  ["#mobile_qianlong__qingzheng-choose"] = "清正：可以弃置一种花色的所有手牌，观看一名角色手牌并弃置其中一种花色",
  ["#mobile_qianlong__qingzheng-discard"] = "清正：请选择一种花色的所有手牌弃置",
  ["#mobile_qianlong__qingzheng-throw"] = "清正：弃置其一种花色的所有手牌",

  ["$mobile_qianlong__qingzheng1"] = "朕虽不德，昧于大道，思与宇内共臻兹路。",
  ["$mobile_qianlong__qingzheng2"] = "愿遵前人教诲，为一国明帝贤君。",
}

QLqingzheng.permanent_skill = true
caomao:addRelatedSkill(QLqingzheng)

local QLjiushi = fk.CreateViewAsSkill{
  name = "mobile_qianlong__jiushi",
  anim_type = "support",
  prompt = "#mobile_qianlong__jiushi-active",
  pattern = "analeptic",
  card_filter = Util.FalseFunc,
  before_use = function(self, player)
    player:turnOver()
  end,
  view_as = function(self, cards)
    local c = Fk:cloneCard("analeptic")
    c.skillName = self.name
    return c
  end,
  enabled_at_play = function (self, player)
    return player.faceup
  end,
  enabled_at_response = function (self, player)
    return player.faceup
  end,
}
local QLjiushiTrigger = fk.CreateTriggerSkill{
  name = "#mobile_qianlong__jiushi_trigger",
  anim_type = "support",
  events = {fk.Damaged, fk.TurnedOver},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(QLjiushi) then
      if event == fk.Damaged then
        return not player.faceup and not (data.extra_data or {}).QLjiushicheck
      end

      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    return event == fk.TurnedOver or player.room:askForSkillInvoke(player, QLjiushi.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      player:turnOver()
    else
      local cards = player.room:getCardsFromPileByRule(".|.|.|.|.|trick")
      if #cards > 0 then
        room:obtainCard(player, cards[1], true, fk.ReasonPrey)
      end
    end
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.faceup
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.QLjiushicheck = true
  end,
}
Fk:loadTranslationTable{
  ["mobile_qianlong__jiushi"] = "酒诗",
  ["#mobile_qianlong__jiushi_trigger"] = "酒诗",
  [":mobile_qianlong__jiushi"] = "持恒技，当你需要使用【酒】时，若你的武将牌正面向上，你可以翻面，视为使用一张【酒】；当你受到伤害后，" ..
  "若你的武将牌于受到此伤害时背面向上，你可以翻面；当你翻面后，你随机获得牌堆中的一张锦囊牌。",
  ["#mobile_qianlong__jiushi-active"] = "发动酒诗，翻面来视为使用一张【酒】",

  ["$mobile_qianlong__jiushi1"] = "心愤无所表，下笔即成篇。",
  ["$mobile_qianlong__jiushi2"] = "弃忧但求醉，醒后寻复来。",
}

QLjiushi.permanent_skill = true
QLjiushiTrigger.permanent_skill = true
QLjiushi:addRelatedSkill(QLjiushiTrigger)
caomao:addRelatedSkill(QLjiushi)

local QLfangzhu = fk.CreateActiveSkill{
  name = "mobile_qianlong__fangzhu",
  anim_type = "control",
  prompt = "#mobile_qianlong__fangzhu",
  card_num = 0,
  target_num = 1,
  interaction = function(self)
    local choiceList = {
      "mobile_qianlong_only_trick",
      "mobile_qianlong_nullify_skill",
    }

    return UI.ComboBox { choices = choiceList }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Self:getMark("mobile_qianlong__fangzhu_target") ~= to_select
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, "mobile_qianlong__fangzhu_target", target.id)

    local choice = self.interaction.data
    if choice == "mobile_qianlong_only_trick" then
      room:setPlayerMark(target, "@mobile_qianlong__fangzhu_limit", "trick_char")
    elseif choice == "mobile_qianlong_nullify_skill" then
      room:setPlayerMark(target, "@@mobile_qianlong__fangzhu_skill_nullified", 1)
    end
  end,
}
local QLfangzhuRefresh = fk.CreateTriggerSkill{
  name = "#mobile_qianlong__fangzhu_refresh",
  refresh_events = { fk.AfterTurnEnd },
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      table.find(
        { "@mobile_qianlong__fangzhu_limit", "@@mobile_qianlong__fangzhu_skill_nullified" },
        function(markName) return player:getMark(markName) ~= 0 end
      )
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
  
    for _, markName in ipairs({ "@mobile_qianlong__fangzhu_limit", "@@mobile_qianlong__fangzhu_skill_nullified" }) do
      if player:getMark(markName) ~= 0 then
        room:setPlayerMark(player, markName, 0)
      end
    end
  end,
}
local QLfangzhuProhibit = fk.CreateProhibitSkill{
  name = "#mobile_qianlong__fangzhu_prohibit",
  prohibit_use = function(self, player, card)
    local typeLimited = player:getMark("@mobile_qianlong__fangzhu_limit")
    if type(typeLimited) == "string" and typeLimited ~= card:getTypeString() .. "_char" then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
}
local QLfangzhuNullify = fk.CreateInvaliditySkill {
  name = "#mobile_qianlong__fangzhu_nullify",
  invalidity_func = function(self, from, skill)
    return from:getMark("@@mobile_qianlong__fangzhu_skill_nullified") > 0 and skill:isPlayerSkill(from)
  end
}
Fk:loadTranslationTable{
  ["mobile_qianlong__fangzhu"] = "放逐",
  [":mobile_qianlong__fangzhu"] = "持恒技，出牌阶段限一次，你可以选择一项令一名其他角色执行（不可选择上次以此法选择的角色）：" ..
  "1.直到其下个回合开始，其只能使用锦囊牌；2.直到其下个回合开始，其所有技能失效。",
  ["#mobile_qianlong__fangzhu"] = "放逐：你可选择一名角色，对其进行限制",
  ["#mobile_qianlong__fangzhu_prohibit"] = "放逐",
  ["@mobile_qianlong__fangzhu_limit"] = "放逐限",
  ["@@mobile_qianlong__fangzhu_skill_nullified"] = "放逐 技能失效",
  ["mobile_qianlong_only_trick"] = "只可使用锦囊牌",
  ["mobile_qianlong_nullify_skill"] = "武将技能失效",

  ["$mobile_qianlong__fangzhu1"] = "卿当竭命纳忠，何为此逾矩之举！",
  ["$mobile_qianlong__fangzhu2"] = "朕继文帝风流，亦当效其权略！",
}

QLfangzhu.permanent_skill = true
QLfangzhuRefresh.permanent_skill = true
QLfangzhuProhibit.permanent_skill = true
QLfangzhuNullify.permanent_skill = true
QLfangzhu:addRelatedSkill(QLfangzhuRefresh)
QLfangzhu:addRelatedSkill(QLfangzhuProhibit)
QLfangzhu:addRelatedSkill(QLfangzhuNullify)
caomao:addRelatedSkill(QLfangzhu)

local juejin = fk.CreateActiveSkill{
  name = "juejin",
  anim_type = "control",
  prompt = "#juejin-active",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)

    if player.general == "mobile__caomao" then
      player.general = "mobile2__caomao"
      room:broadcastProperty(player, "general")
    elseif player.deputyGeneral == "mobile__caomao" then
      player.deputyGeneral = "mobile2__caomao"
      room:broadcastProperty(player, "deputyGeneral")
    end

    for _, p in ipairs(room:getAlivePlayers()) do
      if p:isAlive() then
        local diff = 1 - p.hp
        if diff ~= 0 then
          room:changeHp(p, diff, nil, self.name)
        end
        if p == player then
          diff = math.min(diff, 0) - 2
        end

        if diff < 0 then
          room:changeShield(p, -diff)
        end
      end
    end

    local toVoid = {}
    for _, id in ipairs(room.draw_pile) do
      if table.contains({ "analeptic", "peach", "jink" }, Fk:getCardById(id).name) then
        table.insert(toVoid, id)
      end
    end
    for _, id in ipairs(room.discard_pile) do
      if table.contains({ "analeptic", "peach", "jink" }, Fk:getCardById(id).name) then
        table.insert(toVoid, id)
      end
    end

    for _, p in ipairs(room.alive_players) do
      for _, id in ipairs(p:getCardIds("hej")) do
        if table.contains({ "analeptic", "peach", "jink" }, Fk:getCardById(id).name) then
          table.insert(toVoid, id)
        end
      end
    end

    if #toVoid > 0 then
      room:moveCardTo(toVoid, Card.Void, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
  end,
}
Fk:loadTranslationTable{
  ["juejin"] = "决进",
  [":juejin"] = "持恒技，限定技，出牌阶段，你可以令所有角色将体力调整为1并获得X点护甲（X为其以此法减少的体力值，" ..
  "若该角色为你，则+2），然后将牌堆、弃牌堆和所有角色区域内的【酒】、【桃】、【闪】移出游戏。",
  ["#juejin-active"] = "决进：你可令所有角色将体力调整为1并转化为护甲，然后移除【酒】、【桃】和【闪】",

  ["$juejin1"] = "朕宁拼一死，逆贼安敢一战！",
  ["$juejin2"] = "朕安可坐受废辱，今日当与卿自出讨之！",
}

juejin.permanent_skill = true
caomao:addRelatedSkill(juejin)

local weitong = fk.CreateTriggerSkill{
  name = "weitong$",
  anim_type = "support",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(self) and
      player:hasSkill("mobile__qianlong") and
      table.find(player.room.alive_players, function(p) return p ~= player and p.kingdom == "wei" end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = #table.filter(room.alive_players, function(p) return p ~= player and p.kingdom == "wei" end) * 20

    local daoxin = player:getMark("@mobile__qianlong_daoxin")
    num = math.min(99 - daoxin, num)
    if num > 0 then
      room:setPlayerMark(player, "@mobile__qianlong_daoxin", daoxin + num)
      if player:getMark("@mobile__qianlong_daoxin") >= 25 and not player:hasSkill("mobile_qianlong__qingzheng") then
        room:handleAddLoseSkills(player, "mobile_qianlong__qingzheng")
      end
      if player:getMark("@mobile__qianlong_daoxin") >= 50 and not player:hasSkill("mobile_qianlong__jiushi") then
        room:handleAddLoseSkills(player, "mobile_qianlong__jiushi")
      end
      if player:getMark("@mobile__qianlong_daoxin") >= 75 and not player:hasSkill("mobile_qianlong__fangzhu") then
        room:handleAddLoseSkills(player, "mobile_qianlong__fangzhu")
      end
      if player:getMark("@mobile__qianlong_daoxin") >= 99 and not player:hasSkill("juejin") then
        room:handleAddLoseSkills(player, "juejin")
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["weitong"] = "卫统",
  [":weitong"] = "持恒技，主公技，游戏开始时，若你拥有技能〖潜龙〗，则你获得X点道心值（X为其他魏势力角色数×20）。",

  ["$weitong1"] = "手无实权难卫统，朦胧成睡，睡去还惊。",
}

weitong.permanent_skill = true
caomao:addSkill(weitong)

local zhangbu = General(extension, "zhangbu", "wu", 4)
zhangbu.total_hidden = true
local chengxiong = fk.CreateTriggerSkill{
  name = "chengxiong",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.firstTarget and data.card.type == Card.TypeTrick and
      table.find(AimGroup:getAllTargets(data.tos), function(id) return id ~= player.id end) then
      local room = player.room
      local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        return use and use.from == player.id
      end, Player.HistoryPhase)
      return table.find(room.alive_players, function(p)
        return #p:getCardIds("he") >= n
      end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      return use and use.from == player.id
    end, Player.HistoryPhase)
    local targets = table.map(table.filter(room.alive_players, function(p)
      return #p:getCardIds("he") >= n
    end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#chengxiong-choose:::"..data.card:getColorString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(player, to, "he", self.name)
    local color = Fk:getCardById(card).color
    room:throwCard(card, self.name, to, player)
    if color == data.card.color and color ~= Card.NoColor and not to.dead then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local wangzhuan = fk.CreateTriggerSkill{
  name = "wangzhuan",
  anim_type = "drawcard",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not data.card and
      (data.from and data.from == player or target == player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wangzhuan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, self.name)
    if room.current and not room.current.dead then
      room:doIndicate(player.id, {room.current.id})
      room:addPlayerMark(room.current, "@@wangzhuan-turn")
      room:addPlayerMark(room.current, MarkEnum.UncompulsoryInvalidity .. "-turn")
    end
  end,
}
zhangbu:addSkill(chengxiong)
zhangbu:addSkill(wangzhuan)
Fk:loadTranslationTable{
  ["zhangbu"] = "张布",
  ["#zhangbu"] = "主胜辅义",
  --["illustrator:zhangbu"] = "",

  ["chengxiong"] = "惩凶",
  [":chengxiong"] = "你使用锦囊牌指定其他角色为目标后，你可以选择一名牌数不小于X的角色（X为你此阶段使用的牌数），弃置其一张牌，"..
  "若此牌颜色与你使用的锦囊牌颜色相同，你对其造成1点伤害。",
  ["wangzhuan"] = "妄专",
  [":wangzhuan"] = "当一名角色受到非游戏牌造成的伤害后，若你是伤害来源或受伤角色，你可以摸两张牌，然后当前回合角色非锁定技失效直到回合结束。",
  ["#chengxiong-choose"] = "惩凶：弃置一名角色一张牌，若为%arg，对其造成1点伤害",
  ["#wangzhuan-invoke"] = "妄专：你可以摸两张牌，令当前回合角色本回合非锁定技无效",
  ["@@wangzhuan-turn"] = "妄专",
}

local wangjing = General(extension, "wangjing", "wei", 3)
wangjing.total_hidden = true
local zujin = fk.CreateViewAsSkill{
  name = "zujin",
  pattern = "slash,jink,nullification",
  prompt = function (self)
    if Fk.currentResponsePattern == nil or Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("slash")) then
      return "#zujin-slash"
    else
      return "#zujin-jink"
    end
  end,
  interaction = function()
    local all_names = {"slash", "jink", "nullification"}
    local names = U.getViewAsCardNames(Self, "zujin", all_names, {}, U.getMark(Self, "zujin-turn"))
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function (self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local mark = U.getMark(player, "zujin-turn")
    table.insert(mark, Fk:cloneCard(self.interaction.data).trueName)
    player.room:setPlayerMark(player, "zujin-turn", mark)
  end,
  enabled_at_play = function(self, player)
    return not table.contains(U.getMark(player, "zujin-turn"), "slash") and
      (not player:isWounded() or table.find(Fk:currentRoom().alive_players, function(p)
        return p ~= player and p.hp <= player.hp
      end))
  end,
  enabled_at_response = function(self, player, response)
    if Fk.currentResponsePattern ~= nil then
      for _, name in ipairs({"slash", "jink", "nullification"}) do
        local card = Fk:cloneCard(name)
        card.skillName = self.name
        if not table.contains(U.getMark(player, "zujin-turn"), name) and Exppattern:Parse(Fk.currentResponsePattern):match(card) then
          if name == "slash" then
            return not player:isWounded() or table.find(Fk:currentRoom().alive_players, function(p)
              return p.hp < player.hp
            end)
          elseif player:isWounded() then
            if name == "jink" then
              return true
            else
              return not response
            end
          end
        end
      end
    end
  end,
}
local jiejianw = fk.CreateTriggerSkill{
  name = "jiejianw",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self) and player.phase == Player.Start and not player:isKongcheng() and #player.room.alive_players > 1
    elseif event == fk.TargetConfirming then
      return player:hasSkill(self) and target:getMark("@jiejianw") ~= 0 and
        #AimGroup:getAllTargets(data.tos) == 1 and
        data.from ~= player.id and  --应该是
        data.card.type ~= Card.TypeEquip and  --测试确实不能偷装备
        not player.room:getPlayerById(data.from):isProhibited(player, data.card)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local cards = player:getCardIds("h")
      local result = U.askForDistribution(player, cards, player.room:getOtherPlayers(player), self.name, 0, #cards,
        "#jiejianw-give", nil, true)
      if result then
        self.cost_data = result
        return true
      end
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#jiejianw-invoke::"..target.id..":"..data.card:toLogString())
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      for id, cards in pairs(self.cost_data) do
        if #cards > 0 then
          local p = room:getPlayerById(tonumber(id))
          room:setPlayerMark(p, "@jiejianw", tostring(math.max(p.hp, 0)))
        end
      end
      U.doDistribution(room, self.cost_data, player.id, self.name)
    else
      room:doIndicate(data.from, {player.id})
      AimGroup:cancelTarget(data, target.id)
      AimGroup:addTargets(room, data, player.id)
      player:drawCards(1, self.name)
    end
  end
}
local jiejianw_delay = fk.CreateTriggerSkill{
  name = "#jiejianw_delay",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@jiejianw") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.hp >= tonumber(player:getMark("@jiejianw")) then
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:hasSkill("jiejianw") then
          p:broadcastSkillInvoke("jiejianw")
          room:notifySkillInvoked(p, "jiejianw", "drawcard")
          p:drawCards(2, "jiejianw")
        end
      end
    end
    room:setPlayerMark(player, "@jiejianw", 0)
  end,
}
jiejianw:addRelatedSkill(jiejianw_delay)
wangjing:addSkill(zujin)
wangjing:addSkill(jiejianw)
Fk:loadTranslationTable{
  ["wangjing"] = "王经",
  ["#wangjing"] = "青云孤竹",
  --["illustrator:wangjing"] = "",

  ["zujin"] = "阻进",
  [":zujin"] = "每回合每种牌名限一次。若你未受伤或体力值不为最低，你可以将一张基本牌当【杀】使用或打出；"..
  "若你已受伤，你可以将一张基本牌当【闪】或【无懈可击】使用或打出。",
  ["jiejianw"] = "节谏",
  [":jiejianw"] = "准备阶段，你可将任意张手牌交给任意名其他角色，这些角色获得“节谏”标记。当“节谏”角色成为其他角色使用非装备牌的唯一目标时，"..
  "你可将此牌转移给你，然后摸一张牌。“节谏”角色的回合结束时，移除其“节谏”标记，若其体力值不小于X（X为你交给其牌时其体力值），你摸两张牌。",
  ["#zujin-slash"] = "阻进：你可以将一张基本牌当【杀】使用或打出",
  ["#zujin-jink"] = "阻进：你可以将一张基本牌当【闪】或【无懈可击】使用或打出",
  ["#jiejianw-give"] = "节谏：将手牌任意分配给其他角色，这些角色获得“节谏”标记",
  ["@jiejianw"] = "节谏",
  ["#jiejianw-invoke"] = "节谏：是否将对 %dest 使用的%arg转移给你并摸一张牌？",
}

return extension
