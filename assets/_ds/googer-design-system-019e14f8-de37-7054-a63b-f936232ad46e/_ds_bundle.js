/* @ds-bundle: {"format":4,"namespace":"GoogerDesignSystem_019e14","components":[],"sourceHashes":{"mobile/android-frame.jsx":"26b6e42067a7","mobile/ios-frame.jsx":"d67eb3ffe562","mobile/screens.jsx":"479b639d0a17","ui_kits/auth/LoginForm.jsx":"67f0f3c4c129","ui_kits/auth/ResetModal.jsx":"24def992b1f1","ui_kits/feed/Composer.jsx":"65f271ee538f","ui_kits/feed/GoogCard.jsx":"a58c2b6a94ad","ui_kits/feed/Topbar.jsx":"33bf4775b9b2","ui_kits/shop/CartSidebar.jsx":"1d5020ebfdde","ui_kits/shop/ProductCard.jsx":"7fdc51e8bd85","ui_kits/wallet/BalanceCard.jsx":"8213eacf3946","ui_kits/wallet/TransactionRow.jsx":"7c7b35eba0ee"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.GoogerDesignSystem_019e14 = window.GoogerDesignSystem_019e14 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// mobile/android-frame.jsx
try { (() => {
// Android.jsx — Simplified Android (Material 3) device frame
// Status bar + top app bar + content + gesture nav + keyboard.
// Based on Figma M3 spec. No dependencies, no image assets.

const MD_C = {
  surface: '#f4fbf8',
  surfaceVariant: '#dae5e1',
  inverseOnSurface: '#ecf2ef',
  secondaryContainer: '#cde8e1',
  primaryFixedDim: '#83d5c6',
  onSurface: '#171d1b',
  onSurfaceVar: '#49454f',
  onPrimaryContainer: '#00201c',
  primary: '#006a60',
  frameBorder: 'rgba(116,119,117,0.5)'
};

// ─────────────────────────────────────────────────────────────
// Status bar (time left, wifi/cell/battery right)
// ─────────────────────────────────────────────────────────────
function AndroidStatusBar({
  dark = false
}) {
  const c = dark ? '#fff' : MD_C.onSurface;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: 40,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 16px',
      position: 'relative',
      fontFamily: 'Roboto, system-ui, sans-serif'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 128,
      display: 'flex',
      alignItems: 'center',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 14,
      fontWeight: 400,
      letterSpacing: 0.25,
      lineHeight: '20px',
      color: c
    }
  }, "9:30")), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: '50%',
      top: 8,
      transform: 'translateX(-50%)',
      width: 24,
      height: 24,
      borderRadius: 100,
      background: '#2e2e2e'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      paddingRight: 2
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "16",
    height: "16",
    viewBox: "0 0 16 16",
    style: {
      marginRight: -2
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M8 13.3L.67 5.97a10.37 10.37 0 0114.66 0L8 13.3z",
    fill: c
  })), /*#__PURE__*/React.createElement("svg", {
    width: "16",
    height: "16",
    viewBox: "0 0 16 16",
    style: {
      marginRight: -2
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M14.67 14.67V1.33L1.33 14.67h13.34z",
    fill: c
  }))), /*#__PURE__*/React.createElement("svg", {
    width: "16",
    height: "16",
    viewBox: "0 0 16 16"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "3.75",
    y: "2",
    width: "8.5",
    height: "13",
    rx: "1.5",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "5.5",
    y: "0.9",
    width: "5",
    height: "2",
    rx: "0.5",
    fill: c
  }))));
}

// ─────────────────────────────────────────────────────────────
// Top app bar (Material 3 small/medium)
// ─────────────────────────────────────────────────────────────
function AndroidAppBar({
  title = 'Title',
  large = false
}) {
  const iconDot = /*#__PURE__*/React.createElement("div", {
    style: {
      width: 48,
      height: 48,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 22,
      height: 22,
      borderRadius: '50%',
      background: MD_C.onSurfaceVar,
      opacity: 0.3
    }
  }));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      background: MD_C.surface,
      padding: '4px 4px 0'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 56,
      display: 'flex',
      alignItems: 'center',
      gap: 4
    }
  }, iconDot, !large && /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      fontSize: 22,
      fontWeight: 400,
      color: MD_C.onSurface,
      fontFamily: 'Roboto, system-ui, sans-serif'
    }
  }, title), large && /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }), iconDot), large && /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '16px 16px 20px',
      fontSize: 28,
      fontWeight: 400,
      color: MD_C.onSurface,
      fontFamily: 'Roboto, system-ui, sans-serif'
    }
  }, title));
}

// ─────────────────────────────────────────────────────────────
// List item (Material 3)
// ─────────────────────────────────────────────────────────────
function AndroidListItem({
  headline,
  supporting,
  leading
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 16,
      padding: '12px 16px',
      minHeight: 56,
      boxSizing: 'border-box',
      fontFamily: 'Roboto, system-ui, sans-serif'
    }
  }, leading && /*#__PURE__*/React.createElement("div", {
    style: {
      width: 40,
      height: 40,
      borderRadius: '50%',
      background: MD_C.primary,
      color: '#fff',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontSize: 18,
      fontWeight: 500,
      flexShrink: 0
    }
  }, leading), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 16,
      color: MD_C.onSurface,
      lineHeight: '24px'
    }
  }, headline), supporting && /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 14,
      color: MD_C.onSurfaceVar,
      lineHeight: '20px'
    }
  }, supporting)));
}

// ─────────────────────────────────────────────────────────────
// Gesture nav bar (pill)
// ─────────────────────────────────────────────────────────────
function AndroidNavBar({
  dark = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: 24,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 108,
      height: 4,
      borderRadius: 2,
      background: dark ? '#fff' : MD_C.onSurface,
      opacity: 0.4
    }
  }));
}

// ─────────────────────────────────────────────────────────────
// Device frame — wraps everything
// ─────────────────────────────────────────────────────────────
function AndroidDevice({
  children,
  width = 412,
  height = 892,
  dark = false,
  title,
  large = false,
  keyboard = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width,
      height,
      borderRadius: 18,
      overflow: 'hidden',
      background: dark ? '#1d1b20' : MD_C.surface,
      border: `8px solid ${MD_C.frameBorder}`,
      boxShadow: '0 30px 80px rgba(0,0,0,0.25)',
      display: 'flex',
      flexDirection: 'column',
      boxSizing: 'border-box'
    }
  }, /*#__PURE__*/React.createElement(AndroidStatusBar, {
    dark: dark
  }), title !== undefined && /*#__PURE__*/React.createElement(AndroidAppBar, {
    title: title,
    large: large
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflow: 'auto'
    }
  }, children), keyboard && /*#__PURE__*/React.createElement(AndroidKeyboard, null), /*#__PURE__*/React.createElement(AndroidNavBar, {
    dark: dark
  }));
}

// ─────────────────────────────────────────────────────────────
// Keyboard — Gboard (Material 3)
// ─────────────────────────────────────────────────────────────
function AndroidKeyboard() {
  let _k = 0;
  const key = (l, {
    flex = 1,
    bg = MD_C.surface,
    r = 6,
    minW,
    fs = 21
  } = {}) => /*#__PURE__*/React.createElement("div", {
    key: _k++,
    style: {
      height: 46,
      borderRadius: r,
      flex,
      minWidth: minW,
      background: bg,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'Roboto, system-ui',
      fontSize: fs,
      color: MD_C.onPrimaryContainer
    }
  }, l);
  const row = (keys, style = {}) => /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      justifyContent: 'center',
      ...style
    }
  }, keys.map(l => key(l)));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      background: MD_C.inverseOnSurface,
      padding: '0 8px 8px',
      display: 'flex',
      flexDirection: 'column',
      gap: 4
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 44
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 12
    }
  }, row(['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']), row(['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'], {
    padding: '0 20px'
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6
    }
  }, key('', {
    bg: MD_C.surfaceVariant
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      flex: 7,
      minWidth: 274
    }
  }, ['z', 'x', 'c', 'v', 'b', 'n', 'm'].map(l => key(l))), key('', {
    bg: MD_C.surfaceVariant
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6
    }
  }, key('?123', {
    bg: MD_C.secondaryContainer,
    r: 100,
    minW: 58,
    fs: 14
  }), key(',', {
    bg: MD_C.surfaceVariant
  }), key('', {
    flex: 3,
    minW: 154
  }), key('.', {
    bg: MD_C.surfaceVariant
  }), key('', {
    bg: MD_C.primaryFixedDim,
    r: 100,
    minW: 58
  }))));
}
Object.assign(window, {
  AndroidDevice,
  AndroidStatusBar,
  AndroidAppBar,
  AndroidListItem,
  AndroidNavBar,
  AndroidKeyboard
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "mobile/android-frame.jsx", error: String((e && e.message) || e) }); }

