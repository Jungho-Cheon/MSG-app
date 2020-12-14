# 미식한 고독가 (Team MSG)

<div>
<img width="1000" src="https://msg-project.s3.ap-northeast-2.amazonaws.com/title_mockup.png"> 
</div>  
<br/>
<br/>
  
> ## STACK
>
> -   APP : Flutter
> -   Server :
>     -   WebSocket : EC2 Instances(Nginx, Python Websockets, Flask) with Docker
>     -   RESTful API : API Gateway + Lambda
> -   DB : DynamoDB
> -   Storage : S3
> -   Crawling : python (BeautifulSoup4, Selenium)
> -   ML(NLP) : python (Sklearn, Gensim etc.)

<br/>
<br/>

> ## APP Icon
>
> <div>
> <img width="50" src="https://msg-project.s3.ap-northeast-2.amazonaws.com/68747470733a2f2f73332e61702d6e6f727468656173742d322e616d617a6f6e6177732e636f6d2f736f6d616d73672e636f6d2f61707073746f72652e706e67.png"/> 
> </div>

## APP Download
<del>[Play Store (Android)](https://play.google.com/store/apps/details?id=com.somamsg.msgapp)</del>
<br/>
<del>[App Store (iOS)](https://apps.apple.com/us/app/%EB%AF%B8%EC%8B%9D%ED%95%9C%EA%B3%A0%EB%8F%85%EA%B0%80/id1535910346)</del>

<br/>

# 주요 기능

-   영수증 분석을 통해 간편한 식재료 관리
-   취향 분석을 통한 레시피 추천

<br/>
<br/>

# 인앱 화면 캡처

<div>
<img width="250" src="https://msg-project.s3.ap-northeast-2.amazonaws.com/Simulator+Screen+Shot+-+iPhone+11+-+2020-10-18+at+09.50.07.png"/> 
<img width="250" src="https://msg-project.s3.ap-northeast-2.amazonaws.com/Simulator+Screen+Shot+-+iPhone+11+-+2020-10-18+at+09.49.56.png"/>
</div>
<div>
<img width="250" src="https://msg-project.s3.ap-northeast-2.amazonaws.com/Simulator+Screen+Shot+-+iPhone+11+-+2020-10-18+at+09.50.20.png"/>
<img width="250" src="https://msg-project.s3.ap-northeast-2.amazonaws.com/Simulator+Screen+Shot+-+iPhone+11+-+2020-10-18+at+09.50.36.png"/>
</div>
<br/>
<br/>

# 레시피 취향 분석

![animation-2](https://user-images.githubusercontent.com/61958795/102055058-9f2e6380-3e2d-11eb-9985-de363e8f2661.gif)
> ### 하루에 최대 3번 요리한다는 가정을 하면..
>
> -   취향 분석을 위한 데이터가 부족하기 때문에 부가적으로 데이터 수집을 위한 기능이 필요했습니다.
> -   추가적으로 사용자가 조회한 레시피 정보 또한 DB에 저장하여 추천 알고리즘에 이용했습니다.
> - 레시피는 공공데이터를 이용했습니다.

<br/>
<br/>

# 서버 구성도

<div>
<img width="600" src="https://msg-project.s3.ap-northeast-2.amazonaws.com/68747470733a2f2f73332e61702d6e6f727468656173742d322e616d617a6f6e6177732e636f6d2f736f6d616d73672e636f6d2f7365727665725f6172636869746563747572652e706e67.png"/>
</div>

## 영수증 분석 기능

![animation-1](https://user-images.githubusercontent.com/61958795/102055089-a6ee0800-3e2d-11eb-8b88-6d9df947c65f.gif)
<br/>

> -  영수증 분석을 위해 S3 버킷에 사용자 별로 스토리지를 관리합니다.
> -  사용자가 영수증 사진을 찍으면 해당 사용자의 버킷 스토리지에 영수증 사진이 업로드 됩니다.
> -  사진의 주소를 통해 Naver Clova의 OCR API를 호출하고 반환된 결과 값을 통해 영수증 발급 날짜, 식재료, 총 가격 등 정보를 추출합니다.
> -  사용자는 분석된 결과를 모바일 앱에서 즉시 확인 가능하고 잘못된 내용을 수정할 수 있습니다.
> -  최종적으로 등록하기를 누를 때 각 정보들은 DynamoDB에 저장되어 사용자가 날짜별로 조회할 수 있도록 합니다.

<br/>

## 레시피 분석을 위한 데이터 셋 구축

-   특정 사용자에게 특정 레시피를 추천하기 위해 사용자의 취향을 기반으로 레시피를 선별할 수 있어야 합니다.
-   자연어 처리와 머신러닝 알고리즘을 응용하기 위해 공공데이터 보다 많은 데이터를 수집해야 했고, BeautifulSoup4, Selenium을 이용한 크롤러를 만들어 학습용 레시피 DB를 구축했습니다.
-   크롤링한 레시피를 바탕으로 word2vec 모델을 만들고 레시피들을 K-means Clustering 해 본 결과 의미있는 군집화가 일어났음을 확인할 수 있었습니다.
-   단순한 분석에도 의미있는 결과를 보였기 때문에 레시피 추천 서비스의 실효성을 예측할 수 있었고, 가장 많이 쓰이고 성능이 준수한 Collaborative Filter를 고려했습니다.
-   하지만 초기에 성능이 잘 나오지 않는 Cold-Start 문제점이 심각했기에 방향을 바꿔 Item2Vec 모델을 구상했습니다.
-   서비스를 제공할 레시피들에 대해 Doc2Vec 모델을 미리 만들어두고, 사용자가 메인 페이지를 로드할 때 선호하는 레시피 정보를 바탕으로 User Vector를 생성했습니다.
-   또한, 난이도 Category를 이용해 단순한 Item2Vec 모델을 넘어서 유저의 레벨에 맞는 난이도의 레시피를 추천하고자 했습니다.
-   이렇게 생성된 레시피 Doc2Vec과 User Vector에 대해서 Cosine Similarity를 계산해 유저가 가장 선호할 만한 레시피들을 추천합니다.

<br/>

## 인증을 위한 Cognito

-   AWS (Amazon Web Service)는 자사의 리소스 접근을 제어하고 서비스 사용자 관리를 편하게 할 수 있도록 도와주는 Cognito를 지원한다. 회원가입 절차부터 로그인 사용자의 권한까지 Cognito과 IAM으로 관리할 수 있습니다.
-   Cognito는 타사의 계정으로 로그인할 수 있도록 OAuth2.0 기반의 인증 또한 관리해 줍니다.
-   User Pool과 Identity Pool로 구성되어 있으며 User Pool은 말 그대로 서비스의 회원을 관리하며, Identity Pool은 올바른 로그인 사용자에게 임시권한을 부여하는 역할을 합니다.

<br/>

> ### OAuth2.0기반의 서드파티 로그인
>
> -   다수의 Id 공급자를 선택하기 보다, 로그인의 편의를 위해 카카오 계정을 통해 로그인이 가능하도록 구성했습니다.
> -   (이슈) App Store에 OAuth2.0 로그인을 지원하는 어플리케이션을 업로드하려면 Apple 계정으로도 로그인이 가능하도록 해야 했습니다. 지원하지 않는 경우 Apple측에서 어플리케이션을 reject합니다.

<br/>

## AWS 서버리스 서비스

-   서버리스는 마치 서버가 없이 자신의 코드를 실행시키는 것과 같은 환경을 제공합니다.
-   미식한 고독가는 CPU자원을 많이 사용하지 않는 요청에 대해 API Gateway와 Lambda로 작업을 처리할 수 있도록 구성되었습니다.
-   DynamoDB는 Lambda에서만 접근할 수 있도록 각 Lambda에 자격을 부여하여 3계층 구성을 할 수 있도록 하였습니다.

<br/>

## ELB & Auto-Scaling

-   서비스에서 CPU자원을 요구하는 작업이나 실시간으로 처리되어야하는 웹소켓 서버를 위해 사용량에 따라 EC2 인스턴스를 유동적으로 생성하는 Auto-Scaling을 적용합니다.
-   로드 벨런스를 위한 스위치로 ELB의 Network Load Balancer를 사용했습니다.
-   로드 벨런서는 라운드 로빈 방식으로 부하를 분산해 서비스의 기능들이 안정적으로 제공될 수 있도록 합니다.

<br/>

> ## Docker와 Docker-Compose
> -   Nginx, python websocket, Flask를 Docker 컨테이너로 각각 구성하여 Docker-Compose로 구동하였습니다.
> -   Nginx는 각 엔드포인트로 요청을 전달하는 리버스 프록시의 역할을 합니다.
