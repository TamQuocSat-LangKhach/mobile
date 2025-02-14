local extension = Package("wisdom")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["wisdom"] = "手杀-始计篇·智",
}

local U = require "packages/utility/utility"

local wangcan = General(extension, "mobile__wangcan", "wei", 3)
local wisdom__qiai = fk.CreateActiveSkill{
  name = "wisdom__qiai",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    room:moveCardTo(Fk:getCardById(effect.cards[1]), Player.Hand, to, fk.ReasonGive, self.name, nil, true, from.id)
    if to.dead or from.dead then return end
    local choices = {"draw2"}
    if from:isWounded() then
      table.insert(choices, 1, "recover")
    end

    local choice = room:askForChoice(to, choices, self.name, "#wisdom__qiai-choose::" .. from.id)
    if choice == "draw2" then
      from:drawCards(2, self.name)
    else
      room:recover({
        who = from,
        num = 1,
        recoverBy = to,
        skillName = self.name,
      })
    end
  end,
}
local wisdom__shanxi = fk.CreateTriggerSkill{
  name = "wisdom__shanxi",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Play and
          table.find(player.room:getOtherPlayers(player, false), function(p) return p:getMark("@@wisdom__xi") == 0 end)
      else
        return target:getMark("@@wisdom__xi") > 0 and not target.dying and target:isAlive()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local targets = table.map(table.filter(player.room:getOtherPlayers(player, false), function(p)
        return p:getMark("@@wisdom__xi") == 0 end), Util.IdMapper)
      local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#wisdom__shanxi-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local source = table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getMark("@@wisdom__xi") > 0
      end)
      if source then
        room:setPlayerMark(source, "@@wisdom__xi", 0)
      end
      room:setPlayerMark(room:getPlayerById(self.cost_data), "@@wisdom__xi", 1)
    else
      local cardIds = room:askForCard(target, 2, 2, true, self.name, true, nil, "#wisdom__shanxi-give::" .. player.id)
      if #cardIds == 2 then
        room:moveCardTo(cardIds, Player.Hand, player, fk.ReasonGive, self.name, nil, false, target.id)
      else
        room:loseHp(target, 1, self.name)
      end
    end
  end,
}
wangcan:addSkill(wisdom__qiai)
wangcan:addSkill(wisdom__shanxi)
Fk:loadTranslationTable{
  ["mobile__wangcan"] = "王粲",
  ["#mobile__wangcan"] = "词章纵横",
  ["illustrator:mobile__wangcan"] = "鬼画府", -- 皮肤 笔翰如流
  ["wisdom__qiai"] = "七哀",
  [":wisdom__qiai"] = "出牌阶段限一次，你可以将一张非基本牌交给一名其他角色，然后其须选择一项：1.令你回复1点体力；2.令你摸两张牌。",
  ["wisdom__shanxi"] = "善檄",
  [":wisdom__shanxi"] = "出牌阶段开始时，你可以令一名没有“檄”的角色获得一枚“檄”标记（若场上有该标记则改为转移至该角色）；当有“檄”标记的角色回复体力后，"..
  "若其不处于濒死状态，其须选择一项：1.交给你两张牌；2.失去1点体力。",
  ["#wisdom__qiai-choose"] = "七哀：请选择一项令 %dest 执行",
  ["#wisdom__shanxi-choose"] = "善檄：请选择一名其他角色获得“檄”标记（场上已有则转移标记至该角色）",
  ["@@wisdom__xi"] = "檄",
  ["#wisdom__shanxi-give"] = "善檄：请交给%dest两张牌，否则失去1点体力",

  ["$wisdom__qiai1"] = "亲戚对我悲，朋友相追攀。",
  ["$wisdom__qiai2"] = "出门无所见，白骨蔽平原。",
  ["$wisdom__shanxi1"] = "西京乱无象，豺虎方遘患。",
  ["$wisdom__shanxi2"] = "复弃中国去，委身适荆蛮。",
  ["~mobile__wangcan"] = "悟彼下泉人，喟然伤心肝……",
}