// mobile/ios-frame.jsx
try { (() => {
// iOS.jsx — Simplified iOS 26 (Liquid Glass) device frame
// Based on the iOS 26 UI Kit + Figma status bar spec. No assets, no deps.
// Exports: IOSDevice, IOSStatusBar, IOSNavBar, IOSGlassPill, IOSList, IOSListRow, IOSKeyboard

// ─────────────────────────────────────────────────────────────
// Status bar
// ─────────────────────────────────────────────────────────────
function IOSStatusBar({
  dark = false,
  time = '9:41'
}) {
  const c = dark ? '#fff' : '#000';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 154,
      alignItems: 'center',
      justifyContent: 'center',
      padding: '21px 24px 19px',
      boxSizing: 'border-box',
      position: 'relative',
      zIndex: 20,
      width: '100%'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 22,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      paddingTop: 1.5
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 590,
      fontSize: 17,
      lineHeight: '22px',
      color: c
    }
  }, time)), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 22,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 7,
      paddingTop: 1,
      paddingRight: 1
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "19",
    height: "12",
    viewBox: "0 0 19 12"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0",
    y: "7.5",
    width: "3.2",
    height: "4.5",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "4.8",
    y: "5",
    width: "3.2",
    height: "7",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "9.6",
    y: "2.5",
    width: "3.2",
    height: "9.5",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "14.4",
    y: "0",
    width: "3.2",
    height: "12",
    rx: "0.7",
    fill: c
  })), /*#__PURE__*/React.createElement("svg", {
    width: "17",
    height: "12",
    viewBox: "0 0 17 12"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M8.5 3.2C10.8 3.2 12.9 4.1 14.4 5.6L15.5 4.5C13.7 2.7 11.2 1.5 8.5 1.5C5.8 1.5 3.3 2.7 1.5 4.5L2.6 5.6C4.1 4.1 6.2 3.2 8.5 3.2Z",
    fill: c
  }), /*#__PURE__*/React.createElement("path", {
    d: "M8.5 6.8C9.9 6.8 11.1 7.3 12 8.2L13.1 7.1C11.8 5.9 10.2 5.1 8.5 5.1C6.8 5.1 5.2 5.9 3.9 7.1L5 8.2C5.9 7.3 7.1 6.8 8.5 6.8Z",
    fill: c
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "8.5",
    cy: "10.5",
    r: "1.5",
    fill: c
  })), /*#__PURE__*/React.createElement("svg", {
    width: "27",
    height: "13",
    viewBox: "0 0 27 13"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0.5",
    y: "0.5",
    width: "23",
    height: "12",
    rx: "3.5",
    stroke: c,
    strokeOpacity: "0.35",
    fill: "none"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "2",
    y: "2",
    width: "20",
    height: "9",
    rx: "2",
    fill: c
  }), /*#__PURE__*/React.createElement("path", {
    d: "M25 4.5V8.5C25.8 8.2 26.5 7.2 26.5 6.5C26.5 5.8 25.8 4.8 25 4.5Z",
    fill: c,
    fillOpacity: "0.4"
  }))));
}

// ─────────────────────────────────────────────────────────────
// Liquid glass pill — blur + tint + shine
// ─────────────────────────────────────────────────────────────
function IOSGlassPill({
  children,
  dark = false,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: 44,
      minWidth: 44,
      borderRadius: 9999,
      position: 'relative',
      overflow: 'hidden',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      boxShadow: dark ? '0 2px 6px rgba(0,0,0,0.35), 0 6px 16px rgba(0,0,0,0.2)' : '0 1px 3px rgba(0,0,0,0.07), 0 3px 10px rgba(0,0,0,0.06)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 9999,
      backdropFilter: 'blur(12px) saturate(180%)',
      WebkitBackdropFilter: 'blur(12px) saturate(180%)',
      background: dark ? 'rgba(120,120,128,0.28)' : 'rgba(255,255,255,0.5)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 9999,
      boxShadow: dark ? 'inset 1.5px 1.5px 1px rgba(255,255,255,0.15), inset -1px -1px 1px rgba(255,255,255,0.08)' : 'inset 1.5px 1.5px 1px rgba(255,255,255,0.7), inset -1px -1px 1px rgba(255,255,255,0.4)',
      border: dark ? '0.5px solid rgba(255,255,255,0.15)' : '0.5px solid rgba(0,0,0,0.06)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 1,
      display: 'flex',
      alignItems: 'center',
      padding: '0 4px'
    }
  }, children));
}

// ─────────────────────────────────────────────────────────────
// Navigation bar — glass pills + large title
// ─────────────────────────────────────────────────────────────
function IOSNavBar({
  title = 'Title',
  dark = false,
  trailingIcon = true
}) {
  const muted = dark ? 'rgba(255,255,255,0.6)' : '#404040';
  const text = dark ? '#fff' : '#000';
  const pillIcon = content => /*#__PURE__*/React.createElement(IOSGlassPill, {
    dark: dark
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 36,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, content));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 10,
      paddingTop: 62,
      paddingBottom: 10,
      position: 'relative',
      zIndex: 5
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 16px'
    }
  }, pillIcon(/*#__PURE__*/React.createElement("svg", {
    width: "12",
    height: "20",
    viewBox: "0 0 12 20",
    fill: "none",
    style: {
      marginLeft: -1
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M10 2L2 10l8 8",
    stroke: muted,
    strokeWidth: "2.5",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }))), trailingIcon && pillIcon(/*#__PURE__*/React.createElement("svg", {
    width: "22",
    height: "6",
    viewBox: "0 0 22 6"
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "3",
    cy: "3",
    r: "2.5",
    fill: muted
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "11",
    cy: "3",
    r: "2.5",
    fill: muted
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "19",
    cy: "3",
    r: "2.5",
    fill: muted
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 16px',
      fontFamily: '-apple-system, system-ui',
      fontSize: 34,
      fontWeight: 700,
      lineHeight: '41px',
      color: text,
      letterSpacing: 0.4
    }
  }, title));
}

// ─────────────────────────────────────────────────────────────
// Grouped list (inset card, r:26) + row (52px)
// ─────────────────────────────────────────────────────────────
function IOSListRow({
  title,
  detail,
  icon,
  chevron = true,
  isLast = false,
  dark = false
}) {
  const text = dark ? '#fff' : '#000';
  const sec = dark ? 'rgba(235,235,245,0.6)' : 'rgba(60,60,67,0.6)';
  const ter = dark ? 'rgba(235,235,245,0.3)' : 'rgba(60,60,67,0.3)';
  const sep = dark ? 'rgba(84,84,88,0.65)' : 'rgba(60,60,67,0.12)';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      minHeight: 52,
      padding: '0 16px',
      position: 'relative',
      fontFamily: '-apple-system, system-ui',
      fontSize: 17,
      letterSpacing: -0.43
    }
  }, icon && /*#__PURE__*/React.createElement("div", {
    style: {
      width: 30,
      height: 30,
      borderRadius: 7,
      background: icon,
      marginRight: 12,
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      color: text
    }
  }, title), detail && /*#__PURE__*/React.createElement("span", {
    style: {
      color: sec,
      marginRight: 6
    }
  }, detail), chevron && /*#__PURE__*/React.createElement("svg", {
    width: "8",
    height: "14",
    viewBox: "0 0 8 14",
    style: {
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M1 1l6 6-6 6",
    stroke: ter,
    strokeWidth: "2",
    fill: "none",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  })), !isLast && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      right: 0,
      left: icon ? 58 : 16,
      height: 0.5,
      background: sep
    }
  }));
}
function IOSList({
  header,
  children,
  dark = false
}) {
  const hc = dark ? 'rgba(235,235,245,0.6)' : 'rgba(60,60,67,0.6)';
  const bg = dark ? '#1C1C1E' : '#fff';
  return /*#__PURE__*/React.createElement("div", null, header && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: '-apple-system, system-ui',
      fontSize: 13,
      color: hc,
      textTransform: 'uppercase',
      padding: '8px 36px 6px',
      letterSpacing: -0.08
    }
  }, header), /*#__PURE__*/React.createElement("div", {
    style: {
      background: bg,
      borderRadius: 26,
      margin: '0 16px',
      overflow: 'hidden'
    }
  }, children));
}

// ─────────────────────────────────────────────────────────────
// Device frame
// ─────────────────────────────────────────────────────────────
function IOSDevice({
  children,
  width = 402,
  height = 874,
  dark = false,
  title,
  keyboard = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width,
      height,
      borderRadius: 48,
      overflow: 'hidden',
      position: 'relative',
      background: dark ? '#000' : '#F2F2F7',
      boxShadow: '0 40px 80px rgba(0,0,0,0.18), 0 0 0 1px rgba(0,0,0,0.12)',
      fontFamily: '-apple-system, system-ui, sans-serif',
      WebkitFontSmoothing: 'antialiased'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 11,
      left: '50%',
      transform: 'translateX(-50%)',
      width: 126,
      height: 37,
      borderRadius: 24,
      background: '#000',
      zIndex: 50
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      zIndex: 10
    }
  }, /*#__PURE__*/React.createElement(IOSStatusBar, {
    dark: dark
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      display: 'flex',
      flexDirection: 'column'
    }
  }, title !== undefined && /*#__PURE__*/React.createElement(IOSNavBar, {
    title: title,
    dark: dark
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflow: 'auto'
    }
  }, children), keyboard && /*#__PURE__*/React.createElement(IOSKeyboard, {
    dark: dark
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      left: 0,
      right: 0,
      zIndex: 60,
      height: 34,
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'flex-end',
      paddingBottom: 8,
      pointerEvents: 'none'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 139,
      height: 5,
      borderRadius: 100,
      background: dark ? 'rgba(255,255,255,0.7)' : 'rgba(0,0,0,0.25)'
    }
  })));
}

