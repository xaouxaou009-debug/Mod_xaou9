Xaou - Multi Pet Probe v0.2
===========================

เป้าหมาย
- ตรวจว่าตอนเรียกสัตว์เลี้ยงผ่านรูปปั้น LingShouMgr เปลี่ยนฟิลด์ใด
- ตรวจค่าภายใน List / Dictionary / Array เพิ่มเติม
- ใช้หาจุดที่เกมเก็บ "สัตว์เลี้ยงที่ Active อยู่" เพื่อทำ Multi Pet ตัวจริงต่อ
- เวอร์ชันนี้ยังไม่ปลดลิมิต และตั้งใจให้พฤติกรรมเกมเหมือนเดิม

ไฟล์ Log
- ม็อดจะสร้างไฟล์ชื่อ XaouMultiPetProbe.log อัตโนมัติ
- พยายามสร้างไว้ในโฟลเดอร์ของม็อด XaouMultiPetProbe
- ถ้าหาโฟลเดอร์ม็อดไม่เจอ จะลองวางไว้ในโฟลเดอร์ Mods
- Console log เดิมยังทำงานควบคู่กัน

วิธีทดสอบ
1) สำรองเซฟก่อน
2) เปิดม็อดแล้วปิด/เปิดเกมใหม่
3) โหลดเซฟที่มีสัตว์เลี้ยงและรูปปั้นอย่างน้อย 2 ชนิด
4) ใช้รูปปั้นเรียกสัตว์เลี้ยงตัวแรก
5) ใช้รูปปั้นเรียกสัตว์เลี้ยงอีกชนิด
6) ปิดเกมหรือออกจากเซฟเมื่อทดสอบเสร็จ
7) ส่งไฟล์ XaouMultiPetProbe.log มาให้ตรวจได้เลย

สิ่งที่ Log จะเก็บ
- FIELD ...
- METHOD ...
- CHANGED <field>
- BEFORE / AFTER
- เนื้อหาภายใน collection สูงสุด 32 รายการต่อ field
- ERROR / WARN ถ้ามี

หมายเหตุ
Settings/CommandDef/XaouMultiPetProbe.xml override เฉพาะคำสั่ง GoToActiveLcBuild
จากนั้น Lua จะ snapshot LingShouMgr ก่อนและหลังเรียก LingShouMgr.Instance:ActiveLcBuild(it)
ตัวเกมเดิมยังเป็นผู้ทำการ Active รูปปั้นตามปกติ
