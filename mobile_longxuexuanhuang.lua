local extension = Package("mobile_longxuexuanhuang")
extension.extensionName = "mobile"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["mobile_longxuexuanhuang"] = "手杀-龙血玄黄",
  ["mob_sp"] = "手杀SP",
  ["mobile2"] = "手杀",
}

local caomao = General(extension, "mobile__caomao", "wei", 3)
local caomao2 = General(extension, "mobile2__caomao", "wei", 3)
local caomaoWin = fk.CreateActiveSkill{ name = "mobile__caomao_win_audio" }
caomaoWin.package = extension
Fk:addSkill(caomaoWin)

caomao2.total_hidden = true

Fk:loadTranslationTable{
  ["mobile__caomao"] = "曹髦",
  ["#mobile__caomao"] = "向死存魏",
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
      if
        player:hasSkill("weitong") and
        table.find(room.alive_players, function(p) return p ~= player and p.kingdom == "wei" end)
      then
        num = 60
      end
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
      and table.find(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
    local listNames = {"log_spade", "log_club", "log_heart", "log_diamond"}
    local listCards = {{}, {}, {}, {}}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit and not player:prohibitDiscard(id) then
        table.insertIfNeed(listCards[suit], id)
      end
    end
    local choices = U.askForChooseCardList(room, player, listNames, listCards, 1, 1, self.name, "#mobile_qianlong__qingzheng-card")
    if #choices == 1 then
      local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
      "#mobile_qianlong__qingzheng-choose", self.name, true)
      if #to > 0 then
        self.cost_data = {choice = choices, tos = to}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = self.cost_data.choice
    local to = room:getPlayerById(self.cost_data.tos[1])
    local my_throw = table.filter(player.player_cards[Player.Hand], function (id)
      return not player:prohibitDiscard(Fk:getCardById(id)) and table.contains(choices, Fk:getCardById(id):getSuitString(true))
    end)
    room:throwCard(my_throw, self.name, player, player)
    if player.dead then return end
    local to_throw = {}
    local listNames = {"log_spade", "log_club", "log_heart", "log_diamond"}
    local listCards = {{}, {}, {}, {}}
    local can_throw
    for _, id in ipairs(to.player_cards[Player.Hand]) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(listCards[suit], id)
        can_throw = true
      end
    end
    if can_throw then
      local choice = U.askForChooseCardList(room, player, listNames, listCards, 1, 1, self.name,
      "#mobile_qianlong__qingzheng-throw::"..to.id..":"..#my_throw, false, false)
      if #choice == 1 then
        to_throw = table.filter(to.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getSuitString(true) == choice[1] end)
      end
    end
    room:throwCard(to_throw, self.name, to, player)
    if #my_throw > #to_throw then
      if not to.dead then
        room:doIndicate(player.id, {to.id})
        room:damage{ from = player, to = to, damage = 1, skillName = self.name }
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["mobile_qianlong__qingzheng"] = "清正",
  [":mobile_qianlong__qingzheng"] = "持恒技，出牌阶段开始时，你可以选择一名有手牌的其他角色，你弃置一种花色的所有手牌，" ..
  "然后观看其手牌并选择一种花色的牌，其弃置所有该花色的手牌。若如此做且你以此法弃置的牌数大于其弃置的手牌，你对其造成1点伤害。",
  ["#mobile_qianlong__qingzheng-card"] = "清正：你可弃置1种花色的手牌，观看1名角色手牌，弃其1种花色的手牌",
  ["#mobile_qianlong__qingzheng-choose"] = "清正：选择一名其他角色，观看其手牌并弃置其中一种花色",
  ["#mobile_qianlong__qingzheng-throw"] = "清正：弃置 %dest 一种花色的手牌，若弃置张数小于 %arg，对其造成伤害",

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
        room:obtainCard(player, cards[1], false, fk.ReasonPrey)
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
    return
      #selected == 0 and
      to_select ~= Self.id and
      Self:getMark("mobile_qianlong__fangzhu_target") ~= to_select and
      Self:getMark("mobile_qianlong__fangzhu_target-turn") ~= to_select
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if player:getMark("mobile_qianlong__fangzhu_target-turn") ~= 0 then
      room:setPlayerMark(player, "mobile_qianlong__fangzhu_target-turn", 0)
    end
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
  refresh_events = { fk.TurnStart, fk.AfterTurnEnd },
  can_refresh = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return target == player and player:getMark("mobile_qianlong__fangzhu_target") ~= 0
    end

    return
      target == player and
      table.find(
        { "@mobile_qianlong__fangzhu_limit", "@@mobile_qianlong__fangzhu_skill_nullified" },
        function(markName) return player:getMark(markName) ~= 0 end
      )
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local fangzhuTarget = player:getMark("mobile_qianlong__fangzhu_target")
      room:setPlayerMark(player, "mobile_qianlong__fangzhu_target", 0)
      room:setPlayerMark(player, "mobile_qianlong__fangzhu_target-turn", fangzhuTarget)
    else
      for _, markName in ipairs({ "@mobile_qianlong__fangzhu_limit", "@@mobile_qianlong__fangzhu_skill_nullified" }) do
        if player:getMark(markName) ~= 0 then
          room:setPlayerMark(player, markName, 0)
        end
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
  [":mobile_qianlong__fangzhu"] = "持恒技，出牌阶段限一次，你可以选择一项令一名其他角色执行" ..
  "（不可选择从你的上个回合开始至今期间你上次以此法选择的角色）：1.直到其下个回合结束，其只能使用锦囊牌；2.直到其下个回合结束，其所有技能失效。",
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
}
Fk:loadTranslationTable{
  ["weitong"] = "卫统",
  [":weitong"] = "持恒技，主公技，若场上有存活的其他魏势力角色，则你的〖潜龙〗于游戏开始时获得的道心值改为60点。",

  ["$weitong1"] = "手无实权难卫统，朦胧成睡，睡去还惊。",
}

weitong.permanent_skill = true
caomao:addSkill(weitong)

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
    local room = player.room
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Play and #room.alive_players > 1
      elseif event == fk.TargetSpecified and player.phase == Player.Play then
        local to = room:getPlayerById(data.to)
        return
          not to.dead and to:getMark("@@kuangli-turn") > 0 and
          player:getMark("kuangli-phase") <
            (table.contains({"m_1v2_mode", "brawl_mode"}, room.settings.gameMode) and 1 or 2)
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
  [":kuangli"] = "锁定技，出牌阶段开始时，令随机数量（至少为一）名其他角色获得“狂戾”标记直到回合结束；每阶段限两次" ..
  "（若为斗地主，则改为限一次），当你于出牌阶段内使用牌指定一名拥有“狂戾”标记的角色为目标后，你随机弃置你与其各一张牌，然后你摸两张牌。",
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
    local all_choices = {"panxiang2"}
    if data.from and not data.from.dead then
      table.insert(all_choices, 1, "panxiang1-from:" .. data.from.id)
    else
      table.insert(all_choices, 1, "panxiang1")
    end
    table.insert(all_choices, "Cancel")
    local choices = table.simpleClone(all_choices)
    local mark = target:getMark("@panxiang")
    if type(mark) == "string" then
      local n = string.match(mark, "mkpanxiang(%d)")
      if n then table.remove(choices, n) end
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#panxiang-invoke::"..target.id, false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = {choice, table.indexOf(all_choices, choice)}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "panxiang_"..target.id, self.cost_data)
    room:setPlayerMark(target, "@panxiang", "mkpanxiang" .. self.cost_data[2])
    room:notifySkillInvoked(player, self.name, "support")
    room:doIndicate(player.id, {target.id})
    if self.cost_data[1] == "panxiang2" then
      player:broadcastSkillInvoke(self.name, math.random(1, 2))
      data.damage = data.damage + 1
      if not target.dead then
        room:drawCards(target, 3, self.name)
      end
    else
      player:broadcastSkillInvoke(self.name, math.random(3, 4))
      data.damage = data.damage - 1
      if data.from and not data.from.dead then
        room:drawCards(data.from, 2, self.name)
      end
    end
  end,
}
local mobile__chenjie = fk.CreateTriggerSkill{
  name = "mobile__chenjie",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:hasSkill("panxiang", true) and player:getMark("panxiang_"..target.id) ~= 0
  end,
  on_use = function(self, event, target, player, data)
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
  ["illustrator:mobile__simafu"] = "鬼画府",

  ["panxiang"] = "蹒襄",
  [":panxiang"] = "当一名角色受到伤害时，你可以选择一项（不能选择上次对该角色发动时选择的选项）：1.令此伤害-1，然后伤害来源摸两张牌；"..
  "2.令此伤害+1，然后其摸三张牌。",
  ["mobile__chenjie"] = "臣节",
  [":mobile__chenjie"] = "锁定技，若你有〖蹒襄〗，当一名成为过蹒襄目标的角色死亡后，你弃置你区域内所有牌，然后摸四张牌。",

  ["#panxiang-invoke"] = "蹒襄：你可以选择一项：",
  ["panxiang1"] = "伤害-1",
  ["panxiang1-from"] = "伤害-1，%src摸两张牌",
  ["panxiang2"] = "伤害+1，其摸三张牌",
  ["@panxiang"] = "蹒襄",
  ["mkpanxiang1"] = "－",
  ["mkpanxiang2"] = "＋",

  ["$panxiang1"] = "殿下当以国事为重，奈何效匹夫之孝乎？",
  ["$panxiang2"] = "诸卿当早拜嗣君，以镇海内，而但哭邪？",
  ["$panxiang3"] = "身负托孤之重，但坐论清谈，此亦可乎？",
  ["$panxiang4"] = "老臣受命督军，自竭拒吴蜀于疆外。",

  ["$mobile__chenjie1"] = "杀陛下者，臣之罪也！",
  ["$mobile__chenjie2"] = "身为魏臣，终不背魏。",
  ["~mobile__simafu"] = "生此篡逆之事，罪臣难辞其咎……",
}

