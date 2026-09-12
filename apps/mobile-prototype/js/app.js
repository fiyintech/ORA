/* ============================================
   ORA — UI Prototype JavaScript
   Screen navigation, auto-transitions
   ============================================ */

// --- Navigation ---
function navigateTo(page) {
  // Hide all screens
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  
  // Hide all pages
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));

  // Update bottom nav
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));

  switch (page) {
    case 'splash':
      document.getElementById('splash').classList.add('active');
      break;
    case 'onboarding':
      document.getElementById('onboarding').classList.add('active');
      break;
    case 'login':
      document.getElementById('login').classList.add('active');
      break;
    case 'home':
      document.getElementById('app').classList.add('active');
      document.getElementById('page-home').classList.add('active');
      document.querySelector('.nav-item[data-page="home"]').classList.add('active');
      break;
    case 'chats':
      document.getElementById('app').classList.add('active');
      document.getElementById('page-chats').classList.add('active');
      document.querySelector('.nav-item[data-page="chats"]').classList.add('active');
      break;
    case 'hoods':
      document.getElementById('app').classList.add('active');
      document.getElementById('page-hoods').classList.add('active');
      document.querySelector('.nav-item[data-page="hoods"]').classList.add('active');
      break;
    case 'gbedu':
      document.getElementById('app').classList.add('active');
      document.getElementById('page-gbedu').classList.add('active');
      document.querySelector('.nav-item[data-page="gbedu"]').classList.add('active');
      break;
    case 'profile':
      document.getElementById('app').classList.add('active');
      document.getElementById('page-profile').classList.add('active');
      document.querySelector('.nav-item[data-page="profile"]').classList.add('active');
      break;
  }
}

// --- Auto-transition splash → onboarding ---
setTimeout(() => {
  navigateTo('onboarding');
}, 2500);

// --- Allow Enter key on login form ---
document.addEventListener('DOMContentLoaded', () => {
  const loginForm = document.querySelector('.auth-form');
  if (loginForm) {
    loginForm.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        navigateTo('home');
      }
    });
  }
});

// --- Chat tabs switching ---
function switchChatTab(tabName) {
  console.log('Switching to tab:', tabName);
  
  // Hide all tab contents
  const allTabs = document.querySelectorAll('.tab-content');
  allTabs.forEach(tab => {
    tab.classList.remove('active');
  });
  
  // Remove active class from all tabs
  const allChatTabs = document.querySelectorAll('.chat-tab');
  allChatTabs.forEach(tab => {
    tab.classList.remove('active');
  });
  
  // Show selected tab content
  const selectedTab = document.getElementById('tab-' + tabName);
  if (selectedTab) {
    selectedTab.classList.add('active');
    console.log('Tab content shown:', tabName);
  } else {
    console.error('Tab content not found:', tabName);
  }
  
  // Add active class to clicked tab
  const clickedTab = document.querySelector('.chat-tab[data-tab="' + tabName + '"]');
  if (clickedTab) {
    clickedTab.classList.add('active');
    console.log('Tab button activated:', tabName);
  } else {
    console.error('Tab button not found:', tabName);
  }
}

// Make function globally accessible
window.switchChatTab = switchChatTab;
