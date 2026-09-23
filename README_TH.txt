Xaou - Multi Pet Probe v0.11
============================

ผลจาก v0.10
- ไม่ได้ติดที่ FindStoneData หาไม่เจอ
- error จริงคือ XLua เลือก overload ของ MethodInfo.Invoke ผิด
- Object[] ถูกพยายามแปลงเป็น System.Reflection.BindingFlags
- log จึงขึ้น:
  invalid value for enum System.Reflection.BindingFlags

อีกจุดที่ยืนยันได้จาก log:
- หลังสลับสัตว์เลี้ยง waitSwitchNpc มี LsStoneData 1 รายการ
- รายการนี้เปลี่ยนตามตัวที่เพิ่งถูกส่งเข้ารูปปั้น
- จึงไม่จำเป็นต้องเรียก FindStoneData อีก

v0.11 แก้:
1) เรียก MethodInfo.Invoke แบบ 5 arguments ชัดเจน
   target + BindingFlags.Default + Binder(nil) + Object[] + CultureInfo(nil)
2) อ่าน LsStoneData จาก waitSwitchNpc โดยตรง
3) เรียก RebornFromStone(stoneData)
4) เพิ่มตัวเก่ากลับ running ด้วย AddNpc2Running(previous, false)
5) ตั้งตัวที่เลือกใหม่กลับเป็น main pet

ก่อนทดสอบ
- สำรองเซฟ
- เวอร์ชันนี้ยังเป็น Experimental

วิธีทดสอบ
1) อัปเดตเป็น Version 11
2) ปิดเกมแล้วเปิดใหม่
3) โหลดเซฟ
4) เรียกตัวแรก รอ 2-3 วินาที
5) เรียกตัวที่สอง รอ 5-10 วินาที
6) ดูว่าตัวแรกกลับออกมาจากรูปปั้นหรือไม่
7) ส่ง XaouMultiPetProbe.log มาให้ตรวจ

บรรทัดสำคัญ:
- MULTIPET waitSwitchNpc StoneData acquired
- MULTIPET RebornFromStone(previous stone) OK
- MULTIPET reflection AddNpc2Running(previous, false) OK
- running count after = 2

ถ้ายังล้ม ให้ดูบรรทัด MULTIPET ERROR RebornFromStone เป็นหลัก
