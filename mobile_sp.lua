local extension = Package("mobile_sp")
extension.extensionName = "mobile"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["mobile_sp"] = "手杀-SP",
}

--SP武将组：1~5重复
--SP6：董承
local mobile__dongcheng = General(extension, "mobile__dongcheng", "qun", 4)
local chengzhao = fk.CreateTriggerSkill{
  name = "chengzhao",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Finish and not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player), function(p) return player:canPindian(p) end) then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.PlayerHand and move.to == player.id then
            n = n + #move.moveInfo
          end
        end
      end, Player.HistoryTurn)
      return n >= 2
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player.room:getOtherPlayers(player), function(p) return player:canPindian(p) end)
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#chengzhao-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local pindian = player:pindian({to}, self.name)
    local winner = pindian.results[to.id].winner
    if winner and winner == player then
      room:useVirtualCard("slash", nil, player, to, self.name, true)
    end
  end,
  refresh_events = {fk.TargetSpecified, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      return target == player and data.card and table.contains(data.card.skillNames, self.name)
    else
      return data.extra_data and data.extra_data.chengzhaoNullified
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
      data.extra_data = data.extra_data or {}
      data.extra_data.chengzhaoNullified = data.extra_data.chengzhaoNullified or {}
      data.extra_data.chengzhaoNullified[tostring(data.to)] = (data.extra_data.chengzhaoNullified[tostring(data.to)] or 0) + 1
    else
      for key, num in pairs(data.extra_data.chengzhaoNullified) do
        local p = room:getPlayerById(tonumber(key))
        if p:getMark(fk.MarkArmorNullified) > 0 then
          room:removePlayerMark(p, fk.MarkArmorNullified, num)
        end
      end
      data.chengzhaoNullified = nil
    end
  end,
}
mobile__dongcheng:addSkill(chengzhao)
Fk:loadTranslationTable{
  ["mobile__dongcheng"] = "董承",
  ["#mobile__dongcheng"] = "沥胆卫汉",
  ["illustrator:mobile__dongcheng"] = "绘聚艺堂",

  ["chengzhao"] = "承诏",
  [":chengzhao"] = "一名角色的结束阶段，若你本回合获得过至少两张牌，你可以与一名其他角色拼点，若你赢，视为你对其使用一张无视防具的【杀】。",
  ["#chengzhao-choose"] = "承诏：你可以与一名其他角色拼点，若你赢，视为你对其使用一张无视防具的【杀】",

  ["$chengzhao1"] = "定当为皇上诛杀首害！",
  ["$chengzhao2"] = "此诏字字诛心，岂能不斩曹贼！",
  ["~mobile__dongcheng"] = "九泉之下，我等着你曹贼到来！",
}

--SP7：陶谦 杨仪
local taoqian = General(extension, "taoqian", "qun", 3)
local zhaohuo = fk.CreateTriggerSkill{
  name = "zhaohuo",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and player.maxHp > 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player.maxHp - 1
    room:changeMaxHp(player, -n)
    if not player.dead then
      player:drawCards(n, self.name)
    end
  end,
}
taoqian:addSkill(zhaohuo)
local yixiang = fk.CreateTriggerSkill{
  name = "yixiang",
  anim_type = "drawcard",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) < 1
    and player.room:getPlayerById(data.from).hp > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(names, Fk:getCardById(id).trueName)
    end
    local ids = table.filter(room.draw_pile, function (id) -- wait for fixing Exppattern
      return Fk:getCardById(id).type == Card.TypeBasic and not table.contains(names, Fk:getCardById(id).trueName)
    end)
    if #ids > 0 then
      room:obtainCard(player, table.random(ids), false, fk.ReasonPrey)
    end
  end,
}
taoqian:addSkill(yixiang)
local yirang = fk.CreateTriggerSkill{
  name = "yirang",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local ids,types = {},{}
    for _, id in ipairs(player:getCardIds("he")) do
      if Fk:getCardById(id).type ~= Card.TypeBasic then
        table.insertIfNeed(types, Fk:getCardById(id).type)
        table.insert(ids, id)
      end
    end
    if #ids == 0 then return false end
    local targets = table.filter(room.alive_players, function (p) return p.maxHp > player.maxHp end)
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#yirang-choose:::"..#types, self.name, true)
    if #tos > 0 then
      self.cost_data = {ids, tos[1], #types}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[2])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(self.cost_data[1])
    room:obtainCard(to, dummy, false, fk.ReasonGive)
    room:changeMaxHp(player, to.maxHp-player.maxHp)
    if not player.dead and player:isWounded() then
      room:recover { num = self.cost_data[3], skillName = self.name, who = player , recoverBy = player}
    end
  end,
}
taoqian:addSkill(yirang)
Fk:loadTranslationTable{
  ["taoqian"] = "陶谦",
  ["#taoqian"] = "膺秉温仁",
  ["illustrator:taoqian"] = "F.源",
  ["zhaohuo"] = "招祸",
  [":zhaohuo"] = "锁定技，当其他角色进入濒死状态时，若你的体力上限大于1，你将体力上限减至1点，然后你摸等同于体力上限减少数张牌。",
  ["yixiang"] = "义襄",
  [":yixiang"] = "每回合限一次，当你成为一名体力值大于你的角色使用牌的目标后，你可以从牌堆中随机获得一张你没有的基本牌。",
  ["yirang"] = "揖让",
  [":yirang"] = "出牌阶段开始时，你可以将所有非基本牌（至少一张）交给一名体力上限大于你的其他角色，然后你将体力上限增至与该角色相同并回复X点体力"..
  "（X为你以此法交给其的牌中包含的类别数）。",
  ["#yirang-choose"] = "揖让：可以将所有非基本牌交给一名体力上限大于你的角色，将体力上限增至与其相同并回复%arg体力",

  ["$zhaohuo1"] = "我获罪于天，致使徐州之民，受此大难！",
  ["$zhaohuo2"] = "如此一来，徐州危矣……",
  ["$yixiang1"] = "一方有难，八方应援。",
  ["$yixiang2"] = "昔日有恩，还望此时来报。",
  ["$yirang1"] = "明公切勿推辞！",
  ["$yirang2"] = "万望明公可怜汉家城池为重！",
  ["~taoqian"] = "悔不该差使小人，招此祸患。",
}

local mobile__yangyi = General(extension, "mobile__yangyi", "shu", 3)

local mobile__gongsun = fk.CreateTriggerSkill{
  name = "mobile__gongsun",
  events = {fk.EventPhaseStart},
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local _, dat = room:askForUseActiveSkill(player, "mobile__gongsun_vs", "#mobile__gongsun-choose")
    if dat then
      self.cost_data = {dat.cards, dat.targets[1]}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data[1], self.name, player, player)
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card:isCommonTrick() or card.type == Card.TypeBasic) and not card.is_derived then
        table.insertIfNeed(names, card.trueName)
      end
    end
    if player.dead or #names == 0 then return end
    local to = room:getPlayerById(self.cost_data[2])
    local choice = room:askForChoice(player, names, self.name, "#mobile__gongsun-name:" .. to.id)
    local tos = U.getMark(player, "_mobile__gongsun")
    table.insertIfNeed(tos, to.id)
    room:setPlayerMark(player, "_mobile__gongsun", tos)
    for _, p in ipairs({player, to}) do
      local record = U.getMark(p, "@mobile__gongsun")
      table.insert(record, choice)
      room:setPlayerMark(p, "@mobile__gongsun", record)
    end
  end,

  refresh_events = {fk.TurnStart, fk.Death},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_mobile__gongsun") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@mobile__gongsun", 0)
    table.forEach(table.map(player:getMark("_mobile__gongsun"), function(pid)
      return room:getPlayerById(pid)
    end), function(p)
      room:setPlayerMark(p, "@mobile__gongsun", 0)
    end)
  end,
}
local mobile__gongsun_prohibit = fk.CreateProhibitSkill{
  name = "#mobile__gongsun_prohibit",
  prohibit_use = function(self, player, card)
    local mark = U.getMark(player, "@mobile__gongsun")
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.contains(mark, card.trueName) and
    table.find(cards, function(id) return table.contains(player.player_cards[Player.Hand], id) end)
  end,
  prohibit_response = function(self, player, card)
    local mark = U.getMark(player, "@mobile__gongsun")
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.contains(mark, card.trueName) and
    table.find(cards, function(id) return table.contains(player.player_cards[Player.Hand], id) end)
  end,
  prohibit_discard = function(self, player, card)
    local mark = U.getMark(player, "@mobile__gongsun")
    return table.contains(mark, card.trueName) and table.contains(player.player_cards[Player.Hand], card.id)
  end,
}
mobile__gongsun:addRelatedSkill(mobile__gongsun_prohibit)
mobile__yangyi:addSkill("os__duoduan")
mobile__yangyi:addSkill(mobile__gongsun)
local mobile__gongsun_vs = fk.CreateActiveSkill{
  name = "mobile__gongsun_vs",
  card_num = 2,
  card_filter = function (self, to_select, selected)
    return #selected < 2 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
}
Fk:addSkill(mobile__gongsun_vs)
Fk:loadTranslationTable{
  ["mobile__yangyi"] = "杨仪",
  ["#mobile__yangyi"] = "孤鹬",
  ["illustrator:mobile__yangyi"] = "绘聚艺堂",

  ["mobile__gongsun"] = "共损",
  [":mobile__gongsun"] = "出牌阶段开始时，你可以弃置两张牌并选择一名其他角色，然后你声明一种基本牌或普通锦囊牌的牌名。若如此做，直到你的下个回合开始或你死亡时，你与其均不能使用、打出或弃置此牌名的手牌。",
  ["#mobile__gongsun-choose"] = "共损：弃置两张牌并选择一名其他角色",
  ["#mobile__gongsun-name"] = "共损：选择一种基本牌或普通锦囊牌的牌名，直至你下个回合开始前，你和 %src 无法使用、打出或弃置该牌名的手牌。",
  ["@mobile__gongsun"] = "共损",
  ["mobile__gongsun_vs"] = "共损",

  ["$os__duoduan_mobile__yangyi1"] = "度势而谋，断计求胜。",
  ["$os__duoduan_mobile__yangyi2"] = "逢敌先虑，定策后图。",
  ["$mobile__gongsun1"] = "胸怀大才者，岂能与庸人共处？",
  ["$mobile__gongsun2"] = "满朝文武，半数庶子而已。",
  ["~mobile__yangyi"] = "如今追悔，亦不可复及矣……",
}

--SP8：审配
local mobile__shenpei = General(extension, "mobile__shenpei", "qun", 2, 3)
local shouye = fk.CreateTriggerSkill{
  name = "shouye",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and data.from ~= player.id and #AimGroup:getAllTargets(data.tos) == 1
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#shouye-invoke::"..data.from..":"..data.card.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local choices = U.doStrategy(room, player, from, {"shouye_choice1","shouye_choice2"}, {"shouye_choice3","shouye_choice4"}, self.name, 2)
    if (choices[1] == "shouye_choice1" and choices[2] == "shouye_choice3") or (choices[1] == "shouye_choice2" and choices[2] == "shouye_choice4") then
      table.insertIfNeed(data.nullifiedTargets, player.id)
      data.extra_data = data.extra_data or {}
      data.extra_data.shouye = player.id
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      end
    end
  end,
}
local shouye_delay = fk.CreateTriggerSkill{
  name = "#shouye_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.shouye and data.extra_data.shouye == player.id
    and #player.room:getSubcardsByRule(data.card, {Card.Processing}) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getSubcardsByRule(data.card, {Card.Processing})
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(ids)
    room:obtainCard(player, dummy, true, fk.ReasonJustMove)
  end,
}
shouye:addRelatedSkill(shouye_delay)
mobile__shenpei:addSkill(shouye)
local liezhi = fk.CreateTriggerSkill{
  name = "liezhi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Start and player:getMark("@@liezhi_failed") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function (p) return not p:isAllNude() end)
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 2, "#liezhi-choose", self.name, true)
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, pid in ipairs(self.cost_data) do
      if player.dead then break end
      local to = room:getPlayerById(pid)
      if not to:isAllNude() then
        local id = room:askForCardChosen(player, to, "hej", self.name)
        room:throwCard({id}, self.name, to, player)
      end
    end
  end,
  refresh_events = {fk.Damaged, fk.EventPhaseStart},
  can_refresh = function (self, event, target, player, data)
    if event == fk.Damaged then
      return player == target and player:hasSkill(self,true) and player:getMark("@@liezhi_failed") == 0
    else
      return player == target and player:hasSkill(self,true) and player.phase == Player.Finish
    end
  end,
  on_refresh = function (self, event, target, player, data)
    if event == fk.Damaged then
      player:broadcastSkillInvoke(self.name)
      player.room:setPlayerMark(player, "@@liezhi_failed", 1)
    else
      player.room:setPlayerMark(player, "@@liezhi_failed", 0)
    end
  end,
}
mobile__shenpei:addSkill(liezhi)
Fk:loadTranslationTable{
  ["mobile__shenpei"] = "审配",
  ["#mobile__shenpei"] = "正南义北",
  ["illustrator:mobile__shenpei"] = "YanBai",

  ["shouye"] = "守邺",
  [":shouye"] = "每回合限一次，当你成为其他角色使用牌的唯一目标后，你可以与其对策，若你对策成功，此牌对你无效，且此牌结算结束后，你获得之。",
  ["#shouye-invoke"] = "守邺：你可以与 %dest 对策，若成功，%arg 对你无效且你获得之",
  ["shouye_choice1"] = "开门诱敌",
  ["shouye_choice2"] = "奇袭粮道",
  ["shouye_choice3"] = "全力攻城",
  ["shouye_choice4"] = "分兵围城",
  [":shouye_choice1"] = "开门诱敌！",
  [":shouye_choice2"] = "奇袭粮道！",
  [":shouye_choice3"] = "全力攻城？",
  [":shouye_choice4"] = "分兵围城？",
  ["liezhi"] = "烈直",
  [":liezhi"] = "①准备阶段，你可以依次弃置至多两名其他角色区域内的各一张牌；②当你受到伤害后，〖烈直〗失效直到你的下个结束阶段。",
  ["#liezhi-choose"] = "烈直：弃置至多两名其他角色区域内一张牌",
  ["@@liezhi_failed"] = "烈直失效",
  ["$shouye1"] = "敌军攻势渐怠，还望诸位依策坚守。",
  ["$shouye2"] = "袁幽州不日便至，当行策建功以报之。",
  ["$liezhi1"] = "只恨箭支太少，不能射杀汝等！",
  ["$liezhi2"] = "身陨事小，秉节事大。",
  ["~mobile__shenpei"] = "吾君在北，但求面北而亡！",
}

--SP9：苏飞 贾逵 许贡
local mobile__sufei = General(extension, "mobile__sufei", "wu", 4)
local zhengjian = fk.CreateTriggerSkill{
  name = "zhengjian",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Finish and table.find(player.room.alive_players, function(p)
          return type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0 end)
      else
        return table.find(player.room.alive_players, function(p)
          return not (type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0) end)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local targets = table.filter(player.room.alive_players, function(p)
        return type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0 end)
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#zhengjian-choose", self.name, false)
      local to = room:getPlayerById(tos[1])
      room:setPlayerMark(to, "@zhengjian", "0")
    else
      for _, p in ipairs(room.alive_players) do
        local mark = type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") or 0
        room:setPlayerMark(p, "@zhengjian", 0)
        if mark > 0 then
          local x = math.min(mark, p.maxHp, 5)
          p:drawCards(x, self.name)
        end
      end
    end
  end,
  refresh_events = {fk.CardUsing, fk.CardResponding, fk.Deathed},
  can_refresh = function (self, event, target, player, data)
    if event == fk.Deathed then
      return not table.find(player.room.alive_players, function(p) return p:hasSkill(self,true) end)
    else
      return target == player and not (type(player:getMark("@zhengjian")) == "number" and player:getMark("@zhengjian") == 0)
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.Deathed then
      for _, p in ipairs(room.alive_players) do
        room:setPlayerMark(p, "@zhengjian", 0)
      end
    else
      local mark = type(player:getMark("@zhengjian")) == "number" and player:getMark("@zhengjian") or 0
      room:setPlayerMark(player, "@zhengjian", math.min(5,mark+1))
    end
  end,
}
mobile__sufei:addSkill(zhengjian)
local gaoyuan = fk.CreateTriggerSkill{
  name = "gaoyuan",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if target == player and player:hasSkill(self) and data.card.trueName == "slash" then
      return table.find(room:getOtherPlayers(player), function (p)
        return p.id ~= data.from and not room:getPlayerById(data.from):isProhibited(p, data.card) and
          not (type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0)
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function (p)
      return p.id ~= data.from and not room:getPlayerById(data.from):isProhibited(p, data.card) and
        not (type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0)
    end)
    if #targets == 0 then
      return false
    elseif #targets == 1 then
      local card = room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#gaoyuan-invoke:"..targets[1].id)
      if #card > 0 then
        self.cost_data = {targets[1].id, card[1]}
        return true
      end
    else
      local tos, cid = room:askForChooseCardAndPlayers(player, targets, 1, 1, nil, "#gaoyuan-choose", self.name, true, true)
      if #tos > 0 then
        self.cost_data = {tos[1], cid}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = self.cost_data[1]
    room:doIndicate(player.id, { to })
    room:throwCard(self.cost_data[2], self.name, player, player)
    AimGroup:cancelTarget(data, player.id)
    AimGroup:addTargets(room, data, to)
    return true
  end,
}
mobile__sufei:addSkill(gaoyuan)
Fk:loadTranslationTable{
  ["mobile__sufei"] = "苏飞",
  ["zhengjian"] = "诤荐",
  [":zhengjian"] = "锁定技，结束阶段，你令一名角色获得“诤荐”标记，然后其于你的下个回合开始时摸X张牌并移去“诤荐”标记（X为其此期间使用或打出牌的数量且"..
  "至多为其体力上限且至多为5）。",
  ["@zhengjian"] = "诤荐",
  ["#zhengjian-choose"] = "选择“诤荐”的目标",
  ["gaoyuan"] = "告援",
  [":gaoyuan"] = "当你成为一名角色使用【杀】的目标时，你可以弃置一张牌，将此【杀】转移给另一名有“诤荐”标记的其他角色。",
  ["#gaoyuan-choose"] = "告援：你可以弃置一张牌，将此【杀】转移给一名有“诤荐”标记的其他角色",
  ["#gaoyuan-invoke"] = "告援：你可以弃置一张牌，将此【杀】转移给%src",


  ["$zhengjian1"] = "此人有雄猛逸才，还请明公观之。",
  ["$zhengjian2"] = "若明公得此人才，定当如虎添翼。",
  ["$gaoyuan1"] = "烦请告知兴霸，请他务必相助。",
  ["$gaoyuan2"] = "如今事急，唯有兴霸可救。",
  ["~mobile__sufei"] = "本可共图大业，奈何主公量狭器小啊……",
}

