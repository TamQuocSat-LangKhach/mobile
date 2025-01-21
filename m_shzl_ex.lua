local extension = Package("m_shzl_ex")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["m_shzl_ex"] = "手杀-界神话再临",
}

local U = require "packages/utility/utility"

--[[local xiaoqiao = General(extension, "m_ex__xiaoqiao", "wu", 3, 3, General.Female)
xiaoqiao:addSkill("ol_ex__tianxiang")
xiaoqiao:addSkill("mou__hongyan")]]--
Fk:loadTranslationTable{
  ["m_ex__xiaoqiao"] = "界小乔",
  ["#m_ex__xiaoqiao"] = "矫情之花",
  ["illustrator:m_ex__xiaoqiao"] = "凝聚永恒",
}

local zhangjiao = General(extension, "m_ex__zhangjiao", "qun", 3)
local leiji = fk.CreateTriggerSkill{
  name = "ex__leiji",
  anim_type = "offensive",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and data.card.name == "jink" and #player.room.alive_players > 1
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper), 1, 1,
      "#ex__leiji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local judge = {
      who = to,
      reason = self.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade and not to.dead then
      room:damage{
        from = player,
        to = to,
        damage = 2,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    elseif judge.card.suit == Card.Club then
      if player:isWounded() and not player.dead then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
      end
    end
  end,
}
zhangjiao:addSkill(leiji)
zhangjiao:addSkill("guidao")
zhangjiao:addSkill("huangtian")
Fk:loadTranslationTable{
  ["m_ex__zhangjiao"] = "界张角",
  ["#m_ex__zhangjiao"] = "大贤良师",
  ["illustrator:m_ex__zhangjiao"] = "LiuHeng",

  ["ex__leiji"] = "雷击",
  [":ex__leiji"] = "当你使用或打出【闪】后，你可以令一名其他角色进行一次判定，若结果为：♠，你对其造成2点雷电伤害；♣，你回复1点体力，"..
  "对其造成1点雷电伤害。",
  ["#ex__leiji-choose"] = "雷击：令一名角色进行判定，若为♠，你对其造成2点雷电伤害；若为♣，你回复1点体力，对其造成1点雷电伤害",

  ["$ex__leiji1"] = "成为黄天之世的祭品吧。",
  ["$ex__leiji2"] = "呼风唤雨，驱雷策电！",
  ["$guidao_m_ex__zhangjiao1"] = "道势所向，皆由我控。",
  ["$guidao_m_ex__zhangjiao2"] = "哼哼，天意如此！",
  ["$huangtian_m_ex__zhangjiao1"] = "苍天不复，黄天将替！",
  ["$huangtian_m_ex__zhangjiao2"] = "黄天立，民心顺，天下平！",
  ["~m_ex__zhangjiao"] = "黄天既覆，苍生何存……",
}

