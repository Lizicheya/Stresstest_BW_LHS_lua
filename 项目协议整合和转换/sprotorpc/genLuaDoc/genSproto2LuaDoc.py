## -------------------------------
## @author: chenjinjie
## @date: 2025-01-25 
## @introduce  : 用于解析 sproto 文件，生成 luadoc 文档
## --------------------------------
import re
import os
import sys
import json
from typing import Union, Literal

"""
README:
    1. 本脚本用于解析 sproto 文件，生成 luadoc 文档
    2. 启动脚本参数为文件夹路径，读取文件夹下（不递归子文件夹！）所有 sproto 文件，生成对应的 luadoc 文件
    3. 【已优化】
    4. 生成的 luadoc 描述文件，放在文件夹下的 luadoc 文件夹中，文件名为 doc_XXXProto.lua，额外多生成 doc_globalStructs.json 输出结构体定义、 doc_globalProtoCol.json 输出协议定义、doc_globalKvMapStructs 输出 key value 类型的结构
    5. 解析 sproto 文件深度优先，所以数据的类型(field 的 type)一定要先定义，再使用
    6. 不要在协议中定义结构
        6.1 就是不要在 c2s 或是 s2c 使用 .xxx 定义结构
        6.2 sproto 的规范是可以的，但是这个脚本不支持，因为项目中基本没这么用，图省点事了 
"""

"""
目前项目中使用 sproto 协议的参数类型定义中，转成 luadoc 的时候，实际清晰的就是
    1. string
    2. integer
    3. double
    4. boolean
    5. struct
对于 sproto 中，还有一些特殊的类型，就是使用了 * 号开头的，比如数组（和简单类型在一起比较好理解）
    6. *integer = integer[] 或是 *struct = struct[]    
但是还有一种情况，就是 *struct() 或是 *struct(key_type) 这种情况（就是 *struct+括号），这种情况就是 map 类型，这边有两种解析，
    当只有两个成员 且只有 {
        "key": "key_type",
        "value": "value_type"
    }，这种时候就是个简单 map
对于简单 map，就是 key-value 型的，比如 *struct()，这种情况，我们可以直接生成一个别名，比如 *struct() = {GLOBAL_SPROTO_MAP_PREFIX}struct
    7. *struct() = {GLOBAL_SPROTO_MAP_PREFIX}struct #（只有 key、value的简单map）
对于复杂 map，就是有多个 feild 的，首先要明确， default key 是第一个字段，此外还可以指定做 key 的字段，所以要记录下每个 key 的类型，准备找到做 key 的类型用
    8. *struct() = table<default_key_type, struct>
    9. *struct(key_type) = table<key_type, struct>
"""

##########################################################################################################
def capitalizeFirst(s):
    """首字母大写"""
    return s[0].upper() + s[1:] if s else s

def genDict2JsonStr(data, label=""):
    return json.dumps(data, indent=4, ensure_ascii=False)
# end for genDict2JsonStr

# 返回一个空的结构体，所有结构都是这个 struct:
def getEmptyStruct():
    return {
        "originName": "",
        "onlyName": "",
        "notPrefixOnlyName": "", # 不带统一前缀的唯一名字，用于生成别名
        "fields": [],
        "subStructs": {},
    }
# end for getEmptyStruct

# 保存一个字段到结构体中
def saveField2GlobalStructMap(arrVisitStep, field):
    if len(arrVisitStep) == 0: # 保存 field 必须是要进入了结构体中
        print(f"Error: saveField2GlobalStructMap arrVisitStep: {arrVisitStep} not found")
        sys.exit(1)

    visitStruct = GLOBAL_STRUCTS_MAP
    for step in arrVisitStep:
        visitStruct = visitStruct['subStructs'][step]
        if visitStruct is None:
            print(f"Error: saveField2GlobalStructMap arrVisitStep: {arrVisitStep}, step: {step} not found")
            sys.exit(1)    
    visitStruct['fields'].append(field)
# end for saveField2GlobalStructMap

# 保存一个结构体定义到全局结构体中
def saveStruct2GlobalStructMap(arrVisitStep, name, struct):
    visitStruct = GLOBAL_STRUCTS_MAP
    for step in arrVisitStep:
        visitStruct = visitStruct['subStructs'][step]
        if visitStruct is None:
            print(f"Error: saveStruct2GlobalStructMap arrVisitStep: {arrVisitStep}, step: {step} not found")
            sys.exit(1) # 这里应该是直接退出，因为这个是必须要找到的，不然后续的处理都会有问题

    visitStruct['subStructs'][f"{name}"] = struct