local mobileWenqin = General(extension, "mobile__wenqin", "wei", 4)
Fk:loadTranslationTable{
  ["mobile__wenqin"] = "文钦",
  ["#mobile__wenqin"] = "淮山骄腕",
  -- ["illustrator:mobile__wenqin"] = "鬼画府",
  ["~mobile__wenqin"] = "伺君兵败之日，必报此仇于九泉！",
}

local beiming = fk.CreateTriggerSkill{
  name = "beiming",
  anim_type = "drawcard",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(
      player,
      table.map(room.alive_players, Util.IdMapper),
      1,
      2,
      "#beiming-choose",
      self.name
    )

    if #tos == 0 then
      return false
    end

    self.cost_data = tos
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data
    room:sortPlayersByAction(targets)
    for _, toId in ipairs(targets) do
      local to = room:getPlayerById(toId)
      if to:isAlive() then
        local suits = {}
        for _, id in ipairs(to:getCardIds("h")) do
          local card = Fk:getCardById(id)
          if card.suit ~= Card.NoSuit then
            table.insertIfNeed(suits, card.suit)
          end
        end

        local weapons = {}
        for _, id in ipairs(room.draw_pile) do
          local card = Fk:getCardById(id)
          if card.sub_type == Card.SubtypeWeapon and card.attack_range == #suits then
            table.insert(weapons, id)
          end
        end

        if #weapons > 0 then
          room:obtainCard(to, table.random(weapons), true, fk.ReasonPrey, to.id, self.name)
        end
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["beiming"] = "孛明",
  [":beiming"] = "游戏开始时，你可以令至多两名角色分别从牌堆中随机获得一张攻击范围为X的武器牌（X为其手牌中的花色数）。",
  ["#beiming-choose"] = "孛明：你可令至多两名角色分别获得武器牌",

  ["$beiming1"] = "孛星起于吴楚，吾等应举刀兵！",
  ["$beiming2"] = "尽点淮南兵马，以讨司马逆臣！",
}