local yuji = General(extension, "m_ex__yuji", "qun", 3)
local guhuo = fk.CreateViewAsSkill{
  name = "m_ex__guhuo",
  pattern = ".",
  prompt = "#m_ex__guhuo-prompt",
  interaction = function(self)
    local all_names = U.getAllCardNames("bt")
    return U.CardNameBox { choices = U.getViewAsCardNames(Self, self.name, all_names) }
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    self.cost_data = cards
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local cards = self.cost_data
    local card_id = cards[1]
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonPut, self.name, "", false, player.id)
    local targets = TargetGroup:getRealTargets(use.tos)
    if targets and #targets > 0 then
      room:sendLog{
        type = "#guhuo_use",
        from = player.id,
        to = targets,
        arg = use.card.name,
        arg2 = self.name
      }
      room:doIndicate(player.id, targets)
    else
      room:sendLog{
        type = "#guhuo_no_target",
        from = player.id,
        arg = use.card.name,
        arg2 = self.name
      }
    end

    local canuse = true
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:hasSkill("chanyuan") and p:isAlive() then
        local choice = room:askForChoice(p, {"noquestion", "question"}, self.name, "#guhuo-ask::"..player.id..":"..use.card.name)
        room:sendLog{
          type = "#guhuo_query",
          from = p.id,
          arg = choice
        }
        if choice ~= "noquestion" then
          player:showCards({card_id})
          if use.card.name == Fk:getCardById(card_id).name then
            room:setCardEmotion(card_id, "judgegood")
            room:handleAddLoseSkills(p, "chanyuan")
          else
          room:setCardEmotion(card_id, "judgebad")
            canuse = false
          end
          break
        end
      end
    end

    if canuse then
      use.card:addSubcard(card_id)
    else
      room:moveCardTo(card_id, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name)
      return ""
    end
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
}
local chanyuan = fk.CreateInvaliditySkill {
  name = "chanyuan",
  invalidity_func = function(self, from, skill)
    --- FIXME:无法在此处判断“缠怨”的isEffectable，会导致自我嵌套死循环
    return from:hasSkill(self, true) and from.hp == 1 and skill:isPlayerSkill(from)
  end
}
local chanyuan_audio = fk.CreateTriggerSkill{
  name = "#chanyuan_audio",
  refresh_events = {fk.HpChanged, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.HpChanged then
      return target == player and player:hasShownSkill(chanyuan) and player.hp == 1 and data.num < 0
    else
      return target == player and data == chanyuan
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.HpChanged then
      room:notifySkillInvoked(player, "chanyuan", "negative")
      player:broadcastSkillInvoke("chanyuan")
    else
      room:setPlayerMark(player, "@@chanyuan", event == fk.EventAcquireSkill and 1 or 0)
    end
  end,
}
chanyuan:addRelatedSkill(chanyuan_audio)
yuji:addSkill(guhuo)
yuji:addRelatedSkill(chanyuan)
Fk:loadTranslationTable{
  ["m_ex__yuji"] = "界于吉",
  ["#m_ex__yuji"] = "太平道人",
  ["illustrator:m_ex__yuji"] = "魔鬼鱼",

  ["m_ex__guhuo"] = "蛊惑",
  [":m_ex__guhuo"] = "每回合限一次，你可以扣置一张手牌当任意一张基本牌或普通锦囊牌使用或打出。使用此牌前，令所有其他角色依次选择是否质疑，"..
  "若有角色质疑则翻开此牌：若为假，则此牌作废；若为真，则该色获得〖缠怨〗。",
  ["chanyuan"] = "缠怨",
  [":chanyuan"] = "锁定技，你不能质疑〖蛊惑〗；若你的体力值为1，你的其他技能失效。",
  ["@@chanyuan"] = "缠怨",
  ["#m_ex__guhuo-prompt"] = "蛊惑：扣置一张手牌并声明一种基本牌或普通锦囊牌，若无人质疑，则按牌名使用或打出",

  ["$m_ex__guhuo1"] = "道法玄机，变幻莫测。",
  ["$m_ex__guhuo2"] = "如真似幻，扑朔迷离。",
  ["$chanyuan1"] = "不识天数，在劫难逃。",
  ["$chanyuan2"] = "凡人仇怨，皆由心生。",
  ["~m_ex__yuji"] = "道法玄机，竟被参破……",
}

local dianwei = General(extension, "m_ex__dianwei", "wei", 4)
local qiangxi = fk.CreateActiveSkill{
  name = "m_ex__qiangxi",
  anim_type = "offensive",
  max_card_num = 1,
  target_num = 1,
  prompt = "#m_ex__qiangxi",
  can_use = Util.TrueFunc,
  card_filter = function(self, to_select, selected)
    return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id and not table.contains(Self:getTableMark("m_ex__qiangxi-phase"), to_select) then
      if #selected_cards == 0 or table.contains(Self:getCardIds("e"), selected_cards[1]) then
        return Self:inMyAttackRange(Fk:currentRoom():getPlayerById(to_select))
      else
        return Self:distanceTo(Fk:currentRoom():getPlayerById(to_select)) == 1
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addTableMark(player, "m_ex__qiangxi-phase", target.id)
    if #effect.cards > 0 then
      room:throwCard(effect.cards, self.name, player)
    else
      room:loseHp(player, 1, self.name)
    end
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
  end,
}
dianwei:addSkill(qiangxi)
Fk:loadTranslationTable{
  ["m_ex__dianwei"] = "界典韦",
  ["#m_ex__dianwei"] = "古之恶来",
  ["illustrator:m_ex__dianwei"] = "凝聚永恒",

  ["m_ex__qiangxi"] = "强袭",
  [":m_ex__qiangxi"] = "出牌阶段对每名角色限一次，你可以失去1点体力或弃置一张武器牌，对攻击范围内一名其他角色造成1点伤害。",
  ["#m_ex__qiangxi"] = "强袭：弃置一张武器牌，或点“确定”失去1点体力，对攻击范围内一名本阶段未选择过的角色造成1点伤害",

  ["$m_ex__qiangxi1"] = "铁戟双提八十斤，威风凛凛震乾坤！",
  ["$m_ex__qiangxi2"] = "勇字当头，义字当先！",
  ["~m_ex__dianwei"] = "汝等小儿，竟敢害我！拿命来！",
}

local xunyu = General(extension, "m_ex__xunyu", "wei", 3)
local m_ex__jieming = fk.CreateTriggerSkill{
  name = "m_ex__jieming",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1,
      "#m_ex__jieming-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local to = player.room:getPlayerById(self.cost_data.tos[1])
    to:drawCards(2, self.name)
    if to:getHandcardNum() < to.maxHp and not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
xunyu:addSkill("quhu")
xunyu:addSkill(m_ex__jieming)
Fk:loadTranslationTable{
  ["m_ex__xunyu"] = "界荀彧",
  ["#m_ex__xunyu"] = "王佐之才",
  ["illustrator:m_ex__xunyu"] = "青岛磐蒲",

  ["m_ex__jieming"] = "节命",
  [":m_ex__jieming"] = "当你受到1点伤害后，你可以令一名角色摸两张牌，然后若其手牌数小于其体力上限，你摸一张牌。",
  ["#m_ex__jieming-choose"] = "节命：令一名角色摸两张牌，然后若其手牌数小于其体力上限，你摸一张牌",

  ["$m_ex__jieming1"] = "因势利导，是为良计。",
  ["$m_ex__jieming2"] = "杀身成仁，不负皇恩。",
  ["$quhu_m_ex__xunyu1"] = "驱虎伤敌，保我无虞。",
  ["$quhu_m_ex__xunyu2"] = "无需费我一兵一卒。",
  ["~m_ex__xunyu"] = "命不由人，徒叹奈何……",
}

local wolong = General(extension, "m_ex__wolong", "shu", 3)
local huoji = fk.CreateViewAsSkill{
  name = "m_ex__huoji",
  anim_type = "offensive",
  pattern = "fire_attack",
  prompt = "#m_ex__huoji",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
}
local kanpo = fk.CreateViewAsSkill{
  name = "m_ex__kanpo",
  anim_type = "control",
  pattern = "nullification",
  prompt = "#m_ex__kanpo",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
}
wolong:addSkill("bazhen")
wolong:addSkill(huoji)
wolong:addSkill(kanpo)
Fk:loadTranslationTable{
  ["m_ex__wolong"] = "界卧龙诸葛亮",
  ["#m_ex__wolong"] = "卧龙",
  ["illustrator:m_ex__wolong"] = "YanBai",

  ["m_ex__huoji"] = "火计",
  [":m_ex__huoji"] = "你可以将一张红色牌当【火攻】使用。",
  ["m_ex__kanpo"] = "看破",
  [":m_ex__kanpo"] = "你可以将一张黑色牌当【无懈可击】使用。",
  ["#m_ex__huoji"] = "火计：你可以将一张红色牌当【火攻】使用",
  ["#m_ex__kanpo"] = "看破：你可以将一张黑色牌当【无懈可击】使用",

  ["$m_ex__huoji1"] = "此火可助我军大获全胜。",
  ["$m_ex__huoji2"] = "燃烧吧！",
  ["$m_ex__kanpo1"] = "雕虫小技。",
  ["$m_ex__kanpo2"] = "你的计谋被识破了。",
  ["~m_ex__wolong"] = "我的计谋竟被……",
}

local pangtong = General:new(extension, "m_ex__pangtong", "shu", 3)
local lianhuan = fk.CreateActiveSkill{
  name = "m_ex__lianhuan",
  mute = true,
  card_num = 1,
  min_target_num = 0,
  prompt = "#m_ex__lianhuan",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, selected_targets)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Club and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards, _, _, player)
    if #selected_cards == 1 then
      local card = Fk:cloneCard("iron_chain")
      card:addSubcard(selected_cards[1])
      return card.skill:canUse(player, card) and card.skill:targetFilter(to_select, selected, selected_cards, card, nil, player) and
        not player:prohibitUse(card) and not player:isProhibited(Fk:currentRoom():getPlayerById(to_select), card)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke(self.name)
    if #effect.tos == 0 then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:recastCard(effect.cards, player, self.name)
    else
      room:notifySkillInvoked(player, self.name, "control")
      room:sortPlayersByAction(effect.tos)
      room:useVirtualCard("iron_chain", effect.cards, player, table.map(effect.tos, Util.Id2PlayerMapper), self.name)
    end
  end,
}
local lianhuan_trigger = fk.CreateTriggerSkill{
  name = "#m_ex__lianhuan_trigger",
  mute = true,
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.name == "iron_chain" then
      local current_targets = TargetGroup:getRealTargets(data.tos)
      for _, p in ipairs(player.room.alive_players) do
        if not table.contains(current_targets, p.id) and not player:isProhibited(p, data.card) and
            data.card.skill:modTargetFilter(p.id, current_targets, player, data.card, true) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local current_targets = TargetGroup:getRealTargets(data.tos)
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if not table.contains(current_targets, p.id) and not player:isProhibited(p, data.card) and
          data.card.skill:modTargetFilter(p.id, current_targets, player, data.card, true) then
        table.insert(targets, p.id)
      end
    end
    local tos = room:askForChoosePlayers(player, targets, 1, 1,
    "#m_ex__lianhuan-choose:::"..data.card:toLogString(), self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("m_ex__lianhuan")
    player.room:notifySkillInvoked(player, "m_ex__lianhuan", "control")
    TargetGroup:pushTargets(data.tos, self.cost_data)
    player.room:sendLog{
      type = "#AddTargetsBySkill",
      from = player.id,
      to = {self.cost_data},
      arg = "m_ex__lianhuan",
      arg2 = data.card:toLogString()
    }
  end,
}
local niepan = fk.CreateActiveSkill{
  name = "m_ex__niepan",
  anim_type = "defensive",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  prompt = "#m_ex__niepan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:throwAllCards("hej")
    if player.dead then return end
    player:drawCards(3, self.name)
    if not player.dead and math.min(3, player.maxHp) > player.hp then
      room:recover({
        who = player,
        num = math.min(3, player.maxHp) - player.hp,
        recoverBy = player,
        skillName = self.name,
      })
    end
    if not player.dead then
      player:reset()
    end
  end,
}
local niepan_trigger = fk.CreateTriggerSkill{
  name = "#m_ex__niepan_trigger",
  mute = true,
  main_skill = niepan,
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(niepan) and player.dying and
      player:usedSkillTimes("m_ex__niepan", Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("m_ex__niepan")
    room:notifySkillInvoked(player, "m_ex__niepan", "support")
    niepan:onUse(room, {
      from = player.id,
    })
  end,
}
lianhuan:addRelatedSkill(lianhuan_trigger)
niepan:addRelatedSkill(niepan_trigger)
pangtong:addSkill(lianhuan)
pangtong:addSkill(niepan)
Fk:loadTranslationTable{
  ["m_ex__pangtong"] = "界庞统",
  ["#m_ex__pangtong"] = "凤雏",
  ["illustrator:m_ex__pangtong"] = "青岛磐蒲",

  ["m_ex__lianhuan"] = "连环",
  [":m_ex__lianhuan"] = "你可以将一张♣手牌当【铁索连环】使用或重铸，你使用【铁索连环】时可以额外指定一个目标。",
  ["#m_ex__lianhuan"] = "连环：你可以将一张♣手牌当【铁索连环】使用或重铸",
  ["#m_ex__lianhuan_trigger"] = "连环",
  ["#m_ex__lianhuan-choose"] = "连环：你可以为 %arg 额外指定一个目标",
  ["m_ex__niepan"] = "涅槃",
  [":m_ex__niepan"] = "限定技，出牌阶段，或当你处于濒死状态时，你可以弃置你区域里所有的牌，摸三张牌，将体力值回复至3点，复原武将牌。",
  ["#m_ex__niepan_trigger"] = "涅槃",
  ["#m_ex__niepan"] = "涅槃：是否弃置区域里所有的牌，摸三张牌，将体力值回复至3点，复原武将牌？",

  ["$m_ex__lianhuan1"] = "将多兵众，不可以敌，使其自累，以杀其势。",
  ["$m_ex__lianhuan2"] = "善用兵者，运巧必防损，立谋虑中变。",
  ["$m_ex__niepan1"] = "凤凰折翅，涅槃再生。",
  ["$m_ex__niepan2"] = "九天之志，展翅翱翔。",
  ["~m_ex__pangtong"] = "落……凤……坡……",
}

local yanliangwenchou = General(extension, "m_ex__yanliangwenchou", "qun", 4)
local shuangxiong = fk.CreateViewAsSkill{
  name = "m_ex__shuangxiong",
  anim_type = "offensive",
  pattern = "duel",
  prompt = function()
    local mark = Self:getMark("@shuangxiong-turn")
    local color = ""
    if #mark == 1 then
      if mark[1] == "red" then
        color = "black"
      else
        color = "red"
      end
    end
    return "#shuangxiong:::"..color
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    local color = Fk:getCardById(to_select):getColorString()
    if color == "red" then
      color = "black"
    elseif color == "black" then
      color = "red"
    else
      return false
    end
    return table.contains(Self:getHandlyIds(true), to_select) and table.contains(Self:getMark("@shuangxiong-turn"), color)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("duel")
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return type(player:getMark("@shuangxiong-turn")) == "table"
  end,
  enabled_at_response = function(self, player, resp)
    return type(player:getMark("@shuangxiong-turn")) == "table" and not resp
  end,
}
local shuangxiong_trigger = fk.CreateTriggerSkill{
  name = "#m_ex__shuangxiong_trigger",
  events = {fk.EventPhaseStart, fk.Damaged},
  mute = true,
  main_skill = shuangxiong,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shuangxiong) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Draw
      elseif event == fk.Damaged then
        if data.card and table.contains(data.card.skillNames, "m_ex__shuangxiong") then
          local room = player.room
          local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
          if use_event == nil then return end
          local cards = {}
          room.logic:getEventsByRule(GameEvent.RespondCard, 1, function (e)
            local response = e.data[1]
            if response.responseToEvent and response.responseToEvent.card and
              table.contains(response.responseToEvent.card.skillNames, "m_ex__shuangxiong") and
              response.responseToEvent.from == player.id and
              response.from ~= player.id then
              local ids = response.card:isVirtual() and response.card.subcards or { response.card.id }
              for _, id in ipairs(ids) do
                if room:getCardArea(id) == Card.DiscardPile then
                  table.insertIfNeed(cards, id)
                end
              end
            end
          end, use_event.id)
          if #cards > 0 then
            self.cost_data = cards
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#m_ex__shuangxiong-invoke"
    if event == fk.Damaged then
      prompt = "#m_ex__shuangxiong-prey"
    end
    return player.room:askForSkillInvoke(player, "m_ex__shuangxiong", nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "m_ex__shuangxiong", "offensive")
    player:broadcastSkillInvoke("m_ex__shuangxiong")
    if event == fk.EventPhaseStart then
      local cards = room:getNCards(2)
      room:moveCardTo(cards, Card.Processing, nil, fk.ReasonJustMove, "m_ex__shuangxiong", nil, true, player.id)
      room:delay(1000)
      local card = U.askforChooseCardsAndChoice(player, cards, {"OK"}, "m_ex__shuangxiong", "#m_ex__shuangxiong-get")
      local color = Fk:getCardById(card[1]):getColorString()
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, "m_ex__shuangxiong", nil, true, player.id)
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.Processing
      end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.DrawPile, nil, fk.ReasonJustMove, "m_ex__shuangxiong", nil, true)
      end
      if color == "nocolor" then return end
      room:addTableMarkIfNeed(player, "@shuangxiong-turn", color)
      return true
    elseif event == fk.Damaged then
      room:moveCardTo(self.cost_data, Card.PlayerHand, player, fk.ReasonJustMove, "m_ex__shuangxiong", nil, true, player.id)
    end
  end,
}
shuangxiong:addRelatedSkill(shuangxiong_trigger)
yanliangwenchou:addSkill(shuangxiong)
Fk:loadTranslationTable{
  ["m_ex__yanliangwenchou"] = "界颜良文丑",
  ["#m_ex__yanliangwenchou"] = "虎狼兄弟",
  ["illustrator:m_ex__yanliangwenchou"] = "",

  ["m_ex__shuangxiong"] = "双雄",
  [":m_ex__shuangxiong"] = "摸牌阶段，你可以改为亮出牌堆顶两张牌，你获得其中一张牌，然后本回合你可以将颜色与之不同的手牌当【决斗】使用；"..
  "当你受到以此法使用的【决斗】的伤害后，你可以获得其他角色响应此【决斗】打出的【杀】。",
  ["#m_ex__shuangxiong_trigger"] = "双雄",
  ["#m_ex__shuangxiong-get"] = "双雄：获得其中一张牌，本回合可以将不同颜色的手牌当【决斗】使用",
  ["#m_ex__shuangxiong-invoke"] = "双雄：是否放弃摸牌，改为亮出牌堆顶两张牌并获得其中一张？",
  ["#m_ex__shuangxiong-prey"] = "双雄：是否获得对方打出的【杀】？",

  ["$m_ex__shuangxiong1"] = "哥哥，且看我与赵云一战！/且与他战个五十回合！",
  ["$m_ex__shuangxiong2"] = "此战，如有你我一人在此，何惧华雄！/定叫他有去无回！",
  ["~m_ex__yanliangwenchou"] = "不是叫你看好我身后吗……",
}

