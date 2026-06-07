import React, { useEffect, useMemo, useState } from "react";

const content = {
  en: {
    lang: "en",
    navLabel: "Primary navigation",
    nav: ["Features", "Interface", "Privacy", "Download"],
    themeLabel: "Toggle theme",
    languageLabel: "Switch language",
    heroTitle: "SubPulse — subscription calendar for Mac.",
    heroText:
      "Track recurring payments, see upcoming renewals, and make spending decisions in a calm local-first app without accounts, extra network noise, or overloaded spreadsheets.",
    primaryCta: "Download DMG",
    secondaryCta: "See interface",
    notesLabel: "Key properties",
    notes: ["macOS 14+", "Local-first", "SwiftUI"],
    heroShotLabel: "SubPulse app screenshot",
    screenshotAlt: "SubPulse dashboard with a subscription calendar",
    monthLabels: ["Today", "In 7 days", "In 30 days"],
    floatingForecast: "renewal forecast",
    nextRenewal: "Next renewal",
    analytics: [
      ["$112.98", "June renewals"],
      ["3", "active renewals"],
      ["7 days", "until next payment"],
    ],
    sectionTitle: "All subscription essentials in one quiet window.",
    sectionText: "SubPulse turns recurring payments into a calendar, readable forecasts, and clear control.",
    features: [
      {
        title: "Renewal calendar",
        text: "Each month becomes a living payment map with day totals, service icons, and quick details.",
        icon: "calendar",
      },
      {
        title: "Expense analytics",
        text: "Categories, forecasts, top subscriptions, and saving scenarios show where the budget goes.",
        icon: "chart",
      },
      {
        title: "Local on Mac",
        text: "The MVP keeps your subscription data local: no accounts, no tracking, no unnecessary network calls.",
        icon: "lock",
      },
      {
        title: "Reminders",
        text: "Notifications and Reminders.app integration help you avoid forgotten renewals.",
        icon: "bell",
      },
      {
        title: "Currencies",
        text: "USD, EUR, RUB, GBP, and TRY convert into your base currency for honest totals.",
        icon: "currency",
      },
      {
        title: "Soft Neumorphic",
        text: "Raised and inset surfaces, tactile hover states, and soft light/dark themes.",
        icon: "layers",
      },
    ],
    interfaceTitle: "Soft Neumorphic UI without the toy feeling.",
    interfaceText:
      "SubPulse surfaces feel tactile: raised cards sink on hover, inset controls lift up, and motion explains what can be clicked.",
    bullets: ["Light and dark soft themes.", "Native macOS window behavior.", "Smooth calendar and chart animation."],
    galleryLabel: "SubPulse interface screenshots",
    galleryOpen: "Open screenshot",
    galleryClose: "Close screenshot",
    galleryItems: [
      {
        title: "Main calendar",
        text: "Monthly totals, renewal dates, and tactile navigation.",
        alt: "SubPulse main calendar screen in light Soft Neumorphic theme",
      },
      {
        title: "Dark surface",
        text: "The same soft depth in a darker macOS-friendly palette.",
        alt: "SubPulse main calendar screen in dark Soft Neumorphic theme",
      },
      {
        title: "Subscriptions",
        text: "A clean active list with quick actions and payment details.",
        alt: "SubPulse subscriptions list screen",
      },
      {
        title: "Analytics",
        text: "Forecasts, categories, and charts inside calm raised cards.",
        alt: "SubPulse analytics screen with charts",
      },
    ],
    boardA: "All subscriptions",
    boardB: "Analytics",
    privacyTitle: "Your data stays close.",
    privacyText:
      "SubPulse is built as a local-first app: subscriptions, categories, payment methods, and preferences live on your Mac. It is simple for personal finance tracking and ready for future iOS expansion.",
    steps: [
      ["01", "Add a subscription", "amount, period, date, and currency"],
      ["02", "Open the month", "the calendar shows renewals"],
      ["03", "Decide", "analytics suggests savings"],
    ],
    downloadAlt: "SubPulse app icon",
    downloadTitle: "Download SubPulse for macOS.",
    downloadText: "The DMG is included in this MVP landing page. Future releases can move to GitHub Releases.",
    downloadCta: "Download SubPulse.dmg",
    statsLabel: "SubPulse live site stats",
    stats: {
      downloads: "downloads",
      online: "online now",
      recentUsers: "last 3 users",
      totalVisitors: "total visitors",
    },
    rights: "All rights reserved.",
    faqLabel: "Questions and answers",
    faqs: [
      {
        q: "How do I install SubPulse?",
        a: "Download the DMG, open it, then drag SubPulse.app to Applications. If Gatekeeper asks, use Control-click -> Open for the first launch.",
      },
      {
        q: "Which macOS version is required?",
        a: "SubPulse targets macOS 14 and newer because it uses SwiftUI, SwiftData, Charts, and system notifications.",
      },
      {
        q: "Where is my data stored?",
        a: "The current MVP is local-first, so subscription data stays on your Mac. iCloud sync is planned as a future direction.",
      },
      {
        q: "Is there a Russian version?",
        a: "Yes. Use the EN/RU switch in the header to change the landing page language.",
      },
    ],
    footerDev: "Developer @Rootoff",
  },
  ru: {
    lang: "ru",
    navLabel: "Основная навигация",
    nav: ["Возможности", "Интерфейс", "Приватность", "Скачать"],
    themeLabel: "Переключить тему",
    languageLabel: "Переключить язык",
    heroTitle: "SubPulse — календарь подписок для Mac.",
    heroText:
      "Учитывайте регулярные платежи, смотрите ближайшие списания и принимайте решения по расходам в спокойном local-first приложении без аккаунтов, лишней сети и перегруженных таблиц.",
    primaryCta: "Скачать DMG",
    secondaryCta: "Посмотреть интерфейс",
    notesLabel: "Ключевые свойства",
    notes: ["macOS 14+", "Local-first", "SwiftUI"],
    heroShotLabel: "Скриншот приложения SubPulse",
    screenshotAlt: "Главный экран SubPulse с календарем подписок",
    monthLabels: ["Сегодня", "Через 7 дней", "Через 30 дней"],
    floatingForecast: "прогноз списаний",
    nextRenewal: "Next renewal",
    analytics: [
      ["$112.98", "списания в июне"],
      ["3", "активных продления"],
      ["7 дн.", "до следующего платежа"],
    ],
    sectionTitle: "Все важное по подпискам — в одном спокойном окне.",
    sectionText: "SubPulse собирает платежи в календарь, превращает суммы в понятные прогнозы и оставляет контроль у пользователя.",
    features: [
      {
        title: "Календарь списаний",
        text: "Месяц показывает платежи как живую карту: сумма в день, иконка сервиса и быстрый переход к деталям.",
        icon: "calendar",
      },
      {
        title: "Аналитика расходов",
        text: "Категории, прогноз, топ подписок и сценарии экономии помогают увидеть, куда уходит бюджет.",
        icon: "chart",
      },
      {
        title: "Локально на Mac",
        text: "MVP хранит данные локально. Без сети для подписок, без аккаунтов и без лишнего шума.",
        icon: "lock",
      },
      {
        title: "Напоминания",
        text: "Уведомления и интеграция с Reminders.app помогают не пропускать продления.",
        icon: "bell",
      },
      {
        title: "Валюты и курсы",
        text: "USD, EUR, RUB, GBP и TRY пересчитываются в базовую валюту для честной общей суммы.",
        icon: "currency",
      },
      {
        title: "Soft Neumorphic",
        text: "Выпуклые и впуклые поверхности, мягкие hover-состояния и светлая/темная tactile-тема.",
        icon: "layers",
      },
    ],
    interfaceTitle: "Soft Neumorphic UI без ощущения игрушки.",
    interfaceText:
      "В SubPulse поверхности ведут себя тактильно: выпуклые карточки уходят внутрь на hover, впуклые элементы поднимаются, а движение объясняет, что можно нажать.",
    bullets: ["Светлая и темная soft-тема.", "Нативные размеры окна и macOS-поведение.", "Аккуратная анимация графиков и календаря."],
    galleryLabel: "Скриншоты интерфейса SubPulse",
    galleryOpen: "Открыть скриншот",
    galleryClose: "Закрыть скриншот",
    galleryItems: [
      {
        title: "Главный календарь",
        text: "Сумма месяца, даты списаний и тактильная навигация.",
        alt: "Главный календарь SubPulse в светлой Soft Neumorphic теме",
      },
      {
        title: "Темная поверхность",
        text: "Та же мягкая глубина в темной macOS-палитре.",
        alt: "Главный календарь SubPulse в темной Soft Neumorphic теме",
      },
      {
        title: "Подписки",
        text: "Чистый список активных сервисов с быстрыми действиями.",
        alt: "Экран списка подписок SubPulse",
      },
      {
        title: "Аналитика",
        text: "Прогнозы, категории и графики внутри спокойных карточек.",
        alt: "Экран аналитики SubPulse с графиками",
      },
    ],
    boardA: "Все подписки",
    boardB: "Аналитика",
    privacyTitle: "Данные остаются ближе к вам.",
    privacyText:
      "SubPulse сделан как local-first приложение: список подписок, категории, способы оплаты и настройки живут на вашем Mac. Это удобно для личного учета и хорошо подходит для будущего расширения под iOS.",
    steps: [
      ["01", "Добавьте подписку", "сумма, период, дата и валюта"],
      ["02", "Смотрите месяц", "календарь покажет списания"],
      ["03", "Решайте", "аналитика подскажет экономию"],
    ],
    downloadAlt: "Иконка SubPulse",
    downloadTitle: "Скачайте SubPulse для macOS.",
    downloadText: "DMG уже включен в этот лендинг для MVP. В будущем релизы можно вынести в GitHub Releases.",
    downloadCta: "Скачать SubPulse.dmg",
    statsLabel: "Живая статистика сайта SubPulse",
    stats: {
      downloads: "скачиваний",
      online: "онлайн сейчас",
      recentUsers: "последние 3",
      totalVisitors: "всего посетителей",
    },
    rights: "Все права защищены.",
    faqLabel: "Вопросы и ответы",
    faqs: [
      {
        q: "Как установить SubPulse?",
        a: "Скачайте DMG, откройте его и перенесите SubPulse.app в Applications. Если macOS спросит подтверждение, откройте приложение через Control-click -> Open.",
      },
      {
        q: "Какая версия macOS нужна?",
        a: "SubPulse рассчитан на macOS 14 и новее, потому что использует SwiftUI, SwiftData, Charts и системные уведомления.",
      },
      {
        q: "Где хранятся данные?",
        a: "В текущем MVP данные local-first и остаются на вашем Mac. iCloud-синхронизация оставлена как направление для будущих версий.",
      },
      {
        q: "Есть английская версия?",
        a: "Да. Используйте переключатель EN/RU в шапке сайта.",
      },
    ],
    footerDev: "Разработчик @Rootoff",
  },
};