# end for saveStruct2GlobalStructMap

# 从全局结构体中获取一个结构体定义
def getStruct4GlobalStructMap(arrVisitStep):
    if len(arrVisitStep) == 0:
        print(f"Error: getStruct4GlobalStructMap arrVisitStep: {arrVisitStep} not found")
        sys.exit(1) # 这里应该是直接退出，因为这个是必须要找到的，不然后续的处理都会有问题

    visitStruct = GLOBAL_STRUCTS_MAP
    for step in arrVisitStep:
        visitStruct = visitStruct['subStructs'][step]
        if visitStruct is None:
            print(f"Error: getStruct4GlobalStructMap arrVisitStep: {arrVisitStep}, step: {step} not found")
            sys.exit(1)

    return visitStruct
# end for getStruct4GlobalStructMap

# 存在嵌套定义结构体的时候，结构体可能名字重复，从最外层开始一步步进来，拼接出唯一名字,类似 xxx_yyy_zzz
def genStructOnlyName(arrVisitStep, structName):    
    tmpArrVisitStep = []
    for step in arrVisitStep:
        tmpArrVisitStep.append(capitalizeFirst(step))
    tmpStructName = capitalizeFirst(structName)

    newStructOnlyName = None
    if len(tmpArrVisitStep) == 0:
        newStructOnlyName = tmpStructName
    else:
        newStructOnlyName =  ''.join(tmpArrVisitStep) + '' + tmpStructName
    return f"{GLOBAL_SPROTO_PREFIX}{newStructOnlyName}", newStructOnlyName

# end for genStructOnlyName

# 存在嵌套定义结构体的时候，结构体可能名字重复，从最外层开始一步步进来，找到最近的定义，最为最终的类型
def getStructOnlyName(arrVisitStep, structName):
    struct = GLOBAL_STRUCTS_MAP['subStructs'].get(structName) # 首先从全局可见中找这个定义，因为可能是基础结构或是全局可见的结构
    # print(f"getStructOnlyName arrVisitStep: {arrVisitStep}, structName: {structName}, struct: {struct}")

    visitStruct = GLOBAL_STRUCTS_MAP # 接下来，按照遍历顺序，一层层遍历进去，找到最近的同名定义，作为最终定义
    for step in arrVisitStep:
        visitStruct = visitStruct['subStructs'][step]
        if visitStruct is None:
            print(f"Error: saveStruct2GlobalStructMap arrVisitStep: {arrVisitStep}, step: {step} not found")
            sys.exit(1) # 这里应该是直接退出，因为这个是必须要找到的，不然后续的处理都会有问题
        tmpStruct = visitStruct['subStructs'].get(structName)
        if tmpStruct is not None: # 找到更接近的同名定义，更新
            struct = tmpStruct
        
    if struct is None:
        print(f"Error: getStructOnlyName arrVisitStep: {arrVisitStep}, structName: {structName} not found")
        sys.exit(1)
    return struct['onlyName']
# end for getStructOnlyName

##########################################################################################################

### 全局定义
# 记录所有结构体的定义，多层map
# {
#     "originName": "originName",   # 原始名字,就是 sproto 定义中取的名字，因为嵌套定义，可能会重复
#     "onlyName": "structonlyName", # 标识的结构体名字，会处理嵌套定义，变成 xxx_yyy_zzz 这样的嵌套
#     "fields": [
#         {
#             "name": "fieldName",
#             "type": "fieldType",
#             "comment": "fieldComment"
#         }
#     ],
#     "subStructs": {
#         "typeName": {#struct#}, # 递归的 struct，这个 name 就是 sproto 文件中直接定义的名字，
#      },
# }
GLOBAL_STRUCTS_MAP = getEmptyStruct()
GLOBAL_BASE_TYPE_MAP = { # sproto => lua
    'integer': 'integer',
    'string': 'string',
    'boolean': 'boolean',
    'double': 'number',
    'uint32': 'integer',
    'uint64': 'number',
}
GLOBAL_COMMOM_STRUCTS_FILE_NAME = 'commonStruct.lua'
GLOBAL_ALLIANCE_INFOPROTO_FILE_NAME = 'allianceInfoProto.lua'
GLOBAL_PLAYER_INFOPROTO_FILE_NAME = 'playerInfoProto.lua'

GLOBAL_LUA_TYPE_TABLE_KEY_SET = { # lua转到 lua 的实际类型后，可以作为 table key 的类型
    'integer': 1,
    'number': 1,
    'string': 1,
}

