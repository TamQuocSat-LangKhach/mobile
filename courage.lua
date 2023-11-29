local extension = Package("courage")
extension.extensionName = "mobile"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["courage"] = "手杀-始计篇·勇",
}

local wangshuang = General(extension, "mobile__wangshuang", "wei", 4)
local yiyongw = fk.CreateTriggerSkill{
  name = "yiyongw",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and
      data.from and data.from ~= player and not data.from.dead and player:getEquipment(Card.SubtypeWeapon) then
      local subcards = data.card:isVirtual() and data.card.subcards or {data.card.id}
      return #subcards>0 and table.every(subcards, function(id) return player.room:getCardArea(id) == Card.Processing end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yiyongw-invoke::"..data.from.id..":"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    local subcards = data.card:isVirtual() and data.card.subcards or {data.card.id}
    if player.dead or data.from.dead then return end
    if table.every(subcards, function(id) return table.contains(player:getCardIds("h"), id) end) then
      local card = Fk:cloneCard("slash")
      card:addSubcards(subcards)
      card.skillName = self.name
      if U.canUseCardTo(room, player, data.from, card, false, false) then
        local use = {
          from = player.id,
          tos = {{data.from.id}},
          card = card,
          extraUse = true,
        }
        if not data.from:getEquipment(Card.SubtypeWeapon) then
          use.additionalDamage = (use.additionalDamage or 0) + 1
        end
        room:useCard(use)
      end
    end
  end,
}
local shanxie = fk.CreateActiveSkill{
  name = "shanxie",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  prompt = "#shanxie",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local card = room:getCardsFromPileByRule(".|.|.|.|.|weapon")
    if #card == 0 then
      local ids = {}
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if p:getEquipment(Card.SubtypeWeapon) then
          table.insertIfNeed(ids, p:getEquipment(Card.SubtypeWeapon))
        end
      end
      card = {table.random(ids)}
    end
    if #card > 0 then
      room:obtainCard(player.id, card[1], true, fk.ReasonPrey)
    end
  end,
}
local shanxie_trigger = fk.CreateTriggerSkill{
  name = "#shanxie_trigger",
  main_skill = shanxie,
  mute = true,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    if target == player and data.responseToEvent and data.card.name == "jink" then
      local src = player.room:getPlayerById(data.responseToEvent.from)
      return src:hasSkill(self) and data.card.number <= 2 * src:getAttackRange()
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = Util.TrueFunc,
}
shanxie:addRelatedSkill(shanxie_trigger)
wangshuang:addSkill(yiyongw)
wangshuang:addSkill(shanxie)
Fk:loadTranslationTable{
  ["mobile__wangshuang"] = "王双",
  ["yiyongw"] = "异勇",
  [":yiyongw"] = "当你受到其他角色使用【杀】造成的伤害后，若你装备区内有武器牌，你可以获得此【杀】，然后将之当无距离和次数限制的普通【杀】对其"..
  "使用；若其装备区内没有武器牌，此【杀】伤害+1。",
  ["shanxie"] = "擅械",
  [":shanxie"] = "出牌阶段限一次，你可以从牌堆中获得一张武器牌（若没有，则随机获得一名其他角色装备区内的武器牌）。其他角色使用【闪】响应你使用的【杀】"..
  "时，若此【闪】没有点数或点数不大于你攻击范围的两倍，则此【闪】无效。",
  ["#yiyongw-invoke"] = "异勇：你可以获得此%arg，将之当【杀】对 %dest 使用",
  ["#shanxie"] = "擅械：你可以从牌堆获得一张武器牌（若没有则随机获得一名其他角色的武器）",

  ["$yiyongw1"] = "这么着急回营？哼！那我就送你一程！",
  ["$yiyongw2"] = "你的兵器，本大爷还给你！哈哈哈哈！",
  ["$shanxie1"] = "快快取我兵器，我上阵杀敌！",
  ["$shanxie2"] = "哈哈！还是自己的兵器用着趁手！",
  ["~mobile__wangshuang"] = "啊？速回主营！啊！",
}