const galleryAssets = [
  {
    thumb: "/assets/gallery/dashboard-light-thumb.png",
    full: "/assets/gallery/dashboard-light.png",
  },
  {
    thumb: "/assets/gallery/dashboard-dark-thumb.png",
    full: "/assets/gallery/dashboard-dark.png",
  },
  {
    thumb: "/assets/gallery/subscriptions-list-thumb.png",
    full: "/assets/gallery/subscriptions-list.png",
  },
  {
    thumb: "/assets/gallery/analytics-view-thumb.png",
    full: "/assets/gallery/analytics-view.png",
  },
];

function Icon({ name }) {
  const icons = {
    calendar: (
      <path d="M7 3v3M17 3v3M4.5 9.5h15M6 5h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2Z" />
    ),
    chart: (
      <>
        <path d="M5 19V9" />
        <path d="M12 19V5" />
        <path d="M19 19v-7" />
      </>
    ),
    lock: (
      <>
        <path d="M7 11V8a5 5 0 0 1 10 0v3" />
        <path d="M6 11h12v9H6z" />
      </>
    ),
    bell: (
      <>
        <path d="M18 15H6c1.2-1.1 1.5-2.7 1.5-5a4.5 4.5 0 0 1 9 0c0 2.3.3 3.9 1.5 5Z" />
        <path d="M10 18a2 2 0 0 0 4 0" />
      </>
    ),
    currency: (
      <>
        <path d="M12 3v18" />
        <path d="M16.5 7.5c-.8-1-2.2-1.6-4-1.6-2.3 0-4 .9-4 2.6 0 4.1 8.5 1.7 8.5 6.2 0 1.8-1.8 3.1-4.5 3.1-2 0-3.6-.6-4.6-1.8" />
      </>
    ),
    layers: (
      <>
        <path d="m12 3 8 4.5-8 4.5-8-4.5L12 3Z" />
        <path d="m4 12 8 4.5 8-4.5" />
        <path d="m4 16.5 8 4.5 8-4.5" />
      </>
    ),
  };

  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <g fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
        {icons[name]}
      </g>
    </svg>
  );
}