# 记录每个结构体的字段类型,一维 map
# {
#   XXX_default: 'integer',
#   XXX_id: 'integer',
#   XXX_name: 'integer',
#   ...
# }
GLOBAL_STRUCTS_FIELD_TYPE_MAP = {} # 记录每个结构体的字段类型，方便后续生成别名 { , XXX_id: 'integer', XXX_name: 'string' } 
GLOBAL_STRUCTS_FIELD_DEFAULT_KEY_PREFIX = "_default"

GLOBAL_ONLY_GEN_JSON_4_DEBUG = False # 是否只生成 json 文件,方便调试先看解析 sproto 文件是否正确

GLOBAL_PROTO_COL_MAP = {}

GLOBAl_KV_MAP_STRUCT = {} # 记录所有生成了 kv map 别名的结构体

GLOBAL_SPROTO_PREFIX = 'SP' # 由这个脚本生成 class 和 alias 的时候，统一加上的前缀, SP 代表 sproto

GLOBAL_SPROTO_MAP_PREFIX = 'KvMap_'
##########################################################################################################

# 解析协议定义
# 返回一个数组
# [
#   {
#     'name': 'XXX',
#     'id': '1001',
#     'request': {
#       'fields': [
#         {'name': 'field1', 'type': 'integer', 'comment': '...'},
#         {'name': 'field2', 'type': 'string', 'comment': '...'},
#       ]
#     },
#     'response': {
#       'fields': [
#         {'name': 'field1', 'type': 'integer', 'comment': '...'},
#         {'name': 'field2', 'type': 'string', 'comment': '...'},
#       ]
#     }
#   }
# ]
def parseProtocol(content: str, inputFileName: str, msgForward: Union[Literal["s2c"], Literal["c2s"]]):
    protocols = []
    currentProto = None
    currentSection = None
    braceCount = 0
    
    lines = content.splitlines()
    for i in range(len(lines)):
        line = lines[i].strip()

        if not line or line.startswith('#'): # 空行或者注释行，跳过
            continue
        if line.startswith('.'): # 不要在 request/response 中再定义结构了！
            print(f"Error: invalid line: {line}")
            sys.exit(1)

        # 处理注释
        comment = ''
        if '#' in line: # 本行就有注释的
            parts = line.split('#', 1)
            comment = parts[1].strip()
        else:            
            if i > 0:
                lastLine = lines[i - 1].strip()
                if lastLine.startswith('#'): # 本行没有注释，但是上一行是注释的
                    comment = lastLine[1:]
            
        # 计算大括号
        braceCount += line.count('{') - line.count('}')

        # 匹配协议定义
        proto_match = re.match(r'(\w+)\s+(\d+)\s*{', line)
        if proto_match:
            proto_name = proto_match.group(1)
            proto_id = proto_match.group(2)
            currentProto = {
                'name': proto_name,
                'fileName': inputFileName,
                'comment': comment,
                'msgForward': msgForward,
                'id': proto_id,
                'request': {'fields': [], 'requestOnlyName': ''},
                'response': {'fields': [], 'requestOnlyName': ''},
            }
            protocols.append(currentProto)
            continue
            
        # 解析request/response字段
        if currentProto:
            if 'request {' in line:
                currentSection = currentProto['request']
            elif 'response {' in line:
                currentSection = currentProto['response']
            # 大括号闭合时重置section
            elif braceCount == 0:
                currentSection = None
            # 解析字段
            elif currentSection is not None:
                field = parseField(line, []) # 协议定义的类型，必须是要在全局可见的类型中的
                if field:
                    currentSection['fields'].append(field)
    
    for protoCol in protocols:
        GLOBAL_PROTO_COL_MAP[protoCol['id']] = protoCol
    return protocols
#end for parseProtocol