local jiakui = General(extension, "tongqu__jiakui", "wei", 4)
local tongqu = fk.CreateTriggerSkill{
  name = "tongqu",
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        return target == player and player.phase == Player.Start and
          table.find(player.room.alive_players, function(p) return p:getMark("@@tongqu") == 0 end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      local targets = table.map(table.filter(player.room.alive_players, function(p) return p:getMark("@@tongqu") == 0 end), Util.IdMapper)
      local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#tongqu-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:setPlayerMark(player, "@@tongqu", 1)
    else
      room:loseHp(player, 1, self.name)
      room:setPlayerMark(room:getPlayerById(self.cost_data), "@@tongqu", 1)
    end
  end,
}
local tongqu_trigger = fk.CreateTriggerSkill{
  name = "#tongqu_trigger",
  mute = true,
  events = {fk.DrawNCards, fk.AfterDrawNCards, fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@tongqu") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local src = table.find(room.alive_players, function(p) return p:hasSkill("huaiju") end)
    if src then
      src:broadcastSkillInvoke("tongqu")
      if event == fk.DrawNCards then
        room:notifySkillInvoked(src, "tongqu", "drawcard")
      elseif event == fk.EnterDying then
        room:notifySkillInvoked(src, "tongqu", "negative")
      end
    end
    if event == fk.DrawNCards then
      data.n = data.n + 1  --据说手杀是drawCards(1)，离谱
      return true
    elseif event == fk.AfterDrawNCards then
      if not player:isNude() then
        local success, dat = room:askForUseActiveSkill(player, "tongqu_active", "#tongqu-give", false)
        if success then
          if #dat.targets == 1 then
            local to = room:getPlayerById(dat.targets[1])
            local id = dat.cards[1]
            room:obtainCard(to.id, id, false, fk.ReasonGive)
            if room:getCardOwner(id) == to and room:getCardArea(id) == Card.PlayerHand and
              Fk:getCardById(id).type == Card.TypeEquip and not to:isProhibited(to, Fk:getCardById(id)) then
            room:useCard({
              from = to.id,
              tos = {{to.id}},
              card = Fk:getCardById(id),
            })
          end
          else
            room:throwCard(dat.cards, "tongqu", player, player)
          end
        end
      end
    elseif event == fk.EnterDying then
      room:setPlayerMark(player, "@@tongqu", 0)
    end
  end
}
local tongqu_active = fk.CreateActiveSkill{
  name = "tongqu_active",
  mute = true,
  card_num = 1,
  min_target_num = 0,
  max_target_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("@@tongqu") > 0
  end,
  feasible = function (self, selected, selected_cards)
    if #selected_cards == 1 then
      if #selected == 0 then
        return not Self:prohibitDiscard(Fk:getCardById(selected_cards[1]))
      elseif #selected == 1 then
        return true
      end
    end
  end,
}
local wanlan = fk.CreateTriggerSkill{
  name = "wanlan",
  anim_type = "support",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.damage >= target.hp and #player:getCardIds("e") > 0 and
      table.find(player:getCardIds("e"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wanlan-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    player:throwAllCards("e")
    return true
  end,
}
tongqu:addRelatedSkill(tongqu_trigger)
Fk:addSkill(tongqu_active)
jiakui:addSkill(tongqu)
jiakui:addSkill(wanlan)
Fk:loadTranslationTable{
  ["tongqu__jiakui"] = "贾逵",
  ["tongqu"] = "通渠",
  [":tongqu"] = "游戏开始时，你获得一枚“渠”标记；准备阶段，你可以失去1点体力令一名没有“渠”标记的角色获得“渠”标记。有“渠”的角色摸牌阶段额外摸一张牌，"..
  "然后将一张牌交给另一名有“渠”的角色或弃置一张牌，若以此法给出的是装备牌则其使用之。有“渠”的角色进入濒死状态时移除其“渠”。",
  ["wanlan"] = "挽澜",
  [":wanlan"] = "当一名角色受到致命伤害时，你可弃置装备区中所有牌（至少一张），防止此伤害。",
  ["@@tongqu"] = "通渠",
  ["#tongqu-choose"] = "通渠：你可以失去1点体力，令一名角色获得“渠”标记",
  ["#tongqu-give"] = "通渠：将一张牌交给一名有“渠”的角色，或弃置一张牌",
  ["tongqu_active"] = "通渠",
  ["#wanlan-invoke"] = "挽澜：你可以弃置所有装备，防止 %dest 受到的致命伤害！",

  ["$tongqu1"] = "兴凿修渠，依水屯军！",
  ["$tongqu2"] = "开渠疏道，以备军实！",
  ["$wanlan1"] = "石亭既败，断不可再失大司马！",
  ["$wanlan2"] = "大司马怀托孤之重，岂容半点有失？",
  ["~tongqu__jiakui"] = "生怀死忠之心，死必为报国之鬼！",
}

local xugong = General(extension, "mobile__xugong", "wu", 3)
local mobile__biaozhao = fk.CreateTriggerSkill{
  name = "mobile__biaozhao",
  mute = true,
  derived_piles = "mobile__biaozhao_message",
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseStart then
      return (player.phase == Player.Finish and not player:isNude()) or
      (player.phase == Player.Start and #player:getPile("mobile__biaozhao_message") > 0)
    elseif #player:getPile("mobile__biaozhao_message") > 0 then
      local numbers = {}
      for _, id in ipairs(player:getPile("mobile__biaozhao_message")) do
        table.insertIfNeed(numbers, Fk:getCardById(id).number)
      end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if table.contains(numbers, card.number) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      local cards = room:askForCard(player, 1, 1, true, self.name, true, ".", "#mobile__biaozhao-cost")
      if #cards > 0 then
        self.cost_data = cards[1]
        return true
      end
      return false
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name, "support")
      if player.phase == Player.Finish then
        player:addToPile("mobile__biaozhao_message", self.cost_data, false, self.name)
      else
        room:moveCards({
          from = player.id,
          ids = player:getPile("mobile__biaozhao_message"),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
        })
        local targets = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#mobile__biaozhao-choose", self.name, false)
        if #targets > 0 then
          local to = room:getPlayerById(targets[1])
          if to:isWounded() then
            room:recover{  who = to, num = 1, recoverBy = player, skillName = self.name }
          end
          if not to.dead then
            to:drawCards(3, self.name)
          end
        end
      end
    elseif event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "negative")
      room:moveCards({
        from = player.id,
        ids = player:getPile("mobile__biaozhao_message"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
      })
      if not player.dead then
        room:loseHp(player, 1, self.name)
      end
    end
  end,
}
xugong:addSkill(mobile__biaozhao)
xugong:addSkill("yechou")
Fk:loadTranslationTable{
  ["mobile__xugong"] = "许贡",
  ["#mobile__xugong"] = "独计击流",
  ["mobile__biaozhao"] = "表召",
  [":mobile__biaozhao"] = "结束阶段，你可以将一张牌扣置于武将牌上，称为“表”。当一张与“表”点数相同的牌进入弃牌堆时，你移去“表”并失去1点体力。准备阶段，你移去“表”，然后令一名角色回复1点体力并摸三张牌。",
  ["mobile__biaozhao_message"] = "表",
  ["#mobile__biaozhao-cost"] = "表召：可以将一张牌作为表置于武将牌上",
  ["#mobile__biaozhao-choose"] = "表召：令一名角色回复1点体力并摸三张牌",

  ["$mobile__biaozhao1"] = "孙策如秦末之项籍，如得时势，必有异志！",
  ["$mobile__biaozhao2"] = "贡谨奉此表，以使君明孙策之异！",
  ["$yechou_mobile__xugong1"] = "孙策小儿，你必还恶报！",
  ["$yechou_mobile__xugong2"] = "吾命丧黄泉，你也休想得安!",
  ["~mobile__xugong"] = "此表非我所写，岂可污我！",
}

local baosanniang = General(extension, "mobile__baosanniang", "shu", 3, 3, General.Female)
local shuyong = fk.CreateTriggerSkill{
  name = "shuyong",
  anim_type = "control",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
    table.find(player.room:getOtherPlayers(player), function(p) return not p:isAllNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isAllNude() end), Util.IdMapper), 1, 1, "#shuyong-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, player, target, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local id = room:askForCardChosen(player, to, "hej", self.name)
    room:obtainCard(player.id, id, false, fk.ReasonPrey)
    if not to.dead then
      to:drawCards(1, self.name)
    end
  end,
}
baosanniang:addSkill(shuyong)
local mobile__xushen = fk.CreateActiveSkill{
  name = "mobile__xushen",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player.hp > 0
    and table.find(Fk:currentRoom().alive_players, function(p) return U.isMale(p) end)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if U.isMale(p) then
        n = n + 1
      end
    end
    room:loseHp(player, n, self.name)
  end,
}
local mobile__xushen_delay = fk.CreateTriggerSkill{
  name = "#mobile__xushen_delay",
  mute = true,
  events = {fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead then
      local who = data.extra_data and data.extra_data.mobile__xushen
      if who then
        self.cost_data = who
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if room:askForSkillInvoke(player, "mobile__xushen", nil, "#mobile__xushen-invoke:"..to.id) then
      room:handleAddLoseSkills(to, "wusheng|dangxian", nil)
    end
  end,

  refresh_events = {fk.HpChanged},
  can_refresh = function (self, event, target, player, data)
    return player == target and player.hp > 0 and data.num > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local recover_event = room.logic:getCurrentEvent():findParent(GameEvent.Recover)
    if recover_event then
      local dat = recover_event.data[1]
      if dat.recoverBy then
        local hpchange_event = room.logic:getCurrentEvent():findParent(GameEvent.ChangeHp, false)
        local skillName = hpchange_event and hpchange_event.data[4]
        if skillName and skillName == "mobile__xushen" then
          local dying_event = room.logic:getCurrentEvent():findParent(GameEvent.Dying)
          if dying_event then
            local dying = dying_event.data[1]
            dying.extra_data = dying.extra_data or {}
            dying.extra_data.mobile__xushen = dat.recoverBy.id
          end
        end
      end
    end
  end,
}
mobile__xushen:addRelatedSkill(mobile__xushen_delay)
baosanniang:addSkill(mobile__xushen)
local mobile__zhennan = fk.CreateTriggerSkill{
  name = "mobile__zhennan",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    local from = player.room:getPlayerById(data.from)
    return player:hasSkill(self) and not player:isNude() and data.firstTarget and data.tos and #AimGroup:getAllTargets(data.tos) > 1
    and not from.dead and table.contains(AimGroup:getAllTargets(data.tos), player.id) and #AimGroup:getAllTargets(data.tos) > from.hp
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#mobile__zhennan-discard:"..data.from, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = player.room:getPlayerById(data.from)
    room:throwCard(self.cost_data, self.name, player, player)
    room:damage{
      from = player,
      to = from,
      damage = 1,
      skillName = self.name,
    }
  end,
}
baosanniang:addSkill(mobile__zhennan)
baosanniang:addRelatedSkill("wusheng")
baosanniang:addRelatedSkill("dangxian")
Fk:loadTranslationTable{
  ["mobile__baosanniang"] = "鲍三娘",
  ["#mobile__baosanniang"] = "慕花之姝",
  ["illustrator:mobile__baosanniang"] = "迷走之音", -- 皮肤 嫣然一笑
  ["shuyong"] = "姝勇",
  [":shuyong"] = "当你使用或打出【杀】时，你可以获得一名其他角色区域内的一张牌；若如此做，其摸一张牌。",
  ["mobile__xushen"] = "许身",
  [":mobile__xushen"] = "限定技，出牌阶段，你可以失去等同于场上存活男性角色数的体力值；若你因此进入濒死状态，则你脱离濒死状态后，你可以令使你脱离濒死的角色获得〖武圣〗和〖当先〗。",
  ["mobile__zhennan"] = "镇南",
  [":mobile__zhennan"] = "当一张牌指定多个目标后，若你为此牌目标之一且此牌指定目标数大于使用者当前体力值，则你可以弃置一张牌，对此牌使用者造成1点伤害。",
  ["#shuyong-choose"] = "武娘：你可以获得一名其他角色区域内一张牌，其摸一张牌",
  ["#mobile__zhennan-discard"] = "镇南：你可以弃置一张牌，对 %src 造成1点伤害",
  ["#mobile__xushen_delay"] = "许身",
  ["#mobile__xushen-invoke"] = "许身：你可以令 %src 获得〖武圣〗和〖当先〗",
  
  ["$shuyong1"] = "我的武艺，可是关将军亲传哦！",
  ["$shuyong2"] = "让你看看这招如何！",
  ["$mobile__xushen1"] = "你我相遇于此，应当彼此珍惜。",
  ["$mobile__xushen2"] = "携子之手，与子共闯天涯。",
  ["$mobile__zhennan1"] = "怎可让你再兴风作浪？",
  ["$mobile__zhennan2"] = "南中由我和夫君一起守护！",
  ["~mobile__baosanniang"] = "夫君，来世还愿与你相伴……",
}

--SP10：丁原 傅肜 邓芝 陈登 张翼 公孙康 周群
local dingyuan = General(extension, "dingyuan", "qun", 4)
local beizhu = fk.CreateActiveSkill{
  name = "beizhu",
  mute = true,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:notifySkillInvoked(player, self.name, "control")
    player:broadcastSkillInvoke(self.name, 1)
    local ids = table.filter(target:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == "slash" end)
    if #ids > 0 then
      room:askForCardsChosen(player, target, 0, 0, { card_data = { { "WatchHand", target:getCardIds("h") } } }, self.name)
      player:broadcastSkillInvoke(self.name, 3)
      room:setPlayerMark(player, "beizhu_slash", ids)
      for _, id in ipairs(ids) do
        local card = Fk:getCardById(id)
        if room:getCardOwner(id) == target and room:getCardArea(id) == Card.PlayerHand and card.trueName == "slash" and
          not player.dead and not target:isProhibited(player, card) then
          room:useCard({
            from = target.id,
            tos = {{player.id}},
            card = card,
          })
        end
      end
    else
      local card_data = {}
      table.insert(card_data, { "$Hand", target:getCardIds("h") })
      if #target:getCardIds("e") > 0 then
        table.insert(card_data, { "$Equip", target:getCardIds("e") })
      end
      local throw = room:askForCardChosen(player, target, { card_data = card_data }, self.name)
      room:throwCard({throw}, self.name, target, player)
      player:broadcastSkillInvoke(self.name, 2)
      local slash = room:getCardsFromPileByRule("slash")
      if #slash > 0 and not target.dead and not player.dead and room:askForSkillInvoke(player, self.name, nil, "#beizhu-draw:"..target.id) then
        room:obtainCard(target, slash[1], true, fk.ReasonDraw)
      end
    end
  end,
}
local beizhu_trigger = fk.CreateTriggerSkill{
  name = "#beizhu_trigger",
  mute = true,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("beizhu") and data.card and
      type(player:getMark("beizhu_slash")) == "table" and table.contains(player:getMark("beizhu_slash"), data.card:getEffectiveId())
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, _, player, data)
    player:drawCards(1, "beizhu")
  end,
}
beizhu:addRelatedSkill(beizhu_trigger)
dingyuan:addSkill(beizhu)
Fk:loadTranslationTable{
  ["dingyuan"] = "丁原",
  ["#dingyuan"] = "饲虎成患",
  ["beizhu"] = "备诛",
  [":beizhu"] = "出牌阶段限一次，你可以观看一名其他角色的手牌。若其中有【杀】，则其对你依次使用这些【杀】（当你受到因此使用的【杀】造成的伤害后，"..
  "你摸一张牌），否则你弃置其一张牌并可以令其从牌堆中获得一张【杀】。",
  ["WatchHand"] = "观看手牌",
  ["#beizhu-draw"] = "备诛：你可令 %src 从牌堆中获得一张【杀】",

  ["$beizhu1"] = "检阅士卒，备将行之役。",
  ["$beizhu2"] = "点选将校，讨乱汉之贼。",
  ["$beizhu3"] = "乱贼势大，且暂勿力战。",
  ["~dingyuan"] = "奉先何故心变，啊！",
}

local furong = General(extension, "mobile__furong", "shu", 4)
local mobile__xuewei = fk.CreateTriggerSkill{
  name = "mobile__xuewei",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
      return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      "#mobile__xuewei-choose", self.name, true, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, self.cost_data)
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
  end,
}
local mobile__xuewei_trigger = fk.CreateTriggerSkill{
  name = "#mobile__xuewei_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("mobile__xuewei") == target.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("mobile__xuewei")
    room:notifySkillInvoked(player, "mobile__xuewei", "defensive")
    room:setPlayerMark(player, "mobile__xuewei", 0)
    room:damage{
      from = data.from or nil,
      to = player,
      damage = data.damage,
      skillName = "mobile__xuewei",
    }
    if data.from and not data.from.dead then
      room:damage{
        from = player,
        to = data.from,
        damage = data.damage,
        damageType = data.damageType,
        skillName = "mobile__xuewei",
      }
    end
    return true
  end,
}
local mobile__liechi = fk.CreateTriggerSkill{
  name = "mobile__liechi",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.damage and data.damage.from and not data.damage.from.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.damage.from.id})
    room:askForDiscard(data.damage.from, 1, 1, true, self.name, false)
  end,
}
mobile__xuewei:addRelatedSkill(mobile__xuewei_trigger)
furong:addSkill(mobile__xuewei)
furong:addSkill(mobile__liechi)
Fk:loadTranslationTable{
  ["mobile__furong"] = "傅肜",
  ["#mobile__furong"] = "危汉烈义",
  ["illustrator:mobile__furong"] = "三道纹",
  ["mobile__xuewei"] = "血卫",
  [":mobile__xuewei"] = "准备阶段，你可以标记一名其他角色。若如此做，直到你下回合开始前，你标记的角色第一次受到伤害时，你防止此伤害并受到等量伤害，"..
  "然后你对伤害来源造成等量的同属性伤害。",
  ["mobile__liechi"] = "烈斥",
  [":mobile__liechi"] = "锁定技，当你进入濒死状态时，伤害来源弃置一张牌。",
  ["#mobile__xuewei-choose"] = "血卫：秘密选择一名角色，防止其下次受到的伤害，你受到等量伤害，并对伤害来源造成伤害",

  ["$mobile__xuewei1"] = "老夫一息尚存，吴狗便动不得主公分毫！",
  ["$mobile__xuewei2"] = "吴狗何在，大汉将军傅肜在此！",
  ["$mobile__liechi1"] = "自古唯有战死之将，无屈膝之人！",
  ["$mobile__liechi2"] = "征吴之役，某不欲求生而愿效死！",
  ["~mobile__furong"] = "此战有死而已，何须多言。",
}

local mobile__dengzhi = General(extension, "mobile__dengzhi", "shu", 3)
local mobile__jimeng = fk.CreateTriggerSkill{
  name = "mobile__jimeng",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function (p) return not p:isNude() end)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
        "#mobile__jimeng-choose:::"..player.hp, self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local id = room:askForCardChosen(player, to, "he", self.name)
    room:obtainCard(player, id, false, fk.ReasonPrey)

    if player.dead or player:isNude() or player.hp < 1 then return false end
    local cards = room:askForCard(player, player.hp, player.hp, true, self.name, false, ".", "#mobile__jimeng-give::" .. to.id..":"..player.hp)
    local dummy = Fk:cloneCard("slash")
    dummy:addSubcards(cards)
    room:obtainCard(to, dummy, false, fk.ReasonGive)
  end,
}
local mobile__shuaiyan = fk.CreateTriggerSkill{
  name = "mobile__shuaiyan",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Discard and
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function (p) return not p:isNude() end)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#mobile__shuaiyan-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:showCards(player:getCardIds(Player.Hand))
    local to = room:getPlayerById(self.cost_data)
    if not player.dead and not to:isNude() then
      local c = room:askForCard(to, 1, 1, true, self.name, false, ".", "#mobile__shuaiyan-give::"..player.id)[1]
      room:moveCardTo(c, Player.Hand, player, fk.ReasonGive, self.name, nil, false)
    end
  end,
}
mobile__dengzhi:addSkill(mobile__jimeng)
mobile__dengzhi:addSkill(mobile__shuaiyan)

Fk:loadTranslationTable{
  ["mobile__dengzhi"] = "邓芝",
  ["mobile__jimeng"] = "急盟",
  [":mobile__jimeng"] = "出牌阶段开始时，你可以获得一名其他角色的一张牌，然后你交给该角色X张牌（X为你的体力值）。",
  ["mobile__shuaiyan"] = "率言",
  [":mobile__shuaiyan"] = "弃牌阶段开始时，若你的手牌数大于1，你可以展示所有手牌，令一名其他角色交给你一张牌。",

  ["#mobile__jimeng-choose"] = "急盟：你可以获得一名其他角色的一张牌，然后交给其 %arg 张牌",
  ["#mobile__jimeng-give"] = "急盟：交给 %dest %arg张牌",
  ["#mobile__shuaiyan-choose"] = "率言：你可展示所有手牌，令一名其他角色交给你一张牌",
  ["#mobile__shuaiyan-give"] = "率言：交给 %dest 一张牌",

  ["$mobile__jimeng1"] = "曹魏已成鲸吞之势，还望连横抗之。",
  ["$mobile__jimeng2"] = "主上幼弱，吾愿往重修吴好。",
  ["$mobile__shuaiyan1"] = "天无二日，士无二主。",
  ["$mobile__shuaiyan2"] = "吾言意欲为吴，非但为蜀也。",
  ["~mobile__dengzhi"] = "一生为国，已然无憾矣。",
}