// ─────────────────────────────────────────────────────────────
// Keyboard — iOS 26 liquid glass
// ─────────────────────────────────────────────────────────────
function IOSKeyboard({
  dark = false
}) {
  const glyph = dark ? 'rgba(255,255,255,0.7)' : '#595959';
  const sugg = dark ? 'rgba(255,255,255,0.6)' : '#333';
  const keyBg = dark ? 'rgba(255,255,255,0.22)' : 'rgba(255,255,255,0.85)';

  // special-key icons
  const icons = {
    shift: /*#__PURE__*/React.createElement("svg", {
      width: "19",
      height: "17",
      viewBox: "0 0 19 17"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M9.5 1L1 9.5h4.5V16h8V9.5H18L9.5 1z",
      fill: glyph
    })),
    del: /*#__PURE__*/React.createElement("svg", {
      width: "23",
      height: "17",
      viewBox: "0 0 23 17"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M7 1h13a2 2 0 012 2v11a2 2 0 01-2 2H7l-6-7.5L7 1z",
      fill: "none",
      stroke: glyph,
      strokeWidth: "1.6",
      strokeLinejoin: "round"
    }), /*#__PURE__*/React.createElement("path", {
      d: "M10 5l7 7M17 5l-7 7",
      stroke: glyph,
      strokeWidth: "1.6",
      strokeLinecap: "round"
    })),
    ret: /*#__PURE__*/React.createElement("svg", {
      width: "20",
      height: "14",
      viewBox: "0 0 20 14"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M18 1v6H4m0 0l4-4M4 7l4 4",
      fill: "none",
      stroke: "#fff",
      strokeWidth: "1.8",
      strokeLinecap: "round",
      strokeLinejoin: "round"
    }))
  };
  const key = (content, {
    w,
    flex,
    ret,
    fs = 25,
    k
  } = {}) => /*#__PURE__*/React.createElement("div", {
    key: k,
    style: {
      height: 42,
      borderRadius: 8.5,
      flex: flex ? 1 : undefined,
      width: w,
      minWidth: 0,
      background: ret ? '#08f' : keyBg,
      boxShadow: '0 1px 0 rgba(0,0,0,0.075)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: '-apple-system, "SF Compact", system-ui',
      fontSize: fs,
      fontWeight: 458,
      color: ret ? '#fff' : glyph
    }
  }, content);
  const row = (keys, pad = 0) => /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6.5,
      justifyContent: 'center',
      padding: `0 ${pad}px`
    }
  }, keys.map(l => key(l, {
    flex: true,
    k: l
  })));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 15,
      borderRadius: 27,
      overflow: 'hidden',
      padding: '11px 0 2px',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      boxShadow: dark ? '0 -2px 20px rgba(0,0,0,0.09)' : '0 -1px 6px rgba(0,0,0,0.018), 0 -3px 20px rgba(0,0,0,0.012)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 27,
      backdropFilter: 'blur(12px) saturate(180%)',
      WebkitBackdropFilter: 'blur(12px) saturate(180%)',
      background: dark ? 'rgba(120,120,128,0.14)' : 'rgba(255,255,255,0.25)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 27,
      boxShadow: dark ? 'inset 1.5px 1.5px 1px rgba(255,255,255,0.15)' : 'inset 1.5px 1.5px 1px rgba(255,255,255,0.7), inset -1px -1px 1px rgba(255,255,255,0.4)',
      border: dark ? '0.5px solid rgba(255,255,255,0.15)' : '0.5px solid rgba(0,0,0,0.06)',
      pointerEvents: 'none'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 20,
      alignItems: 'center',
      padding: '8px 22px 13px',
      width: '100%',
      boxSizing: 'border-box',
      position: 'relative'
    }
  }, ['"The"', 'the', 'to'].map((w, i) => /*#__PURE__*/React.createElement(React.Fragment, {
    key: i
  }, i > 0 && /*#__PURE__*/React.createElement("div", {
    style: {
      width: 1,
      height: 25,
      background: '#ccc',
      opacity: 0.3
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      textAlign: 'center',
      fontFamily: '-apple-system, system-ui',
      fontSize: 17,
      color: sugg,
      letterSpacing: -0.43,
      lineHeight: '22px'
    }
  }, w)))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 13,
      padding: '0 6.5px',
      width: '100%',
      boxSizing: 'border-box',
      position: 'relative'
    }
  }, row(['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']), row(['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'], 20), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14.25,
      alignItems: 'center'
    }
  }, key(icons.shift, {
    w: 45,
    k: 'shift'
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6.5,
      flex: 1
    }
  }, ['z', 'x', 'c', 'v', 'b', 'n', 'm'].map(l => key(l, {
    flex: true,
    k: l
  }))), key(icons.del, {
    w: 45,
    k: 'del'
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      alignItems: 'center'
    }
  }, key('ABC', {
    w: 92.25,
    fs: 18,
    k: 'abc'
  }), key('', {
    flex: true,
    k: 'space'
  }), key(icons.ret, {
    w: 92.25,
    ret: true,
    k: 'ret'
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 56,
      width: '100%',
      position: 'relative'
    }
  }));
}
Object.assign(window, {
  IOSDevice,
  IOSStatusBar,
  IOSNavBar,
  IOSGlassPill,
  IOSList,
  IOSListRow,
  IOSKeyboard
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "mobile/ios-frame.jsx", error: String((e && e.message) || e) }); }

// mobile/screens.jsx
try { (() => {
// Googer mobile screens — faithful port of the web app's responsive mobile view.
// Sourced from Sandil10/googernew@main: app/page.tsx, app/dashboard/layout.tsx,
// app/components/Topbar.tsx, app/components/googs/GoogCard.tsx, app/dashboard/wallet/page.tsx.
// Styles (colors, spacing, font sizes, classes) preserved verbatim from the codebase.

const FONT = '-apple-system, "Segoe UI", Roboto, system-ui, sans-serif';
const MONO = 'ui-monospace, "SFMono-Regular", Menlo, monospace';
function Ion({
  name,
  size = 18,
  color = 'currentColor',
  style
}) {
  return /*#__PURE__*/React.createElement("ion-icon", {
    name: name,
    style: {
      fontSize: size,
      color,
      ...style
    }
  });
}

// ─── Topbar (mobile slice of Topbar.tsx — h-16, blur, no center nav) ─────────
function Topbar({
  pageTitle = 'Googer'
}) {
  return /*#__PURE__*/React.createElement("header", {
    style: {
      position: 'sticky',
      top: 0,
      zIndex: 50,
      height: 64,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      borderBottom: '1px solid #27272a',
      background: 'rgba(24,24,27,0.80)',
      backdropFilter: 'blur(12px)',
      padding: '0 16px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 32,
      height: 32,
      borderRadius: 9999,
      overflow: 'hidden',
      border: '1px solid rgba(255,255,255,0.10)',
      position: 'relative'
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: "../assets/googer.png",
    alt: "Googer Logo",
    style: {
      width: '100%',
      height: '100%',
      objectFit: 'contain'
    }
  })), /*#__PURE__*/React.createElement("h1", {
    style: {
      fontSize: 20,
      fontWeight: 700,
      letterSpacing: '-0.02em',
      color: '#fff',
      margin: 0
    }
  }, pageTitle)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 4
    }
  }, /*#__PURE__*/React.createElement("button", {
    style: {
      width: 36,
      height: 36,
      borderRadius: 9999,
      background: 'transparent',
      border: 0,
      color: '#9ca3af',
      position: 'relative',
      display: 'grid',
      placeItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: "cart-outline",
    size: 20,
    color: "#9ca3af"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: -4,
      right: -4,
      width: 16,
      height: 16,
      background: '#3b82f6',
      color: '#fff',
      fontSize: 9,
      fontWeight: 900,
      borderRadius: 9999,
      border: '2px solid #18181b',
      display: 'grid',
      placeItems: 'center'
    }
  }, "3")), /*#__PURE__*/React.createElement("button", {
    style: {
      width: 36,
      height: 36,
      borderRadius: 9999,
      background: 'transparent',
      border: 0,
      color: '#9ca3af',
      position: 'relative',
      display: 'grid',
      placeItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: "notifications-outline",
    size: 20,
    color: "#9ca3af"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: 6,
      right: 6,
      width: 8,
      height: 8,
      background: '#ec4899',
      borderRadius: 9999,
      border: '2px solid #18181b'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      marginLeft: 8,
      width: 36,
      height: 36,
      borderRadius: 9999,
      overflow: 'hidden',
      border: '2px solid rgba(255,255,255,0.10)',
      background: '#1e293b',
      display: 'grid',
      placeItems: 'center',
      color: '#94a3b8'
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: "person-outline",
    size: 16,
    color: "#94a3b8"
  }))));
}

// ─── Mobile bottom nav (verbatim from app/dashboard/layout.tsx) ──────────────
function BottomNav({
  active = 'home'
}) {
  const items = [{
    id: 'home',
    icon: 'home',
    label: 'Home'
  }, {
    id: 'shop',
    icon: 'bag',
    label: 'Shop'
  }, {
    id: 'add',
    icon: 'add-circle',
    label: 'Add',
    isCreate: true
  }, {
    id: 'wallet',
    icon: 'wallet',
    label: 'Wallet'
  }, {
    id: 'chats',
    icon: 'chatbubbles',
    label: 'Chats'
  }];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'sticky',
      bottom: 0,
      height: 64,
      background: '#18181b',
      borderTop: '1px solid #27272a',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-around',
      zIndex: 50,
      padding: '0 8px'
    }
  }, items.map(it => {
    const isActive = it.id === active;
    if (it.isCreate) {
      return /*#__PURE__*/React.createElement("button", {
        key: it.id,
        style: {
          background: 'transparent',
          border: 0,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          padding: 0
        }
      }, /*#__PURE__*/React.createElement("div", {
        style: {
          width: 40,
          height: 40,
          borderRadius: 12,
          background: 'rgba(255,255,255,0.05)',
          display: 'grid',
          placeItems: 'center',
          color: '#9ca3af'
        }
      }, /*#__PURE__*/React.createElement(Ion, {
        name: "add-circle",
        size: 24,
        color: "#9ca3af"
      })), /*#__PURE__*/React.createElement("span", {
        style: {
          fontSize: 10,
          marginTop: 4,
          fontWeight: 500,
          color: '#6b7280',
          textTransform: 'uppercase',
          letterSpacing: '0.1em'
        }
      }, "Add"));
    }
    return /*#__PURE__*/React.createElement("div", {
      key: it.id,
      style: {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 8,
        color: isActive ? '#fff' : '#6b7280'
      }
    }, /*#__PURE__*/React.createElement(Ion, {
      name: isActive ? it.icon : it.icon + '-outline',
      size: 24,
      color: isActive ? '#fff' : '#6b7280'
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 10,
        marginTop: 4,
        fontWeight: 500
      }
    }, it.label));
  }));
}

// ─── Page chrome ────────────────────────────────────────────────────────────
function Shell({
  children,
  active,
  title
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      background: '#1c1917',
      color: '#fff',
      fontFamily: FONT
    }
  }, /*#__PURE__*/React.createElement(Topbar, {
    pageTitle: title
  }), /*#__PURE__*/React.createElement("main", {
    style: {
      flex: 1,
      overflow: 'auto',
      padding: '20px 12px 16px'
    }
  }, children), /*#__PURE__*/React.createElement(BottomNav, {
    active: active
  }));
}