local yuanhuan = General(extension, "yuanhuan", "wei", 3)
local qingjue = fk.CreateTriggerSkill{
  name = "qingjue",
  anim_type = "control",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and #AimGroup:getAllTargets(data.tos) == 1 and
      data.to ~= player.id and target.hp > player.room:getPlayerById(data.to).hp and
      not table.find(player.room.alive_players, function(p) return p.dying end) and
      player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qingjue-invoke:"..data.from..":"..data.to..":"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    if player.dead or target.dead or target:isKongcheng() then return end
    room:doIndicate(player.id, {target.id})
    local pindian = player:pindian({target}, self.name)
    AimGroup:cancelTarget(data, data.to)
    if pindian.results[target.id].winner == player then
      --do nothing
    else
      if player and data.card.skill:targetFilter(player.id, {}, {}, data.card) then
        if data.card.trueName == "collateral" then
          if target.dead then return end
          local victim = room:askForChoosePlayers(target, table.map(table.filter(room:getOtherPlayers(player), function(p)
            return player:inMyAttackRange(p) end), function(p) return p.id end), 1, 1,
            "#collateral-choose::"..player.id..":"..data.card:toLogString(), "collateral_skill", true)
          if #victim > 0 then
            room:doIndicate(target.id, {player.id})
            room:delay(500)
            room:doIndicate(player.id, {victim[1]})
            AimGroup:addTargets(room, data, {player.id, victim[1]})
          end
        else
          room:doIndicate(target.id, {player.id})
          AimGroup:addTargets(room, data, player.id)
        end
      end
    end
  end,
}
local fengjie = fk.CreateTriggerSkill{
  name = "fengjie",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if player.phase == Player.Start then
        return true
      elseif target.phase == Player.Finish then
        if player:getMark(self.name) == 0 then return end
        local to = player.room:getPlayerById(player:getMark(self.name))
        return not to.dead and player:getHandcardNum() ~= to:getHandcardNum()
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#fengjie-choose", self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(targets)
      end
      room:setPlayerMark(player, "@fengjie", room:getPlayerById(to).general)
      room:setPlayerMark(player, self.name, to)
    else
      local n = player:getHandcardNum() - room:getPlayerById(player:getMark(self.name)):getHandcardNum()
      if n < 0 then
        player:drawCards(-n, self.name)
      else
        room:askForDiscard(player, n, n, false, self.name, false)
      end
    end
  end,
}
yuanhuan:addSkill(qingjue)
yuanhuan:addSkill(fengjie)
Fk:loadTranslationTable{
  ["yuanhuan"] = "袁涣",
  ["qingjue"] = "请决",
  [":qingjue"] = "每轮限一次，一名其他角色使用牌指定一名体力值小于其的其他角色为唯一目标时，若没有角色处于濒死状态，你可以摸一张牌，与使用者拼点，"..
  "若你赢或你不是此牌合法目标，取消此牌；若你没赢且是此牌合法目标，此牌目标转移为你。",
  ["fengjie"] = "奉节",
  [":fengjie"] = "锁定技，准备阶段，你选择一名其他角色，直到你下回合开始，每名角色结束阶段，若其存活，你将手牌摸或弃至与其相同（至多摸至四张）。",
  ["#qingjue-invoke"] = "请决：%src 对 %dest 使用%arg，你可以摸一张牌与 %src 拼点，若赢则取消之，若没赢则转移给你",
  ["#fengjie-choose"] = "奉节：选择一名角色，每回合结束阶段你将手牌调整至与其相同",
  ["@fengjie"] = "奉节",

  ["$qingjue1"] = "兵者，凶器也，宜不得已而用之。",
  ["$qingjue2"] = "民安土重迁，易以顺行，难以逆动。",
  ["$qingjue3"] = "鼓之以道德，征之以仁义，才可得百姓之心。",
  ["$fengjie1"] = "见贤思齐，内自省也。",
  ["$fengjie2"] = "立本于道，置身于正。",
  ["~yuanhuan"] = "乱世之中，有礼无用啊……",
}

local courageGaolan = General(extension, "mobile__gaolan", "qun", 4)
Fk:loadTranslationTable{
  ["mobile__gaolan"] = "高览",
  ["~mobile__gaolan"] = "满腹忠肝，难抵一句谮言……唉！",
}

