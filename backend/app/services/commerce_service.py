import os
import re
import urllib.parse
import requests

NAVER_CLIENT_ID = os.getenv("NAVER_CLIENT_ID")
NAVER_CLIENT_SECRET = os.getenv("NAVER_CLIENT_SECRET")

_TAG_RE = re.compile(r"<[^>]+>")

def _strip_tags(text: str) -> str:
    return _TAG_RE.sub("", text or "")

def get_external_mall_link(keyword: str, platform="naver"):
    encoded_keyword = urllib.parse.quote(keyword)
    if platform == "naver":
        return f"https://search.shopping.naver.com/search/all?query={encoded_keyword}"
    return f"https://www.google.com/search?q={encoded_keyword}"

def get_safety_product_recommendation(purchase_keyword: str, topk: int = 6):
    """
    ✅ 네이버 쇼핑 검색 API로 '상품 리스트'를 반환합니다.
    """
    # 1. API 키 체크 (없으면 바로 fallback)
    if not NAVER_CLIENT_ID or not NAVER_CLIENT_SECRET:
        q = urllib.parse.quote(purchase_keyword)
        return [{
            "product_id": "nv_fallback",
            "name": f"{purchase_keyword} (검색 결과)",
            "price": None,
            "imageUrl": None,
            "buyUrl": f"https://search.shopping.naver.com/search/all?query={q}"
        }]

    # 2. 네이버 쇼핑 검색 API 호출
    url = "https://openapi.naver.com/v1/search/shop.json"
    headers = {
        "X-Naver-Client-Id": NAVER_CLIENT_ID,
        "X-Naver-Client-Secret": NAVER_CLIENT_SECRET,
    }
    params = {
        "query": purchase_keyword,
        "display": topk,
        "sort": "sim",
    }

    try:
        r = requests.get(url, headers=headers, params=params, timeout=5)
        r.raise_for_status()
        raw = r.json()
        
        products = []
        # 3. 받아온 데이터를 반복문으로 처리 (requests 호출 이후에 위치)
        for i, it in enumerate(raw.get("items", [])):
            title = _strip_tags(it.get("title", ""))
            lprice = it.get("lprice")
            price = int(lprice) if lprice and str(lprice).isdigit() else None

            products.append({
                "product_id": f"nv_{i}",             # ✅ 변수명 id -> product_id 변경
                "name": title,
                "price": price,
                "imageUrl": it.get("image"),
                "buyUrl": it.get("link")
            })

        # 4. 결과가 비어있을 경우 처리
        if not products:
            q = urllib.parse.quote(purchase_keyword)
            return [{
                "product_id": "nv_empty",
                "name": f"{purchase_keyword} (검색)",
                "price": None,
                "imageUrl": None,
                "buyUrl": f"https://search.shopping.naver.com/search/all?query={q}"
            }]

        return products

    except Exception as e:
        print(f"❌ 네이버 쇼핑 API 에러: {e}")
        return []