def generateProtocolLuadoc(protocols):
    result = []
    for proto in protocols:
        # 生成Request类型
        protoName = proto['name']
        protoId = proto['id']
        capProtoName = capitalizeFirst(protoName) # 首字母大写

        # Request
        requestOnlyName = f"{capProtoName}Request"
        proto['request']['requestOnlyName'] = requestOnlyName

        if proto['comment']: # 协议注释在 request 上有即可
            result.append(f"--- {protoName}: {protoId} {proto['comment']}")
        else:
            result.append(f"--- {protoName}: {protoId}")

        result.append(f"---@class {requestOnlyName}")
        for field in proto['request']['fields']:
            fieldName = field['name']
            fieldType = field['type']
            comment = f" {field['comment']}" if field['comment'] else ''

            fieldType = convertType(fieldType)                
            result.append(f"---@field {fieldName} {fieldType}{comment}")

            field['convertToType'] = fieldType
        result.append('')

        # 生成一个 request 的别名，兼容客户端旧的注解
        result.append(f"---@alias {protoName}.request {requestOnlyName}")
        result.append('')
            
        # 生成Response类型
        responseOnlyName = f"{capProtoName}Response"
        proto['response']['requestOnlyName'] = responseOnlyName

        result.append(f"--- {protoName}: {protoId}")
        result.append(f"---@class {responseOnlyName}")
        for field in proto['response']['fields']:
            fieldName = field['name']
            fieldType = field['type']
            comment = f" {field['comment']}" if field['comment'] else ''

            fieldType = convertType(fieldType)
            result.append(f"---@field {fieldName} {fieldType}{comment}")

            field['convertToType'] = fieldType
        result.append('')

        # 生成一个 request 的别名，兼容客户端旧的注解
        result.append(f"---@alias {protoName}.response {responseOnlyName}")
        result.append('')
    
    return '\n'.join(result)
# end for generateProtocolLuadoc

# 解析协议
def cacheProrocolDefine(inputPath, inputFileName):
    with open(inputPath, 'r') as f:
        content = f.read()
    
    c2sProtoDoc = ''
    s2cProtoDoc = ''

    # 提取c2s定义部分    
    c2sMatch = re.search(r'c2s\s*=.*?\[\[(.*?)\]\]', content, re.DOTALL)
    if c2sMatch:
        c2sContent = c2sMatch.group(1)
        c2sProtocols = parseProtocol(c2sContent, inputFileName, "c2s")
        if not GLOBAL_ONLY_GEN_JSON_4_DEBUG:
            c2sProtoDoc = generateProtocolLuadoc(c2sProtocols)
            
    # 提取s2c定义部分
    s2cMatch = re.search(r's2c\s*=.*?\[\[(.*?)\]\]', content, re.DOTALL)
    if s2cMatch:
        s2cContent = s2cMatch.group(1)
        s2cProtocols = parseProtocol(s2cContent, inputFileName, "s2c")
        if not GLOBAL_ONLY_GEN_JSON_4_DEBUG:
            s2cProtoDoc = generateProtocolLuadoc(s2cProtocols)
        

    return c2sProtoDoc, s2cProtoDoc
# end for cacheProrocolDefine

##########################################################################################################

# 从 sproto 文件中提取 struct 内容
def getStructContent(inputPath, content):
    structContent = ''
    # 特殊处理commonStruct.lua
    if GLOBAL_COMMOM_STRUCTS_FILE_NAME in inputPath:
        # 直接提取[[]]中的内容
        match = re.search(r'\[\[(.*?)\]\]', content, re.DOTALL)
        if match:
            structContent = match.group(1)
    else:
        # 提取struct定义部分
        structMatch = re.search(r'struct\s*=\s*\[\[(.*?)\]\]', content, re.DOTALL)
        if structMatch:
            structContent = structMatch.group(1)
    
    return structContent
# end for getStructContent

def getTypeBase(typeStr):
    # typeStr 的内容可能是
    # 1. xxx
    # 2. *xxx
    # 3. *xxx()
    # 4. *xxx(key_type)
    # 需要提取出xxx

    # 移除前导*号
    if typeStr.startswith('*'):
        typeStr = typeStr[1:]
    # 处理带括号的情况
    if '(' in typeStr:
        typeStr = typeStr.split('(')[0]
    return typeStr
#end for getTypeBase

# 解析 sproto 字段定义, 获得字段的 name、类型、注释
def parseField(line, arrVisitStep):
    pattern = r'(\w+)\s+(\d+)\s*:\s*([^#]+)(?:#\s*(.+))?'
    match = re.match(pattern, line.strip())
    if not match:
        return None

    name = match.group(1)
    typeStr = match.group(3).strip()
    comment = match.group(4).strip() if match.group(4) else ''
    
    typeStrBase = getTypeBase(typeStr)            
    translateType = getStructOnlyName(arrVisitStep, typeStrBase)
    # print(f"parseField: name: {name}, typeStr: {typeStr}, typeStrBase: {typeStrBase}, translateType: {translateType}")
    typeStr = typeStr.replace(typeStrBase, translateType) # 转化为正确的 onlyName

    return {
        'name': name,
        'type': typeStr,
        'comment': comment,
        'convertToType': '', # 最后生成 luadoc 的时候，转换后的类型
    }
