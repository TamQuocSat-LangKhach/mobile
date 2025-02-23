local extension = Package:new("mobile_shiji")
extension.extensionName = "mobile"

extension:loadSkillSkels(require("packages.mobile.pkg.mobile_shiji.skills"))

Fk:loadTranslationTable{
  ["mobile_shiji"] = "手杀-始计篇",
}

--智：王粲 陈震 荀谌 费祎 骆统 杜预 孙邵 卞夫人 神郭嘉 神荀彧
General:new(extension, "mobile__wangcan", "wei", 3):addSkills { "wisdom__qiai", "wisdom__shanxi" }
Fk:loadTranslationTable{
  ["mobile__wangcan"] = "王粲",
  ["#mobile__wangcan"] = "词章纵横",
  ["illustrator:mobile__wangcan"] = "鬼画府",

  ["~mobile__wangcan"] = "悟彼下泉人，喟然伤心肝……",
}

General:new(extension, "chenzhen", "shu", 3):addSkills { "shameng" }
Fk:loadTranslationTable{
  ["chenzhen"] = "陈震",
  ["#chenzhen"] = "歃盟使节",
  ["illustrator:chenzhen"] = "成都劲心",

  ["~chenzhen"] = "若毁盟约，则两败俱伤！",
}

General:new(extension, "luotong", "wu", 4):addSkills { "qinzheng" }
Fk:loadTranslationTable{
  ["luotong"] = "骆统",
  ["#luotong"] = "力政人臣",
  ["illustrator:luotong"] = "鬼画府",

  ["~luotong"] = "臣统之大愿，足以死而不朽矣。",
}

General:new(extension, "mobile__bianfuren", "wei", 3, 3, General.Female):addSkills { "mobile__wanwei", "mobile__yuejian" }
Fk:loadTranslationTable{
  ["mobile__bianfuren"] = "卞夫人",
  ["#mobile__bianfuren"] = "内助贤后",
  ["illustrator:mobile__bianfuren"] = "芝芝不加糖",

  ["~mobile__bianfuren"] = "孟德大人，妾身可以再伴你身边了……",
}

local godguojia = General:new(extension, "godguojia", "god", 3)
godguojia:addSkills { "mobile__huishi", "mobile__tianyi", "huishig" }
godguojia:addRelatedSkill("zuoxing")
Fk:loadTranslationTable{
  ["godguojia"] = "神郭嘉",
  ["#godguojia"] = "星月奇佐",
  ["illustrator:godguojia"] = "木美人",

  ["~godguojia"] = "可叹桢干命也迂……",
  ["$godguojia_win_audio"] = "既为奇佐，怎可徒有虚名？",
}

General:new(extension, "godxunyu", "god", 3):addSkills { "tianzuo", "lingce", "dinghan" }
Fk:loadTranslationTable{
  ["godxunyu"] = "神荀彧",
  ["#godxunyu"] = "洞心先识",
  ["illustrator:godxunyu"] = "枭瞳",

  ["~godxunyu"] = "宁鸣而死，不默而生……",
  ["$godxunyu_win_audio"] = "汉室复兴，指日可待！",
}

--信：辛毗 周处 吴景 王甫赵累 羊祜 糜夫人 王凌 孔融 神太史慈 神孙策

--仁：许靖 向宠 刘璋 华歆 张仲景 张温 蔡贞姬 桥公 神华佗 神鲁肃

--勇：孙翊 高览 宗预 花鬘 陈武董袭 文鸯 袁涣 王双

--严：蒋琬 蒋钦 崔琰 张昌蒲 吕范 皇甫嵩 朱儁 刘巴

return extension