local chendeng = General(extension, "mobile__chendeng", "qun", 3)
local mobile__zhouxuan = fk.CreateActiveSkill{
  name = "mobile__zhouxuan",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#mobile__zhouxuan",
  interaction = function()
    local names = {"trick", "equip"}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and not card.is_derived then
        table.insertIfNeed(names, card.trueName)
      end
    end
    return UI.ComboBox {choices = names}
  end,
  can_use = function (self, player, card)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function (self, room, effect)
    local player = room:getPlayerById(effect.from)
    local mark = U.getMark(player, "mobile__zhouxuan")
    table.insert(mark, {effect.tos[1], self.interaction.data})
    room:setPlayerMark(player, "mobile__zhouxuan", mark)
    room:throwCard(effect.cards, self.name, player, player)
  end,
}
local mobile__zhouxuan_trigger = fk.CreateTriggerSkill{
  name = "#mobile__zhouxuan_trigger",
  mute = true,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return table.find(U.getMark(player, "mobile__zhouxuan"), function(m) return m[1] == target.id end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "mobile__zhouxuan")
    local can_invoke
    for i = #mark, 1, -1 do
      if mark[i][1] == target.id then
        if mark[i][2] == data.card.trueName or mark[i][2] == data.card:getTypeString() then
          can_invoke = true
        end
        table.remove(mark, i)
      end
    end
    room:setPlayerMark(player, "mobile__zhouxuan", mark)
    if can_invoke then
      player:broadcastSkillInvoke("mobile__zhouxuan")
      room:notifySkillInvoked(player, "mobile__zhouxuan", "drawcard")
      local cards = room:getNCards(3)
      U.askForDistribution(player, cards, nil, self.name, 3, 3, nil, cards)
    end
  end,
}
local mobile__fengji = fk.CreateTriggerSkill{
  name = "mobile__fengji",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local num = player:getMark("@mobile__fengji")
      if num == 0 then num = player:getMark(self.name) end
      return num ~= 0 and player:getHandcardNum() >= tonumber(num)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player  --不判断技能拥有者以适配偷技能的情况
  end,
  on_refresh = function(self, event, target, player, data)
    local num = (player:getHandcardNum() > 0) and player:getHandcardNum() or "0"
    if player:hasSkill(self, true) then
      player.room:setPlayerMark(player, "@mobile__fengji", num)
    else
      player.room:setPlayerMark(player, self.name, num)
    end
  end,
}
local mobile__fengji_maxcards = fk.CreateMaxCardsSkill{
  name = "#mobile__fengji_maxcards",
  frequency = Skill.Compulsory,
  fixed_func = function(self, player)
    if player:usedSkillTimes("mobile__fengji", Player.HistoryTurn) > 0 then
      return player.maxHp
    end
  end
}
mobile__zhouxuan:addRelatedSkill(mobile__zhouxuan_trigger)
mobile__fengji:addRelatedSkill(mobile__fengji_maxcards)
chendeng:addSkill(mobile__zhouxuan)
chendeng:addSkill(mobile__fengji)
Fk:loadTranslationTable{
  ["mobile__chendeng"] = "陈登",
  ["#mobile__chendeng"] = "雄气壮节",
  ["illustrator:mobile__chendeng"] = "小强",

  ["mobile__zhouxuan"] = "周旋",
  [":mobile__zhouxuan"] = "出牌阶段限一次，你可以弃置一张牌，选择一名其他角色并选择一种非基本牌的类型或一种基本牌的牌名。若该角色之后"..
  "使用或打出的第一张牌与你的选择相同，你观看牌堆顶的三张牌，并分配给任意角色。",
  ["mobile__fengji"] = "丰积",
  [":mobile__fengji"] = "锁定技，回合开始时，若你的手牌数不小于你上个回合结束后的数量，你摸两张牌且你本回合手牌上限等于你的体力上限。",
  ["#mobile__zhouxuan"] = "周旋：弃置一张牌，猜测一名角色使用或打出下一张牌的牌名/类别",
  ["#mobile__zhouxuan_trigger"] = "周旋",
  ["#mobile__zhouxuan-give"] = "周旋：你可以将这些牌任意分配，点“取消”自己保留",
  ["@mobile__fengji"]= "丰积",

  ["$mobile__zhouxuan1"] = "孰为虎？孰为鹰？于吾都如棋子。",
  ["$mobile__zhouxuan2"] = "群雄逐鹿之际，唯有洞明时势方有所成。",
  ["$mobile__fengji1"] = "巡土田之宜，尽凿溉之利。",
  ["$mobile__fengji2"] = "养耆育孤，视民如伤，以丰定徐州。",
  ["~mobile__chendeng"] = "诸卿何患无令君乎？",	
}

local zhangyi = General(extension, "mobile__zhangyiy", "shu", 4)
local zhiyi_viewas = fk.CreateViewAsSkill{
  name = "zhiyi_viewas",
  interaction = function()
    local mark = Self:getMark("@$zhiyi-turn")
    if type(mark) ~= "table" then return nil end
    local names = table.filter(mark, function (card_name)
      local to_use = Fk:cloneCard(card_name)
      return Self:canUse(to_use) and not Self:prohibitUse(to_use)
    end)
    if #names > 0 then
      return UI.ComboBox {choices = names, all_choices = mark }
    end
  end,
  card_filter = function() return false end,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "zhiyi"
    return card
  end,
}
Fk:addSkill(zhiyi_viewas)
local zhiyi = fk.CreateTriggerSkill{
  name = "zhiyi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.CardUsing, fk.CardResponding},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardUsing or event == fk.CardResponding then
      if player == target and data.card.type == Card.TypeBasic then
        local mark = player:getMark("@$zhiyi-turn")
        return type(mark) ~= "table" or not table.contains(mark, data.card.name)
      end
    elseif event == fk.EventPhaseStart and target.phase == Player.Finish then
      local mark = player:getMark("@$zhiyi-turn")
      return type(mark) == "table" and #mark > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing or event == fk.CardResponding then
      local mark = player:getMark("@$zhiyi-turn")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, data.card.name)
      room:setPlayerMark(player, "@$zhiyi-turn", mark)
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name)
      player:broadcastSkillInvoke(self.name)
      local mark = player:getMark("@$zhiyi-turn")
      if type(mark) ~= "table" then return false end
      if table.every(mark, function (card_name)
        local to_use = Fk:cloneCard(card_name)
        return not (player:canUse(to_use) and not player:prohibitUse(to_use))
      end) then
        room:drawCards(player, 1, self.name)
        return false
      end
      local success, dat = player.room:askForUseActiveSkill(player, "zhiyi_viewas", "#zhiyi-choose", true)
      if success then
        local card = Fk.skills["zhiyi_viewas"]:viewAs(dat.cards)
        room:useCard{
          from = player.id,
          tos = table.map(dat.targets, function(id) return {id} end),
          card = card,
        }
      else
        room:drawCards(player, 1, self.name)
      end
    end
  end,
}
zhangyi:addSkill(zhiyi)
Fk:loadTranslationTable{
  ["mobile__zhangyiy"] = "张翼",
  ["zhiyi"] = "执义",
  [":zhiyi"] = "锁定技，一名角色的结束阶段，若你本回合使用或打出过基本牌，你选择一项：1.视为使用任意一张你本回合使用或打出过的基本牌；2.摸一张牌。",

  ["@$zhiyi-turn"] = "执义",
  ["#zhiyi-choose"] = "执义：选择视为使用一张基本牌，或点取消则摸一张牌",

  ["$zhiyi1"] = "岂可擅退而误国家之功？",
  ["$zhiyi2"] = "统摄不懈，只为破敌！",
  ["~mobile__zhangyiy"] = "唯愿百姓，不受此乱所害，哎……",
}

local gongsunkang = General(extension, "gongsunkang", "qun", 4)
local juliao = fk.CreateDistanceSkill{
  name = "juliao",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if to:hasSkill(self) then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms - 1
    end
    return 0
  end,
}
local taomie = fk.CreateTriggerSkill{
  name = "taomie",
  anim_type = "offensive",
  events = {fk.Damage, fk.Damaged, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.DamageCaused then
        return data.to:getMark("@@taomie") > 0
      elseif event == fk.Damage then
        return not data.to.dead and data.to:getMark("@@taomie") == 0 and not data.taomie
      elseif event == fk.Damaged then
        return data.from and not data.from.dead and data.from:getMark("@@taomie") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      return true
    else
      local prompt
      if event == fk.Damage then
        prompt = "#taomie-invoke::"..data.to.id
      else
        prompt = "#taomie-invoke::"..data.from.id
      end
      return player.room:askForSkillInvoke(player, self.name, nil, prompt)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      local all_choices = {"taomie_damage", "taomie_prey", "taomie_beishui"}
      local choices = table.clone(all_choices)
      if data.to:isNude() then
        choices = {"taomie_damage"}
      end
      local choice = room:askForChoice(player, choices, self.name, nil, false, all_choices)
      if choice ~= "taomie_prey" then
        data.damage = data.damage + 1
      end
      if choice ~= "taomie_damage" then
        if choice == "taomie_beishui" then
          room:setPlayerMark(data.to, "@@taomie", 0)
          data.taomie = true
        end
        if data.to:isNude() then return end
        room:doIndicate(player.id, {data.to.id})
        local id = room:askForCardChosen(player, data.to, "hej", self.name)
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
        if player.dead then return end
        local targets = table.map(room:getOtherPlayers(data.to), function(p) return p.id end)
        if #targets == 0 or room:getCardOwner(id) ~= player or room:getCardArea(id) ~= Card.PlayerHand then return end
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#taomie-choose:::"..Fk:getCardById(id):toLogString(), self.name, true)
        if #to > 0 then
          to = to[1]
        else
          to = player.id
        end
        if to ~= player.id then
          room:obtainCard(to, id, false, fk.ReasonGive)
        end
      end
    else
      for _, p in ipairs(room.alive_players) do
        room:setPlayerMark(p, "@@taomie", 0)
      end
      if event == fk.Damage then
        room:doIndicate(player.id, {data.to.id})
        room:setPlayerMark(data.to, "@@taomie", 1)
      else
        room:doIndicate(player.id, {data.from.id})
        room:setPlayerMark(data.from, "@@taomie", 1)
      end
    end
  end
}
local taomie_attackrange = fk.CreateAttackRangeSkill{
  name = "#taomie_attackrange",
  main_skill = taomie,
  within_func = function (self, from, to)
    if from:hasSkill("taomie") then
      return to:getMark("@@taomie") > 0
    end
    if to:hasSkill("taomie") then
      return from:getMark("@@taomie") > 0
    end
  end,
}
taomie:addRelatedSkill(taomie_attackrange)
gongsunkang:addSkill(juliao)
gongsunkang:addSkill(taomie)
Fk:loadTranslationTable{
  ["gongsunkang"] = "公孙康",
  ["juliao"] = "据辽",
  [":juliao"] = "锁定技，其他角色计算与你的距离+X（X为场上势力数-1）。",
  ["taomie"] = "讨灭",
  [":taomie"] = "当你受到伤害后或当你造成伤害后，你可以令伤害来源或受伤角色获得“讨灭”标记（如场上已有标记则转移给该角色），"..
  "你和拥有“讨灭”标记的角色互相视为在对方的攻击范围内；当你对有“讨灭”标记的角色造成伤害时，你选择一项：1.令此伤害+1；"..
  "2.你获得其区域里的一张牌并可将此牌交给另一名角色；背水：弃置其“讨灭”标记，本次伤害不令其获得“讨灭”标记。",
  ["#taomie-invoke"] = "讨灭：是否令 %dest 获得“讨灭”标记？",
  ["@@taomie"] = "讨灭",
  ["taomie_damage"] = "此伤害+1",
  ["taomie_prey"] = "获得其区域内一张牌，且可以交给另一名角色",
  ["taomie_beishui"] = "背水：弃置其“讨灭”标记，且本次伤害不令其获得标记",
  ["#taomie-choose"] = "讨灭：你可以将此%arg交给另一名角色",

  ["$taomie1"] = "犯我辽东疆界，必遭后报！",
  ["$taomie2"] = "韩濊之乱，再无可生之机！",
  ["$taomie3"] = "颅且远行万里，要席何用？",
  ["~gongsunkang"] = "枭雄一世，何有所憾！",
}

local zhouqun = General(extension, "zhouqun", "shu", 3)
local tiansuanProhibit = fk.CreateProhibitSkill{
  name = "#tiansuan_prohibit",
  is_prohibited = function() return false end,
  prohibit_use = function(self, player, card)
    return (card.trueName == "peach" or card.trueName == "analeptic")
      and player:getMark("@tiansuan") == "tiansuanC"
  end,
}
local tiansuanTrig = fk.CreateTriggerSkill{
  name = "#tiansuan_trig",
  events = { fk.DamageInflicted, fk.Damaged },
  on_cost = Util.TrueFunc,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return end
    if event == fk.DamageInflicted then
      return player:getMark("@tiansuan") ~= 0
    elseif event == fk.Damaged then
      return player:getMark("@tiansuan") == "tiansuanS"
    end
  end,
  on_use = function(self, event, target, player, data)
    -- local room = player.room
    if event == fk.Damaged then
      player:drawCards(data.damage, "tiansuan")
      return
    end

    local mark = player:getMark("@tiansuan")
    if mark == "tiansuanSSR" then
      return true
    elseif mark == "tiansuanS" then
      if data.damage > 1 then data.damage = 1 end
    elseif mark == "tiansuanA" then
      data.damageType = fk.FireDamage
      if data.damage > 1 then data.damage = 1 end
    elseif mark == "tiansuanB" or mark == "tiansuanC" then
      data.damage = data.damage + 1
    end
  end,

  refresh_events = { fk.TurnStart, fk.Death },
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("tiansuan") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "tiansuan", 0)
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@tiansuan") ~= 0 then
        room:setPlayerMark(p, "@tiansuan", 0)
      end
    end
  end
}
local tiansuan = fk.CreateActiveSkill{
  name = "tiansuan",
  card_filter = Util.FalseFunc,
  interaction = UI.ComboBox {
    choices = { "tiansuanNone", "tiansuanSSR", "tiansuanS", "tiansuanA", "tiansuanB", "tiansuanC" }
  },
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "tiansuan", 1)
    local choices = {
      "SSR", "SSR",
      "S", "S", "S",
      "A", "A", "A", "A",
      "B", "B", "B",
      "C", "C",
    }
    local dat = self.interaction.data
    if dat ~= "tiansuanNone" then
      table.insert(choices, dat:sub(9))
    end
    local result = "tiansuan" .. table.random(choices)
    room:sendLog{type = "#TiansuanResult", from = player.id, arg = result, toast = true}

    local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper),
      1, 1, "#tiansuan-choose:::" .. result, self.name, false)
    local tgt = room:getPlayerById(tos[1])
    room:setPlayerMark(tgt, "@tiansuan", result)

    if tgt == player then return end
    if result == "tiansuanSSR" then
      if tgt:isKongcheng() then return end
      local cids = tgt.player_cards[Player.Hand]
      room:fillAG(player, cids)

      local id = room:askForAG(player, cids, false, self.name)
      room:closeAG(player)

      if not id then return false end
      room:obtainCard(player, id, false)
    elseif result == "tiansuanS" then
      if tgt:isNude() then return end
      local id = room:askForCardChosen(player, tgt, "he", self.name)
      room:obtainCard(player, id, false)
    end
  end,
}
tiansuan:addRelatedSkill(tiansuanProhibit)
tiansuan:addRelatedSkill(tiansuanTrig)
zhouqun:addSkill(tiansuan)

local zhouqun_win = fk.CreateActiveSkill{ name = "zhouqun_win_audio" }
zhouqun_win.package = extension
Fk:addSkill(zhouqun_win)

Fk:loadTranslationTable{
  ['zhouqun'] = '周群',
  ['tiansuan'] = '天算',
  ['#tiansuan_trig'] = '天算',
  [':tiansuan'] = '每轮限一次，出牌阶段，你可以抽取一个“命运签”' ..
    '（在抽签开始前，你可以悄悄作弊，额外放入一个“命运签”增加其抽中的机会）。' ..
    '<br/>然后你选择一名角色，其获得命运签的效果直到你的下回合开始。' ..
    '<br/>若其获得的是“上上签”，你观看其手牌并从其区域内获得一张牌；' ..
    '若其获得的是“上签”，你从其处获得一张牌。' ..
    '<br/>各种“命运签”的效果如下：' ..
    '<br/>上上签：防止受到的伤害。' ..
    '<br/>上签：受到伤害时，若伤害值大于1，则将伤害值改为1；每受到一点伤害后，你摸一张牌。' ..
    '<br/>中签：受到伤害时，将伤害改为火焰伤害，若此伤害值大于1，则将伤害值改为1。' ..
    '<br/>下签：受到伤害时，伤害值+1。' ..
    '<br/>下下签：受到伤害时，伤害值+1；不能使用【桃】和【酒】。 ',
  ['tiansuanNone'] = '我足够会玩了，不需要作弊',
  ['tiansuanSSR'] = '上上签',
  ['tiansuanS'] = '上签',
  ['tiansuanA'] = '中签',
  ['tiansuanB'] = '下签',
  ['tiansuanC'] = '下下签',
  ['#TiansuanResult'] = '%from 天算的抽签结果是 %arg',
  ['@tiansuan'] = '天算',
  ['#tiansuan-choose'] = '天算：抽签结果是 %arg ，请选择一名角色获得签的效果',

  ['$tiansuan1'] = '汝既持签问卜，亦当应天授命。',
  ['$tiansuan2'] = '尔若居正体道，福寿自当天成。',
  ['~zhouqun'] = '及时止损，过犹不及…',
  ['$zhouqun_win_audio'] = '占星问卜，莫不言精！',
}

