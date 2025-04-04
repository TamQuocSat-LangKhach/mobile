
--SP9：苏飞 贾逵 许贡 曹婴 鲍三娘 徐荣
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
      return table.find(room:getOtherPlayers(player, false), function (p)
        return p.id ~= data.from and not room:getPlayerById(data.from):isProhibited(p, data.card) and
          not (type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0)
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
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
  ["#mobile__sufei"] = "诤友投明",
  ["illustrator:mobile__sufei"] = "石蝉",
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
            room:obtainCard(to.id, id, false, fk.ReasonGive, player.id)
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
  ["#tongqu__jiakui"] = "肃齐万里",
  ["illustrator:tongqu__jiakui"] = "福州暗金", -- 皮肤 水到渠成
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
  derived_piles = "$mobile__biaozhao_message",
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseStart then
      return (player.phase == Player.Finish and not player:isNude()) or
      (player.phase == Player.Start and #player:getPile("$mobile__biaozhao_message") > 0)
    elseif #player:getPile("$mobile__biaozhao_message") > 0 then
      local numbers = {}
      for _, id in ipairs(player:getPile("$mobile__biaozhao_message")) do
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
        player:addToPile("$mobile__biaozhao_message", self.cost_data, false, self.name)
      else
        room:moveCards({
          from = player.id,
          ids = player:getPile("$mobile__biaozhao_message"),
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
        ids = player:getPile("$mobile__biaozhao_message"),
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
  ["$mobile__biaozhao_message"] = "表",
  ["#mobile__biaozhao-cost"] = "表召：可以将一张牌作为表置于武将牌上",
  ["#mobile__biaozhao-choose"] = "表召：令一名角色回复1点体力并摸三张牌",

  ["$mobile__biaozhao1"] = "孙策如秦末之项籍，如得时势，必有异志！",
  ["$mobile__biaozhao2"] = "贡谨奉此表，以使君明孙策之异！",
  ["$yechou_mobile__xugong1"] = "孙策小儿，你必还恶报！",
  ["$yechou_mobile__xugong2"] = "吾命丧黄泉，你也休想得安!",
  ["~mobile__xugong"] = "此表非我所写，岂可污我！",
}

local caoying = General(extension, "mobile__caoying", "wei", 4, 4, General.Female)
local lingren = fk.CreateTriggerSkill{
  name = "mobile__lingren",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and data.firstTarget and data.card.is_damage_card and
    player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
      return not room:getPlayerById(id).dead
    end)
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#mobile__lingren-invoke::" .. targets[1]) then
        room:doIndicate(player.id, targets)
        self.cost_data = targets
        return true
      end
    else
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#mobile__lingren-choose", self.name, true)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local choices = {"lingren_basic", "lingren_trick", "lingren_equip"}
    local yes = room:askForChoices(player, choices, 0, 3, self.name, "#mobile__lingren-choice::" .. to.id, false)
    for _, value in ipairs(yes) do
      table.removeOne(choices, value)
    end
    local right = 0
    for _, id in ipairs(to.player_cards[Player.Hand]) do
      local str = "lingren_"..Fk:getCardById(id):getTypeString()
      if table.contains(yes, str) then
        right = right + 1
        table.removeOne(yes, str)
      else
        table.removeOne(choices, str)
      end
    end
    right = right + #choices
    room:sendLog{
      type = "#mobile__lingren_result",
      from = player.id,
      arg = tostring(right),
    }
    if right > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.mobile__lingren = data.extra_data.mobile__lingren or {}
      table.insert(data.extra_data.mobile__lingren, to.id)
    end
    if right > 1 then
      player:drawCards(2, self.name)
    end
    if right > 2 then
      local skills = {}
      if not player:hasSkill("jianxiong", true) then
        table.insert(skills, "jianxiong")
      end
      if not player:hasSkill("xingshang", true) then
        table.insert(skills, "xingshang")
      end
      if #skills > 0 then
        room:setPlayerMark(player, self.name, skills)
        room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
      end
    end
  end,
}
local lingren_delay = fk.CreateTriggerSkill {
  name = "#mobile__lingren_delay",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or target ~= player then return false end
    local room = player.room
    local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not card_event then return false end
    local use = card_event.data[1]
    return use.extra_data and use.extra_data.mobile__lingren and table.contains(use.extra_data.mobile__lingren, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("mobile__lingren") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = player:getMark("mobile__lingren")
    room:setPlayerMark(player, "mobile__lingren", 0)
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, true, false)
  end,
}
local fujian = fk.CreateTriggerSkill {
  name = "mobile__fujian",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
    #player.room.alive_players > 1 and table.every(player.room.alive_players, function(p)
      return not p:isKongcheng()
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getHandcardNum()
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if p ~= player then
        x = math.min(x, p:getHandcardNum())
        table.insert(targets, p)
      end
    end
    local to = table.random(targets)
    room:doIndicate(player.id, {to.id})
    U.viewCards(player, table.random(to:getCardIds(Player.Hand), x), self.name, "$ViewCardsFrom:"..to.id)
  end,
}
lingren:addRelatedSkill(lingren_delay)
caoying:addSkill(lingren)
caoying:addSkill(fujian)
caoying:addRelatedSkill("jianxiong")
caoying:addRelatedSkill("xingshang")
AddWinAudio(caoying)
Fk:loadTranslationTable{
  ["mobile__caoying"] = "曹婴",
  ["#mobile__caoying"] = "龙城凤鸣",
  ["cv:mobile__caoying"] = "水原",
  ["illustrator:mobile__caoying"] = "DH",--锋芒毕露*曹婴 of 三国杀·移动版
  ["designer:mobile__caoying"] = "韩旭",
  ["mobile__lingren"] = "凌人",
  [":mobile__lingren"] = "每阶段限一次，当你于出牌阶段内使用【杀】或伤害类锦囊牌指定第一个目标后，"..
  "你可以猜测其中一名目标角色的手牌区中是否有基本牌、锦囊牌或装备牌。"..
  "若你猜对：至少一项，此牌对其造成的伤害+1；至少两项，你摸两张牌；三项，你获得〖奸雄〗和〖行殇〗直到你的下个回合开始。",
  ["mobile__fujian"] = "伏间",
  [":mobile__fujian"] = "锁定技，结束阶段，你随机观看一名其他角色的X张手牌（X为手牌数最少的角色的手牌数）。",

  ["#mobile__lingren-choose"] = "是否发动 凌人，猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["#mobile__lingren-invoke"] = "是否对%dest发动 凌人，猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["#mobile__lingren-choice"] = "凌人：猜测%dest的手牌中是否有基本牌、锦囊牌或装备牌",
  ["lingren_basic"] = "有基本牌",
  ["lingren_trick"] = "有锦囊牌",
  ["lingren_equip"] = "有装备牌",
  ["#mobile__lingren_result"] = "%from 猜对了 %arg 项",
  ["#mobile__lingren_delay"] = "凌人",

  ["$mobile__lingren1"] = "老将军虎威犹在，可惜命不久矣。",
  ["$mobile__lingren2"] = "此山已为我军所围，尔等若降，还可善终！",
  ["$mobile__fujian1"] = "以上智行间，则大功可成！",
  ["$mobile__fujian2"] = "五间之法，吾尽知而可用。",
  ["$jianxiong_mobile__caoying"] = "为大事者，当如祖父一般，眼界高远。",
  ["$xingshang_mobile__caoying"] = "将军忠魂不泯，应当厚葬。",
  ["~mobile__caoying"] = "吾虽身陨，无碍大魏之兴……",
  ["!mobile__caoying"] = "此战既胜，破蜀吞吴，指日可待！",
}

local baosanniang = General(extension, "mobile__baosanniang", "shu", 3, 3, General.Female)
local shuyong = fk.CreateTriggerSkill{
  name = "shuyong",
  anim_type = "control",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
    table.find(player.room:getOtherPlayers(player, false), function(p) return not p:isAllNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isAllNude() end), Util.IdMapper), 1, 1, "#shuyong-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
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
    and table.find(Fk:currentRoom().alive_players, function(p) return p:isMale() end)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if p:isMale() then
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

local xurong = General(extension, "mobile__xurong", "qun", 4)
local xionghuo = fk.CreateActiveSkill{
  name = "mobile__xionghuo",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__xionghuo-active",
  can_use = function(self, player)
    return player:getMark("@mobile__baoli") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("@mobile__baoli") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:removePlayerMark(player, "@mobile__baoli", 1)
    room:addPlayerMark(target, "@mobile__baoli", 1)
  end,

  on_lose = function (self, player)
    if table.every(player.room.alive_players, function (p)
      return not p:hasSkill(self, true)
    end) then
      for _, p in ipairs(player.room.alive_players) do
        if p:getMark("@mobile__baoli") > 0 then
          player.room:setPlayerMark(p, "@mobile__baoli", 0)
        end
      end
    end
  end,
}
local xionghuo_record = fk.CreateTriggerSkill{
  name = "#mobile__xionghuo_record",
  main_skill = xionghuo,
  anim_type = "offensive",
  events = {fk.GameStart, fk.DamageCaused, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xionghuo) then
      if event == fk.GameStart then
        return true
      elseif event == fk.DamageCaused then
        return target == player and data.to ~= player and data.to:getMark("@mobile__baoli") > 0
      else
        return target ~= player and target:getMark("@mobile__baoli") > 0 and target.phase == Player.Play
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("mobile__xionghuo")
    if event == fk.GameStart then
      room:addPlayerMark(player, "@mobile__baoli", 3)
    elseif event == fk.DamageCaused then
      room:doIndicate(player.id, {data.to.id})
      data.damage = data.damage + 1
    else
      room:doIndicate(player.id, {target.id})
      room:setPlayerMark(target, "@mobile__baoli", 0)
      local rand = math.random(1, target:isNude() and 2 or 3)
      if rand == 1 then
        room:damage {
          from = player,
          to = target,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = "mobile__xionghuo",
        }
        if not (player.dead or target.dead) then
          room:addTableMark(target, "mobile__xionghuo_prohibit-turn", player.id)
        end
      elseif rand == 2 then
        room:loseHp(target, 1, "mobile__xionghuo")
        if not target.dead then
          room:addPlayerMark(target, "MinusMaxCards-turn", 1)
        end
      else
        local cards = table.random(target:getCardIds(Player.Hand), 1)
        table.insertTable(cards, table.random(target:getCardIds(Player.Equip), 1))
        room:obtainCard(player, cards, false, fk.ReasonPrey)
      end
    end
  end,
}
local xionghuo_prohibit = fk.CreateProhibitSkill{
  name = "#mobile__xionghuo_prohibit",
  is_prohibited = function(self, from, to, card)
    return card.trueName == "slash" and table.contains(from:getTableMark("mobile__xionghuo_prohibit-turn"), to.id)
  end,
}
local shajue = fk.CreateTriggerSkill{
  name = "mobile__shajue",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and target.hp < 0 and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@mobile__baoli", 1)
    if data.damage and data.damage.card and U.hasFullRealCard(room, data.damage.card) then
      room:obtainCard(player, data.damage.card, true, fk.ReasonPrey)
    end
  end
}
xionghuo:addRelatedSkill(xionghuo_record)
xionghuo:addRelatedSkill(xionghuo_prohibit)
xurong:addSkill(xionghuo)
xurong:addSkill(shajue)
Fk:loadTranslationTable{
  ["mobile__xurong"] = "徐荣",
  ["#mobile__xurong"] = "玄菟战魔",
  ["cv:mobile__xurong"] = "曹真",
  ["designer:mobile__xurong"] = "Loun老萌",
  ["illustrator:mobile__xurong"] = "青岛磐蒲",-- 烬灭神骇*徐荣 of 三国杀·移动版
  ["mobile__xionghuo"] = "凶镬",
  [":mobile__xionghuo"] = "游戏开始时，你获得3个“暴戾”标记。出牌阶段，你可以交给一名其他角色一个“暴戾”标记，"..
  "你对有此标记的其他角色造成的伤害+1，且其出牌阶段开始时，移去“暴戾”并随机执行一项："..
  "1.受到1点火焰伤害且本回合不能对你使用【杀】；"..
  "2.流失1点体力且本回合手牌上限-1；"..
  "3.你随机获得其一张手牌和一张装备区里的牌。",
  ["mobile__shajue"] = "杀绝",
  [":mobile__shajue"] = "锁定技，其他角色进入濒死状态时，若其需要超过一张【桃】或【酒】救回，你获得一个“暴戾”标记且获得使其进入濒死状态的牌。",
  ["#mobile__xionghuo_record"] = "凶镬",
  ["@mobile__baoli"] = "暴戾",
  ["#mobile__xionghuo-active"] = "发动 凶镬，将“暴戾”交给其他角色",

  ["$mobile__xionghuo1"] = "战场上的懦夫，可不会有好结局！",
  ["$mobile__xionghuo2"] = "用最残忍的方式，碾碎敌人！",
  ["$mobile__shajue1"] = "现在才投降？有些太晚了哦。",
  ["$mobile__shajue2"] = "与我们为敌的人，一个都不用留。",
  ["~mobile__xurong"] = "死于战场……是个不错的结局……",
}

--SP10：丁原 傅肜 邓芝 陈登 张翼 张琪瑛 公孙康 周群
local dingyuan = General(extension, "dingyuan", "qun", 4)
local beizhu = fk.CreateActiveSkill{
  name = "beizhu",
  mute = true,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  prompt = "#beizhu-prompt",
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
    player:broadcastSkillInvoke(self.name, math.random(2))
    target:filterHandcards()
    local ids = table.filter(target:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == "slash" end)
    if #ids > 0 then
      U.viewCards(player, target:getCardIds("h"), self.name, "$ViewCardsFrom:"..target.id)
      room:setPlayerMark(player, "beizhu_slash", ids)
      for _, id in ipairs(ids) do
        local card = Fk:getCardById(id)
        if room:getCardOwner(id) == target and room:getCardArea(id) == Card.PlayerHand and card.trueName == "slash" and
          not player.dead and not target:isProhibited(player, card) and not target:prohibitUse(card) then
          room:useCard({
            from = target.id,
            tos = {{player.id}},
            card = card,
            extra_data = {beizhu_from = player.id},
            extraUse = true,
          })
        end
      end
    else
      local card_data = {}
      table.insert(card_data, { "$Hand", target:getCardIds("h") })
      if #target:getCardIds("e") > 0 then
        table.insert(card_data, { "$Equip", target:getCardIds("e") })
      end
      local throw = room:askForCardChosen(player, target, { card_data = card_data }, self.name, "#beizhu-throw:"..target.id)
      room:throwCard({throw}, self.name, target, player)
      local slash = room:getCardsFromPileByRule("slash")
      if #slash > 0 and not target.dead and not player.dead and room:askForSkillInvoke(player, self.name, nil, "#beizhu-draw:"..target.id) then
        room:obtainCard(target, slash[1], true, fk.ReasonJustMove, target.id, self.name)
      end
    end
  end,
}
local beizhu_trigger = fk.CreateTriggerSkill{
  name = "#beizhu_trigger",
  mute = true,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead and data.card then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        local use = e.data[1]
        return use.card == data.card and use.extra_data and use.extra_data.beizhu_from == player.id
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, _, player, data)
    player:broadcastSkillInvoke("beizhu", 3)
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
  ["#beizhu-throw"] = "备诛：请弃置 %src 一张牌",
  ["#beizhu-prompt"] = "备诛：你可以观看其他角色的手牌，若有【杀】，其对你使用【杀】；否则你弃置其牌",

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
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper), 1, 1,
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
  ["#mobile__xuewei_trigger"] = "血卫",

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
      table.find(player.room:getOtherPlayers(player, false), function(p) return not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p) return not p:isNude() end)
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
    room:obtainCard(to, cards, false, fk.ReasonGive)
  end,
}
local mobile__shuaiyan = fk.CreateTriggerSkill{
  name = "mobile__shuaiyan",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
  return target == player and player:hasSkill(self) and player.phase == Player.Discard and
    player:getHandcardNum() > 1 and 
    table.find(player.room:getOtherPlayers(player, false), function(p) return not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p) return not p:isNude() end)
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
      room:moveCardTo(c, Player.Hand, player, fk.ReasonGive, self.name, nil, false, to.id)
    end
  end,
}
mobile__dengzhi:addSkill(mobile__jimeng)
mobile__dengzhi:addSkill(mobile__shuaiyan)