function useTheme() {
  const [theme, setTheme] = useState(() => {
    if (typeof window === "undefined") return "light";
    return localStorage.getItem("subpulse-landing-theme") || "light";
  });

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem("subpulse-landing-theme", theme);
  }, [theme]);

  return [theme, setTheme];
}

function useLanguage() {
  const [language, setLanguage] = useState(() => {
    if (typeof window === "undefined") return "en";
    return localStorage.getItem("subpulse-landing-language") || "en";
  });

  useEffect(() => {
    document.documentElement.lang = content[language]?.lang || "en";
    localStorage.setItem("subpulse-landing-language", language);
  }, [language]);

  return [language, setLanguage];
}

function useScrollReveal(refreshKey) {
  useEffect(() => {
    if (typeof window === "undefined") return undefined;

    const elements = Array.from(document.querySelectorAll("[data-reveal]"));
    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    if (reduceMotion || !("IntersectionObserver" in window)) {
      elements.forEach((element) => element.classList.add("is-visible"));
      return undefined;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        });
      },
      {
        threshold: 0.16,
        rootMargin: "0px 0px -8% 0px",
      }
    );

    elements.forEach((element) => {
      element.classList.remove("is-visible");
      observer.observe(element);
    });

    return () => observer.disconnect();
  }, [refreshKey]);
}