--SP11：阎圃 马元义 毛玠 傅佥 阮慧 马日磾 王濬
local yanpu = General(extension, "yanpu", "qun", 3)
local huantu = fk.CreateTriggerSkill{
  name = "huantu",
  anim_type = "support",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:inMyAttackRange(target) and data.to == Player.Draw and not player:isNude() and
      player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, true, self.name, true, ".", "#huantu-invoke::"..target.id)
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(Fk:getCardById(self.cost_data), Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
    return true
  end,
}
local huantu_trigger = fk.CreateTriggerSkill{
  name = "#huantu_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:usedSkillTimes("huantu", Player.HistoryTurn) > 0 and
    target.phase == Player.Finish and not target.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    player:broadcastSkillInvoke("huantu")
    room:notifySkillInvoked(player, "huantu")
    local choices = {"huantu1::"..target.id, "huantu2::"..target.id}
    local choice = room:askForChoice(player, choices, "huantu")
    if choice[7] == "1" then
      if target:isWounded() then
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = "huantu"
        })
      end
      if not target.dead then
        target:drawCards(2, "huantu")
      end
    else
      player:drawCards(3, "huantu")
      if not player:isKongcheng() and not target.dead then
        local cards = player:getCardIds(Player.Hand)
        if #cards > 2 then
          cards = room:askForCard(player, 2, 2, false, "huantu", false, ".", "#huantu-give::"..target.id)
        end
        room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, "huantu", nil, false, player.id)
      end
    end
  end,
}
local bihuoy = fk.CreateTriggerSkill{
  name = "bihuoy",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    return target:isAlive() and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#bihuoy-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    target:drawCards(3, self.name)
    room:setPlayerMark(target, "@bihuoy-round", #room.players)
  end,
}
local bihuoy_distance = fk.CreateDistanceSkill{
  name = "#bihuoy_distance",
  correct_func = function(self, from, to)
    return to:getMark("@bihuoy-round")
  end,
}
huantu:addRelatedSkill(huantu_trigger)
bihuoy:addRelatedSkill(bihuoy_distance)
yanpu:addSkill(huantu)
yanpu:addSkill(bihuoy)
Fk:loadTranslationTable{
  ["yanpu"] = "阎圃",
  ["huantu"] = "缓图",
  [":huantu"] = "每轮限一次，你攻击范围内一名其他角色摸牌阶段开始前，你可以交给其一张牌，令其跳过摸牌阶段，若如此做，本回合结束阶段你选择一项："..
  "1.令其回复1点体力并摸两张牌；2.你摸三张牌并交给其两张手牌。",
  ["bihuoy"] = "避祸",
  [":bihuoy"] = "限定技，一名角色脱离濒死状态时，你可以令其摸三张牌，然后除其以外的角色本轮计算与其的距离时+X（X为场上角色数）。",
  ["#huantu-invoke"] = "缓图：你可以交给 %dest 一张牌令其跳过摸牌阶段，本回合结束阶段其摸牌",
  ["huantu1"] = "%dest回复1点体力并摸两张牌",
  ["huantu2"] = "你摸三张牌，然后交给%dest两张手牌",
  ["#huantu-give"] = "缓图：交给 %dest 两张手牌",
  ["#bihuoy-invoke"] = "避祸：你可以令 %dest 摸三张牌且本轮所有角色至其距离增加",
  ["@bihuoy-round"] = "避祸",

  ["$huantu1"] = "今群雄蜂起，主公宜外收内敛，勿为祸先。",
  ["$huantu2"] = "昔陈胜之事，足为今日之师，望主公熟虑。",
  ["$bihuoy1"] = "公以败兵之身投之，功轻且恐难保身也。",
  ["$bihuoy2"] = "公不若附之他人与相拒，然后委质，功必多。",
  ["~yanpu"] = "公皆听吾计，圃岂敢不专……",
}

local mayuanyi = General(extension, "mayuanyi", "qun", 4)
local jibing = fk.CreateViewAsSkill{
  name = "jibing",
  pattern = "slash,jink",
  expand_pile = "mayuanyi_bing",
  derived_piles = "mayuanyi_bing",
  prompt = "#jibing",
  interaction = function()
    local names = {}
    if Fk.currentResponsePattern == nil and Self:canUse(Fk:cloneCard("slash")) then
      table.insertIfNeed(names, "slash")
    else
      for _, name in ipairs({"slash", "jink"}) do
        if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name)) then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "mayuanyi_bing"
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
}
local jibing_trigger = fk.CreateTriggerSkill{
  name = "#jibing_trigger",
  main_skill = jibing,
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Draw then
      local kingdoms = {}
      for _, p in ipairs(player.room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #player:getPile("mayuanyi_bing") < #kingdoms
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "jibing", nil, "#jibing-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("jibing")
    player.room:notifySkillInvoked(player, "jibing", "special")
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player.room:getNCards(2))
    player:addToPile("mayuanyi_bing", dummy, false, "jibing")
    return true
  end,
}
local wangjingm = fk.CreateTriggerSkill{
  name = "wangjingm",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and
      table.find(data.card.skillNames, function(name) return string.find(name, "jibing") end) then
      local id
      if event == fk.CardUsing then
        if data.card.trueName == "slash" then
          id = data.tos[1][1]
        elseif data.card.name == "jink" then
          if data.responseToEvent then
            id = data.responseToEvent.from  --jink
          end
        end
      elseif event == fk.CardResponding then
        if data.responseToEvent then
          if data.responseToEvent.from == player.id then
            id = data.responseToEvent.to  --duel used by self
          else
            id = data.responseToEvent.from  --savsavage_assault, archery_attack, passive duel
          end
        end
      end
      if id ~= nil then
        local to = player.room:getPlayerById(id)
        return table.every(player.room.alive_players, function(p) return to.hp >= p.hp end)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local moucuan = fk.CreateTriggerSkill{
  name = "moucuan",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    return #player:getPile("mayuanyi_bing") >= #kingdoms
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead then
      room:handleAddLoseSkills(player, "binghuo", nil, true, false)
    end
  end,
}
local binghuo = fk.CreateTriggerSkill{
  name = "binghuo",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Finish then
      if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        return use.from == player.id and table.contains(use.card.skillNames, "jibing")
      end, Player.HistoryTurn) > 0 then
        return true
      end
      if #player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e) 
        local use = e.data[1]
        return use.from == player.id and table.contains(use.card.skillNames, "jibing")
      end, Player.HistoryTurn) > 0 then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, function(p)
      return p.id end), 1, 1, "#binghuo-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local judge = {
      who = to,
      reason = self.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge.card.color == Card.Black and not to.dead then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    end
  end,
}
jibing:addRelatedSkill(jibing_trigger)
mayuanyi:addSkill(jibing)
mayuanyi:addSkill(wangjingm)
mayuanyi:addSkill(moucuan)
mayuanyi:addRelatedSkill(binghuo)
Fk:loadTranslationTable{
  ["mayuanyi"] = "马元义",
  ["#mayuanyi"] = "黄天擎炬",
  ["illustrator:mayuanyi"] = "丸点科技",

  ["jibing"] = "集兵",
  [":jibing"] = "摸牌阶段开始时，若你的“兵”数少于X（X为场上势力数），你可以放弃摸牌，改为将牌堆顶两张牌置于你的武将牌上，称为“兵”。"..
  "你可以将一张“兵”当做普通【杀】或【闪】使用或打出。",
  ["wangjingm"] = "往京",
  [":wangjingm"] = "锁定技，当你发动〖集兵〗使用或打出一张“兵”时，若对方是场上体力值最高的角色，你摸一张牌。",
  ["moucuan"] = "谋篡",
  [":moucuan"] = "觉醒技，准备阶段，若你的“兵”数不少于X张（X为场上势力数），你减少1点体力值上限，然后获得技能〖兵祸〗。",
  ["binghuo"] = "兵祸",
  [":binghuo"] = "一名角色结束阶段，若你本回合发动〖集兵〗使用或打出过“兵”，你可以令一名角色判定，若结果为黑色，你对其造成1点雷电伤害。",
  ["#jibing"] = "集兵：你可以将一张“兵”当【杀】或【闪】使用或打出",
  ["#jibing-invoke"] = "集兵：是否放弃摸牌，改为获得两张“兵”？",
  ["mayuanyi_bing"] = "兵",
  ["#binghuo-choose"] = "兵祸：令一名角色判定，若为黑色，你对其造成1点雷电伤害",

  ["$jibing1"] = "集荆、扬精兵，而后共举大义！",
  ["$jibing2"] = "教众快快集合，不可误了大事！",
  ["$wangjingm1"] = "联络朝中中常侍，共抗朝廷不义师！",
  ["$wangjingm2"] = "往来京城，与众常侍密谋举事！",
  ["$moucuan1"] = "汉失民心，天赐良机！",
  ["$moucuan2"] = "天下正主，正是大贤良师！",
  ["$binghuo1"] = "黄巾既起，必灭不义之师！",
  ["$binghuo2"] = "诛官杀吏，尽诛朝廷爪牙！",
  ["~mayuanyi"] = "唐周……无耻！",
}

local maojie = General(extension, "maojie", "wei", 3)
local bingqing = fk.CreateTriggerSkill{
  name = "bingqing",
  events = {fk.CardUseFinished},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return 
      target == player and
      player:hasSkill(self) and
      player.phase == Player.Play and
      (data.extra_data or {}).firstCardSuitUseFinished and
      type(player:getMark("@bingqing-phase")) == "table" and
      #player:getMark("@bingqing-phase") > 1 and
      #player:getMark("@bingqing-phase") < 5
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local suitsNum = #player:getMark("@bingqing-phase")
    local targets = {}
    local prompt = "#bingqing-draw"
    if suitsNum == 2 then
      targets = room.alive_players
    elseif suitsNum == 3 then
      targets = table.filter(room.alive_players, function(p)
        if p == player and not table.find(player:getCardIds({ Player.Hand, Player.Equip, Player.Judge }), function(id)
          return not player:prohibitDiscard(Fk:getCardById(id))
        end) then
          return false
        end
        return not p:isAllNude()
      end)
      prompt = "#bingqing-discard"
    else
      targets = room:getOtherPlayers(player, false)
      prompt = "#bingqing-damage"
    end
    if #targets == 0 then return end
    targets = table.map(targets, function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suitsNum = #player:getMark("@bingqing-phase")
    local to = room:getPlayerById(self.cost_data)
    if suitsNum == 2 then
      to:drawCards(2, self.name)
    elseif suitsNum == 3 then
      local cardId = room:askForCardChosen(player, to, "hej", self.name)
      room:throwCard({ cardId }, self.name, to, player)
    else
      room:damage({
        from = player,
        to = to,
        damage = 1,
        damageType = fk.NormalDamage,
        skillName = self.name,
      })
    end
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self, true) and target == player and
      player.phase == Player.Play and
      data.card.suit ~= Card.NoSuit and
      (type(player:getMark("@bingqing-phase")) ~= "table" or
      not table.contains(player:getMark("@bingqing-phase"), "log_" .. data.card:getSuitString()))
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local typesRecorded = type(player:getMark("@bingqing-phase")) == "table" and player:getMark("@bingqing-phase") or {}
    table.insert(typesRecorded, "log_" .. data.card:getSuitString())
    room:setPlayerMark(player, "@bingqing-phase", typesRecorded)

    data.extra_data = data.extra_data or {}
    data.extra_data.firstCardSuitUseFinished = true
  end,
}
maojie:addSkill(bingqing)
Fk:loadTranslationTable{
  ["maojie"] = "毛玠",
  ["#maojie"] = "清公素履",
  ["cv:maojie"] = "刘强",
  ["bingqing"] = "秉清",
  [":bingqing"] = "当你于出牌阶段内使用牌结算结束后，若此牌的花色与你于此阶段内使用并结算结束的牌花色均不相同，则你记录此牌花色直到此阶段结束，"..
  "然后你根据记录的花色数，你可以执行对应效果：<br>两种，令一名角色摸两张牌；<br>三种，弃置一名角色区域内的一张牌；<br>四种，对一名角色造成1点伤害。",
  ["@bingqing-phase"] = "秉清",
  ["#bingqing-draw"] = "秉清：你可以令一名角色摸两张牌",
  ["#bingqing-discard"] = "秉清：你可以弃置一名角色区域里的一张牌",
  ["#bingqing-damage"] = "秉清：你可以对一名其他角色造成1点伤害",

  ["$bingqing1"] = "常怀圣言，以是自励。",
  ["$bingqing2"] = "身受贵宠，不忘初心。",
  ["~maojie"] = "废立大事，公不可不慎……",
}

local fuqian = General(extension, "fuqian", "shu", 4)
local poxiang = fk.CreateActiveSkill{
  name = "poxiang",
  anim_type = "drawcard",
  prompt = "#poxiang-active",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and to_select ~= Self.id and #cards > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:moveCardTo(effect.cards, Card.PlayerHand, room:getPlayerById(effect.tos[1]), fk.ReasonGive, self.name, "", false, player.id)
    if player.dead then return end
    player:drawCards(3, self.name)
    local pile = player:getPile("jueyong_desperation")
    if #pile > 0 then
      room:moveCards({
        from = player.id,
        ids = pile,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
      })
    end
    if player.dead then return end
    room:loseHp(player, 1, self.name)
  end
}
local poxiang_refresh = fk.CreateTriggerSkill{
  name = "#poxiang_refresh",

  refresh_events = {fk.AfterCardsMove, fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == "poxiang" and move.moveReason == fk.ReasonDraw then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player.player_cards[Player.Hand], info.cardId) then
              room:setCardMark(Fk:getCardById(info.cardId), "@@poxiang-inhand", 1)
            end
          end
        end
      end
    else
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        room:setCardMark(Fk:getCardById(id), "@@poxiang-inhand", 0)
      end
    end
  end,
}
local poxiang_maxcards = fk.CreateMaxCardsSkill{
  name = "#poxiang_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@poxiang-inhand") > 0
  end,
}
local jueyong = fk.CreateTriggerSkill{
  name = "jueyong",
  anim_type = "defensive",
  events = {fk.TargetConfirming, fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  derived_piles = "jueyong_desperation",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player ~= target then return false end
    if event == fk.TargetConfirming then
      return data.card.trueName ~= "peach" and data.card.trueName ~= "analeptic" and
      not (data.extra_data and data.extra_data.useByJueyong) and U.isPureCard(data.card) and
      U.isOnlyTarget(player, data, event) and #player:getPile("jueyong_desperation") < player.hp
    elseif event == fk.EventPhaseStart then
      return player.phase == Player.Finish and #player:getPile("jueyong_desperation") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirming then
      data.tos = AimGroup:initAimGroup({})
      data.targetGroup = {}
      if room:getCardArea(data.card) ~= Card.Processing then return true end
      player:addToPile("jueyong_desperation", data.card, true, self.name)
      if table.contains(player:getPile("jueyong_desperation"), data.card.id) then
        local mark = player:getMark(self.name)
        if type(mark) ~= "table" then mark = {} end
        table.insert(mark, {data.card.id, data.from})
        room:setPlayerMark(player, self.name, mark)
      end
      return true
    elseif event == fk.EventPhaseStart then
      while #player:getPile("jueyong_desperation") > 0 do
        local id = player:getPile("jueyong_desperation")[1]
        local jy_remove = true
        local card = Fk:getCardById(id)
        local mark = player:getMark(self.name)
        if type(mark) == "table" then
          local pid
          for _, jy_record in ipairs(mark) do
            if #jy_record == 2 and jy_record[1] == id then
              pid = jy_record[2]
              break
            end
          end
          if pid ~= nil then
            local from = room:getPlayerById(pid)
            if from ~= nil and not from.dead then
              if from:canUse(card) and not from:prohibitUse(card) and not from:isProhibited(player, card) and
                  (card.skill:modTargetFilter(player.id, {}, pid, card, false)) then
                local tos = {{player.id}}
                if card.skill:getMinTargetNum() == 2 then
                  local targets = table.filter(room.alive_players, function (p)
                    return card.skill:targetFilter(p.id, {player.id}, {}, card)
                  end)
                  if #targets > 0 then
                    local to_slash = room:askForChoosePlayers(from, table.map(targets, function (p)
                      return p.id
                    end), 1, 1, "#jueyong-choose::"..player.id..":"..card:toLogString(), self.name, false)
                    if #to_slash > 0 then
                      table.insert(tos, to_slash)
                    end
                  end
                end

                if #tos >= card.skill:getMinTargetNum() then
                  jy_remove = false
                  room:useCard({
                    from = pid,
                    tos = tos,
                    card = card,
                    extra_data = {useByJueyong = true}
                  })
                end
              end
            end
          end
        end
        if jy_remove then
          room:moveCards({
            from = player.id,
            ids = {id},
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPutIntoDiscardPile,
            skillName = self.name,
          })
        end
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return type(player:getMark(self.name)) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local pile = player:getPile("jueyong_desperation")
    if #pile == 0 then
      room:setPlayerMark(player, self.name, 0)
      return false
    end
    local mark = player:getMark(self.name)
    local to_record = {}
    for _, jy_record in ipairs(mark) do
      if #jy_record == 2 and table.contains(pile, jy_record[1]) then
        table.insert(to_record, jy_record)
      end
    end
    room:setPlayerMark(player, self.name, to_record)
  end,
}
poxiang:addRelatedSkill(poxiang_refresh)
poxiang:addRelatedSkill(poxiang_maxcards)
fuqian:addSkill(poxiang)
fuqian:addSkill(jueyong)
Fk:loadTranslationTable{
  ["fuqian"] = "傅佥",
  ["#fuqian"] = "危汉绝勇",
  ["illustrator:fuqian"] = "君桓文化",
  
  ["poxiang"] = "破降",
  [":poxiang"] = "出牌阶段限一次，你可以交给一名其他角色一张牌，然后你摸三张牌，移去所有“绝”并失去1点体力，你以此法获得的牌本回合不计入手牌上限。",
  ["jueyong"] = "绝勇",
  [":jueyong"] = "锁定技，当你成为一张非因〖绝勇〗使用的、非转化且非虚拟的牌（【桃】和【酒】除外）指定的目标时，若你是此牌的唯一目标，"..
  "且此时“绝”的数量小于你的体力值，你取消之。然后将此牌置于你的武将牌上，称为“绝”。结束阶段，若你有“绝”，则按照置入顺序从前到后依次结算“绝”，"..
  "令其原使用者对你使用（若此牌使用者不在场，则将此牌置入弃牌堆）。",
  ["#poxiang-active"] = "发动破降，选择一张牌交给一名角色，然后摸三张牌，移去所有绝并失去1点体力",
  ["@@poxiang-inhand"] = "破降",
  ["jueyong_desperation"] = "绝",
  ["#jueyong-choose"] = "绝勇：选择对%dest使用的%arg的副目标",

  ["$poxiang1"] = "王瓘既然假降，吾等可将计就计。",
  ["$poxiang2"] = "佥率已降两千魏兵，便可大破魏军主力。",
  ["$jueyong1"] = "敌围何惧，有死而已！",
  ["$jueyong2"] = "身陷敌阵，战而弥勇！",
  ["~fuqian"] = "生为蜀臣，死……亦当为蜀！",
}

local ruanhui = General(extension, "ruanhui", "wei", 3, 3, General.Female)
local mingcha = fk.CreateTriggerSkill{
  name = "mingcha",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    room:delay(2000)
    local _, choice = U.askforChooseCardsAndChoice(player, cards, {"OK"}, self.name, "#mingcha-get", {"Cancel"}, 0, 0, cards)
    if choice == "OK" then
      local dummy = Fk:cloneCard("slash")
      for i = 3, 1, -1 do
        if Fk:getCardById(cards[i]).number < 9 then
          dummy:addSubcard(cards[i])
          table.remove(cards, i)
        end
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
      end
      if not player.dead then
        local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end), Util.IdMapper)
        if #targets > 0 then
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#mingcha-choose", self.name, true)
          if #to > 0 then
            to = room:getPlayerById(to[1])
            room:obtainCard(player, table.random(to:getCardIds("he")), false, fk.ReasonPrey)
          end
        end
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        fromArea = Card.Processing,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
    end
    if choice == "OK" then
      return true
    end
  end,
}
local jingzhong = fk.CreateTriggerSkill{
  name = "jingzhong",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Discard then
      local n = 0
      local logic = player.room.logic
      logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).color == Card.Black then
                n = n + 1
              end
            end
          end
        end
      end, Player.HistoryPhase)
      return n > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper),
      1, 1, "#jingzhong-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local mark = to:getMark("@@jingzhong")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, player.id)
    room:setPlayerMark(to, "@@jingzhong", mark)
  end,
}
local jingzhong_trigger = fk.CreateTriggerSkill{
  name = "#jingzhong_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play and player:getMark("@@jingzhong") ~= 0 then
      local card = data.card:isVirtual() and data.card.subcards or {data.card.id}
      return #card > 0 and table.every(card, function(id) return player.room:getCardArea(id) == Card.Processing end)
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@@jingzhong")
    local src = 0
    for i = #mark, 1, -1 do
      local p = room:getPlayerById(mark[i])
      if p.dead or player:getMark("jingzhong_count"..p.id.."-turn") > 2 then
        table.remove(mark, i)
      else
        src = p.id
        break
      end
    end
    if #mark == 0 then mark = 0 end
    room:setPlayerMark(player, "@@jingzhong", mark)
    if src ~= 0 then
      self:doCost(event, target, player, {src, data.card})
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local src = room:getPlayerById(data[1])
    room:addPlayerMark(player, "jingzhong_count"..src.id.."-turn", 1)
    src:broadcastSkillInvoke("jingzhong")
    room:notifySkillInvoked(src, "jingzhong", "drawcard")
    room:obtainCard(src.id, data[2], true, fk.ReasonJustMove)
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@jingzhong") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@jingzhong", 0)
  end,
}
jingzhong:addRelatedSkill(jingzhong_trigger)
ruanhui:addSkill(mingcha)
ruanhui:addSkill(jingzhong)
Fk:loadTranslationTable{
  ["ruanhui"] = "阮慧",
  ["#ruanhui"] = "明察福祸",
  ["mingcha"] = "明察",
  [":mingcha"] = "摸牌阶段开始时，你亮出牌堆顶三张牌，然后你可以放弃摸牌并获得其中点数不大于8的牌，若如此做，你可以选择一名其他角色，随机获得其一张牌。",
  ["jingzhong"] = "敬重",
  [":jingzhong"] = "弃牌阶段结束时，若你本阶段弃置过至少两张黑色牌，你可以选择一名其他角色；其下回合出牌阶段限三次，当其使用牌结算后，你获得之。",
  ["#mingcha-get"] = "明察：是否放弃摸牌，获得其中点数不大于8的牌？",
  ["#mingcha-choose"] = "明察：你可以选择一名角色，随机获得其一张牌",
  ["#jingzhong-choose"] = "敬重：你可以选择一名角色，获得其下回合出牌阶段使用的前三张牌",
  ["@@jingzhong"] = "敬重",

  ["$mingcha1"] = "明主可以理夺，怎可以情求之？",
  ["$mingcha2"] = "祸见于此，何免之有？",
  ["$jingzhong1"] = "妾所乏为容，试问君有几德？",
  ["$jingzhong2"] = "君好色轻德，何谓百德皆备？",
  ["~ruanhui"] = "贱妾茕茕守空房，忧来思君不敢忘……",
}

