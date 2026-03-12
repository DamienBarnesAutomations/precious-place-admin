<script setup>
import { ref, onMounted, computed } from 'vue'
import { 
  FileText, 
  PlusCircle, 
  Library, 
  Scale, 
  Building2, 
  TrendingUp, 
  DollarSign, 
  Wallet,
  ArrowUpRight,
  ArrowDownRight,
  Clock,
  CheckCircle,
  AlertCircle,
  Loader2
} from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

// State
const isLoading = ref(true)
const stats = ref({
  totalTransactions: 0,
  totalDebit: 0,
  totalCredit: 0,
  accountsCount: 0,
  recentActivity: []
})

const journalWebhook = import.meta.env.VITE_GET_JOURNAL_ENTRIES_WEBHOOK
const accountsWebhook = import.meta.env.VITE_GET_ACCOUNTS_WEBHOOK

// Fetch data
const fetchDashboardData = async () => {
  isLoading.value = true
  try {
    // Fetch journal entries
    if (journalWebhook) {
      const journalRes = await fetch(journalWebhook)
      if (journalRes.ok) {
        const journalData = await journalRes.json()
        if (Array.isArray(journalData)) {
          const entries = journalData.filter(e => e && Object.keys(e).length > 0)
          stats.value.totalTransactions = entries.length
          stats.value.totalDebit = entries.reduce((sum, e) => sum + (Number(e.total_debit) || 0), 0)
          stats.value.totalCredit = entries.reduce((sum, e) => sum + (Number(e.total_credit) || 0), 0)
          stats.value.recentActivity = entries.slice(0, 5)
        }
      }
    }

    // Fetch accounts count
    if (accountsWebhook) {
      const accountsRes = await fetch(accountsWebhook)
      if (accountsRes.ok) {
        const accountsData = await accountsRes.json()
        if (Array.isArray(accountsData)) {
          stats.value.accountsCount = accountsData.filter(a => a && Object.keys(a).length > 0).length
        }
      }
    }
  } catch (error) {
    console.error('Error fetching dashboard data:', error)
  } finally {
    isLoading.value = false
  }
}

onMounted(fetchDashboardData)

// Format currency
const formatCurrency = (value) => {
  const num = Number(value) || 0
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2
  }).format(num)
}

// Quick stats cards
const quickStats = computed(() => [
  {
    title: 'Total Transactions',
    value: stats.value.totalTransactions,
    icon: FileText,
    color: 'primary',
    change: '+12.5%',
    changeType: 'positive'
  },
  {
    title: 'Total Debit',
    value: formatCurrency(stats.value.totalDebit),
    icon: ArrowDownRight,
    color: 'danger',
    change: '+8.2%',
    changeType: 'positive'
  },
  {
    title: 'Total Credit',
    value: formatCurrency(stats.value.totalCredit),
    icon: ArrowUpRight,
    color: 'success',
    change: '+5.7%',
    changeType: 'positive'
  },
  {
    title: 'Active Accounts',
    value: stats.value.accountsCount,
    icon: Library,
    color: 'info',
    change: '+2',
    changeType: 'positive'
  }
])

// Navigation items for quick access
const quickLinks = [
  { to: '/accounting/journal/new', icon: PlusCircle, label: 'New Entry', color: 'primary' },
  { to: '/accounting/ledger', icon: Library, label: 'View Ledger', color: 'success' },
  { to: '/accounting/trial-balance', icon: Scale, label: 'Trial Balance', color: 'warning' },
  { to: '/accounting/balance-sheet', icon: Building2, label: 'Balance Sheet', color: 'info' }
]
</script>

