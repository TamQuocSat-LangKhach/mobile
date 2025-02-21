
local U = require "packages/utility/utility"

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
    local cards = player.room:askForCard(player, 1, 1, true, self.name, true, ".|.|"..data.card:getSuitString(),
    "#chenjie-invoke::"..target.id..":"..data.card:getSuitString(true)..":"..data.reason)
    if #cards > 0 then
      self.cost_data = cards[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(Fk:getCardById(self.cost_data), player, data, self.name)
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
  [":chenjie"] = "当一名角色的判定牌生效前，你可以用一张与判定牌相同花色的牌代替之，然后你摸两张牌。",
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
    room:sortPlayersByAction(tos)
    self.cost_data = {tos = tos}
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, toId in ipairs(self.cost_data.tos) do
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
      AimGroup:isOnlyTarget(player.room:getPlayerById(data.to), data) and
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

    self.cost_data = {choice = choice, tos = {data.from == player.id and data.to or data.from}}
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data.choice

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
      data.extra_data.choumangPreyPlayers = data.extra_data.choumangPreyPlayers or {}
      table.insert(data.extra_data.choumangPreyPlayers, { player.id, self.cost_data.tos[1] })
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
      table.find(data.extra_data.choumangPreyPlayers, function(info) return info[1] == player.id end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = table.find(data.extra_data.choumangPreyPlayers, function(info) return info[1] == player.id end)[2]
    to = room:getPlayerById(to)
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if not p:isAllNude() and not p:isRemoved()
      and ((player:distanceTo(p) <= 1) or (to:isAlive() and to:compareDistance(p, 1, "<="))) then
        table.insert(targets, p.id)
      end
    end

    if #targets == 0 then
      return false
    end

    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#choumang_delay-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
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
  [":choumang"] = "每回合限一次，当你使用【杀】指定唯一目标后或当你成为【杀】的唯一目标后，你可以选择一项：1.令此【杀】伤害+1；" ..
  "2.令此【杀】被抵消后，你可以获得你与其距离为1以内的一名其他角色区域内的一张牌。背水：弃置你与其装备区里的武器牌（你或其装备区里有武器牌才可选择）。",
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

    if #room.logic:getEventsByRule(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        return use.from ~= player.id and use.responseToEvent.card == data.card
      end, useEvent.id) > 0 or
      #room.logic:getEventsByRule(GameEvent.RespondCard, 1, function(e)
        local response = e.data[1]
        return response.from ~= player.id and response.responseToEvent.card == data.card
      end, useEvent.id) > 0
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
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("2v2_mode") then
      return "suwang_2v2"
    else
      return "suwang_role_mode"
    end
  end,
  derived_piles = "$suwang",
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
        room.logic:getActualDamageEvents(1, function(e)
          local damage = e.data[1]
          if damage.to == player then
            damageNum = damageNum + damage.damage
          end

          return damageNum > 1
        end
        )

        return damageNum < 2
      else
        return #room.logic:getActualDamageEvents(1, function(e)
          return e.data[1].to == player
        end) == 0
      end
    end

    return target == player and player.phase == Player.Draw and #player:getPile("$suwang") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return
      event == fk.TurnEnd or
      player.room:askForSkillInvoke(player, self.name, data, "#suwang-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      player:addToPile("$suwang", room:getNCards(1), false, self.name, player.id)
    else
      room:obtainCard(player, player:getPile("$suwang"), false, fk.ReasonPrey, player.id, self.name)
      local tos = room:askForChoosePlayers(
        player,
        table.map(room:getOtherPlayers(player, false), Util.IdMapper),
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
  "则你将牌堆顶一张牌置于你的武将牌上，称为“宿望”；摸牌阶段，若你有“宿望”，则你可以改为获得你的所有“宿望”，然后你可令一名其他角色摸两张牌。",
  [":suwang_role_mode"] = "一名角色的回合结束时，若其于此回合内使用牌时指定过你为目标且你未受到过伤害，" ..
  "则你将牌堆顶一张牌置于你的武将牌上，称为“宿望”；摸牌阶段，若你有“宿望”，则你可以改为获得你的所有“宿望”，然后你可令一名其他角色摸两张牌。",
  [":suwang_2v2"] = "一名角色的回合结束时，若其于此回合内使用牌时指定过你为目标且你受到过的伤害值不大于1，" ..
  "则你将牌堆顶一张牌置于你的武将牌上，称为“宿望”；摸牌阶段，若你有“宿望”，则你可以改为获得你的所有“宿望”，然后你可令一名其他角色摸两张牌。",
  ["$suwang"] = "宿望",
  ["#suwang-invoke"] = "宿望：你可获得你的“宿望”牌，然后可令一名其他角色摸两张牌",
  ["#suwang-choose"] = "宿望：你可令一名其他角色摸两张牌",

  ["$suwang1"] = "国治吏和，百姓自存怀化之心。",
  ["$suwang2"] = "居上处事，当极绥怀之人。",
}

mobileSimazhou:addSkill(suwang)

local mobile__jiachong = General(extension, "mobile__jiachong", "qun", 3)

local mobile__beini = fk.CreateActiveSkill{
  name = "mobile__beini",
  anim_type = "drawcard",
  prompt = "#mobile__beini",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select).hp >= Self.hp
  end,
  target_num = 1,
  interaction = UI.ComboBox { choices = {"mobile__beini_own", "mobile__beini_other"} },
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local drawer = self.interaction.data == "mobile__beini_own" and player or to
    local from = self.interaction.data == "mobile__beini_other" and player or to
    drawer:drawCards(2, self.name)
    if drawer.dead or from.dead then return end
    local all_choices = {"mobile__beini_slash:"..drawer.id, "mobile__beini_prey:"..drawer.id}
    local choices = {}
    if from:canUseTo(Fk:cloneCard("slash"), drawer, {bypass_distances = true, bypass_times = true}) then
      table.insert(choices, all_choices[1])
    end
    if #drawer:getCardIds("ej") > 0 then
      table.insert(choices, all_choices[2])
    end
    if #choices == 0 then return end
    local choice = room:askForChoice(from, choices, self.name, nil, false, all_choices)
    if choice == all_choices[1] then
      room:useVirtualCard("slash", nil, from, drawer, self.name, true)
    else
      local card = room:askForCardChosen(from, drawer, "ej", self.name)
      room:obtainCard(from, card, true, fk.ReasonPrey, from.id, self.name)
    end
  end,
}
mobile__jiachong:addSkill(mobile__beini)