// ─── 1. Login (verbatim from app/page.tsx) ──────────────────────────────────
function LoginScreen() {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      minHeight: '100%',
      background: '#000',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
      alignItems: 'center',
      padding: '48px 16px',
      fontFamily: FONT,
      color: '#fff'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: 448,
      width: '100%'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      background: '#000',
      padding: 32,
      borderRadius: 24,
      border: '1px solid rgba(168,85,247,0.20)',
      boxShadow: '0 0 50px -12px rgba(168,85,247,0.1)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      marginBottom: 24
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: "../assets/googer.png",
    alt: "Googer Logo",
    width: 80,
    height: 80,
    style: {
      objectFit: 'contain'
    }
  })), /*#__PURE__*/React.createElement("form", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement("input", {
    placeholder: "Enter Email",
    defaultValue: "mira@googer.app",
    style: {
      width: '100%',
      padding: '12px 16px',
      borderRadius: 12,
      border: '1px solid #1f2937',
      background: '#121212',
      color: '#fff',
      fontSize: 14,
      fontFamily: FONT,
      outline: 'none',
      boxSizing: 'border-box'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative'
    }
  }, /*#__PURE__*/React.createElement("input", {
    type: "password",
    placeholder: "Enter Password",
    defaultValue: "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022",
    style: {
      width: '100%',
      padding: '12px 16px',
      paddingRight: 48,
      borderRadius: 12,
      border: '1px solid #1f2937',
      background: '#121212',
      color: '#fff',
      fontSize: 14,
      fontFamily: FONT,
      outline: 'none',
      boxSizing: 'border-box'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      right: 12,
      top: '50%',
      transform: 'translateY(-50%)',
      color: '#6b7280',
      display: 'grid',
      placeItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: "eye-off-outline",
    size: 20,
    color: "#6b7280"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'right',
      padding: '0 4px'
    }
  }, /*#__PURE__*/React.createElement("button", {
    type: "button",
    style: {
      background: 'transparent',
      border: 0,
      color: '#c084fc',
      fontSize: 12,
      fontWeight: 300
    }
  }, "Forgot password?")), /*#__PURE__*/React.createElement("button", {
    type: "submit",
    style: {
      fontWeight: 700,
      width: '100%',
      borderRadius: 9999,
      background: '#fff',
      color: '#000',
      padding: '12px 16px',
      border: 0,
      boxShadow: '0 10px 15px -3px rgba(0,0,0,0.5)',
      fontSize: 14,
      marginTop: 8,
      fontFamily: FONT
    }
  }, "Login"), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      marginTop: 16
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: '#6b7280',
      fontSize: 12,
      textDecoration: 'underline',
      textDecorationColor: '#1f2937',
      textUnderlineOffset: 4
    }
  }, "Don't have an account? \u2014 "), /*#__PURE__*/React.createElement("span", {
    style: {
      color: '#c084fc',
      fontSize: 12,
      fontWeight: 700,
      marginLeft: 4
    }
  }, "Register"))))));
}

// ─── 2. Feed — GoogCard verbatim from app/components/googs/GoogCard.tsx ─────
function GoogCard({
  name,
  time,
  text,
  likes,
  comments,
  views,
  shares,
  liked
}) {
  return /*#__PURE__*/React.createElement("article", {
    style: {
      borderBottom: '1px solid rgba(255,255,255,0.10)',
      padding: '20px 20px',
      transition: 'background 200ms'
    }
  }, /*#__PURE__*/React.createElement("header", {
    style: {
      display: 'flex',
      alignItems: 'flex-start',
      justifyContent: 'space-between',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      minWidth: 0,
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      height: 40,
      width: 40,
      flexShrink: 0,
      overflow: 'hidden',
      borderRadius: 9999,
      background: 'rgba(255,255,255,0.10)',
      display: 'grid',
      placeItems: 'center',
      fontWeight: 900,
      color: '#fff',
      fontSize: 13
    }
  }, name[0]), /*#__PURE__*/React.createElement("div", {
    style: {
      minWidth: 0,
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      minWidth: 0,
      alignItems: 'center',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      fontWeight: 900,
      color: '#fff'
    }
  }, name), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      color: 'rgba(255,255,255,0.35)'
    }
  }, time)), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 6,
      whiteSpace: 'pre-wrap',
      wordBreak: 'break-word',
      fontSize: 14,
      lineHeight: '24px',
      color: '#fff'
    }
  }, text), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16,
      display: 'flex',
      alignItems: 'center',
      gap: 20,
      color: 'rgba(255,255,255,0.80)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 4
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: liked ? 'heart' : 'heart-outline',
    size: 21,
    color: liked ? '#ef4444' : '#fff'
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 9,
      fontWeight: 900,
      letterSpacing: '-0.05em'
    }
  }, likes)), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 4
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: "chatbubble-outline",
    size: 21,
    color: "#fff"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 9,
      fontWeight: 900,
      letterSpacing: '-0.05em'
    }
  }, comments)), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 4
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: "eye-outline",
    size: 21,
    color: "#fff"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 9,
      fontWeight: 900,
      letterSpacing: '-0.05em'
    }
  }, views)), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 4
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: "share-social-outline",
    size: 21,
    color: "#fff"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 9,
      fontWeight: 900,
      letterSpacing: '-0.05em'
    }
  }, shares))))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexShrink: 0,
      alignItems: 'center',
      gap: 4
    }
  }, /*#__PURE__*/React.createElement("button", {
    style: {
      padding: '4px 10px',
      borderRadius: 9999,
      background: 'rgba(168,85,247,0.10)',
      border: '1px solid rgba(168,85,247,0.30)',
      color: '#c084fc',
      fontWeight: 900,
      fontSize: 9,
      letterSpacing: '0.14em',
      textTransform: 'uppercase'
    }
  }, "Subscribe"), /*#__PURE__*/React.createElement("button", {
    style: {
      display: 'grid',
      placeItems: 'center',
      height: 32,
      width: 32,
      borderRadius: 9999,
      background: 'rgba(255,255,255,0.05)',
      color: '#fff',
      border: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 2
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      height: 4,
      width: 4,
      borderRadius: 9999,
      background: '#fff'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      height: 4,
      width: 4,
      borderRadius: 9999,
      background: '#fff'
    }
  }))))));
}
function FeedScreen() {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      background: '#1c1917',
      color: '#fff',
      fontFamily: FONT
    }
  }, /*#__PURE__*/React.createElement(Topbar, {
    pageTitle: "Googer"
  }), /*#__PURE__*/React.createElement("main", {
    style: {
      flex: 1,
      overflow: 'auto',
      padding: 0
    }
  }, /*#__PURE__*/React.createElement(GoogCard, {
    name: "Mira K.",
    time: "\xB7 2h",
    text: "first goog of the day. googer.app just hit different on a monday",
    likes: 42,
    comments: 8,
    views: "1.2k",
    shares: 3,
    liked: true
  }), /*#__PURE__*/React.createElement(GoogCard, {
    name: "Devan S.",
    time: "\xB7 4h",
    text: "hot take: notifications belong on the LEFT side of the topbar. fight me.",
    likes: 211,
    comments: 47,
    views: "9.4k",
    shares: 11
  }), /*#__PURE__*/React.createElement(GoogCard, {
    name: "aurora.exe",
    time: "\xB7 6h",
    text: "just promoted my profile for 200 coins. feels expensive. feels worth it.",
    likes: 18,
    comments: 3,
    views: "612",
    shares: 1
  }), /*#__PURE__*/React.createElement(GoogCard, {
    name: "rohit_p",
    time: "\xB7 9h",
    text: "sold three packs of ginger candy on Shop in one hour. unhinged behavior.",
    likes: 86,
    comments: 12,
    views: "2.1k",
    shares: 4,
    liked: true
  })), /*#__PURE__*/React.createElement(BottomNav, {
    active: "home"
  }));
}

// ─── 3. Shop ────────────────────────────────────────────────────────────────
function ShopCard({
  title,
  price,
  tag
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      background: '#070707',
      borderRadius: 16,
      overflow: 'hidden',
      border: '1px solid #1f2937'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      aspectRatio: '1',
      background: 'linear-gradient(135deg,#1f2937,#0a0a0a)',
      position: 'relative',
      display: 'grid',
      placeItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: "../assets/coin.png",
    style: {
      width: '60%',
      height: '60%',
      objectFit: 'contain'
    }
  }), tag && /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: 8,
      left: 8,
      padding: '4px 8px',
      borderRadius: 9999,
      background: 'rgba(0,0,0,0.6)',
      backdropFilter: 'blur(8px)',
      fontSize: 9,
      fontWeight: 900,
      letterSpacing: '0.14em',
      textTransform: 'uppercase',
      color: '#fff'
    }
  }, tag)), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      fontWeight: 700,
      color: '#fff'
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      marginTop: 6
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: "../assets/rupee.png",
    style: {
      width: 16,
      height: 10,
      objectFit: 'contain'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 900,
      fontSize: 13,
      color: '#fff',
      fontFamily: MONO
    }
  }, price))));
}
function ShopScreen() {
  return /*#__PURE__*/React.createElement(Shell, {
    active: "shop",
    title: "Shop"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: '10px 14px',
      borderRadius: 12,
      background: '#121212',
      border: '1px solid #1f2937',
      marginBottom: 10
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: "search-outline",
    size: 18,
    color: "#6b7280"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: '#6b7280'
    }
  }, "search 12,481 items")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      marginBottom: 14,
      overflow: 'auto'
    }
  }, ['All', 'Trending', 'Gadgets', 'Food', 'Apparel'].map((c, i) => /*#__PURE__*/React.createElement("div", {
    key: c,
    style: {
      padding: '6px 12px',
      borderRadius: 9999,
      background: i === 0 ? 'rgba(255,255,255,0.10)' : 'transparent',
      border: i === 0 ? 'none' : '1px solid rgba(255,255,255,0.10)',
      fontWeight: 900,
      fontSize: 9,
      letterSpacing: '0.14em',
      textTransform: 'uppercase',
      color: '#fff',
      flexShrink: 0
    }
  }, c))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(ShopCard, {
    title: "Ginger Candy Pack",
    price: "120",
    tag: "New"
  }), /*#__PURE__*/React.createElement(ShopCard, {
    title: "Brass Lamp",
    price: "2,400"
  }), /*#__PURE__*/React.createElement(ShopCard, {
    title: "Cold Brew Kit",
    price: "850",
    tag: "\u221220%"
  }), /*#__PURE__*/React.createElement(ShopCard, {
    title: "Linen Tote",
    price: "640"
  })));
}

