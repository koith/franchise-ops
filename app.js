export const APP_VERSION = "v0.01";

export const tenant = {
  id: "gcova",
  name: "지코바 치킨",
  displayName: "지코바 치킨",
  regionLabel: "전국",
  stores: [
    { id: "gcova-seoul-gangnam", name: "강남점", region: "서울", staff: 8, working: 3, sales: 2840000, status: "정상" },
    { id: "gcova-seoul-nowon", name: "노원점", region: "서울", staff: 6, working: 2, sales: 1960000, status: "정상" },
    { id: "gcova-incheon-bupyeong", name: "부평점", region: "인천", staff: 7, working: 4, sales: 2310000, status: "정상" },
    { id: "gcova-suwon-ingye", name: "수원 인계점", region: "경기", staff: 9, working: 3, sales: 3170000, status: "확인 필요" },
    { id: "gcova-busan-seomyeon", name: "부산 서면점", region: "부산", staff: 7, working: 2, sales: 2570000, status: "정상" },
    { id: "gcova-daegu-dongseongro", name: "대구 동성로점", region: "대구", staff: 5, working: 1, sales: 1740000, status: "정상" }
  ]
};

const won = value => new Intl.NumberFormat("ko-KR").format(value) + "원";
const qs = new URLSearchParams(location.search);
const storeId = qs.get("store");
const store = tenant.stores.find(item => item.id === storeId);

document.querySelector("#version").textContent = APP_VERSION;
document.querySelector("#brand").textContent = tenant.displayName;

function renderDashboard() {
  document.title = tenant.displayName + " 본사 대시보드";
  const regions = ["전체", ...new Set(tenant.stores.map(s => s.region))];
  document.querySelector("main").innerHTML = `
    <section class="hero">
      <div><p class="eyebrow">HEADQUARTERS</p><h1>본사 대시보드</h1><p>전국 지점의 오늘 운영 현황을 확인합니다.</p></div>
      <div class="summary"><strong>${tenant.stores.length}</strong><span>운영 지점</span></div>
    </section>
    <section class="toolbar">
      <label>지역<select id="region">${regions.map(r=>`<option>${r}</option>`).join("")}</select></label>
      <label>지점 검색<input id="search" placeholder="지점명 검색"></label>
    </section>
    <section id="stores" class="store-grid"></section>`;
  const region = document.querySelector("#region");
  const search = document.querySelector("#search");
  const draw = () => {
    const r=region.value, q=search.value.trim();
    const list=tenant.stores.filter(s=>(r==="전체"||s.region===r)&&(!q||s.name.includes(q)));
    document.querySelector("#stores").innerHTML=list.map(s=>`
      <article class="store-card">
        <header><div><span class="region">${s.region}</span><h2>${s.name}</h2></div><span class="status ${s.status==="정상"?"ok":"warn"}">${s.status}</span></header>
        <div class="metrics"><div><span>오늘 매출</span><strong>${won(s.sales)}</strong></div><div><span>근무 중</span><strong>${s.working} / ${s.staff}명</strong></div></div>
        <a class="primary" href="?store=${encodeURIComponent(s.id)}">상세</a>
      </article>`).join("") || '<p class="empty">조건에 맞는 지점이 없습니다.</p>';
  };
  region.addEventListener("change",draw); search.addEventListener("input",draw); draw();
}

function renderStore() {
  if (!store) { history.replaceState(null,"",location.pathname); renderDashboard(); return; }
  document.title = tenant.displayName + " " + store.name;
  document.querySelector("main").innerHTML = `
    <a class="back" href="./">← 본사 대시보드</a>
    <section class="hero store-hero"><div><p class="eyebrow">${tenant.displayName}</p><h1>${store.name}</h1><p>${store.region} · 오늘 운영 현황</p></div><span class="status ${store.status==="정상"?"ok":"warn"}">${store.status}</span></section>
    <nav class="tabs" aria-label="지점 업무 메뉴">
      <button class="active">출퇴근</button><button>관리</button><button>급여</button><button>재고</button><button>레시피</button>
    </nav>
    <section class="overview">
      <article><span>재직 직원</span><strong>${store.staff}명</strong></article>
      <article><span>현재 근무</span><strong>${store.working}명</strong></article>
      <article><span>오늘 매출</span><strong>${won(store.sales)}</strong></article>
    </section>
    <section class="panel"><h2>현재 근무 현황</h2><p>범용판 첫 단계에서는 지점 진입 구조와 테넌트/지점 경계를 먼저 구축했습니다. 직원·근태·급여·재고·레시피 데이터는 별도 범용 백엔드에 연결됩니다.</p></section>`;
}
storeId ? renderStore() : renderDashboard();