local mobile__dingfa = fk.CreateTriggerSkill{
  name = "mobile__dingfa",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and player.phase == Player.Discard
    and player:getMark("@mobile__dingfa-turn") >= 4
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"mobile__dingfa_throw", "Cancel"}
    if player:isWounded() then table.insert(choices, 2, "mobile__dingfa_recover") end
    local choice = room:askForChoice(player, choices, self.name, nil, false, {"mobile__dingfa_throw", "mobile__dingfa_recover", "Cancel"})
    if choice == "Cancel" then return false end
    if choice == "mobile__dingfa_throw" then
      local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#mobile__dingfa-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = {tos = tos}
        return true
      end
    else
      self.cost_data = nil
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == nil then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    else
      local to = room:getPlayerById(self.cost_data.tos[1])
      if to:isNude() then return end
      local cards = room:askForCardsChosen(player, to, 1, 2, "he", self.name)
      room:throwCard(cards, self.name, to, player)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self, true) and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local num = #U.getLostCardsFromMove(player, data)
    if num > 0 then
      player.room:addPlayerMark(player, "@mobile__dingfa-turn", num)
    end
  end,

  on_lose = function (self, player)
    player.room:setPlayerMark(player, "@mobile__dingfa-turn", 0)
  end,
}
mobile__jiachong:addSkill(mobile__dingfa)