// ─── 4. Wallet (verbatim from app/dashboard/wallet/page.tsx) ────────────────
function WalletScreen() {
  return /*#__PURE__*/React.createElement(Shell, {
    active: "wallet",
    title: "Wallet"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      background: '#fff',
      borderRadius: 12,
      padding: 16,
      marginBottom: 24,
      boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("h1", {
    style: {
      color: '#000',
      fontWeight: 700,
      fontSize: 18,
      textAlign: 'center',
      letterSpacing: '0.025em',
      margin: 0
    }
  }, "( My Googer ID - GOOG-48201 )"), /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      maxWidth: 384,
      background: '#f3f4f6',
      borderRadius: 8,
      padding: '8px 8px 8px 12px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: 8,
      border: '1px solid #e5e7eb'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      color: '#6b7280',
      fontSize: 12,
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap',
      flex: 1,
      fontFamily: MONO
    }
  }, "googer.app/register?ref=GOOG-48201"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("button", {
    style: {
      padding: 8,
      borderRadius: 8,
      background: '#fff',
      color: '#000',
      border: 0,
      display: 'grid',
      placeItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: "copy-outline",
    size: 18,
    color: "#000"
  })), /*#__PURE__*/React.createElement("button", {
    style: {
      padding: 8,
      borderRadius: 8,
      background: '#fff',
      color: '#000',
      border: 0,
      display: 'grid',
      placeItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: "share-social-outline",
    size: 18,
    color: "#000"
  }))))), /*#__PURE__*/React.createElement("div", {
    style: {
      background: '#070707',
      border: '1px solid #1f2937',
      borderRadius: 16,
      padding: 24,
      marginBottom: 32,
      position: 'relative',
      overflow: 'hidden',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("h2", {
    style: {
      fontSize: 18,
      fontWeight: 700,
      color: '#fff',
      marginBottom: 16,
      letterSpacing: '0.025em'
    }
  }, "My total Ruppier Coins balance"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      justifyContent: 'center',
      marginBottom: 8
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: "../assets/rupee.png",
    alt: "Rupee",
    style: {
      width: 48,
      height: 24,
      objectFit: 'contain'
    }
  }), /*#__PURE__*/React.createElement("h2", {
    style: {
      fontSize: 36,
      fontWeight: 700,
      color: '#fff',
      letterSpacing: '-0.025em',
      lineHeight: 1,
      margin: 0,
      whiteSpace: 'nowrap'
    }
  }, "12,840.00"))), /*#__PURE__*/React.createElement("h3", {
    style: {
      fontSize: 18,
      fontWeight: 700,
      color: '#fff',
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      marginBottom: 20
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: "grid-outline",
    size: 20,
    color: "#fff"
  }), " Services"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr',
      gap: 16
    }
  }, [{
    icon: 'wallet-outline',
    title: 'My Wallet',
    desc: 'Manage your balance and earnings',
    stat: '12,840.00',
    label: 'Balance'
  }, {
    icon: 'add-circle-outline',
    title: 'Top Up',
    desc: 'Recharge your wallet with Rupier coins',
    stat: 'Topup',
    label: 'Wallet'
  }, {
    icon: 'cash-outline',
    title: 'Withdrawal',
    desc: 'Cash out your earnings to your account',
    stat: '12,840.00',
    label: 'Available'
  }].map((c, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      background: '#070707',
      border: '1px solid #1f2937',
      borderRadius: 16,
      padding: 20,
      position: 'relative',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-start',
      justifyContent: 'space-between'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 48,
      height: 48,
      border: '1px solid rgba(255,255,255,0.10)',
      background: 'rgba(0,0,0,0.20)',
      borderRadius: 12,
      display: 'grid',
      placeItems: 'center',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: c.icon,
    size: 24,
    color: "rgba(255,255,255,0.75)"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'right'
    }
  }, /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 11,
      color: '#6b7280',
      marginBottom: 4,
      fontWeight: 500,
      letterSpacing: '0.025em'
    }
  }, c.label), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'flex-end',
      gap: 12
    }
  }, i !== 3 && /*#__PURE__*/React.createElement("img", {
    src: "../assets/rupee.png",
    alt: "\u20B9",
    style: {
      width: 32,
      height: 16,
      objectFit: 'contain'
    }
  }), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 24,
      fontWeight: 700,
      color: '#fff',
      margin: 0
    }
  }, c.stat)))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20
    }
  }, /*#__PURE__*/React.createElement("h4", {
    style: {
      fontSize: 16,
      fontWeight: 700,
      color: '#fff',
      marginBottom: 4
    }
  }, c.title), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 12,
      color: '#6b7280',
      lineHeight: 1.5,
      margin: 0
    }
  }, c.desc))))));
}

// ─── 5. Chats ───────────────────────────────────────────────────────────────
function ChatsScreen() {
  const convos = [{
    name: 'Mira K.',
    last: 'sent you a goog · 2m',
    unread: 2
  }, {
    name: 'Devan S.',
    last: 'okay but the bell on the right tho',
    unread: 0
  }, {
    name: 'rohit_p',
    last: 'shipped! tracking in 10 min',
    unread: 1
  }, {
    name: 'aurora.exe',
    last: 'thanks for the boost',
    unread: 0
  }, {
    name: 'support',
    last: 'your withdrawal is processing',
    unread: 0
  }];
  return /*#__PURE__*/React.createElement(Shell, {
    active: "chats",
    title: "Chats"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: '10px 14px',
      borderRadius: 12,
      background: '#121212',
      border: '1px solid #1f2937',
      marginBottom: 12
    }
  }, /*#__PURE__*/React.createElement(Ion, {
    name: "search-outline",
    size: 18,
    color: "#6b7280"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: '#6b7280'
    }
  }, "search messages")), /*#__PURE__*/React.createElement("div", null, convos.map((c, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      padding: '12px 4px',
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      borderTop: i === 0 ? 'none' : '1px solid rgba(255,255,255,0.06)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 44,
      height: 44,
      borderRadius: 9999,
      background: 'rgba(255,255,255,0.10)',
      flexShrink: 0,
      display: 'grid',
      placeItems: 'center',
      fontWeight: 900,
      color: '#fff',
      fontSize: 14
    }
  }, c.name[0]), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      fontWeight: 900,
      color: '#fff'
    }
  }, c.name), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: '#71717a',
      marginTop: 3,
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, c.last)), c.unread > 0 && /*#__PURE__*/React.createElement("div", {
    style: {
      minWidth: 20,
      height: 20,
      padding: '0 6px',
      borderRadius: 9999,
      background: '#2563eb',
      color: '#fff',
      display: 'grid',
      placeItems: 'center',
      fontWeight: 900,
      fontSize: 10
    }
  }, c.unread)))));
}
Object.assign(window, {
  LoginScreen,
  FeedScreen,
  ShopScreen,
  WalletScreen,
  ChatsScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "mobile/screens.jsx", error: String((e && e.message) || e) }); }

// ui_kits/auth/LoginForm.jsx
try { (() => {
/* global React */
const {
  useState
} = React;
function LoginForm({
  onForgot,
  onSubmit
}) {
  const [email, setEmail] = useState("");
  const [pw, setPw] = useState("");
  const [showPw, setShowPw] = useState(false);
  const [err, setErr] = useState("");
  const submit = e => {
    e.preventDefault();
    if (!email || !pw) {
      setErr("Login failed. Please check your credentials.");
      return;
    }
    setErr("");
    onSubmit?.();
  };
  return /*#__PURE__*/React.createElement("div", {
    className: "bg-black p-8 rounded-3xl border border-purple-500/20",
    style: {
      boxShadow: "0 0 50px -12px rgba(168,85,247,0.1)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex flex-col items-center justify-center mb-6"
  }, /*#__PURE__*/React.createElement("img", {
    src: "../../assets/googer.png",
    alt: "Googer",
    className: "w-20 h-20 object-contain"
  })), err && /*#__PURE__*/React.createElement("div", {
    className: "mb-4 p-3 bg-white border border-gray-200 text-black rounded-xl text-sm font-semibold text-center shadow-sm"
  }, err), /*#__PURE__*/React.createElement("form", {
    onSubmit: submit,
    className: "space-y-4"
  }, /*#__PURE__*/React.createElement("input", {
    className: "w-full px-4 py-3 rounded-xl border border-gray-800 bg-[#121212] text-white focus:outline-none focus:ring-1 focus:ring-purple-500/50 placeholder-gray-500 text-sm",
    type: "email",
    placeholder: "Enter Email",
    value: email,
    onChange: e => setEmail(e.target.value),
    required: true
  }), /*#__PURE__*/React.createElement("div", {
    className: "relative"
  }, /*#__PURE__*/React.createElement("input", {
    className: "w-full px-4 py-3 rounded-xl border border-gray-800 bg-[#121212] text-white focus:outline-none focus:ring-1 focus:ring-purple-500/50 placeholder-gray-500 pr-12 text-sm",
    type: showPw ? "text" : "password",
    placeholder: "Enter Password",
    value: pw,
    onChange: e => setPw(e.target.value),
    required: true
  }), /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: () => setShowPw(!showPw),
    className: "absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-white transition-colors"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: showPw ? "eye-outline" : "eye-off-outline",
    style: {
      fontSize: "20px"
    }
  }))), /*#__PURE__*/React.createElement("div", {
    className: "text-right px-1"
  }, /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onForgot,
    className: "text-purple-400 hover:text-purple-300 text-xs font-light transition-colors"
  }, "Forgot password?")), /*#__PURE__*/React.createElement("button", {
    type: "submit",
    className: "font-bold w-full rounded-full bg-white text-black py-3 px-4 shadow-lg hover:bg-gray-200 active:scale-[0.97] transition-all duration-200 mt-2 text-sm"
  }, "Login"), /*#__PURE__*/React.createElement("div", {
    className: "text-center mt-4"
  }, /*#__PURE__*/React.createElement("span", {
    className: "text-gray-500 text-xs font-normal underline decoration-gray-800 underline-offset-4"
  }, "Don't have an account? \u2014"), /*#__PURE__*/React.createElement("a", {
    href: "#",
    className: "text-purple-400 hover:text-purple-300 text-xs font-bold transition-all ml-1"
  }, "Register"))));
}
window.LoginForm = LoginForm;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/auth/LoginForm.jsx", error: String((e && e.message) || e) }); }