local jungong = fk.CreateViewAsSkill{
  name = "jungong",
  anim_type = "offensive",
  interaction = function(self)
    local usedTimes = Self:usedSkillTimes(self.name) + 1
    local choiceList = { "jungong_discard:::" .. usedTimes }
    if (Self.hp > 0) then
      table.insert(choiceList, "jungong_loseHp:::" .. usedTimes)
    end

    return UI.ComboBox { choices = choiceList }
  end,
  enabled_at_play = function(self, player)
    local usedTimes = player:usedSkillTimes(self.name) + 1
    return player:getMark("jungong_nullified-turn") == 0 and
      (player.hp > 0 or
      #player:getCardIds({ Player.Hand, Player.Equip }) >= usedTimes)
  end,
  card_filter = function(self, to_select, selected)
    return
    self.interaction.data:startsWith("jungong_discard") and
      #selected <= Self:usedSkillTimes(self.name) and
      not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  view_as = function(self, cards)
    if self.interaction.data:startsWith("jungong_discard") then
      if #cards ~= Self:usedSkillTimes(self.name) + 1 then
        return nil
      end
    end
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    card:setMark("jungong_discard", cards)
    return card
  end,
  before_use = function(self, player, useData)
    local room = player.room
    local cards = useData.card:getMark("jungong_discard")
    if cards and #cards > 0 then
      room:throwCard(cards, self.name, player, player)
    else
      room:loseHp(player, player:usedSkillTimes(self.name))
    end
    room:addPlayerMark(player, "@jungong-turn")

    useData.extraUse = true
  end
}
Fk:loadTranslationTable{
  ["jungong"] = "峻攻",
  [":jungong"] = "出牌阶段，你可以弃置X+1张牌或失去X+1点体力（X为你于本回合内发动过本技能的次数），并视为使用一张不计入次数，且无距离和次数限制的【杀】。若如此做，当此【杀】对目标角色造成伤害后，本技能于本回合内失效。",
  ["jungong_discard"] = "弃置%arg张牌",
  ["jungong_loseHp"] = "失去%arg点体力",
  ["@jungong-turn"] = "峻攻",

  ["$jungong1"] = "曹军营守，不能野战，此乃攻敌之机！",
  ["$jungong2"] = "若此营攻之不下，览何颜面见袁公！",
}

local jungongNullified = fk.CreateTriggerSkill{
  name = "#jungong-nullified",
  mute = true,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      table.contains(data.card.skillNames, "jungong") and
      not data.chain
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "jungong_nullified-turn", 1)
  end,
}

local jungongBuff = fk.CreateTargetModSkill{
  name = "#jungong-buff",
  residue_func = function(self, player, skill, scope, card)
    return (player:hasSkill(self) and card and table.contains(card.skillNames, jungong.name)) and 999 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return (player:hasSkill(self) and card and table.contains(card.skillNames, jungong.name)) and 999 or 0
  end,
}

jungong:addRelatedSkill(jungongNullified)
jungong:addRelatedSkill(jungongBuff)
courageGaolan:addSkill(jungong)

