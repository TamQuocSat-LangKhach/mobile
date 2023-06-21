local extension = Package("sincerity")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["sincerity"] = "信包",
}

local zhouchu = General(extension, "mobile__zhouchu", "wu", 4)
Fk:loadTranslationTable{
  ["mobile__zhouchu"] = "周处",
  ["~mobile__zhouchu"] = "改励自砥，誓除三害……",
}

local xianghai = fk.CreateFilterSkill{
  name = "xianghai",
  card_filter = function(self, to_select, player)
    return player:hasSkill(self.name) and to_select.type == Card.TypeEquip and table.contains(player.player_cards[Player.Hand], to_select.id)
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("analeptic", to_select.suit, to_select.number)
    card.skillName = "xianghai"
    return card
  end,
}

local xianghai_maxcards = fk.CreateMaxCardsSkill{
  name = "#xianghai_maxcards",
  correct_func = function(self, player)
    return - #table.filter(Fk:currentRoom().alive_players, function(p) return p:hasSkill(xianghai.name) and p ~= player end)
  end,
}

xianghai:addRelatedSkill(xianghai_maxcards)

Fk:loadTranslationTable{
  ["xianghai"] = "乡害",
  [":xianghai"] = "锁定技，其他角色的手牌上限-1，你手牌中的装备牌均视为【酒】。",
  ["$xianghai1"] = "快快闪开，伤到你们可就不好了，哈哈哈！",
  ["$xianghai2"] = "你自己撞上来的，这可怪不得小爷我！",
}

zhouchu:addSkill(xianghai)

