<template>
  <div class="app-shell">
    <Transition name="fade">
      <div v-if="mobileOpen" class="backdrop" @click="mobileOpen = false" />
    </Transition>

    <aside :class="['sidebar', { collapsed, 'mobile-open': mobileOpen }]">
      <div class="sidebar-header">
        <span class="logo" v-if="!collapsed || mobileOpen">Ledger</span>
        <button class="icon-btn hide-mobile" @click="collapsed = !collapsed">☰</button>
        <button class="icon-btn hide-desktop" @click="mobileOpen = false">✕</button>
      </div>

      <nav @click="onNavClick">
        <RouterLink v-for="item in menu" :key="item.to" :to="item.to" class="nav-item">
          <span class="icon">{{ item.icon }}</span>
          <span class="label" v-if="!collapsed || mobileOpen">{{ item.label }}</span>
        </RouterLink>
      </nav>
    </aside>

    <section class="main">
      <header class="top-bar">
        <div class="flex-row items-center gap-1">
          <button class="icon-btn hide-desktop" @click="mobileOpen = true">☰</button>
          <h2 class="title">Accounting</h2>
        </div>
        
        <!-- Create User Icon -->
        <button class="icon-btn user-create-btn" @click="showSelectionDialog = true" title="Add New User">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
            <circle cx="8.5" cy="7" r="4"></circle>
            <line x1="20" y1="8" x2="20" y2="14"></line>
            <line x1="23" y1="11" x2="17" y2="11"></line>
          </svg>
        </button>
      </header>
      <div class="content">
        <RouterView />
      </div>
    </section>

    <!-- Selection Dialog -->
    <Transition name="fade">
      <div v-if="showSelectionDialog" class="modal-overlay" @click.self="showSelectionDialog = false">
        <div class="modal-content selection-modal">
          <h3 class="modal-title">Add New User</h3>
          <div class="selection-actions">
            <button @click="selectType('site')" class="selection-btn">
              <span>Add: Site Admin</span>
              <span class="selection-arrow">→</span>
            </button>
            <button @click="selectType('chat')" class="selection-btn">
              <span>Add: Chat Admin</span>
              <span class="selection-arrow">→</span>
            </button>
            <button @click="showSelectionDialog = false" class="btn btn-cancel full-width">Cancel</button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Create User Dialog -->
    <Transition name="fade">
      <div v-if="showUserDialog" class="modal-overlay" @click.self="showUserDialog = false">
        <div class="modal-content">
          <h3 class="modal-title">Add {{ userType === 'site' ? 'Site Admin' : 'Chat Admin' }}</h3>
          <form @submit.prevent="handleCreateUser" class="user-form">
            <template v-if="userType === 'site'">
              <div class="form-group">
                <label for="username">Username</label>
                <input v-model="userForm.username" id="username" type="text" required placeholder="Enter username" />
              </div>
              <div class="form-group">
                <label for="password">Password</label>
                <input v-model="userForm.password" id="password" type="password" required placeholder="Enter password" />
              </div>
            </template>
            <template v-else>
              <div class="form-group">
                <label for="userId">User Id</label>
                <input v-model="userForm.userId" id="userId" type="text" required placeholder="Enter Chat User ID" />
              </div>
            </template>

            <div class="modal-actions">
              <button type="button" class="btn btn-cancel" @click="showUserDialog = false">Cancel</button>
              <button type="submit" class="btn btn-submit" :disabled="isSubmitting">
                {{ isSubmitting ? 'Creating...' : 'Submit' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'

const collapsed = ref(false)
const mobileOpen = ref(false)
const showSelectionDialog = ref(false)
const showUserDialog = ref(false)
const isSubmitting = ref(false)
const userType = ref('site') // 'site' or 'chat'

const userForm = reactive({
  username: '',
  password: '',
  userId: ''
})

const createAdminUserUrl = import.meta.env.VITE_CREATE_ADMIN_USER_URL
const createChatAdminUserUrl = import.meta.env.VITE_CREATE_CHAT_ADMIN_USER_URL

const menu = [
  { to: '/accounting/journal', icon: '📒', label: 'Journal' },
  { to: '/accounting/journal/new', icon: '➕', label: 'New Entry' },
  { to: '/accounting/ledger', icon: '📊', label: 'Ledger' },
  { to: '/accounting/trial-balance', icon: '⚖️', label: 'Trial Balance' },
  { to: '/accounting/balance-sheet', icon: '🏛️', label: 'Balance Sheet' },
  { to: '/accounting/profit-loss', icon: '📈', label: 'Profit & Loss' },
  { to: '/accounting/income-report', icon: '💰', label: 'Income Report' },
  { to: '/accounting/expense-report', icon: '💸', label: 'Expense Report' },
  { to: '/accounting/create-account', icon: '🗂️', label: 'Create Account' }
]

const selectType = (type) => {
  userType.value = type
  showSelectionDialog.value = false
  showUserDialog.value = true
}

const handleCreateUser = async () => {
  const url = userType.value === 'site' ? createAdminUserUrl : createChatAdminUserUrl
  
  if (!url) {
    alert('Request URL is not configured.')
    return
  }

  isSubmitting.value = true
  try {
    const payload = userType.value === 'site' 
      ? { username: userForm.username, password: userForm.password }
      : { userId: userForm.userId }

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    if (response.ok) {
      alert('User created successfully!')
      showUserDialog.value = false
      userForm.username = ''
      userForm.password = ''
      userForm.userId = ''
    } else {
      const errorData = await response.json().catch(() => ({}))
      alert(`Failed to create user: ${errorData.message || response.statusText}`)
    }
  } catch (error) {
    console.error('Error creating user:', error)
    alert('An error occurred while creating the user.')
  } finally {
    isSubmitting.value = false
  }
}

const onNavClick = () => {
  if (window.innerWidth <= 640) {
    mobileOpen.value = false
  }
}
</script>

<style scoped>
.app-shell {
  display: grid;
  grid-template-columns: auto 1fr;
  height: 100vh;
  width: 100vw;
  background: var(--bg);
  color: var(--text);
  overflow: hidden;
}

.sidebar {
  width: 220px;
  background: var(--panel);
  border-right: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  z-index: 100;
}
.sidebar.collapsed { width: 64px; }

.sidebar-header {
  height: 60px;
  padding: 0 1.25rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid var(--border);
}

.logo { font-weight: 800; font-size: 1.1rem; color: var(--accent); letter-spacing: -0.03em; }

.nav-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.75rem 1.25rem;
  color: var(--muted);
  text-decoration: none;
  margin: 4px 8px;
  border-radius: 8px;
  transition: all 0.2s ease;
}
.nav-item:hover { background: rgba(255,255,255,0.03); color: var(--text); }
.router-link-active { color: var(--accent); background: rgba(16, 185, 129, 0.08); font-weight: 600; }

.main { display: flex; flex-direction: column; height: 100%; overflow: hidden; }

.top-bar { 
  height: 60px; 
  padding: 0 2rem; 
  display: flex; 
  align-items: center; 
  justify-content: space-between;
  border-bottom: 1px solid var(--border);
  background: var(--bg);
}

.flex-row { display: flex; align-items: center; }
.gap-1 { gap: 0.5rem; }

.title { font-size: 1rem; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: 0.05em; }

.content { 
  flex: 1; 
  overflow-y: auto; 
  padding: 2rem; /* Consistent desktop padding */
}

.user-create-btn {
  color: var(--muted);
  transition: color 0.2s ease;
}
.user-create-btn:hover {
  color: var(--accent);
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.8);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 200;
}

