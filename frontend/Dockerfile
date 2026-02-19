# 빌드 단계
FROM curlimages/curl:latest AS download
FROM google/dart:latest AS build
WORKDIR /app
RUN apt-get update && apt-get install -y unzip
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter doctor
COPY . .
RUN flutter build web --release

# 실행 단계
FROM nginx:stable-alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