Fk:loadTranslationTable{
  ["mobile__dengzhi"] = "邓芝",
  ["#mobile__dengzhi"] = "绝境外交家",
  ["illustrator:mobile__dengzhi"] = "齐名", -- 皮肤 出使东吴
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
    room:addTableMark(player, self.name, {effect.tos[1], self.interaction.data})
    room:throwCard(effect.cards, self.name, player, player)
  end,
}
local mobile__zhouxuan_trigger = fk.CreateTriggerSkill{
  name = "#mobile__zhouxuan_trigger",
  mute = true,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return table.find(player:getTableMark("mobile__zhouxuan"), function(m) return m[1] == target.id end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("mobile__zhouxuan")
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
      room:askForYiji(player, cards, nil, self.name, 3, 3, nil, cards)
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
local zhiyi = fk.CreateTriggerSkill{
  name = "zhiyi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and
      (#player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        return use.from == player.id and use.card.type == Card.TypeBasic
      end, Player.HistoryTurn) > 0 or
      #player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
        local use = e.data[1]
        return use.from == player.id and use.card.type == Card.TypeBasic
      end, Player.HistoryTurn) > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("zhiyi_cards") == 0 then
      room:setPlayerMark(player, "zhiyi_cards", U.getUniversalCards(room, "b"))
    end
    local names = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data[1]
      if use.from == player.id and use.card.type == Card.TypeBasic then
        table.insertIfNeed(names, use.card.name)
      end
    end, Player.HistoryTurn)
    room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
      local use = e.data[1]
      if use.from == player.id and use.card.type == Card.TypeBasic then
        table.insertIfNeed(names, use.card.name)
      end
    end, Player.HistoryTurn)
    local cards = table.filter(player:getMark("zhiyi_cards"), function (id)
      return table.contains(names, Fk:getCardById(id).name)
    end)
    local use = U.askForUseRealCard(room, player, cards, nil, self.name, "#zhiyi-use",
      {expand_pile = cards, bypass_times = true, extraUse = true}, true, true)
    if use then
      use = {
        card = Fk:cloneCard(use.card.name),
        from = player.id,
        tos = use.tos,
      }
      use.card.skillName = self.name
      room:useCard(use)
    else
      player:drawCards(1, self.name)
    end
  end,
}
zhangyi:addSkill(zhiyi)
Fk:loadTranslationTable{
  ["mobile__zhangyiy"] = "张翼",
  ["#mobile__zhangyiy"] = "亢锐怀忠",
  ["illustrator:mobile__zhangyiy"] = "王强",

  ["zhiyi"] = "执义",
  [":zhiyi"] = "锁定技，一名角色的结束阶段，若你本回合使用或打出过基本牌，你选择一项：1.视为使用任意一张你本回合使用或打出过的基本牌；2.摸一张牌。",
  ["#zhiyi-use"] = "执义：视为使用一张基本牌，或点“取消”摸一张牌",

  ["$zhiyi1"] = "岂可擅退而误国家之功？",
  ["$zhiyi2"] = "统摄不懈，只为破敌！",
  ["~mobile__zhangyiy"] = "唯愿百姓，不受此乱所害，哎……",
}

