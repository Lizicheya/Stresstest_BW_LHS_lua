#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""修复 s2c.sproto 文件中的语法错误"""

with open('s2c.sproto', 'r', encoding='utf-8') as f:
    content = f.read()

start = content.find('# === genClientQueryRspSproto.lua ===')
end = content.find('# === loginproto.lua ===')

if start != -1 and end != -1:
    new_content = content[:start] + '# === genClientQueryRspSproto.lua ===\n\n' + content[end:]
    with open('s2c.sproto', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f'Fixed successfully, removed {end-start} characters')
else:
    print('Could not find the markers')
