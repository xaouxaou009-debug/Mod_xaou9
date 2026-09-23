Xaou - Multi Pet Probe v0.6
===========================

ผลจาก v0.5
- ตัวม็อดโหลดจริง
- สร้างและเขียน XaouMultiPetProbe.log ได้
- reflection เปิด LingShouMgr ได้ครบ
- แต่ hook ผ่าน GoToActiveLcBuild ไม่ถูกเรียกบนมือถือ

v0.6 จึงเปลี่ยนวิธี:
- ไม่รอ hook จากรูปปั้นแล้ว
- เฝ้าฟิลด์ที่เกี่ยวกับสัตว์เลี้ยงโดยตรงทุกประมาณ 0.5 วินาที
- เขียน log เฉพาะเมื่อค่ามีการเปลี่ยนแปลง

ฟิลด์หลักที่เฝ้า
- runningLss
- SortedRunningLss
- <runningLs>k__BackingField
- waitSwitchNpc
- <waitBornNpc>k__BackingField
- bd2Npc
- raceLs
- LsNpcs
- lsData
- raceLsData

วิธีทดสอบ
1) อัปเดตม็อดเป็น Version 6
2) ปิดเกมแล้วเปิดใหม่
3) โหลดเซฟและรอประมาณ 2 วินาที
4) เรียกสัตว์เลี้ยงตัวแรก
5) รอ 2-3 วินาที
6) เรียกสัตว์เลี้ยงตัวที่สอง
7) รอ 2-3 วินาที
8) ส่ง XaouMultiPetProbe.log มาให้ตรวจ

มองหาบรรทัด:
- === WATCH INITIAL active-pet state ===
- === WATCH CHANGE detected ===
- WATCH CHANGED runningLss
- WATCH CHANGED SortedRunningLss
- WATCH CHANGED <runningLs>k__BackingField
