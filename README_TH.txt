Xaou - Multi Pet Probe v0.4
===========================

เวอร์ชันนี้แก้สำหรับการทดสอบบนมือถือ/Android

ตำแหน่ง Log
ม็อดจะพยายามสร้าง:
XaouMultiPetProbe.log

ลำดับตำแหน่งที่ลองเขียน:
1) Unity Application.persistentDataPath
2) Unity Application.temporaryCachePath
3) โฟลเดอร์ม็อด/Mods แบบ PC เป็น fallback

บน Android ให้ค้นชื่อไฟล์:
XaouMultiPetProbe.log

ด้วย MT Manager หรือ file manager ที่เข้าถึงโฟลเดอร์ข้อมูลแอปได้
ตำแหน่งจริงขึ้นกับแอป/ตัวรันที่ใช้ จึงไม่ hard-code package name

ภายในหัวไฟล์จะบันทึก:
- LogPath
- PersistentDataPath
- DataPath

วิธีทดสอบ
1) อัปเดตม็อดเป็น Version 4
2) ปิดเกมแล้วเปิดใหม่
3) โหลดเซฟ
4) เรียกสัตว์เลี้ยงตัวแรกจากรูปปั้น
5) เรียกสัตว์เลี้ยงตัวที่สอง
6) ค้น XaouMultiPetProbe.log แล้วส่งมาให้ตรวจ

ตัว Probe ยังไม่ปลดลิมิตสัตว์เลี้ยง มีไว้เก็บข้อมูลก่อนทำ Multi Pet ตัวจริง