# end for parseField

def convertType(sprotoType):
    """
        将字符串的类型 sprotoType 转换为 luadoc 中的实际类型
        就是解析 数组、结构体、map 这些类型
    """
    if sprotoType.startswith('*'): # 数组或是结构体
        baseType = sprotoType[1:] # 去掉*
        if '(' not in baseType: # 数组: 就是 *XXX 不带括号的
            return f'{baseType}[]'
        else:
            # 结构体 *XXX() 或 *XXX(YYY)
            baseType = baseType.split('(')[0]
            paramMatch = re.search(r'\((\w+)\)', sprotoType) # 提取括号中的参数
            if not paramMatch: # *XXX(),括号中没有指定key的时候，要考虑是不是复杂 map，使用 第一个 field 做默认 key 的
                isKvMap = GLOBAl_KV_MAP_STRUCT.get(baseType)
                if isKvMap is not None:
                    return f'{GLOBAL_SPROTO_MAP_PREFIX}{baseType}'
                else:
                    defaultKeyType = GLOBAL_STRUCTS_FIELD_TYPE_MAP.get(f"{baseType}{GLOBAL_STRUCTS_FIELD_DEFAULT_KEY_PREFIX}")
                    if defaultKeyType is None:
                        print(f"Error: convertType defaultKeyType not found: {baseType}{GLOBAL_STRUCTS_FIELD_DEFAULT_KEY_PREFIX}")
                        sys.exit(1)
                    return f'table<{defaultKeyType}, {baseType}>'    

                # keyType = GLOBAL_STRUCTS_FIELD_TYPE_MAP.get(f"{baseType}{GLOBAL_STRUCTS_FIELD_DEFAULT_KEY_PREFIX}")
                # if keyType is None:
                #     # 为空 说明应该是 key-value 的简单 map
                #     return f'{GLOBAL_SPROTO_MAP_PREFIX}{baseType}'
                # else:
                #     # 不为空，说明是复杂 map，用默认的第一个 field 做 key 的情况
                #     return f'table<{keyType}, {baseType}>'
            else:
                # *XXX(YYY),括号中指定了 key 的类型
                keyFieldName = paramMatch.group(1)
                keyType = GLOBAL_STRUCTS_FIELD_TYPE_MAP.get(f"{baseType}_{keyFieldName}")
                if keyType is None:
                    print(f"Error: convertType keyType not found: {baseType}_{keyFieldName}")
                    sys.exit(1)                    
                return f'table<{keyType}, {baseType}>'

    else:
        return sprotoType
#end for convertType

# 完成一个结构体的解析了，准备生成这个结构体的 luadoc 定义了
def finishOneStruct(visitStep):
    struct = getStruct4GlobalStructMap(visitStep)
    print(f"finishOneStruct: {struct['onlyName']}")

    structOriginName = struct['originName']
    structOnlyName = struct['onlyName']
    notPrefixtructOnlyName = struct['notPrefixOnlyName']
    fields = struct['fields']
    result = []

    # 普通结构体使用@class
    result.append(f'--- .{structOriginName}')
    result.append(f'---@class {structOnlyName}')
    for field in fields:
        fKey = field["name"]
        fType = field["type"]
        fComment = f' {field["comment"]}' if field["comment"] else ''

        fType = convertType(fType)
        result.append(f'---@field {fKey} {fType}{fComment}')

        field['convertToType'] = fType
    
    # 多生成一个别名，因为客户端也已经有一些注解定义了，是不带统一前缀的
    result.append('')
    result.append(f'---@alias {notPrefixtructOnlyName} {structOnlyName}')

    # 检查是不是只有 key,value 的简单 map 类型
    # 如果 fields 只有两个，也有可能当成 key-value 结构使用，生成一个别名
    if len(fields) == 2:
        keyName = fields[0]['name']
        keyType = fields[0]['type']

        valueName = fields[1]['name']
        valueType = fields[1]['type']

        keyType = convertType(keyType)
        valueType = convertType(valueType)

        canBeKey = GLOBAL_LUA_TYPE_TABLE_KEY_SET.get(keyType)
        if canBeKey is not None:
        # if keyName == 'key' and valueName == 'value': # 只要是两个 key 的先生成一个别名
            result.append('')
            result.append(f'--- .{structOriginName}')
            result.append(f'---@alias {GLOBAL_SPROTO_MAP_PREFIX}{structOnlyName} table<{keyType},{valueType}> {{[{keyType}({keyName})]={valueType}({valueName})}}')

            GLOBAl_KV_MAP_STRUCT[structOnlyName] = 1
            # result.append('')
            # result.append(f'---@alias {GLOBAL_SPROTO_MAP_PREFIX}{notPrefixtructOnlyName} {GLOBAL_SPROTO_MAP_PREFIX}{structOnlyName}')


    # 对于所有 map，记录下每个 field 的 key，方便后续当成 key 的类型
    for i in range(len(fields)):
        field = fields[i]
        keyName = field['name']
        keyType = field['type']

        GLOBAL_STRUCTS_FIELD_TYPE_MAP[f"{structOnlyName}_{keyName}"] = keyType
        if i == 0: # 潜规则，第一个 key 可当作默认的key
            # 对于 {key: value:} 的，不要生成 default 的默认 key
            # 因为对于 *struct() 这种简单 map 的使用情况，就是直接生成一维的 key-value 结构
            keyType = convertType(keyType)
            GLOBAL_STRUCTS_FIELD_TYPE_MAP[f"{structOnlyName}{GLOBAL_STRUCTS_FIELD_DEFAULT_KEY_PREFIX}"] = keyType


    result.append('')
    # print('\n'.join(result))
    return result
