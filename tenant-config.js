// Demo fixture only. Production tenant identity and operational data must come from the tenant-scoped backend.
export const tenant={
 id:"gcova",name:"지코바 치킨",
 stores:[{id:"gangnam",name:"강남점",region:"서울"},{id:"nowon",name:"노원점",region:"서울"},{id:"bupyeong",name:"부평점",region:"인천"},{id:"ingye",name:"수원 인계점",region:"경기"},{id:"seomyeon",name:"부산 서면점",region:"부산"},{id:"dongseong",name:"대구 동성로점",region:"대구"}],
 fixture:{employeeNames:["김민준","이서연","박지훈","최유진","정현우","한지민","오세훈","윤수아"],baseWage:10320,baseHours:36,operatingHours:{open:"11:00",close:"24:00"},baseSales:1850000,salesStep:213000,inventory:[["순살 닭고기",34,"kg",20],["양념소스",18,"kg",12],["치킨무",42,"팩",30],["콜라 1.25L",16,"병",20]],recipes:[["순살양념구이","순살 닭고기 600g · 양념소스 180g"],["소금구이","순살 닭고기 600g · 소금구이 시즈닝 14g"],["떡사리","떡 180g · 양념소스 35g"]]}
};
