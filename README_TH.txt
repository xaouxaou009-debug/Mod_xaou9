Xaou - Multi Pet Probe v0.5
===========================

แก้จากผลทดสอบบน Android:
- v0.4 สร้างไฟล์ XaouMultiPetProbe.log ได้สำเร็จ
- แต่มีเพียงหัวไฟล์ ไม่มีบรรทัด log ต่อท้าย
- v0.5 เลิกใช้ File.AppendAllText
- เปลี่ยนเป็น ReadAllText + WriteAllText เพื่อรองรับ Lua/C# binding ของตัวเกมมือถือ

ตำแหน่ง Log หลัก:
Unity Application.persistentDataPath

วิธีทดสอบ
1) อัปเดตม็อดเป็น Version 5
2) ปิดเกมแล้วเปิดใหม่
3) โหลดเซฟ
4) เรียกสัตว์เลี้ยงตัวแรกจากรูปปั้น
5) เรียกสัตว์เลี้ยงตัวที่สอง
6) ส่ง XaouMultiPetProbe.log มาให้ตรวจ

ไฟล์ที่ถูกต้องควรเริ่มมีบรรทัด:
- [XaouMultiPetProbe] ... v0.5 loaded
- FIELD ...
- METHOD ...
- === Activate pet statue ...
- CHANGED ...