Fk:loadTranslationTable{
  ["mobile__jiachong"] = "贾充",
  ["#mobile__jiachong"] = "凶凶踽行",
  ["designer:mobile__jiachong"] = "Loun老萌",
  ["illustrator:mobile__jiachong"] = "铁杵文化",
  ["cv:mobile__jiachong"] = "虞晓旭",

  ["mobile__beini"] = "悖逆",
  [":mobile__beini"] = "出牌阶段限一次，你可以选择一名体力值不小于你的角色，令你或其摸两张牌，然后未摸牌的角色选择一项：1.视为对摸牌的角色使用一张无距离限制、无次数限制且不计入使用次数的【杀】；2.获得摸牌的角色场上的一张牌。",
  ["#mobile__beini"] = "悖逆：选择一名体力值不小于你的角色，令你或其摸两张牌，未摸牌角色选择出杀或偷牌",
  ["mobile__beini_own"] = "你摸两张牌，其选一项",
  ["mobile__beini_other"] = "其摸两张牌，你选一项",
  ["mobile__beini_slash"] = "视为对 %src 使用【杀】",
  ["mobile__beini_prey"] = "获得 %src 场上一张牌",
  ["mobile__dingfa"] = "定法",
  [":mobile__dingfa"] = "弃牌阶段结束时，若本回合你失去的牌数不小于4，你可以选择一项：1.回复1点体力；2.弃置一名角色至多两张牌。",
  ["@mobile__dingfa-turn"] = "定法",
  ["mobile__dingfa_throw"] = "弃置一名角色至多2张牌",
  ["mobile__dingfa_recover"] = "回复1点体力",
  ["#mobile__dingfa-choose"] = "定法：选择一名角色，弃置其至多2张牌",

  ["$mobile__beini1"] = "今日污无用清名，明朝自得新圣褒嘉。",
  ["$mobile__beini2"] = "吾佐奉朝日暖旭，又何惮落月残辉？",
  ["$mobile__dingfa1"] = "峻礼教之防，准五服以制罪。",
  ["$mobile__dingfa2"] = "礼律并重，臧善否恶，宽简弼国。",
  ["~mobile__jiachong"] = "此生从势忠命，此刻，只乞不获恶谥……",
}


local simazhao = General(extension, "mobile__simazhao", "wei", 3)
table.insert(Fk.lords, "mobile__simazhao") -- 没有主公技的常备主
local simazhao2 = General(extension, "mobile2__simazhao", "qun", 3)
simazhao2.hidden = true

local simazhaoWin = fk.CreateActiveSkill{ name = "mobile__simazhao_win_audio" }
simazhaoWin.package = extension
Fk:addSkill(simazhaoWin)
local simazhao2Win = fk.CreateActiveSkill{ name = "mobile2__simazhao_win_audio" }
simazhao2Win.package = extension
Fk:addSkill(simazhao2Win)

Fk:loadTranslationTable{
  ["mobile__simazhao"] = "司马昭",
  ["#mobile__simazhao"] = "独祅吞天",
  ["illustrator:mobile__simazhao"] = "腥鱼仔",
  ["$mobile__simazhao_win_audio"] = "明日正为吉日，当举禅位之典。",
  ["~mobile__simazhao"] = "曹髦小儿竟有如此肝胆……我实不甘。",

  ["mobile2__simazhao"] = "司马昭",
  ["#mobile2__simazhao"] = "独祅吞天",
  ["illustrator:mobile2__simazhao"] = "腥鱼仔",
  ["$mobile2__simazhao_win_audio"] = "万里山河，终至我司马一家。",
  ["~mobile2__simazhao"] = "愿我晋祚，万世不易，国运永昌。",
}

