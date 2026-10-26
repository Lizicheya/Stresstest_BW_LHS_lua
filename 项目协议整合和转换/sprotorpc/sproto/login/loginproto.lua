local loginproto = {}

--登录1-20

loginproto.struct = [[
	.ClientInfo {
    	platform 0: string # 登录设备平台
    	deviceId 1: string # 登录设备id
    	version 2: string # 游戏版本号
    	sysVersion 3: string # 系统版号
    	deviceType 4: string # 设备型号
    	deviceLanguage 5: string # 设备语言
        language 6: string # 游戏语言
        carrier 7: string # 运营商
        gameversion 8: string # 游戏资源(热更)版本号
        channel 9: string # 渠道
        country 10: string # 国家(导量分量器测试时候用)
	}
]]

loginproto.c2s = loginproto.struct..[[

#a、默认登录（直接打开游戏）不传uid,createNewRole
#b、切换账号（游戏内通过设置->角色界面，选择已经存在的角色）传uid,不传createNewRole
#c、创建账号（游戏内通过设置->角色界面，选择服务器后选择创建角色）传createNewRole=true
reqlogin 1 { #请求登陆
    request {
        account 0: string
        password 1: string
        sdkToken 2: string
        uid 3: uint32
        createNewRole 4: boolean
        serverId 5: uint32
        clientInfo 6: ClientInfo
    }
    response {
        sucess 0: boolean
        gameToken 1: string
        gatewayHost 2: string
        gatewayPort 3: uint32
        uid 4: uint32
        serverVersion 5: string
        configVersion 6: string
        isNew 7: boolean
        timeZone 8: integer # -12~12基于utc
    }
}

reqAuth 2 { #网关验证
    request {
        uid 0: uint32
        gameToken 1: string
        isReconnect 2: boolean
        sessionResponse 3 : uint32 # 服务器回包确认:回包对应的请求包的session
        sessionSync 4 : uint32 # 服务器推送包确认:服务器推送包的session
    }
    response {
        node 0: string # 节点名 
        agent 1: uint32 # agent 地址
    }
}

]]


loginproto.s2c = loginproto.struct..[[

resLogin 2 {
    request {
        sucess 0: boolean
        gameToken 1: string
        gatewayHost 2: string
        gatewayPort 3: uint32
        uid 4: uint32
        serverVersion 5: string
        configVersion 6: string
        isNew 7: boolean
    }
}

syncKicked 3 {
    request {
        kickedReason 0: uint32
    }
}

]]

return loginproto