local extension = Package:new("mobile_lxxh")
extension.extensionName = "mobile"

extension:loadSkillSkels(require("packages.mobile.pkg.mobile_lxxh.skills"))

Fk:loadTranslationTable{
  ["mobile_lxxh"] = "手杀-龙血玄黄",
  ["m_sp"] = "手杀SP",
  ["mobile2"] = "手杀",
}

local caomao = General:new(extension, "mobile__caomao", "wei", 3)
caomao:addSkills { "mobile__qianlong", "weitong" }
caomao:addRelatedSkills { "mobile_qianlong__qingzheng", "mobile_qianlong__jiushi", "mobile_qianlong__fangzhu", "juejin" }
Fk:loadTranslationTable{
  ["mobile__caomao"] = "曹髦",
  ["#mobile__caomao"] = "向死存魏",
  ["illustrator:mobile__caomao"] = "铁杵",

  ["$mobile__caomao_win_audio"] = "少康诛寒浞以中兴，朕夷司马未尝不可！",
  ["~mobile__caomao"] = "纵不成身死，朕亦为太祖子孙，大魏君王……",
}
local caomao2 = General:new(extension, "mobile2__caomao", "wei", 3)
caomao2:addSkills { "mobile__qianlong", "weitong" }
caomao2:addRelatedSkills { "mobile_qianlong__qingzheng", "mobile_qianlong__jiushi", "mobile_qianlong__fangzhu", "juejin" }
caomao2.total_hidden = true
Fk:loadTranslationTable{
  ["mobile2__caomao"] = "曹髦",
  ["#mobile2__caomao"] = "向死存魏",
  ["illustrator:mobile2__caomao"] = "铁杵",

  ["~mobile2__caomao"] = "纵不成身死，朕亦为太祖子孙，大魏君王……",
}

General:new(extension, "m_sp__guanqiujian", "wei", 4):addSkills { "cuizhen", "kuili" }
Fk:loadTranslationTable{
  ["m_sp__guanqiujian"] = "毌丘俭",
  ["#m_sp__guanqiujian"] = "才识拔干",
  ["illustrator:m_sp__guanqiujian"] = "凝聚永恒",

  ["~m_sp__guanqiujian"] = "汝不讨篡权逆臣，何杀吾讨贼义军……",
}

General:new(extension, "lizhaojiaobo", "wei", 4):addSkills { "zuoyou", "shishoul" }
Fk:loadTranslationTable{
  ["lizhaojiaobo"] = "李昭焦伯",
  ["#lizhaojiaobo"] = "竭诚尽节",
  ["illustrator:lizhaojiaobo"] = "凝聚永恒",

  ["~lizhaojiaobo"] = "陛下！！尔等乱臣，安敢弑君！呃啊……",
}

General:new(extension, "chengjiw", "wei", 4):addSkills { "kuangli", "xiongsi" }
Fk:loadTranslationTable{
  ["chengjiw"] = "成济",
  ["#chengjiw"] = "劣犬良弓",
  ["illustrator:chengjiw"] = "凝聚永恒",

  ["~chengjiw"] = "汝等要卸磨杀驴吗？呃啊……",
}

local simafu = General:new(extension, "mobile__simafu", "wei", 3)
simafu:addSkills { "panxiang", "mobile__chenjie" }
simafu.subkingdom = "jin"
Fk:loadTranslationTable{
  ["mobile__simafu"] = "司马孚",
  ["#mobile__simafu"] = "徒难夷惠",
  ["illustrator:mobile__simafu"] = "鬼画府",

  ["~mobile__simafu"] = "生此篡逆之事，罪臣难辞其咎……",
}

General:new(extension, "mobile__wenqin", "wei", 4):addSkills { "beiming", "choumang" }
Fk:loadTranslationTable{
  ["mobile__wenqin"] = "文钦",
  ["#mobile__wenqin"] = "淮山骄腕",
  ["illustrator:mobile__wenqin"] = "铁杵",

  ["~mobile__wenqin"] = "伺君兵败之日，必报此仇于九泉！",
}

local simazhou = General:new(extension, "mobile__simazhou", "wei", 4)
simazhou:addSkills { "bifeng", "suwang" }
simazhou.subkingdom = "jin"
Fk:loadTranslationTable{
  ["mobile__simazhou"] = "司马伷",
  ["#mobile__simazhou"] = "恭温克己",
  -- ["illustrator:mobile__simazhou"] = "",

  ["~mobile__simazhou"] = "臣所求唯莽伏太妃陵次，分国封四子而已。",
}

local jiachong = General:new(extension, "mobile__jiachong", "qun", 3)
jiachong:addSkills { "mobile__beini", "mobile__dingfa" }
jiachong.subkingdom = "jin"
Fk:loadTranslationTable{
  ["mobile__jiachong"] = "贾充",
  ["#mobile__jiachong"] = "凶凶踽行",
  ["designer:mobile__jiachong"] = "Loun老萌",
  ["illustrator:mobile__jiachong"] = "铁杵文化",
  ["cv:mobile__jiachong"] = "虞晓旭",

  ["~mobile__jiachong"] = "此生从势忠命，此刻，只乞不获恶谥……",
}

return extension
