#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
修复 sproto 文件中的脚本生成错误残留
"""
import re


def fix_sproto_file(file_path):
    """
    修复 sproto 文件中的脚本生成错误残留
    :param file_path: 文件路径
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 修复脚本生成错误残留
    # 模式1: \n" 后跟换行和空格和 str = str .. "
    pattern1 = r'\n"\s*\n\s*str = str \.\. "'
    content = re.sub(pattern1, '', content)
    
    # 模式2: 单独的 \n"
    pattern2 = r'\n"\s*'
    content = re.sub(pattern2, '\n', content)
    
    # 模式3: 单独的 str = str .. "
    pattern3 = r'\s*str = str \.\. "\s*'
    content = re.sub(pattern3, '', content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"已修复 {file_path}")


if __name__ == '__main__':
    fix_sproto_file(r'E:\TreaCN\Projects\协议整合和转换\sprotorpc\c2s.sproto')
    fix_sproto_file(r'E:\TreaCN\Projects\协议整合和转换\sprotorpc\s2c.sproto')
    print("\n修复完成！")