local chuhai = fk.CreateActiveSkill{
  name = "chuhai",
  anim_type = "offensive",
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

chuhai:addRelatedSkill(chuhai_trigger)
chuhai:addRelatedSkill(chuhai_delay)

Fk:loadTranslationTable{
  ["chuhai"] = "除害",
  ["#chuhai_trigger"] = "除害",
  ["#chuhai_delay"] = "除害",
  [":chuhai"] = "使命技，出牌阶段限一次，你可以摸一张牌，并与一名其他角色拼点，此次你的拼点牌点数增加X（X为4减去你装备区的装备数量）。若你赢：你观看其手牌，从牌堆或弃牌堆随机获得其手牌中拥有的类别牌各一张；你于此阶段对其造成伤害后，将牌堆或弃牌堆中一张你空置装备栏对应类型的装备牌，置入你对应的装备区。<br>\
  <strong>成功</strong>：当一张装备牌进入你的装备区后，若你的装备区有不少于3张装备，则你将体力值回复至上限，获得〖彰名〗，失去〖乡害〗。<br>\
  <strong>失败</strong>：若你于使命达成前，你使用〖除害〗拼点没赢，且你的拼点结果不大于6点，则使命失败。",

  ["@@chuhai-phase"] = "除害",
  ["$chuhai1"] = "有我在此，安敢为害？！",
  ["$chuhai2"] = "小小孽畜，还不伏诛？！",
  ["$chuhai3"] = "此番不成，明日再战！",
}

zhouchu:addSkill(chuhai)

local zhangming = fk.CreateTriggerSkill{
  name = "zhangming",
  anim_type = "drawcard",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 and player ~= data.to
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {"basic", "trick", "equip"}
    local to = data.to
    if to:isAlive() then
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

zhangming:addRelatedSkill(zhangming_trigger)
zhangming:addRelatedSkill(zhangming_maxcards)

Fk:loadTranslationTable{
  ["zhangming"] = "彰名",
  ["#zhangming_trigger"] = "彰名",
  [":zhangming"] = "锁定技，你使用梅花牌不能被响应。每回合限一次，你对其他角色造成伤害后，其随机弃置一张手牌，然后你从牌堆或弃牌堆中获得与其弃置牌类型不同的牌各一张（若其无法弃置手牌，改为你从牌堆或弃牌堆获得所有类型牌各一张），以此法获得的牌不计入本回合手牌上限。",
  ["$zhangming1"] = "心怀远志，何愁声名不彰！",
  ["$zhangming2"] = "从今始学，成为有用之才！",
}

zhouchu:addRelatedSkill(zhangming)

local wujing = General(extension, "mobile__wujing", "wu", 4)
Fk:loadTranslationTable{
  ["mobile__wujing"] = "吴景",
  ["~mobile__wujing"] = "贼寇未除，奈何吾身先丧……",
}

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
    local use = player.room:askForUseCard(player, "slash,duel", "slash,duel", "#heji-use::" .. targets[1], true, { must_targets = targets, bypass_distances = true, bypass_times = true})
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

heji:addRelatedSkill(heji_delay)

Fk:loadTranslationTable{
  ["heji"] = "合击",
  ["#heji_delay"] = "合击",
  [":heji"] = "若一名角色使用【决斗】或红色【杀】，仅指定了唯一一名其他角色为目标，在此牌结算结束后，你可从手牌中对同目标使用一张无次数和距离限制的【杀】或【决斗】。若此次你使用的牌为非转化牌，在使用此牌时，你随机获得一张红色牌。",

  ["#heji-use"] = "合击：你可以对%dest使用一张手牌中的【杀】或者【决斗】",
  ["$heji1"] = "你我合势而击之，区区贼寇岂会费力？",
  ["$heji2"] = "伯符！今日之战，务必全力攻之！",
}

wujing:addSkill(heji)

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

liubing:addRelatedSkill(liubing_trigger)

Fk:loadTranslationTable{
  ["liubing"] = "流兵",
  ["#liubing_trigger"] = "流兵",
  [":liubing"] = "锁定技，你每回合使用的第一张非虚拟【杀】的花色视为方块。其他角色于出牌阶段使用的非转化黑色【杀】若未造成伤害，结算结束后，你获得之。",
  ["$liubing1"] = "尔等流寇，亦可展吾军之勇。",
  ["$liubing2"] = "流寇不堪大用，勤加操练可为精兵。",
}

wujing:addSkill(liubing)

-- local wangling = General(extension, "wangling", "wei", 4)
-- Fk:loadTranslationTable{
--   ["wangling"] = "王凌",
--   ["~wangling"] = "一生尽忠事魏，不料，今日晚节尽毁啊！",
-- }

-- local xingqi = fk.CreateTriggerSkill{
--   name = "xingqi",
--   anim_type = "drawcard",
--   events = {fk.CardUsing, fk.EventPhaseStart},
--   can_trigger = function(self, event, target, player, data)
--     if target ~= player or not player:hasSkill(self.name) then
--       return false
--     end

--     if event == fk.CardUsing then
--       return
--         data.card.sub_type ~= Card.SubtypeDelayedTrick and
--         not table.contains(type(player:getMark("@xingqi_bei")) == "table" and player:getMark("@xingqi_bei") or {}, data.card.trueName)
--     else
--       return player.phase == Player.Finish and #(type(player:getMark("@xingqi_bei")) == "table" and player:getMark("@xingqi_bei") or {}) > 0
--     end
--   end,
--   on_cost = function(self, event, target, player, data)
--     if event == fk.EventPhaseStart then
--       local room = player.room
--       if not room:askForSkillInvoke(player, self.name) then
--         return false
--       end
--       self.cost_data = room:askForChoice(player, player:getMark("@xingqi_bei"), self.name, "#xingqi-obtain")
--     end

--     return true
--   end,
--   on_use = function(self, event, target, player, data)
--     local room = player.room
--     if event == fk.CardUsing then
--       local xingqiRecord = type(player:getMark("@xingqi_bei")) == "table" and player:getMark("@xingqi_bei") or {}
--       table.insert(xingqiRecord, data.card.trueName)
--       room:setPlayerMark(player, "@$xingqi", xingqiRecord)
--     else
--       local xingqiRecord = player:getMark("@xingqi_bei")
--       table.removeOne(xingqiRecord, self.cost_data)
--       room:setPlayerMark(player, "@$xingqi", #xingqiRecord > 0 and xingqiRecord or 0)

--       local cardId = room:getCardsFromPileByRule(self.cost_data, 1)
--       room:obtainCard(player, cardId, true, fk.ReasonPrey)
--     end
--   end,
-- }
-- Fk:loadTranslationTable{
--   ["xingqi"] = "星启",
--   [":xingqi"] = "当你使用不为延时类锦囊牌的牌时，若你没有此牌名的“备”，你将此牌牌名记录为“备”；结束阶段开始时，你可以移出一个“备”，从牌堆中随机获得一张与此牌名相同的牌。",
--   ["$xingqi1"] = "翻江复蹈海，六合定乾坤！",
--   ["$xingqi2"] = "力攻平江东，威名扬天下！",
-- }

-- wangling:addSkill(xingqi)

-- local zifu = fk.CreateTriggerSkill{
--   name = "zifu",
--   anim_type = "negative",
--   events = {fk.EventPhaseEnd},
--   frequency = Skill.Compulsory,
--   can_trigger = function(self, event, target, player, data)
--     return
--       target == player and
--       player:hasSkill(self.name) and
--       player.phase == Player.Play and
--       player:getMark("zifu-phase") == 0
--   end,
--   on_use = function(self, event, target, player, data)
--     local room = player.room
--     room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn)
--   end,
-- }
-- Fk:loadTranslationTable{
--   ["zifu"] = "自缚",
--   [":zifu"] = "当你使用不为延时类锦囊牌的牌时，若你没有此牌名的“备”，你将此牌牌名记录为“备”；结束阶段开始时，你可以移出一个“备”，从牌堆中随机获得一张与此牌名相同的牌。",
--   ["$zifu1"] = "翻江复蹈海，六合定乾坤！",
--   ["$zifu2"] = "力攻平江东，威名扬天下！",
-- }

-- wangling:addSkill(zifu)

local godsunce = General(extension, "godsunce", "god", 1, 6)
Fk:loadTranslationTable{
  ["godsunce"] = "神孙策",
  ["~godsunce"] = "无耻小人！竟敢暗算于我……",
}

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
Fk:loadTranslationTable{
  ["yingba"] = "英霸",
  [":yingba"] = "出牌阶段限一次，你可以令一名体力上限大于1的其他角色减1点体力上限，并令其获得一枚“平定”标记，然后你减1点体力上限；你对拥有“平定”标记的角色使用牌无距离限制。",
  ["@yingba_pingding"] = "平定",
  ["$yingba1"] = "从我者可免，拒我者难容！",
  ["$yingba2"] = "卧榻之侧，岂容他人鼾睡！",
}

local yingbaBuff = fk.CreateTargetModSkill{
  name = "#yingba-buff",
  distance_limit_func =  function(self, player, skill, card, to)
    if player:hasSkill(self.name) and to and to:getMark("@yingba_pingding") > 0 then
      return 999
    end

    return 0
  end
}

yingba:addRelatedSkill(yingbaBuff)
godsunce:addSkill(yingba)

local fuhai = fk.CreateTriggerSkill{
  name = "fuhai",
  events = {fk.TargetSpecified, fk.Death},
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then
      return false
    end

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
Fk:loadTranslationTable{
  ["fuhai"] = "覆海",
  [":fuhai"] = "锁定技，拥有“平定”标记的角色不能响应你对其使用的牌；当你使用牌指定拥有“平定”标记的角色为目标后，你摸一张牌；当拥有“平定”标记的角色死亡时，你加X点体力上限并摸X张牌（X为其“平定”标记数）。",
  ["$fuhai1"] = "翻江复蹈海，六合定乾坤！",
  ["$fuhai2"] = "力攻平江东，威名扬天下！",
}

godsunce:addSkill(fuhai)

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

    local tos, cardId = room:askForChooseCardAndPlayers(
      player,
      table.map(room:getOtherPlayers(player, false), function(p)
        return p.id
      end),
      1,
      1,
      ".|.|.|hand",
      "#pinghe-give",
      self.name,
      false,
      true
    )

    room:obtainCard(tos[1], cardId, false, fk.ReasonGive)

    if player:hasSkill(yingba.name, true) and data.from:isAlive() then
      room:addPlayerMark(data.from, "@yingba_pingding")
    end

    return true
  end,
}
Fk:loadTranslationTable{
  ["pinghe"] = "冯河",
  [":pinghe"] = "锁定技，你的手牌上限基值为你已损失的体力值；当你受到其他角色造成的伤害时，若你的体力上限大于1且你有手牌，你防止此伤害，减1点体力上限并将一张手牌交给一名其他角色，然后若你有技能“英霸”，伤害来源获得一枚“平定”标记。",
  ["#pinghe-give"] = "冯河：请交给一名其他角色一张手牌",
  ["$pinghe1"] = "不过胆小鼠辈，吾等有何惧哉！",
  ["$pinghe2"] = "只可得胜而返，岂能败战而归！",
}

local pingheBuff = fk.CreateMaxCardsSkill {
  name = "#pinghe-buff",
  frequency = Skill.Compulsory,
  fixed_func = function(self, player)
    return player:hasSkill("pinghe") and player:getLostHp() or nil
  end
}

pinghe:addRelatedSkill(pingheBuff)
godsunce:addSkill(pinghe)

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
  [":dulie"] = "锁定技，当你成为体力值大于你的角色使用【杀】的目标时，你判定，若结果为红桃，取消之。",
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
        return not player:prohibitDiscard(id)
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
            if p:getMark("@@powei_wei") > (hasLastPlayer and 1 or 0) and not (#room.alive_players < 3 and p:getNextAlive() == player)  then
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
  [":powei"] = "使命技，游戏开始时，你令所有其他角色获得“围”标记；回合开始时，你令所有拥有“围”标记的角色将“围”标记移动至下家（若下家为你，则改为移动至你的下家）；有“围”标记的角色受到伤害后，移去其“围”标记；有“围”的角色的回合开始时，你可以选择一项并令你于本回合内视为处于其攻击范围内：1.弃置一张手牌，对其造成1点伤害；2.若其体力值不大于你，你获得其一张手牌。<br>\
               <strong>成功</strong>：回合开始时，若场上没有“围”标记，则你获得技能“神著”；<br>\
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
  [":shenzhuo"] = "锁定技，当你使用非转化且非虚拟的【杀】结算结束后，你须选择一项：1.摸一张牌，令你于本回合内使用【杀】的次数上限+1；2.摸三张牌，令你于本回合内不能使用【杀】。",
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
