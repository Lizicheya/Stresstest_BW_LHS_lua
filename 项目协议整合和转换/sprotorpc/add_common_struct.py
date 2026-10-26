#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
将 commonStruct.lua 中的类型定义添加到 c2s.sproto 和 s2c.sproto 文件中
"""
import re


def extract_common_struct(common_file):
    """
    从 commonStruct.lua 中提取类型定义
    :param common_file: commonStruct.lua 文件路径
    :return: 类型定义内容
    """
    with open(common_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 提取 [[...]] 中的内容
    pattern = r'\[\[([\s\S]*?)\]\]'
    match = re.search(pattern, content)
    if match:
        return match.group(1).strip()
    return ""


def add_struct_to_sproto(sproto_file, struct_content):
    """
    将类型定义添加到 sproto 文件中（在 .package 之后）
    :param sproto_file: sproto 文件路径
    :param struct_content: 要添加的类型定义内容
    """
    with open(sproto_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 在 .package 块之后插入类型定义
    package_end_pattern = r'(\.package\s*\{[^}]*\})\s*'
    replacement = r'\1\n\n' + struct_content + '\n\n'
    
    new_content = re.sub(package_end_pattern, replacement, content)
    
    with open(sproto_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"已将 commonStruct 添加到 {sproto_file}")


if __name__ == '__main__':
    common_file = r'E:\TreaCN\Projects\协议整合和转换\sprotorpc\sproto\game\commonStruct.lua'
    c2s_file = r'E:\TreaCN\Projects\协议整合和转换\sprotorpc\c2s.sproto'
    s2c_file = r'E:\TreaCN\Projects\协议整合和转换\sprotorpc\s2c.sproto'
    
    # 提取类型定义
    struct_content = extract_common_struct(common_file)
    print(f"提取到 {len(struct_content.splitlines())} 行类型定义")
    
    # 添加到 c2s.sproto
    add_struct_to_sproto(c2s_file, struct_content)
    
    # 添加到 s2c.sproto
    add_struct_to_sproto(s2c_file, struct_content)
    
    print("\n完成！")