<template>
  <div class="space-y-6">
    <!-- Welcome Section -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-text">Welcome Back</h1>
        <p class="text-muted mt-1">Here's what's happening with your finances today.</p>
      </div>
      <RouterLink to="/accounting/journal/new" class="btn btn-primary">
        <PlusCircle class="w-5 h-5" />
        <span>New Journal Entry</span>
      </RouterLink>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex items-center justify-center py-20">
      <Loader2 class="w-8 h-8 text-primary animate-spin" />
    </div>

    <template v-else>
      <!-- Quick Stats Grid -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div 
          v-for="(stat, index) in quickStats" 
          :key="stat.title"
          class="card card-hover animate-fade-in"
          :style="{ animationDelay: `${index * 100}ms` }"
        >
          <div class="flex items-start justify-between">
            <div>
              <p class="text-sm text-muted">{{ stat.title }}</p>
              <p class="text-2xl font-bold text-text mt-1">{{ stat.value }}</p>
            </div>
            <div 
              :class="[
                'w-12 h-12 rounded-xl flex items-center justify-center',
                stat.color === 'primary' ? 'bg-primary/10 text-primary' : '',
                stat.color === 'success' ? 'bg-success/10 text-success' : '',
                stat.color === 'danger' ? 'bg-danger/10 text-danger' : '',
                stat.color === 'info' ? 'bg-info/10 text-info' : '',
                stat.color === 'warning' ? 'bg-warning/10 text-warning' : ''
              ]"
            >
              <component :is="stat.icon" class="w-6 h-6" />
            </div>
          </div>
          <div class="flex items-center gap-1 mt-3">
            <span 
              :class="[
                'text-xs font-medium',
                stat.changeType === 'positive' ? 'text-success' : 'text-danger'
              ]"
            >
              {{ stat.change }}
            </span>
            <span class="text-xs text-muted">vs last month</span>
          </div>
        </div>
      </div>

      <!-- Quick Actions & Recent Activity -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Quick Actions -->
        <div class="lg:col-span-1">
          <div class="card">
            <h3 class="text-lg font-semibold text-text mb-4">Quick Actions</h3>
            <div class="space-y-2">
              <RouterLink 
                v-for="link in quickLinks" 
                :key="link.to"
                :to="link.to"
                class="flex items-center gap-3 p-3 rounded-lg hover:bg-surface-hover transition-colors group"
              >
                <div 
                  :class="[
                    'w-10 h-10 rounded-lg flex items-center justify-center',
                    link.color === 'primary' ? 'bg-primary/10 text-primary' : '',
                    link.color === 'success' ? 'bg-success/10 text-success' : '',
                    link.color === 'warning' ? 'bg-warning/10 text-warning' : '',
                    link.color === 'info' ? 'bg-info/10 text-info' : ''
                  ]"
                >
                  <component :is="link.icon" class="w-5 h-5" />
                </div>
                <span class="text-sm font-medium text-text group-hover:text-primary transition-colors">
                  {{ link.label }}
                </span>
                <ArrowUpRight class="w-4 h-4 text-muted ml-auto group-hover:text-primary transition-colors" />
              </RouterLink>
            </div>
          </div>
        </div>

        <!-- Recent Activity -->
        <div class="lg:col-span-2">
          <div class="card">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold text-text">Recent Transactions</h3>
              <RouterLink to="/accounting/journal" class="text-sm text-primary hover:text-primary-hover font-medium">
                View All
              </RouterLink>
            </div>
            
            <div v-if="stats.recentActivity.length === 0" class="text-center py-8">
              <FileText class="w-12 h-12 text-muted mx-auto mb-3" />
              <p class="text-muted">No recent transactions</p>
            </div>

            <div v-else class="space-y-3">
              <div 
                v-for="(entry, index) in stats.recentActivity" 
                :key="entry.id || index"
                class="flex items-center gap-4 p-3 rounded-lg bg-background hover:bg-surface-hover transition-colors"
              >
                <div class="w-10 h-10 rounded-lg bg-success/10 flex items-center justify-center">
                  <CheckCircle class="w-5 h-5 text-success" />
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-text truncate">{{ entry.description || 'No description' }}</p>
                  <p class="text-xs text-muted">{{ new Date(entry.entry_date).toLocaleDateString('en-GB') }}</p>
                </div>
                <div class="text-right">
                  <p class="text-sm font-medium text-text">{{ formatCurrency(entry.total_debit) }}</p>
                  <p class="text-xs text-muted">Debit</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Financial Overview -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Balance Overview -->
        <div class="card">
          <h3 class="text-lg font-semibold text-text mb-4">Balance Overview</h3>
          <div class="space-y-4">
            <div class="flex items-center justify-between p-4 rounded-lg bg-background">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-lg bg-success/10 flex items-center justify-center">
                  <TrendingUp class="w-5 h-5 text-success" />
                </div>
                <div>
                  <p class="text-sm font-medium text-text">Total Income</p>
                  <p class="text-xs text-muted">All revenue streams</p>
                </div>
              </div>
              <p class="text-lg font-bold text-success">{{ formatCurrency(stats.value?.totalCredit || 0) }}</p>
            </div>
            <div class="flex items-center justify-between p-4 rounded-lg bg-background">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-lg bg-danger/10 flex items-center justify-center">
                  <Wallet class="w-5 h-5 text-danger" />
                </div>
                <div>
                  <p class="text-sm font-medium text-text">Total Expenses</p>
                  <p class="text-xs text-muted">All expense accounts</p>
                </div>
              </div>
              <p class="text-lg font-bold text-danger">{{ formatCurrency(stats.value?.totalDebit || 0) }}</p>
            </div>
          </div>
        </div>

        <!-- Reports Quick Access -->
        <div class="card">
          <h3 class="text-lg font-semibold text-text mb-4">Financial Reports</h3>
          <div class="grid grid-cols-2 gap-3">
            <RouterLink 
              to="/accounting/profit-loss" 
              class="p-4 rounded-lg bg-background hover:bg-surface-hover border border-border hover:border-border-light transition-all group"
            >
              <TrendingUp class="w-6 h-6 text-success mb-2" />
              <p class="text-sm font-medium text-text group-hover:text-primary">Profit & Loss</p>
              <p class="text-xs text-muted">Income vs Expenses</p>
            </RouterLink>
            <RouterLink 
              to="/accounting/balance-sheet" 
              class="p-4 rounded-lg bg-background hover:bg-surface-hover border border-border hover:border-border-light transition-all group"
            >
              <Building2 class="w-6 h-6 text-info mb-2" />
              <p class="text-sm font-medium text-text group-hover:text-primary">Balance Sheet</p>
              <p class="text-xs text-muted">Assets & Liabilities</p>
            </RouterLink>
            <RouterLink 
              to="/accounting/income-report" 
              class="p-4 rounded-lg bg-background hover:bg-surface-hover border border-border hover:border-border-light transition-all group"
            >
              <DollarSign class="w-6 h-6 text-success mb-2" />
              <p class="text-sm font-medium text-text group-hover:text-primary">Income Report</p>
              <p class="text-xs text-muted">Revenue breakdown</p>
            </RouterLink>
            <RouterLink 
              to="/accounting/expense-report" 
              class="p-4 rounded-lg bg-background hover:bg-surface-hover border border-border hover:border-border-light transition-all group"
            >
              <Wallet class="w-6 h-6 text-danger mb-2" />
              <p class="text-sm font-medium text-text group-hover:text-primary">Expense Report</p>
              <p class="text-xs text-muted">Expense breakdown</p>
            </RouterLink>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
