#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""修复 c2s.sproto 文件中的语法错误"""

with open('c2s.sproto', 'r', encoding='utf-8') as f:
    content = f.read()

# 修复问题1: \n" str = str .. " 在 CompTrialTroop 后
old1 = '''.CompTrialTroop {
        type 1: uint32
        army 19: *ComArmyIdAndNum()
        heros 17: *uint32
        targetX 15: uint32
        targetY 16: uint32
    }

\n"
    str = str .. "

.ComMileStoneData {'''

new1 = '''.CompTrialTroop {
        type 1: uint32
        army 19: *ComArmyIdAndNum()
        heros 17: *uint32
        targetX 15: uint32
        targetY 16: uint32
    }

.ComMileStoneData {'''

content = content.replace(old1, new1)

# 修复问题2: genClientQueryRspSproto.lua 脚本残留
old2 = '''# === genClientQueryRspSproto.lua ===
\n"
    str = str .. "

# === loginproto.lua ==='''

new2 = '''# === genClientQueryRspSproto.lua ===

# === loginproto.lua ==='''

content = content.replace(old2, new2)

with open('c2s.sproto', 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed c2s.sproto successfully')