# end for finishOneStruct


# 解析 sproto struct 结构体定义
# bOnlyPreLoadStructName: 为 True 的时候，只是提前加载结构体名字，不需要生成 luadoc
#   这边只是生成了个 empty struct ，把 onlyName 确定了
#   重复运行函数读取同一个文件的时候，真正生成 luadoc 的时候会又生成一次 empty struct，覆盖掉这个函数生成的，来真正写入数据
#   不过 bOnlyPreLoadStructName 就是为了，提前生成 struct onlyName
#   来实现先把类型先找出来，方便结构体定义，可以不用去分文件解析的顺序，所以覆盖掉是无所谓的
def parseSprotoStruct(content, bOnlyPreLoadStructName=False):
    result = []
    visitStep = [] # 记录遍历的步骤，用于嵌套定义的时候，找到最近的定义
    topLevelStructNames = [] # 这个 content 中非嵌套定义的结构体的名字，就是在 GLOBAL_STRUCTS_MAP 中的 subStructs 的 key

    for line in content.splitlines(): # 按照行读取结构体定义
        line = line.strip()
        if not line or line.startswith('#'): # 空行或者注释行，跳过
            continue
        
        ######################################## 解析嵌套定义 - 开始
        ########################################
        if line.startswith('.'): # . 开头的是结构体定义
            if '{' not in line:
                print(f"Error: missing '{{' in struct definition: [{line}]") # 结构体定义，必须是 . xxx { 的格式,大括号不能换行
                sys.exit(1)
            structName = line[1:].replace('{', ' ').split()[0].strip()
            structonlyname, notPrefixStructonlyname = genStructOnlyName(visitStep, structName)
            if len(visitStep) == 0: # 顶层结构体
                topLevelStructNames.append(structName)
            # print(f"visitStep: {visitStep}, structName: {structName}, structonlyname: {structonlyname}, topLevelStructNames: {topLevelStructNames}")

            newStruct = getEmptyStruct()
            newStruct['originName'] = structName
            newStruct['onlyName'] = structonlyname
            newStruct['notPrefixOnlyName'] = notPrefixStructonlyname
            saveStruct2GlobalStructMap(visitStep, structName, newStruct)
            visitStep.append(structName)
            continue

        # 结构体结束
        if '}' in line:
            # 移除所有空白字符
            nonSpaceLine = ''.join(line.split())
            if nonSpaceLine != '}':
                print(f"Error: invalid struct end line, should only have '}}': [{line}]") # 结构体结束，那一行只能有 } 字符
                sys.exit(1)
            if not bOnlyPreLoadStructName: # 只是提前加载结构体名字，不需要生成 luadoc
                if not GLOBAL_ONLY_GEN_JSON_4_DEBUG: # 只生成 json 文件的时候，不需要生成 luadoc
                    oneStructContent = finishOneStruct(visitStep)            
                    if len(oneStructContent) > 0: # 把解析的当个 struct 的 luadoc 合并到这个文件总的中去
                        for tmpLineStr in oneStructContent:
                            result.append(tmpLineStr)

            visitStep.pop()
            continue
        ########################################
        ######################################## 解析嵌套定义 - 结束

        # 解析字段
        if not bOnlyPreLoadStructName: # 只是提前加载结构体名字，不需要解析字段            
            field = parseField(line, visitStep)
            if field is not None:
                saveField2GlobalStructMap(visitStep, field)
        
    struct_doc = '\n'.join(result)
    # print(struct_doc)

    return struct_doc
