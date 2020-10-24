import websockets
import traceback
import asyncio
import json
import csv
import boto3
import random
from boto3.dynamodb.conditions import Key


def cmdStringify(cmd, data=None):
    jsonData = dict()
    jsonData['CMD'] = cmd
    if data:
        jsonData['DATA'] = data
    return json.dumps(jsonData, indent='\t', ensure_ascii=False)


def initIngredients():
    lst = []
    with open('./ingredients.csv', 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        for word in reader:
            lst.append(word[0])

    ingredients = {}
    for ingredient in lst:
        ingredient.replace(' ', '')
        tmp_ingredients = ingredients
        for idx, c in enumerate(ingredient):
            if c not in tmp_ingredients:
                tmp_ingredients[c] = {
                    'word': ''
                }
            tmp_ingredients = tmp_ingredients[c]
            if idx == len(ingredient) - 1:
                tmp_ingredients['word'] = ingredient

        tmp_ingredients = ingredients
        for idx, c in enumerate(ingredient[::-1]):
            if c not in tmp_ingredients:
                tmp_ingredients[c] = {
                    'word': ''
                }
            tmp_ingredients = tmp_ingredients[c]
            if idx == len(ingredient) - 1:
                tmp_ingredients['word'] = ingredient


    return ingredients


def DFS(ingredients, results):
    if ingredients['word'] != '':
        results.add(ingredients['word'])
    for _key in ingredients.keys():
        if _key == 'word':
            continue
        DFS(ingredients[_key], results)


def search_word(ingredients, search):
    results = set()
    isExist = True
    try:
        tmp_ingredients = ingredients
        for c in search:
            if c not in tmp_ingredients:
                isExist = False
                break
            tmp_ingredients = tmp_ingredients[c]

        if isExist:
            DFS(tmp_ingredients, results)

        isExist = True
        tmp_ingredients = ingredients
        for c in search[::-1]:
            if c not in tmp_ingredients:
                isExist = False
                break
            tmp_ingredients = tmp_ingredients[c]
        if isExist:
            DFS(tmp_ingredients, results)
    except:
        return []

    return list(results)



async def recvData(websocket):
    data = await websocket.recv()
    data = json.loads(data)
    return data

async def accept(websocket, _):
    try:
        while True:
            data = await recvData(websocket)

            cmd = data['CMD']

            if cmd == 'START':
                await websocket.send(cmdStringify('SEARCH'))
            elif cmd == "SEARCH":
                keyword = data['BODY']
                if len(keyword) == 0:
                    await websocket.send(cmdStringify('RESULTS', dict({
                        'ingredients': []
                    })))

                result = search_word(ingredients, keyword)

                await websocket.send(cmdStringify('RESULTS', dict({
                    'ingredients': result
                })))

            elif cmd == 'CLOSE':
                print('CONNECTION CLOSE')
                break

    except Exception:
        traceback.print_exc()
        print('EXCEPTION CLOSE')



if __name__ == '__main__':
    port = 9998
    print('listen port {}'.format(port))

    # dynamodb = boto3.resource('dynamodb')
    # table = dynamodb.Table('MSG-RECIPES')

    ingredients = initIngredients()

    start_server = websockets.serve(accept, port=port)
    asyncio.get_event_loop().run_until_complete(start_server)
    asyncio.get_event_loop().run_forever()