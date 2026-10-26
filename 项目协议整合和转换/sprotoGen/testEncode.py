import json
import pysproto
from sys import getrefcount
from pysproto import sproto_create, sproto_type, sproto_encode, sproto_decode, sproto_pack, sproto_unpack, sproto_protocol, sproto_dump, sproto_name
from binascii import b2a_hex, a2b_hex
import unittest
import socket
import struct
import json
import time

c2s_sp = None

def init_c2s_sp():
    global c2s_sp
    if c2s_sp is None:
        with open("sproto\c2s.spb", "rb") as fh:
            content = fh.read()
            c2s_sp = sproto_create(content)

def get_c2s_req_resp(msgNameOrTag):
    global c2s_sp
    init_c2s_sp()
    tag, req, resp = sproto_protocol(c2s_sp, msgNameOrTag)
    return tag, req, resp

def get_c2s_st(structName):
    global c2s_sp
    init_c2s_sp()
    st = sproto_type(c2s_sp, structName)
    return st

def packNetMsg(session, msgNameOrTag, msg):
        print("pack start:" + str(msgNameOrTag))
        stPackage = get_c2s_st("package")
        print("pack get package proto")
        retTag, req, resp = get_c2s_req_resp(msgNameOrTag)
        print("pack get msg proto")
        if type(msgNameOrTag) == type('a'):
            tag = retTag
        else:
            tag = msgNameOrTag
        print("tag:" + str(tag))
        package = {
            "type":tag,
            "session":session,
        }

        print("package.type:" + str(package["type"]))
        print("package.session:" + str(package["session"]))

        packageData = sproto_encode(stPackage, package)

        dest, r = sproto_decode(stPackage, packageData)
        print("dest package.type:" + str(dest["type"]))
        print("dest package.session:" + str(dest["session"]))
        print("r:" + json.dumps(r))
        print("dest:" + json.dumps(dest))

        print("pack encode package")
        msgData = sproto_encode(req, msg)
        print("pack encode msg")
        
        dest, r = sproto_decode(req, msgData)
        print("r:" + json.dumps(r))
        print("dest:" + json.dumps(dest))

        netData = packageData + msgData
        netData = sproto_pack(netData)
        netMsgLen = netData.__len__()
        print("netMsgLen:" + str(netMsgLen))
        packedMsg = struct.pack('>h{}s'.format(netMsgLen), netMsgLen, netData)
        print("packedMsgLen:" + str(packedMsg.__len__()))

        return packedMsg

session = 1
uid = 1
gameToken = "wg"
msgName = "resExchangeMultiple"
msg = {
    "exchanges": {
        20003:{
            "key":20003,
            "value":1
        }
    }
}

packedMsg = packNetMsg(session, msgName, msg)

