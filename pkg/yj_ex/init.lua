local extension = Package:new("m_yj_ex")
extension.extensionName = "mobile"

local prefix = "packages.mobile.pkg.yj_ex.skills."

extension:loadSkillSkels{
  require(prefix .. "pojun"),
  require(prefix .. "ganlu"),
  require(prefix .. "xianzhen"),
  require(prefix .. "jinjiu"),
  require(prefix .. "jieyue"),
  require(prefix .. "jieyue_active"),
  require(prefix .. "jiushi"),
  require(prefix .. "chengzhang"),
  require(prefix .. "xuanfeng"),
  require(prefix .. "xuanfeng_active"),
  require(prefix .. "yicong"),
  require(prefix .. "quanji"),
  require(prefix .. "zili"),
  require(prefix .. "paiyi"),
  require(prefix .. "zongshi"),
  require(prefix .. "anxu"),
  require(prefix .. "dangxian"),
  require(prefix .. "fuli"),
  require(prefix .. "jiangchi"),
  require(prefix .. "danshou"),
  require(prefix .. "duodao"),
  require(prefix .. "anjian"),
  require(prefix .. "junxing"),
  require(prefix .. "qiaoshui"),
  require(prefix .. "zongshij"),
}

Fk:loadTranslationTable{
  ["m_yj_ex"] = "手杀-界一将成名",
  ["m_ex"] = "手杀界",
}

General:new(extension, "m_ex__xusheng", "wu", 4):addSkills {
  "m_ex__pojun"
}

Fk:loadTranslationTable{
  ["m_ex__xusheng"] = "界徐盛",
  ["#m_ex__xusheng"] = "江东的铁壁",
  ["cv:m_ex__xusheng"] = "金垚",
  ["illustrator:m_ex__xusheng"] = "铁杵文化",
  ["~m_ex__xusheng"] = "盛只恨，不能再为主公，破敌致胜了。",
}

General:new(extension, "m_ex__wuguotai", "wu", 3, 3, General.Female):addSkills {
  "m_ex__ganlu",
  --"buyi"
}

Fk:loadTranslationTable{
  ["m_ex__wuguotai"] = "界吴国太",
  ["#m_ex__wuguotai"] = "慈怀瑾瑜",
  ["illustrator:m_ex__wuguotai"] = "李秀森",
  ["~m_ex__wuguotai"] = "诸位卿家，还请尽力辅佐仲谋啊……",

  ["$buyi_m_ex__wuguotai1"] = "有我在，定保贤婿无虞！",
  ["$buyi_m_ex__wuguotai2"] = "东吴岂容汝等儿戏！",
}

General:new(extension, "m_ex__gaoshun", "qun", 4):addSkills {
  "m_ex__xianzhen",
  "m_ex__jinjiu"
}

Fk:loadTranslationTable{
  ["m_ex__gaoshun"] = "界高顺",
  ["#m_ex__gaoshun"] = "攻无不克",
  ["illustrator:m_ex__gaoshun"] = "蛋费鸡丁",
  ["~m_ex__gaoshun"] = "可叹主公知而不用啊！",
}

General:new(extension, "m_ex__yujin", "wei", 4):addSkills {
  "m_ex__jieyue"
}

Fk:loadTranslationTable{
  ["m_ex__yujin"] = "界于禁",
  ["#m_ex__yujin"] = "讨暴坚垒",
  ["illustrator:m_ex__yujin"] = "biou09",
  ["~m_ex__yujin"] = "如今临危处难，却负丞相三十年之赏识，唉……",
}

General:new(extension, "m_ex__caozhi", "wei", 3):addSkills {
  --"luoying",
  "m_ex__jiushi",
  "chengzhang"
}

Fk:loadTranslationTable{
  ["m_ex__caozhi"] = "界曹植",
  ["#m_ex__caozhi"] = "八斗之才",
  ["illustrator:m_ex__caozhi"] = "青岛磐蒲",
  ["~m_ex__caozhi"] = "先民谁不死，知命复何忧？",

  ["$luoying_m_ex__caozhi1"] = "转蓬离本根，飘摇随长风。",
  ["$luoying_m_ex__caozhi2"] = "高树多悲风，海水扬其波。",
}

General:new(extension, "m_ex__lingtong", "wu", 4):addSkills {
  "m_ex__xuanfeng"
}

Fk:loadTranslationTable{
  ["m_ex__lingtong"] = "界凌统",
  ["#m_ex__lingtong"] = "豪情烈胆",
  ["illustrator:m_ex__lingtong"] = "青岛磐蒲",
  ["~m_ex__lingtong"] = "先……停一下吧……",
}

General:new(extension, "m_ex__gongsunzan", "qun", 4):addSkills {
  --"qiaomeng",
  "m_ex__yicong"
}

Fk:loadTranslationTable{
  ["m_ex__gongsunzan"] = "界公孙瓒",
  ["#m_ex__gongsunzan"] = "白马将军",
  ["illustrator:m_ex__gongsunzan"] = "fingerling",
  ["~m_ex__gongsunzan"] = "啊！（马叫声）",

  ["$qiaomeng_m_ex__gongsunzan1"] = "夺汝兵刃战马，尔等必败无疑。",
  ["$qiaomeng_m_ex__gongsunzan2"] = "摧敌思折枯，荡寇如反掌。",
}

