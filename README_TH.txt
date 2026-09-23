Xaou - Multi Pet Probe v0.7
===========================

ผลจาก v0.6
- ระบบมีสัตว์เลี้ยง 2 ตัวจริงใน LsNpcs และ raceLs
- แต่ SortedRunningLss มีเพียง 1 ตัว
- <runningLs>k__BackingField ชี้สัตว์เลี้ยง active ได้ทีละตัว
- ตอนสลับสัตว์เลี้ยง ตัวเกมเปลี่ยน runningLs และ waitSwitchNpc โดยไม่ได้ลบอีกตัวจาก LsNpcs

v0.7 เพิ่มการตรวจ:
- runtime fields/properties/methods ของ runningLss
- runtime API ของ SortedRunningLss และ waitSwitchNpc
- method signature ของ LingShouMgr ที่เกี่ยวกับ run/active/switch/born/stone/build/remove
- เน้นดู Add / Remove / Clear / Count / Contains / get / set / sort / enumerator

วิธีทดสอบ
1) อัปเดตม็อดเป็น Version 7
2) ปิดเกมแล้วเปิดใหม่
3) โหลดเซฟ
4) รอประมาณ 2 วินาที
5) เรียกสัตว์เลี้ยงตัวแรก
6) รอ 2-3 วินาที
7) เรียกสัตว์เลี้ยงตัวที่สอง
8) ส่ง XaouMultiPetProbe.log มาให้ตรวจ

บรรทัดสำคัญรอบนี้:
- === RUNTIME TYPE runningLss ...
- RUNTIME FIELD ...
- RUNTIME PROP ...
- RUNTIME METHOD ...
- === LingShouMgr relevant method signatures ===
- SIG ...

ยังไม่แก้ค่า active-pet โดยตรงในเวอร์ชันนี้ เพื่อเลี่ยงทำ state/AI/เซฟเสียก่อนรู้ API ของ HashList ชัดเจน