local yuanshao = General(extension, "m_ex__yuanshao", "qun", 4)
local luanji = fk.CreateViewAsSkill{
  name = "m_ex__luanji",
  anim_type = "offensive",
  prompt = "#m_ex__luanji",
  card_filter = function(self, to_select, selected)
    if #selected < 2 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip then
      local suit = Fk:getCardById(to_select):getSuitString(true)
      return suit ~= "log_nosuit" and not table.contains(Self:getTableMark("@m_ex__luanji-phase"), suit)
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 2 then return end
    local card = Fk:cloneCard("archery_attack")
    card:addSubcards(cards)
    return card
  end,
  before_use = function (self, player, use)
    local mark = player:getTableMark("@m_ex__luanji-phase")
    for _, id in ipairs(use.card.subcards) do
      table.insertIfNeed(mark, Fk:getCardById(id):getSuitString(true))
    end
    player.room:setPlayerMark(player, "@m_ex__luanji-phase", mark)
  end,
}
local luanji_trigger = fk.CreateTriggerSkill{
  name = "#m_ex__luanji_trigger",
  mute = true,
  main_skill = luanji,
  events = {fk.CardResponding, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(luanji) then
      if event == fk.CardResponding then
        return data.card.name == "jink" and data.responseToEvent and data.responseToEvent.from == player.id and
          data.responseToEvent.card.trueName == "archery_attack" and not target.dead
      elseif event == fk.CardUseFinished then
        return target == player and data.card.trueName == "archery_attack" and not data.damageDealt and
          #TargetGroup:getRealTargets(data.tos) > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("m_ex__luanji")
    if event == fk.CardResponding then
      target:drawCards(1, "m_ex__luanji")
    elseif event == fk.CardUseFinished then
      player:drawCards(#TargetGroup:getRealTargets(data.tos), "m_ex__luanji")
    end
  end,
}
luanji:addRelatedSkill(luanji_trigger)
yuanshao:addSkill(luanji)
yuanshao:addSkill("xueyi")
Fk:loadTranslationTable{
  ["m_ex__yuanshao"] = "界袁绍",
  ["#m_ex__yuanshao"] = "高贵的名门",
  ["illustrator:m_ex__yuanshao"] = "17号工坊",

  ["m_ex__luanji"] = "乱击",
  [":m_ex__luanji"] = "出牌阶段，你可以将两张手牌当【万箭齐发】使用（不能使用本阶段发动此技能已使用过的花色）；其他角色响应你使用的"..
  "【万箭齐发】打出【闪】时，其摸一张牌；你使用【万箭齐发】结算后，若没有角色受到此牌伤害，你摸此【万箭齐发】指定目标数的牌。",
  ["#m_ex__luanji"] = "乱击：将两张手牌当【万箭齐发】使用，不能使用本阶段已用过的花色",
  ["@m_ex__luanji-phase"] = "乱击",
  ["#m_ex__luanji_trigger"] = "乱击",

  ["$m_ex__luanji1"] = "万箭穿心，灭其士气。",
  ["$m_ex__luanji2"] = "卿当与本公同心戮力，共安社稷。",
  ["$xueyi_m_ex__yuanshao1"] = "名门思召，朝野敬仰。",
  ["$xueyi_m_ex__yuanshao2"] = "吾乃名门望族，岂能与汝等为伍？",
  ["~m_ex__yuanshao"] = "袁门不幸啊……",
}

local xuhuang = General(extension, "m_ex__xuhuang", "wei", 4)
local duanliang = fk.CreateViewAsSkill{
  name = "m_ex__duanliang",
  anim_type = "control",
  pattern = "supply_shortage",
  prompt = "#m_ex__duanliang",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and Fk:getCardById(to_select).type ~= Card.TypeTrick
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("supply_shortage")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
local duanliang_targetmod = fk.CreateTargetModSkill{
  name = "#m_ex__duanliang_targetmod",
  main_skill = duanliang,
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(duanliang) and skill.name == "supply_shortage_skill" and to:getHandcardNum() >= player:getHandcardNum()
  end,
}
local jiezi = fk.CreateTriggerSkill{
  name = "m_ex__jiezi",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player ~= target and target and target.skipped_phases[Player.Draw] and
        player:usedSkillTimes(self.name, Player.HistoryTurn) < 1 then
      return data.to == Player.Play or data.to == Player.Discard or data.to == Player.Finish
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
duanliang:addRelatedSkill(duanliang_targetmod)
xuhuang:addSkill(duanliang)
xuhuang:addSkill(jiezi)
Fk:loadTranslationTable{
  ["m_ex__xuhuang"] = "界徐晃",
  ["#m_ex__xuhuang"] = "周亚夫之风",
  ["illustrator:m_ex__xuhuang"] = "波子",

  ["m_ex__duanliang"] = "断粮",
  [":m_ex__duanliang"] = "你可以将一张黑色非锦囊牌当【兵粮寸断】使用。你对手牌数不小于你的角色使用【兵粮寸断】无距离限制。",
  ["m_ex__jiezi"] = "截辎",
  [":m_ex__jiezi"] = "锁定技，当一名其他角色跳过摸牌阶段后，你摸一张牌。",
  ["#m_ex__duanliang"] = "断粮：你可以将一张黑色非锦囊牌当【兵粮寸断】使用",

  ["$m_ex__duanliang1"] = "粮不三载，敌军已犯行军大忌。",
  ["$m_ex__duanliang2"] = "断敌粮秣，此战可胜。",
  ["$m_ex__jiezi1"] = "因粮于敌，故军食可足也。",
  ["$m_ex__jiezi2"] = "食敌一钟，当吾二十钟。",
  ["~m_ex__xuhuang"] = "敌军防备周全，是吾轻敌……",
}

local caopi = General(extension, "m_ex__caopi", "wei", 3)
local xingshang = fk.CreateTriggerSkill{
  name = "m_ex__xingshang",
  anim_type = "drawcard",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not (target:isNude() and not player:isWounded())
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel"}
    if player:isWounded() then table.insert(choices, 1, "recover") end
    if not target:isNude() then table.insert(choices, 1, "m_ex__xingshang_obtain::" .. target.id) end
    local choice = player.room:askForChoice(player, choices, self.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data
    if choice == "recover" then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    else
      room:obtainCard(player.id, target:getCardIds{Player.Hand, Player.Equip}, false, fk.ReasonPrey)
    end
  end,
}
local fangzhu = fk.CreateTriggerSkill{
  name = "m_ex__fangzhu",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper), 1, 1,
      "#m_ex__fangzhu-choose:::"..player:getLostHp(), self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local num = player:getLostHp()
    if to.hp > 0 and #room:askForDiscard(to, num, num, true, self.name, true, nil, "#m_ex__fangzhu-ask:::" .. num, false) > 0 then
      if not to.dead then
        room:loseHp(to, 1, self.name)
      end
    else
      to:drawCards(num, self.name)
      if not to.dead then
        to:turnOver()
      end
    end
  end,
}
caopi:addSkill(xingshang)
caopi:addSkill(fangzhu)
caopi:addSkill("songwei")
Fk:loadTranslationTable{
  ["m_ex__caopi"] = "界曹丕",
  ["#m_ex__caopi"] = "霸业的继承者",
  ["illustrator:m_ex__caopi"] = "YanBai",

  ["m_ex__xingshang"] = "行殇",
  [":m_ex__xingshang"] = "当其他角色死亡时，你可以选择一项：1.获得其所有牌；2.回复1点体力。",
  ["m_ex__fangzhu"] = "放逐",
  [":m_ex__fangzhu"] = "当你受到伤害后，你可以令一名其他角色选择一项：1.弃置X张牌并失去1点体力；2.摸X张牌并翻面（X为你已损失的体力值）。",

  ["m_ex__xingshang_obtain"] = "获得%dest的所有牌",
  ["#m_ex__fangzhu-choose"] = "放逐：你可令一名其他角色选择摸%arg张牌并翻面，或弃置%arg张牌并失去1点体力",
  ["#m_ex__fangzhu-ask"] = "放逐：弃置%arg张牌并失去1点体力，或点击“取消”，摸%arg张牌并翻面",

  ["$m_ex__xingshang1"] = "群燕辞归鹄南翔，念君客游思断肠。",
  ["$m_ex__xingshang2"] = "霜露纷兮交下，木叶落兮凄凄。",
  ["$m_ex__fangzhu1"] = "国法不可废耳，汝先退去。",
  ["$m_ex__fangzhu2"] = "将军征战辛苦，孤当赠以良宅。",
  ["$songwei_m_ex__caopi1"] = "藩屏大宗，御侮厌难。",
  ["$songwei_m_ex__caopi2"] = "朕承符运，终受革命。",
  ["~m_ex__caopi"] = "建平所言八十，谓昼夜也，吾其决矣……",
}

local dengai = General(extension, "m_ex__dengai", "wei", 4)
local tuntian = fk.CreateTriggerSkill{
  name = "m_ex__tuntian",
  anim_type = "special",
  derived_piles = "dengai_field",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase == Player.NotActive then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
  end,

  refresh_events = {fk.FinishJudge},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and data.reason == self.name and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_refresh = function(self, event, target, player, data)
    if data.card.suit == Card.Heart then
      player.room:obtainCard(player, data.card, true, fk.ReasonJustMove)
    else
      player:addToPile("dengai_field", data.card, true, self.name)
    end
  end,
}
local tuntian_distance = fk.CreateDistanceSkill{
  name = "#m_ex__tuntian_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      return -#from:getPile("dengai_field")
    end
  end,
}
tuntian:addRelatedSkill(tuntian_distance)
dengai:addSkill(tuntian)
dengai:addSkill("zaoxian")
dengai:addRelatedSkill("jixi")
Fk:loadTranslationTable{
  ["m_ex__dengai"] = "界邓艾",
  ["#m_ex__dengai"] = "矫然的壮士",
  ["illustrator:m_ex__dengai"] = "凝聚永恒",

  ["m_ex__tuntian"] = "屯田",
  [":m_ex__tuntian"] = "当你于回合外失去牌后，你可以进行判定：若结果为<font color='red'>♥</font>，则你获得此判定牌；否则你将生效后的判定牌"..
  "置于你的武将牌上，称为“田”；你计算与其他角色的距离-X（X为“田”的数量）。",

  ["$m_ex__tuntian1"] = "休养生息，是为以备不虞。",
  ["$m_ex__tuntian2"] = "战损难免，应以军务减之。",
  ["$zaoxian_m_ex__dengai1"] = "用兵以险，则战之以胜！",
  ["$zaoxian_m_ex__dengai2"] = "已至马阁山，宜速进军破蜀！",
  ["$jixi_m_ex__dengai1"] = "攻敌之不备，斩将夺辎！",
  ["$jixi_m_ex__dengai2"] = "奇兵正攻，敌何能为？",
  ["~m_ex__dengai"] = "一片忠心，换来这般田地。",
}

local jiangwei = General(extension, "m_ex__jiangwei", "shu", 4)
local tiaoxin = fk.CreateActiveSkill{
  name = "m_ex__tiaoxin",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#m_ex__tiaoxin",
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
    local use = room:askForUseCard(target, self.name, "slash",
      "#m_ex__tiaoxin-use:"..player.id, true, {exclusive_targets = {player.id} })
    if use then
      room:useCard(use)
    else
      if not target:isNude() then
        local card = room:askForCardChosen(player, target, "he", self.name)
        room:throwCard(card, self.name, target, player)
      end
    end
  end
}
local zhiji = fk.CreateTriggerSkill{
  name = "m_ex__zhiji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "draw2" then
      player:drawCards(2, self.name)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    end
    if player.dead then return end
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "ex__guanxing", nil, true, false)
  end,
}
jiangwei:addSkill(tiaoxin)
jiangwei:addSkill(zhiji)
jiangwei:addRelatedSkill("ex__guanxing")
Fk:loadTranslationTable{
  ["m_ex__jiangwei"] = "界姜维",
  ["#m_ex__jiangwei"] = "龙的衣钵",
  ["illustrator:m_ex__jiangwei"] = "石蝉",

  ["m_ex__tiaoxin"] = "挑衅",
  [":m_ex__tiaoxin"] = "出牌阶段限一次，你可以选择一名其他角色，然后除非该角色对你使用一张【杀】，否则你弃置其一张牌。",
  ["m_ex__zhiji"] = "志继",
  [":m_ex__zhiji"] = "觉醒技，准备阶段，若你没有手牌，你回复1点体力或摸两张牌，减1点体力上限，然后获得〖观星〗。",
  ["#m_ex__tiaoxin"] = "挑衅：令一名角色对你使用【杀】，否则你弃置其一张牌",
  ["#m_ex__tiaoxin-use"] = "挑衅：对 %src 使用一张【杀】，否则其弃置你一张牌",

  ["$m_ex__tiaoxin1"] = "黄口竖子，何必上阵送命？",
  ["$m_ex__tiaoxin2"] = "汝如欲大败而归，则可进军一战！",
  ["$m_ex__zhiji1"] = "维定当奋身以复汉室。",
  ["$m_ex__zhiji2"] = "丞相之志，维必竭力而为。",
  ["$ex__guanxing_m_ex__jiangwei1"] = "知天易则观之，逆天难亦行之。",
  ["$ex__guanxing_m_ex__jiangwei2"] = "欲尽人事，亦先听天命。",
  ["~m_ex__jiangwei"] = "可惜大计未成，吾已身陨。",
}

local liushan = General(extension, "m_ex__liushan", "shu", 3)
local fangquan = fk.CreateTriggerSkill{
  name = "m_ex__fangquan",
  anim_type = "support",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:skip(Player.Play)
    return true
  end,
}
local fangquan_delay = fk.CreateTriggerSkill{
  name = "#m_ex__fangquan_delay",
  events = {fk.AfterTurnEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("m_ex__fangquan", Player.HistoryTurn) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "m_ex__fangquan", "support")
    local cards = table.filter(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id)
    end)
    local success, dat = room:askForUseActiveSkill(player, "choose_players_skill", "#m_ex__fangquan-choose", true, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      num = 1,
      min_num = 1,
      pattern = tostring(Exppattern{ id = cards }),
      skillName = "m_ex__fangquan",
    }, false)
    if success and dat then
      room:throwCard(dat.cards, "m_ex__fangquan", player, player)
      local to = room:getPlayerById(dat.targets[1])
      if not to.dead then
        to:gainAnExtraTurn(true, "m_ex__fangquan")
      end
    end
  end,
}
local fangquan_maxcards = fk.CreateMaxCardsSkill{
  name = "#m_ex__fangquan_maxcards",
  main_skill = fangquan,
  fixed_func = function(self, player)
    if player:usedSkillTimes("m_ex__fangquan", Player.HistoryTurn) > 0 then
      return player.maxHp
    end
  end
}
fangquan:addRelatedSkill(fangquan_delay)
fangquan:addRelatedSkill(fangquan_maxcards)
liushan:addSkill("xiangle")
liushan:addSkill(fangquan)
liushan:addSkill("ruoyu")
liushan:addRelatedSkill("jijiang")
Fk:loadTranslationTable{
  ["m_ex__liushan"] = "界刘禅",
  ["#m_ex__liushan"] = "无为的真命主",
  ["illustrator:m_ex__liushan"] = "绘聚艺堂",

  ["m_ex__fangquan"] = "放权",
  [":m_ex__fangquan"] = "你可以跳过出牌阶段，若如此做，本回合你的手牌上限等于你的体力上限，且本回合结束后，你可以弃置一张手牌，令一名其他角色"..
  "获得一个额外回合。",
  ["#m_ex__fangquan_delay"] = "放权",
  ["#m_ex__fangquan-choose"] = "放权：弃置一张手牌，令一名其他角色获得一个额外回合",

  ["$xiangle_m_ex__liushan1"] = "天府之国，自然民安国泰。",
  ["$xiangle_m_ex__liushan2"] = "战事扰乱民生，不如作罢。",
  ["$m_ex__fangquan1"] = "爱卿自行定夺便是。",
  ["$m_ex__fangquan2"] = "北伐事重，相父全权处理即可。",
  ["$ruoyu_m_ex__liushan1"] = "唯有自认庸主之名，方能保蜀地官民无虞啊。",
  ["$ruoyu_m_ex__liushan2"] = "既无争雄天下之才，只好做守成之主。",
  ["$jijiang_m_ex__liushan1"] = "还望诸卿勠力同心，以保国祚。",
  ["$jijiang_m_ex__liushan2"] = "哪位爱卿愿意报效国家？",
  ["~m_ex__liushan"] = "实在有愧父皇与相父啊……",
}

local sunce = General(extension, "m_ex__sunce", "wu", 4)
local hunzi = fk.CreateTriggerSkill{
  name = "m_ex__hunzi",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player.hp <= 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:addSkillUseHistory("hunzi", 1)  --以触发制霸拒绝拼点
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "ex__yingzi|yinghun", nil, true, false)
  end,
}
sunce:addSkill("jiang")
sunce:addSkill(hunzi)
sunce:addSkill("zhiba")
sunce:addRelatedSkill("ex__yingzi")
sunce:addRelatedSkill("yinghun")
Fk:loadTranslationTable{
  ["m_ex__sunce"] = "界孙策",
  ["#m_ex__sunce"] = "江东的小霸王",
  ["illustrator:m_ex__sunce"] = "凝聚永恒",

  ["m_ex__hunzi"] = "魂姿",
  [":m_ex__hunzi"] = "觉醒技，准备阶段，若你的体力值不大于2，你减1点体力上限，然后获得〖英姿〗和〖英魂〗。",

  ["$jiang_m_ex__sunce1"] = "我会把胜利带回江东。",
  ["$jiang_m_ex__sunce2"] = "天下英雄，谁能与我一战？",
  ["$m_ex__hunzi1"] = "小霸王之名响彻天下，何人不知？",
  ["$m_ex__hunzi2"] = "江东已平，中原动荡，直取许昌。",
  ["$zhiba_m_ex__sunce1"] = "我的霸业才刚刚开始。",
  ["$zhiba_m_ex__sunce2"] = "汝是战是降，我皆奉陪。",
  ["$ex__yingzi_m_ex__sunce1"] = "有公瑾助我，可平天下。",
  ["$ex__yingzi_m_ex__sunce2"] = "所到之处，战无不胜。",
  ["$yinghun_m_ex__sunce1"] = "武烈之魂，助我扬名。",
  ["$yinghun_m_ex__sunce2"] = "江东之主，众望所归。",
  ["~m_ex__sunce"] = "大业未就，中世而殒……",
}

