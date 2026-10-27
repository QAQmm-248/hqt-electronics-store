(() => {
  window.loadBrandFilters = async function () {
    const brands = await api('/api/brands' + (category ? '?category=' + encodeURIComponent(category) : ''));
    const host = document.getElementById('brandFilters');
    if (!host) return;
    const label = document.createElement('span');
    label.className = 'filter-label';
    label.textContent = 'Thương hiệu';
    host.replaceChildren(label);
    for (const name of ['', ...brands.map(x => x.BrandName)]) {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'filter brand-filter' + (brand === name ? ' on' : '');
      button.textContent = name || 'Tất cả hãng';
      button.addEventListener('click', () => setBrand(name, button));
      host.append(button);
    }
  };
  const nav = document.querySelector('.desktop-nav');
  const menu = nav?.querySelector('.mega-menu');
  if (!nav || !menu) return;
  const panel = document.createElement('div');
  panel.className = 'brand-menu-options';
  menu.replaceChildren(panel);
  menu.setAttribute('aria-label', 'Lọc theo thương hiệu');
  let generation = 0;
  let closeTimer;
  const cache = new Map();
  function close() {
    generation++;
    menu.classList.remove('brands-open');
    nav.querySelectorAll('[aria-expanded]').forEach(a => a.setAttribute('aria-expanded', 'false'));
  }
  async function open(link, categoryName) {
    clearTimeout(closeTimer);
    const ticket = ++generation;
    nav.querySelectorAll('[aria-expanded]').forEach(a => a.setAttribute('aria-expanded', String(a === link)));
    menu.style.left = `${Math.max(0, Math.min(link.offsetLeft, nav.clientWidth - 300))}px`;
    menu.classList.add('brands-open');
    panel.textContent = 'Đang tải thương hiệu…';
    try {
      let brands = cache.get(categoryName);
      if (!brands) {
        brands = await api('/api/brands?category=' + encodeURIComponent(categoryName));
        cache.set(categoryName, brands);
      }
      if (ticket !== generation) return;
      panel.replaceChildren();
      for (const entry of brands) {
        const button = document.createElement('button');
        button.type = 'button';
        button.textContent = entry.BrandName;
        button.addEventListener('click', async () => {
          close();
          category = categoryName;
          brand = entry.BrandName;
          document.querySelectorAll('.category-filter').forEach(b => b.classList.toggle('on', b.textContent.trim() === categoryName));
          await loadBrandFilters();
          await loadProducts();
          document.getElementById('products').scrollIntoView({behavior: 'smooth', block: 'start'});
          if (document.activeElement instanceof HTMLElement) document.activeElement.blur();
        });
        panel.append(button);
      }
      if (!brands.length) panel.textContent = 'Chưa có thương hiệu trong danh mục này.';
    } catch {
      if (ticket === generation) panel.textContent = 'Không tải được thương hiệu. Vui lòng thử lại.';
    }
  }
  const categories = ['Điện thoại thông minh', 'Laptop', 'Máy tính bảng', 'Màn hình', 'Phụ kiện'];
  [...nav.querySelectorAll(':scope > a')].forEach((link, index) => {
    if (!categories[index]) {
      link.addEventListener('mouseenter', close);
      link.addEventListener('focus', close);
      return;
    }
    link.setAttribute('aria-expanded', 'false');
    link.setAttribute('aria-controls', 'navigation-brands');
    link.addEventListener('mouseenter', () => open(link, categories[index]));
    link.addEventListener('focus', () => open(link, categories[index]));
    link.addEventListener('click', close);
  });
  menu.id = 'navigation-brands';
  nav.addEventListener('mouseleave', () => { closeTimer = setTimeout(close, 120); });
  menu.addEventListener('mouseenter', () => clearTimeout(closeTimer));
  nav.addEventListener('focusout', e => { if (!nav.contains(e.relatedTarget)) close(); });
  document.addEventListener('click', e => { if (!nav.contains(e.target)) close(); });
  document.addEventListener('keydown', e => { if (e.key === 'Escape') close(); });
})();