local mobile__bianfuren = General(extension, "mobile__bianfuren", "wei", 3, 3, General.Female)
local mobile__wanwei = fk.CreateActiveSkill{
  name = "mobile__wanwei",
  anim_type = "support",
  prompt = "#mobile__wanwei-promot",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local x = player.hp
    room:recover({ who = target, num = x+1, recoverBy = player, skillName = self.name })
    room:loseHp(player, x, self.name)
  end
}
local mobile__wanwei_trigger = fk.CreateTriggerSkill{
  name = "#mobile__wanwei_trigger",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local n = math.max(1-target.hp,player.hp+1)
    return player.room:askForSkillInvoke(player, self.name, nil, "#mobile__wanwei-invoke::"..target.id..":"..n..":"..player.hp)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.max(1-target.hp,player.hp+1)
    room:recover({ who = target, num = n, recoverBy = player, skillName = self.name })
    room:loseHp(player, player.hp, self.name)
  end,
}
mobile__wanwei:addRelatedSkill(mobile__wanwei_trigger)
mobile__bianfuren:addSkill(mobile__wanwei)
local mobile__yuejian = fk.CreateTriggerSkill{
  name = "mobile__yuejian",
  anim_type = "defensive",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and #player:getCardIds("he") > 1
  end,
  on_cost = function (self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 2, 2, true,self.name,true,".","#mobile__yuejian-invoke",true)
    if #cards == 2 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, self.name, player, player)
    player.room:recover({ who = target, num = 1, recoverBy = player, skillName = self.name })
  end,
}
local mobile__yuejian_maxcards = fk.CreateMaxCardsSkill{
  name = "#mobile__yuejian_maxcards",
  fixed_func = function(self, player)
    if player:hasSkill(self) then
      return player.maxHp
    end
  end
}
mobile__yuejian:addRelatedSkill(mobile__yuejian_maxcards)
mobile__bianfuren:addSkill(mobile__yuejian)
Fk:loadTranslationTable{
  ["mobile__bianfuren"] = "卞夫人",
  ["#mobile__bianfuren"] = "内助贤后",
  ["illustrator:mobile__bianfuren"] = "芝芝不加糖", -- 皮肤 慈母情深
  ["mobile__wanwei"] = "挽危",
  [":mobile__wanwei"] = "每轮限一次，当一名其他角色进入濒死状态时，或出牌阶段内你可以选择一名其他角色，你可以令其回复X+1点体力（若不足使其脱离濒死，"..
  "改为回复至1点体力），然后你失去X点体力（X为你的体力值）。",
  ["#mobile__wanwei-invoke"] = "挽危：你可以令%dest回复%arg点体力，然后你失去%arg2点体力",
  ["#mobile__wanwei_trigger"] = "挽危",
  ["#mobile__wanwei-promot"] = "挽危：令一名其他角色回复X+1点体力，然后你失去X点体力（X为你的体力值）",
  ["mobile__yuejian"] = "约俭",
  [":mobile__yuejian"] = "①你的手牌上限等于体力上限；②当你进入濒死状态时，你可以弃置两张牌，回复1点体力。",
  ["#mobile__yuejian-invoke"] = "约俭：你可以弃两张牌，回复1点体力",

  ["$mobile__wanwei1"] = "事已至此，当思后策。",
  ["$mobile__wanwei2"] = "休养生息，无碍徐图天下。",
  ["$mobile__yuejian1"] = "后宫节用，可树德于外。",
  ["$mobile__yuejian2"] = "减损之益，不亚多得。",
  ["~mobile__bianfuren"] = "孟德大人，妾身可以再伴你身边了……",
}

local feiyi = General(extension, "mobile__feiyi", "shu", 3)
local jianyu = fk.CreateActiveSkill{
  name = "jianyu",
  anim_type = "control",
  card_num = 0,
  target_num = 2,
  prompt = "#jianyu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < 2
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "jianyu_targets", effect.tos)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "@@jianyu", 1)
    target = room:getPlayerById(effect.tos[2])
    room:setPlayerMark(target, "@@jianyu", 1)
  end,
}
local jianyu_trigger = fk.CreateTriggerSkill{
  name = "#jianyu_trigger",
  mute = true,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("jianyu_targets") ~= 0 and data.from ~= data.to and
      table.contains(player:getMark("jianyu_targets"), target.id) and
      table.contains(player:getMark("jianyu_targets"), data.to) and not player.room:getPlayerById(data.to).dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, player, target, data)
    local room = player.room
    player:broadcastSkillInvoke("jianyu")
    room:notifySkillInvoked(player, "jianyu", "support")
    room:doIndicate(player.id, {data.to})
    room:getPlayerById(data.to):drawCards(1, "jianyu")
  end,

  refresh_events = {fk.TurnStart, fk.Deathed},
  can_refresh = function(self, event, player, target, data)
    return player:getMark("jianyu_targets") ~= 0 and target == player
  end,
  on_refresh = function(self, event, player, target, data)
    local room = player.room
    local targets = player:getMark("jianyu_targets")
    room:setPlayerMark(player, "jianyu_targets", 0)
    for _, id in ipairs(targets) do
      local p = room:getPlayerById(id)
      if not table.find(room.alive_players, function(src)
        return src:getMark("jianyu_targets") ~= 0 and table.contains(src:getMark("jianyu_targets"), id) end) then
        room:setPlayerMark(p, "@@jianyu", 0)
        end
    end
  end,
}
jianyu:addRelatedSkill(jianyu_trigger)
feiyi:addSkill(jianyu)
feiyi:addSkill("os__shengxi")
Fk:loadTranslationTable{
  ["mobile__feiyi"] = "费祎",
  ["#mobile__feiyi"] = "蜀汉名相",
  ["illustrator:mobile__feiyi"] = "游漫美绘", -- 皮肤 居中调解
  ["jianyu"] = "谏喻",
  [":jianyu"] = "每轮限一次，出牌阶段，你可以选择两名角色，直到你下回合开始，当这些角色于其出牌阶段使用牌指定对方为目标后，你令目标摸一张牌。",
  ["#jianyu"] = "谏喻：指定两名角色，直到你下回合开始，这些角色互相使用牌时，目标摸一张牌",
  ["@@jianyu"] = "谏喻",

  ["$jianyu1"] = "斟酌损益，进尽忠言，此臣等之任也。",
  ["$jianyu2"] = "两相匡护，以各安其分，兼尽其用。",
  ["$os__shengxi_mobile__feiyi1"] = "承葛公遗托，富国安民。",
  ["$os__shengxi_mobile__feiyi2"] = "保国治民，敬守社稷。",
  ["~mobile__feiyi"] = "吾何惜一死，惜不见大汉中兴矣。",
}

