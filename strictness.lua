local extension = Package("strictness")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["strictness"] = "严包",
}

local zhangchangpu = General(extension, "mobile__zhangchangpu", "wei", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["mobile__zhangchangpu"] = "张昌蒲",
  ["~mobile__zhangchangpu"] = "钟氏门楣，待我儿光耀……",
}

local difei = fk.CreateTriggerSkill{
  name = "difei",
  anim_type = "masochism",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player == target and player:usedSkillTimes(self.name) < 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#difei-discard"
    if data.card then
      if data.card.suit == Card.NoSuit then
        prompt = prompt .. "-recover1"
      else
        prompt = prompt .. "-recover2:::" .. data.card:getSuitString(true)
      end
    end
    local card = room:askForDiscard(player, 1, 1, false, self.name, true, ".", prompt)
    if #card == 0 then
      room:drawCards(player, 1, self.name)
    end
    if player:isKongcheng() then return false end
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)

    if player:isWounded() and data.card then
      local suit = data.card.suit
      if suit ~= Card.NoSuit then
        for _, id in ipairs(cards) do
          if Fk:getCardById(id).suit == suit then
            return false
          end
        end
      end
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}

Fk:loadTranslationTable{
  ["difei"] = "抵诽",
  [":difei"] = "锁定技，每回合限一次，当你受到伤害后，你摸一张牌或弃置一张手牌，然后你展示所有手牌，若对你造成伤害的牌无花色或你的手牌中没有与对你造成伤害的牌花色相同的牌，你回复1点体力。",

  ["#difei-discard"] = "抵诽：你可选择一张手牌弃置，或点取消则摸一张牌",
  ["#difei-discard-recover1"] = "抵诽：你可选择一张手牌弃置，或点取消则摸一张牌，然后展示所有手牌并回复1点体力",
  ["#difei-discard-recover2"] = "抵诽：你可选择一张手牌弃置，或点取消则摸一张牌，然后展示所有手牌，若其中没有%arg牌则回复1点体力",

  ["$difei1"] = "称病不见，待其自露马脚。",
  ["$difei2"] = "孙氏之诽，伤不到我分毫。",
}

zhangchangpu:addSkill(difei)

