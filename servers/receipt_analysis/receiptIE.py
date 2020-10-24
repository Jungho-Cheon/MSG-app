import traceback
import dateutil.parser as dparser
from urllib import parse
import json
import csv
import requests
import re
import datetime
from config import Config

def callOCRAPI(receiptURL, providerId):
    headers = {
        'Content-Type': 'application/json',
        'X-OCR-SECRET': Config['X-OCR-SECRET']
    }
    body = {
        "version": "V1",
        "requestId": str(datetime.datetime.now()),
        "timestamp": 0,
        "images": [{
            "format": "png",
            "url": receiptURL,
            "name": "tmp"
        }]
    }

    results = []
    try:
        response = requests.post(Config['OCR-END-POINT'], headers=headers, data=json.dumps(body)).json()

        # with open('/Users/mac/receipt_detections/{}.json'.format(providerId + str(datetime.datetime.now())), 'w') as f:
        #     json.dump(response, f, indent='\t', ensure_ascii=False)

        results = response['images'][0]['fields']
    except Exception:
        traceback.print_exc()

    return results

def initData(fields):
    blockData = []
    word_height = 0
    word_width = []
    for field in fields:
        vertices = field['boundingPoly']['vertices']
        text = field['inferText'].replace(' ', '')
        word_height += vertices[3]['y'] - vertices[0]['y']
        word_width.append((vertices[1]['x'] - vertices[0]['x'])/len(text))
        x0 = round(vertices[0]['x'] + (vertices[3]['x'] - vertices[0]['x']) / 2, 2)
        y0 = round(vertices[0]['y'] + (vertices[3]['y'] - vertices[0]['y']) / 2, 2)
        x1 = round(vertices[1]['x'] + (vertices[2]['x'] - vertices[1]['x']) / 2, 2)
        y1 = round(vertices[1]['y'] + (vertices[2]['y'] - vertices[1]['y']) / 2, 2)
        blockData.append(list([(tuple([x0,y0]), tuple([x1,y1])), text]))
        # y 좌표로 정렬
        blockData.sort(key=lambda x: x[0][0][1])
    word_height /= len(fields)
    return blockData, sum(word_width)/len(fields), word_height * 0.4,

def joinCoordinates(c1, c2=None):
    if c1 is None:
        return c2
    else:
        x0, y0 = c1[0]
        x1, y1 = c2[1]
        return (tuple([x0,y0]), tuple([x1,y1]))

def checkDate(text):
    dateTypes = [
        re.compile(r'[^\d]*?\d{4}-\d{2}-\d{2}[^\d]*?'),
        re.compile(r'[^\d]*?\d{2}-\d{2}-\d{2}[^\d]*?'),
        re.compile(r'[^\d]*?\d{2}/\d{2}/\d{2}[^\d]*?')
    ]
    for _type in dateTypes:
        date = _type.search(text)
        if date:
            try:
                print(date.group())
                _date = dparser.parse(date.group(), yearfirst=True)
            except Exception:
                traceback.print_exc()
                return None
            return _date
    return None

def recipeInformationExtraction(receiptURL, providerId):
    fields = callOCRAPI(receiptURL, providerId)
    if len(fields) == 0:
        return None
    blockData, word_width, word_height = initData(fields)
    print('word_height : ', word_height)
    print('word_width : ', word_width)
    startTokens = ['상품명', '품명', '상품', '제품명', '단품명', '단가', '수량', '금액']
    endTokens = [
        '합계', '내신금액', '내실금액', '합계금액', '판매총액',
        '총구매액', '카드명', '과세물품가액', '면세물품과액',
        '거스름돈', '받은돈', '신용카드', '현금', '판매금액',
        '면세물품가액', '할인액'
    ]

    result = {}
    productsFlag = False
    dateFlag = False
    words_in_line = [[]]

    for i in range(1, len(blockData) - 1):
        # OCR 추출 텍스트
        text = blockData[i][1]

        if not productsFlag and not dateFlag:
            print(text)
            date = checkDate(text)
            if date:
                date = str(date).split()[0]
                year, month, day = re.split('-|/', date)
                result['date'] = dict({
                    'year': year,
                    'month': month,
                    'day': day,
                    'coordinate': blockData[i][0]
                })

                dateFlag = True

        # 상품명이 시작되는 토큰을 찾았을 때
        if text in startTokens:
            # 날짜 정보를 찾지 못한 경우 현재 날짜를 반환한다.
            if not dateFlag:
                date = datetime.datetime.now()
                result['date'] = dict({
                    'year': str(date.year),
                    'month': str(date.month),
                    'day': str(date.day),
                })
            productsFlag = True

        if productsFlag:
            if word_height < blockData[i][0][0][1] - blockData[i - 1][0][0][1]:
                words_in_line.append([blockData[i]])
            else:
                words_in_line[-1].append(blockData[i])

    # x좌표 정렬
    for line in words_in_line:
        line.sort(key=lambda x: x[0][0][0])

    product_list = []
    price_list = []
    bottomFlag = False
    for line in words_in_line:
        target = ''
        for _, _text in line:
            target += _text

        if not bottomFlag:
            for end in endTokens:
                if target.find(end) != -1:
                    bottomFlag = True
                    break

        if bottomFlag:
            price_list.append(line)
        else:
            product_list.append(line)

    # 식재료 매퍼
    ingredients = []
    with open('./ingredient_list.csv', encoding='utf-8', mode='r') as f:
        reader = csv.reader(f)
        [ingredients.append(row[0]) for row in reader]

    # 상품명, 좌표 추출
    products = []
    for product_blocks in product_list:
        product_name = ''
        product_coordinate = None
        for _product in product_blocks:
            if re.search(r'[가-힣]+', _product[1]):
                product_name += _product[1]
                product_coordinate = joinCoordinates(product_coordinate, _product[0])
        if product_coordinate:
            for ingredient in ingredients:
                if product_name.find(ingredient) != -1:
                    products.append(
                        dict({
                            'ingredient': ingredient,
                            'coordinate': product_coordinate
                        })
                    )
                    break

    [print(p) for p in products]

    # 가격, 좌표 추출
    for price_blocks in price_list:
        price_name = ''
        price_coordinate = None
        for _price in price_blocks:
            price_name += _price[1]
            price_coordinate = joinCoordinates(price_coordinate, _price[0])
        if price_coordinate:
            preprocess = re.sub(r'[^가-힣0-9]', '', price_name)
            try:
                price_name = re.search(r'[가-힣]+', preprocess).group()
                price = re.search(r'[0-9]+', preprocess).group()
            except:
                continue

            for price_kind in ['총액', '합계', '총구매액', '받은돈', ' 내신금액']:
                if price_name.find(price_kind) != -1:
                    result['price'] = dict({
                            'price_kind': price_kind,
                            'price': price,
                            'coordinate': price_coordinate
                        })
                    break


    if products:
        result['ingredients'] = products

    return result