function makeId() {
  if (typeof crypto !== "undefined" && crypto.randomUUID) {
    return crypto.randomUUID();
  }

  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
}

function useSiteStats() {
  const [stats, setStats] = useState({
    downloads: null,
    online: null,
    recentUsers: [],
    totalVisitors: null,
  });

  useEffect(() => {
    if (typeof window === "undefined") return undefined;

    let visitorId = localStorage.getItem("subpulse-visitor-id");
    let sessionId = sessionStorage.getItem("subpulse-session-id");

    if (!visitorId) {
      visitorId = makeId();
      localStorage.setItem("subpulse-visitor-id", visitorId);
    }

    if (!sessionId) {
      sessionId = makeId();
      sessionStorage.setItem("subpulse-session-id", sessionId);
    }

    let cancelled = false;

    const ping = async () => {
      try {
        const response = await fetch("/api/metrics", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ visitorId, sessionId }),
        });

        if (!response.ok) return;

        const data = await response.json();
        if (!cancelled) {
          setStats({
            downloads: data.downloads,
            online: data.online,
            recentUsers: Array.isArray(data.recentUsers) ? data.recentUsers : [],
            totalVisitors: data.totalVisitors,
          });
        }
      } catch {
        // Static local previews do not run Netlify Functions. Production does.
      }
    };

    ping();
    const timer = window.setInterval(ping, 30000);

    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
  }, []);

  return stats;
}

function formatStat(value, language) {
  if (!Number.isFinite(value)) return "—";

  return new Intl.NumberFormat(language === "ru" ? "ru-RU" : "en-US").format(value);
}

function countryFlag(countryCode) {
  if (typeof countryCode !== "string" || !/^[A-Z]{2}$/.test(countryCode)) return "🌐";

  return countryCode
    .split("")
    .map((letter) => String.fromCodePoint(127397 + letter.charCodeAt(0)))
    .join("");
}

function recentUserFlags(users) {
  const flags = users.slice(0, 3).map((user) => ({
    flag: countryFlag(user.countryCode),
    label: user.countryName || user.countryCode || "Unknown",
  }));

  while (flags.length < 3) {
    flags.push({ flag: "•", label: "Waiting for visitor" });
  }

  return flags;
}

