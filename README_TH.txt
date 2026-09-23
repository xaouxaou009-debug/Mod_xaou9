Xaou - Multi Pet Probe v0.3
===========================

เป้าหมาย
- ตรวจว่าตอนเรียกสัตว์เลี้ยงผ่านรูปปั้น LingShouMgr เปลี่ยนฟิลด์ใด
- ตรวจค่าภายใน List / Dictionary / Array
- ใช้หาจุดที่เกมเก็บ "สัตว์เลี้ยงที่ Active อยู่" เพื่อทำ Multi Pet ตัวจริงต่อ
- เวอร์ชันนี้ยังไม่ปลดลิมิตสัตว์เลี้ยง

ไฟล์ Log
ม็อดจะสร้างไฟล์ชื่อ:
XaouMultiPetProbe.log

v0.3 แก้การค้นหาโฟลเดอร์ให้รองรับทั้ง:
1) AmazingCultivationSimulator\Mods\<โฟลเดอร์ม็อด>
2) Steam Workshop: steamapps\workshop\content\955900\<Workshop ID>
3) ถ้าสองตำแหน่งแรกเขียนไม่ได้ จะลองโฟลเดอร์ Mods
4) ถ้ายังไม่ได้ จะลอง Unity persistentDataPath
5) สุดท้ายจึงลองโฟลเดอร์เกม

วิธีทดสอบ
1) อัปเดตม็อดเป็น Version 3
2) ปิดเกมแล้วเปิดใหม่
3) เปิดม็อดและโหลดเซฟ
4) เรียกสัตว์เลี้ยงตัวแรกจากรูปปั้น
5) เรียกสัตว์เลี้ยงตัวที่สอง
6) ค้นหาไฟล์ XaouMultiPetProbe.log
7) ส่งไฟล์นั้นมาให้ตรวจได้เลย

ถ้าเจอไฟล์แล้ว ภายในบรรทัดต้น ๆ จะมี LogPath บอกตำแหน่งจริงที่เกมเขียนไฟล์ไว้

หมายเหตุ
Settings/CommandDef/XaouMultiPetProbe.xml override เฉพาะ GoToActiveLcBuild
และเรียก LingShouMgr.Instance:ActiveLcBuild(it) ของเกมเดิมต่อหลัง snapshot