local zhonghui = General:new(extension, "m_ex__zhonghui", "wei", 4)
zhonghui:addSkills { "m_ex__quanji", "m_ex__zili" }
zhonghui:addRelatedSkills{ "m_ex__paiyi" }

Fk:loadTranslationTable{
  ["m_ex__zhonghui"] = "界钟会",
  ["#m_ex__zhonghui"] = "桀骜的野心家",
  ["illustrator:m_ex__zhonghui"] = "monkey",
  ["~m_ex__zhonghui"] = "父亲，吾能自知。却终不能自制……",
}

General:new(extension, "m_ex__liubiao", "qun", 3):addSkills {
  --"qiaomeng",
  "m_ex__zongshi"
}

Fk:loadTranslationTable{
  ["m_ex__liubiao"] = "界刘表",
  ["#m_ex__liubiao"] = "跨蹈汉南",
  ["illustrator:m_ex__liubiao"] = "光域",
  ["~m_ex__liubiao"] = "垂垂老矣，已忘壮年雄心……",

  ["$re__zishou_m_ex__liubiao1"] = "忍时待机，以期坐收渔利！",
  ["$re__zishou_m_ex__liubiao2"] = "按兵不动，徐图荆襄霸业！",
}

General:new(extension, "m_ex__bulianshi", "wu", 3, 3, General.Female):addSkills {
  "m_ex__anxu",
  --"zhuiyi"
}

Fk:loadTranslationTable{
  ["m_ex__bulianshi"] = "界步练师",
  ["#m_ex__bulianshi"] = "无冕之后",
  ["illustrator:m_ex__bulianshi"] = "凡果",
  ["~m_ex__bulianshi"] = "今生先君逝，来世再侍君……",
  ["$m_ex__bulianshi_win_audio"] = "壮我江东，人才济济！",

  ["$zhuiyi_m_ex__bulianshi1"] = "化作桃园只为君。",
  ["$zhuiyi_m_ex__bulianshi2"] = "魂若有灵，当助夫君。",
}

General:new(extension, "m_ex__liaohua", "shu", 4):addSkills {
  "m_ex__dangxian",
  "m_ex__fuli"
}

Fk:loadTranslationTable{
  ["m_ex__liaohua"] = "界廖化",
  ["#m_ex__liaohua"] = "历尽沧桑",
  ["illustrator:m_ex__liaohua"] = "聚一工作室",
  ["~m_ex__liaohua"] = "兴复大业，就靠你们了！",
}

General:new(extension, "m_ex__caozhang", "wei", 4):addSkills {
  "m_ex__jiangchi"
}

Fk:loadTranslationTable{
  ["m_ex__caozhang"] = "界曹彰",
  ["#m_ex__caozhang"] = "黄须儿",
  ["illustrator:m_ex__caozhang"] = "枭瞳",
  ["~m_ex__caozhang"] = "黄须金甲，也难敌骨肉毒心！",
}

General:new(extension, "m_ex__zhuran", "wu", 4):addSkills {
  "m_ex__danshou"
}

Fk:loadTranslationTable{
  ["m_ex__zhuran"] = "界朱然",
  ["#m_ex__zhuran"] = "不动之督",
  ["illustrator:m_ex__zhuran"] = "zoo",
  ["~m_ex__zhuran"] = "大耳贼就在眼前，快追……",
}

General:new(extension, "m_ex__jianyong", "shu", 3):addSkills {
  "m_ex__qiaoshui",
  "m_ex__zongshij"
}

Fk:loadTranslationTable{
  ["m_ex__jianyong"] = "界简雍",
  ["#m_ex__jianyong"] = "悠游风议",
  ["illustrator:m_ex__jianyong"] = "zoo",
  ["~m_ex__jianyong"] = "行事无矩，为人所恶矣。",
}





General:new(extension, "m_ex__manchong", "wei", 3):addSkills {
  "m_ex__junxing",
  --"yuce"
}

Fk:loadTranslationTable{
  ["m_ex__manchong"] = "界满宠",
  ["#m_ex__manchong"] = "政法兵谋",
  ["designer:m_ex__manchong"] = "Loun老萌",
  ["illustrator:m_ex__manchong"] = "YanBai",
  ["~m_ex__manchong"] = "宠一生为公，无愧忠俭之节。",

  ["$yuce_m_ex__manchong1"] = "骄之以利，示之以慑！",
  ["$yuce_m_ex__manchong2"] = "虽举得于外，则福生于内矣。",
}

General:new(extension, "m_ex__panzhangmazhong", "wu", 4):addSkills {
  "m_ex__duodao",
  "m_ex__anjian"
}

Fk:loadTranslationTable{
  ["m_ex__panzhangmazhong"] = "潘璋马忠",
  ["#m_ex__panzhangmazhong"] = "擒龙伏虎",
  ["illustrator:m_ex__panzhangmazhong"] = "凝聚永恒",
  ["~m_ex__panzhangmazhong"] = "埋伏得这么好，怎会……",
}


return extension
