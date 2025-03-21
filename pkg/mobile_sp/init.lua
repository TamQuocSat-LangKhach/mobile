local extension = Package:new("mobile_sp")
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/mobile_sp/skills")

Fk:loadTranslationTable{
  ["mobile_sp"] = "手杀-SP",
}

--SP1：-
--SP2：孙鲁育
local sunluyu = General:new(extension, "mobile__sunluyu", "wu", 3, 3, General.Female)
sunluyu:addSkills { "mobile__meibu", "mobile__mumu" }
sunluyu:addRelatedSkill("mobile__zhixi")
Fk:loadTranslationTable{
  ["mobile__sunluyu"] = "孙鲁育",
  ["#mobile__sunluyu"] = "舍身饲虎",
  ["illustrator:mobile__sunluyu"] = "鬼画府",

  ["~mobile__sunluyu"] = "今朝遭诬含冤去，他日丹青还我清！",
}

--SP3：-
--SP4：贺齐
local heqi = General:new(extension, "mobile__heqi", "wu", 4)
heqi:addSkills { "mobile__qizhou", "mobile__shanxi" }
heqi:addRelatedSkills { "yingzi", "qixi", "xuanfeng" }
Fk:loadTranslationTable{
  ["mobile__heqi"] = "贺齐",
  ["#mobile__heqi"] = "马踏群峦",
  ["illustrator:mobile__heqi"] = "白夜零BYL",

  ["~mobile__heqi"] = "我军器精甲坚，竟也落败……",
}

--SP5：马忠
General:new(extension, "mazhong", "shu", 4):addSkills { "fuman" }
Fk:loadTranslationTable{
  ["mazhong"] = "马忠",
  ["#mazhong"] = "笑合南中",
  ["designer:mazhong"] = "Virgopaladin",
  ["illustrator:mazhong"] = "Thinking",

  ["~mazhong"] = "丞相不在，你们竟然……",
}

--SP6：董承 卫温诸葛直
General:new(extension, "mobile__dongcheng", "qun", 4):addSkills { "chengzhao" }
Fk:loadTranslationTable{
  ["mobile__dongcheng"] = "董承",
  ["#mobile__dongcheng"] = "沥胆卫汉",
  ["illustrator:mobile__dongcheng"] = "绘聚艺堂",

  ["~mobile__dongcheng"] = "九泉之下，我等着你曹贼到来！",
}

General:new(extension, "mobile__weiwenzhugezhi", "wu", 4):addSkills { "mobile__fuhaiw" }
Fk:loadTranslationTable{
  ["mobile__weiwenzhugezhi"] = "卫温诸葛直",
  ["#mobile__weiwenzhugezhi"] = "帆至夷洲",
  ["illustrator:mobile__weiwenzhugezhi"] = "biou09",

  ["~mobile__weiwenzhugezhi"] = "吾皆海岱清士，岂料生死易逝……",
}

--SP7：陶谦 杨仪 关索
General:new(extension, "taoqian", "qun", 3):addSkills { "zhaohuo", "yixiang", "yirang" }
Fk:loadTranslationTable{
  ["taoqian"] = "陶谦",
  ["#taoqian"] = "膺秉温仁",
  ["illustrator:taoqian"] = "F.源",
  ["designer:taoqian"] = "Rivers",

  ["~taoqian"] = "悔不该差使小人，招此祸患。",
}

General:new(extension, "mobile__yangyi", "shu", 3):addSkills { "os__duoduan", "mobile__gongsun" }
Fk:loadTranslationTable{
  ["mobile__yangyi"] = "杨仪",
  ["#mobile__yangyi"] = "孤鹬",
  ["illustrator:mobile__yangyi"] = "铁杵文化",

  ["$os__duoduan_mobile__yangyi1"] = "度势而谋，断计求胜。",
  ["$os__duoduan_mobile__yangyi2"] = "逢敌先虑，定策后图。",
  ["~mobile__yangyi"] = "如今追悔，亦不可复及矣……",
}