local mobile__mamidi = General(extension, "mobile__mamidi", "qun", 3)
local getClassicsType = function (cardId)
  local card = Fk:getCardById(cardId,true)
  if card.type == Card.TypeBasic then
    return "cy_classic_basic"
  elseif card.type == Card.TypeEquip then
    return "cy_classic_equip"
  elseif card.name == "nullification" or card.name == "ex_nihilo" or card.name == "indulgence" then
    return "cy_classic_"..card.name
  elseif card.is_damage_card then
    return "cy_classic_damage"
  end
  return ""
end
local getLackClassics = function (player)
  local classic = {"cy_classic_basic","cy_classic_equip","cy_classic_damage","cy_classic_nullification","cy_classic_ex_nihilo","cy_classic_indulgence"}
  for _, id in ipairs(player:getPile("chengye_classic")) do
    local c = getClassicsType(id)
    table.removeOne(classic, c)
  end
  return classic
end
local chengye = fk.CreateTriggerSkill{
  name = "chengye",
  events = {fk.CardUseFinished , fk.AfterCardsMove, fk.EventPhaseStart},
  mute = true,
  derived_piles = "chengye_classic",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      if player:hasSkill(self) and target ~= player and not data.card:isVirtual() then
        local id = data.card:getEffectiveId()
        if player.room:getCardArea(id) == Card.Processing and table.contains(getLackClassics(player), getClassicsType(id)) then
          self.cost_data = {id}
          return true
        end
      end
    elseif event == fk.AfterCardsMove then
      if player:hasSkill(self) then
        local ids = {}
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile and move.from ~= player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerJudge then
                if player.room:getCardArea(info.cardId) == Card.DiscardPile and table.contains(getLackClassics(player), getClassicsType(info.cardId))then
                  table.insertIfNeed(ids, info.cardId)
                end
              end
            end
          end
        end
        if #ids > 0 then
          self.cost_data = ids
          return true
        end
      end
    elseif event == fk.EventPhaseStart then
      return player:hasSkill(self) and target == player and player.phase == Player.Play and #player:getPile("chengye_classic") == 6
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "drawcard")
    if event == fk.EventPhaseStart then
      player:broadcastSkillInvoke(self.name, 3)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(player:getPile("chengye_classic"))
      room:obtainCard(player, dummy, true, fk.ReasonPrey)
    else
      player:broadcastSkillInvoke(self.name, math.random(2))
      local ids = {}
      local moves = {}
      local moveMap = {}
      for _, id in ipairs(self.cost_data) do
        local ctype = getClassicsType(id)
        moveMap[ctype] = moveMap[ctype] or {}
        table.insert(moveMap[ctype], id)
      end
      for _, v in pairs(moveMap) do
        local put = #v == 1 and v[1] or
        room:askForCardChosen(player, player, { card_data = { { "AskForCardChosen", v } } }, self.name, "#chengye-put")
        table.insert(moves, {
          ids = { put },
          from = room.owner_map[put],
          to = player.id,
          toArea = Card.PlayerSpecial,
          moveReason = fk.ReasonPut,
          skillName = self.name,
          specialName = "chengye_classic",
          proposer = player.id,
        })
      end
      room:moveCards(table.unpack(moves))
    end
  end,
}
mobile__mamidi:addSkill(chengye)
local buxu = fk.CreateActiveSkill{
  name = "buxu",
  anim_type = "drawcard",
  can_use = function(self, player)
    return #player:getPile("chengye_classic") < 6
  end,
  card_num = function ()
    return 1 + Self:getMark("buxu-phase")
  end,
  card_filter = function (self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select)) and #selected < (1 + Self:getMark("buxu-phase"))
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local choice = room:askForChoice(player, getLackClassics(player), self.name, "#buxu-choice", true)
    local cards = table.simpleClone(room.draw_pile)
    table.insertTable(cards, room.discard_pile)
    for i = #cards, 1, -1 do
      if getClassicsType (cards[i]) ~= choice then
        table.remove(cards, i)
      end
    end
    if #cards > 0 then
      player:addToPile("chengye_classic", table.random(cards), true, self.name)
      room:addPlayerMark(player, "buxu-phase")
    else
      room:sendLog{ type = "#BuXuFalid", from = player.id, arg = self.name, arg2 = ":"..choice }
    end
  end,
}
mobile__mamidi:addSkill(buxu)
Fk:loadTranslationTable{
  ["mobile__mamidi"] = "马日磾",
  ["#mobile__mamidi"] = "少传融业",
  ["illustrator:mobile__mamidi"] = "君桓文化",

  ["chengye"] = "承业",
  [":chengye"] = "锁定技，①当其他角色使用一张非转化牌结算结束后，或一张其他角色区域内的装备牌或延时锦囊牌进入弃牌堆后，若你有对应的“六经”处于缺失状态，"..
  "你将此牌置于你的武将牌上，称为“典”；"..
  "<br>②出牌阶段开始时，若你的“六经”均未处于缺失状态，你获得所有“典”。"..
  "<br><font color='grey'>“六经”即：诗-伤害类锦囊牌；书-基本牌；礼-【无懈可击】；易-【无中生有】；乐-【乐不思蜀】；春秋-装备牌。",
  ["chengye_classic"] = "典",
  ["#chengye-put"] = "承业：将其中一张牌作为“典”",
  ["buxu"] = "补续",
  [":buxu"] = "出牌阶段，若你拥有技能〖承业〗，你可以弃置X张牌并选择一种你缺失的“六经”，然后从牌堆或弃牌堆中随机获得一张对应此“六经”的牌加入“典”中"..
  "（X为你本阶段此前成功发动过此技能的次数+1）。",
  ["#buxu-choice"] = "补续：选择一种你缺失的“六经”获得",
  ["cy_classic_nullification"] = "礼",
  ["cy_classic_ex_nihilo"] = "易",
  ["cy_classic_indulgence"] = "乐",
  ["cy_classic_basic"] = "书",
  ["cy_classic_equip"] = "春秋",
  ["cy_classic_damage"] = "诗",
  [":cy_classic_nullification"] = "无懈可击",
  [":cy_classic_ex_nihilo"] = "无中生有",
  [":cy_classic_indulgence"] = "乐不思蜀",
  [":cy_classic_basic"] = "基本牌",
  [":cy_classic_equip"] = "装备牌",
  [":cy_classic_damage"] = "伤害类锦囊牌",
  ["#BuXuFalid"] = "%from 发动 %arg 失败，无法检索到 %arg2",
  ["$chengye1"] = "勤学于未长，立志于未壮。",
  ["$chengye2"] = "志在坚且行，学在勤且久。",
  ["$chengye3"] = "承继族贤之业，弘彰孔儒之学。",
  ["$buxu1"] = "今世俗儒穿凿，不加补续，恐疑误后学。",
  ["$buxu2"] = "经籍去圣久远，文字多谬，当正定《六经》。",
  ["~mobile__mamidi"] = "袁公路！汝怎可欺我！",
}

local wangjun = General(extension, "wangjun", "qun", 4)
wangjun.subkingdom = "jin"
local zhujian = fk.CreateActiveSkill{
  name = "zhujian",
  anim_type = "drawcard",
  min_target_num = 2,
  max_target_num = 999,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #Fk:currentRoom():getPlayerById(to_select):getCardIds(Player.Equip) > 0
  end,
  on_use = function(self, room, effect)
    local tos = table.simpleClone(effect.tos)
    room:sortPlayersByAction(tos)
    local targets = table.map(effect.tos, function(pId) return room:getPlayerById(pId) end)
    for _, p in ipairs(targets) do
      p:drawCards(1, self.name)
    end
  end,
}
local duansuo = fk.CreateActiveSkill{
  name = "duansuo",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return Fk:currentRoom():getPlayerById(to_select).chained
  end,
  on_use = function(self, room, effect)
    local tos = table.simpleClone(effect.tos)
    room:sortPlayersByAction(tos)
    local targets = table.map(effect.tos, function(pId) return room:getPlayerById(pId) end)
    for _, p in ipairs(targets) do
      p:setChainState(false)
    end
    for _, p in ipairs(targets) do
      room:damage({
        from = room:getPlayerById(effect.from),
        to = p,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = self.name,
      })
    end
  end,
}
wangjun:addSkill(zhujian)
wangjun:addSkill(duansuo)
Fk:loadTranslationTable{
  ["wangjun"] = "王濬",
  ["#wangjun"] = "首下石城",
  ["zhujian"] = "筑舰",
  [":zhujian"] = "出牌阶段限一次，你可以令至少两名装备区里有牌的角色各摸一张牌。",
  ["duansuo"] = "断索",
  [":duansuo"] = "出牌阶段限一次，你可以重置至少一名角色，然后对这些角色各造成1点火焰伤害。",
  ["$zhujian1"] = "修橹筑楼舫，伺时补金瓯。",
  ["$zhujian2"] = "连舫披金甲，王气自可收。",
  ["$duansuo1"] = "吾心如炬，无碍寒江铁索。",
  ["$duansuo2"] = "熔金断索，克敌建功！",
  ["~wangjun"] = "问鼎金瓯碎，临江铁索寒……",
}

--SP12：赵统赵广 刘晔 李丰 诸葛果 胡金定 王元姬 羊徽瑜 杨彪 司马昭
local zhaotongzhaoguang = General(extension, "zhaotongzhaoguang", "shu", 4)
local yizan = fk.CreateViewAsSkill{
  name = "yizan",
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, selected, selected_cards)
    if Self:usedSkillTimes("longyuan", Player.HistoryGame) > 0 then
      return "#yizan2"
    else
      return "#yizan1"
    end
  end,
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and not card.is_derived and
        ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    if #selected == 0 then
      return card.type == Card.TypeBasic
    elseif Self:usedSkillTimes("longyuan", Player.HistoryGame) == 0 then
      return #selected == 1
    else
      return false
    end
  end,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    if Self:usedSkillTimes("longyuan", Player.HistoryGame) > 0 then
      if #cards ~= 1 then return end
    else
      if #cards ~= 2 then return end
    end
    if not table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeBasic end) then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
}
local longyuan = fk.CreateTriggerSkill{
  name = "longyuan",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:usedSkillTimes("yizan", Player.HistoryGame) > 2
  end,
}
zhaotongzhaoguang:addSkill(yizan)
zhaotongzhaoguang:addSkill(longyuan)

local zhaotongzhaoguang_win = fk.CreateActiveSkill{ name = "zhaotongzhaoguang_win_audio" }
zhaotongzhaoguang_win.package = extension
Fk:addSkill(zhaotongzhaoguang_win)

Fk:loadTranslationTable{
  ["zhaotongzhaoguang"] = "赵统赵广",
  ["#zhaotongzhaoguang"] = "翊赞季兴",
  ["designer:zhaotongzhaoguang"] = "Loun老萌",
	["illustrator:zhaotongzhaoguang"] = "蛋费鸡丁",

  ["yizan"] = "翊赞",
  [":yizan"] = "你可以将两张牌（其中至少一张是基本牌）当任意基本牌使用或打出。",
  ["longyuan"] = "龙渊",
  [":longyuan"] = "觉醒技，准备阶段，若你本局游戏内发动过至少三次〖翊赞〗，你修改〖翊赞〗为只需一张牌。",
  ["#yizan1"] = "翊赞：你可以将两张牌（其中至少一张是基本牌）当任意基本牌使用或打出",
  ["#yizan2"] = "翊赞：你可以将一张基本牌当任意基本牌使用或打出",

  ["$yizan1"] = "承吾父之勇，翊军立阵。",
  ["$yizan2"] = "继先帝之志，季兴大汉。",
  ["$longyuan1"] = "金鳞岂是池中物，一遇风云便化龙。",
  ["$longyuan2"] = "忍时待机，今日终于可以建功立业。",
  ["~zhaotongzhaoguang"] = "守业死战，不愧初心。",
  ["$zhaotongzhaoguang_win_audio"] = "身继龙魂，效捷致果！",
}

local liuye = General(extension, "mobile__liuye", "wei", 3)
local mobile__catapult = {{"mobile__catapult", Card.Diamond, 9}}
local polu = fk.CreateTriggerSkill{
  name = "polu",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnStart then
      if player:hasSkill(self) and target == player and #player:getAvailableEquipSlots(Card.SubtypeWeapon) > 0 then
        return player.room:getCardArea(U.prepareDeriveCards(player.room, mobile__catapult, "mobile__catapult")[1]) == Card.Void
      end
    else
      return player:hasSkill(self) and target == player and not table.find(player:getEquipments(Card.SubtypeWeapon), function(id)
        return Fk:getCardById(id).name == "mobile__catapult" end)
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local n = (event == fk.TurnStart) and 1 or data.damage
    for _ = 1, n do
      if not player:hasSkill(self) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local id = U.prepareDeriveCards(player.room, mobile__catapult, "mobile__catapult")[1]
      if not id then return end
      room:obtainCard(player, id, false, fk.ReasonPrey)
      local card = Fk:getCardById(id)
      if table.contains(player:getCardIds("h"), id) and U.canUseCardTo(room, player, player, card) then
        room:useCard({from = player.id, tos = {{player.id}}, card = card})
      end
    else
      player:drawCards(1, self.name)
      if player.dead then return end
      local ids = {}
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).sub_type == Card.SubtypeWeapon then table.insert(ids, id) end
      end
      if #ids == 0 then return end
      local id = table.random(ids)
      room:obtainCard(player, id, false, fk.ReasonPrey)
      local card = Fk:getCardById(id)
      if table.contains(player:getCardIds("h"), id) and U.canUseCardTo(room, player, player, card) then
        room:useCard({from = player.id, tos = {{player.id}}, card = card})
      end
    end
  end,
}
liuye:addSkill(polu)
local choulue = fk.CreateTriggerSkill{
  name = "choulue",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function (p) return not p:isNude() end)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#choulue-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards = room:askForCard(to, 1, 1, true, self.name, true, ".", "#choulue-ask::"..player.id)
    if #cards > 0 then
      room:obtainCard(player, cards[1], false, fk.ReasonGive)
      local name = player:getMark("@choulue")
      if name ~= 0 then
        U.askForUseVirtualCard(room, player, name, nil, self.name, nil, true, true, false, true)
      end
    end
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self,true) and target == player and data.card and data.card.subtype ~= Card.SubtypeDelayedTrick
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@choulue", data.card.trueName)
  end,
}
liuye:addSkill(choulue)

Fk:loadTranslationTable{
  ["mobile__liuye"] = "刘晔",
  ["#mobile__liuye"] = "佐世之才",
  ["designer:mobile__liuye"] = "荼蘼",
	["illustrator:mobile__liuye"] = "Thinking",

  ["polu"] = "破橹",
  [":polu"] = "锁定技，①回合开始时，你获得游戏外的【霹雳车】并使用之；②当你受到1点伤害后，若你的装备区里没有【霹雳车】，你摸一张牌，然后随机从"..
  "牌堆中获得一张武器牌并使用之。<br>"..
  "<font color='grey'>【霹雳车】装备牌·武器<br/><b>攻击范围</b>：9<br /><b>武器技能</b>：当你对其他角色造成伤害后，你可以弃置其装备区内的所有牌。",
  ["choulue"] = "筹略",
  [":choulue"] = "出牌阶段开始时，你可以令一名其他角色选择是否交给你一张牌，若其执行，你可视为使用上一张除延时锦囊牌以外对你造成伤害的牌。",
  ["#choulue-choose"] = "筹略：令一名其他角色选择是否交给你一张牌",
  ["#choulue-ask"] = "筹略：你可以交给 %dest 一张牌，若交给，其可以转化牌",
  ["@choulue"] = "筹略",

  ["$polu1"] = "设此发石车，可破袁军高橹。",
  ["$polu2"] = "霹雳之声，震丧敌胆。",
  ["$choulue1"] = "依此计行，可安军心。",
  ["$choulue2"] = "破袁之策，吾已有计。",
  ["~mobile__liuye"] = "唉，于上不能佐君主，于下不能亲同僚，吾愧为佐世人臣。",	
}

local lifeng = General(extension, "lifeng", "shu", 3)
local tunchu = fk.CreateTriggerSkill{
  name = "tunchu",
  anim_type = "drawcard",
  derived_piles = "lifeng_liang",
  events = {fk.DrawNCards, fk.AfterDrawNCards},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.DrawNCards then
        return player:hasSkill(self) and #player:getPile("lifeng_liang") == 0
      else
        return player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and not player:isKongcheng()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      return player.room:askForSkillInvoke(player, self.name)
    else
      local cards = player.room:askForCard(player, 1, 999, false, self.name, true, ".", "#tunchu-put")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n + 2
    else
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(self.cost_data)
      player:addToPile("lifeng_liang", dummy, true, self.name)
    end
  end,
}
local tunchu_prohibit = fk.CreateProhibitSkill{
  name = "#tunchu_prohibit",
  prohibit_use = function(self, player, card)
    return player:hasSkill(tunchu) and #player:getPile("lifeng_liang") > 0 and card.trueName == "slash"
  end,
}
local shuliang = fk.CreateTriggerSkill{
  name = "shuliang",
  anim_type = "support",
  expand_pile = "lifeng_liang",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Finish and target:getHandcardNum() < target.hp and
    #player:getPile("lifeng_liang") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, false, self.name, true,
      ".|.|.|lifeng_liang|.|.", "#shuliang-invoke::"..target.id, "lifeng_liang")
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:moveCards({
      from = player.id,
      ids = self.cost_data,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = self.name,
      specialName = self.name,
    })
    if not target.dead then
      target:drawCards(2, self.name)
    end
  end,
}
tunchu:addRelatedSkill(tunchu_prohibit)
lifeng:addSkill(tunchu)
lifeng:addSkill(shuliang)
Fk:loadTranslationTable{
  ["lifeng"] = "李丰",
  ["#lifeng"] = "朱提太守",
  ["illustrator:lifeng"] = "NOVART",

  ["tunchu"] = "屯储",
  [":tunchu"] = "摸牌阶段，若你没有“粮”，你可以多摸两张牌，然后可以将任意张手牌置于你的武将牌上，称为“粮”；若你的武将牌上有“粮”，你不能使用【杀】。",
  ["shuliang"] = "输粮",
  [":shuliang"] = "一名角色结束阶段，若其手牌数小于其体力值，你可以移去一张“粮”，然后该角色摸两张牌。",
  ["lifeng_liang"] = "粮",
  ["#tunchu-put"] = "屯储：你可以将任意张手牌置为“粮”",
  ["#shuliang-invoke"] = "输粮：你可以移去一张“粮”，令 %dest 摸两张牌",

  ["$tunchu1"] = "屯粮事大，暂不与尔等计较。",
  ["$tunchu2"] = "屯粮待战，莫动刀枪。",
  ["$shuliang1"] = "将军驰劳，酒肉慰劳。",
  ["$shuliang2"] = "将军，牌来了。",
  ["~lifeng"] = "吾，有负丞相重托。",
}