export default function App() {
  const [theme, setTheme] = useTheme();
  const [language, setLanguage] = useLanguage();
  const [active, setActive] = useState(0);
  const [selectedShot, setSelectedShot] = useState(null);
  const siteStats = useSiteStats();
  const t = content[language] || content.en;

  useScrollReveal(language);

  useEffect(() => {
    const timer = window.setInterval(() => {
      setActive((current) => (current + 1) % 3);
    }, 2400);
    return () => window.clearInterval(timer);
  }, []);

  const monthLabel = useMemo(() => t.monthLabels[active], [active, t]);
  const selectedGalleryItem = selectedShot === null ? null : {
    ...galleryAssets[selectedShot],
    ...t.galleryItems[selectedShot],
  };

  useEffect(() => {
    if (selectedShot === null) return undefined;
    const handleKeyDown = (event) => {
      if (event.key === "Escape") setSelectedShot(null);
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [selectedShot]);

  useEffect(() => {
    if (typeof window === "undefined") return undefined;

    const scrollToHash = () => {
      const id = window.location.hash.slice(1);
      if (!id) return;

      window.requestAnimationFrame(() => {
        document.getElementById(id)?.scrollIntoView({ block: "start" });
      });
    };

    scrollToHash();
    window.addEventListener("hashchange", scrollToHash);
    return () => window.removeEventListener("hashchange", scrollToHash);
  }, [language]);

  return (
    <main className="site-shell">
      <nav className="top-nav" aria-label={t.navLabel} data-reveal>
        <a className="brand" href="#top" aria-label="SubPulse home">
          <img src="/assets/subpulse-app-icon.png" alt="" />
          <span>SubPulse</span>
        </a>
        <div className="nav-links">
          <a href="#features">{t.nav[0]}</a>
          <a href="#interface">{t.nav[1]}</a>
          <a href="#privacy">{t.nav[2]}</a>
          <a href="#download">{t.nav[3]}</a>
        </div>
        <div className="nav-controls">
          <button
            className="language-toggle"
            type="button"
            onClick={() => setLanguage(language === "en" ? "ru" : "en")}
            aria-label={t.languageLabel}
          >
            <span className={language === "en" ? "active" : ""}>EN</span>
            <span className={language === "ru" ? "active" : ""}>RU</span>
          </button>
          <button
            className="theme-toggle"
            type="button"
            onClick={() => setTheme(theme === "light" ? "dark" : "light")}
            aria-label={t.themeLabel}
          >
            <span>{theme === "light" ? "Dark" : "Light"}</span>
            <i />
          </button>
        </div>
      </nav>

      <section className="hero" id="top">
        <div className="hero-copy" data-reveal style={{ "--reveal-delay": "80ms" }}>
          <h1>{t.heroTitle}</h1>
          <p>{t.heroText}</p>
          <div className="hero-actions">
            <a className="primary-action" href="/api/download">
              {t.primaryCta}
            </a>
            <a className="secondary-action" href="#interface">
              {t.secondaryCta}
            </a>
          </div>
          <div className="hero-notes" aria-label={t.notesLabel}>
            {t.notes.map((note) => (
              <span key={note}>{note}</span>
            ))}
          </div>
        </div>

        <div className="hero-stage" aria-label={t.heroShotLabel} data-reveal style={{ "--reveal-delay": "180ms" }}>
          <div className="pulse-orbit" />
          <div className="window-shot raised">
            <div className="window-bar">
              <span />
              <span />
              <span />
              <strong>SubPulse</strong>
            </div>
            <img src="/assets/subpulse-dashboard.png" alt={t.screenshotAlt} />
          </div>
          <div className="floating-card stat-card">
            <small>{monthLabel}</small>
            <strong>$112.98</strong>
            <span>{t.floatingForecast}</span>
          </div>
          <div className="floating-card calendar-card">
            <small>{t.nextRenewal}</small>
            <strong>iCloud+</strong>
            <span>$2.99 · Jun 22</span>
          </div>
        </div>
      </section>

      <section className="proof-strip" aria-label={t.sectionTitle}>
        {t.analytics.map(([value, label], index) => (
          <div className="proof-item" key={label} data-reveal style={{ "--reveal-delay": `${index * 80}ms` }}>
            <strong>{value}</strong>
            <span>{label}</span>
          </div>
        ))}
      </section>

      <section className="section-heading" id="features" data-reveal>
        <h2>{t.sectionTitle}</h2>
        <p>{t.sectionText}</p>
      </section>

      <section className="feature-grid">
        {t.features.map((feature, index) => (
          <article className="feature-card" key={feature.title} data-reveal style={{ "--reveal-delay": `${index * 70}ms` }}>
            <div className="icon-well">
              <Icon name={feature.icon} />
            </div>
            <h3>{feature.title}</h3>
            <p>{feature.text}</p>
          </article>
        ))}
      </section>

      <section className="interface-section" id="interface">
        <div className="interface-copy" data-reveal>
          <h2>{t.interfaceTitle}</h2>
          <p>{t.interfaceText}</p>
          <ul>
            {t.bullets.map((bullet) => (
              <li key={bullet}>{bullet}</li>
            ))}
          </ul>
        </div>
        <div className="interface-gallery" aria-label={t.galleryLabel}>
          {t.galleryItems.map((item, index) => (
            <button
              className="gallery-shot"
              type="button"
              key={item.title}
              onClick={() => setSelectedShot(index)}
              aria-label={`${t.galleryOpen}: ${item.title}`}
              data-reveal
              style={{ "--reveal-delay": `${index * 80}ms` }}
            >
              <img src={galleryAssets[index].thumb} alt={item.alt} loading="lazy" />
              <span>
                <strong>{item.title}</strong>
                <small>{item.text}</small>
              </span>
            </button>
          ))}
        </div>
      </section>

      {selectedGalleryItem && (
        <div
          className="gallery-lightbox"
          role="dialog"
          aria-modal="true"
          aria-label={selectedGalleryItem.title}
          onClick={() => setSelectedShot(null)}
        >
          <div className="gallery-lightbox-panel" onClick={(event) => event.stopPropagation()}>
            <button className="lightbox-close" type="button" onClick={() => setSelectedShot(null)}>
              {t.galleryClose}
            </button>
            <img src={selectedGalleryItem.full} alt={selectedGalleryItem.alt} />
            <div>
              <strong>{selectedGalleryItem.title}</strong>
              <span>{selectedGalleryItem.text}</span>
            </div>
          </div>
        </div>
      )}

      <section className="privacy-section" id="privacy">
        <div className="privacy-card" data-reveal>
          <h2>{t.privacyTitle}</h2>
          <p>{t.privacyText}</p>
        </div>
        <div className="privacy-steps">
          {t.steps.map(([number, title, text], index) => (
            <div key={number} data-reveal style={{ "--reveal-delay": `${index * 80}ms` }}><span>{number}</span><strong>{title}</strong><small>{text}</small></div>
          ))}
        </div>
      </section>

      <section className="download-section" id="download" data-reveal>
        <div className="download-icon-badge">
          <span aria-hidden="true" />
          <img src="/assets/subpulse-app-icon.png" alt={t.downloadAlt} />
        </div>
        <h2>{t.downloadTitle}</h2>
        <p>{t.downloadText}</p>
        <a className="primary-action" href="/api/download">
          {t.downloadCta}
        </a>
      </section>

      <section className="faq-section" aria-label={t.faqLabel}>
        {t.faqs.map((item, index) => (
          <details key={item.q} data-reveal style={{ "--reveal-delay": `${index * 60}ms` }}>
            <summary>{item.q}</summary>
            <p>{item.a}</p>
          </details>
        ))}
      </section>

      <footer>
        <div className="footer-main">
          <span>SubPulse</span>
          <div className="site-stats" aria-label={t.statsLabel}>
            <span>
              <strong>{formatStat(siteStats.downloads, language)}</strong>
              <small>{t.stats.downloads}</small>
            </span>
            <span>
              <strong>{formatStat(siteStats.online, language)}</strong>
              <small>{t.stats.online}</small>
            </span>
            <span className="recent-users-card">
              <strong className="recent-flags" aria-label={t.stats.recentUsers}>
                {recentUserFlags(siteStats.recentUsers).map((user, index) => (
                  <b key={`${user.label}-${index}`} title={user.label}>
                    {user.flag}
                  </b>
                ))}
              </strong>
              <small>{t.stats.recentUsers}</small>
            </span>
            <span>
              <strong>{formatStat(siteStats.totalVisitors, language)}</strong>
              <small>{t.stats.totalVisitors}</small>
            </span>
          </div>
          <span>{t.footerDev}</span>
        </div>
        <small className="rights-line">© {new Date().getFullYear()} SubPulse. {t.rights}</small>
      </footer>
    </main>
  );
}