local zhangqiying = General(extension, "mobile__zhangqiying", "qun", 3, 3, General.Female)
local falu = fk.CreateTriggerSkill{
  name = "mobile__falu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        for _, move in ipairs(data) do
          if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
            self.cost_data = {}
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                local suit = Fk:getCardById(info.cardId):getSuitString()
                if player:getMark("@@mobile__falu" .. suit) == 0 then
                  table.insertIfNeed(self.cost_data, suit)
                end
              end
            end
            return #self.cost_data > 0
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local suits = {"spade", "club", "heart", "diamond"}
      for i = 1, 4, 1 do
        room:addPlayerMark(player, "@@mobile__falu" .. suits[i], 1)
      end
    else
      for _, suit in ipairs(self.cost_data) do
        room:addPlayerMark(player, "@@mobile__falu" .. suit, 1)
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    for i = 1, 4, 1 do
      room:setPlayerMark(player, "@@mobile__falu" .. suits[i], 0)
    end
  end,
}
local zhenyi = fk.CreateViewAsSkill{
  name = "mobile__zhenyi",
  anim_type = "support",
  pattern = "peach",
  prompt = "#mobile__zhenyi2",
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@@mobile__faluclub", 1)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("peach")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player)
    return player.dying and player:getMark("@@mobile__faluclub") > 0
  end,
}
local zhenyi_trigger = fk.CreateTriggerSkill {
  name = "#mobile__zhenyi_trigger",
  main_skill = zhenyi,
  events = {fk.AskForRetrial, fk.DamageCaused, fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhenyi) then
      if event == fk.AskForRetrial then
        return player:getMark("@@mobile__faluspade") > 0
      elseif event == fk.DamageCaused then
        return target == player and player:getMark("@@mobile__faluheart") > 0
      elseif event == fk.Damaged then
        return target == player and player:getMark("@@mobile__faludiamond") > 0 and data.damageType ~= fk.NormalDamage
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt
    if event == fk.AskForRetrial then
      prompt = "#mobile__zhenyi1::"..target.id
    elseif event == fk.DamageCaused then
      prompt = "#mobile__zhenyi3::"..data.to.id
    elseif event == fk.Damaged then
      prompt = "#mobile__zhenyi4"
    end
    return room:askForSkillInvoke(player, zhenyi.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zhenyi.name)
    if event == fk.AskForRetrial then
      room:notifySkillInvoked(player, zhenyi.name, "control")
      room:removePlayerMark(player, "@@mobile__faluspade", 1)
      local choice = room:askForChoice(player, {"mobile__zhenyi_spade", "mobile__zhenyi_heart"}, zhenyi.name)
      local new_card = Fk:cloneCard(data.card.name, choice == "mobile__zhenyi_spade" and Card.Spade or Card.Heart, 5)
      new_card.skillName = zhenyi.name
      new_card.id = data.card.id
      data.card = new_card
      room:sendLog{
        type = "#ChangedJudge",
        from = player.id,
        to = { data.who.id },
        arg2 = new_card:toLogString(),
        arg = zhenyi.name,
      }
      return true
    elseif event == fk.DamageCaused then
      room:notifySkillInvoked(player, zhenyi.name, "offensive")
      room:removePlayerMark(player, "@@mobile__faluheart", 1)
      local judge = {
        who = player,
        reason = zhenyi.name,
        pattern = ".|.|club,spade",
      }
      room:judge(judge)
      if judge.card.color == Card.Black then
        data.damage = data.damage + 1
      end
    elseif event == fk.Damaged then
      room:notifySkillInvoked(player, zhenyi.name, "masochism")
      room:removePlayerMark(player, "@@mobile__faludiamond", 1)
      local cards = {}
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|basic"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|trick"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|equip"))
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = zhenyi.name,
        })
      end
    end
  end,
}
local dianhua = fk.CreateTriggerSkill{
  name = "mobile__dianhua",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player.phase == Player.Start or player.phase == Player.Finish) and
    not table.every({"spade", "club", "heart", "diamond"}, function (suit)
      return player:getMark("@@mobile__falu"..suit) == 0
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local n = 0
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
      if player:getMark("@@mobile__falu"..suit) > 0 then
        n = n + 1
      end
    end
    if n > 0 and player.room:askForSkillInvoke(player, self.name) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForGuanxing(player, room:getNCards(self.cost_data), nil, {0, 0})
  end,
}
zhenyi:addRelatedSkill(zhenyi_trigger)
zhangqiying:addSkill(falu)
zhangqiying:addSkill(zhenyi)
zhangqiying:addSkill(dianhua)
AddWinAudio(zhangqiying)
Fk:loadTranslationTable{
  ["mobile__zhangqiying"] = "张琪瑛",
  ["#mobile__zhangqiying"] = "禳祷西东",
  ["illustrator:mobile__zhangqiying"] = "蛋费鸡丁",
  ["mobile__falu"] = "法箓",
  [":mobile__falu"] = "锁定技，当你的牌因弃置而移至弃牌堆后，根据这些牌的花色，你获得对应标记：<br>"..
  "♠，你获得1枚“紫微”；<br>"..
  "♣，你获得1枚“后土”；<br>"..
  "<font color='red'>♥</font>，你获得1枚“玉清”；<br>"..
  "<font color='red'>♦</font>，你获得1枚“勾陈”。<br>"..
  "每种标记限拥有一个。游戏开始时，你获得以上四种标记。",
  ["mobile__zhenyi"] = "真仪",
  [":mobile__zhenyi"] = "你可以在以下时机弃置相应的标记来发动以下效果：<br>"..
  "当一张判定牌生效前，你可以弃置“紫微”，然后将判定结果改为♠5或<font color='red'>♥5</font>并终止此时机；<br>"..
  "当你处于濒死状态时，你可以弃置“后土”，然后将你的一张手牌当【桃】使用；<br>"..
  "当你造成伤害时，你可以弃置“玉清”，然后判定，若结果为黑色，你令伤害值+1；<br>"..
  "当你受到属性伤害后，你可以弃置“勾陈”，然后你从牌堆中随机获得三种类型的牌各一张。",
  ["mobile__dianhua"] = "点化",
  [":mobile__dianhua"] = "准备阶段或结束阶段，你可以观看牌堆顶的X张牌（X为你的标记数），将这些牌以任意顺序放回牌堆顶。",
  ["@@mobile__faluspade"] = "♠紫微",
  ["@@mobile__faluclub"] = "♣后土",
  ["@@mobile__faluheart"] = "<font color='red'>♥</font>玉清",
  ["@@mobile__faludiamond"] = "<font color='red'>♦</font>勾陈",
  ["#mobile__zhenyi1"] = "真仪：你可以弃置♠紫微，将 %dest 的判定结果改为♠5或<font color='red'>♥5</font>",
  ["#mobile__zhenyi2"] = "真仪：你可以弃置♣后土，将一张手牌当【桃】使用",
  ["#mobile__zhenyi3"] = "真仪：你可以弃置<font color='red'>♥</font>玉清，对 %dest 造成的伤害+1",
  ["#mobile__zhenyi4"] = "真仪：你可以弃置<font color='red'>♦</font>勾陈，从牌堆中随机获得三种类型的牌各一张",
  ["#mobile__zhenyi_trigger"] = "真仪",
  ["mobile__zhenyi_spade"] = "将判定结果改为♠5",
  ["mobile__zhenyi_heart"] = "将判定结果改为<font color='red'>♥</font>5",

  -- aduio：漫天银色*张琪瑛 of 三国杀·移动版
  ["$mobile__falu1"] = "修撰法箓，以继黄老。",
  ["$mobile__falu2"] = "化无为有，以有载无。",
  ["$mobile__zhenyi1"] = "人道常变，天道如恒。",
  ["$mobile__zhenyi2"] = "既明大道，自显真仪。",
  ["$mobile__dianhua1"] = "点之以形，化之以心。 ",
  ["$mobile__dianhua2"] = "俯仰喟天地，坐化对本心。",
  ["~mobile__zhangqiying"] = "天地不仁，以万物为刍狗……",
  ["!mobile__zhangqiying"] = "谷神不死，是谓玄牝。",
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
        local targets = table.map(room:getOtherPlayers(data.to), Util.IdMapper)
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
  ["#gongsunkang"] = "沸流腾蛟",
  ["illustrator:gongsunkang"] = "小强",
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
  is_prohibited = Util.FalseFunc,
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
  prompt = "#tiansuan",
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

    if result == "tiansuanSSR" then
      local card_data = {}
      if not tgt:isKongcheng() and tgt ~= player then
        table.insert(card_data, { "$Hand", tgt.player_cards[Player.Hand] })
      end
      if #tgt.player_cards[Player.Equip] > 0 then
        table.insert(card_data, { "$Equip", tgt.player_cards[Player.Equip] })
      end
      if #tgt.player_cards[Player.Judge] > 0 then
        table.insert(card_data, { "$Judge", tgt.player_cards[Player.Judge] })
      end
      if #card_data == 0 then return end
      local id = room:askForCardChosen(player, tgt, { card_data = card_data }, self.name)
      room:obtainCard(player, id, false, fk.ReasonPrey, player.id, self.name)
    elseif result == "tiansuanS" then
      if tgt:isNude() then return end
      local id = room:askForCardChosen(player, tgt, "he", self.name)
      room:obtainCard(player, id, false, fk.ReasonPrey, player.id, self.name)
    end
  end,
}
tiansuan:addRelatedSkill(tiansuanProhibit)
tiansuan:addRelatedSkill(tiansuanTrig)
zhouqun:addSkill(tiansuan)
AddWinAudio(zhouqun)
Fk:loadTranslationTable{
  ['zhouqun'] = '周群',
  ["#zhouqun"] = "后圣",
  ["illustrator:zhouqun"] = "张帅",
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
  ["#tiansuan"] = "天算：你可以抽取一个“命运签”（你可额外放入一个任意签）",
  ['tiansuanNone'] = '不作弊',
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
  ['!zhouqun'] = '占星问卜，莫不言精！',
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
      self.cost_data = {tos = {target.id}, cards = card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    target:skip(Player.Draw)
    player.room:moveCardTo(self.cost_data.cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
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
  ["#yanpu"] = "盱衡识势",
  ["illustrator:yanpu"] = "鬼画府",
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
  expand_pile = "$mayuanyi_bing",
  derived_piles = "$mayuanyi_bing",
  prompt = "#jibing",
  interaction = function(self, player)
    local all_names = {"slash", "jink"}
    local names = player:getViewAsCardNames(self.name, all_names)
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "$mayuanyi_bing"
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
      return #player:getPile("$mayuanyi_bing") < #kingdoms
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "jibing", nil, "#jibing-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("jibing")
    player.room:notifySkillInvoked(player, "jibing", "special")
    player:addToPile("$mayuanyi_bing", player.room:getNCards(2), false, "jibing")
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
    return #player:getPile("$mayuanyi_bing") >= #kingdoms
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
  ["$mayuanyi_bing"] = "兵",
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
    targets = table.map(targets, Util.IdMapper)
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
    player:drawCards(3, self.name, nil, "@@poxiang-inhand-turn")
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
local poxiang_maxcards = fk.CreateMaxCardsSkill{
  name = "#poxiang_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@poxiang-inhand-turn") > 0
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
      AimGroup:isOnlyTarget(player, data) and #player:getPile("jueyong_desperation") < player.hp
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
            if from and not from.dead then
              if from:canUse(card) and not from:prohibitUse(card) and not from:isProhibited(player, card) and
                  (card.skill:modTargetFilter(player.id, {}, from, card, false)) then
                local tos = {{player.id}}
                if card.skill:getMinTargetNum() == 2 then
                  local targets = table.filter(room.alive_players, function (p)
                    return p ~= player and card.skill:targetFilter(p.id, {player.id}, {}, card, nil, from)
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
poxiang:addRelatedSkill(poxiang_maxcards)
fuqian:addSkill(poxiang)
fuqian:addSkill(jueyong)
Fk:loadTranslationTable{
  ["fuqian"] = "傅佥",
  ["#fuqian"] = "危汉绝勇",
  ["illustrator:fuqian"] = "君桓文化",
  ["cv:fuqian"] = "杨超然",

  ["poxiang"] = "破降",
  [":poxiang"] = "出牌阶段限一次，你可以交给一名其他角色一张牌，然后你摸三张牌，移去所有“绝”并失去1点体力，你以此法获得的牌本回合不计入手牌上限。",
  ["jueyong"] = "绝勇",
  [":jueyong"] = "锁定技，当你成为一张非因〖绝勇〗使用的、非转化且非虚拟的牌（【桃】和【酒】除外）指定的目标时，若你是此牌的唯一目标，"..
  "且此时“绝”的数量小于你的体力值，你取消之。然后将此牌置于你的武将牌上，称为“绝”。结束阶段，若你有“绝”，则按照置入顺序从前到后依次结算“绝”，"..
  "令其原使用者对你使用（若此牌使用者不在场，则将此牌置入弃牌堆）。",
  ["#poxiang-active"] = "发动破降，选择一张牌交给一名角色，然后摸三张牌，移去所有绝并失去1点体力",
  ["@@poxiang-inhand-turn"] = "破降",
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
      proposer = player.id,
    })
    room:delay(2000)
    local _, choice = U.askforChooseCardsAndChoice(player, cards, {"OK"}, self.name, "#mingcha-get", {"Cancel"}, 0, 0, cards)
    if choice == "OK" then
      local to_get = {}
      for i = 3, 1, -1 do
        if Fk:getCardById(cards[i]).number < 9 then
          table.insert(to_get, cards[i])
          table.remove(cards, i)
        end
      end
      if #to_get > 0 then
        room:obtainCard(player.id, to_get, true, fk.ReasonJustMove)
      end
      if not player.dead then
        local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p) return not p:isNude() end), Util.IdMapper)
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
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
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
      room:obtainCard(player, player:getPile("chengye_classic"), true, fk.ReasonPrey)
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
  prompt = "#zhujian",
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
    local targets = table.map(tos, Util.Id2PlayerMapper)
    for _, p in ipairs(targets) do
      if not p.dead then
        p:drawCards(1, self.name)
      end
    end
  end,
}
local duansuo = fk.CreateActiveSkill{
  name = "duansuo",
  anim_type = "offensive",
  prompt = "#duansuo",
  min_target_num = 1,
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
    local targets = table.map(tos, Util.Id2PlayerMapper)
    for _, p in ipairs(targets) do
      p:setChainState(false)
    end
    for _, p in ipairs(targets) do
      if not p.dead then
        room:damage({
          from = room:getPlayerById(effect.from),
          to = p,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        })
      end
    end
  end,
}
wangjun:addSkill(zhujian)
wangjun:addSkill(duansuo)
Fk:loadTranslationTable{
  ["wangjun"] = "王濬",
  ["#wangjun"] = "首下石城",
  ["illustrator:wangjun"] = "凝聚永恒",
  ["zhujian"] = "筑舰",
  [":zhujian"] = "出牌阶段限一次，你可以令至少两名装备区里有牌的角色各摸一张牌。",
  ["#zhujian"] = "筑舰：令至少两名装备区里有牌的角色各摸一张牌",
  ["duansuo"] = "断索",
  [":duansuo"] = "出牌阶段限一次，你可以重置至少一名角色，然后对这些角色各造成1点火焰伤害。",
  ["#duansuo"] = "断索：重置至少一名角色，对这些角色各造成1点火焰伤害",
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
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(self.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  handly_pile = true,
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
AddWinAudio(zhaotongzhaoguang)
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
  ["!zhaotongzhaoguang"] = "身继龙魂，效捷致果！",
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
      room:obtainCard(player, id, true, fk.ReasonPrey)
      local card = Fk:getCardById(id)
      if table.contains(player:getCardIds("h"), id) and player:canUseTo(card, player) then
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
      room:obtainCard(player, id, true, fk.ReasonPrey)
      local card = Fk:getCardById(id)
      if table.contains(player:getCardIds("h"), id) and player:canUseTo(card, player) then
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
    local targets = table.filter(room:getOtherPlayers(player, false), function (p) return not p:isNude() end)
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
      room:obtainCard(player, cards[1], false, fk.ReasonGive, to.id)
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
  [":polu"] = "锁定技，回合开始时，你获得游戏外的<a href=':mobile__catapult'>【霹雳车】</a>并使用之；"..
  "当你受到1点伤害后，若你的装备区里没有【霹雳车】，你摸一张牌，然后随机从牌堆中获得一张武器牌并使用之。",
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
      player:addToPile("lifeng_liang", self.cost_data, true, self.name)
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
  ["cv:lifeng"] = "秦且歌",
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
    room:obtainCard(target, card, false, fk.ReasonGive, player.id)
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
qianchong:addRelatedSkill(qianchong_targetmod)
wangyuanji:addSkill(qianchong)
wangyuanji:addSkill(shangjian)
wangyuanji:addRelatedSkill("weimu")
wangyuanji:addRelatedSkill("mingzhe")
AddWinAudio(wangyuanji)
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
  ["!mobile__wangyuanji"] = "苍生黎庶，都会有一个美好的未来了。",
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
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local targetRecorded = player:getTableMark("hongyi_targets")
    if table.insertIfNeed(targetRecorded, target.id) then
      room:addPlayerMark(target, "@@hongyi")
      room:setPlayerMark(player, "hongyi_targets", targetRecorded)
    end
  end,
}
local hongyi_delay = fk.CreateTriggerSkill{
  name = "#hongyi_delay",
  anim_type = "control",
  events = {fk.DamageCaused},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(hongyi) and data.from
    and table.contains(player:getTableMark("hongyi_targets"), data.from.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(hongyi.name)
    local judge = {
      who = target,
      reason = hongyi.name,
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

  refresh_events = {fk.TurnStart, fk.BuryVictim, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventLoseSkill and data ~= hongyi then return false end
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
        return player:hasSkill(hongyi, true) and not table.contains(player.room:getBanner('memorializedPlayers') or {}, target.id)
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
  ["designer:mobile__yanghuiyu"] = "Loun老萌",
  ["illustrator:mobile__yanghuiyu"] = "石蝉",

  ["hongyi"] = "弘仪",
  ["#hongyi_delay"] = "弘仪",
  [":hongyi"] = "出牌阶段限一次，你可以指定一名其他角色，当其于你的下个回合开始之前造成伤害时，其判定，若结果为："..
  "红色，受到过此伤害的角色摸一张牌；黑色，令伤害值-1。",
  ["quanfeng"] = "劝封",
  [":quanfeng"] = "限定技，当一名其他角色死亡后，你可以<a href='memorialize'>追思</a>该角色，"..
  "失去〖弘仪〗，获得其武将牌上的所有技能（主公技除外），加1点体力上限，回复1点体力；"..
  "当你处于濒死状态时，你可以加2点体力上限，回复4点体力。",
  ["#hongyi-active"] = "弘仪：选择一名其他角色，其造成伤害时判定，判红受伤角色摸牌，判黑伤害-1",
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
        room:obtainCard(player, cardIds[1], false, fk.ReasonPrey)
      end
    else
      local targets = table.map(self.cost_data, Util.Id2PlayerMapper)
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
      room:setPlayerMark(to, "@@mobile__yizheng", 1)
    else
      room:changeMaxHp(from, -1)
    end
  end,
}
local mobileYizhengDebuff = fk.CreateTriggerSkill{
  name = "#yizheng-debuff",

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.to == Player.Draw and player:getMark("@@mobile__yizheng") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@mobile__yizheng", 0)
    player:skip(Player.Draw)
  end,
}
mobileYizheng:addRelatedSkill(mobileYizhengDebuff)
yangbiao:addSkill(zhaohan)
yangbiao:addSkill(rangjie)
yangbiao:addSkill(mobileYizheng)
Fk:loadTranslationTable{
  ["yangbiao"] = "杨彪",
  ["#yangbiao"] = "德彰海内",
  ["cv:yangbiao"] = "袁国庆",
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

local simazhao = General(extension, "m_sp__simazhao", "wei", 3)
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
    player:addToPile("simazhao_wang", effect.cards, true, self.name)
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
      room:obtainCard(player.id, card[1], true, fk.ReasonGive, data.from.id)
    else
      return true
    end
  end,
}
zhaoxin:addRelatedSkill(zhaoxin_trigger)
simazhao:addSkill(zhaoxin)
simazhao:addSkill(daigong)
AddWinAudio(simazhao)
Fk:loadTranslationTable{
  ["m_sp__simazhao"] = "司马昭", -- 手杀称为SP司马昭
  ["#m_sp__simazhao"] = "四海威服",
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
  ["~m_sp__simazhao"] = "安世，接下来，就看你的了……",
  ["!m_sp__simazhao"] = "天下归一之功，已近在咫尺。",
}

--SP13：曹嵩 裴秀 杨阜 彭羕 牵招 郭女王 韩遂 阎象 李遗
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
        return target == player and #player:getTableMark("@[:]yijin_owner") == 0
      else
        return target == player and player.phase == Player.Play and #player:getTableMark("@[:]yijin_owner") > 0
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
      local targets = table.filter(room:getOtherPlayers(player, false), function(p) return p:getMark("@[:]yijin") == 0 end)
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
  interaction = UI.ComboBox {choices = Self:getTableMark("@[:]yijin_owner") },
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
      player:skip(data.to)
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
Fk:loadTranslationTable{
  ["mobile__caosong"] = "曹嵩",
  ["#mobile__caosong"] = "舆金贾权",
  ["illustrator:mobile__caosong"] = "黯荧岛工作室",
  ["yijin"] = "亿金",
  [":yijin"] = "锁定技，游戏开始时，你获得6枚“金”标记；回合开始时，若你没有“金”，你死亡。出牌阶段开始时，你令一名没有“金”的其他角色获得一枚“金”和"..
  "对应的效果直到其下回合结束：<br>膴士：摸牌阶段摸牌数+4、出牌阶段使用【杀】次数上限+1；<br>厚任：回合结束时回复3点体力；<br>"..
  "贾凶：出牌阶段开始时失去1点体力，本回合手牌上限-3；<br>拥蔽：跳过摸牌阶段；<br>通神：防止受到的非雷电伤害；<br>金迷：跳过出牌阶段和弃牌阶段。",
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

  ["$yijin1"] = "吾家资巨万，无惜此两贯三钱！",
  ["$yijin2"] = "小儿持金过闹市，哼！杀人何需我多劳！",
  ["$yijin3"] = "普天之下，竟有吾难市之职？",
  ["~mobile__caosong"] = "长恨人心不如水，等闲平地起波澜……",
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
      local mark = target:getTableMark("@@shihe")
      table.insertIfNeed(mark, player.id)
      if room.settings.gameMode == "m_1v2_mode" or room.settings.gameMode == "m_2v2_mode" then
        for _, p in ipairs(room:getOtherPlayers(player, false)) do
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
  on_cost = Util.TrueFunc,
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
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      1, 1, "#zhenfu-choose", self.name, true)
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
end
local daming = fk.CreateTriggerSkill{
  name = "daming",
  anim_type = "control",
  attached_skill_name = "daming_other&",
  events = {fk.GameStart},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    changeDaming (player, 1)
  end,
}
local daming_other = fk.CreateActiveSkill{
  name = "daming_other&",
  prompt = "#daming_other",
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
    room:obtainCard(py, get, false, fk.ReasonGive, player.id)
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
          room:obtainCard(player, give[1], false, fk.ReasonGive, to.id)
          changeDaming (py, 1)
          return
        end
      end
    end
    if table.contains(py:getCardIds("he"), get) and not player.dead then
      room:obtainCard(player, get, false, fk.ReasonGive, py.id)
    end
  end,
}
pengyang:addSkill(daming)
Fk:addSkill(daming_other)
local xiaoni = fk.CreateViewAsSkill{
  name = "xiaoni",
  prompt = "#xiaoni",
  interaction = function(self)
    local all_names = Fk:getAllCardNames("btd")
    local names = table.filter(all_names, function (name)
      local card = Fk:cloneCard(name)
      card.skillName = self.name
      return Self:canUse(card) and not Self:prohibitUse(card)
      and (card.trueName == "slash" or (card.type == Card.TypeTrick and card.is_damage_card) or card.name == "lightning")
    end)
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  handly_pile = true,
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
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and
      tonumber(player:getMark("@daming")) > 0
  end,
}
local xiaoni_trigger = fk.CreateTriggerSkill{
  name = "#xiaoni_trigger",
  refresh_events = {fk.CardUsing},
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
  ["daming_other&"] = "达命",
  [":daming_other&"] = "出牌阶段限一次，你可以交给彭羕一张牌，然后其选择另一名其他角色。若该角色有相同类型的牌，则该角色须交给你一张相同类型的牌且"..
  "彭羕获得1点“达命”值，否则彭羕将获得的牌交还给你。",
  ["#daming-choose"] = "达命：选择一名其他角色，若其有%arg，则须交给%dest一张%arg且你获得1点“达命”值，否则你将%arg2交给%dest",
  ["#daming-give"] = "达命：你须交给%dest一张%arg",
  ["#daming_other"] = "达命：你可以交给有“达命”的角色一张牌，令其选择其他角色交给你同类型牌",
  ["xiaoni"] = "嚣逆",
  [":xiaoni"] = "①出牌阶段限一次，若你的“达命”值大于0，你可以将一张牌当任意一种【杀】或伤害类锦囊牌使用，并减少此牌目标数点“达命”值。<br>"..
  "②你的手牌上限等于X（X为“达命”值，且至多为你的体力值）。",
  ["#xiaoni"] = "嚣逆：你可以消耗“达命”值(可减至到负值)将一张牌当伤害牌使用！",

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
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
        1, 1, "#yichong-choose", self.name, true)
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
  events = {fk.PreDamage, fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end
    local to = player.room:getPlayerById(mark[1])
    if to == nil or to.dead then return false end
    if event == fk.PreDamage then
      return player == data.from and player.room.logic:damageByCardEffect()
    elseif event == fk.Damaged then
      return player == target and to.hp > 3
    end
  end,
  on_cost = function(self, event, target, player, data)
    local mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end
    if event == fk.PreDamage or player.room:askForSkillInvoke(player, self.name, nil, "#wufei-invoke::"..mark[1]) then
      self.cost_data = { tos = { mark[1] } }
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(self.name)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    if event == fk.PreDamage then
      room:notifySkillInvoked(player, self.name, "control")
      data.from = to
    else
      player.room:notifySkillInvoked(player, self.name, "masochism")
      player.room:damage{
        to = to,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
guonvwang:addSkill(yichong)
guonvwang:addSkill(wufei)
Fk:loadTranslationTable{
  ["mobile__guozhao"] = "郭女王",
  ["#mobile__guozhao"] = "文德皇后",
  ["illustrator:mobile__guozhao"] = "凡果",
  ["yichong"] = "易宠",
  [":yichong"] = "准备阶段，你可以选择一名其他角色并指定一种花色，获得其所有该花色的装备和一张该花色的手牌，并令其获得“雀”标记直到你下个回合开始"..
  "（若场上已有“雀”标记则转移给该角色）。拥有“雀”标记的角色获得你指定花色的牌时，你获得此牌（你至多因此“雀”标记获得一张牌）。",
  ["wufei"] = "诬诽",
  [":wufei"] = "你使用【杀】或普通锦囊牌造成的伤害的来源视为拥有“雀”的角色。"..
  "当你受到伤害后，若拥有“雀”标记的角色体力值大于3，你可以令其受到1点无来源伤害。",

  ["#yichong-choose"] = "你可以发动 易宠，选择一名其他角色，获得其所有该花色的装备区里的牌和一张该花色的手牌",
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
  handly_pile = true,
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

local mobile__yanxiang = General(extension, "mobile__yanxiang", "qun", 3)
local kujian = fk.CreateActiveSkill{
  name = "kujian",
  anim_type = "support",
  prompt = "#kujian-active",
  mute = true,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  max_card_num = 3,
  min_card_num = 1,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and #selected < 2
  end,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local player = room:getPlayerById(effect.from)
    room:notifySkillInvoked(player, self.name, "support", effect.tos)
    player:broadcastSkillInvoke(self.name, 1)
    table.forEach(effect.cards, function(cid)
      room:setCardMark(Fk:getCardById(cid), "@@kujian", 1)
    end)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false, effect.from)
  end,
}
local kujian_judge = fk.CreateTriggerSkill{
  name = "#kujian_judge",
  events = {fk.CardUsing, fk.CardResponding, fk.AfterCardsMove},
  anim_type = "drawcard",
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event ~= fk.AfterCardsMove then
      if player == target then return false end
      return table.find(Card:getIdList(data.card), function(id)
        return Fk:getCardById(id):getMark("@@kujian") > 0
      end)
    else
      for _, move in ipairs(data) do
        if move.from ~= player.id and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
          if table.find(move.moveInfo, function(info)
            return Fk:getCardById(info.cardId):getMark("@@kujian") > 0 and info.fromArea == Card.PlayerHand
          end) then
            return true
          end
        end
      end
    end
    return false
  end,
  on_trigger = function(self, event, target, player, data)
    if event ~= fk.AfterCardsMove then
      local num = #table.filter(Card:getIdList(data.card), function(id)
        return Fk:getCardById(id):getMark("@@kujian") > 0
      end)
      for _ = 1, num, 1 do
        self:doCost(event, target, player, data)
      end
    else
      local room = player.room
      local targets = {}
      for _, move in ipairs(data) do
        if move.from ~= player.id and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@kujian") > 0 and info.fromArea == Card.PlayerHand then
              table.insert(targets, move.from)
            end
          end
        end
      end
      room:sortPlayersByAction(targets)
      for _, target_id in ipairs(targets) do
        if not player:hasSkill(self) then break end
        local skill_target = room:getPlayerById(target_id)
        if skill_target and not skill_target.dead and not player.dead and not (skill_target:isNude() and player:isNude()) then
          self:doCost(event, skill_target, player, data)
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event ~= fk.AfterCardsMove then
      room:notifySkillInvoked(player, "kujian", "drawcard")
      player:broadcastSkillInvoke("kujian", 3)
      table.forEach(Card:getIdList(data.card), function(id)
        return room:setCardMark(Fk:getCardById(id), "@@kujian", 0)
      end)
      room:doIndicate(player.id, {target.id})
      player:drawCards(2, self.name)
      target:drawCards(2, self.name)
    else
      room:notifySkillInvoked(player, "kujian", "negative")
      player:broadcastSkillInvoke("kujian", 2)
      room:doIndicate(player.id, {target.id})
      for _, move in ipairs(data) do
        if move.from ~= player.id and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              room:setCardMark(Fk:getCardById(info.cardId), "@@kujian", 0)
            end
          end
        end
      end
      room:askForDiscard(player, 1, 1, true, self.name, false, nil, "#kujian-discard")
      room:askForDiscard(target, 1, 1, true, self.name, false, nil, "#kujian-discard")
    end
  end,
}
kujian:addRelatedSkill(kujian_judge)

local ruilian = fk.CreateTriggerSkill{
  name = "ruilian",
  events = {fk.RoundStart, fk.TurnEnd},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (event == fk.RoundStart or (tonumber(target:getMark("@ruilian-turn")) > 0 and table.contains(target:getMark("_ruilianGiver"), player.id)))
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.RoundStart then
      local target = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1, "#ruilian-ask", self.name, true)
      if #target > 0 then
        self.cost_data = target[1]
        return true
      end
    else
      local cids = target:getMark("_ruilianCids-turn")
      local cardType = {}
      table.forEach(cids, function(cid)
        table.insertIfNeed(cardType, Fk:getCardById(cid):getTypeString())
      end)
      table.insert(cardType, "Cancel")
      local choice = player.room:askForChoice(player, cardType, self.name, "#ruilian-type:" .. target.id)
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      local target = room:getPlayerById(self.cost_data)
      room:setPlayerMark(target, "@@ruilian", 1)
      local ruilianGiver = type(target:getMark("_ruilianGiver")) == "table" and target:getMark("_ruilianGiver") or {}
      table.insertIfNeed(ruilianGiver, player.id)
      room:setPlayerMark(target, "_ruilianGiver", ruilianGiver)
    else
      local id = room:getCardsFromPileByRule(".|.|.|.|.|" .. self.cost_data, 1, "discardPile")
      if #id > 0 then
        room:obtainCard(player, id[1], true, fk.ReasonPrey)
      end
      id = room:getCardsFromPileByRule(".|.|.|.|.|" .. self.cost_data, 1, "discardPile")
      if #id > 0 then
        room:obtainCard(target, id[1], true, fk.ReasonPrey)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    if player ~= player.room.current then return false end
    if event == fk.AfterCardsMove then
      if player:getMark("@ruilian-turn") == 0 then return false end
      local cids = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.insert(cids, info.cardId)
            end
          end
        end
      end
      if #cids > 0 then
        return true
      end
      return false
    else
      return target == player and player:getMark("@@ruilian") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local cids = type(player:getMark("_ruilianCids-turn")) == "table" and player:getMark("_ruilianCids-turn") or {}
      local otherCids = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.insert(otherCids, info.cardId)
            end
          end
        end
      end
      table.insertTable(cids, otherCids)
      room:setPlayerMark(player, "_ruilianCids-turn", cids)
      room:setPlayerMark(player, "@ruilian-turn", #player:getMark("_ruilianCids-turn"))
    else
      room:setPlayerMark(player, "@ruilian-turn", "0")
      room:setPlayerMark(player, "@@ruilian", 0)
    end
  end,
}
Fk:loadTranslationTable{
  ["mobile__yanxiang"] = "阎象",
  ["#mobile__yanxiang"] = "明尚夙达",
  ["illustrator:mobile__yanxiang"] = "君桓文化",

  ["kujian"] = "苦谏",
  [":kujian"] = "出牌阶段限一次，你可将至多两张手牌标记为“谏”并交给一名其他角色。当其他角色使用或打出“谏”牌时，你与其各摸两张牌。当其他角色非因使用或打出从手牌区失去“谏”牌后，你与其各弃置一张牌。",
  ["ruilian"] = "睿敛",
  [":ruilian"] = "每轮开始时，你可选择一名角色，其下个回合结束前，若其此回合弃置过牌，你可选择其此回合弃置过的牌中的一种类别，你与其各从弃牌堆中获得一张此类别的牌。",

  ["#kujian-active"] = "你可发动“苦谏”，将至多两张手牌标记为“谏”并交给一名其他角色",
  ["#kujian-discard"] = "苦谏：请弃置一张牌",
  ["#kujian_judge"] = "苦谏",
  ["#ruilian-ask"] = "你可对一名角色发动“睿敛”",
  ["@@ruilian"] = "睿敛",
  ["@ruilian-turn"] = "睿敛",
  ["#ruilian-type"] = "睿敛：你可选择 %src 此回合弃置过的牌中的一种类别，你与其各从弃牌堆中获得一张此类别的牌",
  ["@@kujian"] = "谏",

  ["$kujian1"] = "吾之所言，皆为公之大业。",
  ["$kujian2"] = "公岂徒有纳谏之名乎！",
  ["$kujian3"] = "明公虽奕世克昌，未若有周之盛。",
  ["$ruilian1"] = "公若擅进庸肆，必失民心！",
  ["$ruilian2"] = "外敛虚进之势，内减弊民之政。",
  ["~mobile__yanxiang"] = "若遇明主，或可青史留名……",
}