local hujinding = General(extension, "hujinding", "shu", 2, 6, General.Female)
local renshi = fk.CreateTriggerSkill{
  name = "renshi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.every(data.card:isVirtual() and data.card.subcards or {data.card.id}, function(id)
      return room:getCardArea(id) == Card.Processing end) then
      room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    end
    room:changeMaxHp(player, -1)
    return true
  end,
}
local wuyuan = fk.CreateActiveSkill{
  name = "wuyuan",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:getCardById(effect.cards[1])
    room:obtainCard(target, card, false, fk.ReasonGive)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if not target.dead then
      if card.color == Card.Red and target:isWounded() then
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      local n = card.name ~= "slash" and 2 or 1
      target:drawCards(n, self.name)
    end
  end,
}
local huaizi = fk.CreateMaxCardsSkill{
  name = "huaizi",
  frequency = Skill.Compulsory,
  fixed_func = function(self, player)
    if player:hasSkill(self) then
      return player.maxHp
    end
  end
}
hujinding:addSkill(renshi)
hujinding:addSkill(wuyuan)
hujinding:addSkill(huaizi)
Fk:loadTranslationTable{
  ["hujinding"] = "胡金定",
  ["#hujinding"] = "怀子求怜",
  ["illustrator:hujinding"] = "Thinking",
  ["renshi"] = "仁释",
  [":renshi"] = "锁定技，当你受到【杀】造成的伤害时，若你已受伤，你防止此伤害，获得此【杀】并减1点体力上限。",
  ["wuyuan"] = "武缘",
  [":wuyuan"] = "出牌阶段限一次，你可以交给一名其他角色一张【杀】，然后你回复1点体力，其摸一张牌。若此【杀】为：红色【杀】，该角色额外回复1点体力；"..
  "非普通【杀】，该角色额外摸一张牌。",
  ["huaizi"] = "怀子",
  [":huaizi"] = "锁定技，你的手牌上限等于体力上限。",

  ["$renshi1"] = "巾帼于乱世，只能飘零如尘。",
  ["$renshi2"] = "还望您可以手下留情！",
  ["$wuyuan1"] = "夫君，此次出征，还望您记挂妾身！",
  ["$wuyuan2"] = "云长，一定要平安归来啊！",
  ["~hujinding"] = "云长，重逢不久，又要相别么……",
}

local wangyuanji = General(extension, "mobile__wangyuanji", "wei", 3, 3, General.Female)
local qianchong = fk.CreateTriggerSkill{
  name = "qianchong",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      local colors = {}
      for _, id in ipairs(player.player_cards[Player.Equip]) do
        table.insertIfNeed(colors, Fk:getCardById(id).color)
      end
      table.removeOne(colors, Card.NoColor)
      return #colors ~= 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local choice = player.room:askForChoice(player, {"basic", "trick", "equip"}, self.name, "#qianchong-choice")
    player.room:setPlayerMark(player, "@qianchong-phase", choice)
  end,

  refresh_events = {fk.AfterCardsMove, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return event == fk.AfterCardsMove or (data == self and player == target)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local equips = player.player_cards[Player.Equip]
    local hasweimu = player:hasSkill(self, true) and #equips > 0 and table.every(equips, function (id)
      return Fk:getCardById(id).color == Card.Black end)
    local hasmingzhe = player:hasSkill(self, true) and #equips > 0 and table.every(equips, function (id)
      return Fk:getCardById(id).color == Card.Red end)

    local qianchong_skills = type(player:getMark("qianchong_skills")) == "table" and player:getMark("qianchong_skills") or {}
    local skillchange = {}
    if hasweimu and not player:hasSkill("weimu", true) then
      table.insert(skillchange, "weimu")
      table.insertIfNeed(qianchong_skills, "weimu")
    elseif not hasweimu and player:hasSkill("weimu", true) and table.contains(qianchong_skills, "weimu") then
      table.insert(skillchange, "-weimu")
      table.removeOne(qianchong_skills, "mingzhe")
    end
    if hasmingzhe and not player:hasSkill("mingzhe", true) then
      table.insert(skillchange, "mingzhe")
      table.insertIfNeed(qianchong_skills, "mingzhe")
    elseif not hasmingzhe and player:hasSkill("mingzhe", true) and table.contains(qianchong_skills, "mingzhe") then
      table.insert(skillchange, "-mingzhe")
      table.removeOne(qianchong_skills, "mingzhe")
    end
    if #skillchange > 0 then
      room:handleAddLoseSkills(player, table.concat(skillchange, "|"), nil, true, false)
    end
    room:setPlayerMark(player, "qianchong_skills", qianchong_skills)
  end,
}
local qianchong_targetmod = fk.CreateTargetModSkill{
  name = "#qianchong_targetmod",
  residue_func = function(self, player, skill, scope, card)
    return (card and card:getTypeString() == player:getMark("@qianchong-phase")) and 999 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return (card and card:getTypeString() == player:getMark("@qianchong-phase")) and 999 or 0
  end,
}
local shangjian = fk.CreateTriggerSkill{
  name = "shangjian",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Finish and
      player:getMark("shangjian-turn") > 0 and player:getMark("shangjian-turn") <= player.hp
  end,
  on_use = function(self, event, target, player, data)
    player.room:drawCards(player, player:getMark("shangjian-turn"), self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    local fuckYoka = {}
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if parentUseData then
      local use = parentUseData.data[1]
      if use.card.type == Card.TypeEquip and use.from == player.id then
        fuckYoka = use.card:isVirtual() and use.card.subcards or {use.card.id}
      end
    end
    local x = 0
    for _, move in ipairs(data) do
      if move.from and move.from == player.id then
        x = x + #table.filter(move.moveInfo, function(info)
          return (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and not table.contains(fuckYoka, info.cardId) end)
      end
      if move.to ~= player.id or move.toArea ~= Card.PlayerEquip then
        x = x + #table.filter(move.moveInfo, function(info)
          return (info.fromArea == Card.Processing) and table.contains(fuckYoka, info.cardId) end)
      end
    end
    if x > 0 then
      self.cost_data = x
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "shangjian-turn", self.cost_data)
    if player:hasSkill(self, true) then
      player.room:setPlayerMark(player, "@shangjian-turn", player:getMark("shangjian-turn"))
    end
  end,
}
local win = fk.CreateActiveSkill{ name = "mobile__wangyuanji_win_audio" }
win.package = extension
Fk:addSkill(win)
qianchong:addRelatedSkill(qianchong_targetmod)
wangyuanji:addSkill(qianchong)
wangyuanji:addSkill(shangjian)
wangyuanji:addRelatedSkill("weimu")
wangyuanji:addRelatedSkill("mingzhe")
Fk:loadTranslationTable{
  ["mobile__wangyuanji"] = "王元姬",
  ["#mobile__wangyuanji"] = "清雅抑华",
  ["illustrator:mobile__wangyuanji"] = "凝聚永恒",
  ["qianchong"] = "谦冲",
  [":qianchong"] = "锁定技，如果你的装备区所有牌均为黑色，则你拥有〖帷幕〗；如果你装备区所有牌均为红色，则你拥有〖明哲〗。出牌阶段开始时，"..
  "若你不满足上述条件，则你选择一种类型的牌，本阶段内使用此类型的牌无次数和距离限制。",
  ["shangjian"] = "尚俭",
  [":shangjian"] = "锁定技，一名角色的结束阶段，若你于此回合失去的牌（非因使用装备牌而失去的牌数与你使用装备牌的过程中未进入你装备区的牌数之和）"..
  "不大于你的体力值，你摸等同于失去数量的牌。",
  ["#qianchong-choice"] = "谦冲：选择一种类别，此阶段内使用此类别的牌无次数和距离限制",
  ["@qianchong-phase"] = "谦冲",
  ["@shangjian-turn"] = "尚俭",

  ["$shangjian1"] = "如今乱世，当秉俭行之节。",
  ["$shangjian2"] = "百姓尚处寒饥之困，吾等不可奢费财力。",
  ["$qianchong1"] = "细行策划，只盼能助夫君一臂之力。",
  ["$weimu_mobile__wangyuanji"] = "宫闱之内，何必擅涉外事！",
  ["$mingzhe_mobile__wangyuanji"] = "谦瑾行事，方能多吉少恙。",
  ["~mobile__wangyuanji"] = "世事沉浮，非是一人可逆啊……",
  ["$mobile__wangyuanji_win_audio"] = "苍生黎庶，都会有一个美好的未来了。",
}

local yanghuiyu = General(extension, "mobile__yanghuiyu", "wei", 3, 3, General.Female)
local hongyi = fk.CreateActiveSkill{
  name = "hongyi",
  anim_type = "control",
  prompt = "#hongyi-active",
  max_card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(target, "@@hongyi")
    local targetRecorded = type(player:getMark("hongyi_targets")) == "table" and player:getMark("hongyi_targets") or {}
    table.insertIfNeed(targetRecorded, effect.tos[1])
    room:setPlayerMark(player, "hongyi_targets", targetRecorded)
  end,
}
local hongyi_delay = fk.CreateTriggerSkill{
  name = "#hongyi_delay",
  anim_type = "control",
  events = {fk.DamageCaused},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and target:getMark("@@hongyi") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      if data.to and not data.to.dead then
        room:drawCards(data.to, 1, hongyi.name)
      end
    elseif judge.card.color == Card.Black then
      data.damage = data.damage - 1
    end
  end,

  refresh_events = {fk.TurnStart, fk.Death},
  can_refresh = function(self, event, target, player, data)
    return player == target and type(player:getMark("hongyi_targets")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("hongyi_targets")
    if type(targets) == "table" then
      for _, pid in ipairs(targets) do
        room:removePlayerMark(room:getPlayerById(pid), "@@hongyi")
      end
    end
    room:setPlayerMark(player, "hongyi_targets", 0)
  end,
}
local quanfeng = fk.CreateTriggerSkill{
  name = "quanfeng",
  events = {fk.Deathed, fk.AskForPeaches},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      if event == fk.Deathed then
        return player:hasSkill(hongyi.name, true) and not table.contains(player.room:getBanner('memorializedPlayers') or {}, target.id)
      else
        return player == target and player.dying and player.hp < 1
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = event == fk.Deathed and "#quanfeng1-invoke::" .. target.id or "#quanfeng2-invoke"
    return player.room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Deathed then
      local zhuisiPlayers = room:getBanner('memorializedPlayers') or {}
      table.insertIfNeed(zhuisiPlayers, target.id)
      room:setBanner('memorializedPlayers', zhuisiPlayers)

      room:handleAddLoseSkills(player, "-hongyi", nil, true, false)

      local skills = Fk.generals[target.general]:getSkillNameList()
      if target.deputyGeneral ~= "" then
        table.insertTableIfNeed(skills, Fk.generals[target.deputyGeneral]:getSkillNameList())
      end
      skills = table.filter(skills, function(skill_name)
        local skill = Fk.skills[skill_name]
        return not skill.lordSkill and not (#skill.attachedKingdom > 0 and not table.contains(skill.attachedKingdom, player.kingdom))
      end)
      if #skills > 0 then
        room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
      end
      room:changeMaxHp(player, 1)
      if not player.dead and player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    elseif event == fk.AskForPeaches then
      room:changeMaxHp(player, 2)
      if not player.dead and player:isWounded() then
        room:recover({
          who = player,
          num = math.min(4, player:getLostHp()),
          recoverBy = player,
          skillName = self.name
        })
      end
    end
  end,
}
hongyi:addRelatedSkill(hongyi_delay)
yanghuiyu:addSkill(hongyi)
yanghuiyu:addSkill(quanfeng)
Fk:loadTranslationTable{
  ["mobile__yanghuiyu"] = "羊徽瑜",
  ["#mobile__yanghuiyu"] = "温慧母仪",
  ["illustrator:mobile__yanghuiyu"] = "石蝉",

  ["hongyi"] = "弘仪",
  ["#hongyi_delay"] = "弘仪",
  [":hongyi"] = "出牌阶段限一次，你可以指定一名其他角色，然后直到你的下个回合开始时，其造成伤害时进行一次判定：若结果为红色，则受伤角色摸一张牌；"..
  "若结果为黑色则此伤害-1。",
  ["quanfeng"] = "劝封",
  [":quanfeng"] = "限定技，当一名其他角色死亡后，你可以<u>追思</u>该角色，失去“弘仪”，然后获得其武将牌上的所有技能（主公技除外），"..
  "你加1点体力上限并回复1点体力；当你处于濒死状态时，你可以加2点体力上限，回复4点体力。" ..
  "<br/><font color='grey'>#\"<b>追思</b>\"：被追思过的角色本局游戏不能再成为追思的目标。",
  ["#hongyi-active"] = "发动弘仪，选择一名其他角色",
  ["@@hongyi"] = "弘仪",
  ["#quanfeng1-invoke"] = "劝封：可失去弘仪并获得%dest的所有技能，然后加1点体力上限和体力",
  ["#quanfeng2-invoke"] = "劝封：是否加2点体力上限，回复4点体力",

  ["$hongyi1"] = "克明礼教，约束不端之行。",
  ["$hongyi2"] = "训成弘操，以扬正明之德。",
  ["$quanfeng1"] = "媛容德懿，应追谥之。",
  ["$quanfeng2"] = "景怀之号，方配得上前人之德。",
  ["~mobile__yanghuiyu"] = "桃符，一定要平安啊……",
}

local yangbiao = General(extension, "yangbiao", "qun", 3)
local zhaohan = fk.CreateTriggerSkill{
  name = "zhaohan",
  mute = true,
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) < 7
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:usedSkillTimes(self.name, Player.HistoryGame) < 5 then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "support")
      room:changeMaxHp(player, 1)
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    else
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
      room:changeMaxHp(player, -1)
    end
  end,
}
local rangjie = fk.CreateTriggerSkill{
  name = "rangjie",
  events = {fk.Damaged},
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_trigger = function(self, event, target, player, data)
    local ret
    for i = 1, data.damage do
      ret = self:doCost(event, target, player, data)
      if ret then return ret end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choices = { "rangjie_obtain", "Cancel" }
    local room = player.room
    if #room:canMoveCardInBoard() > 0 then
      table.insert(choices, 1, "rangjie_move")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "Cancel" then return end
    if choice == "rangjie_obtain" then
      self.cost_data = room:askForChoice(player, { "basic", "trick", "equip" }, self.name)
    else
      local targets = room:askForChooseToMoveCardInBoard(player, "#rangjie-move", self.name)
      if #targets == 0 then
        return false
      end
      self.cost_data = targets
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if type(self.cost_data) == "string" then
      local cardIds = room:getCardsFromPileByRule(".|.|.|.|.|" .. self.cost_data)
      if #cardIds > 0 then
        room:obtainCard(player, cardIds[1], true, fk.ReasonPrey)
      end
    else
      local targets = table.map(self.cost_data, function(pId)
        return room:getPlayerById(pId)
      end)
      room:askForMoveCardInBoard(player, targets[1], targets[2], self.name)
    end
    player:drawCards(1, self.name)
  end,
}
local mobileYizheng = fk.CreateActiveSkill{
  name = "mobile__yizheng",
  anim_type = "control",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return
      #selected < 1 and
      Self.id ~= to_select and
      Self.hp >= target.hp and
      Self:canPindian(target)
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local pindian = from:pindian({ to }, self.name)
    if pindian.results[to.id].winner == from then
      room:setPlayerMark(to, "@@mobile__yizheng", true)
    else
      room:changeMaxHp(from, -1)
    end
  end,
}
local mobileYizhengDebuff = fk.CreateTriggerSkill{
  name = "#yizheng-debuff",
  mute = true,
  priority = 3,
  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return player == target and player.phase == Player.Start and target:getMark("@@mobile__yizheng") == true
  end,
  on_refresh = function(self, event, target, player, data)
    target.room:setPlayerMark(target, "@@mobile__yizheng", 0)
    target:skip(Player.Draw)
  end,
}
mobileYizheng:addRelatedSkill(mobileYizhengDebuff)
yangbiao:addSkill(zhaohan)
yangbiao:addSkill(rangjie)
yangbiao:addSkill(mobileYizheng)
Fk:loadTranslationTable{
  ["yangbiao"] = "杨彪",
  ["#yangbiao"] = "德彰海内",
  ["designer:yangbiao"] = "Loun老萌",
	["illustrator:yangbiao"] = "木美人",

  ["zhaohan"] = "昭汉",
  [":zhaohan"] = "锁定技，准备阶段开始时，若X：小于4，你加1点体力上限并回复1点体力；不小于4且小于7，你减1点体力上限（X为你发动过本技能的次数）。",
  ["rangjie"] = "让节",
  [":rangjie"] = "当你受到1点伤害后，你可以选择一项：1.移动场上一张牌；2.从牌堆中随机获得一张你指定类别的牌。最后你摸一张牌。",
  ["mobile__yizheng"] = "义争",
  [":mobile__yizheng"] = "出牌阶段限一次，你可以与一名体力值不大于你的角色拼点。若你：赢，跳过其下个摸牌阶段；没赢，你减1点体力上限。",
  ["rangjie_move"] = "移动场上一张牌",
  ["rangjie_obtain"] = "获得指定类别的牌",
  ["#rangjie-move"] = "让节：请选择两名角色，移动其场上的一张牌",
  ["@@mobile__yizheng"] = "义争",
  ["#yizheng-debuff"] = "义争",

  ["$zhaohan1"] = "天道昭昭，再兴如光武亦可期。",
  ["$zhaohan2"] = "汉祚将终，我又岂能无憾。",
  ["$rangjie1"] = "公既执掌权柄，又何必令君臣遭乱。",
  ["$rangjie2"] = "公虽权倾朝野，亦当尊圣上之意。",
  ["$mobile__yizheng1"] = "一人劫天子，一人质公卿，此可行邪？",
  ["$mobile__yizheng2"] = "诸军举事，当上顺天心，奈何如是！",
  ["~yangbiao"] = "未能效死佑汉，只因宗族之重……",
}

local simazhao = General(extension, "mobile__simazhao", "wei", 3)
local zhaoxin = fk.CreateActiveSkill{
  name = "zhaoxin",
  anim_type = "drawcard",
  derived_piles = "simazhao_wang",
  min_card_num = 1,
  target_num = 0,
  prompt = "#zhaoxin",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and #Self:getPile("simazhao_wang") < 3
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 3 - #Self:getPile("simazhao_wang")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    player:addToPile("simazhao_wang", dummy, true, self.name)
    if not player.dead then
      player:drawCards(#effect.cards, self.name)
    end
  end
}
local zhaoxin_trigger = fk.CreateTriggerSkill{
  name = "#zhaoxin_trigger",
  main_skill = zhaoxin,
  expand_pile = "simazhao_wang",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("zhaoxin") and (target == player or player:inMyAttackRange(target)) and target.phase == Player.Draw and
      #player:getPile("simazhao_wang") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(target, "zhaoxin", nil, "#zhaoxin-get:"..player.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(target.id, {player.id})
    player:broadcastSkillInvoke("zhaoxin")
    room:notifySkillInvoked(player, "zhaoxin", "support")
    local card = room:askForCard(player, 1, 1, false, "zhaoxin", false,
      ".|.|.|simazhao_wang|.|.", "#zhaoxin-give::"..target.id, "simazhao_wang")
    if #card > 0 then
      card = card[1]
    else
      card = table.random(player:getPile("simazhao_wang"))
    end
    room:obtainCard(target.id, card, true, fk.ReasonPrey)
    if player.dead or target.dead then return end
    if room:askForSkillInvoke(player, "zhaoxin", nil, "#zhaoxin-damage::"..target.id) then
      room:doIndicate(player.id, {target.id})
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = "zhaoxin",
      }
    end
  end,
}
local daigong = fk.CreateTriggerSkill{
  name = "daigong",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not player:isKongcheng() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#daigong-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.from.id})
    player:showCards(player:getCardIds("h"))
    if player.dead then return end
    if data.from.dead or data.from:isNude() then
      return true
    end
    local suits = {}
    for _, id in ipairs(player:getCardIds("h")) do
      if Fk:getCardById(id).suit ~= Card.NoSuit then
        table.insertIfNeed(suits, Fk:getCardById(id):getSuitString())
      end
    end
    local card = room:askForCard(data.from, 1, 1, true, self.name, true, ".|.|^("..table.concat(suits, ",")..")", "#daigong-give:"..player.id)
    if #card > 0 then
      room:obtainCard(player.id, card[1], true, fk.ReasonGive)
    else
      return true
    end
  end,
}
zhaoxin:addRelatedSkill(zhaoxin_trigger)
simazhao:addSkill(zhaoxin)
simazhao:addSkill(daigong)