local dengli = fk.CreateTriggerSkill{
  name = "dengli",
  anim_type = "drawcard",
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.trueName == "slash" and
      player:hasSkill(self) and
      (
        event == fk.TargetSpecified and
        (data.to ~= player.id and player.hp == player.room:getPlayerById(data.to).hp) or
        (data.from ~= player.id and player.hp == player.room:getPlayerById(data.from).hp)
      )
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
Fk:loadTranslationTable{
  ["dengli"] = "等力",
  [":dengli"] = "当你使用【杀】指定其他角色为目标后，或当你成为其他角色使用【杀】的目标后，若你与其体力值相等，你可以摸一张牌。",
  ["$dengli1"] = "纵尔勇冠天下，吾亦不退半分！",
  ["$dengli2"] = "虚名何足夸口，败吾休得再提！",
}

courageGaolan:addSkill(dengli)

local huaman = General(extension, "mobile__huaman", "shu", 4, 4, General.Female)
Fk:loadTranslationTable{
  ["mobile__huaman"] = "花鬘",
  ["~mobile__huaman"] = "战事已定，吾愿终亦得偿……",
}

local xiangzhen = fk.CreateTriggerSkill{
  name = "xiangzhen",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.card.trueName == "savage_assault" then
      if event == fk.PreCardEffect then
        return data.to == player.id
      else
        return data.damageDealt
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.PreCardEffect then
      return true
    else
      player:drawCards(1, self.name)
      local players = (data.extra_data or {}).xiangzhen_drawers
      local targets = table.filter(player.room:getAlivePlayers(), function (p)
        return table.contains(players, p.id)
      end)
      for _, p in ipairs(targets) do
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card and data.card.name == "savage_assault"
  end,
  on_refresh = function(self, event, target, player, data)
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if parentUseData then
      local cardUseEvent = parentUseData.data[1]
      cardUseEvent.extra_data = cardUseEvent.extra_data or {}
      local xiangzhen_drawers = cardUseEvent.extra_data.xiangzhen_drawers or {}
      table.insertIfNeed(xiangzhen_drawers, player.id)
      cardUseEvent.extra_data.xiangzhen_drawers = xiangzhen_drawers
    end
  end,
}

Fk:loadTranslationTable{
  ["xiangzhen"] = "象阵",
  [":xiangzhen"] = "锁定技，【南蛮入侵】对你无效；【南蛮入侵】结算结束后，若此牌造成过伤害，你与伤害来源各摸一张牌。",
  ["$xiangzhen1"] = "象兵便可退敌，何劳本姑娘亲往？",
  ["$xiangzhen2"] = "哼！象阵所至，尽皆纷乱之师。",
}

huaman:addSkill(xiangzhen)

local fangzong = fk.CreateTriggerSkill{
  name = "fangzong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
      and player.phase == Player.Finish and player:getHandcardNum() < #player.room.alive_players
  end,
  on_use = function(self, event, target, player, data)
    local x = #player.room.alive_players - player:getHandcardNum()
    if x > 0 then
      player:drawCards(x, self.name)
    end
  end,
}

local fangzong_prohibit = fk.CreateProhibitSkill{
  name = "#fangzong_prohibit",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
    return from and from:inMyAttackRange(to) and card.is_damage_card and
      ((from:hasSkill(fangzong.name) and from:getMark("@@fangzong_invalidity-turn") == 0 and from.phase == Player.Play) or
      (to:hasSkill(fangzong.name) and to:getMark("@@fangzong_invalidity-turn") == 0))
  end,
}

fangzong:addRelatedSkill(fangzong_prohibit)

Fk:loadTranslationTable{
  ["fangzong"] = "芳踪",
  [":fangzong"] = "锁定技，出牌阶段，你使用伤害牌不能指定你攻击范围内的角色为目标；攻击范围内含有你的其他角色使用伤害牌不能指定你为目标。"..
  "结束阶段，你将手牌摸至X张（X为场上存活人数）。",

  ["@@fangzong_invalidity-turn"] = "芳踪失效",
  ["$fangzong1"] = "一战结缘难再许，痛为大义斩此情！",
  ["$fangzong2"] = "将军处处留情，小女芳心暗许。",
}

huaman:addSkill(fangzong)

local xizhan = fk.CreateTriggerSkill{
  name = "xizhan",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player ~= target and not target.dead and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    self.cost_data = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#xizhan-invoke::"..target.id, true)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #self.cost_data == 1 then
      local suits = {"spade", "heart", "club", "diamond", "nosuit"}
      local anim_types = {"support", "drawcard", "control", "offensive", "negative"}
      local index = table.indexOf(suits, Fk:getCardById(self.cost_data[1]):getSuitString())
      room:notifySkillInvoked(player, self.name, anim_types[index])
      if index < 5 then
        player:broadcastSkillInvoke(self.name, index + 1)
      end
      room:throwCard(self.cost_data, self.name, player, player)
      room:addPlayerMark(player, "@@fangzong_invalidity-turn")
      if index == 1 then
        room:useVirtualCard("analeptic", nil, target, target, self.name, false)
      elseif index == 2 then
        room:useVirtualCard("ex_nihilo", nil, player, player, self.name, false)
      elseif index == 3 then
        room:useVirtualCard("iron_chain", nil, player, target, self.name, false)
      elseif index == 4 then
        room:useVirtualCard("fire__slash", nil, player, target, self.name, false)
      end
    else
      if player:hasSkill(fangzong.name) then
        room:notifySkillInvoked(player, self.name, "defensive")
        player:broadcastSkillInvoke(self.name, 1)
      else
        room:notifySkillInvoked(player, self.name, "negative")
      end
      room:loseHp(player, 1, self.name)
    end
  end,
}

Fk:loadTranslationTable{
  ["xizhan"] = "嬉战",
  [":xizhan"] = "锁定技，其他角色回合开始时，你需选择一项：1.弃置一张牌并令你本回合〖芳踪〗失效，根据弃置牌的花色执行效果：♠，其视为使用一张【酒】；"..
  "<font color='red'>♥</font>，你视为使用一张【无中生有】；♣，你视为对其使用一张【铁索连环】；<font color='red'>♦</font>，你视为对其使用一张"..
  "火【杀】。}；2.失去1点体力。",

  ["#xizhan-invoke"] = "嬉战：%dest的回合，选择一张牌弃置并根据花色执行对应效果，或点取消则失去1点体力",
  ["$xizhan1"] = "战场纵非玩乐之所，尔等又能奈我何？",
  ["$xizhan2"] = "本姑娘只是戏耍一番，尔等怎下如此重手！",
  ["$xizhan3"] = "哎呀~母亲放心，鬘儿不会捣乱的。",
  ["$xizhan4"] = "嘻嘻，这样才好玩嘛。",
  ["$xizhan5"] = "哼！让你瞧瞧本姑娘的厉害！",
}

huaman:addSkill(xizhan)

local wenyang = General(extension, "mobile__wenyang", "wei", 4)
wenyang.subkingdom = "wu"
Fk:loadTranslationTable{
  ["mobile__wenyang"] = "文鸯",
  ["~mobile__wenyang"] = "半生功业，而见疑于一家之言，岂能无怨！",
}

local quedi = fk.CreateTriggerSkill{
  name = "quedi",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return
      data.firstTarget and
      target == player and
      player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < (1 + player:getMark("choujue_buff-turn")) and
      table.contains({ "slash", "duel" }, data.card.trueName) and
      player.room:getPlayerById(data.to):isAlive()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local to = room:getPlayerById(data.to)
    if not to:isKongcheng() then
      table.insert(choices, "quedi-prey")
    end

    if table.find(player:getCardIds(Player.Hand), function(id)
      return Fk:getCardById(id).type == Card.TypeBasic and not player:prohibitDiscard(Fk:getCardById(id))
    end) then
      table.insert(choices, "quedi-offense")
    end

    if #choices > 0 then
      table.insert(choices, 1, "beishui")
      table.insert(choices, "Cancel")

      local choice = room:askForChoice(player, choices, self.name)
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "beishui" then
      room:changeMaxHp(player, -1)
    end

    local to = room:getPlayerById(data.to)
    if self.cost_data == "quedi-prey" or (self.cost_data == "beishui" and not to:isKongcheng()) then
      local cardId = room:askForCardChosen(player, to, "h", self.name)
      room:obtainCard(player, cardId, false, fk.ReasonPrey)
    end
    if self.cost_data == "quedi-offense" or
      (
        self.cost_data == "beishui" and table.find(player:getCardIds(Player.Hand), function(id)
          return Fk:getCardById(id).type == Card.TypeBasic and not player:prohibitDiscard(Fk:getCardById(id))
        end)
      )
    then
      room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|.|.|.|basic")
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
}
Fk:loadTranslationTable{
  ["quedi"] = "却敌",
  [":quedi"] = "每回合限一次，当你使用【杀】或【决斗】指定唯一目标后，你可以选择一项：1.获得其一张手牌；2.弃置一张基本牌，令此【杀】或【决斗】"..
  "伤害基数+1；背水：减1点体力上限。",
  ["quedi-prey"] = "获得其手牌",
  ["quedi-offense"] = "弃基本牌令此伤害+1",

  ["$quedi1"] = "力摧敌阵，如视天光破云！",
  ["$quedi2"] = "让尔等有命追，无命回！",
}

wenyang:addSkill(quedi)

local chuifeng = fk.CreateViewAsSkill{
  name = "chuifeng",
  anim_type = "offensive",
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2 and player.hp > 0 and player:getMark("chuifeng_nullified-phase") == 0
  end,
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("duel")
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    player.room:loseHp(player, 1, self.name)
  end
}
local chuifengDefence = fk.CreateTriggerSkill{
  name = "#chuifeng_defence",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and table.contains(data.card.skillNames, chuifeng.name)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "chuifeng_nullified-phase", 1)
    return true
  end,
}
chuifeng:addAttachedKingdom("wei")
chuifeng:addRelatedSkill(chuifengDefence)
Fk:loadTranslationTable{
  ["chuifeng"] = "椎锋",
  ["#chuifeng_defence"] = "椎锋",
  [":chuifeng"] = "魏势力技，出牌阶段限两次，你可以失去1点体力，并视为使用一张【决斗】。当你受到以此法使用的【决斗】造成的伤害时，防止此伤害，"..
  "本技能于此阶段内失效。",

  ["$chuifeng1"] = "率军冲锋，不惧刀枪所阻！",
  ["$chuifeng2"] = "登锋履刃，何妨马革裹尸！",
}

