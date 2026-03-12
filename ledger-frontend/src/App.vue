<template>
  <div class="min-h-screen bg-background flex">
    <!-- Mobile Backdrop -->
    <Transition name="fade">
      <div 
        v-if="sidebarOpen" 
        class="fixed inset-0 bg-black/60 backdrop-blur-sm z-40 lg:hidden"
        @click="sidebarOpen = false"
      />
    </Transition>

    <!-- Sidebar -->
    <aside 
      :class="[
        'fixed lg:static inset-y-0 left-0 z-50 flex flex-col w-72 bg-surface border-r border-border transition-transform duration-300 ease-out',
        'lg:translate-x-0',
        sidebarOpen ? 'translate-x-0' : '-translate-x-full'
      ]"
    >
      <!-- Logo -->
      <div class="h-16 flex items-center justify-between px-6 border-b border-border">
        <div class="flex items-center gap-3">
          <div class="w-9 h-9 rounded-lg bg-gradient-to-br from-primary to-primary/70 flex items-center justify-center shadow-glow-primary">
            <BookOpen class="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 class="text-lg font-bold text-text">FinanceFlow</h1>
            <p class="text-xs text-muted -mt-0.5">Accounting</p>
          </div>
        </div>
        <button 
          @click="sidebarOpen = false"
          class="lg:hidden p-1.5 rounded-lg hover:bg-surface-hover text-muted hover:text-text transition-colors"
        >
          <X class="w-5 h-5" />
        </button>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 overflow-y-auto py-4 px-3">
        <div class="space-y-1">
          <RouterLink 
            v-for="(item, index) in navItems" 
            :key="item.to"
            :to="item.to"
            :class="[
              'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 group',
              isActiveRoute(item.to) 
                ? 'bg-primary/10 text-primary' 
                : 'text-muted hover:text-text hover:bg-surface-hover'
            ]"
            @click="sidebarOpen = false"
          >
            <component 
              :is="item.icon" 
              :class="[
                'w-5 h-5 transition-colors',
                isActiveRoute(item.to) ? 'text-primary' : 'text-muted group-hover:text-text'
              ]"
            />
            <span>{{ item.label }}</span>
            <Transition name="fade">
              <div 
                v-if="isActiveRoute(item.to)" 
                class="ml-auto w-1.5 h-1.5 rounded-full bg-primary"
              />
            </Transition>
          </RouterLink>
        </div>
      </nav>

      <!-- User Section -->
      <div class="p-4 border-t border-border">
        <button 
          @click="showUserDialog = true"
          class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg hover:bg-surface-hover transition-colors"
        >
          <div class="w-9 h-9 rounded-lg bg-gradient-to-br from-success to-success/70 flex items-center justify-center">
            <UserPlus class="w-5 h-5 text-white" />
          </div>
          <div class="flex-1 text-left">
            <p class="text-sm font-medium text-text">Add User</p>
            <p class="text-xs text-muted">Create new admin</p>
          </div>
          <ChevronRight class="w-4 h-4 text-muted" />
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <div class="flex-1 flex flex-col min-h-screen">
      <!-- Top Header -->
      <header class="h-16 flex items-center justify-between px-4 lg:px-6 border-b border-border bg-surface/50 backdrop-blur-sm sticky top-0 z-30">
        <div class="flex items-center gap-3">
          <button 
            @click="sidebarOpen = true"
            class="lg:hidden p-2 rounded-lg hover:bg-surface-hover text-muted hover:text-text transition-colors"
          >
            <Menu class="w-5 h-5" />
          </button>
          <div>
            <h2 class="text-lg font-semibold text-text">{{ currentPageTitle }}</h2>
            <p class="text-xs text-muted hidden sm:block">{{ currentDate }}</p>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <!-- Quick Actions -->
          <button 
            @click="refreshData"
            :class="[
              'p-2.5 rounded-lg transition-all duration-200',
              isRefreshing ? 'animate-spin text-primary' : 'text-muted hover:text-text hover:bg-surface-hover'
            ]"
            title="Refresh data"
          >
            <RefreshCw class="w-5 h-5" />
          </button>
        </div>
      </header>

      <!-- Page Content -->
      <main class="flex-1 p-4 lg:p-6 overflow-y-auto">
        <RouterView v-slot="{ Component }">
          <Transition name="page" mode="out-in">
            <component :is="Component" @refresh="refreshData" />
          </Transition>
        </RouterView>
      </main>
    </div>

    <!-- User Creation Dialog -->
    <Transition name="modal">
      <div 
        v-if="showUserDialog" 
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
      >
        <div class="absolute inset-0 bg-black/70 backdrop-blur-sm" @click="showUserDialog = false" />
        
        <div class="relative w-full max-w-md bg-surface border border-border rounded-2xl shadow-2xl animate-scale-in">
          <!-- Dialog Header -->
          <div class="flex items-center justify-between p-6 border-b border-border">
            <h3 class="text-lg font-semibold text-text">Create New User</h3>
            <button 
              @click="showUserDialog = false"
              class="p-1.5 rounded-lg hover:bg-surface-hover text-muted hover:text-text transition-colors"
            >
              <X class="w-5 h-5" />
            </button>
          </div>

          <!-- Dialog Body -->
          <div class="p-6 space-y-4">
            <!-- User Type Selection -->
            <div class="grid grid-cols-2 gap-3">
              <button
                @click="userType = 'site'"
                :class="[
                  'p-4 rounded-xl border-2 transition-all duration-200 text-left',
                  userType === 'site' 
                    ? 'border-primary bg-primary/10' 
                    : 'border-border hover:border-border-light hover:bg-surface-hover'
                ]"
              >
                <Shield class="w-6 h-6 mb-2" :class="userType === 'site' ? 'text-primary' : 'text-muted'" />
                <p class="font-medium text-text">Site Admin</p>
                <p class="text-xs text-muted mt-0.5">Full system access</p>
              </button>
              <button
                @click="userType = 'chat'"
                :class="[
                  'p-4 rounded-xl border-2 transition-all duration-200 text-left',
                  userType === 'chat' 
                    ? 'border-success bg-success/10' 
                    : 'border-border hover:border-border-light hover:bg-surface-hover'
                ]"
              >
                <MessageSquare class="w-6 h-6 mb-2" :class="userType === 'chat' ? 'text-success' : 'text-muted'" />
                <p class="font-medium text-text">Chat Admin</p>
                <p class="text-xs text-muted mt-0.5">Chat management</p>
              </button>
            </div>

            <!-- Form Fields -->
            <Transition name="fade" mode="out-in">
              <div v-if="userType === 'site'" key="site" class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-text-secondary mb-1.5">Username</label>
                  <input 
                    v-model="userForm.username"
                    type="text" 
                    class="input"
                    placeholder="Enter username"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-text-secondary mb-1.5">Password</label>
                  <input 
                    v-model="userForm.password"
                    type="password" 
                    class="input"
                    placeholder="Enter password"
                  />
                </div>
              </div>
              <div v-else key="chat" class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-text-secondary mb-1.5">User ID</label>
                  <input 
                    v-model="userForm.userId"
                    type="text" 
                    class="input"
                    placeholder="Enter chat user ID"
                  />
                </div>
              </div>
            </Transition>
          </div>

          <!-- Dialog Footer -->
          <div class="flex items-center justify-end gap-3 p-6 border-t border-border">
            <button 
              @click="showUserDialog = false"
              class="btn btn-ghost"
            >
              Cancel
            </button>
            <button 
              @click="createUser"
              :disabled="isCreating"
              class="btn btn-primary"
            >
              <Loader2 v-if="isCreating" class="w-4 h-4 animate-spin" />
              <span>{{ isCreating ? 'Creating...' : 'Create User' }}</span>
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
          'fixed bottom-6 right-6 z-50 flex items-center gap-3 px-4 py-3 rounded-xl shadow-lg border',
          toast.type === 'success' ? 'bg-success/10 border-success/30 text-success' : 'bg-danger/10 border-danger/30 text-danger'
        ]"
      >
        <CheckCircle v-if="toast.type === 'success'" class="w-5 h-5" />
        <AlertCircle v-else class="w-5 h-5" />
        <span class="text-sm font-medium">{{ toast.message }}</span>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, reactive } from 'vue'
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
  Users
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()