local mobile__simazhao_win = fk.CreateActiveSkill{ name = "mobile__simazhao_win_audio" }
mobile__simazhao_win.package = extension
Fk:addSkill(mobile__simazhao_win)

Fk:loadTranslationTable{
  ["mobile__simazhao"] = "司马昭",
  ["#mobile__simazhao"] = "四海威服",
  ["zhaoxin"] = "昭心",
  [":zhaoxin"] = "出牌阶段限一次，你可以将任意张牌置于你的武将牌上，称为“望”（其总数不能超过3），然后摸等量的牌。你和你攻击范围内角色的摸牌阶段"..
  "结束时，其可以获得一张你选择的“望”，然后你可以对其造成1点伤害。",
  ["daigong"] = "怠攻",
  [":daigong"] = "每回合限一次，当你受到伤害时，你可展示所有手牌令伤害来源选择一项：1.交给你一张与你以此法展示的所有牌花色均不同的牌；2.防止此伤害。",
  ["#zhaoxin"] = "昭心：你可以将任意张牌置为“望”，摸等量的牌（“望”至多三张）",
  ["simazhao_wang"] = "望",
  ["#zhaoxin-get"] = "昭心：你可以令 %src 选择一张“望”令你获得，然后其可以对你造成1点伤害",
  ["#zhaoxin-give"] = "昭心：选择一张“望”令 %dest 获得",
  ["#zhaoxin-damage"] = "昭心：是否对 %dest 造成1点伤害？",
  ["#daigong-invoke"] = "怠攻：你可以展示所有手牌，令伤害来源交给你一张花色不同的牌或防止此伤害",
  ["#daigong-give"] = "怠攻：你需交给 %src 一张花色不同的牌，否则防止此伤害",

  ["$zhaoxin1"] = "吾心昭昭，何惧天下之口！",
  ["$zhaoxin2"] = "公此行欲何为，吾自有量度。",
  ["$daigong1"] = "不急，只等敌军士气渐殆。",
  ["$daigong2"] = "敌谋吾已尽料，可以长策縻之。",
  ["~mobile__simazhao"] = "安世，接下来，就看你的了……",
  ["$mobile__simazhao_win_audio"] = "天下归一之功，已近在咫尺。",
}

--SP12：曹嵩 裴秀 杨阜 彭羕 牵招 郭女王 韩遂
local caosong = General(extension, "mobile__caosong", "wei", 3)
local yijin = fk.CreateTriggerSkill{
  name = "yijin",
  frequency = Skill.Compulsory,
  mute = true,
  events = {fk.GameStart, fk.TurnStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.TurnStart then
        return target == player and #U.getMark(player, "@[:]yijin_owner") == 0
      else
        return target == player and player.phase == Player.Play and #U.getMark(player, "@[:]yijin_owner") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "special")
      room:setPlayerMark(player, "@[:]yijin_owner",
        {"yijin_wushi", "yijin_houren", "yijin_guxiong", "yijin_yongbi", "yijin_tongshen", "yijin_jinmi"})
    elseif event == fk.TurnStart then
      player:broadcastSkillInvoke(self.name, 3)
      room:notifySkillInvoked(player, self.name, "negative")
      room:killPlayer({who = player.id})
    else
      local targets = table.filter(room:getOtherPlayers(player), function(p) return p:getMark("@[:]yijin") == 0 end)
      if #targets == 0 then return false end
      local _, dat = room:askForUseActiveSkill(player, "yijin_active", "#yijin-choose", false)
      local to = dat and room:getPlayerById(dat.targets[1]) or table.random(targets)
      local mark = player:getMark("@[:]yijin_owner")
      local choice = dat and dat.interaction or table.random(mark)
      table.removeOne(mark, choice)
      room:setPlayerMark(player, "@[:]yijin_owner", mark)
      room:setPlayerMark(to, "@[:]yijin", choice)
      if table.contains({"yijin_wushi", "yijin_houren", "yijin_tongshen"}, choice) then
        player:broadcastSkillInvoke(self.name, 1)
        room:notifySkillInvoked(player, self.name, "support")
      else
        player:broadcastSkillInvoke(self.name, 2)
        room:notifySkillInvoked(player, self.name, "control")
      end
    end
  end,
}
local yijin_active = fk.CreateActiveSkill{
  name = "yijin_active",
  mute = true,
  card_num = 0,
  target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = U.getMark(Self, "@[:]yijin_owner") }
  end,
  prompt = function (self)
    return self.interaction.data and Fk:translate(":"..self.interaction.data) or ""
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return target:getMark("@[:]yijin") == 0
    end
  end,
}
local yijin_trigger = fk.CreateTriggerSkill{
  name = "#yijin_trigger",
  mute = true,
  events = {fk.DrawNCards, fk.EventPhaseChanging, fk.TurnEnd, fk.EventPhaseStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    local mark = player:getMark("@[:]yijin")
    if target == player and mark ~= 0 then
      if event == fk.DrawNCards then
        return mark == "yijin_wushi"
      elseif event == fk.TurnEnd then
        return player:isWounded() and mark == "yijin_houren"
      elseif event == fk.EventPhaseChanging then
        return (data.to == Player.Draw and mark == "yijin_yongbi") or
          ((data.to == Player.Play or data.to == Player.Discard) and mark == "yijin_jinmi")
      elseif event == fk.EventPhaseStart then
        return player.phase == Player.Play and mark == "yijin_guxiong"
      elseif event == fk.DamageInflicted then
        return data.damageType ~= fk.ThunderDamage and mark == "yijin_tongshen"
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local src = table.find(room.alive_players, function(p) return p:hasSkill("yijin", true) end)
    if event == fk.DrawNCards then
      if src then
        src:broadcastSkillInvoke("yijin", 1)
        room:notifySkillInvoked(src, "yijin", "support")
      end
      data.n = data.n + 4
    elseif event == fk.TurnEnd then
      if src then
        src:broadcastSkillInvoke("yijin", 1)
        room:notifySkillInvoked(src, "yijin", "support")
      end
      room:recover({
        who = player,
        num = math.min(3, player:getLostHp()),
        recoverBy = player,
        skillName = "yijin",
      })
    elseif event == fk.EventPhaseChanging then
      if src then
        src:broadcastSkillInvoke("yijin", 2)
        room:notifySkillInvoked(src, "yijin", "control")
      end
      return true
    elseif event == fk.EventPhaseStart then
      if src then
        src:broadcastSkillInvoke("yijin", 2)
        room:notifySkillInvoked(src, "yijin", "control")
      end
      room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 3)
      room:loseHp(player, 1, "yijin")
    elseif event == fk.DamageInflicted then
      if src then
        src:broadcastSkillInvoke("yijin", 1)
        room:notifySkillInvoked(src, "yijin", "support")
      end
      return true
    end
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@[:]yijin") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@[:]yijin", 0)
  end,
}
local yijin_targetmod = fk.CreateTargetModSkill{
  name = "#yijin_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@[:]yijin") == "yijin_wushi" and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
local guanzong = fk.CreateActiveSkill{
  name = "guanzong",
  anim_type = "special",
  card_num = 0,
  target_num = 2,
  prompt = "#guanzong",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < 2 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.tos[1])
    local to = room:getPlayerById(effect.tos[2])
    room:doIndicate(from.id, {to.id})
    room:damage{
      from = from,
      to = to,
      damage = 1,
      skillName = self.name,
      isVirtualDMG = true,
    }
  end,
}
Fk:addSkill(yijin_active)
yijin:addRelatedSkill(yijin_trigger)
yijin:addRelatedSkill(yijin_targetmod)
caosong:addSkill(yijin)
caosong:addSkill(guanzong)
Fk:loadTranslationTable{
  ["mobile__caosong"] = "曹嵩",
  ["#mobile__caosong"] = "舆金贾权",
  ["yijin"] = "亿金",
  [":yijin"] = "锁定技，游戏开始时，你获得6枚“金”标记；回合开始时，若你没有“金”，你死亡。出牌阶段开始时，你令一名没有“金”的其他角色获得一枚“金”和"..
  "对应的效果直到其下回合结束：<br>膴士：摸牌阶段摸牌数+4、出牌阶段使用【杀】次数上限+1；<br>厚任：回合结束时回复3点体力；<br>"..
  "贾凶：出牌阶段开始时失去1点体力，本回合手牌上限-3；<br>拥蔽：跳过摸牌阶段；<br>通神：防止受到的非雷电伤害；<br>金迷：跳过出牌阶段和弃牌阶段。",
  ["guanzong"] = "惯纵",
  [":guanzong"] = "出牌阶段限一次，你可以令一名其他角色<font color='red'>视为</font>对另一名其他角色造成1点伤害。",
  ["yijin_active"] = "亿金",
  ["#yijin_trigger"] = "亿金",
  ["@[:]yijin_owner"] = "亿金",
  ["@[:]yijin"] = "",
  ["#yijin-choose"] = "亿金：将一种“金”交给一名其他角色",
  ["@$yijin"] = "金",
  ["yijin_wushi"] = "膴士",
  [":yijin_wushi"] = "摸牌阶段摸牌数+4、出牌阶段使用【杀】次数+1",
  ["yijin_houren"] = "厚任",
  [":yijin_houren"] = "回合结束时回复3点体力",
  ["yijin_guxiong"] = "贾凶",
  [":yijin_guxiong"] = "出牌阶段开始时失去1点体力，手牌上限-3",
  ["yijin_yongbi"] = "拥蔽",
  [":yijin_yongbi"] = "跳过摸牌阶段",
  ["yijin_tongshen"] = "通神",
  [":yijin_tongshen"] = "防止受到的非雷电伤害",
  ["yijin_jinmi"] = "金迷",
  [":yijin_jinmi"] = "跳过出牌阶段和弃牌阶段",
  ["#guanzong"] = "惯纵：选择两名角色，<font color='red'>视为</font>第一名角色对第二名角色造成1点伤害",

  ["$yijin1"] = "吾家资巨万，无惜此两贯三钱！",
  ["$yijin2"] = "小儿持金过闹市，哼！杀人何需我多劳！",
  ["$yijin3"] = "普天之下，竟有吾难市之职？",
  ["$guanzong1"] = "汝为叔父，怎可与小辈计较！",
  ["$guanzong2"] = "阿瞒生龙活虎，汝切勿胡言！",
  ["~mobile__caosong"] = "长恨人心不如水，等闲平地起波澜……",
}

local peixiu = General(extension, "peixiu", "qun", 3)
peixiu.subkingdom = "jin"
local xingtu = fk.CreateTriggerSkill{
  name = "xingtu",
  events = {fk.CardUsing},
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and data.card.number > 0 and
      type((data.extra_data or {}).xingtuNumber) == "number" and
      (data.extra_data or {}).xingtuNumber % data.card.number == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local lastNumber = player:getMark("@xingtu")
    local realNumber = math.max(data.card.number, 0)
    player.room:setPlayerMark(player, "@xingtu", realNumber)
    if lastNumber > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.xingtuNumber = lastNumber
    end
  end,
}
local xingtuBuff = fk.CreateTargetModSkill{
  name = "#xingtu-buff",
  residue_func = function(self, player, skill, scope, card)
    return (player:hasSkill(self) and player:getMark("@xingtu") > 0 and card and card.number > 0 and
      card.number % player:getMark("@xingtu") == 0) and 999 or 0
  end,
}
local juezhi = fk.CreateActiveSkill{
  name = "juezhi",
  anim_type = "drawcard",
  min_card_num = 2,
  can_use = function(self, player)
    return true
  end,
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local number = 0
    for _, id in ipairs(effect.cards) do
      number = number + math.max(Fk:getCardById(id).number, 0)
    end
    number = number % 13
    number = number == 0 and 13 or number
    room:throwCard(effect.cards, self.name, from, from)
    if from.dead then return end
    local randomId = room:getCardsFromPileByRule(".|" .. number)
    if #randomId > 0 then
      room:obtainCard(from, randomId[1], true, fk.ReasonPrey)
    end
  end,
}
xingtu:addRelatedSkill(xingtuBuff)
peixiu:addSkill(xingtu)
peixiu:addSkill(juezhi)
Fk:loadTranslationTable{
  ["peixiu"] = "裴秀",
  ["#peixiu"] = "晋国开秘",
  ["xingtu"] = "行图",
  [":xingtu"] = "锁定技，当你使用牌时，若此牌的点数为X的因数，你摸一张牌；你使用点数为X的倍数的牌无次数限制（X为你使用的上一张牌的点数）。",
  ["juezhi"] = "爵制",
  [":juezhi"] = "出牌阶段，你可以弃置至少两张牌，然后从牌堆中随机获得一张点数为X的牌（X为以此法弃置的牌点数和与13的余数，若余数为0则改为13）。",
  ["@xingtu"] = "行图",

  ["$xingtu1"] = "制图之体有六，缺一不可言精。",
  ["$xingtu2"] = "图设分率，则宇内地域皆可绘于一尺。",
  ["$juezhi1"] = "复设五等之制，以解天下土崩之势。",
  ["$juezhi2"] = "表为建爵五等，实则藩卫帝室。",
  ["~peixiu"] = "既食寒石散，便不可饮冷酒啊……",
}

local yangfu = General(extension, "yangfu", "wei", 3)
local jiebing = fk.CreateTriggerSkill{
  name = "jiebing",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() and p ~= data.from end)
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#jiebing-choose", self.name, false)
    local to = room:getPlayerById(tos[1])
    local id = table.random(to:getCardIds("he"))
    room:obtainCard(player, id, false, fk.ReasonPrey)
    if not table.contains(player.player_cards[Player.Hand], id) then return end
    player:showCards({id})
    if Fk:getCardById(id).type == Card.TypeEquip and not player:isProhibited(player, Fk:getCardById(id)) then
      room:useCard({
        from = player.id,
        tos = {{player.id}},
        card = Fk:getCardById(id),
      })
    end
  end,
}
local hannan = fk.CreateActiveSkill{
  name = "hannan",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#hannan",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    local from, to
    if pindian.results[target.id].winner == player then
      from, to = player, target
    elseif pindian.results[target.id].winner == target then
      from, to = target, player
    end
    if to and not to.dead then
      room:damage{
        from = from,
        to = to,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
yangfu:addSkill(jiebing)
yangfu:addSkill(hannan)
Fk:loadTranslationTable{
  ["yangfu"] = "杨阜",
  ["#yangfu"] = "勇撼雄狮",

  ["jiebing"] = "借兵",
  [":jiebing"] = "锁定技，当你受到伤害后，你选择除伤害来源外的一名其他角色，随机获得其一张牌并展示之，若此牌为装备牌，则你使用之。",
  ["hannan"] = "扞难",
  [":hannan"] = "出牌阶段限一次，你可以与一名其他角色拼点，拼点赢的角色对拼点没赢的角色造成1点伤害。",
  ["#jiebing-choose"] = "借兵：选择一名角色，随机获得其一张牌",
  ["#hannan"] = "扞难：你可以拼点，赢的角色对没赢的角色造成1点伤害！",

  ["$jiebing1"] = "敌寇势大，情况危急，只能多谢阁下。",
  ["$jiebing2"] = "将军借兵之恩，阜退敌后自当报还。",
  ["$hannan1"] = "贼寇虽勇，阜亦戮力以捍！",
  ["$hannan2"] = "纵使信布之勇，亦非无策可当！",
  ["~yangfu"] = "汝背父叛君，吾誓，杀……",
}

local qianzhao = General(extension, "qianzhao", "wei", 4)
local shihe = fk.CreateActiveSkill{
  name = "shihe",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#shihe",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      if target.dead then return end
      local mark = target:getMark("@@shihe")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, player.id)
      if room.settings.gameMode == "m_1v2_mode" or room.settings.gameMode == "m_2v2_mode" then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if p.role == player.role then
            table.insertIfNeed(mark, p.id)
          end
        end
      end
      room:setPlayerMark(target, "@@shihe", mark)
    elseif not player.dead and not player:isNude() then
      local id = table.random(player:getCardIds("he"))
      room:throwCard({id}, self.name, player, player)
    end
  end,
}
local shihe_trigger = fk.CreateTriggerSkill{
  name = "#shihe_trigger",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target and target:getMark("@@shihe") ~= 0 and data.to == player and table.contains(target:getMark("@@shihe"), player.id)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("shihe")
    room:notifySkillInvoked(player, "shihe", "defensive")
    return true
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@shihe") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@shihe", 0)
  end,
}
local zhenfu = fk.CreateTriggerSkill{
  name = "zhenfu",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and target:hasSkill(self) and player.phase == Player.Finish then
      local events = player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            return true
          end
        end
      end, Player.HistoryTurn)
      return #events > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, "#zhenfu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeShield(room:getPlayerById(self.cost_data), 1)
  end,
}
shihe:addRelatedSkill(shihe_trigger)
qianzhao:addSkill(shihe)
qianzhao:addSkill(zhenfu)
Fk:loadTranslationTable{
  ["qianzhao"] = "牵招",
  ["#qianzhao"] = "威风远振",
  ["shihe"] = "势吓",
  [":shihe"] = "出牌阶段限一次，你可以与一名其他角色拼点，若你赢，直到其下回合结束，防止其对友方角色造成的伤害；没赢，你随机弃置一张牌。",
  ["zhenfu"] = "镇抚",
  [":zhenfu"] = "结束阶段，若你本回合因弃置失去过牌，你可以令一名其他角色获得1点护甲。",
  ["#shihe"] = "势吓：你可以拼点，若赢，防止其对你造成伤害；若没赢，你随机弃置一张牌",
  ["@@shihe"] = "势吓",
  ["#zhenfu-choose"] = "镇抚：你可以令一名其他角色获得1点护甲",

  ["$shihe1"] = "此举关乎福祸，还请峭王明察！",
  ["$shihe2"] = "汉乃天朝上国，岂是辽东下郡可比？",
  ["$zhenfu1"] = "储资粮，牧良畜，镇外贼，抚黎庶。",
  ["$zhenfu2"] = "通民户十万余众，镇大小夷虏晏息。",
  ["~qianzhao"] = "治边数载，虽不敢称功，亦可谓无过……",
}

local pengyang = General(extension, "pengyang", "shu", 3)
local changeDaming = function (player, n)
  local room = player.room
  local mark = type(player:getMark("@daming")) == "string" and 0 or player:getMark("@daming")
  mark = mark + n
  room:setPlayerMark(player, "@daming", mark == 0 and "0" or mark)
  room:broadcastProperty(player, "MaxCards")