local mobile__yanjiao = fk.CreateActiveSkill{
  name = "mobile__yanjiao",
  anim_type = "offensive",
  prompt = "#mobile__yanjiao-active",
  interaction = function(self)
    local choiceList = {}
    local cards = Self.player_cards[Player.Hand]
    for _, id in ipairs(cards) do
      table.insertIfNeed(choiceList, Fk:getCardById(id):getSuitString(true))
    end
    return UI.ComboBox { choices = choiceList }
  end,
  max_card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local suit = self.interaction.data
    local handcards = player.player_cards[Player.Hand]
    local cards = table.filter(handcards, function (id)
      return Fk:getCardById(id):getSuitString(true) == suit
    end)
    if #cards == 0 then return false end
    room:addPlayerMark(player, "@mobile__yanjiao", #cards)
    local dummy = Fk:cloneCard'slash'
    dummy:addSubcards(cards)
    room:obtainCard(target.id, dummy, false, fk.ReasonGive)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}

local mobile__yanjiao_delay = fk.CreateTriggerSkill{
  name = "#mobile__yanjiao_delay",
  anim_type = "control",
  events = {fk.EventPhaseChanging},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to == Player.Start and not player.dead and player:getMark("@mobile__yanjiao") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark("@mobile__yanjiao")
    room:setPlayerMark(player, "@mobile__yanjiao", 0)
    room:drawCards(player, x, mobile__yanjiao.name)
  end,
}

mobile__yanjiao:addRelatedSkill(mobile__yanjiao_delay)

Fk:loadTranslationTable{
  ["mobile__yanjiao"] = "严教",
  [":mobile__yanjiao"] = "出牌阶段限一次，你可以将手牌中某种花色的所有牌（至少一张）交给一名其他角色，然后对其造成1点伤害，若如此做，你的下个回合开始时，你摸X张牌（X为你以此法给出的牌数）。",

  ["#mobile__yanjiao-active"] = "严教：选择一种花色和一名其他角色，将手牌中所有该花色的牌交给该角色并对其造成1点伤害",
  ["@mobile__yanjiao"] = "严教",

  ["$mobile__yanjiao1"] = "此篇未记，会儿便不可嬉戏。",
  ["$mobile__yanjiao2"] = "母亲虽严，却皆为汝好。",
}

zhangchangpu:addSkill(mobile__yanjiao)

Fk:loadTranslationTable{
  ["mobile__huangfusong"] = "皇甫嵩",
  ["~mobile__huangfusong"] = "力有所能，臣必为也……",
}

Fk:loadTranslationTable{
  ["hfs__taoluan"] = "讨乱",
  [":hfs__taoluan"] = "每回合限一次，当判定牌生效时，若判定结果为黑桃，你可以终止此次判定，然后选择：1.你获得此判定牌；2.若进行判定的角色不是你，你视为对其使用一张无距离和次数限制的火【杀】。",
  ["$hfs__taoluan1"] = "乱民桀逆，非威不服！",
  ["$hfs__taoluan2"] = "欲定黄巾，必赖兵革之利！",
}

Fk:loadTranslationTable{
  ["shiji"] = "势击",
  [":shiji"] = "你对其他角色造成属性伤害时，若你的手牌数不为全场唯一最多，你可以查看其手牌并弃置其中所有的红色牌，然后你摸等量的牌。",
  ["$shiji1"] = "敌军依草结营，正犯兵家大忌！",
  ["$shiji2"] = "兵法所云火攻之计，正合此时之势！",
}

Fk:loadTranslationTable{
  ["zhengjun"] = "整军",
  [":zhengjun"] = "出牌阶段开始时，你可以进行一次“整肃”，若如此做，弃牌阶段结束后，若你“整肃”未失败，你获得“整肃”奖励，并可以令一名其他角色也获得“整肃”奖励。",
  ["$zhengjun1"] = "众将平日随心，战则务尽死力！",
  ["$zhengjun2"] = "汝等不怀余力，皆有平贼之功！",
  ["$zhengjun3"] = "仁恕之道，终非治军良策！",
}

local zhujun = General(extension, "mobile__zhujun", "qun", 4)
Fk:loadTranslationTable{
  ["mobile__zhujun"] = "朱儁",
  ["~mobile__zhujun"] = "郭汜小竖！气煞我也！嗯……",
}

local yangjie = fk.CreateActiveSkill{
  name = "yangjie",
  anim_type = "offensive",
  prompt = "#yangjie-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and not target:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner ~= player and not player.dead and not target.dead then
      local slash = Fk:cloneCard("fire__slash")
      slash.skillName = self.name
      local targets = table.filter(room.alive_players, function (p)
        return not (p == player or p == target or p:prohibitUse(slash) or p:isProhibited(target, slash))
      end)
      if #targets == 0 then return false end
      local tos = room:askForChoosePlayers(player, table.map(targets, function (p)
        return p.id end), 1, 1, "#yangjie-choose::" .. effect.tos[1], self.name, true, true)
       if #tos > 0 then
        room:useCard({
          from = tos[1],
          tos = {effect.tos},
          card = slash,
        })
       end
    end
  end,
}

Fk:loadTranslationTable{
  ["yangjie"] = "佯解",
  [":yangjie"] = "出牌阶段限一次，你可以与一名角色拼点。若你没赢，你可以令另一名其他角色视为对与你拼点的角色使用一张无距离限制的火【杀】。",

  ["#yangjie-active"] = "发动佯解，选择与你拼点的角色",
  ["#yangjie-choose"] = "佯解：可选择一名其他角色，视为其对%dest使用一张火【杀】",
  ["$yangjie1"] = "全军彻围，待其出城迎敌，再攻敌自散矣！",
  ["$yangjie2"] = "佯解敌围，而后城外击之，此为易破之道！",
}

zhujun:addSkill(yangjie)

local zj__juxiang = fk.CreateTriggerSkill{
  name = "zj__juxiang",
  anim_type = "offensive",
  frequency = Skill.Limited,
  events = {fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and not target.dead and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zj__juxiang-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    player.room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
  end,
}

Fk:loadTranslationTable{
  ["zj__juxiang"] = "拒降",
  [":zj__juxiang"] = "限定技，当一名其他角色的濒死结算结束后，你可对其造成1点伤害。",
  ["#zj__juxiang-invoke"] = "你可发动拒降，对%dest造成1点伤害",
  ["$zj__juxiang1"] = "今非秦项之际，如若受之，徒增逆意！",
  ["$zj__juxiang2"] = "兵有形同而势异者，此次乞降断不可受！",
}

zhujun:addSkill(zj__juxiang)

local houfeng = fk.CreateTriggerSkill{
  name = "houfeng",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and
    target.phase == Player.Play and not target.dead and player:inMyAttackRange(target)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#houfeng-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    room:broadcastSkillInvoke(self.name, 1)
    room:doIndicate(player.id, {target.id})
    local choices = {"zhengsu_leijin", "zhengsu_bianzhen", "zhengsu_mingzhi"}
    local choice = room:askForChoice(player, choices, self.name, "#houfeng-choice::"..target.id, true)
    room:setPlayerMark(target, "@" .. choice .. "-turn", self.name)
    room:setPlayerMark(target, choice .. "-turn", player.id)
    room:setPlayerMark(player, "@houfeng-turn", target.general)
  end,

  refresh_events = {fk.CardUsing, fk.AfterCardsMove, fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUsing and player == target and target.phase == Player.Play then
      return player:getMark("zhengsu_leijin-turn") ~= 0 or player:getMark("zhengsu_bianzhen-turn") ~= 0
    elseif event == fk.AfterCardsMove and player.phase == Player.Discard then
      return player:getMark("zhengsu_mingzhi-turn") ~= 0
    elseif event == fk.EventPhaseEnd and player == target and target.phase == Player.Discard then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      if player:getMark("zhengsu_leijin-turn") ~= 0 then
        local x = data.card.number
        if x > 0 then
          room:addPlayerMark(player, "zhengsu_leijin_times-turn")
          if player:getMark("zhengsu_point-turn") < x then
            room:setPlayerMark(player, "zhengsu_point-turn", x)
          else
            room:broadcastSkillInvoke(self.name, 3)
            room:setPlayerMark(player, "zhengsu_leijin-turn", 0)
            room:setPlayerMark(player, "@zhengsu_leijin-turn", "zhengsu_failure")
          end
        end
      end
      if player:getMark("zhengsu_bianzhen-turn") ~= 0 then
        local suit = data.card:getSuitString()
        if suit ~= "nosuit" then
          room:addPlayerMark(player, "zhengsu_bianzhen_times-turn")
          if (player:getMark("zhengsu_suit-turn") == 0 or player:getMark("zhengsu_suit-turn") == suit) then
            room:setPlayerMark(player, "zhengsu_suit-turn", suit)
          else
            room:broadcastSkillInvoke(self.name, 3)
            room:setPlayerMark(player, "zhengsu_bianzhen-turn", 0)
            room:setPlayerMark(player, "@zhengsu_bianzhen-turn", "zhengsu_failure")
          end
        end
      end
    elseif event == fk.AfterCardsMove then
      local discarded = type(player:getMark("zhengsu_mingzhi_discard-turn")) == "table" and player:getMark("zhengsu_mingzhi_discard-turn") or {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.skillName == "game_rule" then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insert(discarded, info.cardId)
            end
          end
        end
      end
      room:setPlayerMark(player, "zhengsu_mingzhi_discard-turn", discarded)
    elseif event == fk.EventPhaseEnd then
      local zhengsu_failure = false
      if player:getMark("zhengsu_leijin-turn") ~= 0 and player:getMark("zhengsu_leijin_times-turn") < 3 then
        zhengsu_failure = true
        room:setPlayerMark(player, "zhengsu_leijin-turn", 0)
        room:setPlayerMark(player, "@zhengsu_leijin-turn", "zhengsu_failure")
      end
      if player:getMark("zhengsu_bianzhen-turn") ~= 0 and player:getMark("zhengsu_bianzhen_times-turn") < 2 then
        zhengsu_failure = true
        room:setPlayerMark(player, "zhengsu_bianzhen-turn", 0)
        room:setPlayerMark(player, "@zhengsu_bianzhen-turn", "zhengsu_failure")
      end
      if player:getMark("zhengsu_mingzhi-turn") ~= 0 then
        local discarded = player:getMark("zhengsu_mingzhi_discard-turn")
        if type(discarded) == "table" and #discarded > 1 then
          local suits = {}
          for _, id in ipairs(discarded) do
            if Fk:getCardById(id).suit ~= Card.NoSuit then
              table.insertIfNeed(suits, Fk:getCardById(id).suit)
            end
          end
          if #suits < #discarded then
            zhengsu_failure = true
            room:setPlayerMark(player, "zhengsu_mingzhi-turn", 0)
            room:setPlayerMark(player, "@zhengsu_mingzhi-turn", "zhengsu_failure")
          end
        else
          zhengsu_failure = true
          room:setPlayerMark(player, "zhengsu_mingzhi-turn", 0)
          room:setPlayerMark(player, "@zhengsu_mingzhi-turn", "zhengsu_failure")
        end
      end
      if zhengsu_failure then
        room:broadcastSkillInvoke(self.name, 3)
      end
    end
  end,
}

local houfeng_delay = fk.CreateTriggerSkill{
  name = "#houfeng_delay",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Discard and not target.dead and not player.dead and
    not table.every({"zhengsu_leijin-turn", "zhengsu_bianzhen-turn", "zhengsu_mingzhi-turn"}, function (name)
      return target:getMark(name) ~= player.id
    end)
  end,
  on_cost = function(self, event, target, player, data) return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, houfeng.name)
    room:broadcastSkillInvoke(houfeng.name, 2)
    local choices = {"draw2"}
    if player:isWounded() or target:isWounded() then
      table.insert(choices, 1, "recover")
    end
    local choice = room:askForChoice(target, choices, houfeng.name, "#houfeng-reward:"..player.id)
    if choice == "draw2" then
      room:drawCards(target, 2, houfeng.name)
      if not player.dead then
        room:drawCards(player, 2, houfeng.name)
      end
    elseif choice == "recover" then
      if target:isWounded() then
        room:recover({
          who = target,
          num = 1,
          recoverBy = target.id,
          skillName = houfeng.name
        })
      end
      if not player.dead and player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = target.id,
          skillName = houfeng.name
        })
      end
    end
  end,
}

houfeng:addRelatedSkill(houfeng_delay)

Fk:loadTranslationTable{
  ["houfeng"] = "厚俸",
  ["#houfeng_delay"] = "厚俸",
  [":houfeng"] = "每轮限一次，你攻击范围内一名角色出牌阶段开始时，你可以令其开始一次“整肃”，若如此做，其弃牌阶段结束后，若其“整肃”未失败，你与其获得“整肃”奖励。"..
  "<br/><font color='grey'>#\"<b>整肃</b>\"<br/>"..
  "技能发动者从擂进、变阵、鸣止中选择一项令目标执行，若其于其回合内弃牌阶段结束后未整肃失败，则选择“整肃奖励”。<br/>"..
  "<b>擂进：</b>出牌阶段内，使用的所有牌点数需递增且至少使用三张牌。<br/>"..
  "<b>变阵：</b>出牌阶段内，使用的所有牌花色需相同且至少使用两张牌。<br/>"..
  "<b>鸣止：</b>弃牌阶段内，弃置的所有牌花色均不同且至少弃置两张牌。<br/>"..
  "<b>整肃奖励：</b>选择一项：1.摸两张牌；2.回复1点体力。",
  ["#houfeng-invoke"] = "你可发动厚俸，令%dest开始一次整肃，若未失败则获得整肃奖励",
  ["@houfeng-turn"] = "厚俸",
  ["#houfeng-choice"] = "厚俸：为%dest选择一项整肃条件",
  ["#houfeng-reward"] = "厚俸：你整肃未失败，选择整肃奖励令你与%src共同执行",

  ["$houfeng1"] = "交汝统领，勿负我望！",
  ["$houfeng2"] = "有功自当行赏，来人呈上！",
  ["$houfeng3"] = "叉出去！罚其二十军杖！",
}
Fk:loadTranslationTable{
  ["zhengsu_leijin"] = "擂进",
  ["@zhengsu_leijin-turn"] = "擂进",
  [":zhengsu_leijin"] = "出牌阶段内<br>至少使用3张牌<br>使用所有牌点数递增",
  ["zhengsu_bianzhen"] = "变阵",
  ["@zhengsu_bianzhen-turn"] = "变阵",
  [":zhengsu_bianzhen"] = "出牌阶段内<br>至少使用2张牌<br>使用所有牌花色相同",
  ["zhengsu_mingzhi"] = "鸣止",
  ["@zhengsu_mingzhi-turn"] = "鸣止",
  [":zhengsu_mingzhi"] = "弃牌阶段内<br>至少弃置2张牌<br>弃置所有牌花色均不同",

  ["zhengsu_failure"] = "失败",
}

zhujun:addSkill(houfeng)


return extension
