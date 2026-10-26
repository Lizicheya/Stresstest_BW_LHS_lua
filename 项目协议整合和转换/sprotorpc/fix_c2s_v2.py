#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""修复 c2s.sproto 文件中的语法错误"""

with open('c2s.sproto', 'r', encoding='utf-8') as f:
    content = f.read()

import re

# 修复问题1: \n" str = str .. " 模式（在任何地方出现）
pattern1 = r'\n\\n"\s*\n\s*str\s*=\s*str\s*\.\.\s*"\n'
content = re.sub(pattern1, '\n\n', content)

# 修复问题2: 删除 genClientQueryRspSproto.lua 的脚本残留
old_marker = '# === genClientQueryRspSproto.lua ===\n\\n"\n    str = str .. "\n\n# === loginproto.lua ==='
new_marker = '# === genClientQueryRspSproto.lua ===\n\n# === loginproto.lua ==='
content = content.replace(old_marker, new_marker)

with open('c2s.sproto', 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed c2s.sproto successfully')