end
local daming = fk.CreateTriggerSkill{
  name = "daming",
  anim_type = "control",
  events = {fk.GameStart},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    changeDaming (player, 1)
  end,
  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self and target == player
    else
      return target == player and player:hasSkill(self, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = room:getOtherPlayers(player)
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self, true) then
        table.forEach(targets, function(p)
          room:handleAddLoseSkills(p, "daming_other&", nil, false, true)
        end)
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      table.forEach(targets, function(p)
        room:handleAddLoseSkills(p, "-daming_other&", nil, false, true)
      end)
    end
  end,
}
local daming_other = fk.CreateActiveSkill{
  name = "daming_other&",
  mute = true,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and not player:isNude() then
      return table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill("daming") and p ~= player end)
    end
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):hasSkill("daming") and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local py = room:getPlayerById(effect.tos[1])
    room:notifySkillInvoked(py, "daming")
    py:broadcastSkillInvoke("daming")
    local get = effect.cards[1]
    local cardType = Fk:getCardById(get):getTypeString()
    room:obtainCard(py, get, false, fk.ReasonGive)
    local targets = table.simpleClone(room:getOtherPlayers(py))
    table.removeOne(targets, player)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(py, table.map(targets, Util.IdMapper), 1, 1,
        "#daming-choose::"..player.id..":"..cardType..":"..Fk:getCardById(get):toLogString(), self.name, false)
      local to = room:getPlayerById(tos[1])
      if table.find(to:getCardIds("he"), function(id) return Fk:getCardById(id):getTypeString() == cardType end) then
        local give = room:askForCard(to, 1, 1 ,true, self.name, false, ".|.|.|.|.|"..cardType, "#daming-give::"..player.id..":"..cardType)
        if #give > 0 and not player.dead then
          py:broadcastSkillInvoke("daming")
          room:obtainCard(player, give[1], false, fk.ReasonGive)
          changeDaming (py, 1)
          return
        end
      end
    end
    if table.contains(py:getCardIds("he"), get) and not player.dead then
      room:obtainCard(player, get, false, fk.ReasonGive)
    end
  end,
}
pengyang:addSkill(daming)
Fk:addSkill(daming_other)
local xiaoni = fk.CreateViewAsSkill{
  name = "xiaoni",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card.trueName == "slash" or(card.type == Card.TypeTrick and card.is_damage_card)) and not card.is_derived and
        ((Fk.currentResponsePattern == nil and Self:canUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and self.interaction.data
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and
      type(player:getMark("@daming")) == "number" and player:getMark("@daming") > 0
  end,
}
local xiaoni_trigger = fk.CreateTriggerSkill{
  name = "#xiaoni_trigger",
  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return player == target and table.contains(data.card.skillNames, "xiaoni")
  end,
  on_refresh = function(self, event, target, player, data)
    changeDaming (player, -#TargetGroup:getRealTargets(data.tos))
  end,
}
xiaoni:addRelatedSkill(xiaoni_trigger)
local xiaoni_maxcards = fk.CreateMaxCardsSkill{
  name = "#xiaoni_maxcards",
  fixed_func = function(self, player)
    if player:hasSkill(self) then
      local mark = type(player:getMark("@daming")) == "string" and 0 or player:getMark("@daming")
      return math.max(0, math.min(mark, player.hp))
    end
  end
}
xiaoni:addRelatedSkill(xiaoni_maxcards)
pengyang:addSkill(xiaoni)
Fk:loadTranslationTable{
  ["pengyang"] = "彭羕",
  ["#pengyang"] = "难别菽麦",
  ["illustrator:pengyang"] = "铁杵文化",
  ["daming"] = "达命",
  [":daming"] = "①游戏开始时，你获得1点“达命”值；②其他角色的出牌阶段限一次，其可以交给你一张牌，然后你选择另一名其他角色。若后者有相同类型的牌，"..
  "则后者须交给前者一张相同类型的牌且你获得1点“达命”值，否则你将以此法获得的牌交给前者。",
  ["@daming"] = "达命",
  ["daming_other&"] = "达命[给牌]",
  [":daming_other&"] = "出牌阶段限一次，你可以交给彭羕一张牌，然后其选择另一名其他角色。若该角色有相同类型的牌，则该角色须交给你一张相同类型的牌且"..
  "彭羕获得1点“达命”值，否则彭羕将获得的牌交还给你。",
  ["#daming-choose"] = "达命：选择一名其他角色，若其有%arg，则须交给%dest一张%arg且你获得1点“达命”值，否则你将%arg2交给%dest",
  ["#daming-give"] = "达命：你须交给%dest一张%arg",
  ["xiaoni"] = "嚣逆",
  [":xiaoni"] = "①出牌阶段限一次，若你的“达命”值大于0，你可以将一张牌当任意一种【杀】或伤害类锦囊牌使用，然后你减少此牌目标数点“达命”值。<br>"..
  "②你的手牌上限等于X（X为“达命”值，且至多为你的体力值）。",

  ["$daming1"] = "幸蒙士元斟酌，诣公于葭萌，达命于蜀川。",
  ["$daming2"] = "论治图王，助吾主成就大业。",
  ["$daming3"] = "心大志广，愧公知遇之恩。",
  ["$xiaoni1"] = "织席贩履之辈，果无用人之能乎？",
  ["$xiaoni2"] = "古今天下，岂有重屠沽之流而轻贤达者乎？",
  ["~pengyang"] = "招祸自咎，无不自己……",
}

local guonvwang = General(extension, "mobile__guozhao", "wei", 3, 3, General.Female)
local yichong = fk.CreateTriggerSkill{
  name = "yichong",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseStart then
      return target == player and player.phase == Player.Start
    elseif event == fk.AfterCardsMove then
      local mark = player:getMark("@yichong")
      if type(mark) ~= "table" or mark[1] > 0 then return false end
      mark = player:getMark("yichong_target")
      if type(mark) ~= "table" then return false end
      local room = player.room
      local to = room:getPlayerById(mark[1])
      if to == nil or to.dead then return false end
      for _, move in ipairs(data) do
        if move.to == mark[1] and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == to and
            Fk:getCardById(id):getSuitString(true) == mark[2] then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
        return p.id end), 1, 1, "#yichong-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    elseif event == fk.AfterCardsMove then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:getPlayerById(self.cost_data)
      local suits = {"log_spade", "log_club", "log_heart", "log_diamond"}
      local choice = room:askForChoice(player, suits, self.name)
      local cards = table.filter(to:getCardIds({Player.Equip}), function (id)
        return Fk:getCardById(id):getSuitString(true) == choice
      end)
      local hand = to:getCardIds("h")
      for _, id in ipairs(hand) do
        if Fk:getCardById(id):getSuitString(true) == choice then
          table.insert(cards, id)
          break
        end
      end
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      end
      if not (player.dead or to.dead) then
        local mark = player:getMark("yichong_target")
        if type(mark) == "table" then
          local orig_to = room:getPlayerById(mark[1])
          local mark2 = orig_to:getMark("@yichong_que")
          if type(mark2) == "table" then
            table.removeOne(mark2, mark[2])
            room:setPlayerMark(orig_to, "@yichong_que", #mark2 > 0 and mark2 or 0)
          end
        end
        local mark2 = type(to:getMark("@yichong_que")) == "table" and to:getMark("@yichong_que") or {}
        table.insert(mark2, choice)
        room:setPlayerMark(to, "@yichong_que", mark2)
        room:setPlayerMark(player, "yichong_target", {self.cost_data, choice})
        room:setPlayerMark(player, "@yichong", {0})
      end
    else
      local mark = player:getMark("@yichong")
      if type(mark) ~= "table" or mark[1] > 0 then return false end
      local x = 1 - mark[1]
      mark = player:getMark("yichong_target")
      if type(mark) ~= "table" then return false end
      local to = room:getPlayerById(mark[1])
      if to == nil or to.dead then return false end
      local cards = {}
      for _, move in ipairs(data) do
        if move.to == mark[1] and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == to and
                Fk:getCardById(id):getSuitString(true) == mark[2] then
              table.insert(cards, id)
            end
          end
        end
      end
      if #cards == 0 then
        return false
      elseif #cards > x then
        cards = table.random(cards, x)
      end
      room:setPlayerMark(player, "@yichong", {1-x+#cards})
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    end
  end,

  refresh_events = {fk.TurnStart, fk.EventLoseSkill, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventLoseSkill and data ~= self then return false end
    return player == target and type(player:getMark("yichong_target")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("yichong_target")
    local to = room:getPlayerById(mark[1])
    local mark2 = to:getMark("@yichong_que")
    if type(mark2) == "table" then
      table.removeOne(mark2, mark[2])
      room:setPlayerMark(to, "@yichong_que", #mark2 > 0 and mark2 or 0)
    end
    room:setPlayerMark(player, "yichong_target", 0)
    room:setPlayerMark(player, "@yichong", 0)
  end,
}
local wufei = fk.CreateTriggerSkill{
  name = "wufei",
  events = {fk.TargetSpecified, fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player ~= target then return false end
    local mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end
    local to = player.room:getPlayerById(mark[1])
    if to == nil or to.dead then return false end
    if event == fk.TargetSpecified then
      return data.firstTarget and (data.card.trueName == "slash" or (data.card:isCommonTrick() and data.card.is_damage_card))
    elseif event == fk.Damaged then
      return to.hp > 3
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      return true
    end
    local mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#wufei-invoke::"..mark[1]) then
      room:doIndicate(player.id, {mark[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end
    local to = player.room:getPlayerById(mark[1])
    if to == nil or to.dead then return false end
    player:broadcastSkillInvoke(self.name)
    if event == fk.TargetSpecified then
      player.room:notifySkillInvoked(player, self.name, "control")
      data.extra_data = data.extra_data or {}
      data.extra_data.wufei = mark[1]
    else
      player.room:notifySkillInvoked(player, self.name, "masochism")
      player.room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
    end
  end,

  refresh_events = {fk.PreDamage},
  can_refresh = function(self, event, target, player, data)
    if data.card then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return use.extra_data and use.extra_data.wufei
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data[1]
      data.from = room:getPlayerById(use.extra_data.wufei)
    end
  end,
}
guonvwang:addSkill(yichong)
guonvwang:addSkill(wufei)
Fk:loadTranslationTable{
  ["mobile__guozhao"] = "郭女王",
  ["#mobile__guozhao"] = "文德皇后",
  ["yichong"] = "易宠",
  [":yichong"] = "准备阶段，你可以选择一名其他角色并指定一种花色，获得其所有该花色的装备和一张该花色的手牌，并令其获得“雀”标记直到你下个回合开始"..
  "（若场上已有“雀”标记则转移给该角色）。拥有“雀”标记的角色获得你指定花色的牌时，你获得此牌（你至多因此“雀”标记获得一张牌）。",
  ["wufei"] = "诬诽",
  [":wufei"] = "你使用【杀】或伤害类普通锦囊指定目标后，令拥有“雀”标记的其他角色代替你成为伤害来源。"..
  "你受到伤害后，若拥有“雀”标记的角色体力值大于3，你可以令其受到1点伤害。",

  ["#yichong-choose"] = "你可以发动 易宠，选择一名其他角色，获得其一种花色的所有牌",
  ["@yichong_que"] = "雀",
  ["@yichong"] = "易宠",
  ["#wufei-invoke"] = "你可发动 诬诽，令%dest受到1点伤害",

  ["$yichong1"] = "处椒房之尊，得陛下隆宠！",
  ["$yichong2"] = "三千宠爱？当聚于我一身！",
  ["$wufei1"] = "巫蛊实乃凶邪之术，陛下不可不察！",
  ["$wufei2"] = "妾不该多言，只怕陛下为其所害。",
  ["~mobile__guozhao"] = "不觉泪下……沾衣裳……",
}

local hansui = General(extension, "mobile__hansui", "qun", 4)
hansui.shield = 1
local mobile__niluan = fk.CreateTriggerSkill{
  name = "mobile__niluan",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Finish and not target.dead and target ~= player then
      return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == target.id then
          for _, pid in ipairs(TargetGroup:getRealTargets(use.tos)) do
            if pid ~= target.id then
              return true
            end
          end
        end
      end, Player.HistoryTurn) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askForUseCard(player, "slash", "slash", "#mobile__niluan-slash:"..target.id, true,
     {exclusive_targets = {target.id} , bypass_distances = true})
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = self.cost_data
    use.extraUse = true
    room:useCard(use)
    if use.damageDealt and use.damageDealt[target.id] and not player.dead and not target:isNude() then
      local cid = room:askForCardChosen(player, target, "he", self.name)
      room:throwCard({cid}, self.name, target, player)
    end
  end,
}
hansui:addSkill(mobile__niluan)
local mobile__xiaoxi = fk.CreateViewAsSkill{
  name = "mobile__xiaoxi",
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
hansui:addSkill(mobile__xiaoxi)
Fk:loadTranslationTable{
  ["mobile__hansui"] = "韩遂",
  ["#mobile__hansui"] = "雄踞北疆",
  ["mobile__niluan"] = "逆乱",
  [":mobile__niluan"] = "其他角色的结束阶段，若其本回合对除其以外的角色使用过牌，你可以对其使用一张【杀】（无距离限制），然后此【杀】结算结束后，若此【杀】对其造成了伤害，你弃置其一张牌。",
  ["mobile__xiaoxi"] = "骁袭",
  [":mobile__xiaoxi"] = "你可以将一张黑色牌当【杀】使用或打出。",
  ["#mobile__niluan-slash"] = "逆乱：你可以对 %src 使用一张【杀】",

  ["$mobile__niluan1"] = "不是你死，便是我亡！",
  ["$mobile__niluan2"] = "后无退路，只有一搏！",
  ["$mobile__xiaoxi1"] = "看你如何躲过！",
  ["$mobile__xiaoxi2"] = "小贼受死！",
  ["~mobile__hansui"] = "称雄三十载，一败化为尘……",
}

--其他：司马孚 来敏 李遗
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

local liwei = General(extension, "mobile__liwei", "shu", 4)
local mobile__jiaohua = fk.CreateActiveSkill{
  name = "mobile__jiaohua",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__jiaohua",
  interaction = function(self)
    local choices = {"basic", "trick", "equip"}
    for i = 3, 1, -1 do
      if Self:getMark("mobile__jiaohua_"..choices[i]) > 0 then
        table.remove(choices, i)
      end
    end
    if #choices == 0 then return false end
    return UI.ComboBox {choices = choices}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, self.name.."_"..self.interaction.data, 1)
    if table.every({"basic", "trick", "equip"}, function(type) return player:getMark(self.name.."_"..type) > 0 end) then
      table.forEach({"basic", "trick", "equip"}, function(type) room:setPlayerMark(player, self.name.."_"..type, 0) end)
    end
    local card = room:getCardsFromPileByRule(".|.|.|.|.|"..self.interaction.data)
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
liwei:addSkill(mobile__jiaohua)
Fk:loadTranslationTable{
  ["mobile__liwei"] = "李遗",
  ["#mobile__liwei"] = "伏被俞元",
  ["mobile__jiaohua"] = "教化",
  [":mobile__jiaohua"] = "出牌阶段限两次，你可以令一名角色从牌堆获得一张未以此法选择过的类别的牌；所有类别均被选择后，重置选择过的类别。",
  ["#mobile__jiaohua"] = "教化：令一名角色获得你选择的类别的牌",
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
Fk:loadTranslationTable{
  ["mobile__huban"] = "胡班",
  ["#mobile__huban"] = "昭义烈勇",
  ["~mobile__huban"] = "生虽微而志不可改，位虽卑而节不可夺……",
}

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
      true
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
Fk:loadTranslationTable{
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
}

yilie:addRelatedSkill(yilieDelay)
huban:addSkill(yilie)

local chengui = General(extension, "mobile__chengui", "qun", 3)
Fk:loadTranslationTable{
  ["mobile__chengui"] = "陈珪",
  ["#mobile__chengui"] = "弄辞巧掇",
  ["~mobile__chengui"] = "布非忠良之士，将军宜早图之……",
}

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
          to = room:askForChoosePlayers(player, targets, 1, 1, "#guimou-choose", self.name, true)[1]
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
            true
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
        choice = room:askForChoice(player, choices, self.name)
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
Fk:loadTranslationTable{
  ["guimou"] = "诡谋",
  [":guimou"] = "锁定技，游戏开始时你随机选择一项，或回合结束时你选择一项：直到你的下个准备阶段开始时，1.记录使用牌最少的其他角色；" ..
  "2.记录弃置牌最少的其他角色；3.记录获得牌最少的其他角色。准备阶段开始时，你选择被记录的一名角色，观看其手牌并可选择其中一张牌，" ..
  "弃置此牌或将此牌交给另一名其他角色。",
  ["@[private]guimou"] = "诡谋",
  ["#guimou-choose"] = "诡谋：你选择一项，你下个准备阶段令该项值最少的角色受到惩罚",
  ["guimou_use"] = "使用牌",
  ["guimou_discard"] = "弃置牌",
  ["guimou_gain"] = "获得牌",
  ["guimou_option_give"] = "给出此牌",
  ["guimou_option_discard"] = "弃置此牌",
  ["#guimou-choose"] = "诡谋：选择其中一名角色查看其手牌，可选择其中一张给出或弃置",
  ["#guimou-give"] = "诡谋：将 %arg 交给另一名其他角色",
  ["#guimou-view"] = "当前观看的是 %dest 的手牌",

  ["$guimou1"] = "不过卒合之师，岂是将军之敌乎？",
  ["$guimou2"] = "连鸡势不俱栖，依珪计便可一一解离。",
}

chengui:addSkill(guimou)

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
Fk:loadTranslationTable{
  ["zhouxian"] = "州贤",
  [":zhouxian"] = "锁定技，当你成为其他角色使用伤害牌的目标时，你亮出牌堆顶三张牌，然后其须弃置一张亮出牌中含有的一种类别的牌，否则取消此目标。",
  ["#zhouxian-discard"] = "州贤：请弃置一张亮出牌中含有的一种类别的牌，否则取消 %arg 对 %dest 的目标",

  ["$zhouxian1"] = "今未有苛暴之乱，汝敢言失政之语。",
  ["$zhouxian2"] = "曹将军神武应期，如何以以身试祸。",
}

chengui:addSkill(zhouxian)

local muludawang = General(extension, "muludawang", "qun", 3)
muludawang.shield = 1
Fk:loadTranslationTable{
  ["muludawang"] = "木鹿大王",
  ["#muludawang"] = "八纳洞主",
  ["~muludawang"] = "啊啊，诸葛亮神人降世，吾等难挡天威。",
}

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
        player:usedSkillTimes(self.name, Player.HistoryTurn) < 5 and
        (
          table.contains({"m_1v2_mode", "brawl_mode"}, room.settings.gameMode) or
          table.find(room.alive_players, function(p) return p ~= player and p:distanceTo(player) > 1 end)
        )
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(
      room.alive_players,
      function(p)
        return
          table.contains({"m_1v2_mode", "brawl_mode"}, room.settings.gameMode) or
          (event == fk.Damage and player:distanceTo(p) < 3 or p:distanceTo(player) > 1)
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
Fk:loadTranslationTable{
  ["shoufa"] = "兽法",
  [":shoufa"] = "当你每回合首次造成伤害后，你可以选择你距离2以内的一名角色；每回合限五次，当你受到伤害后，" ..
  "你可以选择与你距离大于1的一名角色（若为斗地主，则以上选择角色均改为选择任一角色）。其随机执行一种效果：" ..
  "豹，其受到1点无来源伤害；鹰，你随机获得其一张牌；熊，你随机弃置其装备区里的一张牌；兔，其摸一张牌。",
  ["#shoufa-choose"] = "兽法：请选择一名角色令其执行野兽效果",
  ["shoufa_bao"] = "豹",
  ["shoufa_ying"] = "鹰",
  ["shoufa_xiong"] = "熊",
  ["shoufa_tu"] = "兔",

  ["$shoufa1"] = "毒蛇恶蝎，奉旨而行！",
  ["$shoufa2"] = "虎豹豺狼，皆听我令！",
}

muludawang:addSkill(shoufa)

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
Fk:loadTranslationTable{
  ["zhoulin"] = "咒鳞",
  [":zhoulin"] = "限定技，出牌阶段，若你有“兽法”，则你可以获得2点护甲并选择一种野兽效果，令你直到你的下个回合开始，" ..
  "“兽法”必定执行此野兽效果。",
  ["@zhoulin"] = "咒鳞",
  ["#zhoulin"] = "你可以选择一种野兽，令兽法直到你下回合开始前必定执行此效果",
  ["zhoulin_bao"] = "豹：受到伤害",
  ["zhoulin_ying"] = "鹰：被你获得牌",
  ["zhoulin_xiong"] = "熊：被你弃装备区牌",
  ["zhoulin_tu"] = "兔：摸牌",

  ["$zhoulin1"] = "料一山野书生，安识我南中御兽之术！",
  ["$zhoulin2"] = "本大王承天大法，岂与诸葛亮小计等同！",
}

zhoulin:addRelatedSkill(zhoulinRefresh)
muludawang:addSkill(zhoulin)

local yuxiang = fk.CreateTriggerSkill{
  name = "yuxiang",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = { fk.DamageInflicted },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.shield > 0 and data.damageType == fk.FireDamage
  end,
  on_trigger = function(self, event, target, player, data)
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
Fk:loadTranslationTable{
  ["yuxiang"] = "御象",
  [":yuxiang"] = "锁定技，若你有护甲，则你拥有以下效果：你计算与其他角色的距离-1；其他角色计算与你的距离+1；当你受到火焰伤害时，此伤害+1。",

  ["$yuxiang1"] = "额啊啊，好大的火光啊！",
}

yuxiang:addRelatedSkill(yuxiangDistance)
muludawang:addSkill(yuxiang)

return extension
