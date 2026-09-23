Xaou - Multi Pet Probe v0.8
===========================

ผลจาก v0.7
- runningLss เป็น LingShouMgr.HashList<Npc>
- ภายในใช้ HashSet<Npc>
- มี API AddNpc / RemoveNpc
- LingShouMgr มี API:
  AddNpc2Running(Npc npc, bool updateMain)
  RemoveNpcFromRunning(Npc npc)
  UpdateMainRunningLs()
- SortedRunningLss เป็น List<Npc> ปกติ

v0.8 เริ่มทดสอบ Multi Pet ตัวจริงแบบเสี่ยงต่ำ:
- ไม่แก้ HashSet โดยตรง
- ไม่แก้ save data โดยตรง
- ตอน main pet เปลี่ยนจากตัวเก่าเป็นตัวใหม่
  จะเรียก:
  LingShouMgr.Instance:AddNpc2Running(previousPet, false)
- false หมายถึงไม่ตั้งตัวเก่ากลับเป็น main pet
- ตัวใหม่ยังเป็น main pet ตามระบบเกม

ก่อนทดสอบ
- สำรองเซฟไว้ก่อน
- เวอร์ชันนี้เป็น Experimental
- ถ้าเกมค้าง/สัตว์เลี้ยงหาย/AI แปลก ให้ปิดม็อดแล้วโหลดเซฟสำรอง

วิธีทดสอบ
1) อัปเดตม็อดเป็น Version 8
2) ปิดเกมแล้วเปิดใหม่
3) โหลดเซฟ
4) เรียกสัตว์เลี้ยงตัวแรก รอ 2-3 วินาที
5) เรียกสัตว์เลี้ยงตัวที่สอง รอ 3-5 วินาที
6) ดูว่า "ตัวแรกยังอยู่และทำงานต่อ" พร้อมกับตัวที่สองหรือไม่
7) ส่ง XaouMultiPetProbe.log มาให้ตรวจ

บรรทัดที่ต้องดู:
- === MULTIPET switch detected ===
- MULTIPET AddNpc2Running(previous, false) OK
- running count before
- running count after
- previous now running
- SortedRunningLss after

ถ้า running count after = 2 และ previous now running = true
แปลว่าระบบ Running หลายตัวสำเร็จในระดับ manager แล้ว
จากนั้นค่อยตรวจว่าตัวเก่าถูกคืนจากสถานะรูปปั้น/AI ครบหรือยัง