local xiezheng = fk.CreateTriggerSkill{
  name = "mobile__xiezheng",
  anim_type = "control",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("role_mode") then
      if player:getMark("mobile__xiezheng_updata") > 0 then
        return "mobile__xiezheng_role_mode2"
      else
        return "mobile__xiezheng_role_mode"
      end
    elseif Fk:currentRoom():isGameMode("1v2_mode") then
      return "mobile__xiezheng_1v2"
    else
      return "mobile__xiezheng_2v2"
    end
  end,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player.room:isGameMode("1v2_mode") and player:usedSkillTimes(self.name, Player.HistoryGame) > 0 then return false end
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      table.find(player.room.alive_players, function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng()
    end)
    local num = room:isGameMode("1v2_mode") and 2 or 1
    local debuff = " "
    if room:isGameMode("role_mode") and player:getMark("mobile__xiezheng_updata") == 0 then
      debuff = ":mobile__xiezheng_debuff"
    end
    local prompt = "#mobile__xiezheng-choose:::"..num..":"..debuff
    
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, num,
    prompt, self.name, true)
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data.tos) do
      local p = room:getPlayerById(id)
      if not p.dead and not p:isKongcheng() then
        room:moveCards({
          ids = table.random(p:getCardIds("h"), 1),
          from = id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = self.name,
        })
      end
    end
    if player.dead then return end
    local extra_data = {}
    if room:isGameMode("role_mode") and player:getMark("mobile__xiezheng_updata") == 0 then
      local must_targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return p.kingdom == player.kingdom
      end)
      if #must_targets > 0 then
        extra_data.must_targets = table.map(must_targets, Util.IdMapper)
      end
    end
    local use = U.askForUseVirtualCard(room, player, "mobile__enemy_at_the_gates", nil, self.name, "#mobile__xiezheng-use", false, nil, nil, nil, extra_data)
    if use and not player.dead and not (use.extra_data and use.extra_data.mobile__xiezheng_damageDealt) then
      room:loseHp(player, 1, self.name)
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card and data.card.trueName == "slash"
  end,
  on_refresh = function (self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent().parent
    while e do
      if e.event == GameEvent.UseCard then
        local use = e.data[1]
        if use.card.name == "mobile__enemy_at_the_gates" and table.contains(use.card.skillNames, "mobile__xiezheng") then
          use.extra_data = use.extra_data or {}
          use.extra_data.mobile__xiezheng_damageDealt = true
          return
        end
      end
      e = e.parent
    end
  end,
}
simazhao:addSkill(xiezheng)
simazhao2:addSkill("mobile__xiezheng")

Fk:loadTranslationTable{
  ["mobile__xiezheng"] = "挟征",
  [":mobile__xiezheng"] = "结束阶段，你可以令至多一名角色（若为斗地主模式，改为两名，本局游戏限一次）依次将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】（若为身份模式，优先指定同势力角色为目标），结算后若未造成过伤害，你失去1点体力。",
  [":mobile__xiezheng_role_mode"] = "结束阶段，你可以令一名角色将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】（需优先指定同势力角色为目标），结算后若未造成过伤害，你失去1点体力。",
  [":mobile__xiezheng_role_mode2"] = "结束阶段，你可以令一名角色将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】，结算后若未造成过伤害，你失去1点体力。",
  [":mobile__xiezheng_1v2"] = "每局游戏限一次，结束阶段，你可以令至多两名角色依次将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】，结算后若未造成过伤害，你失去1点体力。",
  [":mobile__xiezheng_2v2"] = "结束阶段，你可以令一名角色将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】，结算后若未造成过伤害，你失去1点体力。",
  ["#mobile__xiezheng-choose"] = "挟征：令至多%arg名角色依次将随机一张手牌置于牌堆顶，然后你视为使用一张%arg2【兵临城下】！",
  ["#mobile__xiezheng-use"] = "挟征：视为使用一张【兵临城下】！若未造成伤害，你失去1点体力",
  ["mobile__xiezheng_debuff"] = "优先指定同势力角色为目标的",

  ["$mobile__xiezheng1"] = "烈祖明皇帝乘舆仍出，陛下何妨效之。",
  ["$mobile__xiezheng2"] = "陛下宜誓临戎，使将士得凭天威。",
  ["$mobile__xiezheng3"] = "既得众将之力，何愁贼不得平？",--挟征（第二形态）
  ["$mobile__xiezheng4"] = "逆贼起兵作乱，诸位无心报国乎？",--挟征（第二形态）
}

