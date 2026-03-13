<template>
  <div class="h-screen flex font-sans overflow-hidden bg-background text-text">
    <!-- Mobile Backdrop -->
    <Transition name="fade">
      <div 
        v-if="sidebarOpen" 
        class="fixed inset-0 bg-slate-900/50 z-40 lg:hidden"
        @click="sidebarOpen = false"
      />
    </Transition>

    <!-- Sidebar -->
    <aside 
      :class="[
        'fixed lg:static inset-y-0 left-0 z-50 flex flex-col w-[240px] bg-slate-900 border-r border-slate-800 transition-transform duration-200 ease-out',
        'lg:translate-x-0',
        sidebarOpen ? 'translate-x-0' : '-translate-x-full'
      ]"
    >
      <!-- Brand -->
      <div class="h-14 flex items-center px-4 border-b border-slate-800 bg-slate-950/50 shrink-0">
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded bg-primary flex items-center justify-center text-white shadow-sm">
            <BookOpen class="w-4 h-4" />
          </div>
          <div>
            <h1 class="text-sm font-bold text-white tracking-tight">LedgerOS</h1>
            <p class="text-[10px] font-medium text-slate-400 uppercase tracking-widest">Accounting</p>
          </div>
        </div>
        <button 
          @click="sidebarOpen = false"
          class="lg:hidden ml-auto p-1 text-slate-400 hover:text-white"
        >
          <X class="w-5 h-5" />
        </button>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 overflow-y-auto py-4 px-2 space-y-6 custom-scrollbar">
        <div v-for="group in navGroups" :key="group.title">
          <h3 class="px-3 mb-2 text-[10px] font-bold text-slate-500 uppercase tracking-widest">
            {{ group.title }}
          </h3>
          <div class="space-y-0.5">
            <RouterLink 
              v-for="item in group.items" 
              :key="item.to"
              :to="item.to"
              :class="[
                'flex items-center gap-3 px-3 py-2 rounded text-xs font-medium transition-colors',
                isActiveRoute(item.to) 
                  ? 'bg-primary text-white shadow-sm' 
                  : 'text-slate-400 hover:bg-slate-800 hover:text-slate-200'
              ]"
              @click="sidebarOpen = false"
            >
              <component 
                :is="item.icon" 
                :class="[
                  'w-4 h-4',
                  isActiveRoute(item.to) ? 'text-white' : 'text-slate-500 group-hover:text-slate-300'
                ]"
              />
              <span>{{ item.label }}</span>
            </RouterLink>
          </div>
        </div>
      </nav>

      <!-- User/Admin Footer -->
      <div class="p-4 border-t border-slate-800 bg-slate-950/30">
        <button 
          @click="showUserDialog = true"
          class="w-full flex items-center gap-3 px-3 py-2 rounded hover:bg-slate-800 transition-colors group"
        >
          <div class="w-8 h-8 rounded-full bg-slate-800 flex items-center justify-center text-slate-400 group-hover:text-white">
            <UserPlus class="w-4 h-4" />
          </div>
          <div class="text-left">
            <p class="text-xs font-medium text-slate-300 group-hover:text-white">Admin Access</p>
            <p class="text-[10px] text-slate-500">Manage Users</p>
          </div>
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <div class="flex-1 flex flex-col h-screen min-w-0 bg-background">
      <!-- Top Header -->
      <header class="h-14 flex items-center justify-between px-4 lg:px-6 border-b border-border bg-surface sticky top-0 z-30 shrink-0">
        <div class="flex items-center gap-4">
          <button 
            @click="sidebarOpen = true"
            class="lg:hidden p-1.5 text-muted hover:text-text transition-colors"
          >
            <Menu class="w-5 h-5" />
          </button>
          
          <div class="flex items-center gap-3">
             <!-- Breadcrumb-ish Location -->
            <div class="hidden sm:flex items-center gap-2 text-xs font-medium text-muted">
              <span>LedgerOS</span>
              <span class="text-border">/</span>
            </div>
            <h2 class="text-sm font-bold text-text">{{ currentPageTitle }}</h2>
          </div>
        </div>

        <div class="flex items-center gap-4">
          <!-- System Status Indicator (Global) -->
          <div class="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-full bg-slate-100 border border-slate-200">
            <div class="relative flex h-2 w-2">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
              <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
            </div>
            <span class="text-[10px] font-bold text-slate-600 uppercase tracking-widest">System Operational</span>
          </div>

          <div class="h-4 w-px bg-border mx-1 hidden sm:block"></div>
          
          <div class="flex items-center gap-2">
            <button 
              @click="toggleTheme"
              class="p-2 rounded text-muted hover:text-primary hover:bg-surface-hover transition-colors"
              :title="isDark ? 'Light Mode' : 'Dark Mode'"
            >
              <Sun v-if="isDark" class="w-4 h-4" />
              <Moon v-else class="w-4 h-4" />
            </button>
            <button 
              @click="refreshData"
              :class="[
                'p-2 rounded transition-colors',
                isRefreshing ? 'text-primary animate-spin' : 'text-muted hover:text-primary hover:bg-surface-hover'
              ]"
              title="Refresh Data"
            >
              <RefreshCw class="w-4 h-4" />
            </button>
          </div>
        </div>
      </header>

      <!-- Page Content -->
      <main class="flex-1 p-4 lg:p-8 overflow-y-auto custom-scrollbar bg-background">
        <div class="max-w-7xl mx-auto space-y-6">
          <RouterView v-slot="{ Component }">
            <Transition name="fade" mode="out-in">
              <component :is="Component" @refresh="refreshData" />
            </Transition>
          </RouterView>
        </div>
      </main>
    </div>

    <!-- User Creation Dialog -->
    <Transition name="modal">
      <div v-if="showUserDialog" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showUserDialog = false" />
        <div class="relative w-full max-w-md bg-surface border border-border rounded shadow-xl overflow-hidden">
          <div class="px-6 py-4 border-b border-border flex items-center justify-between bg-slate-50">
            <h3 class="text-sm font-bold text-text uppercase tracking-wider">New System User</h3>
            <button @click="showUserDialog = false" class="text-muted hover:text-text">
              <X class="w-4 h-4" />
            </button>
          </div>
          
          <div class="p-6 space-y-4">
             <!-- User Type Selector -->
            <div class="grid grid-cols-2 gap-4">
              <button 
                @click="userType = 'site'"
                :class="[
                  'p-3 border rounded text-left transition-all',
                  userType === 'site' ? 'border-primary bg-primary/5 ring-1 ring-primary' : 'border-border hover:bg-slate-50'
                ]"
              >
                <Shield class="w-5 h-5 mb-2" :class="userType === 'site' ? 'text-primary' : 'text-muted'" />
                <div class="text-xs font-bold text-text">Administrator</div>
                <div class="text-[10px] text-muted mt-0.5">Full System Control</div>
              </button>
              
              <button 
                @click="userType = 'chat'"
                 :class="[
                  'p-3 border rounded text-left transition-all',
                  userType === 'chat' ? 'border-emerald-500 bg-emerald-50 ring-1 ring-emerald-500' : 'border-border hover:bg-slate-50'
                ]"
              >
                <MessageSquare class="w-5 h-5 mb-2" :class="userType === 'chat' ? 'text-emerald-600' : 'text-muted'" />
                <div class="text-xs font-bold text-text">Staff / Chat</div>
                <div class="text-[10px] text-muted mt-0.5">Restricted Access</div>
              </button>
            </div>

            <!-- Inputs -->
            <div v-if="userType === 'site'" class="space-y-3">
              <div>
                <label class="block text-xs font-semibold text-muted-dark mb-1.5 uppercase">Username</label>
                <input v-model="userForm.username" type="text" class="input" placeholder="admin_user" />
              </div>
              <div>
                <label class="block text-xs font-semibold text-muted-dark mb-1.5 uppercase">Password</label>
                <input v-model="userForm.password" type="password" class="input" placeholder="••••••••" />
              </div>
            </div>
            <div v-else class="space-y-3">
               <div>
                <label class="block text-xs font-semibold text-muted-dark mb-1.5 uppercase">Telegram ID</label>
                <input v-model="userForm.userId" type="text" class="input input-mono" placeholder="123456789" />
              </div>
            </div>
          </div>

          <div class="px-6 py-4 border-t border-border bg-slate-50 flex justify-end gap-3">
            <button @click="showUserDialog = false" class="btn btn-outline">Cancel</button>
            <button @click="createUser" :disabled="isCreating" class="btn btn-primary min-w-[100px]">
              <Loader2 v-if="isCreating" class="w-3 h-3 animate-spin" />
              <span>{{ isCreating ? 'Saving...' : 'Create User' }}</span>
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Toast -->
    <Transition name="toast">
      <div 
        v-if="toast.show" 
        :class="[
          'fixed bottom-6 right-6 z-50 flex items-center gap-3 px-4 py-3 rounded shadow-lg border',
          toast.type === 'success' ? 'bg-white border-success/30 text-success-text' : 'bg-white border-danger/30 text-danger-text'
        ]"
      >
        <CheckCircle v-if="toast.type === 'success'" class="w-5 h-5 text-success" />
        <AlertCircle v-else class="w-5 h-5 text-danger" />
        <div>
          <p class="text-xs font-bold uppercase tracking-wide">{{ toast.message }}</p>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, reactive, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { 
  BookOpen, Menu, X, ChevronRight, UserPlus, RefreshCw, Loader2, 
  CheckCircle, AlertCircle, Shield, MessageSquare, FileText, 
  PlusCircle, Library, Scale, Building2, TrendingUp, DollarSign, 
  Wallet, Users, LayoutDashboard, Sun, Moon 
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()

const sidebarOpen = ref(false)
const showUserDialog = ref(false)
const userType = ref('site')
const isCreating = ref(false)
const isRefreshing = ref(false)
const isDark = ref(localStorage.getItem('ledger-theme') === 'dark')

const toggleTheme = () => {
  isDark.value = !isDark.value
  localStorage.setItem('ledger-theme', isDark.value ? 'dark' : 'light')
}

watch(isDark, (val) => {
  if (val) document.documentElement.classList.add('dark')
  else document.documentElement.classList.remove('dark')
}, { immediate: true })

const userForm = reactive({ username: '', password: '', userId: '' })
const toast = ref({ show: false, message: '', type: 'success' })

const createAdminUserUrl = import.meta.env.VITE_CREATE_ADMIN_USER_URL
const createChatAdminUserUrl = import.meta.env.VITE_CREATE_CHAT_ADMIN_USER_URL

const navGroups = [
  {
    title: 'Control',
    items: [
      { to: '/accounting/', icon: LayoutDashboard, label: 'Dashboard' }
    ]
  },
  {
    title: 'Ledger',
    items: [
      { to: '/accounting/journal/new', icon: PlusCircle, label: 'New Entry' },
      { to: '/accounting/journal', icon: FileText, label: 'Journal' },
      { to: '/accounting/ledger', icon: Library, label: 'General Ledger' },
      { to: '/accounting/trial-balance', icon: Scale, label: 'Trial Balance' }
    ]
  },
  {
    title: 'Reporting',
    items: [
      { to: '/accounting/profit-loss', icon: TrendingUp, label: 'Profit & Loss' },
      { to: '/accounting/balance-sheet', icon: Building2, label: 'Balance Sheet' },
      { to: '/accounting/income-report', icon: DollarSign, label: 'Income' },
      { to: '/accounting/expense-report', icon: Wallet, label: 'Expenses' }
    ]
  },
  {
    title: 'Configuration',
    items: [
      { to: '/accounting/create-account', icon: Users, label: 'Chart of Accounts' }
    ]
  }
]

const navItems = navGroups.flatMap(g => g.items)
const currentPageTitle = computed(() => {
  const currentItem = navItems.find(item => item.to === route.path)
  return currentItem?.label || 'LedgerOS'
})

const isActiveRoute = (path) => route.path === path || (path !== '/accounting/' && route.path.startsWith(path))

const showToast = (message, type = 'success') => {
  toast.value = { show: true, message, type }
  setTimeout(() => toast.value.show = false, 3000)
}

const createUser = async () => {
  const url = userType.value === 'site' ? createAdminUserUrl : createChatAdminUserUrl
  if (!url) {
    showToast('Configuration Error: Missing API URL', 'error')
    return
  }

  isCreating.value = true
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
      showToast('User authorized successfully')
      showUserDialog.value = false
      userForm.username = ''
      userForm.password = ''
      userForm.userId = ''
    } else {
      const errorData = await response.json().catch(() => ({}))
      showToast(errorData.message || 'Authorization failed', 'error')
    }
  } catch (error) {
    showToast('Network error', 'error')
  } finally {
    isCreating.value = false
  }
}

const refreshData = () => {
  isRefreshing.value = true
  setTimeout(() => {
    isRefreshing.value = false
    showToast('System data refreshed')
  }, 800)
}
</script>

<style scoped>
/* Precise transitions */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s ease;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}
.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
</style>
