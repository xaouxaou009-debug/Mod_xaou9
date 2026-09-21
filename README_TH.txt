Xaou - Multi Pet Probe v0.1
===========================

เป้าหมาย
- ตรวจว่าตอนเรียกสัตว์เลี้ยงผ่านรูปปั้น LingShouMgr เปลี่ยนฟิลด์ใด
- ใช้หาจุดที่เกมเก็บ "สัตว์เลี้ยงที่ Active อยู่" เพื่อทำ Multi Pet ตัวจริงต่อ
- เวอร์ชันนี้ยังไม่ปลดลิมิต และตั้งใจให้พฤติกรรมเกมเหมือนเดิม

ติดตั้ง
1) สำรองเซฟก่อนทดสอบ
2) แตกโฟลเดอร์ XaouMultiPetProbe_v0.1 ไปไว้ที่:
   AmazingCultivationSimulator\Mods\XaouMultiPetProbe_v0.1
3) เปิดม็อดในเกม แล้วปิด/เปิดเกมใหม่
4) เปิด Developer Mode ตามปกติ

วิธีทดสอบ
1) โหลดเซฟที่มีสัตว์เลี้ยงและรูปปั้นอย่างน้อย 2 ชนิด
2) ใช้รูปปั้นเรียกสัตว์เลี้ยงตัวแรกตามปกติ
3) จากนั้นใช้รูปปั้นเรียกสัตว์เลี้ยงอีกชนิด
4) เปิด log/console และค้นคำว่า:
   [XaouMultiPetProbe]
5) ส่งช่วง log ตั้งแต่:
   === Activate pet statue
   จนถึง
   === Activation complete ===
   รวมถึงบรรทัด FIELD / METHOD ที่พิมพ์ตอนเริ่มด้วย

สิ่งที่ควรเห็น
- FIELD ...
- METHOD ...
- CHANGED <field> : <before> -> <after>

ถ้าเห็น ERROR
- ส่งบรรทัด ERROR ทั้งหมดมาได้เลย
- ลบโฟลเดอร์ม็อดนี้เพื่อถอดตัวทดลองออก

หมายเหตุ
ไฟล์ Settings/CommandDef/XaouMultiPetProbe.xml override เฉพาะคำสั่ง GoToActiveLcBuild
จากนั้น Lua จะบันทึกสถานะก่อน/หลัง แล้วเรียก LingShouMgr.Instance:ActiveLcBuild(it)
ตัวเดิมของเกมต่อทันที
