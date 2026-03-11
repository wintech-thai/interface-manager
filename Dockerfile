FROM ruby:3.3-alpine

# ติดตาม build-base กรณีที่ gem บางตัวต้อง compile native extensions
# และติดตั้ง gem ที่จำเป็นตามที่ error แจ้ง
RUN apk add --no-cache build-base \
    && gem install sinatra rackup puma --no-document

WORKDIR /app

# คัดลอกไฟล์โค้ด (สมมติว่าชื่อไฟล์คือ interface-manager.rb)
COPY interface-manager.rb .

# สร้าง directory สำหรับเก็บ state และกำหนดสิทธิ์
RUN mkdir -p /data

# เปิด port ตามที่ set ไว้ในโค้ด (8080)
EXPOSE 8080

CMD ["ruby", "interface-manager.rb"]