wenyang:addSkill(chuifeng)

local chongjian = fk.CreateViewAsSkill{
  name = "chongjian",
  interaction = UI.ComboBox { choices = { "slash", "analeptic" } },
  pattern = "slash,analeptic",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return
    end

    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, useData)
    useData.extra_data = useData.extra_data or {}
    useData.extra_data.chongjianUser = player.id
  end,
  enabled_at_response = function(self, player, cardResponsing)
    return player:hasSkill(self) and not cardResponsing
  end,
}
Fk:loadTranslationTable{
  ["chongjian"] = "冲坚",
  [":chongjian"] = "吴势力技，你可以将装备牌当【酒】或无距离限制且无视防具的【杀】使用。当你以此法使用的【杀】对一名角色造成伤害后，"..
  "你获得其装备区里的X张牌（X为伤害值）。",
  ["#chongjian_buff"] = "冲坚",

  ["$chongjian1"] = "尔等良将，于我不堪一击！",
  ["$chongjian2"] = "此等残兵，破之何其易也！",
}

chongjian:addAttachedKingdom("wu")

local chongjianBuff = fk.CreateTriggerSkill{
  name = "#chongjian_buff",
  mute = true,
  refresh_events = {fk.TargetSpecified, fk.Damaged, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      return (data.extra_data or {}).chongjianNullified
    elseif event == fk.TargetSpecified then
      return table.contains(data.card.skillNames, chongjian.name) and room:getPlayerById(data.to):isAlive()
    else
      if data.to:isAlive() and #data.to:getCardIds(Player.Equip) > 0 then
        local parentUseData = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        return parentUseData and (parentUseData.data[1].extra_data or {}).chongjianUser == player.id
      end

      return false
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      for key, num in pairs(data.extra_data.chongjianNullified) do
        local p = room:getPlayerById(tonumber(key))
        if p:getMark(fk.MarkArmorNullified) > 0 then
          room:removePlayerMark(p, fk.MarkArmorNullified, num)
        end
      end

      data.chongjianNullified = nil
    elseif event == fk.TargetSpecified then
      room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)

      data.extra_data = data.extra_data or {}
      data.extra_data.chongjianNullified = data.extra_data.chongjianNullified or {}
      data.extra_data.chongjianNullified[tostring(data.to)] = (data.extra_data.chongjianNullified[tostring(data.to)] or 0) + 1
    else
      local equipsNum = #data.to:getCardIds(Player.Equip)
      local num = math.min(equipsNum, data.damage)
      local cards = room:askForCardsChosen(player, data.to, num, num, "e", self.name)

      local pack = Fk:cloneCard("slash")
      pack:addSubcards(cards)
      room:obtainCard(player, pack, true, fk.ReasonPrey)
    end
  end,
}
chongjian:addRelatedSkill(chongjianBuff)

local chongjianUnlimited = fk.CreateTargetModSkill{
  name = "#chongjian_unlimited",
  distance_limit_func = function(self, player, skill, card)
    return (card and table.contains(card.skillNames, chongjian.name)) and 999 or 0
  end,
}
chongjian:addRelatedSkill(chongjianUnlimited)
wenyang:addSkill(chongjian)

local mobileChoujue = fk.CreateTriggerSkill{
  name = "mobile__choujue",
  anim_type = "drawcard",
  events = {fk.Deathed},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.damage and data.damage.from == player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    room:drawCards(player, 2, self.name)
    room:addPlayerMark(player, "choujue_buff-turn", 1)
  end,
}
Fk:loadTranslationTable{
  ["mobile__choujue"] = "仇决",
  [":mobile__choujue"] = "锁定技，当你杀死一名角色后，你加1点体力上限，摸两张牌，你本回合〖却敌〗可发动次数+1。",

  ["$mobile__choujue1"] = "血海深仇，便在今日来报！",
  ["$mobile__choujue2"] = "取汝之头，以祭先父！",
}

wenyang:addSkill(mobileChoujue)

return extension