local guansuo = General:new(extension, "guansuo", "shu", 4)
guansuo:addSkills { "zhengnan", "xiefang" }
guansuo:addRelatedSkills { "wusheng", "dangxian", "zhiman" }
Fk:loadTranslationTable{
  ["guansuo"] = "关索",
  ["#guansuo"] = "倜傥孑侠",
  ["designer:guansuo"] = "千幻",
  ["illustrator:guansuo"] = "depp",

  ["$wusheng_guansuo"] = "逆贼，可识得关氏之勇？",
  ["$dangxian_guansuo"] = "各位将军，且让小辈先行出战！",
  ["$zhiman_guansuo"] = "蛮夷可抚，不可剿！",
  ["~guansuo"] = "只恨天下未平，空留遗志。",
}

--SP8：审配
General:new(extension, "mobile__shenpei", "qun", 2, 3):addSkills { "shouye", "liezhi" }
Fk:loadTranslationTable{
  ["mobile__shenpei"] = "审配",
  ["#mobile__shenpei"] = "正南义北",
  ["illustrator:mobile__shenpei"] = "YanBai",

  ["~mobile__shenpei"] = "吾君在北，但求面北而亡！",
}

--SP9：苏飞 贾逵 张恭 许贡 曹婴 鲍三娘 徐荣
General:new(extension, "mobile__zhanggong", "wei", 3):addSkills { "mobile__qianxinz", "zhenxing" }
Fk:loadTranslationTable{
  ["mobile__zhanggong"] = "张恭",
  ["#mobile__zhanggong"] = "西域长歌",
  ["illustrator:mobile__zhanggong"] = "B_LEE",
  ["designer:mobile__zhanggong"] = "笔枔",

  ["$zhenxing_mobile__zhanggong1"] = "东征西讨，募军百里挑一。",
  ["$zhenxing_mobile__zhanggong2"] = "众口铄金，积毁销骨。",
  ["~mobile__zhanggong"] = "大漠孤烟，孤立无援啊……",
}
--SP10：丁原 傅肜 邓芝 陈登 张翼 张琪瑛 公孙康 周群
--SP11：阎圃 马元义 毛玠 傅佥 阮慧 马日磾 王濬
--SP12：赵统赵广 刘晔 李丰 诸葛果 胡金定 王元姬 羊徽瑜 杨彪 司马昭
--SP13：曹嵩 裴秀 杨阜 彭羕 牵招 郭女王 韩遂 阎象 李遗
local peixiu = General:new(extension, "peixiu", "qun", 3)
peixiu.subkingdom = "jin"
peixiu:addSkills { "xingtu", "juezhi"}
Fk:loadTranslationTable{
  ["peixiu"] = "裴秀",
  ["#peixiu"] = "晋图开秘",
  ["designer:peixiu"] = "Loun老萌",
  ["illustrator:peixiu"] = "鬼画府",

  ["~peixiu"] = "既食寒石散，便不可饮冷酒啊……",
}

General:new(extension, "yangfu", "wei", 3):addSkills { "jiebing", "hannan" }
Fk:loadTranslationTable{
  ["yangfu"] = "杨阜",
  ["#yangfu"] = "勇撼雄狮",
  ["illustrator:yangfu"] = "铁杵文化",

  ["~yangfu"] = "汝背父叛君，吾誓，杀……",
}

General:new(extension, "mobile__liwei", "shu", 4):addSkills { "mobile__jiaohua" }
Fk:loadTranslationTable{
  ["mobile__liwei"] = "李遗",
  ["#mobile__liwei"] = "伏被俞元",
  ["illustrator:mobile__liwei"] = "君桓文化",

  ["~mobile__liwei"] = "安南重任，万不可轻之……",
}

--SP14：吴班 鲍信 胡班 陈珪 霍峻 木鹿大王 蒋干 杨奉 来敏
General:new(extension, "mobile__baoxin", "qun", 4):addSkills { "mobile__mutao", "mobile__yimou" }
Fk:loadTranslationTable{
  ["mobile__baoxin"] = "鲍信",
  ["#mobile__baoxin"] = "坚朴的忠相",
  ["illustrator:mobile__baoxin"] = "凡果",
  ["designer:mobile__baoxin"] = "jcj熊",

  ["~mobile__baoxin"] = "区区黄巾流寇，如何挡我？呃啊……",
}

