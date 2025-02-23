
local U = require "packages/utility/utility"

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
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("jianyu")
    room:notifySkillInvoked(player, "jianyu", "support")
    room:doIndicate(player.id, {data.to})
    room:getPlayerById(data.to):drawCards(1, "jianyu")
  end,

  refresh_events = {fk.TurnStart, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("jianyu_targets") ~= 0 and target == player
  end,
  on_refresh = function(self, event, target, player, data)
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