mobileWenqin:addSkill(beiming)

local choumang = fk.CreateTriggerSkill{
  name = "choumang",
  anim_type = "control",
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.trueName == "slash" and
      player:hasSkill(self) and
      U.isOnlyTarget(player.room:getPlayerById(data.to), data, event) and
      player:usedSkillTimes(self.name) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = { "choumang_damage", "choumang_prey", "Cancel" }
    if
      room:getPlayerById(data.from):getEquipment(Card.SubtypeWeapon) or
      room:getPlayerById(data.to):getEquipment(Card.SubtypeWeapon)
    then
      table.insert(choices, "beishui")
    end

    local choice = room:askForChoice(
      player,
      choices,
      self.name,
      "#choumang-choose::" .. data.to,
      false, 
      { "beishui", "choumang_damage", "choumang_prey", "Cancel" }
    )

    if choice == "Cancel" then
      return false
    end

    self.cost_data = choice
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data

    if choice == "beishui" then
      local players = { data.from, data.to }
      room:sortPlayersByAction(players)
      for _, pId in ipairs(players) do
        local p = room:getPlayerById(pId)
        local weapons = p:getEquipments(Card.SubtypeWeapon)
        if #weapons > 0 then
          room:throwCard(weapons, self.name, p, player)
        end
      end
    end

    if choice == "beishui" or choice == "choumang_damage" then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end

    if choice == "beishui" or choice == "choumang_prey" then
      data.extra_data = data.extra_data or {}
      data.extra_data.choumangPreyPlayers = { player.id, data.from == player.id and data.to or data.from }
    end
  end,
}
local choumangDelay = fk.CreateTriggerSkill{
  name = "#choumang_delay",
  mute = true,
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return
      player:isAlive() and
      data.card.trueName == "slash" and
      (data.extra_data or {}).choumangPreyPlayers and
      data.extra_data.choumangPreyPlayers[1] == player.id
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      local to = room:getPlayerById(data.extra_data.choumangPreyPlayers[2])
      if not p:isAllNude() and ((player:isAlive() and player:distanceTo(p) <= 1) or (to:isAlive() and to:distanceTo(p) <= 1)) then
        table.insert(targets, p.id)
      end
    end

    if #targets == 0 then
      return false
    end

    local to = room:askForChoosePlayers(player, targets, 1, 1, "#choumang_delay-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askForCardChosen(player, room:getPlayerById(self.cost_data), "hej", self.name)
    room:obtainCard(player, id, false, fk.ReasonPrey, player.id, self.name)
  end,
}
Fk:loadTranslationTable{
  ["choumang"] = "仇铓",
  [":choumang"] = "当你使用【杀】指定唯一目标后或当你成为【杀】的唯一目标后，你可以选择一项：1.令此【杀】伤害+1；" ..
  "2.令此【杀】被抵消后，你获得你与其距离为1以内的一名其他角色区域内的一张牌。背水：弃置你与其装备区里的武器牌（你或其装备区里有武器牌才可选择）。",
  ["#choumang_delay"] = "仇铓",
  ["choumang_damage"] = "此【杀】伤害+1",
  ["choumang_prey"] = "此【杀】被抵消后你获得角色牌",
  ["#choumang-choose"] = "仇铓：此【杀】目标为%dest",
  ["#choumang_delay-choose"] = "仇铓：你可获得其中一名角色区域内的一张牌",

  ["$choumang1"] = "司马氏之罪，尽洛水亦难清！",
  ["$choumang2"] = "汝司马氏世受魏恩，今安敢如此！",
}

choumang:addRelatedSkill(choumangDelay)
mobileWenqin:addSkill(choumang)

local mobileSimazhou = General(extension, "mobile__simazhou", "wei", 4)
mobileSimazhou.subkingdom = "jin"
Fk:loadTranslationTable{
  ["mobile__simazhou"] = "司马伷",
  ["#mobile__simazhou"] = "恭温克己",
  -- ["illustrator:mobile__simazhou"] = "鬼画府",
  ["~mobile__simazhou"] = "臣所求唯莽伏太妃陵次，分国封四子而已。",
}

local bifeng = fk.CreateTriggerSkill{
  name = "bifeng",
  anim_type = "control",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      (
        data.card.type == Card.TypeBasic or
        data.card:isCommonTrick()
      ) and
      #AimGroup:getAllTargets(data.tos) < 5 and
      player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#bifeng-invoke:" .. data.from .. "::" .. data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    local users = data.extra_data.bifengUsers or {}
    table.insertIfNeed(users, player.id)
    data.extra_data.bifengUsers = users
    AimGroup:cancelTarget(data, player.id)

    return true
  end,
}
local bifengDelay = fk.CreateTriggerSkill{
  name = "#bifeng_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    local bifengUsers = (data.extra_data or {}).bifengUsers
    return
      bifengUsers and
      player:isAlive() and
      table.contains(bifengUsers, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local useEvent = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not useEvent then
      return false
    end

    if 
      #U.getEventsByRule(
        room,
        GameEvent.UseCard,
        1,
        function(e)
          local use = e.data[1]
          return use.from ~= player.id and use.responseToEvent.card == data.card
        end,
        useEvent.id
      ) > 0 or
      #U.getEventsByRule(
        room,
        GameEvent.RespondCard,
        1,
        function(e)
          local response = e.data[1]
          return response.from ~= player.id and response.responseToEvent.card == data.card
        end,
        useEvent.id
      ) > 0
    then
      player:drawCards(2, self.name)
    else
      room:loseHp(player, 1, self.name)
    end
  end,
}
Fk:loadTranslationTable{
  ["bifeng"] = "避锋",
  [":bifeng"] = "当你成为基本牌或普通锦囊牌的目标时，若目标数不大于4，则你可取消之。若如此做，" ..
  "此牌结算结束后，若没有其他角色响应过此牌，则你失去1点体力，否则你摸两张牌。",
  ["#bifeng_delay"] = "避锋",
  ["#bifeng-invoke"] = "避锋：你可以取消%src对你使用的%arg，结算后你失去体力或摸牌",

  ["$bifeng1"] = "事已至此，当速禀南阙之急。",
  ["$bifeng2"] = "陛下今日所为，实令臣民失望。",
  ["$bifeng3"] = "众士暂避其锋，万不可冲撞圣驾。",
}