local chenzhen = General(extension, "chenzhen", "shu", 3)
local shameng = fk.CreateActiveSkill{
  name = "shameng",
  anim_type = "drawcard",
  card_num = 2,
  target_num = 1,
  prompt = "#shameng",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getHandcardNum() > 1
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) ~= Player.Hand or Self:prohibitDiscard(Fk:getCardById(to_select)) then
      return false
    end
    return #selected == 0 or Fk:getCardById(selected[1]):compareColorWith(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    if not target.dead then
      target:drawCards(2, self.name)
    end
    if not player.dead then
      player:drawCards(3, self.name)
    end
  end,
}
chenzhen:addSkill(shameng)
Fk:loadTranslationTable{
  ["chenzhen"] = "陈震",
  ["#chenzhen"] = "歃盟使节",
  ["illustrator:chenzhen"] = "成都劲心", -- 皮肤 千里之任
  ["shameng"] = "歃盟",
  [":shameng"] = "出牌阶段限一次，你可以弃置两张颜色相同的手牌并选择一名其他角色，该角色摸两张牌，然后你摸三张牌。",
  ["#shameng"] = "歃盟：弃置两张颜色相同的手牌，令一名其他角色摸两张牌，你摸三张牌",

  ["$shameng1"] = "震以不才，得充下使，愿促两国盟好。",
  ["$shameng2"] = "震奉聘叙好，若有违贵国典制，万望告之。",
  ["~chenzhen"] = "若毁盟约，则两败俱伤！",
}