// ui_kits/auth/ResetModal.jsx
try { (() => {
/* global React */
const {
  useState
} = React;
function ResetModal({
  onClose,
  onDone
}) {
  const [step, setStep] = useState(1);
  const [email, setEmail] = useState("");
  const [otp, setOtp] = useState("");
  const [pw, setPw] = useState("");
  return /*#__PURE__*/React.createElement("div", {
    className: "fixed inset-0 bg-black/90 backdrop-blur-md flex items-center justify-center z-50 p-6",
    style: {
      animation: "fadeIn 0.3s ease-out"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "bg-black border border-purple-500/20 w-full max-w-sm rounded-3xl p-8 relative overflow-hidden",
    style: {
      boxShadow: "0 0 50px -12px rgba(168,85,247,0.1)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "absolute -top-10 -right-10 w-32 h-32 bg-purple-500/10 rounded-full blur-3xl"
  }), /*#__PURE__*/React.createElement("button", {
    onClick: onClose,
    className: "absolute top-6 right-6 text-gray-500 hover:text-white transition-all hover:rotate-90 z-10"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "close-outline",
    style: {
      fontSize: "24px"
    }
  })), step === 1 && /*#__PURE__*/React.createElement("div", {
    style: {
      animation: "slideIn 0.4s ease-out"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "mb-6 text-center"
  }, /*#__PURE__*/React.createElement("div", {
    className: "w-14 h-14 bg-purple-500/10 rounded-2xl flex items-center justify-center mx-auto mb-4 border border-purple-500/20"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "mail-outline",
    style: {
      fontSize: "24px",
      color: "#c084fc"
    }
  })), /*#__PURE__*/React.createElement("h3", {
    className: "text-xl font-bold text-white mb-2"
  }, "Reset Password"), /*#__PURE__*/React.createElement("p", {
    className: "text-gray-500 text-xs leading-relaxed"
  }, "Enter your registered email to receive a secure OTP.")), /*#__PURE__*/React.createElement("input", {
    type: "email",
    placeholder: "Enter Email Address",
    value: email,
    onChange: e => setEmail(e.target.value),
    className: "w-full bg-[#121212] border border-gray-800 text-white rounded-xl px-4 py-3 mb-4 focus:ring-1 focus:ring-purple-500/50 outline-none text-sm transition-all"
  }), /*#__PURE__*/React.createElement("button", {
    onClick: () => email && setStep(2),
    className: "w-full bg-white text-black font-bold py-3 px-4 rounded-full text-sm shadow-lg hover:bg-gray-200 active:scale-[0.97] transition-all"
  }, "Send OTP Code")), step === 2 && /*#__PURE__*/React.createElement("div", {
    style: {
      animation: "slideIn 0.4s ease-out"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "mb-6 text-center"
  }, /*#__PURE__*/React.createElement("div", {
    className: "w-14 h-14 bg-purple-500/10 rounded-2xl flex items-center justify-center mx-auto mb-4 border border-purple-500/20"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "keypad-outline",
    style: {
      fontSize: "24px",
      color: "#c084fc"
    }
  })), /*#__PURE__*/React.createElement("h3", {
    className: "text-xl font-bold text-white mb-2"
  }, "Verify OTP"), /*#__PURE__*/React.createElement("p", {
    className: "text-gray-500 text-xs leading-relaxed"
  }, "We've sent a 6-digit code to ", /*#__PURE__*/React.createElement("br", null), /*#__PURE__*/React.createElement("span", {
    className: "text-purple-400 font-bold"
  }, email || "you@googer.app"))), /*#__PURE__*/React.createElement("input", {
    type: "text",
    placeholder: "Enter 6-Digit OTP",
    maxLength: 6,
    value: otp,
    onChange: e => setOtp(e.target.value.replace(/\D/g, "")),
    className: "w-full bg-[#121212] border border-gray-800 text-white rounded-xl px-4 py-3 mb-4 focus:ring-1 focus:ring-purple-500/50 outline-none text-sm text-center font-bold",
    style: {
      letterSpacing: "0.5em"
    }
  }), /*#__PURE__*/React.createElement("button", {
    onClick: () => otp.length === 6 && setStep(3),
    className: "w-full bg-white text-black font-bold py-3 px-4 rounded-full text-sm shadow-lg hover:bg-gray-200 active:scale-[0.97] transition-all"
  }, "Verify & Continue"), /*#__PURE__*/React.createElement("p", {
    className: "text-center mt-4 text-[10px] text-gray-500 uppercase tracking-widest font-bold"
  }, "Didn't receive? ", /*#__PURE__*/React.createElement("button", {
    className: "text-purple-400 hover:underline"
  }, "Resend OTP"))), step === 3 && /*#__PURE__*/React.createElement("div", {
    style: {
      animation: "slideIn 0.4s ease-out"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "mb-6 text-center"
  }, /*#__PURE__*/React.createElement("div", {
    className: "w-14 h-14 bg-green-500/10 rounded-2xl flex items-center justify-center mx-auto mb-4 border border-green-500/20"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "lock-closed-outline",
    style: {
      fontSize: "24px",
      color: "#4ade80"
    }
  })), /*#__PURE__*/React.createElement("h3", {
    className: "text-xl font-bold text-white mb-2"
  }, "New Password"), /*#__PURE__*/React.createElement("p", {
    className: "text-gray-500 text-xs leading-relaxed"
  }, "Secure your account with a new strong password.")), /*#__PURE__*/React.createElement("div", {
    className: "space-y-4 mb-6"
  }, /*#__PURE__*/React.createElement("input", {
    type: "password",
    placeholder: "New Password",
    value: pw,
    onChange: e => setPw(e.target.value),
    className: "w-full bg-[#121212] border border-gray-800 text-white rounded-xl px-4 py-3 focus:ring-1 focus:ring-green-500/50 outline-none text-sm transition-all"
  }), /*#__PURE__*/React.createElement("input", {
    type: "password",
    placeholder: "Confirm New Password",
    className: "w-full bg-[#121212] border border-gray-800 text-white rounded-xl px-4 py-3 focus:ring-1 focus:ring-green-500/50 outline-none text-sm transition-all"
  })), /*#__PURE__*/React.createElement("button", {
    onClick: onDone,
    className: "w-full bg-green-500 text-black font-bold py-3 px-4 rounded-full text-sm shadow-lg hover:bg-green-400 active:scale-[0.97] transition-all"
  }, "Update Password"))));
}
window.ResetModal = ResetModal;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/auth/ResetModal.jsx", error: String((e && e.message) || e) }); }

// ui_kits/feed/Composer.jsx
try { (() => {
/* global React */
const {
  useState: _useState
} = React;
function Composer({
  onPost
}) {
  const [text, setText] = _useState("");
  return /*#__PURE__*/React.createElement("div", {
    className: "px-5 sm:px-7 py-4 border-b border-white/10 flex gap-3"
  }, /*#__PURE__*/React.createElement("div", {
    className: "w-10 h-10 rounded-full bg-gradient-to-br from-purple-600 to-blue-600 grid place-items-center text-white font-black text-sm shrink-0"
  }, "M"), /*#__PURE__*/React.createElement("div", {
    className: "flex-1 min-w-0"
  }, /*#__PURE__*/React.createElement("textarea", {
    value: text,
    onChange: e => setText(e.target.value),
    rows: 2,
    placeholder: "What's on your mind?",
    className: "w-full bg-transparent text-white text-[14px] leading-6 placeholder-gray-500 resize-none focus:outline-none"
  }), /*#__PURE__*/React.createElement("div", {
    className: "flex items-center justify-between mt-2"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex items-center gap-3 text-gray-400"
  }, /*#__PURE__*/React.createElement("button", {
    className: "hover:text-purple-400 transition-colors"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "image-outline",
    style: {
      fontSize: "20px"
    }
  })), /*#__PURE__*/React.createElement("button", {
    className: "hover:text-purple-400 transition-colors"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "link-outline",
    style: {
      fontSize: "20px"
    }
  })), /*#__PURE__*/React.createElement("button", {
    className: "hover:text-purple-400 transition-colors"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "at-outline",
    style: {
      fontSize: "20px"
    }
  }))), /*#__PURE__*/React.createElement("button", {
    onClick: () => {
      if (text.trim()) {
        onPost?.(text);
        setText("");
      }
    },
    disabled: !text.trim(),
    className: "font-bold rounded-full bg-white text-black py-2 px-5 shadow-lg hover:bg-gray-200 active:scale-[0.97] disabled:opacity-30 disabled:cursor-not-allowed transition-all text-xs"
  }, "Post"))));
}
window.Composer = Composer;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/feed/Composer.jsx", error: String((e && e.message) || e) }); }