bifeng:addRelatedSkill(bifengDelay)
mobileSimazhou:addSkill(bifeng)

local suwang = fk.CreateTriggerSkill{
  name = "suwang",
  anim_type = "drawcard",
  events = {fk.TurnEnd, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then
      return false
    end

    if event == fk.TurnEnd then
      if player:getMark("suwang_aimed-turn") == 0 then
        return false
      end

      local room = player.room
      if table.contains({ "m_2v2_mode" }, room.settings.gameMode) then
        local damageNum = 0
        U.getActualDamageEvents(
          room,
          1,
          function(e)
            local damage = e.data[1]
            if damage.to == player then
              damageNum = damageNum + damage.damage
            end

            return damageNum > 1
          end
        )

        return damageNum < 2
      else
        return #U.getActualDamageEvents(room, 1, function(e) return e.data[1].to == player end) == 0
      end
    end

    return target == player and player.phase == Player.Draw and #player:getPile("suwang") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return
      event == fk.TurnEnd or
      player.room:askForSkillInvoke(player, self.name, data, "#suwang-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      player:addToPile("suwang", room:getNCards(1), false, self.name, player.id)
    else
      room:obtainCard(player, player:getPile("suwang"), false, fk.ReasonPrey, player.id, self.name)
      local tos = room:askForChoosePlayers(
        player,
        table.map(room:getOtherPlayers(player), Util.IdMapper),
        1,
        1, 
        "#suwang-choose",
        self.name
      )

      if #tos > 0 then
        room:getPlayerById(tos[1]):drawCards(2, self.name)
      end

      return true
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function (self, event, target, player, data)
    return target == player and player.room.current == player and #TargetGroup:getRealTargets(data.tos) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, pId in ipairs(TargetGroup:getRealTargets(data.tos)) do
      local p = room:getPlayerById(pId)
      if p:getMark("suwang_aimed-turn") == 0 then
        room:setPlayerMark(p, "suwang_aimed-turn", 1)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["suwang"] = "宿望",
  [":suwang"] = "一名角色的回合结束时，若其于此回合内使用牌时指定过你为目标且你未受到过伤害（若为2v2模式，则改为受到过的伤害值不大于1），" ..
  "则你将牌堆顶一张牌置于你的武将牌上，称为“宿望”；摸牌阶段，若你有“宿望”，则你可以获得你的所有“宿望”，然后你可令一名其他角色摸两张牌。",
  ["#suwang-invoke"] = "宿望：你可获得你的“宿望”牌，然后可令一名其他角色摸两张牌",
  ["#suwang-choose"] = "宿望：你可令一名其他角色摸两张牌",

  ["$suwang1"] = "国治吏和，百姓自存怀化之心。",
  ["$suwang2"] = "居上处事，当极绥怀之人。",
}

mobileSimazhou:addSkill(suwang)

return extension