local luotong = General:new(extension, "luotong", "wu", 4)
local qinzheng = fk.CreateTriggerSkill{
  name = "qinzheng",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      not table.every({ 3, 5, 8 }, function(num)
        return player:getMark("@" .. self.name) % num ~= 0
      end)
  end,
  on_use = function(self, event, player, target, data)
    local loopList = table.filter({ 3, 5, 8 }, function(num)
      return player:getMark("@" .. self.name) % num == 0
    end)

    local toObtain = {}
    for _, count in ipairs(loopList) do
      local cardList = "slash,jink"
      if count == 5 then
        cardList = "peach,analeptic"
      elseif count == 8 then
        cardList = "ex_nihilo,duel"
      end
      local randomCard = player.room:getCardsFromPileByRule(cardList)
      if #randomCard > 0 then
        table.insert(toObtain, randomCard[1])
      end
    end

    if #toObtain > 0 then
      player.room:moveCards({
        ids = toObtain,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,

  refresh_events = {fk.CardUsing, fk.CardResponding, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventLoseSkill then
      return target == player and data == self
    end
    return player:hasSkill(self) and target == player
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventLoseSkill then
      player.room:setPlayerMark(player, "@" .. self.name, 0)
    else
      player.room:addPlayerMark(player, "@" .. self.name, 1)
    end
  end,
}
luotong:addSkill(qinzheng)
Fk:loadTranslationTable{
  ["luotong"] = "骆统",
  ["#luotong"] = "力政人臣",
  ["illustrator:luotong"] = "鬼画府",
  ["qinzheng"] = "勤政",
  [":qinzheng"] = "锁定技，你每使用或打出：三张牌时，你随机获得一张【杀】或【闪】；五张牌时，你随机获得一张【桃】或【酒】；"..
  "八张牌时，你随机获得一张【无中生有】或【决斗】。",
  ["@qinzheng"] = "勤政",

  ["$qinzheng1"] = "夫国之有民，犹水之有舟，停则以安，扰则以危。",
  ["$qinzheng2"] = "治疾及其未笃，除患贵其莫深。",
  ["~luotong"] = "臣统之大愿，足以死而不朽矣。",
}

local sunshao = General:new(extension, "mobile__sunshao", "wu", 3)
local dingyi = fk.CreateTriggerSkill{
  name = "dingyi",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choice = room:askForChoice(player, {"dingyi1", "dingyi2", "dingyi3", "dingyi4"}, self.name, "#dingyi-choice")
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@dingyi", choice)
    end
  end,
}
local dingyi_trigger = fk.CreateTriggerSkill{
  name = "#dingyi_trigger",
  mute = true,
  events = {fk.DrawNCards, fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.DrawNCards then
        return player:getMark("@dingyi") == "dingyi1"
      elseif event == fk.AfterDying then
        return player:getMark("@dingyi") == "dingyi4"
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n + (2 ^ player:getMark("fubi"))
    elseif event == fk.AfterDying then
      player.room:recover({
        who = player,
        num = math.min(player:getLostHp(), (2 ^ player:getMark("fubi"))),
        recoverBy = player,
        skillName = "dingyi",
      })
    end
  end,
}
local dingyi_maxcards = fk.CreateMaxCardsSkill{
  name = "#dingyi_maxcards",
  correct_func = function(self, player)
    if player:getMark("@dingyi") == "dingyi2" then
      return 2 * (2 ^ player:getMark("fubi"))
    end
  end,
}
local dingyi_attackrange = fk.CreateAttackRangeSkill{
  name = "#dingyi_attackrange",
  correct_func = function(self, from, to)
    if from:getMark("@dingyi") == "dingyi3" then
      return (2 ^ from:getMark("fubi"))
    end
    return 0
  end,
}
local zuici = fk.CreateTriggerSkill{
  name = "zuici",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead and data.from:getMark("@dingyi") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askForChoice(player, {"Cancel", "dismantlement", "ex_nihilo", "nullification"}, self.name,
      "#zuici-invoke::"..data.from.id)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.from.id})
    room:setPlayerMark(data.from, "@dingyi", 0)
    local cards = room:getCardsFromPileByRule(self.cost_data)
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = data.from.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
local fubi = fk.CreateActiveSkill{
  name = "fubi",
  anim_type = "support",
  min_card_num = 0,
  max_card_num = 1,
  target_num = 1,
  prompt = "#fubi",
  can_use = function (self, player, card)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getMark("@dingyi") ~= 0
  end,
  on_use = function (self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if #effect.cards == 0 then
      local all_choices = {"dingyi1", "dingyi2", "dingyi3", "dingyi4"}
      local choices = table.simpleClone(all_choices)
      table.removeOne(choices, target:getMark("@dingyi"))
      local choice = room:askForChoice(player, choices, self.name, "#fubi-choice::"..target.id, nil, all_choices)
      room:setPlayerMark(target, "@dingyi", choice)
    else
      room:throwCard(effect.cards, self.name, player, player)
      room:addPlayerMark(target, self.name, 1)
      room:setPlayerMark(player, "fubi_using", target.id)
    end
  end,
}
local fubi_trigger = fk.CreateTriggerSkill{
  name = "#fubi_trigger",

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("fubi_using") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local p = room:getPlayerById(player:getMark("fubi_using"))
    room:setPlayerMark(player, "fubi_using", 0)
    if not p.dead then
      room:removePlayerMark(p, "fubi", 1)
    end
  end,
}
dingyi:addRelatedSkill(dingyi_trigger)
dingyi:addRelatedSkill(dingyi_maxcards)
dingyi:addRelatedSkill(dingyi_attackrange)
fubi:addRelatedSkill(fubi_trigger)
sunshao:addSkill(dingyi)
sunshao:addSkill(zuici)
sunshao:addSkill(fubi)
Fk:loadTranslationTable{
  ["mobile__sunshao"] = "孙邵",
  ["#mobile__sunshao"] = "创基抉政",
  ["designer:mobile__sunshao"] = "Loun老萌",
  ["illustrator:mobile__sunshao"] = "君桓文化",
  ["dingyi"] = "定仪",
  [":dingyi"] = "锁定技，游戏开始时，你选择一项对全场角色生效：1.摸牌阶段摸牌数+1；2.手牌上限+2；3.攻击范围+1；4.脱离濒死状态时回复1点体力。",
  ["zuici"] = "罪辞",
  [":zuici"] = "当你受到有〖定仪〗效果的角色造成的伤害后，你可以令其失去〖定仪〗效果，然后其从牌堆中获得你选择的一张智囊牌。",
  ["fubi"] = "辅弼",
  [":fubi"] = "出牌阶段限一次，你可以选择一名有〖定仪〗效果的角色并选择一项：1.更换其〖定仪〗效果；2.弃置一张牌，直到你下回合开始，其〖定仪〗效果加倍。",
  ["#dingyi-choice"] = "定仪：选择一项对所有角色生效",
  ["@dingyi"] = "定仪",
  ["dingyi1"] = "额外摸牌",
  ["dingyi2"] = "手牌上限",
  ["dingyi3"] = "攻击范围",
  ["dingyi4"] = "额外回复",
  ["#dingyi_trigger"] = "定仪",
  ["#zuici-invoke"] = "罪辞：你可以令 %dest 失去“定仪”效果并获得你指定的一种智囊",
  ["#fubi-choice"] = "辅弼：选择为 %dest 更换的“定仪”效果",
  ["#fubi"] = "辅弼：更换一名角色“定仪”效果，或弃一张牌令一名角色“定仪”效果加倍直到你下回合开始",

  ["$dingyi1"] = "经国序民，还需制礼定仪。",
  ["$dingyi2"] = "无礼而治世，欲使国泰，安可得哉？",
  ["$zuici1"] = "既为朝堂宁定，吾请辞便是。",
  ["$zuici2"] = "国事为先，何惧清名有损！",
  ["$fubi1"] = "辅君弼主，士之所志也。",
  ["$fubi2"] = "献策思计，佐定江山。",
  ["~mobile__sunshao"] = "江东将相各有所能，奈何心向不一……",
}

local duyu = General(extension, "mobile__duyu", "qun", 4)
duyu.subkingdom = "jin"
local wuku = fk.CreateTriggerSkill{
  name = "wuku",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:getMark("@wuku") < 3 and data.card.type == Card.TypeEquip
  end,
  on_use = function(self, event, target, player)
    player.room:addPlayerMark(player, "@wuku")
  end,
}
local mobile__sanchen = fk.CreateTriggerSkill{
  name = "mobile__sanchen",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
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
local miewu = fk.CreateViewAsSkill{
  name = "miewu",
  pattern = ".",
  interaction = function(self, player)
    local all_names = U.getAllCardNames("btd")
    local names = U.getViewAsCardNames(player, self.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  handly_pile = true,
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
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, miewu.name)
  end,
}
duyu:addSkill(wuku)
duyu:addSkill(mobile__sanchen)
miewu:addRelatedSkill(miewu_delay)
duyu:addRelatedSkill(miewu)
Fk:loadTranslationTable{
  ["mobile__duyu"] = "杜预",
  ["#mobile__duyu"] = "文成武德",
  ["illustrator:mobile__duyu"] = "鬼画府",
  ["wuku"] = "武库",
  [":wuku"] = "锁定技，当一名角色使用装备时，你获得1个“武库”标记。（“武库”数量至多为3）",
  ["mobile__sanchen"] = "三陈",
  [":mobile__sanchen"] = "觉醒技，结束阶段，若你已有3个“武库”，你增加1点体力上限，回复1点体力，然后获得技能〖灭吴〗。",
  ["@wuku"] = "武库",
  ["miewu"] = "灭吴",
  ["#miewu_delay"] = "灭吴",
  [":miewu"] = "每回合限一次，你可以弃置1个“武库”，将一张牌当做任意一张基本牌或锦囊牌使用或打出；若如此做，你摸一张牌。",

  ["$wuku1"] = "损益万枢，竭世运机。",
  ["$wuku2"] = "胸藏万卷，充盈如库。",
  ["$mobile__sanchen1"] = "贼计已穷，陈兵吴地，可一鼓而下也。",
  ["$mobile__sanchen2"] = "伐吴此举，十有九利，惟陛下察之。",
  ["$miewu1"] = "倾荡之势已成，石城尽在眼下",
  ["$miewu2"] = "吾军势如破竹，江东六郡唾手可得。",
  ["~mobile__duyu"] = "洛水圆石，遂道向南，吾将以俭自完耳……",
}

local xunchen = General(extension, "nos__xunchen", "qun", 3)
local jianzhan = fk.CreateActiveSkill{
  name = "jianzhan",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#jianzhan",
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
    local targets = table.map(table.filter(room:getOtherPlayers(target), function(p)
      return target:inMyAttackRange(p) and target:getHandcardNum() > p:getHandcardNum() end), Util.IdMapper)
    if #targets == 0 then
      player:drawCards(1, self.name)
    else
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#jianzhan-choose::"..target.id, self.name, false, true)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(targets)
      end
      room:doIndicate(target.id, {to})
      local choice = room:askForChoice(target, {"jianzhan_slash::"..to, "jianzhan_draw:"..player.id}, self.name)
      if choice[10] == "d" then
        player:drawCards(1, self.name)
      else
        room:useVirtualCard("slash", nil, target, room:getPlayerById(to), self.name, true)
      end
    end
  end,
}
local duoji = fk.CreateActiveSkill{
  name = "duoji",
  anim_type = "offensive",
  frequency = Skill.Limited,
  prompt = "#duoji",
  card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 2 and Fk:currentRoom():getCardArea(to_select) == Player.Hand and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and #Fk:currentRoom():getPlayerById(to_select):getCardIds("e") > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead or target.dead or #target:getCardIds("e") == 0 then return end
    room:obtainCard(player.id, target:getCardIds("e"), true, fk.ReasonPrey)
  end,
}
xunchen:addSkill(jianzhan)
xunchen:addSkill(duoji)
Fk:loadTranslationTable{
  ["nos__xunchen"] = "荀谌",
  ["#nos__xunchen"] = "谋刃略锋",
  ["jianzhan"] = "谏战",
  [":jianzhan"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.视为其对攻击范围内你选择的另一名手牌少于其的角色使用一张【杀】；2.你摸一张牌。",
  ["duoji"] = "夺冀",
  [":duoji"] = "限定技，出牌阶段，你可以弃置两张手牌，获得一名其他角色装备区内所有的牌。",
  ["#jianzhan"] = "谏战：令一名角色选择视为对你指定的角色使用【杀】，或你摸一张牌",
  ["#jianzhan-choose"] = "谏战：选择 %dest 视为使用【杀】的目标",
  ["jianzhan_slash"] = "视为对%dest使用【杀】",
  ["jianzhan_draw"] = "%src摸一张牌",
  ["#duoji"] = "夺冀：你可以弃置两张手牌，获得一名其他角色装备区内所有的牌！",

  ["$jianzhan1"] = "若能迎天子以兴兵讨贼，大业可成。",
  ["$jianzhan2"] = "明公乃当世之雄，谁可匹敌？",
  ["$duoji1"] = "将军若献冀州，必安如泰山也。",
  ["$duoji2"] = "袁氏得冀州，必厚德将军。",
  ["~nos__xunchen"] = "惟愿不堕颍川荀氏之名……",
}

local godguojia = General(extension, "godguojia", "god", 3)
local godguojia_win = fk.CreateActiveSkill{ name = "godguojia_win_audio" }
godguojia_win.package = extension
Fk:addSkill(godguojia_win)

local godHuishi = fk.CreateActiveSkill{
  name = "mobile__god_huishi",
  anim_type = "drawcard",
  prompt = "#mobile__god_huishi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player.maxHp < 10
  end,
  card_filter = Util.FalseFunc,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cardsJudged = {}
    while true do
      local parsePattern = table.concat(table.map(cardsJudged, function(card)
        return card:getSuitString()
      end), ",")
      local judge = {
        who = player,
        reason = self.name,
        pattern = ".|.|" .. (parsePattern == "" and "." or "^(" .. parsePattern .. ")"),
        skipDrop = true,
      }
      room:judge(judge)
      table.insert(cardsJudged, judge.card)
      if player.dead or player.maxHp >= 10 or
        not table.every(cardsJudged, function(card)
          return card == judge.card or judge.card:compareSuitWith(card, true)
        end) or
        not room:askForSkillInvoke(player, self.name, nil, "#mobile__god_huishi-ask")
      then
        break
      end
      room:changeMaxHp(player, 1)
    end
    cardsJudged = table.filter(cardsJudged, function(card)
      return room:getCardArea(card.id) == Card.Processing
    end)
    if #cardsJudged == 0 then return end
    local targets = table.map(room.alive_players, Util.IdMapper)
    if player.dead or #targets == 0 then
      room:moveCards({
        ids = table.map(cardsJudged, function(card)
          return card:getEffectiveId()
        end),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJudge,
        skillName = self.name,
      })
    else
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#mobile__god_huishi-give", self.name, true)
      if #tos == 0 then tos = {player.id} end
      local to = room:getPlayerById(tos[1])
      room:moveCardTo(cardsJudged, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, true, player.id)
      if
        table.every(room.alive_players, function(p)
          return p:getHandcardNum() <= to:getHandcardNum()
        end)
      then
        room:changeMaxHp(player, -1)
      end
    end
  end,
}

godguojia:addSkill(godHuishi)

local tianyi = fk.CreateTriggerSkill{
  name = "mobile__tianyi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Start and
      player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) < 1
  end,
  can_wake = function(self, event, target, player, data)
    return table.every(player.room.alive_players, function(p)
      return #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data[1].to == p
      end, Player.HistoryGame) > 0
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 2)
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name,
    })

    local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#mobile__tianyi-choose", self.name, false)
    if #tos > 0 then
      room:handleAddLoseSkills(room:getPlayerById(tos[1]), "zuoxing")
    end
  end,
}
local limitedHuishi = fk.CreateActiveSkill{
  name = "mobile__limited_huishi",
  anim_type = "support",
  frequency = Skill.Limited,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return true
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])

    local wakeSkills = {}
    if #room.alive_players <= from.maxHp then
      wakeSkills = table.map(table.filter(to.player_skills, function(s)
        return s.frequency == Skill.Wake and to:usedSkillTimes(s.name, Player.HistoryGame) < 1
      end), function(skill)
        return skill.name 
      end)
    end

    if #wakeSkills > 0 and from.maxHp >= #room.alive_players then
      local choice = room:askForChoice(from, wakeSkills, self.name, "#mobile__limited_huishi-choice:"..to.id)
      room:addTableMarkIfNeed(to, "@mobile__limited_huishi", choice)
      room:addTableMarkIfNeed(to, MarkEnum.StraightToWake, choice)
    else
      to:drawCards(4, self.name)
    end

    room:changeMaxHp(from, -2)
  end,
}
local limitedHuishiClear = fk.CreateTriggerSkill{
  name = "#mobile__limited_huishi-clear",
  refresh_events = {fk.BeforeTriggerSkillUse},
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      data.willUse and
      data.skill.frequency == Skill.Wake and
      type(player:getMark("@mobile__limited_huishi")) == "table" and
      table.contains(player:getMark("@mobile__limited_huishi"), data.skill.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:removeTableMark(player, "@mobile__limited_huishi", data.skill.name)
    room:removeTableMark(player, MarkEnum.StraightToWake, data.skill.name)
  end,
}
local zuoxing = fk.CreateViewAsSkill{
  name = "zuoxing",
  prompt = "#zuoxing",
  interaction = function(self, player)
    local all_names = U.getAllCardNames("t")
    local names = U.getViewAsCardNames(player, self.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  enabled_at_play = function(self, player)
    return
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function(p)
        return table.find({ p.general, p.deputyGeneral }, function(name) return string.find(name, "godguojia") end) and p.maxHp > 1
      end)
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    local firstGodGuojia = table.filter(room:getAlivePlayers(), function(p)
      return table.find({ p.general, p.deputyGeneral }, function(name) return string.find(name, "godguojia") end) and p.maxHp > 1
    end)

    if firstGodGuojia then
      room:changeMaxHp(firstGodGuojia[1], -1)
    end
  end,
}
limitedHuishi:addRelatedSkill(limitedHuishiClear)
godguojia:addSkill(tianyi)
godguojia:addSkill(limitedHuishi)
godguojia:addRelatedSkill(zuoxing)
Fk:loadTranslationTable{
  ["godguojia"] = "神郭嘉",
  ["#godguojia"] = "星月奇佐",
  ["illustrator:godguojia"] = "木美人",
  ["mobile__god_huishi"] = "慧识",
  [":mobile__god_huishi"] = "出牌阶段限一次，若你的体力上限小于10，你可以判定，若结果与本次流程中的其他判定结果均不同，且你的体力上限小于10，你可加1点"..
  "体力上限并重复此流程。最后你将本次流程中所有生效的判定牌交给一名角色，若其手牌为全场最多，你减1点体力上限。",
  ["mobile__tianyi"] = "天翊",
  [":mobile__tianyi"] = "觉醒技，准备阶段开始时，若所有存活角色于本局游戏内均受到过伤害，你加2点体力上限，回复1点体力，令一名角色获得技能“佐幸”。",
  ["mobile__limited_huishi"] = "辉逝",
  [":mobile__limited_huishi"] = "限定技，出牌阶段，你可以选择一名角色，若其有未发动过的觉醒技且你的体力上限不小于存活角色数，你选择其中一项技能，"..
  "视为该角色满足其觉醒条件；否则其摸四张牌。最后你减2点体力上限。",
  ["zuoxing"] = "佐幸",
  [":zuoxing"] = "出牌阶段限一次，你可以令神郭嘉减1点体力上限，视为使用一张普通锦囊牌。",
  ["#mobile__god_huishi"] = "你可进行判定，然后将判定牌交给1名角色，其间你增加体力上限",
  ["#mobile__god_huishi-ask"] = "慧识：你可以加1点体力上限并重复此流程",
  ["#mobile__god_huishi-give"] = "慧识：将这些判定牌交给一名角色，“取消”：留给自己",
  ["#mobile__tianyi-choose"] = "天翊：请选择一名角色获得技能“佐幸”",
  ["@mobile__limited_huishi"] = "辉逝",
  ["#mobile__limited_huishi-choice"] = "辉逝：选择 %src 一个觉醒技，视为满足觉醒条件",
  ["#zuoxing"] = "佐幸：你可以令神郭嘉减1点体力上限，视为使用一张普通锦囊牌",

  ["$mobile__god_huishi1"] = "聪以知远，明以察微。",
  ["$mobile__god_huishi2"] = "见微知著，识人心智。",
  ["$mobile__tianyi1"] = "天命靡常，惟德是辅。",
  ["$mobile__tianyi2"] = "可成吾志者，必此人也！",
  ["$mobile__limited_huishi1"] = "丧家之犬，主公实不足虑也。",
  ["$mobile__limited_huishi2"] = "时事兼备，主公复有何忧？",
  ["$zuoxing1"] = "以聪虑难，悉咨于上。",
  ["$zuoxing2"] = "身计国谋，不可两遂。",
  ["~godguojia"] = "可叹桢干命也迂……",

  ["$godguojia_win_audio"] = "既为奇佐，怎可徒有虚名？",
}

local godxunyu = General(extension, "godxunyu", "god", 3)
local godxunyu_win = fk.CreateActiveSkill{ name = "godxunyu_win_audio" }
godxunyu_win.package = extension
Fk:addSkill(godxunyu_win)

local tianzuo = fk.CreateTriggerSkill{
  name = "tianzuo",
  anim_type = "defensive",
  events = {fk.GameStart, fk.PreCardEffect},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.PreCardEffect then
      return data.to == player.id and data.card.name == "raid_and_frontal_attack"
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local name = "raid_and_frontal_attack"
      local tianzuo_derivecards = {{name, Card.Spade, 2}, {name, Card.Spade, 4}, {name, Card.Spade, 6}, {name, Card.Spade, 8},
      {name, Card.Club, 3},{name, Card.Club, 5},{name, Card.Club, 7},{name, Card.Club, 9}}
      for _, id in ipairs(U.prepareDeriveCards(room, tianzuo_derivecards, "tianzuo_derivecards")) do
        if room:getCardArea(id) == Card.Void then
          table.removeOne(room.void, id)
          table.insert(room.draw_pile, math.random(1, #room.draw_pile), id)
          room:setCardArea(id, Card.DrawPile, nil)
        end
      end
      room:doBroadcastNotify("UpdateDrawPile", tostring(#room.draw_pile))
    else
      return true
    end
  end,
}
local zhinang = { "ex_nihilo", "dismantlement", "nullification" }
local lingce = fk.CreateTriggerSkill{
  name = "lingce",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(self) and
      not data.card:isVirtual() and
      (
        table.contains(zhinang, data.card.trueName) or
        table.contains(player:getTableMark("@$dinghan"), data.card.trueName) or
        data.card.trueName == "raid_and_frontal_attack"
      )
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local dinghan = fk.CreateTriggerSkill{
  name = "dinghan",
  anim_type = "defensive",
  events = {fk.TargetConfirming, fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then
      return false
    end

    if event == fk.TargetConfirming then
      return
        data.card.type == Card.TypeTrick and
        data.card.name ~= "raid_and_frontal_attack" and
        not table.contains(player:getTableMark("@$dinghan"), data.card.trueName)
    else
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TurnStart then
      local room = player.room

      local dinghanRecord = player:getTableMark("@$dinghan")
      local allTricksName = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card.type == Card.TypeTrick and not card.is_derived and not table.contains(dinghanRecord, card.trueName) then
          table.insertIfNeed(allTricksName, card.trueName)
        end
      end

      local choices = {"Cancel"}
      if #allTricksName > 0 then
        table.insert(choices, 1, "dinghan_addRecord")
      end
      if #dinghanRecord > 0 then
        table.insert(choices, 2, "dinghan_removeRecord")
      end
      local choice = room:askForChoice(player, choices, self.name)

      if choice == "Cancel" then
        return false
      end

      local cardName = room:askForChoice(player, choice == "dinghan_addRecord" and allTricksName or dinghanRecord, self.name)

      self.cost_data = { choice = choice, cardName = cardName }
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dinghanRecord = player:getTableMark("@$dinghan")
    if event == fk.TargetConfirming then
      table.insert(dinghanRecord, data.card.trueName)
      room:setPlayerMark(player, "@$dinghan", dinghanRecord)
      AimGroup:cancelTarget(data, player.id)
      return true
    else
      local costData = self.cost_data
      if costData.choice == "dinghan_addRecord" then
        table.insert(dinghanRecord, costData.cardName)
      else
        table.removeOne(dinghanRecord, costData.cardName)
      end
      room:setPlayerMark(player, "@$dinghan", #dinghanRecord > 0 and dinghanRecord or 0)
    end
  end,
}
godxunyu:addSkill(tianzuo)
godxunyu:addSkill(lingce)
godxunyu:addSkill(dinghan)

Fk:loadTranslationTable{
  ["godxunyu"] = "神荀彧",
  ["#godxunyu"] = "洞心先识",
  ["illustrator:godxunyu"] = "枭瞳",
  ["tianzuo"] = "天佐",
  [":tianzuo"] = "锁定技，游戏开始时，将8张<a href='raid_and_frontal_attack_href'>【奇正相生】</a>加入牌堆；【奇正相生】对你无效。",
  ["lingce"] = "灵策",
  [":lingce"] = "锁定技，当非虚拟且非转化的锦囊牌被使用时，若此牌的牌名属于<a href='bag_of_tricks'>智囊</a>牌名、〖定汉〗已记录的牌名或【奇正相生】时，你摸一张牌。",
  ["dinghan"] = "定汉",
  [":dinghan"] = "当你成为锦囊牌的目标时，若此牌牌名未被记录，则记录此牌名，然后取消此目标；回合开始时，你可以增加或移除一种锦囊牌的牌名记录。",
  ["@$dinghan"] = "定汉",
  ["dinghan_addRecord"] = "增加牌名",
  ["dinghan_removeRecord"] = "移除牌名",

  ["bag_of_tricks"] = "#\"<b>智囊</b>\" ：即【过河拆桥】【无懈可击】【无中生有】。",
  ["raid_and_frontal_attack_href"] = "【<b>奇正相生</b>】（♠2/♠4/♠6/♠8/♣3/♣5/♣7/♣9） 锦囊牌<br/>" ..
  "出牌阶段，对一名其他角色使用。当此牌指定目标后，你为其指定“奇兵”或“正兵”。"..
  "目标角色可以打出一张【杀】或【闪】，然后若其为：“正兵”目标且未打出【杀】，你对其造成1点伤害；“奇兵”目标且未打出【闪】，你获得其一张牌。",

  ["$tianzuo1"] = "此时进之多弊，守之多利，愿主公熟虑。",
  ["$tianzuo2"] = "主公若不时定，待四方生心，则无及矣。",
  ["$lingce1"] = "绍士卒虽众，其实难用，必无为也。",
  ["$lingce2"] = "袁军不过一盘砂砾，主公用奇则散。",
  ["$dinghan1"] = "杀身有地，报国有时。",
  ["$dinghan2"] = "益国之事，虽死弗避。",
  ["~godxunyu"] = "宁鸣而死，不默而生……",

  ["$godxunyu_win_audio"] = "汉室复兴，指日可待！",
}

return extension
