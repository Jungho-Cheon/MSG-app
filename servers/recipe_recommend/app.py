import pandas as pd
import numpy as np
from gensim.models.doc2vec import Doc2Vec, TaggedDocument
from sklearn.metrics.pairwise import cosine_similarity

from flask import Flask, jsonify, request
import boto3
from boto3.dynamodb.conditions import Key

def make_doc2vec_data(data, column, t_document=False):
    data_doc = []
    for tag, doc in zip(data.index, data[column]):
        doc = doc.split(" ")
        data_doc.append(([tag], doc))
    if t_document:
        data = [TaggedDocument(words=text, tags=tag) for tag, text in data_doc]
        return data

    return data_doc

dynamodb = boto3.resource('dynamodb', region_name='ap-northeast-2')
history_table = dynamodb.Table('MSG-RECIPE-HISTORY')
taste_table = dynamodb.Table('MSG-USER-TASTE')
recipe_table = dynamodb.Table('MSG-RECIPES')

data_path = './msg_recipe.csv'
model_path = './msg_recipe_model.doc2vec'

recipe = pd.read_csv(data_path, index_col=0)
model = Doc2Vec.load(model_path)
data = make_doc2vec_data(recipe, 'data', t_document=True)
 
app = Flask(__name__)


def get_recommened_contents(user, data_doc, model):
    scores = []

    for text, tags in data_doc:
        trained_doc_vec = model.docvecs[tags[0]]
        scores.append(cosine_similarity(user.reshape(-1, 128), trained_doc_vec.reshape(-1, 128)))

    scores = np.array(scores).reshape(-1)
    scores = np.argsort(-scores)[:10]

    return scores


def make_user_embedding(index_list, data_doc, model):
    user = []
    user_embedding = []
    for i in index_list:
        user.append(data_doc[i][1][0])
    for i in user:
        user_embedding.append(model.docvecs[i])
    user_embedding = np.array(user_embedding)
    user = np.mean(user_embedding, axis=0)
    return user


def recipe_recommend(user_favorite):
    user = make_user_embedding(user_favorite, data, model)
    result = get_recommened_contents(user, data, model)
    return result


@app.route('/recipe-recommend')
def receipe_recommend():
    provider_id = request.args.get('providerId')
    recommend_type = request.args.get('recommendType')
    print('PROVIDER_ID ', provider_id)

    user_history = history_table.query(
        KeyConditionExpression=Key('PROVIDER_ID').eq(provider_id)
    )['Items']

    user_taste = taste_table.query(
        KeyConditionExpression=Key('PROVIDER_ID').eq(provider_id)
    )['Items']

    recipe_ids = []

    # 회원 취향분석 레시피 아이디 추가
    for recipe in user_taste:
        recipe_ids.append(int(recipe['RECIPE_ID']))

    # 회원이 만든 레시피 아이디 추가
    for recipe in user_history:
        recipe_ids.append(int(recipe['RECIPE_ID']))

    print(recipe_ids)

    # 추천 방식
    # if recommend_type == 'CanMake':
    #     print('recommend type : CanMake')
    # elif recommend_type == 'JustRecommend':
    #     print('recommend type : JustRecommend')
    # else:
    #     print('recommend type error', recommend_type)

    # TODO 레시피 추천
    recommended_ids = recipe_recommend(recipe_ids)
    recommended_recipes = []
    for recipe_id in recommended_ids:
        response = recipe_table.query(
            KeyConditionExpression=Key('RECIPE_PROVIDER').eq('PUBLIC') \
                                   & Key('RECIPE_ID').eq(str(recipe_id))
        )['Items']
        if len(response) > 0:
            recommended_recipes.append(response[0])

    return jsonify(recommended_recipes)


if __name__ == '__main__':
   app.run(host='0.0.0.0', port=8080)
