import json
import os
import boto3
import websockets
import asyncio
import base64
from receiptIE import recipeInformationExtraction
from urllib import parse as URLParse
import traceback
import datetime

class Node():
    def __init__(self):
        self.__providerId = ''
        self.__fileName = ''
        self.__fileSize = 0
        self.__data = ''
        self.__imagePath = ''
        self.__receiptInfo = {}


    @property
    def providerId(self):
        return self.__providerId
    @providerId.setter
    def providerId(self, providerId):
        self.__providerId = providerId

    @property
    def fileName(self):
        return self.__fileName
    @fileName.setter
    def fileName(self, fileName):
        self.__fileName = fileName

    @property
    def fileSize(self):
        return self.__fileSize
    @fileSize.setter
    def fileSize(self, fileSize):
        self.__fileSize = int(fileSize)

    @property
    def data(self):
        return self.__data
    @data.setter
    def data(self, data):
        self.__data = data

    @property
    def imagePath(self):
        return self.__imagePath

    @property
    def receiptInfo(self):
        return self.__receiptInfo

    @receiptInfo.setter
    def receiptInfo(self, receiptInfo):
        self.__receiptInfo = receiptInfo

    def addData(self, data):
        self.__data += data

    def isComplete(self):
        print(self.__fileSize, len(self.__data))

        return self.__fileSize == len(self.__data)

    def save(self):
        byte = self.__data.encode("ASCII")
        byte = base64.b64decode(byte)

        self.__imagePath = './{}.png'.format(self.fileName)
        with open(self.__imagePath, 'wb') as f:
            f.write(byte)

        print('저장 완료')


# 바디없는 명령어를 json포맷으로 변경
'''
    ex) 
    input
        cmd = 'START'
    output
        return {
            'cmd': 'START'
        }
'''
def cmdStringify(cmd, data=None):
    jsonData = dict()
    jsonData['CMD'] = cmd
    if data:
        jsonData['DATA'] = data
    return json.dumps(jsonData, indent='\t', ensure_ascii=False)

async def recvData(websocket):
    data = await websocket.recv()
    data = json.loads(data)
    return data

async def accept(websocket, _):

    node = Node()
    while True:

        # 명령어를 받는다.
        data = await recvData(websocket)
        cmd = data['CMD']
        print(cmd)

        # 처음 접속 시 웹소켓에서 START 명령어가 온다.
        if cmd == 'START':
            # 파일 정보를 요청한다.
            print('START')
            await websocket.send(cmdStringify('GET_INFO'))
        # 파일 정보 저장
        elif cmd == 'GET_INFO':
            print('GET_INFO')
            node.providerId = data['BODY']['PROVIDER_ID']
            node.fileName = data['BODY']['FILE_NAME']
            node.fileSize = data['BODY']['FILE_SIZE']
            await websocket.send(cmdStringify('IMAGE_DATA'))

        # 이미지 업로드
        elif cmd == 'IMAGE_DATA':

            node.addData(data['BODY'])
            # 파일 전송이 끝나면
            if node.isComplete():
                print('업로드 완료')
                # 이미지 파일을 저장한다.
                try:
                    node.save()

                    origImageURL = sendS3(node.imagePath, node.providerId, node.fileName)
                    removeOrgImage(node.imagePath)
                    receiptInfo = recipeInformationExtraction(origImageURL, node.providerId)
                    if receiptInfo is None:
                        await websocket.send(cmdStringify("ERROR"))
                        break

                    node.receiptInfo = receiptInfo
                    print("분석완료", str(datetime.datetime.now()))
                    if len(receiptInfo.keys()) == 0:
                        await websocket.send(cmdStringify('NO_INGREDIENTS'))

                    else:
                        node.receiptInfo = receiptInfo
                        await websocket.send(cmdStringify('RECEIPT_INFO', data=receiptInfo))

                except Exception:
                    await websocket.send(cmdStringify("ERROR"))
                    break
            else:
                # 전송이 끝나지 않은 경우 파일 데이터를 요청한다.
                await websocket.send(cmdStringify('IMAGE_DATA'))

        elif cmd == 'CLOSE':
            print('연결 해제')
            break

def sendS3(imagePath, providerId, fileName):
    bucket_key = 'receipt/{}/{}.png'.format(providerId, fileName)

    try:
        s3.upload_file(imagePath, bucket_name, bucket_key)
    except Exception:
        traceback.print_exc()

    imageURL = 'https://msg-user-receipts.s3-ap-northeast-2.amazonaws.com/{}'.format(URLParse.quote(bucket_key))

    return imageURL

def removeOrgImage(imagePath):
    # 원본 파일 삭제
    if os.path.isfile(imagePath):
        os.remove(imagePath)
        print('원본 파일 삭제 완료')
    else:
        print('파일 없음')

if __name__ == '__main__':
    s3 = boto3.client('s3')
    bucket_name = 'msg-user-receipts'

    port = 9999
    print('listen port {}'.format(port))

    start_server = websockets.serve(accept, port=port)
    asyncio.get_event_loop().run_until_complete(start_server)
    asyncio.get_event_loop().run_forever()

