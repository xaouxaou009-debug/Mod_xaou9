Xaou - Multi Pet Probe v0.10
============================

ผลจาก v0.9
- ตรวจพบการสลับสัตว์เลี้ยงได้ถูกต้อง
- ตัวเก่าถูกส่งเข้ารูปปั้นและ Key กลายเป็น 0
- ตัวใหม่ถูกตั้งเป็น runningLs แต่ Key ของ NPC ใน LingShouMgr ยังคง 0
- เพราะฉะนั้นเงื่อนไขเดิมที่รอ "ตัวใหม่มี Key > 0" ไม่มีวันผ่าน
- v0.9 จึง timeout และไม่เคยเรียก RebornFromStone

v0.10 แก้โดย:
1) ตรวจพบการสลับ
2) รอสั้น ๆ ให้ state ของเกมนิ่ง
3) ใช้ reflection เรียก FindStoneData(previousPet)
4) เรียก RebornFromStone(stoneData) เพื่อดึงตัวเก่ากลับออกจากรูปปั้น
5) เรียก AddNpc2Running(previousPet, false)
6) ตั้งตัวที่เพิ่งเลือกกลับเป็น main pet

ก่อนทดสอบ
- สำรองเซฟ
- เวอร์ชันนี้เป็น Experimental

วิธีทดสอบ
1) อัปเดตเป็น Version 10
2) ปิดเกมแล้วเปิดใหม่
3) โหลดเซฟ
4) เรียกสัตว์เลี้ยงตัวแรก
5) รอ 2-3 วินาที
6) เรียกตัวที่สอง
7) รอ 5-10 วินาที
8) ดูว่าตัวแรกถูกดึงกลับออกมาหรือไม่ และทั้งสองตัวอยู่พร้อมกันหรือไม่
9) ส่ง XaouMultiPetProbe.log มาให้ตรวจ

บรรทัดสำคัญ:
- MULTIPET FindStoneData OK
- MULTIPET RebornFromStone(previous) OK
- MULTIPET reflection AddNpc2Running(previous, false) OK
- running count after = 2
- previous running = true
- new running = true
