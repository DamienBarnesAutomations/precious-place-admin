<template>
  <div class="h-screen bg-background flex font-sans overflow-hidden">
    <!-- Mobile Backdrop -->
    <Transition name="fade">
      <div 
        v-if="sidebarOpen" 
        class="fixed inset-0 bg-black/80 backdrop-blur-md z-40 lg:hidden"
        @click="sidebarOpen = false"
      />
    </Transition>

    <!-- Sidebar -->
    <aside 
      :class="[
        'fixed lg:static inset-y-0 left-0 z-50 flex flex-col w-64 bg-surface border-r border-border transition-transform duration-300 ease-out',
        'lg:translate-x-0',
        sidebarOpen ? 'translate-x-0' : '-translate-x-full'
      ]"
    >
      <!-- Logo -->
      <div class="h-14 flex items-center justify-between px-5 border-b border-border bg-background/20 shrink-0">
        <div class="flex items-center gap-2.5">
          <div class="w-8 h-8 rounded bg-primary flex items-center justify-center shadow-glow-primary">
            <BookOpen class="w-4 h-4 text-white" />
          </div>
          <div>
            <h1 class="text-sm font-black tracking-tighter text-text uppercase">LedgerOS</h1>
            <p class="text-[10px] font-bold text-primary tracking-widest uppercase -mt-1">Accounting</p>
          </div>
        </div>
        <button 
          @click="sidebarOpen = false"
          class="lg:hidden p-1.5 rounded hover:bg-surface-hover text-muted transition-colors"
        >
          <X class="w-4 h-4" />
        </button>
      </div>

      <!-- Navigation Groups -->
      <nav class="flex-1 overflow-y-auto py-4 px-3 custom-scrollbar">
        <div v-for="group in navGroups" :key="group.title" class="mb-6 last:mb-0">
          <h3 class="px-3 mb-2 text-[10px] font-black text-muted-dark uppercase tracking-[0.2em]">
            {{ group.title }}
          </h3>
          <div class="space-y-0.5">
            <RouterLink 
              v-for="item in group.items" 
              :key="item.to"
              :to="item.to"
              :class="[
                'flex items-center gap-2.5 px-3 py-1.5 rounded transition-all duration-150 group border border-transparent',
                isActiveRoute(item.to) 
                  ? 'bg-primary/10 text-primary border-primary/20 shadow-sm' 
                  : 'text-muted hover:text-text hover:bg-surface-hover'
              ]"
              @click="sidebarOpen = false"
            >
              <component 
                :is="item.icon" 
                :class="[
                  'w-4 h-4 transition-colors',
                  isActiveRoute(item.to) ? 'text-primary' : 'text-muted group-hover:text-text'
                ]"
              />
              <span class="text-[13px] font-semibold tracking-tight">{{ item.label }}</span>
              <div 
                v-if="isActiveRoute(item.to)" 
                class="ml-auto w-1 h-1 rounded-full bg-primary animate-pulse"
              />
            </RouterLink>
          </div>
        </div>
      </nav>

      <!-- Administration Section -->
      <div class="p-3 bg-background/30 border-t border-border shrink-0">
        <h3 class="px-3 mb-2 text-[10px] font-black text-muted-dark uppercase tracking-[0.2em]">
          Administration
        </h3>
        <button 
          @click="showUserDialog = true"
          class="w-full flex items-center gap-2.5 px-3 py-2 rounded hover:bg-surface-hover transition-colors group border border-transparent hover:border-border-light"
        >
          <div class="w-7 h-7 rounded bg-muted/10 flex items-center justify-center group-hover:bg-primary/10 transition-colors">
            <UserPlus class="w-3.5 h-3.5 text-muted group-hover:text-primary" />
          </div>
          <div class="flex-1 text-left">
            <p class="text-[12px] font-bold text-text-secondary group-hover:text-text">Add Account</p>
          </div>
          <ChevronRight class="w-3 h-3 text-muted-dark group-hover:translate-x-0.5 transition-transform" />
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <div class="flex-1 flex flex-col h-screen min-w-0 overflow-hidden">
      <!-- Top Header -->
      <header class="h-14 flex items-center justify-between px-4 lg:px-6 border-b border-border bg-surface/80 backdrop-blur-xl sticky top-0 z-30 shrink-0">
        <div class="flex items-center gap-4">
          <button 
            @click="sidebarOpen = true"
            class="lg:hidden p-1.5 rounded bg-surface-hover text-muted hover:text-text transition-colors"
          >
            <Menu class="w-4 h-4" />
          </button>
          <div class="flex items-center gap-2">
            <span class="text-xs font-black text-muted uppercase tracking-widest hidden sm:block">Location</span>
            <div class="h-4 w-[1px] bg-border mx-1 hidden sm:block"></div>
            <h2 class="text-sm font-bold text-text">{{ currentPageTitle }}</h2>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <div class="hidden md:flex flex-col items-end">
            <p class="text-[10px] font-black text-muted uppercase tracking-tighter">{{ currentDate }}</p>
            <p class="text-[9px] font-bold text-success uppercase tracking-widest">System Balanced</p>
          </div>
          <div class="h-8 w-[1px] bg-border mx-1 hidden md:block"></div>
          
          <div class="flex items-center gap-1.5 bg-background/50 p-1 rounded-full border border-border">
            <button 
              @click="toggleTheme"
              class="p-1.5 rounded-full transition-all duration-300 hover:bg-surface-hover text-muted hover:text-text"
              :title="isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'"
            >
              <Sun v-if="isDark" class="w-3.5 h-3.5" />
              <Moon v-else class="w-3.5 h-3.5" />
            </button>
            <button 
              @click="refreshData"
              :class="[
                'p-1.5 rounded-full transition-all duration-300 border border-transparent',
                isRefreshing ? 'animate-spin text-primary bg-primary/10' : 'text-muted hover:text-text hover:bg-surface-hover hover:border-border-light'
              ]"
              title="Refresh Ledger"
            >
              <RefreshCw class="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </header>

      <!-- Page Content -->
      <main class="flex-1 p-4 lg:p-6 overflow-y-auto custom-scrollbar">
        <div class="max-w-7xl mx-auto">
          <RouterView v-slot="{ Component }">
            <Transition name="page" mode="out-in">
              <component :is="Component" @refresh="refreshData" />
            </Transition>
          </RouterView>
        </div>
      </main>
    </div>

    <!-- User Creation Dialog -->
    <Transition name="modal">
      <div 
        v-if="showUserDialog" 
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
      >
        <div class="absolute inset-0 bg-black/90 backdrop-blur-sm" @click="showUserDialog = false" />
        
        <div class="relative w-full max-w-md bg-surface border border-border rounded-lg shadow-2xl animate-scale-in overflow-hidden">
          <!-- Dialog Header -->
          <div class="flex items-center justify-between p-4 bg-background/50 border-b border-border">
            <div class="flex items-center gap-2">
              <Shield class="w-4 h-4 text-primary" />
              <h3 class="text-xs font-black text-text uppercase tracking-widest">New Administrative Account</h3>
            </div>
            <button 
              @click="showUserDialog = false"
              class="p-1 rounded hover:bg-surface-hover text-muted transition-colors"
            >
              <X class="w-4 h-4" />
            </button>
          </div>

          <!-- Dialog Body -->
          <div class="p-6 space-y-5">
            <!-- User Type Selection -->
            <div class="grid grid-cols-2 gap-3">
              <button
                @click="userType = 'site'"
                :class="[
                  'p-4 rounded border-2 transition-all duration-150 text-left relative overflow-hidden group',
                  userType === 'site' 
                    ? 'border-primary bg-primary/5' 
                    : 'border-border hover:border-muted/30 hover:bg-surface-hover'
                ]"
              >
                <div v-if="userType === 'site'" class="absolute top-0 right-0 p-1">
                  <CheckCircle class="w-3 h-3 text-primary" />
                </div>
                <Shield class="w-5 h-5 mb-2" :class="userType === 'site' ? 'text-primary' : 'text-muted-dark'" />
                <p class="text-[11px] font-black text-text uppercase tracking-wider">System Admin</p>
                <p class="text-[9px] text-muted mt-0.5 font-bold uppercase tracking-tighter leading-none">Complete Control</p>
              </button>
              <button
                @click="userType = 'chat'"
                :class="[
                  'p-4 rounded border-2 transition-all duration-150 text-left relative overflow-hidden group',
                  userType === 'chat' 
                    ? 'border-success bg-success/5' 
                    : 'border-border hover:border-muted/30 hover:bg-surface-hover'
                ]"
              >
                <div v-if="userType === 'chat'" class="absolute top-0 right-0 p-1">
                  <CheckCircle class="w-3 h-3 text-success" />
                </div>
                <MessageSquare class="w-5 h-5 mb-2" :class="userType === 'chat' ? 'text-success' : 'text-muted-dark'" />
                <p class="text-[11px] font-black text-text uppercase tracking-wider">Staff Account</p>
                <p class="text-[9px] text-muted mt-0.5 font-bold uppercase tracking-tighter leading-none">Limited Access</p>
              </button>
            </div>

            <!-- Form Fields -->
            <Transition name="fade" mode="out-in">
              <div v-if="userType === 'site'" key="site" class="space-y-4">
                <div class="space-y-1.5">
                  <label class="text-[10px] font-black text-muted-dark uppercase tracking-widest">Username</label>
                  <input 
                    v-model="userForm.username"
                    type="text" 
                    class="input"
                    placeholder="ADMIN_USER"
                  />
                </div>
                <div class="space-y-1.5">
                  <label class="text-[10px] font-black text-muted-dark uppercase tracking-widest">Password</label>
                  <input 
                    v-model="userForm.password"
                    type="password" 
                    class="input"
                    placeholder="••••••••"
                  />
                </div>
              </div>
              <div v-else key="chat" class="space-y-4">
                <div class="space-y-1.5">
                  <label class="text-[10px] font-black text-muted-dark uppercase tracking-widest">System User ID</label>
                  <input 
                    v-model="userForm.userId"
                    type="text" 
                    class="input"
                    placeholder="USER_ID_7782"
                  />
                </div>
              </div>
            </Transition>
          </div>

          <!-- Dialog Footer -->
          <div class="flex items-center justify-end gap-2 p-4 bg-background/50 border-t border-border">
            <button 
              @click="showUserDialog = false"
              class="btn btn-ghost"
            >
              Cancel
            </button>
            <button 
              @click="createUser"
              :disabled="isCreating"
              class="btn btn-primary min-w-[120px]"
            >
              <Loader2 v-if="isCreating" class="w-3.5 h-3.5 animate-spin" />
              <span class="text-[11px] font-black uppercase tracking-widest">{{ isCreating ? 'Verifying...' : 'Authorize' }}</span>
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Toast Notification -->
    <Transition name="toast">
      <div 
        v-if="toast.show" 
        :class="[
          'fixed bottom-6 right-6 z-50 flex items-center gap-3 px-4 py-2.5 rounded shadow-2xl border backdrop-blur-md',
          toast.type === 'success' ? 'bg-success/10 border-success/30 text-success' : 'bg-danger/10 border-danger/30 text-danger'
        ]"
      >
        <div :class="['p-1 rounded-full', toast.type === 'success' ? 'bg-success/20' : 'bg-danger/20']">
          <CheckCircle v-if="toast.type === 'success'" class="w-4 h-4" />
          <AlertCircle v-else class="w-4 h-4" />
        </div>
        <span class="text-xs font-black uppercase tracking-widest">{{ toast.message }}</span>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, reactive, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { 
  BookOpen, 
  Menu, 
  X, 
  ChevronRight,
  UserPlus,
  RefreshCw,
  Loader2,
  CheckCircle,
  AlertCircle,
  Shield,
  MessageSquare,
  FileText,
  PlusCircle,
  Library,
  Scale,
  Building2,
  TrendingUp,
  DollarSign,
  Wallet,
  Users,
  LayoutDashboard,
  Sun,
  Moon
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()

const sidebarOpen = ref(false)
const showUserDialog = ref(false)
const userType = ref('site')
const isCreating = ref(false)
const isRefreshing = ref(false)
const isDark = ref(localStorage.getItem('ledger-theme') !== 'light')

const toggleTheme = () => {
  isDark.value = !isDark.value
  localStorage.setItem('ledger-theme', isDark.value ? 'dark' : 'light')
}

watch(isDark, (val) => {
  if (val) {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }
}, { immediate: true })

const userForm = reactive({
  username: '',
  password: '',
  userId: ''
})

const toast = ref({
  show: false,
  message: '',
  type: 'success'
})

const createAdminUserUrl = import.meta.env.VITE_CREATE_ADMIN_USER_URL
const createChatAdminUserUrl = import.meta.env.VITE_CREATE_CHAT_ADMIN_USER_URL

const navGroups = [
  {
    title: 'Overview',
    items: [
      { to: '/accounting/', icon: LayoutDashboard, label: 'Control Center' }
    ]
  },
  {
    title: 'Accounting',
    items: [
      { to: '/accounting/journal', icon: FileText, label: 'Journal Records' },
      { to: '/accounting/journal/new', icon: PlusCircle, label: 'Post Entry' },
      { to: '/accounting/ledger', icon: Library, label: 'General Ledger' },
      { to: '/accounting/trial-balance', icon: Scale, label: 'Trial Balance' }
    ]
  },
  {
    title: 'Financials',
    items: [
      { to: '/accounting/profit-loss', icon: TrendingUp, label: 'Profit & Loss' },
      { to: '/accounting/balance-sheet', icon: Building2, label: 'Balance Sheet' },
      { to: '/accounting/income-report', icon: DollarSign, label: 'Income Statements' },
      { to: '/accounting/expense-report', icon: Wallet, label: 'Expense Analysis' }
    ]
  },
  {
    title: 'Setup',
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

const currentDate = computed(() => {
  return new Date().toLocaleDateString('en-US', { 
    weekday: 'short', 
    year: 'numeric', 
    month: 'short', 
    day: 'numeric' 
  }).toUpperCase()
})

const isActiveRoute = (path) => {
  return route.path === path || (path !== '/accounting/' && route.path.startsWith(path))
}

const showToast = (message, type = 'success') => {
  toast.value = { show: true, message, type }
  setTimeout(() => {
    toast.value.show = false
  }, 3000)
}

const createUser = async () => {
  const url = userType.value === 'site' ? createAdminUserUrl : createChatAdminUserUrl
  
  if (!url) {
    showToast('SYSTEM_URL_NOT_CONFIGURED', 'error')
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
      showToast('AUTHORIZATION_SUCCESS')
      showUserDialog.value = false
      userForm.username = ''
      userForm.password = ''
      userForm.userId = ''
    } else {
      const errorData = await response.json().catch(() => ({}))
      showToast(`AUTH_FAILED: ${errorData.message || response.statusText}`, 'error')
    }
  } catch (error) {
    console.error('Error creating user:', error)
    showToast('INTERNAL_AUTH_ERROR', 'error')
  } finally {
    isCreating.value = false
  }
}

const refreshData = () => {
  isRefreshing.value = true
  setTimeout(() => {
    isRefreshing.value = false
    showToast('LEDGER_RECONCILED')
  }, 1000)
}
</script>

<style scoped>
/* Page Transitions */
.page-enter-active,
.page-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.page-enter-from {
  opacity: 0;
  transform: translateY(10px);
}

.page-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

/* Modal Transitions */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s ease;
}

.modal-enter-active .animate-scale-in,
.modal-leave-active .animate-scale-in {
  transition: transform 0.2s ease, opacity 0.2s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-from .animate-scale-in {
  transform: scale(0.95);
  opacity: 0;
}

.modal-leave-to .animate-scale-in {
  transform: scale(0.95);
  opacity: 0;
}

/* Fade Transition */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Toast Transition */
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateY(20px);
}
</style>
