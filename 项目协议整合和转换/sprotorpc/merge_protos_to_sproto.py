#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
合并 sprotorpc 目录下的所有协议文件到 sproto 格式
- 将所有 c2s（客户端到服务端）协议合并到 c2s.sproto
- 将所有 s2c（服务端到客户端）协议合并到 s2c.sproto
- 类型定义（如 .ComBuild）在两个文件中都包含
"""
import os
import re


def extract_struct(content):
    """
    从协议文件中提取 struct 定义部分
    :param content: 文件内容
    :return: struct 内容列表
    """
    structs = []
    
    # 匹配格式1: struct = [[...]]
    pattern1 = r'struct\s*=\s*\[\[([\s\S]*?)\]\]'
    match = re.search(pattern1, content)
    if match:
        struct_content = match.group(1).strip()
        if struct_content:
            structs.append(struct_content)
    
    # 匹配格式2: local common = [[...]] (commonStruct.lua)
    pattern2 = r'local\s+common\s*=\s*\[\[([\s\S]*?)\]\]'
    match = re.search(pattern2, content)
    if match:
        struct_content = match.group(1).strip()
        if struct_content:
            structs.append(struct_content)
    
    # 匹配格式3: local proto = [[...]] (其他纯定义文件)
    pattern3 = r'local\s+proto\s*=\s*\[\[([\s\S]*?)\]\]'
    match = re.search(pattern3, content)
    if match:
        struct_content = match.group(1).strip()
        if struct_content:
            structs.append(struct_content)
    
    return structs


def extract_proto_section(content, section_name):
    """
    从协议文件中提取指定的部分（c2s 或 s2c）
    支持两种格式：
    1. section_name = variable.struct .. [[...]]
    2. section_name = [[...]]
    :param content: 文件内容
    :param section_name: 'c2s' 或 's2c'
    :return: 提取的协议内容（不包含 struct 部分）
    """
    # 模式1：带 struct 拼接的格式，需要提取 [[...]] 中的内容
    pattern1 = rf'{section_name}\s*=\s*[a-zA-Z0-9_]+\.struct\s*\.\.\s*\[\[([\s\S]*?)\]\]'
    match = re.search(pattern1, content)
    if match:
        return match.group(1).strip()
    
    # 模式2：不带 struct 的格式
    pattern2 = rf'{section_name}\s*=\s*\[\[([\s\S]*?)\]\]'
    match = re.search(pattern2, content)
    if match:
        return match.group(1).strip()
    
    return ""


def find_proto_files(base_path):
    """
    查找所有协议文件（排除 luadoc 目录和 .meta 文件）
    :param base_path: 基础路径
    :return: 文件路径列表
    """
    proto_files = []
    
    for root, dirs, files in os.walk(base_path):
        # 排除 luadoc 目录
        dirs[:] = [d for d in dirs if d != 'luadoc']
        
        for file in files:
            if file.endswith('.lua') and not file.endswith('.meta') and file != 'readme.lua':
                full_path = os.path.join(root, file)
                proto_files.append(full_path)
    
    proto_files.sort()
    return proto_files


def merge_protos(input_dir, output_dir):
    """
    合并所有协议文件
    :param input_dir: 输入目录
    :param output_dir: 输出目录
    """
    print(f"开始合并协议文件，输入目录: {input_dir}")
    
    # 查找所有协议文件
    proto_files = find_proto_files(input_dir)
    print(f"找到 {len(proto_files)} 个协议文件")
    
    # 收集所有 struct、c2s、s2c
    all_structs = set()
    all_c2s = []
    all_s2c = []
    
    for file_path in proto_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            file_name = os.path.basename(file_path)
            
            # 提取 struct 定义
            structs = extract_struct(content)
            for s in structs:
                all_structs.add(s)
            
            # 提取 c2s 部分
            c2s_content = extract_proto_section(content, 'c2s')
            if c2s_content:
                all_c2s.append(f"# === {file_name} ===\n{c2s_content}")
            
            # 提取 s2c 部分
            s2c_content = extract_proto_section(content, 's2c')
            if s2c_content:
                all_s2c.append(f"# === {file_name} ===\n{s2c_content}")
        
        except Exception as e:
            print(f"处理文件 {file_path} 时出错: {e}")
    
    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)
    
    # 生成 c2s.sproto
    c2s_output = os.path.join(output_dir, 'c2s.sproto')
    with open(c2s_output, 'w', encoding='utf-8') as f:
        # 添加 package 定义
        f.write(".package {\n")
        f.write("    type 0 : integer            # 协议类型\n")
        f.write("    session 1: integer          # client server 各维护一套自增的id\n")
        f.write("    ud 2 : integer              # response:用于错误码;推送:用户包确认\n")
        f.write("}\n\n")
        
        # 添加所有 struct 定义
        for struct_def in all_structs:
            f.write(struct_def)
            f.write("\n\n")
        
        # 添加所有 c2s 协议
        f.write("\n\n".join(all_c2s))
        f.write("\n")
    
    print(f"c2s.sproto 已生成，包含 {len(all_structs)} 个 struct 定义，{len(all_c2s)} 个 c2s 协议")
    
    # 生成 s2c.sproto
    s2c_output = os.path.join(output_dir, 's2c.sproto')
    with open(s2c_output, 'w', encoding='utf-8') as f:
        # 添加 package 定义
        f.write(".package {\n")
        f.write("    type 0 : integer            # 协议类型\n")
        f.write("    session 1: integer          # client server 各维护一套自增的id\n")
        f.write("    ud 2 : integer              # response:用于错误码;推送:用户包确认\n")
        f.write("}\n\n")
        
        # 添加所有 struct 定义
        for struct_def in all_structs:
            f.write(struct_def)
            f.write("\n\n")
        
        # 添加所有 s2c 协议
        f.write("\n\n".join(all_s2c))
        f.write("\n")
    
    print(f"s2c.sproto 已生成，包含 {len(all_structs)} 个 struct 定义，{len(all_s2c)} 个 s2c 协议")
    
    print("\n合并完成！")
    print(f"c2s.sproto 路径: {c2s_output}")
    print(f"s2c.sproto 路径: {s2c_output}")


if __name__ == '__main__':
    # 输入目录：sproto 目录
    input_directory = r'E:\TreaCN\Projects\协议整合和转换\sprotorpc\sproto'
    
    # 输出目录：当前目录（sprotorpc 根目录）
    output_directory = r'E:\TreaCN\Projects\协议整合和转换\sprotorpc'
    
    merge_protos(input_directory, output_directory)
