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

return extension