local qiantun = fk.CreateActiveSkill{
  name = "mobile__qiantun",
  anim_type = "control",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "mobile__qiantun_1v2"
    else
      return "mobile__qiantun_role_mode"
    end
  end,
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__qiantun",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askForCard(target, 1, 999, false, self.name, false, nil, "#mobile__qiantun-ask:"..player.id)
    target:showCards(cards)
    cards = table.filter(cards, function (id)
      return table.contains(target:getCardIds("h"), id)
    end)
    if player.dead or target.dead or #cards == 0 or not player:canPindian(target) then return end
    local pindian = {
      from = player,
      tos = {target},
      reason = self.name,
      fromCard = nil,
      results = {},
      extra_data = {
        mobile__qiantun = {
          to = target.id,
          cards = cards,
        },
      },
    }
    room:pindian(pindian)
    if player.dead or target.dead then return end
    if pindian.results[target.id].winner == player then
      cards = table.filter(target:getCardIds("h"), function (id)
        return table.contains(cards, id)
      end)
    else
      cards = table.filter(target:getCardIds("h"), function (id)
        return not table.contains(cards, id)
      end)
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
    end
    if not player.dead and not player:isKongcheng() then
      player:showCards(player:getCardIds("h"))
    end
  end,
}
local qiantun_trigger = fk.CreateTriggerSkill{
  name = "#mobile__qiantun_trigger",
  mute = true,
  events = {fk.StartPindian},
  can_trigger = function(self, event, target, player, data)
    if player == data.from and data.reason == "mobile__qiantun" and data.extra_data and data.extra_data.mobile__qiantun then
      for _, to in ipairs(data.tos) do
        if not (data.results[to.id] and data.results[to.id].toCard) and
          data.extra_data.mobile__qiantun.to == to.id and
          table.find(data.extra_data.mobile__qiantun.cards, function (id)
            return table.contains(to:getCardIds("h"), id)
          end) then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, to in ipairs(data.tos) do
      if not (to.dead or to:isKongcheng() or (data.results[to.id] and data.results[to.id].toCard)) and
        data.extra_data.mobile__qiantun.to == to.id then
        local cards = table.filter(data.extra_data.mobile__qiantun.cards, function (id)
          return table.contains(to:getCardIds("h"), id)
        end)
        if #cards > 0 then
          local card = room:askForCard(to, 1, 1, false, "qiantun", false, tostring(Exppattern{ id = cards }),
            "#mobile__qiantun-pindian:"..data.from.id)
          data.results[to.id] = data.results[to.id] or {}
          data.results[to.id].toCard = Fk:getCardById(card[1])
        end
      end
    end
  end,
}
qiantun:addRelatedSkill(qiantun_trigger)
qiantun:addAttachedKingdom("wei")
simazhao:addSkill(qiantun)