// ui_kits/feed/GoogCard.jsx
try { (() => {
/* global React */
const {
  useState: _useStateG
} = React;
function GoogCard({
  post,
  onLike
}) {
  const [liked, setLiked] = _useStateG(post.liked || false);
  const [likes, setLikes] = _useStateG(post.likes);
  const toggle = () => {
    setLiked(!liked);
    setLikes(likes + (liked ? -1 : 1));
    onLike?.(post.id);
  };
  return /*#__PURE__*/React.createElement("article", {
    className: "border-b border-white/10 px-5 sm:px-7 py-5 transition-colors hover:bg-white/[0.025]"
  }, /*#__PURE__*/React.createElement("header", {
    className: "flex items-start justify-between gap-4"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex min-w-0 gap-3 flex-1"
  }, /*#__PURE__*/React.createElement("div", {
    className: "relative h-10 w-10 shrink-0 overflow-hidden rounded-full bg-white/10 grid place-items-center text-white font-black text-sm",
    style: {
      background: post.user.bg || "#374151"
    }
  }, post.user.name.charAt(0)), /*#__PURE__*/React.createElement("div", {
    className: "min-w-0 flex-1"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex items-center gap-2"
  }, /*#__PURE__*/React.createElement("span", {
    className: "text-[13px] font-black text-white"
  }, post.user.name), /*#__PURE__*/React.createElement("span", {
    className: "text-xs text-white/35"
  }, "\xB7 ", post.time)), /*#__PURE__*/React.createElement("div", {
    className: "mt-1.5 whitespace-pre-wrap break-words text-[14px] leading-6 text-white"
  }, post.text.split(/(https?:\/\/[^\s]+|@[A-Za-z0-9_]+|#[A-Za-z0-9_]+)/g).map((part, i) => {
    if (/^https?:\/\//.test(part)) return /*#__PURE__*/React.createElement("a", {
      key: i,
      href: part,
      className: "text-blue-400 underline decoration-blue-400/50 underline-offset-2 hover:text-blue-300",
      target: "_blank",
      rel: "noopener noreferrer"
    }, part);
    if (part.startsWith("@") || part.startsWith("#")) return /*#__PURE__*/React.createElement("span", {
      key: i,
      className: "text-red-400"
    }, part);
    return part;
  })), post.link && /*#__PURE__*/React.createElement("a", {
    href: post.link.href,
    target: "_blank",
    rel: "noopener noreferrer",
    className: "mt-3 flex items-center gap-3 rounded-xl border border-white/10 bg-white/[0.04] px-3 py-2 transition hover:bg-white/[0.07]"
  }, /*#__PURE__*/React.createElement("div", {
    className: "h-9 w-9 shrink-0 grid place-items-center rounded-lg border border-white/10 bg-white/[0.05]"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "globe-outline",
    style: {
      fontSize: "16px",
      color: "rgba(255,255,255,.7)"
    }
  })), /*#__PURE__*/React.createElement("div", {
    className: "min-w-0 flex-1"
  }, /*#__PURE__*/React.createElement("p", {
    className: "truncate text-[11px] font-black uppercase tracking-[0.12em] text-white/85"
  }, post.link.host), /*#__PURE__*/React.createElement("p", {
    className: "truncate text-[10px] font-semibold text-white/45"
  }, post.link.label)), /*#__PURE__*/React.createElement("ion-icon", {
    name: "open-outline",
    style: {
      fontSize: "16px",
      color: "rgba(255,255,255,.4)"
    }
  })), /*#__PURE__*/React.createElement("div", {
    className: "mt-4 flex items-center gap-5 text-white/80"
  }, /*#__PURE__*/React.createElement("button", {
    onClick: toggle,
    className: "flex items-center gap-1 transition-all active:scale-75",
    style: {
      color: liked ? "#ef4444" : "#fff"
    }
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: liked ? "heart" : "heart-outline",
    style: {
      fontSize: "21px"
    }
  }), likes > 0 && /*#__PURE__*/React.createElement("span", {
    className: "text-[9px] font-black tracking-tighter"
  }, likes)), /*#__PURE__*/React.createElement("button", {
    className: "flex items-center gap-1 transition-all active:scale-75 text-white"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "chatbubble-outline",
    style: {
      fontSize: "21px"
    }
  }), post.comments > 0 && /*#__PURE__*/React.createElement("span", {
    className: "text-[9px] font-black tracking-tighter"
  }, post.comments)), /*#__PURE__*/React.createElement("button", {
    className: "flex items-center gap-1 transition-all active:scale-75 text-white"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "eye-outline",
    style: {
      fontSize: "21px"
    }
  }), /*#__PURE__*/React.createElement("span", {
    className: "text-[9px] font-black tracking-tighter"
  }, post.views)), /*#__PURE__*/React.createElement("button", {
    className: "flex items-center gap-1 transition-all active:scale-75 text-white"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "share-social-outline",
    style: {
      fontSize: "21px"
    }
  }), post.shares > 0 && /*#__PURE__*/React.createElement("span", {
    className: "text-[9px] font-black tracking-tighter"
  }, post.shares))))), /*#__PURE__*/React.createElement("div", {
    className: "flex shrink-0 items-center gap-1"
  }, /*#__PURE__*/React.createElement("button", {
    className: "rounded-full bg-white/5 text-white text-[10px] font-black uppercase tracking-widest px-3 py-1.5 hover:bg-white/10 active:scale-95 transition-all"
  }, "Subscribe"), /*#__PURE__*/React.createElement("button", {
    className: "flex h-8 w-8 items-center justify-center rounded-full bg-white/5 text-white hover:bg-white/10 active:scale-75 transition-all"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex flex-col gap-0.5"
  }, /*#__PURE__*/React.createElement("div", {
    className: "h-1 w-1 rounded-full bg-white"
  }), /*#__PURE__*/React.createElement("div", {
    className: "h-1 w-1 rounded-full bg-white"
  }))))));
}
window.GoogCard = GoogCard;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/feed/GoogCard.jsx", error: String((e && e.message) || e) }); }

// ui_kits/feed/Topbar.jsx
try { (() => {
/* global React */
function Topbar({
  active = "home"
}) {
  const items = [{
    id: "home",
    icon: "home",
    label: "Home"
  }, {
    id: "shop",
    icon: "bag",
    label: "Shop"
  }, {
    id: "wallet",
    icon: "wallet",
    label: "Wallet"
  }, {
    id: "chats",
    icon: "chatbubbles",
    label: "Chats"
  }];
  return /*#__PURE__*/React.createElement("header", {
    className: "fixed left-0 right-0 top-0 z-50 flex items-center justify-between border-b border-[#27272a] px-4 md:px-6 h-16",
    style: {
      background: "rgba(24,24,27,0.80)",
      backdropFilter: "blur(12px)"
    }
  }, /*#__PURE__*/React.createElement("a", {
    href: "#",
    className: "flex items-center gap-2.5"
  }, /*#__PURE__*/React.createElement("div", {
    className: "relative w-8 h-8 rounded-full overflow-hidden border border-white/10 bg-black"
  }, /*#__PURE__*/React.createElement("img", {
    src: "../../assets/googer.png",
    alt: "",
    className: "absolute inset-0 w-full h-full object-contain"
  })), /*#__PURE__*/React.createElement("h1", {
    className: "text-xl font-bold tracking-tight text-white hidden sm:block"
  }, "Googer")), /*#__PURE__*/React.createElement("nav", {
    className: "hidden md:flex items-center gap-1 absolute left-1/2 -translate-x-1/2"
  }, items.slice(0, 2).map(it => /*#__PURE__*/React.createElement("a", {
    key: it.id,
    href: "#",
    className: `flex items-center gap-2 px-3 py-2 rounded-xl transition-all duration-300 ${active === it.id ? "bg-white/10 text-white" : "text-gray-400 hover:bg-white/5 hover:text-white"}`
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: active === it.id ? it.icon : it.icon + "-outline",
    style: {
      fontSize: "20px"
    }
  }), /*#__PURE__*/React.createElement("span", {
    className: "font-black text-[10px] uppercase tracking-widest"
  }, it.label))), /*#__PURE__*/React.createElement("button", {
    className: "flex items-center justify-center w-12 h-10 rounded-xl text-gray-400 hover:bg-white/10 hover:text-white transition-all mx-2"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "add-circle",
    style: {
      fontSize: "30px"
    }
  })), items.slice(2).map(it => /*#__PURE__*/React.createElement("a", {
    key: it.id,
    href: "#",
    className: `flex items-center gap-2 px-3 py-2 rounded-xl transition-all duration-300 ${active === it.id ? "bg-white/10 text-white" : "text-gray-400 hover:bg-white/5 hover:text-white"}`
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: active === it.id ? it.icon : it.icon + "-outline",
    style: {
      fontSize: "20px"
    }
  }), /*#__PURE__*/React.createElement("span", {
    className: "font-black text-[10px] uppercase tracking-widest"
  }, it.label)))), /*#__PURE__*/React.createElement("div", {
    className: "flex items-center gap-2"
  }, /*#__PURE__*/React.createElement("button", {
    className: "w-9 h-9 flex items-center justify-center rounded-full text-gray-400 hover:text-white hover:bg-white/10 transition-all relative"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "cart-outline",
    style: {
      fontSize: "20px"
    }
  })), /*#__PURE__*/React.createElement("button", {
    className: "w-9 h-9 flex items-center justify-center rounded-full text-gray-400 hover:text-white hover:bg-white/5 transition-all relative"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "notifications-outline",
    style: {
      fontSize: "20px"
    }
  }), /*#__PURE__*/React.createElement("span", {
    className: "absolute top-1.5 right-1.5 w-2 h-2 bg-pink-500 rounded-full border-2 border-[#18181b]"
  })), /*#__PURE__*/React.createElement("a", {
    href: "#",
    className: "ml-2 block w-9 h-9 rounded-full overflow-hidden border-2 border-white/10 hover:border-purple-500/50 transition-all bg-slate-800 grid place-items-center"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "person-outline",
    style: {
      color: "#a1a1aa"
    }
  }))));
}
window.Topbar = Topbar;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/feed/Topbar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/shop/CartSidebar.jsx
try { (() => {
/* global React */
function CartSidebar({
  open,
  items,
  onClose,
  onRemove
}) {
  if (!open) return null;
  const total = items.reduce((s, i) => s + i.price * i.qty, 0);
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    className: "fixed inset-0 bg-black/90 backdrop-blur-md z-40",
    onClick: onClose
  }), /*#__PURE__*/React.createElement("aside", {
    className: "fixed right-0 top-0 h-screen w-full max-w-md bg-[#0a0a0a] border-l border-white/10 z-50 flex flex-col",
    style: {
      animation: "slideIn 0.3s ease-out"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex items-center justify-between px-6 py-5 border-b border-white/10"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex items-center gap-2"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "cart",
    style: {
      fontSize: "22px",
      color: "#fff"
    }
  }), /*#__PURE__*/React.createElement("h2", {
    className: "text-lg font-bold text-white"
  }, "Cart"), /*#__PURE__*/React.createElement("span", {
    className: "ml-1 text-[10px] font-black text-gray-500 uppercase tracking-widest"
  }, items.length, " items")), /*#__PURE__*/React.createElement("button", {
    onClick: onClose,
    className: "text-gray-500 hover:text-white hover:rotate-90 transition-all"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "close-outline",
    style: {
      fontSize: "24px"
    }
  }))), /*#__PURE__*/React.createElement("div", {
    className: "flex-1 overflow-y-auto px-4 py-2"
  }, items.length === 0 ? /*#__PURE__*/React.createElement("div", {
    className: "py-20 flex flex-col items-center justify-center text-gray-500"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "cart-outline",
    style: {
      fontSize: "48px",
      opacity: 0.2
    }
  }), /*#__PURE__*/React.createElement("p", {
    className: "mt-3 text-[10px] font-black uppercase tracking-widest opacity-40"
  }, "Cart is empty")) : items.map(it => /*#__PURE__*/React.createElement("div", {
    key: it.id,
    className: "flex items-center gap-3 py-3 border-b border-white/5"
  }, /*#__PURE__*/React.createElement("div", {
    className: "w-14 h-14 rounded-lg grid place-items-center text-3xl shrink-0",
    style: {
      background: it.bg
    }
  }, it.emoji), /*#__PURE__*/React.createElement("div", {
    className: "flex-1 min-w-0"
  }, /*#__PURE__*/React.createElement("div", {
    className: "font-black text-[13px] text-white truncate"
  }, it.name), /*#__PURE__*/React.createElement("div", {
    className: "text-[10px] text-gray-500 font-bold mt-0.5"
  }, "Qty ", it.qty)), /*#__PURE__*/React.createElement("div", {
    className: "text-white font-bold text-sm flex items-center gap-1"
  }, /*#__PURE__*/React.createElement("img", {
    src: "../../assets/rupee.png",
    className: "w-3 h-3 object-contain"
  }), it.price * it.qty), /*#__PURE__*/React.createElement("button", {
    onClick: () => onRemove(it.id),
    className: "text-gray-600 hover:text-red-400 transition-colors"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "close-outline",
    style: {
      fontSize: "18px"
    }
  }))))), items.length > 0 && /*#__PURE__*/React.createElement("div", {
    className: "border-t border-white/10 px-6 py-5"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex items-center justify-between mb-4"
  }, /*#__PURE__*/React.createElement("span", {
    className: "text-[10px] font-black uppercase tracking-widest text-gray-500"
  }, "Total"), /*#__PURE__*/React.createElement("div", {
    className: "flex items-center gap-1 text-white font-bold text-xl"
  }, /*#__PURE__*/React.createElement("img", {
    src: "../../assets/rupee.png",
    className: "w-5 h-5 object-contain"
  }), total)), /*#__PURE__*/React.createElement("button", {
    className: "w-full rounded-full bg-white text-black font-bold py-3 text-sm hover:bg-gray-200 active:scale-[0.97] transition-all"
  }, "Checkout"))));
}
window.CartSidebar = CartSidebar;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/shop/CartSidebar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/shop/ProductCard.jsx
try { (() => {
/* global React */
function ProductCard({
  p,
  onAdd
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "group rounded-2xl border border-white/10 bg-[#0a0a0a] overflow-hidden hover:border-white/20 transition-all"
  }, /*#__PURE__*/React.createElement("div", {
    className: "relative aspect-square bg-gradient-to-br",
    style: {
      background: p.bg
    }
  }, p.promoted && /*#__PURE__*/React.createElement("div", {
    className: "absolute top-2 left-2 px-2 py-1 rounded-full bg-black/70 backdrop-blur-sm border border-purple-500/30 text-purple-300 text-[8px] font-black uppercase tracking-widest"
  }, "Promoted"), /*#__PURE__*/React.createElement("button", {
    className: "absolute top-2 right-2 w-8 h-8 rounded-full bg-black/50 backdrop-blur-sm text-white grid place-items-center hover:bg-black/70 active:scale-90 transition-all"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "heart-outline",
    style: {
      fontSize: "16px"
    }
  })), /*#__PURE__*/React.createElement("div", {
    className: "absolute inset-0 grid place-items-center text-6xl opacity-60"
  }, p.emoji)), /*#__PURE__*/React.createElement("div", {
    className: "p-3"
  }, /*#__PURE__*/React.createElement("div", {
    className: "font-black text-[13px] text-white truncate"
  }, p.name), /*#__PURE__*/React.createElement("div", {
    className: "font-black text-[9px] uppercase tracking-widest text-gray-500 mt-1"
  }, p.seller), /*#__PURE__*/React.createElement("div", {
    className: "flex items-center justify-between mt-3"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex items-center gap-1 text-white font-bold text-sm"
  }, /*#__PURE__*/React.createElement("img", {
    src: "../../assets/rupee.png",
    className: "w-4 h-4 object-contain"
  }), /*#__PURE__*/React.createElement("span", null, p.price)), /*#__PURE__*/React.createElement("button", {
    onClick: () => onAdd?.(p),
    className: "rounded-full bg-white text-black font-bold text-[10px] uppercase tracking-widest px-3 py-1.5 hover:bg-gray-200 active:scale-[0.97] transition-all"
  }, "Add"))));
}
window.ProductCard = ProductCard;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/shop/ProductCard.jsx", error: String((e && e.message) || e) }); }