local zhangzhaozhanghong = General(extension, "m_ex__zhangzhaozhanghong", "wu", 3)
local zhijian = fk.CreateActiveSkill{
  name = "m_ex__zhijian",
  anim_type = "support",
  prompt = "#zhijian-active",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip and
      Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and #selected_cards == 1 and to_select ~= Self.id and
    Fk:currentRoom():getPlayerById(to_select):canMoveCardIntoEquip(selected_cards[1], false)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardIntoEquip(target, effect.cards[1], self.name, true, player)
    if not player.dead then
      room:drawCards(player, 1, self.name)
    end
  end,
}
local zhijian_trigger = fk.CreateTriggerSkill{
  name = "#m_ex__zhijian_trigger",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhijian) and data.card.type == Card.TypeEquip and player.phase == Player.Play
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("m_ex__zhijian")
    player.room:notifySkillInvoked(player, "m_ex__zhijian", "drawcard")
    player:drawCards(1, "m_ex__zhijian")
  end,
}
zhijian:addRelatedSkill(zhijian_trigger)
zhangzhaozhanghong:addSkill(zhijian)
zhangzhaozhanghong:addSkill("guzheng")
Fk:loadTranslationTable{
  ["m_ex__zhangzhaozhanghong"] = "界张昭张纮",
  ["#m_ex__zhangzhaozhanghong"] = "经天纬地",
  ["illustrator:m_ex__zhangzhaozhanghong"] = "绘聚艺堂",

  ["m_ex__zhijian"] = "直谏",
  [":m_ex__zhijian"] = "出牌阶段，你可以将手牌中的一张装备牌置于其他角色的装备区里，然后摸一张牌。当你于出牌阶段使用装备牌时，你摸一张牌。",
  ["#m_ex__zhijian_trigger"] = "直谏",

  ["$m_ex__zhijian1"] = "为臣之道，在于直言无讳。",
  ["$m_ex__zhijian2"] = "谏言或逆耳，于国无一害。",
  ["$guzheng_m_ex__zhangzhaozhanghong1"] = "为君者，不可肆兴土木，奢费物力。",
  ["$guzheng_m_ex__zhangzhaozhanghong2"] = "安民固国，方可思动。",
  ["~m_ex__zhangzhaozhanghong"] = "只恨不能为东吴百姓再谋一日福祉……",
}

