#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
修复损坏的 sproto 文件，移除错误的 Lua 代码部分
"""
import os


def fix_sproto_file(input_file):
    """
    修复损坏的 sproto 文件
    :param input_file: 输入文件路径
    """
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # 找到第一个包含错误 Lua 代码的行
    # 错误模式：]] 或 C2S.c2s = 或 S2C.s2c =
    error_patterns = [']]', 'C2S.c2s =', 'S2C.s2c =']
    
    error_line = None
    for i, line in enumerate(lines):
        for pattern in error_patterns:
            if pattern in line:
                error_line = i
                break
        if error_line:
            break
    
    if error_line is not None:
        print(f"在第 {error_line + 1} 行发现错误代码，截断文件")
        # 截断到错误行之前
        lines = lines[:error_line]
        
        # 清理末尾的空行
        while lines and lines[-1].strip() == '':
            lines.pop()
        
        # 写回文件
        with open(input_file, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        
        print(f"文件已修复，保留 {len(lines)} 行")
    else:
        print("文件没有发现错误")


if __name__ == '__main__':
    fix_sproto_file(r'E:\TreaCN\Projects\PressureTest_lihusheng_test2\pythonTest1\sprotoGen\sproto\src\c2s.sproto')