// ui_kits/wallet/BalanceCard.jsx
try { (() => {
/* global React */
function BalanceCard({
  balance
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "relative overflow-hidden rounded-3xl border border-white/10 bg-[#0a0a0a] p-6"
  }, /*#__PURE__*/React.createElement("div", {
    className: "absolute -top-10 -right-10 w-48 h-48 bg-purple-500/10 rounded-full blur-3xl"
  }), /*#__PURE__*/React.createElement("div", {
    className: "absolute -bottom-16 -left-10 w-48 h-48 bg-blue-500/5 rounded-full blur-3xl"
  }), /*#__PURE__*/React.createElement("div", {
    className: "relative"
  }, /*#__PURE__*/React.createElement("div", {
    className: "flex items-center justify-between"
  }, /*#__PURE__*/React.createElement("span", {
    className: "text-[10px] font-black uppercase tracking-widest text-gray-500"
  }, "Wallet Balance"), /*#__PURE__*/React.createElement("ion-icon", {
    name: "eye-outline",
    style: {
      fontSize: "18px",
      color: "#71717a"
    }
  })), /*#__PURE__*/React.createElement("div", {
    className: "flex items-center gap-3 mt-3"
  }, /*#__PURE__*/React.createElement("img", {
    src: "../../assets/coin.png",
    className: "w-16 h-16 object-contain"
  }), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "text-4xl font-black text-white tracking-tight"
  }, balance.toLocaleString()), /*#__PURE__*/React.createElement("div", {
    className: "text-[10px] font-black uppercase tracking-widest text-gray-500 mt-1"
  }, "Coins"))), /*#__PURE__*/React.createElement("div", {
    className: "grid grid-cols-3 gap-2 mt-6"
  }, /*#__PURE__*/React.createElement("button", {
    className: "rounded-2xl bg-white/5 border border-white/10 hover:bg-white/10 active:scale-[0.97] transition-all py-3 flex flex-col items-center gap-1.5"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "arrow-down-outline",
    style: {
      fontSize: "20px",
      color: "#fff"
    }
  }), /*#__PURE__*/React.createElement("span", {
    className: "text-[9px] font-black uppercase tracking-widest text-white"
  }, "Top up")), /*#__PURE__*/React.createElement("button", {
    className: "rounded-2xl bg-white/5 border border-white/10 hover:bg-white/10 active:scale-[0.97] transition-all py-3 flex flex-col items-center gap-1.5"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "arrow-up-outline",
    style: {
      fontSize: "20px",
      color: "#fff"
    }
  }), /*#__PURE__*/React.createElement("span", {
    className: "text-[9px] font-black uppercase tracking-widest text-white"
  }, "Withdraw")), /*#__PURE__*/React.createElement("button", {
    className: "rounded-2xl bg-white text-black hover:bg-gray-200 active:scale-[0.97] transition-all py-3 flex flex-col items-center gap-1.5"
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: "paper-plane-outline",
    style: {
      fontSize: "20px"
    }
  }), /*#__PURE__*/React.createElement("span", {
    className: "text-[9px] font-black uppercase tracking-widest"
  }, "Transfer")))));
}
window.BalanceCard = BalanceCard;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/wallet/BalanceCard.jsx", error: String((e && e.message) || e) }); }

// ui_kits/wallet/TransactionRow.jsx
try { (() => {
/* global React */
function TransactionRow({
  tx
}) {
  const inflow = tx.direction === "in";
  return /*#__PURE__*/React.createElement("div", {
    className: "flex items-center gap-3 px-4 py-3 hover:bg-white/[0.025] transition-colors rounded-xl"
  }, /*#__PURE__*/React.createElement("div", {
    className: `w-10 h-10 rounded-full grid place-items-center shrink-0 ${inflow ? "bg-green-500/10 text-green-400" : "bg-white/5 text-gray-300"}`
  }, /*#__PURE__*/React.createElement("ion-icon", {
    name: tx.icon,
    style: {
      fontSize: "18px"
    }
  })), /*#__PURE__*/React.createElement("div", {
    className: "flex-1 min-w-0"
  }, /*#__PURE__*/React.createElement("div", {
    className: "font-bold text-[13px] text-white truncate"
  }, tx.title), /*#__PURE__*/React.createElement("div", {
    className: "flex items-center gap-2 mt-0.5"
  }, /*#__PURE__*/React.createElement("span", {
    className: "text-[9px] font-black uppercase tracking-widest text-gray-500"
  }, tx.type), /*#__PURE__*/React.createElement("span", {
    className: "text-[10px] text-gray-600"
  }, "\xB7 ", tx.time))), /*#__PURE__*/React.createElement("div", {
    className: "text-right"
  }, /*#__PURE__*/React.createElement("div", {
    className: `font-black text-sm tabular-nums ${inflow ? "text-green-400" : "text-white"}`
  }, inflow ? "+" : "−", tx.amount.toLocaleString()), /*#__PURE__*/React.createElement("div", {
    className: "text-[9px] font-black uppercase tracking-widest mt-0.5",
    style: {
      color: tx.status === "success" ? "#22c55e" : tx.status === "pending" ? "#c084fc" : "#ef4444"
    }
  }, tx.status)));
}
window.TransactionRow = TransactionRow;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/wallet/TransactionRow.jsx", error: String((e && e.message) || e) }); }

})();