local caiwenji = General(extension, "m_ex__caiwenji", "qun", 3, 3, General.Female)
local beige = fk.CreateTriggerSkill{
  name = "m_ex__beige",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card and data.card.trueName == "slash" and not data.to.dead and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#beige-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.suit == Card.Heart then
      if target:isWounded() and not target.dead then
        room:recover{
          who = target,
          num = data.damage,
          recoverBy = player,
          skillName = self.name
        }
      end
    elseif judge.card.suit == Card.Diamond then
      if not target.dead then
        target:drawCards(3, self.name)
      end
    elseif judge.card.suit == Card.Club then
      if data.from and not data.from.dead then
        room:askForDiscard(data.from, 2, 2, true, self.name, false)
      end
    elseif judge.card.suit == Card.Spade then
      if data.from and not data.from.dead then
        data.from:turnOver()
      end
    end
  end,
}
caiwenji:addSkill(beige)
caiwenji:addSkill("duanchang")
Fk:loadTranslationTable{
  ["m_ex__caiwenji"] = "界蔡文姬",
  ["#m_ex__caiwenji"] = "异乡的孤女",
  ["illustrator:m_ex__caiwenji"] = "青学",

  ["m_ex__beige"] = "悲歌",
  [":m_ex__beige"] = "当一名角色受到【杀】造成的伤害后，你可以弃置一张牌，令其进行判定，若结果为：<font color='red'>♥</font>，其回复X点体力"..
  "（X为其本次受到的伤害值）；<font color='red'>♦</font>，其摸三张牌；♣，伤害来源弃置两张牌；♠，伤害来源翻面。",

  ["$m_ex__beige1"] = "人多暴猛兮如虺蛇，控弦披甲兮为骄奢。",
  ["$m_ex__beige2"] = "两拍张弦兮弦欲绝，志摧心折兮自悲嗟。",
  ["$duanchang_m_ex__caiwenji1"] = "雁飞高兮邈难寻，空断肠兮思愔愔。",
  ["$duanchang_m_ex__caiwenji2"] = "为天有眼兮，何不见我独飘流？",
  ["~m_ex__caiwenji"] = "今别子兮归故乡，旧怨平兮新怨长！",
}

return extension
