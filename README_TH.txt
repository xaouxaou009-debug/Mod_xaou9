Xaou - Multi Pet Probe v0.9
===========================

สาเหตุที่ v0.8 ยังได้สัตว์เลี้ยงตัวเดียว
- ใน log พบ:
  MULTIPET ERROR AddNpc2Running: attempt to call a nil value
- AddNpc2Running มีอยู่จริง แต่เป็นเมธอด non-public
- Lua เรียกตรงด้วย mgr:AddNpc2Running(...) ไม่ได้
- ตอนจับการสลับ ตัวเก่าถูกส่งกลับ Stone แล้วและ Key กลายเป็น 0

v0.9 แก้สองจุดนี้:
1) เรียกเมธอดภายใน LingShouMgr ผ่าน System.Reflection
2) ไม่คืนตัวเก่าทันทีตอนกำลังสลับ
   รอจนตัวใหม่มี Key บนแผนที่ก่อน แล้วจึง:
   - FindStoneData(previous)
   - RebornFromStone(stoneData)
   - AddNpc2Running(previous, false)
   - set_runningLs(newPet) เพื่อให้ตัวใหม่ยังเป็น main pet

ก่อนทดสอบ
- สำรองเซฟ
- เวอร์ชันนี้เป็น Experimental และเริ่มเรียก state ภายในของเกมจริง

วิธีทดสอบ
1) อัปเดตเป็น Version 9
2) ปิดเกมแล้วเปิดใหม่
3) โหลดเซฟ
4) เรียกสัตว์เลี้ยงตัวแรก
5) รอ 2-3 วินาที
6) เรียกตัวที่สอง
7) รออย่างน้อย 8-10 วินาที
8) ดูว่าตัวแรกกลับออกมาบนแผนที่พร้อมกับตัวที่สองหรือไม่
9) ส่ง XaouMultiPetProbe.log มาให้ตรวจ

บรรทัดสำคัญ:
- MULTIPET switch detected; restore scheduled
- MULTIPET FindStoneData OK
- MULTIPET RebornFromStone(previous) OK
- MULTIPET reflection AddNpc2Running(previous, false) OK
- running count after = 2
- previous running = true
- new running = true

หมายเหตุ:
หน้า UI ของเกมอาจยังแสดง "ตัวหลัก" ได้เพียง 1 ตัว เพราะ runningLs เป็น main pet เดี่ยว
สิ่งที่ v0.9 ทดสอบคือให้สัตว์เลี้ยงหลายตัวอยู่และทำงานบนแผนที่พร้อมกัน โดยมี main pet หนึ่งตัว
