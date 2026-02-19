# backend/test_commerce.py
import os
from app.commerce import get_safety_product_recommendation

# 1. 환경 변수 설정 (터미널에서 설정 안 했을 경우를 대비)
# os.environ["NAVER_CLIENT_ID"] = "시현님의_클라이언트_ID"
# os.environ["NAVER_CLIENT_SECRET"] = "시현님의_클라이언트_시크릿"

def test_shopping_api():
    keyword = "아기 모서리 보호대"
    print(f"🔍 테스트 키워드: {keyword}")
    
    try:
        results = get_safety_product_recommendation(keyword, topk=3)
        
        print(f"✅ 결과 개수: {len(results)}개\n")
        for i, item in enumerate(results):
            print(f"[{i+1}] {item['name']}")
            print(f"   - 가격: {item['price']}원")
            print(f"   - 쇼핑몰: {item['shopName']}")
            print(f"   - 구매링크: {item['buyUrl']}")
            print(f"   - 이미지: {item['imageUrl']}\n")
            
    except Exception as e:
        print(f"❌ 테스트 실패: {e}")

if __name__ == "__main__":
    test_shopping_api()