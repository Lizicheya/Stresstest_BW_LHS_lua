import pysproto
from sys import getrefcount
from pysproto import sproto_create, sproto_type, sproto_encode, sproto_decode, sproto_pack, sproto_unpack, sproto_protocol, sproto_dump, sproto_name
from binascii import b2a_hex, a2b_hex
import unittest
import socket
import struct
import json
import time

if not hasattr(socket.socket, 'recvex'):
    def _gsocket_recvex(self, bufsize, flags=0):
        received = self.recv(bufsize, flags)
        if not received:
            raise Exception('socket [{}] has been closed from the other end'.format(self))
        while len(received) != bufsize:
            partmsg = self.recv(bufsize - len(received), flags)
            if not partmsg:
                raise Exception('socket [{}] has been closed from the other end'.format(self))
            received += partmsg

        return received


    socket.socket.recvex = _gsocket_recvex

class TestPySproto(unittest.TestCase):
    __session = {}
    nextSession = 1
    c2s_sp = None
    s2c_sp = None
    def init_c2s_sp(self):
        if self.c2s_sp is None:
            with open("./sproto/c2s.spb", "rb") as fh:
                content = fh.read()
                self.c2s_sp = sproto_create(content)

    def get_c2s_st(self, structName):
        self.init_c2s_sp()
        st = sproto_type(self.c2s_sp, structName)
        return st
    
    def get_c2s_req_resp(self, msgNameOrTag):
        self.init_c2s_sp()
        tag, req, resp = sproto_protocol(self.c2s_sp, msgNameOrTag)
        return tag, req, resp

    def init_s2c_sp(self):
        if self.s2c_sp is None:
            with open("./sproto/s2c.spb", "rb") as fh:
                content = fh.read()
                self.s2c_sp = sproto_create(content)

    def get_s2c_st(self, structName):
        self.init_s2c_sp()
        st = sproto_type(self.s2c_sp, structName)
        return st
    
    def get_s2c_req_resp(self, msgNameOrTag):
        self.init_s2c_sp()
        tag, req, resp = sproto_protocol(self.s2c_sp, msgNameOrTag)
        if req == -1:
            req = None
        if resp == -1:
            resp = None
        return tag, req, resp

    def test_basic_encode_decode(self):
        st = self.get_c2s_st("ComItem")
        source = {
            "id":1001,
        }
        result = sproto_encode(st, source)
        print(b2a_hex(result))
        dest, r = sproto_decode(st, result)
        print("id:" + str(dest["id"]))
        self.assertEqual(source, dest)

    def test_sproto_protocal(self):
        # tag, req, resp = self.get_c2s_req_resp("useItem")
        tag, req, resp = self.get_c2s_req_resp(201)
        print(tag)
        source = {
            "id":1002,
        }
        msg = sproto_encode(req, source)
        print(b2a_hex(msg))
        dest, r = sproto_decode(req, msg)
        print("id:" + str(dest["id"]))

        # msgName = sproto_name(201)
        print("tag:" + str(tag))

    def packMsg(self, msgNameOrTag, msg):
        print("pack start")
        retTag, req, resp = self.get_c2s_req_resp(msgNameOrTag)
        print("pack get msg proto")
        if type(msgNameOrTag) == type('a'):
            tag = retTag
        else:
            tag = msgNameOrTag
        print("tag:" + str(tag))

        msgData = sproto_encode(req, msg)
        print("pack encode msg")
        # netData = packageData + msgData
        # return netData

    def packNetMsg(self, session, msgNameOrTag, msg):
        print("pack start:" + str(msgNameOrTag))
        stPackage = self.get_c2s_st("package")
        print("pack get package proto")
        retTag, req, resp = self.get_c2s_req_resp(msgNameOrTag)
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

        print("pack encode package")
        msgData = sproto_encode(req, msg)
        print("pack encode msg")
        netData = packageData + msgData
        netData = sproto_pack(netData)
        netMsgLen = netData.__len__()
        print("netMsgLen:" + str(netMsgLen))
        packedMsg = struct.pack('>h{}s'.format(netMsgLen), netMsgLen, netData)
        print("packedMsgLen:" + str(packedMsg.__len__()))

        if resp is not None:
            self.__session[session] = resp
        else:
            self.__session[session] = True
        return packedMsg
    
    def recvOne(self, sock):
        pktHeader = sock.recvex(2)
        pktSize, = struct.unpack('>H', pktHeader)
        pktMsg = sock.recvex(pktSize)
        pktMsg = sproto_unpack(pktMsg)
        pktSize = pktMsg.__len__()
        print("msg sz:" + str(pktSize))
        stPackage = self.get_s2c_st("package")
        head, szHead = sproto_decode(stPackage, pktMsg)
        print("head sz:" + str(szHead))
        if head.has_key("type"):
            type = head["type"]
            type = int(type)
            print("head.type:" + str(head["type"]))
            protoName, req, resp = self.get_s2c_req_resp(type)
            print("protoName:" + protoName)
            szData = pktSize - szHead
            print("data sz:" + str(szData))
            msgData = pktMsg[-szData:]
            msg = sproto_decode(req, msgData)
            return "REQUEST", protoName, msg[0], 0
        else:
            session = head["session"]
            print("response head.session:" + str(session))
            resp = self.__session[session]
            szData = pktSize - szHead
            print("response data sz:" + str(szData))
            msgData = pktMsg[-szData:]
            errorCode = head["ud"]
            print("response head.ud:" + str(errorCode))
            self.__session[session] = None
            if resp == True:
                return "RESPONSE", session, None, errorCode
            else:
                result = sproto_decode(resp, msgData)
                result = result[0]
                print(json.dumps(result))
                return "RESPONSE", session, result, errorCode
    
    def auth(self, gatewayHost, gatewayPort, uid, gameToken):
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client_socket.connect((gatewayHost, gatewayPort))

        session = self.nextSession
        self.nextSession += 1
        msgName = "reqAuth"
        msg = {
            "uid":uid,
            "gameToken":gameToken,
        }

        packedMsg = self.packNetMsg(session, msgName, msg)
        client_socket.send(packedMsg)

        sprotoType, protoName, msg, errorCode = self.recvOne(client_socket)
        while sprotoType != "RESPONSE" or protoName != session:
            sprotoType, protoName, msg, errorCode = self.recvOne(client_socket)

        session = self.nextSession
        self.nextSession += 1
        msgName = "upgrade"
        msg = {
            "id":1,
        }

        packedMsg = self.packNetMsg(session, msgName, msg)
        client_socket.send(packedMsg)

        sprotoType, protoName, result, errorCode = self.recvOne(client_socket)
        while sprotoType != "RESPONSE":
            sprotoType, protoName, result, errorCode = self.recvOne(client_socket)
        print("sprotoType:" + str(sprotoType))
        print("protoName:" + str(protoName))
        print("result:" + str(result))
        print("errorCode:" + str(errorCode))

        time.sleep(5)

    def test_login(self):
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client_socket.connect(('10.0.0.142', 8001))
        # client_socket.connect(('192.168.10.93', 10002))
    
        session = self.nextSession
        self.nextSession += 1
        msgName = "reqlogin"
        msg = {
            "account":u'wg',
        }
        
        packedMsg = self.packNetMsg(session, msgName, msg)
        client_socket.send(packedMsg)

        sprotoType, protoName, msgResLogin, errorCode = self.recvOne(client_socket)
        while sprotoType != "RESPONSE" or protoName != session:
            sprotoType, protoName, msgResLogin, errorCode = self.recvOne(client_socket)
        
        print(json.dumps(msgResLogin))
        sucess = msgResLogin["sucess"]
        print("sucess:" + str(sucess))
        if sucess == True:
            print("login sucess")
            gatewayHost = msgResLogin["gatewayHost"]
            gatewayPort = msgResLogin["gatewayPort"]
            gameToken = msgResLogin["gameToken"]
            uid = msgResLogin["uid"]
            print("gatewayHost:" + str(gatewayHost) + ",gatewayHost:" + str(gatewayPort) + ",gameToken:" + str(gameToken), ",uid:" + str(uid))
            client_socket.close()
            self.auth(gatewayHost, gatewayPort, uid, gameToken)
        else:
            print("login failed")
            # client_socket.close()

        # self.recvOne(client_socket)

if __name__ == "__main__":
    unittest.main()