# end for parseSprotoStruct

# 解析 sproto 文件，生成结构体定义，存到 GLOBAL_STRUCTS_MAP 中
def cacheStructDefine(inputPath, bPreLoadStructName=False):
    with open(inputPath, 'r') as f:
        content = f.read()

    structContent = getStructContent(inputPath, content) # 获得 struct 的定义字符串
    # print(f"inputPath: {inputPath}, structContent: {structContent}")

    if bPreLoadStructName:
        parseSprotoStruct(structContent, True) # 预先加载结构体名字，方便后续解析结构体定义
        structDoc = ""
    else:
        structDoc = parseSprotoStruct(structContent) # 解析结构体定义,返回这个文件新增的顶层结构体名字
    # print(f"inputPath: {inputPath}, structDoc: {structDoc}")    
    return structDoc
# end for cacheStructDefine

##########################################################################################################

def write_output(outputPath, structDoc=None, c2sProtoDoc=None, s2cProtoDoc=None):
    """写入生成的文档到输出文件
    Args:
        outputPath: 输出文件路径
        structDoc: 结构体文档
        c2sProtoDoc: c2s协议文档
        s2cProtoDoc: s2c协议文档
    """
    try:
        content = []
        content.append(f"-- Generated by genSproto2LuaDoc.py")
        content.append(f"-- Do not edit this file manually!")
        content.append("")

        if structDoc:
            content.append(structDoc)
        if c2sProtoDoc:
            content.append(c2sProtoDoc)
        if s2cProtoDoc:
            content.append(s2cProtoDoc)
            
        if structDoc or c2sProtoDoc or s2cProtoDoc:
            # 以覆盖模式写入文件
            with open(outputPath, 'w', encoding='utf-8') as f:
                f.write('\n'.join(content))
            print(f'    Generated {outputPath} successfully')
        else:
            print(f'    No content to write to {outputPath}')
            
    except IOError as e:
        print(f'    Error writing to {outputPath}: {e}')
        raise
# end for write_output

def addBaseType2Global():
    for key, value in GLOBAL_BASE_TYPE_MAP.items():
        struct = getEmptyStruct()
        struct['originName'] = key
        struct['onlyName'] = value
        GLOBAL_STRUCTS_MAP['subStructs'][f"{key}"] = struct
# end for addBaseType2Global

def sortInputFiles(fileNames):
    """对输入文件排序:
    1. 先按文件名升序
    2. commonStruct.lua放最前
    3. PlayerInfoProto.lua放最后
    """
    # 按文件名升序排序
    sortedFileNames = sorted(fileNames)

    # 如果存在commonStruct.lua,移到最前
    if GLOBAL_COMMOM_STRUCTS_FILE_NAME in sortedFileNames:
        sortedFileNames.remove(GLOBAL_COMMOM_STRUCTS_FILE_NAME)
        sortedFileNames.insert(0, GLOBAL_COMMOM_STRUCTS_FILE_NAME)

    # 如果存在AllianceInfoProto.lua,移到最后，然后会被移动到倒数第二
    if GLOBAL_ALLIANCE_INFOPROTO_FILE_NAME in sortedFileNames:
        sortedFileNames.remove(GLOBAL_ALLIANCE_INFOPROTO_FILE_NAME)
        sortedFileNames.append(GLOBAL_ALLIANCE_INFOPROTO_FILE_NAME)        

    # 如果存在PlayerInfoProto.lua,移到最后
    if GLOBAL_PLAYER_INFOPROTO_FILE_NAME in sortedFileNames:
        sortedFileNames.remove(GLOBAL_PLAYER_INFOPROTO_FILE_NAME)
        sortedFileNames.append(GLOBAL_PLAYER_INFOPROTO_FILE_NAME)        

    return sortedFileNames
# end for sortInputFiles