Fk:loadTranslationTable{
  ["mobile__qiantun"] = "谦吞",
  [":mobile__qiantun"] = "魏势力技，出牌阶段限一次，你可以令一名有手牌的其他角色展示至少一张手牌，然后你与其拼点（其仅能用展示牌拼点）。"..
  "若你赢，你获得其展示的手牌；若你没赢，你获得其未展示的手牌。（若为斗地主模式，至多获得两张）",
  [":mobile__qiantun_role_mode"] = "魏势力技，出牌阶段限一次，你可以令一名有手牌的其他角色展示至少一张手牌，然后你与其拼点（其仅能用展示牌拼点）。"..
  "若你赢，你获得其展示的手牌；若你没赢，你获得其未展示的手牌。",
  [":mobile__qiantun_1v2"] = "魏势力技，出牌阶段限一次，你可以令一名有手牌的其他角色展示至少一张手牌，然后你与其拼点（其仅能用展示牌拼点）。"..
  "若你赢，你获得其展示的手牌；若你没赢，你获得其未展示的手牌。（至多获得两张）",
  ["#mobile__qiantun"] = "谦吞：令一名角色展示任意张手牌并与其拼点，若赢，你获得展示牌；若没赢，你获得其未展示的手牌",
  ["#mobile__qiantun-ask"] = "谦吞：请展示任意张手牌，你将只能用这些牌与 %src 拼点，根据拼点结果其获得你的展示牌或未展示牌！",
  ["#mobile__qiantun-pindian"] = "谦吞：你只能用这些牌与 %src 拼点！若其赢，其获得你的展示牌；若其没赢，其获得你未展示的手牌",

  ["$mobile__qiantun1"] = "辅国臣之本分，何敢图于禄勋。",
  ["$mobile__qiantun2"] = "蜀贼吴寇未灭，臣未可受此殊荣。",
  ["$mobile__qiantun3"] = "陛下一国之君，不可使以小性。",--谦吞（赢）	
  ["$mobile__qiantun4"] = "讲经宴筵，实非治国之道也。",--谦吞（没赢）
}

local zhaoxiong = fk.CreateTriggerSkill{
  name = "mobile__zhaoxiong",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("role_mode") then
      return "mobile__zhaoxiong_role_mode"
    else
      return "mobile__zhaoxiong_1v2"
    end
  end,
  events = {fk.EventPhaseStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#mobile__zhaoxiong-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "mobile__xiezheng_updata", 1)

    if player.general == "mobile__simazhao" then
      room:setPlayerProperty(player, "general", "mobile2__simazhao")
    elseif player.deputyGeneral == "mobile__simazhao" then
      room:setPlayerProperty(player, "deputyGeneral", "mobile2__simazhao")
    end
    if player.kingdom ~= "qun" then
      room:changeKingdom(player, "qun", true)
    end
    room:handleAddLoseSkills(player, "-mobile__qiantun|mobile__weisi|mobile__dangyi")
  end,
}
zhaoxiong.permanent_skill = true
simazhao:addSkill(zhaoxiong)
simazhao2:addSkill("mobile__zhaoxiong")

Fk:loadTranslationTable{
  ["mobile__zhaoxiong"] = "昭凶",
  [":mobile__zhaoxiong"] = "持恒技，限定技，准备阶段，若你已受伤，你可以将势力变更为群，然后你获得技能〖荡异〗"..
  "（若为身份模式，则删去〖挟征〗中的“优先指定同势力角色为目标”）。",
  [":mobile__zhaoxiong_role_mode"] = "持恒技，限定技，准备阶段，若你已受伤，你可以将势力变更为群，然后你获得技能〖荡异〗，"..
  "并删去〖挟征〗中的“优先指定同势力角色为目标”。",
  [":mobile__zhaoxiong_1v2"] = "持恒技，限定技，准备阶段，若你已受伤，你可以将势力变更为群，然后你获得技能〖荡异〗。",
  ["#mobile__zhaoxiong-invoke"] = "昭凶：是否变为群势力、失去“谦吞”、获得“威肆”和“荡异”？",
  ["$mobile__zhaoxiong1"] = "若得灭蜀之功，何不可受禅为帝。",
  ["$mobile__zhaoxiong2"] = "已极人臣之贵，当一尝人主之威。",
}

local dangyi = fk.CreateTriggerSkill{
  name = "mobile__dangyi$",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) < 2
    and player:usedSkillTimes(self.name) == 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#mobile__dangyi-invoke::"..data.to.id..":"
    ..(2-player:usedSkillTimes(self.name, Player.HistoryGame)))
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
dangyi.permanent_skill = true
simazhao2:addSkill(dangyi)