const sidebarOpen = ref(false)
const showUserDialog = ref(false)
const userType = ref('site')
const isCreating = ref(false)
const isRefreshing = ref(false)

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

const navItems = [
  { to: '/accounting/', icon: Library, label: 'Dashboard', isNew: true },
  { to: '/accounting/journal', icon: FileText, label: 'Journal Entries' },
  { to: '/accounting/journal/new', icon: PlusCircle, label: 'New Entry' },
  { to: '/accounting/ledger', icon: Library, label: 'General Ledger' },
  { to: '/accounting/trial-balance', icon: Scale, label: 'Trial Balance' },
  { to: '/accounting/balance-sheet', icon: Building2, label: 'Balance Sheet' },
  { to: '/accounting/profit-loss', icon: TrendingUp, label: 'Profit & Loss' },
  { to: '/accounting/income-report', icon: DollarSign, label: 'Income Report' },
  { to: '/accounting/expense-report', icon: Wallet, label: 'Expense Report' },
  { to: '/accounting/create-account', icon: Users, label: 'Create Account' }
]

const currentPageTitle = computed(() => {
  const currentItem = navItems.find(item => item.to === route.path)
  return currentItem?.label || 'Accounting'
})

const currentDate = computed(() => {
  return new Date().toLocaleDateString('en-US', { 
    weekday: 'long', 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  })
})

const isActiveRoute = (path) => {
  return route.path === path || route.path.startsWith(path + '/')
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
    showToast('Request URL is not configured.', 'error')
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
      showToast('User created successfully!')
      showUserDialog.value = false
      userForm.username = ''
      userForm.password = ''
      userForm.userId = ''
    } else {
      const errorData = await response.json().catch(() => ({}))
      showToast(`Failed: ${errorData.message || response.statusText}`, 'error')
    }
  } catch (error) {
    console.error('Error creating user:', error)
    showToast('An error occurred while creating the user.', 'error')
  } finally {
    isCreating.value = false
  }
}

const refreshData = () => {
  isRefreshing.value = true
  // Emit refresh event to current component
  const currentComponent = route.meta?.component
  setTimeout(() => {
    isRefreshing.value = false
    showToast('Data refreshed')
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