def getInputFiles(protoDir):
    """获取要处理的输入文件列表"""
    inputFileNames = []

    # 先检查并添加commonStruct.lua
    if os.path.exists(os.path.join(protoDir, GLOBAL_COMMOM_STRUCTS_FILE_NAME)):
        inputFileNames.append(GLOBAL_COMMOM_STRUCTS_FILE_NAME)

    # 添加所有Proto.lua结尾的文件
    for file in os.listdir(protoDir):
        file_lower = file.lower() # mac 下大小写不敏感，都转成小写判断
        if file_lower.endswith('proto.lua'):
            inputFileNames.append(file)
    
    # 对文件排序,commonStruct.lua优先
    inputFileNames = sortInputFiles(inputFileNames)
    return inputFileNames
# end for getInputFiles

# 处理一个 sproto 文件目录，不递归，把一个目录下的所有 sproto 当成一个整体处理
def genSprotoFileDir(protoDir):
    # 创建输出目录
    outputDir = os.path.join(protoDir, 'luadoc')
    if not os.path.exists(outputDir):
        os.makedirs(outputDir)
        print(f"Created output directory: {outputDir}")
    
    outGlobalStructsFileName = 'doc_globalStructs.json'
    outGlobalStructsFilePath = os.path.join(outputDir, outGlobalStructsFileName)

    outGlobalProtoColFileName = 'doc_globalProtoCol.json'
    outGlobalProtoColFilePath = os.path.join(outputDir, outGlobalProtoColFileName)

    outGlobalStructsFieldTypeMapFileName = 'doc_globalStructsFieldTypeMap.json'
    outGlobalStructsFieldTypeMapFilePath = os.path.join(outputDir, outGlobalStructsFieldTypeMapFileName)

    outGlobalKvMapStructs = 'doc_globalKvMapStructs.json'
    outGlobalKvMapStructsFilePath = os.path.join(outputDir, outGlobalKvMapStructs)

    inputFileNames = getInputFiles(protoDir)
    # print(f"inputFileNames: {inputFileNames}")

    # 先遍历一遍，创建空的 struct ，先先找到类型的名字
    for inputFileName in inputFileNames:
        inputFilePath = os.path.join(protoDir, inputFileName)    
        print(f"PreLoading struct {inputFileName} ...")
        cacheStructDefine(inputFilePath, True)

    # 先遍历一遍，读取 struct 并将结果缓存起来
    cachestructDoc = {}
    for inputFileName in inputFileNames:
        inputFilePath = os.path.join(protoDir, inputFileName)

        print(f"Processing struct {inputFileName} ...")
        structDoc = cacheStructDefine(inputFilePath)
        # print(f"       {inputFileName}:{structDoc} ...")
        cachestructDoc[f"{inputFileName}"] = structDoc
            
    for inputFileName in inputFileNames:
        inputFilePath = os.path.join(protoDir, inputFileName)

        outputFileName = f"doc_{inputFileName}"
        outputFilePath = os.path.join(outputDir, outputFileName)

        print(f"Processing protocol {inputFileName} ...")
        c2sProtoDoc, s2cProtoDoc = cacheProrocolDefine(inputFilePath, inputFileName)
        structDoc = cachestructDoc.get(f"{inputFileName}")
        write_output(outputFilePath, structDoc, c2sProtoDoc, s2cProtoDoc)

    # 以覆盖模式写入文件
    with open(outGlobalStructsFilePath, 'w', encoding='utf-8') as f:
        f.write(genDict2JsonStr(GLOBAL_STRUCTS_MAP))
    
    # 以覆盖模式写入文件
    with open(outGlobalProtoColFilePath, 'w', encoding='utf-8') as f:
        f.write(genDict2JsonStr(GLOBAL_PROTO_COL_MAP))
    
    # 以覆盖模式写入文件
    with open(outGlobalStructsFieldTypeMapFilePath, 'w', encoding='utf-8') as f:
        f.write(genDict2JsonStr(GLOBAL_STRUCTS_FIELD_TYPE_MAP))
    
    # 以覆盖模式写入文件
    with open(outGlobalKvMapStructsFilePath, 'w', encoding='utf-8') as f:
        f.write(genDict2JsonStr(GLOBAl_KV_MAP_STRUCT))
# end for genSprotoFileDir

def main():
    if len(sys.argv) < 2:
        print("Error: Missing directory argument")
        print("Usage: python genSproto2LuaDoc.py <directory>")
        sys.exit(1)

    # 获取命令行参数中的目录
    inputDir = sys.argv[1]

    # 把基础类型，添加到 GLOBAL_STRUCTS_MAP 中
    addBaseType2Global()
    # print(genDict2JsonStr(GLOBAL_STRUCTS_MAP))

    # 按照文件目录，开始处理
    genSprotoFileDir(inputDir)
# end for main

if __name__ == '__main__':
    main()