General:new(extension, "mobile__huban", "wei", 4):addSkills { "mobile__yilie" }
Fk:loadTranslationTable{
  ["mobile__huban"] = "胡班",
  ["#mobile__huban"] = "昭义烈勇",
  ["illustrator:mobile__huban"] = "铁杵文化",

  ["~mobile__huban"] = "生虽微而志不可改，位虽卑而节不可夺……",
}

--General:new(extension, "mobile__chengui", "qun", 3):addSkills { "guimou", "zhouxian" }
Fk:loadTranslationTable{
  ["mobile__chengui"] = "陈珪",
  ["#mobile__chengui"] = "弄辞巧掇",
  ["illustrator:mobile__chengui"] = "凝聚永恒",

  ["~mobile__chengui"] = "布非忠良之士，将军宜早图之……",
}

--General:new(extension, "mobile__huojun", "shu", 4):addSkills { "mobile__sidai", "mobile__jieyu" }
Fk:loadTranslationTable{
  ["mobile__huojun"] = "霍峻",
  ["#mobile__huojun"] = "葭萌铁狮",
  ["illustrator:mobile__huojun"] = "枭瞳",
  ["designer:mobile__huojun"] = "步穗",

  ["~mobile__huojun"] = "恨，不能与使君共成霸业……",
}

local muludawang = General:new(extension, "muludawang", "qun", 3)
muludawang:addSkills { "shoufa", "zhoulin", "yuxiang" }
muludawang.shield = 1
Fk:loadTranslationTable{
  ["muludawang"] = "木鹿大王",
  ["#muludawang"] = "八纳洞主",
  ["illustrator:muludawang"] = "三道纹",

  ["~muludawang"] = "啊啊，诸葛亮神人降世，吾等难挡天威。",
}

--General:new(extension, "mobile__jianggan", "wei", 3):addSkills { "mobile__daoshu", "daizui" }
Fk:loadTranslationTable{
  ["mobile__jianggan"] = "蒋干",
  ["#mobile__jianggan"] = "虚义伪诚",
  ["illustrator:mobile__jianggan"] = "鬼画府",

  ["~mobile__jianggan"] = "唉，假信害我不浅啊……",
}

--General:new(extension, "yangfeng", "qun", 4):addSkills { "xuetu", "weiming" }
Fk:loadTranslationTable{
  ["yangfeng"] = "杨奉",
  ["#yangfeng"] = "忠勇半途",
  ["illustrator:yangfeng"] = "铁杵文化",

  ["~yangfeng"] = "刘备！本共图吕布，何设鸿门相欺！",
}

General:new(extension, "laimin", "shu", 3):addSkills { "laishou", "luanqun" }
Fk:loadTranslationTable{
  ["laimin"] = "来敏",
  ["#laimin"] = "悖骴乱群",
  ["illustrator:laimin"] = "错落宇宙",

  ["~laimin"] = "狂嚣之言，一言十过啊……",
}

--未分组：SP甄姬 甘夫人 王经
General:new(extension, "m_sp__zhenji", "qun", 3, 3, General.Female):addSkills { "bojian", "jiwei" }
Fk:loadTranslationTable{
  ["m_sp__zhenji"] = "甄姬",
  ["#m_sp__zhenji"] = "明珠锦玉",
  ["illustrator:m_sp__zhenji"] = "铁杵",

  ["~m_sp__zhenji"] = "悔入帝王家，万愿皆成空……",
  ["!m_sp__zhenji"] = "昔见百姓十室九空，更惜今日安居乐业。",
}

General:new(extension, "mobile__ganfuren", "shu", 3, 3, General.Female):addSkills { "zhijie", "mobile__shushen" }
Fk:loadTranslationTable{
  ["mobile__ganfuren"] = "甘夫人",
  ["#mobile__ganfuren"] = "昭烈皇后",
  --["illustrator:mobile__ganfuren"] = "",

  ["~mobile__ganfuren"] = "只愿夫君，大事可成，兴汉有期……",
}

General:new(extension, "wangjing", "wei", 3):addSkills { "zujin", "jiejianw" }
Fk:loadTranslationTable{
  ["wangjing"] = "王经",
  ["#wangjing"] = "青云孤竹",
  ["illustrator:wangjing"] = "凝聚永恒",

  ["~wangjing"] = "有母此言，经死之无悔。",
}

return extension