.modal-content {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 2rem;
  width: 100%;
  max-width: 400px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.5);
}

.selection-modal {
  max-width: 350px;
}

.modal-title {
  font-size: 1.25rem;
  font-weight: 700;
  margin-bottom: 1.5rem;
  color: var(--text);
  text-align: center;
}

.selection-actions {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.selection-btn {
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--border);
  padding: 1.25rem;
  border-radius: 12px;
  color: var(--text);
  font-weight: 700;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  transition: all 0.2s ease;
}
.selection-btn:hover {
  border-color: var(--accent);
  background: rgba(16, 185, 129, 0.05);
}

.selection-arrow {
  color: var(--muted);
  font-size: 1.2rem;
}
.selection-btn:hover .selection-arrow {
  color: var(--accent);
  transform: translateX(4px);
}

.user-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group label {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--muted);
}

.form-group input {
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 6px;
  padding: 0.75rem;
  color: var(--text);
  font-size: 0.9rem;
}
.form-group input:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2);
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 1rem;
}

.btn {
  padding: 0.6rem 1.25rem;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  border: none;
}

.btn-cancel {
  background: transparent;
  color: var(--muted);
}
.btn-cancel:hover {
  color: var(--text);
  background: rgba(255,255,255,0.05);
}

.btn-submit {
  background: var(--accent);
  color: white;
}
.btn-submit:hover {
  opacity: 0.9;
  transform: translateY(-1px);
}
.btn-submit:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.full-width {
  width: 100%;
  margin-top: 0.5rem;
}

@media (max-width: 640px) {
  .app-shell { grid-template-columns: 1fr; }
  .sidebar { position: fixed; left: 0; top: 0; bottom: 0; width: 280px; transform: translateX(-100%); }
  .sidebar.mobile-open { transform: translateX(0); box-shadow: 20px 0 50px rgba(0,0,0,0.5); }
  .sidebar.collapsed { width: 280px; }
  .top-bar { padding: 0 1rem; }
  .content { padding: 1rem; } /* Mobile breathing room */
  .hide-mobile { display: none; }
  .hide-desktop { display: block; }
}

.backdrop { position: fixed; inset: 0; background: rgba(0, 0, 0, 0.7); backdrop-filter: blur(4px); z-index: 90; }
.icon-btn { background: none; border: none; color: var(--text); font-size: 1.2rem; cursor: pointer; padding: 8px; display: flex; align-items: center; }
</style>