Fk:loadTranslationTable{
  ["mobile__dangyi"] = "荡异",
  [":mobile__dangyi"] = "持恒技，主公技，每回合限一次，当你造成伤害时，你可以令此伤害+1（每局游戏限两次）。",
  ["#mobile__dangyi-invoke"] = "荡异：是否令你对 %dest 造成的伤害+1？（还剩%arg次！）",
  ["$mobile__dangyi1"] = "哼！斩首示众，以儆效尤。",
  ["$mobile__dangyi2"] = "汝等仍存异心，可见心存魏阙。",
}

local weisi = fk.CreateActiveSkill{
  name = "mobile__weisi",
  anim_type = "offensive",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "mobile__weisi_1v2"
    else
      return "mobile__weisi_role_mode"
    end
  end,
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__weisi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askForCard(target, 1, 999, false, self.name, true, nil, "#mobile__weisi-ask:"..player.id)
    if #cards > 0 then
      target:addToPile("$mobile__weisi", cards, false, self.name, target.id)
    end
    if player.dead or target.dead then return end
    room:useVirtualCard("duel", nil, player, target, self.name)
  end,
}
local weisi_delay = fk.CreateTriggerSkill{
  name = "#mobile__weisi_delay",
  mute = true,
  events = {fk.Damage, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if event == fk.Damage then
      return target == player and not player.dead and player.room.logic:damageByCardEffect() and
        data.card and table.contains(data.card.skillNames, "mobile__weisi") and
        not data.to:isKongcheng()
    elseif event == fk.TurnEnd then
      return #player:getPile("$mobile__weisi") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      local cards = data.to:getCardIds("h")
      if room:isGameMode("1v2_mode") then
        cards = table.random(cards, 1)
      end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, "mobile__weisi", nil, false, player.id)
    elseif event == fk.TurnEnd then
      room:moveCardTo(player:getPile("$mobile__weisi"), Card.PlayerHand, player, fk.ReasonJustMove, "mobile__weisi", nil, false, player.id)
    end
  end,
}
weisi:addRelatedSkill(weisi_delay)
simazhao2:addSkill(weisi)

Fk:loadTranslationTable{
  ["mobile__weisi"] = "威肆",
  [":mobile__weisi"] = "群势力技，出牌阶段限一次，你可以选择一名其他角色，令其将任意张手牌移出游戏直到回合结束，然后视为对其使用一张【决斗】，"..
  "此牌对其造成伤害后，你获得其所有手牌（若为斗地主模式，所有改为一张）。",
  [":mobile__weisi_role_mode"] = "群势力技，出牌阶段限一次，你可以选择一名其他角色，令其将任意张手牌移出游戏直到回合结束，"..
  "然后视为对其使用一张【决斗】，此牌对其造成伤害后，你获得其所有手牌。",
  [":mobile__weisi_1v2"] = "群势力技，出牌阶段限一次，你可以选择一名其他角色，令其将任意张手牌移出游戏直到回合结束，然后视为对其使用一张【决斗】，"..
  "此牌对其造成伤害后，你获得其一张手牌。",
  ["#mobile__weisi"] = "威肆：令一名角色将任意张手牌移出游戏直到回合结束，然后视为对其使用【决斗】！",
  ["#mobile__weisi-ask"] = "威肆：%src 将对你使用【决斗】！请将任意张手牌本回合移出游戏，【决斗】对你造成伤害后其获得你手牌！",
  ["$mobile__weisi"] = "威肆",
  ["#mobile__weisi_delay"] = "威肆",
  ["$mobile__weisi1"] = "上者慑敌以威，灭敌以势。",
  ["$mobile__weisi2"] = "哼，求存者多，未见求死者也。",
  ["$mobile__weisi3"] = "未想逆贼区区，竟然好物甚巨。", --威肆（获得手牌）
}


return extension
